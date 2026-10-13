`timescale 1ns / 1ps
////////////////////////////////////////////////////////////////////////////////// 
// Engineer: Soumajit Mandal (Roll: 2023ETB016)
// 
// Create Date: 10/12/2026
// Design Name: 8086 Microprocessor
// Module Name: tb_subroutine_branch
// Project Name: 8086 Verilog Implementation
// Description: Testbench 5 - Subroutine CALL/RET, INC/DEC, SUB, and XCHG AX,BX.
// 
// Revision : 0.01 - File Created
//////////////////////////////////////////////////////////////////////////////////

module tb_subroutine_branch;

    reg clk;
    reg reset;
    reg ready;

    wire halted;
    wire illegal_opcode;
    wire [7:0] offending_opcode;
    wire [15:0] ip, ax, bx, cx, dx;
    wire [31:0] retired, fetch_cycles, operand_cycles, wait_cycles;
    wire [2:0] queue_count;

    top_8086 uut (
        .clk(clk), .reset(reset), .ready(ready),
        .halted(halted), .illegal_opcode(illegal_opcode), .offending_opcode(offending_opcode),
        .ip(ip), .ax(ax), .bx(bx), .cx(cx), .dx(dx),
        .retired(retired), .queue_count(queue_count), 
        .fetch_cycles(fetch_cycles), .operand_cycles(operand_cycles), .wait_cycles(wait_cycles)
    );

    always #5 clk = ~clk;

    initial begin
        clk = 0;
        reset = 1;
        ready = 1;

        // 0000: MOV AX, 0010h (B8 10 00)
        uut.biu.memory[20'h00000] = 8'hB8; 
        uut.biu.memory[20'h00001] = 8'h10;
        uut.biu.memory[20'h00002] = 8'h00;

        // 0003: INC AX (40) -> AX = 0011h
        uut.biu.memory[20'h00003] = 8'h40;

        // 0004: CALL near +0002h (E8 02 00) -> pushes 0007h, jumps to 0009h
        uut.biu.memory[20'h00004] = 8'hE8;
        uut.biu.memory[20'h00005] = 8'h02;
        uut.biu.memory[20'h00006] = 8'h00;

        // 0007: Return target: INC BX (43) -> BX = 0011h
        uut.biu.memory[20'h00007] = 8'h43;

        // 0008: HLT (F4)
        uut.biu.memory[20'h00008] = 8'hF4;

        // Subroutine at 0009h:
        // 0009: SUB AX, 0001h (2D 01 00) -> AX = 0010h
        uut.biu.memory[20'h00009] = 8'h2D;
        uut.biu.memory[20'h0000A] = 8'h01;
        uut.biu.memory[20'h0000B] = 8'h00;

        // 000C: XCHG AX, BX (93) -> BX = 0010h, AX = 0000h
        uut.biu.memory[20'h0000C] = 8'h93;

        // 000D: RET near (C3) -> pops 0007h, returns to 0007h
        uut.biu.memory[20'h0000D] = 8'hC3;

        #20 reset = 0;
        #1 uut.eu.inst_rf.r[4] = 16'h0600;
    end

    initial begin
        wait(halted == 1'b1);
        #10;
        $display("-------------------------------------------------");
        $display("SUBROUTINE CALL/RET & ARITHMETIC TEST COMPLETE");
        $display("Final Registers: AX = %h (Expected 0000), BX = %h (Expected 0011)", ax, bx);
        $display("Final IP: %h (Expected 0009)", ip);
        
        if (ax == 16'h0000 && bx == 16'h0011 && ip == 16'h0009) begin
            $display("==================================================");
            $display("[TEST PASSED] tb_subroutine_branch: Near CALL, RET, INC, SUB, XCHG verified!");
            $display("==================================================");
        end else begin
            $display("[TEST FAILED] tb_subroutine_branch: State mismatch!");
            $fatal(1, "Subroutine verification assertion failed");
        end
        $finish;
    end

endmodule

`timescale 1ns / 1ps
////////////////////////////////////////////////////////////////////////////////// 
// Engineer: Soumajit Mandal (Roll: 2023ETB016)
// 
// Create Date: 10/12/2026
// Design Name: 8086 Microprocessor
// Module Name: tb_stack_ops
// Project Name: 8086 Verilog Implementation
// Description: Testbench for stack instructions (PUSH, POP).
// 
// Revision : 0.01 - File Created
//////////////////////////////////////////////////////////////////////////////////

module tb_stack_ops;

    reg clk, reset, ready;
    wire halted, illegal_opcode;
    wire [15:0] ip, ax, bx;

    top_8086 uut (
        .clk(clk), .reset(reset), .ready(ready),
        .halted(halted), .illegal_opcode(illegal_opcode),
        .ip(ip), .ax(ax), .bx(bx), .cx(), .dx(),
        .retired(), .queue_count(), 
        .fetch_cycles(), .operand_cycles(), .wait_cycles()
    );

    always #5 clk = ~clk;

    initial begin
        clk = 0; reset = 1; ready = 1;

        // 0000: MOV AX, 55AAh
        uut.biu.memory[20'h00000] = 8'hB8; 
        uut.biu.memory[20'h00001] = 8'hAA; 
        uut.biu.memory[20'h00002] = 8'h55; 
        // 0003: PUSH AX
        uut.biu.memory[20'h00003] = 8'h50; 
        // 0004: MOV AX, 0000h (Clear AX to prove POP works)
        uut.biu.memory[20'h00004] = 8'hB8; 
        uut.biu.memory[20'h00005] = 8'h00; 
        uut.biu.memory[20'h00006] = 8'h00; 
        // 0007: POP BX
        uut.biu.memory[20'h00007] = 8'h5B; 
        // 0008: HLT
        uut.biu.memory[20'h00008] = 8'hF4; 

        #20 reset = 0;
    end

    initial begin
        wait(halted == 1'b1);
        #10;
        $display("-------------------------------------------------");
        $display("STACK OPERATIONS TEST COMPLETE");
        $display("Expected BX: 55AA, Actual BX: %h", bx);
        if (bx == 16'h55AA) $display("RESULT: PASS");
        else $display("RESULT: FAIL");
        $display("-------------------------------------------------");
        $finish;
    end

endmodule
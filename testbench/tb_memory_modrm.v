`timescale 1ns / 1ps
////////////////////////////////////////////////////////////////////////////////// 
// Engineer: Soumajit Mandal (Roll: 2023ETB016)
// 
// Create Date: 10/12/2026
// Design Name: 8086 Microprocessor
// Module Name: tb_memory_modrm
// Project Name: 8086 Verilog Implementation
// Description: Testbench for ModR/M decoding and memory read/write cycles.
// 
// Revision : 0.01 - File Created
//////////////////////////////////////////////////////////////////////////////////

module tb_memory_modrm;

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

        // 0000: MOV BX, 0010h
        uut.biu.memory[20'h00000] = 8'hBB; 
        uut.biu.memory[20'h00001] = 8'h10; 
        uut.biu.memory[20'h00002] = 8'h00; 
        // 0003: MOV AX, 1234h
        uut.biu.memory[20'h00003] = 8'hB8; 
        uut.biu.memory[20'h00004] = 8'h34; 
        uut.biu.memory[20'h00005] = 8'h12; 
        // 0006: MOV [BX], AX (Opcode: 89, ModR/M: 07)
        uut.biu.memory[20'h00006] = 8'h89; 
        uut.biu.memory[20'h00007] = 8'h07; 
        // 0008: HLT
        uut.biu.memory[20'h00008] = 8'hF4; 
        
        // Clear target memory
        uut.biu.memory[20'h00010] = 8'h00;
        uut.biu.memory[20'h00011] = 8'h00;

        #20 reset = 0;
    end

    initial begin
        wait(halted == 1'b1);
        #10;
        $display("-------------------------------------------------");
        $display("MEMORY ADDRESSING TEST COMPLETE");
        $display("Expected Memory [0010]: 34, Actual: %h", uut.biu.memory[20'h00010]);
        $display("Expected Memory [0011]: 12, Actual: %h", uut.biu.memory[20'h00011]);
        
        if (uut.biu.memory[20'h00010] == 8'h34 && uut.biu.memory[20'h00011] == 8'h12) begin
            $display("==================================================");
            $display("[TEST PASSED] tb_memory_modrm: 16-bit ModR/M memory write verified!");
            $display("==================================================");
        end else begin
            $display("[TEST FAILED] tb_memory_modrm: Memory write mismatch!");
            $fatal(1, "Memory addressing assertion failed");
        end
        $finish;
    end

endmodule
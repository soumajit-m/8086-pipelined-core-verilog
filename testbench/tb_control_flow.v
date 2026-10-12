`timescale 1ns / 1ps
////////////////////////////////////////////////////////////////////////////////// 
// Engineer: Soumajit Mandal (Roll: 2023ETB016)
// 
// Create Date: 10/12/2026
// Design Name: 8086 Microprocessor
// Module Name: tb_control_flow
// Project Name: 8086 Verilog Implementation
// Description: Testbench for flags and branch instructions (STC, CLC, JMP).
// 
// Revision : 0.01 - File Created
//////////////////////////////////////////////////////////////////////////////////

module tb_control_flow;

    reg clk, reset, ready;
    wire halted, illegal_opcode;
    wire [15:0] ip;
    wire [31:0] retired;

    top_8086 uut (
        .clk(clk), .reset(reset), .ready(ready),
        .halted(halted), .illegal_opcode(illegal_opcode),
        .ip(ip), .ax(), .bx(), .cx(), .dx(),
        .retired(retired), .queue_count(), 
        .fetch_cycles(), .operand_cycles(), .wait_cycles()
    );

    always #5 clk = ~clk;

    initial begin
        clk = 0; reset = 1; ready = 1;

        // 0000: STC (Set Carry)
        uut.biu.memory[20'h00000] = 8'hF9; 
        // 0001: CLC (Clear Carry)
        uut.biu.memory[20'h00001] = 8'hF8; 
        // 0002: JMP short +02h (Jump over the NOPs)
        uut.biu.memory[20'h00002] = 8'hEB; 
        uut.biu.memory[20'h00003] = 8'h02; 
        // 0004: NOP (Should be skipped)
        uut.biu.memory[20'h00004] = 8'h90; 
        // 0005: NOP (Should be skipped)
        uut.biu.memory[20'h00005] = 8'h90; 
        // 0006: HLT
        uut.biu.memory[20'h00006] = 8'hF4; 

        #20 reset = 0;
    end

    initial begin
        wait(halted == 1'b1);
        #10;
        $display("-------------------------------------------------");
        $display("CONTROL FLOW TEST COMPLETE");
        $display("Expected IP at HALT: 0007, Actual IP: %h", ip);
        if (ip == 16'h0007) $display("RESULT: PASS");
        else $display("RESULT: FAIL");
        $display("-------------------------------------------------");
        $finish;
    end

endmodule
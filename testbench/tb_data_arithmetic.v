`timescale 1ns / 1ps
////////////////////////////////////////////////////////////////////////////////// 
// Engineer: Soumajit Mandal (Roll: 2023ETB016)
// 
// Create Date: 10/12/2026
// Design Name: 8086 Microprocessor
// Module Name: tb_data_arithmetic
// Project Name: 8086 Verilog Implementation
// Description: Testbench for Data Transfer and Arithmetic instructions (MOV, ADD).
// 
// Revision : 0.01 - File Created
//////////////////////////////////////////////////////////////////////////////////

module tb_data_arithmetic;

    // Inputs
    reg clk;
    reg reset;
    reg ready;

    // Outputs
    wire halted;
    wire illegal_opcode;
    wire [7:0] offending_opcode;
    wire [15:0] ip, ax, bx, cx, dx;
    wire [31:0] retired, fetch_cycles, operand_cycles, wait_cycles;
    wire [2:0] queue_count;

    // Instantiate the Unit Under Test (UUT)
    top_8086 uut (
        .clk(clk), .reset(reset), .ready(ready),
        .halted(halted), .illegal_opcode(illegal_opcode), .offending_opcode(offending_opcode),
        .ip(ip), .ax(ax), .bx(bx), .cx(cx), .dx(dx),
        .retired(retired), .queue_count(queue_count), 
        .fetch_cycles(fetch_cycles), .operand_cycles(operand_cycles), .wait_cycles(wait_cycles)
    );

    // Clock Generation
    always #5 clk = ~clk;

    initial begin
        clk = 0;
        reset = 1;
        ready = 1; // Always ready (no memory wait states simulated externally)

        // Inject Machine Code into BIU Memory
        // 0000: NOP
        uut.biu.memory[20'h00000] = 8'h90; 
        // 0001: MOV AX, 1234h
        uut.biu.memory[20'h00001] = 8'hB8; 
        uut.biu.memory[20'h00002] = 8'h34; // LSB
        uut.biu.memory[20'h00003] = 8'h12; // MSB
        // 0004: ADD AX, 1111h
        uut.biu.memory[20'h00004] = 8'h05; 
        uut.biu.memory[20'h00005] = 8'h11; // LSB
        uut.biu.memory[20'h00006] = 8'h11; // MSB
        // 0007: HLT
        uut.biu.memory[20'h00007] = 8'hF4; 

        #20 reset = 0;
    end

    // Monitor and verify results
    initial begin
        wait(halted == 1'b1);
        #10;
        $display("-------------------------------------------------");
        $display("DATA & ARITHMETIC TEST COMPLETE");
        $display("Expected AX: 2345, Actual AX: %h", ax);
        if (ax == 16'h2345) begin
            $display("==================================================");
            $display("[TEST PASSED] tb_data_arithmetic: MOV & ADD execution verified!");
            $display("==================================================");
        end else begin
            $display("[TEST FAILED] tb_data_arithmetic: AX mismatch!");
            $fatal(1, "Data arithmetic assertion failed");
        end
        $finish;
    end

endmodule
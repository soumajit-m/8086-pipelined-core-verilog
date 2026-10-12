`timescale 1ns / 1ps
////////////////////////////////////////////////////////////////////////////////// 
// Engineer: Soumajit Mandal (Roll: 2023ETB016)
// 
// Create Date: 10/12/2026
// Design Name: 8086 Microprocessor
// Module Name: control_unit_8086
// Project Name: 8086 Verilog Implementation
// Description: EU sequencing controller mapping instruction phases.
// 
// Revision : 0.02 - Added halt lock to prevent execution escape after F4.
//////////////////////////////////////////////////////////////////////////////////

module control_unit_8086 (
    input  wire       clk,
    input  wire       reset,
    input  wire       instruction_valid,
    input  wire       execute_done,
    input  wire       halted_in,
    output reg        instruction_take,
    output reg        execute_start,
    output reg        halted,
    output reg  [2:0] state
);

    localparam [2:0] 
        FETCH   = 3'd0,
        DECODE  = 3'd1,
        EXECUTE = 3'd2,
        RETIRE  = 3'd3,
        HALT    = 3'd4;

    always @(posedge clk) begin
        if (reset) begin 
            state            <= FETCH; 
            instruction_take <= 1'b0; 
            execute_start    <= 1'b0; 
            halted           <= 1'b0; 
        end else begin 
            instruction_take <= 1'b0; 
            execute_start    <= 1'b0;
            
            case (state)
                FETCH: begin
                    if (instruction_valid && !halted) begin 
                        instruction_take <= 1'b1; 
                        state <= DECODE; 
                    end
                end
                DECODE: begin 
                    execute_start <= 1'b1; 
                    state <= EXECUTE; 
                end
                EXECUTE: begin
                    if (execute_done) begin
                        state <= RETIRE;
                    end
                end
                RETIRE: begin
                    if (halted_in) begin 
                        halted <= 1'b1; 
                        state <= HALT; 
                    end else begin
                        state <= FETCH;
                    end
                end
                HALT: begin 
                    halted <= 1'b1;
                    state <= HALT; // Lock in HALT state permanently
                end
                default: state <= FETCH;
            endcase
        end
    end
endmodule
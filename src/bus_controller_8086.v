`timescale 1ns / 1ps
////////////////////////////////////////////////////////////////////////////////// 
// Engineer: Soumajit Mandal (Roll: 2023ETB016)
// 
// Create Date: 10/12/2026
// Design Name: 8086 Microprocessor
// Module Name: bus_controller_8086
// Project Name: 8086 Verilog Implementation
// Description: External bus-cycle sequencer: T1,T2,T3,(Tw while READY low),T4.
// 
// Revision : 0.01 - File Created
//////////////////////////////////////////////////////////////////////////////////

module bus_controller_8086 (
    input  wire        clk,
    input  wire        reset,
    input  wire        start,
    input  wire        ready,
    output reg         active,
    output reg  [2:0]  state,
    output reg         done,
    output reg  [15:0] cycle_count,
    output reg  [15:0] wait_count
);

    localparam [2:0] 
        IDLE = 3'd0,
        T1   = 3'd1,
        T2   = 3'd2,
        T3   = 3'd3,
        TW   = 3'd4,
        T4   = 3'd5;

    always @(posedge clk) begin
        if (reset) begin 
            state       <= IDLE; 
            active      <= 1'b0; 
            done        <= 1'b0; 
            cycle_count <= 16'b0; 
            wait_count  <= 16'b0; 
        end else begin 
            done <= 1'b0;
            case (state)
                IDLE: begin 
                    active <= 1'b0; 
                    if (start) begin 
                        state <= T1; 
                        active <= 1'b1; 
                    end 
                end
                T1: state <= T2;
                T2: state <= T3;
                T3: begin
                    if (!ready) begin 
                        state <= TW; 
                        wait_count <= wait_count + 1'b1; 
                    end else begin
                        state <= T4;
                    end
                end
                TW: begin
                    if (!ready) begin
                        wait_count <= wait_count + 1'b1; 
                    end else begin
                        state <= T4;
                    end
                end
                T4: begin 
                    state <= IDLE; 
                    active <= 1'b0; 
                    done <= 1'b1; 
                    cycle_count <= cycle_count + 1'b1; 
                end
                default: begin 
                    state <= IDLE; 
                    active <= 1'b0; 
                end
            endcase
        end
    end
endmodule
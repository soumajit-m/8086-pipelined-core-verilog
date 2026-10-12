`timescale 1ns / 1ps
////////////////////////////////////////////////////////////////////////////////// 
// Engineer: Soumajit Mandal (Roll: 2023ETB016)
// 
// Create Date: 10/12/2026
// Design Name: 8086 Microprocessor
// Module Name: address_unit_8086
// Project Name: 8086 Verilog Implementation
// Description: 8086 segmented physical-address calculation and 16-bit EA generation.
// 
// Revision : 0.01 - File Created
//////////////////////////////////////////////////////////////////////////////////

module address_unit_8086 (
    input  wire [15:0] segment,
    input  wire [15:0] offset,
    output wire [19:0] physical_address,
    input  wire [2:0]  rm,
    input  wire [1:0]  mod_field,
    input  wire [15:0] bx,
    input  wire [15:0] bp,
    input  wire [15:0] si,
    input  wire [15:0] di,
    input  wire [15:0] displacement,
    output reg  [15:0] effective_offset,
    output reg         uses_bp
);

    assign physical_address = {segment, 4'b0} + {4'b0, offset};

    always @(*) begin
        uses_bp = 1'b0;
        case (rm)
            3'b000: effective_offset = bx + si;
            3'b001: effective_offset = bx + di;
            3'b010: begin effective_offset = bp + si; uses_bp = 1'b1; end
            3'b011: begin effective_offset = bp + di; uses_bp = 1'b1; end
            3'b100: effective_offset = si;
            3'b101: effective_offset = di;
            3'b110: begin 
                if (mod_field == 2'b00) 
                    effective_offset = displacement; 
                else begin 
                    effective_offset = bp; 
                    uses_bp = 1'b1; 
                end 
            end
            default: effective_offset = bx;
        endcase

        if (mod_field == 2'b01 || mod_field == 2'b10) begin
            effective_offset = effective_offset + displacement;
        end
    end

endmodule
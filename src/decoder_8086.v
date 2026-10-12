`timescale 1ns / 1ps
////////////////////////////////////////////////////////////////////////////////// 
// Engineer: Soumajit Mandal (Roll: 2023ETB016)
// 
// Create Date: 10/12/2026
// Design Name: 8086 Microprocessor
// Module Name: decoder_8086
// Project Name: 8086 Verilog Implementation
// Description: Compact authentic-opcode classifier for the implemented subset.
// 
// Revision : 0.01 - File Created
//////////////////////////////////////////////////////////////////////////////////

module decoder_8086 (
    input  wire [7:0] opcode, 
    output reg  [5:0] operation, 
    output reg        supported, 
    output reg  [2:0] length_hint
);

    localparam [5:0] 
        OP_NOP    = 6'd0, 
        OP_HLT    = 6'd1, 
        OP_MOVI   = 6'd2, 
        OP_ADDI   = 6'd3, 
        OP_JMP8   = 6'd4, 
        OP_JMP16  = 6'd5, 
        OP_JZ     = 6'd6, 
        OP_JNZ    = 6'd7, 
        OP_CLC    = 6'd8, 
        OP_STC    = 6'd9, 
        OP_MOV_RR = 6'd10, 
        OP_ADD_RR = 6'd11, 
        OP_PUSH   = 6'd12, 
        OP_POP    = 6'd13;

    always @(*) begin 
        operation   = 6'd0; 
        supported   = 1'b1; 
        length_hint = 3'd1;
        
        case (opcode)
            8'h90: operation = OP_NOP;
            8'hF4: operation = OP_HLT;
            8'hB0, 8'hB1, 8'hB2, 8'hB3, 
            8'hB4, 8'hB5, 8'hB6, 8'hB7: begin 
                operation   = OP_MOVI; 
                length_hint = 3'd2; 
            end
            8'hB8, 8'hB9, 8'hBA, 8'hBB, 
            8'hBC, 8'hBD, 8'hBE, 8'hBF: begin 
                operation   = OP_MOVI; 
                length_hint = 3'd3; 
            end
            8'h05: begin 
                operation   = OP_ADDI; 
                length_hint = 3'd3; 
            end
            8'h04: begin 
                operation   = OP_ADDI; 
                length_hint = 3'd2; 
            end
            8'hEB: begin 
                operation   = OP_JMP8; 
                length_hint = 3'd2; 
            end
            8'hE9: begin 
                operation   = OP_JMP16; 
                length_hint = 3'd3; 
            end
            8'h74: begin 
                operation   = OP_JZ; 
                length_hint = 3'd2; 
            end
            8'h75: begin 
                operation   = OP_JNZ; 
                length_hint = 3'd2; 
            end
            8'hF8: operation = OP_CLC;
            8'hF9: operation = OP_STC;
            8'h88, 8'h89, 8'h8A, 8'h8B: begin 
                operation   = OP_MOV_RR; 
                length_hint = 3'd2; 
            end
            8'h01, 8'h03: begin 
                operation   = OP_ADD_RR; 
                length_hint = 3'd2; 
            end
            8'h50, 8'h51, 8'h52, 8'h53, 
            8'h54, 8'h55, 8'h56, 8'h57: operation = OP_PUSH;
            8'h58, 8'h59, 8'h5A, 8'h5B, 
            8'h5C, 8'h5D, 8'h5E, 8'h5F: operation = OP_POP;
            default: begin 
                supported   = 1'b0; 
                operation   = 6'd0; 
                length_hint = 3'd1; 
            end
        endcase
    end
endmodule
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
        OP_NOP     = 6'd0, 
        OP_HLT     = 6'd1, 
        OP_MOVI    = 6'd2, 
        OP_ADDI    = 6'd3, 
        OP_JMP8    = 6'd4, 
        OP_JMP16   = 6'd5, 
        OP_JZ      = 6'd6, 
        OP_JNZ     = 6'd7, 
        OP_CLC     = 6'd8, 
        OP_STC     = 6'd9, 
        OP_MOV_RR  = 6'd10, 
        OP_ADD_RR  = 6'd11, 
        OP_PUSH    = 6'd12, 
        OP_POP     = 6'd13,
        OP_SUBI    = 6'd14,
        OP_SUB_RR  = 6'd15,
        OP_CMP_RR  = 6'd16,
        OP_AND_RR  = 6'd17,
        OP_OR_RR   = 6'd18,
        OP_XOR_RR  = 6'd19,
        OP_INC     = 6'd20,
        OP_DEC     = 6'd21,
        OP_CALL    = 6'd22,
        OP_RET     = 6'd23,
        OP_JC      = 6'd24,
        OP_JNC     = 6'd25,
        OP_JS      = 6'd26,
        OP_JNS     = 6'd27,
        OP_JO      = 6'd28,
        OP_JNO     = 6'd29,
        OP_CMC     = 6'd30,
        OP_XCHG_AX = 6'd31,
        OP_CMPI    = 6'd32,
        OP_ANDI    = 6'd33,
        OP_ORI     = 6'd34,
        OP_XORI    = 6'd35;

    always @(*) begin 
        operation   = 6'd0; 
        supported   = 1'b1; 
        length_hint = 3'd1;
        
        case (opcode)
            8'h90: operation = OP_NOP;
            8'hF4: operation = OP_HLT;
            8'hF5: operation = OP_CMC;
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
            8'h2D: begin 
                operation   = OP_SUBI; 
                length_hint = 3'd3; 
            end
            8'h2C: begin 
                operation   = OP_SUBI; 
                length_hint = 3'd2; 
            end
            8'h3D: begin 
                operation   = OP_CMPI; 
                length_hint = 3'd3; 
            end
            8'h3C: begin 
                operation   = OP_CMPI; 
                length_hint = 3'd2; 
            end
            8'h25: begin 
                operation   = OP_ANDI; 
                length_hint = 3'd3; 
            end
            8'h24: begin 
                operation   = OP_ANDI; 
                length_hint = 3'd2; 
            end
            8'h0D: begin 
                operation   = OP_ORI; 
                length_hint = 3'd3; 
            end
            8'h0C: begin 
                operation   = OP_ORI; 
                length_hint = 3'd2; 
            end
            8'h35: begin 
                operation   = OP_XORI; 
                length_hint = 3'd3; 
            end
            8'h34: begin 
                operation   = OP_XORI; 
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
            8'hE8: begin 
                operation   = OP_CALL; 
                length_hint = 3'd3; 
            end
            8'hC3: begin 
                operation   = OP_RET; 
                length_hint = 3'd1; 
            end
            8'h74: begin 
                operation   = OP_JZ; 
                length_hint = 3'd2; 
            end
            8'h75: begin 
                operation   = OP_JNZ; 
                length_hint = 3'd2; 
            end
            8'h72: begin 
                operation   = OP_JC; 
                length_hint = 3'd2; 
            end
            8'h73: begin 
                operation   = OP_JNC; 
                length_hint = 3'd2; 
            end
            8'h78: begin 
                operation   = OP_JS; 
                length_hint = 3'd2; 
            end
            8'h79: begin 
                operation   = OP_JNS; 
                length_hint = 3'd2; 
            end
            8'h70: begin 
                operation   = OP_JO; 
                length_hint = 3'd2; 
            end
            8'h71: begin 
                operation   = OP_JNO; 
                length_hint = 3'd2; 
            end
            8'hF8: operation = OP_CLC;
            8'hF9: operation = OP_STC;
            8'h88, 8'h89, 8'h8A, 8'h8B: begin 
                operation   = OP_MOV_RR; 
                length_hint = 3'd2; 
            end
            8'h00, 8'h01, 8'h02, 8'h03: begin 
                operation   = OP_ADD_RR; 
                length_hint = 3'd2; 
            end
            8'h28, 8'h29, 8'h2A, 8'h2B: begin 
                operation   = OP_SUB_RR; 
                length_hint = 3'd2; 
            end
            8'h38, 8'h39, 8'h3A, 8'h3B: begin 
                operation   = OP_CMP_RR; 
                length_hint = 3'd2; 
            end
            8'h20, 8'h21, 8'h22, 8'h23: begin 
                operation   = OP_AND_RR; 
                length_hint = 3'd2; 
            end
            8'h08, 8'h09, 8'h0A, 8'h0B: begin 
                operation   = OP_OR_RR; 
                length_hint = 3'd2; 
            end
            8'h30, 8'h31, 8'h32, 8'h33: begin 
                operation   = OP_XOR_RR; 
                length_hint = 3'd2; 
            end
            8'h40, 8'h41, 8'h42, 8'h43,
            8'h44, 8'h45, 8'h46, 8'h47: begin
                operation   = OP_INC;
                length_hint = 3'd1;
            end
            8'h48, 8'h49, 8'h4A, 8'h4B,
            8'h4C, 8'h4D, 8'h4E, 8'h4F: begin
                operation   = OP_DEC;
                length_hint = 3'd1;
            end
            8'h91, 8'h92, 8'h93, 8'h94,
            8'h95, 8'h96, 8'h97: begin
                operation   = OP_XCHG_AX;
                length_hint = 3'd1;
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
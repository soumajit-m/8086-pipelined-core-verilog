`timescale 1ns / 1ps
////////////////////////////////////////////////////////////////////////////////// 
// Engineer: Soumajit Mandal (Roll: 2023ETB016)
// 
// Create Date: 10/12/2026
// Design Name: 8086 Microprocessor
// Module Name: alu_8086
// Project Name: 8086 Verilog Implementation
// Description: Combinational width-selectable ALU. flags = {OF,SF,ZF,AF,PF,CF}.
// 
// Revision : 0.02 - Fixed flag bit positions to match EU expectation.
//////////////////////////////////////////////////////////////////////////////////

module alu_8086 (
    input  wire [15:0] a,
    input  wire [15:0] b,
    input  wire [3:0]  operation,
    input  wire        width8,
    input  wire        carry_in,
    output reg  [15:0] result,
    output reg  [5:0]  flags
);

    reg [16:0] tmp;
    reg [15:0] mask_a;
    reg [15:0] mask_b;
    reg [15:0] r;
    reg        parity;

    always @(*) begin
        mask_a = width8 ? {8'b0, a[7:0]} : a;
        mask_b = width8 ? {8'b0, b[7:0]} : b;
        tmp    = 17'b0;
        r      = 16'b0;
        flags  = 6'b0;

        case (operation)
            4'h0: begin // ADD
                tmp = {1'b0, mask_a} + {1'b0, mask_b}; 
                r = tmp[15:0]; 
                flags[0] = width8 ? tmp[8] : tmp[16]; 
                flags[2] = ((mask_a[3:0] + mask_b[3:0]) > 15); 
                flags[5] = width8 ? ((~(mask_a[7] ^ mask_b[7])) & (mask_a[7] ^ r[7])) :
                                    ((~(mask_a[15] ^ mask_b[15])) & (mask_a[15] ^ r[15])); 
            end
            4'h1: begin // ADC
                tmp = {1'b0, mask_a} + {1'b0, mask_b} + carry_in; 
                r = tmp[15:0]; 
                flags[0] = width8 ? tmp[8] : tmp[16]; 
                flags[2] = ((mask_a[3:0] + mask_b[3:0] + carry_in) > 15); 
                flags[5] = width8 ? ((~(mask_a[7] ^ mask_b[7])) & (mask_a[7] ^ r[7])) :
                                    ((~(mask_a[15] ^ mask_b[15])) & (mask_a[15] ^ r[15])); 
            end
            4'h2: begin // SUB
                tmp = {1'b0, mask_a} - {1'b0, mask_b}; 
                r = tmp[15:0]; 
                flags[0] = width8 ? (mask_a[7:0] < mask_b[7:0]) : (mask_a < mask_b); 
                flags[2] = mask_a[3:0] < mask_b[3:0]; 
                flags[5] = width8 ? ((mask_a[7] ^ mask_b[7]) & (mask_a[7] ^ r[7])) :
                                    ((mask_a[15] ^ mask_b[15]) & (mask_a[15] ^ r[15])); 
            end
            4'h3: begin // SBB
                tmp = {1'b0, mask_a} - {1'b0, mask_b} - carry_in; 
                r = tmp[15:0]; 
                flags[0] = width8 ? (mask_a[7:0] < (mask_b[7:0] + carry_in)) : (mask_a < (mask_b + carry_in)); 
                flags[2] = mask_a[3:0] < (mask_b[3:0] + carry_in); 
                flags[5] = width8 ? ((mask_a[7] ^ mask_b[7]) & (mask_a[7] ^ r[7])) :
                                    ((mask_a[15] ^ mask_b[15]) & (mask_a[15] ^ r[15])); 
            end
            4'h4: r = mask_a & mask_b; // AND
            4'h5: r = mask_a | mask_b; // OR
            4'h6: r = mask_a ^ mask_b; // XOR
            4'h7: r = ~mask_a;         // NOT
            4'h8: begin // SHL
                r = mask_a << 1; 
                flags[0] = width8 ? mask_a[7] : mask_a[15]; 
                flags[5] = width8 ? (r[7] ^ flags[0]) : (r[15] ^ flags[0]); 
            end
            4'h9: begin // SHR
                r = mask_a >> 1; 
                flags[0] = mask_a[0]; 
                flags[5] = 1'b0; 
            end
            4'ha: begin // NEG
                r = ~mask_a + 1'b1; 
                flags[0] = width8 ? (mask_a[7:0] != 8'b0) : (mask_a != 16'b0); 
                flags[2] = (mask_a[3:0] != 4'b0); 
                flags[5] = width8 ? (mask_a[7:0] == 8'h80) : (mask_a == 16'h8000); 
            end
            default: r = mask_a;
        endcase

        if (width8) begin
            r = {8'b0, r[7:0]};
        end

        result = r;
        flags[3] = (r == 16'b0);           // ZF
        flags[4] = width8 ? r[7] : r[15];  // SF
        
        parity = ~(^r[7:0]); 
        flags[1] = parity;                 // PF
        
        // Logical operations clear CF, AF, and OF
        if (operation >= 4'h4 && operation <= 4'h7) begin 
            flags[0] = 1'b0; 
            flags[2] = 1'b0; 
            flags[5] = 1'b0; 
        end
    end
endmodule
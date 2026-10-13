`timescale 1ns / 1ps
////////////////////////////////////////////////////////////////////////////////// 
// Engineer: Soumajit Mandal (Roll: 2023ETB016)
// 
// Create Date: 10/12/2026
// Design Name: 8086 Microprocessor
// Module Name: register_file_8086
// Project Name: 8086 Verilog Implementation
// Description: Eight 16-bit general registers in encoding order AX,CX,DX,BX,SP,BP,SI,DI.
// 
// Revision : 0.01 - File Created
//////////////////////////////////////////////////////////////////////////////////

module register_file_8086 (
    input  wire        clk, 
    input  wire        reset,
    input  wire [2:0]  read_a, 
    input  wire [2:0]  read_b, 
    output wire [15:0] data_a, 
    output wire [15:0] data_b,
    input  wire        write_enable, 
    input  wire [2:0]  write_reg, 
    input  wire [15:0] write_data,
    input  wire        byte_mode, 
    input  wire [7:0]  byte_data, 
    input  wire [3:0]  byte_reg,
    input  wire [2:0]  seg_read, 
    output reg  [15:0] seg_data,
    input  wire        seg_write, 
    input  wire [1:0]  seg_wreg, 
    input  wire [15:0] seg_wdata,
    output wire [15:0] ax, 
    output wire [15:0] bx, 
    output wire [15:0] cx, 
    output wire [15:0] dx,
    output wire [15:0] sp, 
    output wire [15:0] bp, 
    output wire [15:0] si, 
    output wire [15:0] di,
    output wire [15:0] cs, 
    output wire [15:0] ds, 
    output wire [15:0] ss, 
    output wire [15:0] es
);

    reg [15:0] r[0:7]; 
    reg [15:0] s[0:3]; 
    integer i;

    assign ax = r[0]; 
    assign cx = r[1]; 
    assign dx = r[2]; 
    assign bx = r[3]; 
    assign sp = r[4]; 
    assign bp = r[5]; 
    assign si = r[6]; 
    assign di = r[7];
    
    assign es = s[0]; 
    assign cs = s[1]; 
    assign ss = s[2]; 
    assign ds = s[3];
    
    assign data_a = r[read_a]; 
    assign data_b = r[read_b];

    always @(*) seg_data = s[seg_read[1:0]];

    always @(posedge clk) begin
        if (reset) begin 
            for (i = 0; i < 8; i = i + 1) r[i] <= 16'b0; 
            for (i = 0; i < 4; i = i + 1) s[i] <= 16'b0; 
            s[1] <= 16'h0000; 
        end else begin
            if (write_enable) begin
                r[write_reg] <= write_data;
            end
            if (byte_mode) begin 
                if (byte_reg[2]) 
                    r[byte_reg[1:0]][15:8] <= byte_data; 
                else 
                    r[byte_reg[1:0]][7:0] <= byte_data; 
            end
            if (seg_write) begin
                s[seg_wreg] <= seg_wdata;
            end
        end
    end
endmodule
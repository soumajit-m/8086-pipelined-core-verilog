`timescale 1ns / 1ps
////////////////////////////////////////////////////////////////////////////////// 
// Engineer: Soumajit Mandal (Roll: 2023ETB016)
// 
// Create Date: 10/12/2026
// Design Name: 8086 Microprocessor
// Module Name: prefetch_queue_8086
// Project Name: 8086 Verilog Implementation
// Description: Six-byte FIFO for instruction bytes. Flush has priority over enqueue/dequeue.
// 
// Revision : 0.01 - File Created
//////////////////////////////////////////////////////////////////////////////////

module prefetch_queue_8086 (
    input  wire       clk, 
    input  wire       reset,
    input  wire       flush, 
    input  wire       enqueue, 
    input  wire [7:0] enqueue_data,
    input  wire       dequeue, 
    output wire [7:0] dequeue_data,
    output wire       empty, 
    output wire       full, 
    output reg  [2:0] count
);

    reg [7:0] mem [0:5];
    reg [2:0] rd_ptr, wr_ptr;

    assign empty = (count == 3'd0);
    assign full  = (count == 3'd6);
    assign dequeue_data = mem[rd_ptr];

    always @(posedge clk) begin
        if (reset || flush) begin 
            rd_ptr <= 3'b0; 
            wr_ptr <= 3'b0; 
            count  <= 3'b0; 
        end else begin
            if (enqueue && !full) begin 
                mem[wr_ptr] <= enqueue_data; 
                wr_ptr <= (wr_ptr == 3'd5) ? 3'd0 : wr_ptr + 1'b1; 
            end
            
            if (dequeue && !empty) begin
                rd_ptr <= (rd_ptr == 3'd5) ? 3'd0 : rd_ptr + 1'b1;
            end
            
            case ({enqueue && !full, dequeue && !empty})
                2'b10: count <= count + 1'b1;
                2'b01: count <= count - 1'b1;
                default: count <= count;
            endcase
        end
    end
endmodule
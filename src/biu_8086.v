`timescale 1ns / 1ps
////////////////////////////////////////////////////////////////////////////////// 
// Engineer: Soumajit Mandal (Roll: 2023ETB016)
// 
// Create Date: 10/12/2026
// Design Name: 8086 Microprocessor
// Module Name: biu_8086
// Project Name: 8086 Verilog Implementation
// Description: Bus Interface Unit utilizing bus_controller_8086 for T-states.
// 
// Revision : 0.05 - Added next_will_be_full lookahead to prevent 1-cycle FIFO overrun dropping bytes.
//////////////////////////////////////////////////////////////////////////////////

module biu_8086 (
    input  wire        clk,
    input  wire        reset,
    input  wire        ready,
    input  wire [15:0] cs,
    input  wire [15:0] fetch_ip,
    input  wire        redirect,
    input  wire [15:0] redirect_ip,
    input  wire        queue_pop,
    output wire [7:0]  queue_data,
    output wire        queue_empty,
    output wire        queue_full,
    output wire [2:0]  queue_count,
    input  wire        mem_req,
    input  wire        mem_write,
    input  wire [19:0] mem_addr,
    input  wire [15:0] mem_wdata,
    input  wire        mem_word,
    output reg         mem_ready,
    output reg  [15:0] mem_rdata,
    output reg  [19:0] last_fetch_address,
    output reg  [2:0]  bus_state,
    output reg  [31:0] fetch_cycles,
    output reg  [31:0] operand_cycles,
    output reg  [31:0] wait_cycles
);

    reg [7:0] memory[0:1048575]; 
    reg [15:0] fetch_offset; 
    reg [7:0]  enqueue_data; 
    reg        enqueue;
    reg        flush;
    
    wire       qempty, qfull; 
    wire [2:0] qcount; 
    wire [7:0] qdata;
    
    reg        operand_pending; 
    reg [19:0] op_addr; 
    reg        op_write; 
    reg [15:0] op_wdata; 
    reg        op_word;

    assign queue_data  = qdata; 
    assign queue_empty = qempty; 
    assign queue_full  = qfull; 
    assign queue_count = qcount;

    prefetch_queue_8086 q (
        .clk(clk),
        .reset(reset),
        .flush(flush),
        .enqueue(enqueue),
        .enqueue_data(enqueue_data),
        .dequeue(queue_pop),
        .dequeue_data(qdata),
        .empty(qempty),
        .full(qfull),
        .count(qcount)
    );

    reg         bc_start;
    wire        bc_active;
    wire [2:0]  bc_state;
    wire        bc_done;
    wire [15:0] bc_waits;
    
    bus_controller_8086 inst_bc (
        .clk         (clk),
        .reset       (reset),
        .start       (bc_start),
        .ready       (ready),
        .active      (bc_active),
        .state       (bc_state),
        .done        (bc_done),
        .cycle_count (),
        .wait_count  (bc_waits)
    );

    wire next_will_be_full = (qcount == 3'd5 && enqueue) || qfull;

    always @(posedge clk) begin
        if (reset) begin 
            fetch_offset       <= 16'b0; 
            enqueue            <= 1'b0; 
            flush              <= 1'b0; 
            mem_ready          <= 1'b0; 
            mem_rdata          <= 16'b0; 
            operand_pending    <= 1'b0; 
            fetch_cycles       <= 32'b0; 
            operand_cycles     <= 32'b0; 
            wait_cycles        <= 32'b0; 
            last_fetch_address <= 20'b0; 
            bus_state          <= 3'b0; 
            bc_start           <= 1'b0;
        end else begin 
            enqueue   <= 1'b0; 
            flush     <= 1'b0; 
            mem_ready <= 1'b0; 
            
            bus_state <= bc_state;

            if (redirect) begin 
                fetch_offset    <= redirect_ip; 
                flush           <= 1'b1; 
                enqueue         <= 1'b0; 
                operand_pending <= 1'b0; 
                bc_start        <= 1'b0;
            end 
            else if (mem_req && !operand_pending) begin 
                operand_pending <= 1'b1; 
                op_addr         <= mem_addr; 
                op_write        <= mem_write; 
                op_wdata        <= mem_wdata; 
                op_word         <= mem_word; 
            end 
            else if (operand_pending) begin
                if (!bc_active && !bc_start) bc_start <= 1'b1;
                else bc_start <= 1'b0;
                
                if (bc_state == 3'd4 && !ready) wait_cycles <= wait_cycles + 1'b1;

                if (bc_done) begin
                    if (op_write) begin 
                        memory[op_addr] <= op_wdata[7:0]; 
                        if (op_word) memory[(op_addr + 1'b1) & 20'hfffff] <= op_wdata[15:8]; 
                    end else begin 
                        mem_rdata[7:0]  <= memory[op_addr]; 
                        mem_rdata[15:8] <= op_word ? memory[(op_addr + 1'b1) & 20'hfffff] : 8'b0; 
                    end
                    
                    mem_ready       <= 1'b1; 
                    operand_pending <= 1'b0; 
                    operand_cycles  <= operand_cycles + 1'b1;
                end
            end 
            else if (!next_will_be_full && !flush) begin 
                last_fetch_address <= ({cs, 4'b0} + {4'b0, fetch_offset}) & 20'hfffff;
                enqueue_data       <= memory[({cs, 4'b0} + {4'b0, fetch_offset}) & 20'hfffff]; 
                enqueue            <= 1'b1; 
                fetch_offset       <= fetch_offset + 1'b1; 
                fetch_cycles       <= fetch_cycles + 1'b1;
            end
        end
    end
endmodule
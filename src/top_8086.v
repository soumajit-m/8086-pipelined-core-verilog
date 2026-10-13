`timescale 1ns / 1ps
////////////////////////////////////////////////////////////////////////////////// 
// Engineer: Soumajit Mandal (Roll: 2023ETB016)
// 
// Create Date: 10/12/2026
// Design Name: 8086 Microprocessor
// Module Name: top_8086
// Project Name: 8086 Verilog Implementation
// Description: Integration top routing the BIU and EU properly.
// 
// Revision : 0.01 - File Created
//////////////////////////////////////////////////////////////////////////////////

module top_8086 (
    input  wire        clk,
    input  wire        reset,
    input  wire        ready,
    output wire        halted,
    output wire        illegal_opcode,
    output wire [7:0]  offending_opcode,
    output wire [15:0] ip,
    output wire [15:0] ax,
    output wire [15:0] bx,
    output wire [15:0] cx,
    output wire [15:0] dx,
    output wire [31:0] retired,
    output wire [2:0]  queue_count,
    output wire [31:0] fetch_cycles,
    output wire [31:0] operand_cycles,
    output wire [31:0] wait_cycles
);

    wire [7:0]  qdata; 
    wire        qempty, qfull, qpop, redirect; 
    wire [15:0] redirect_ip;
    wire        mem_req, mem_write, mem_word, mem_ready; 
    wire [19:0] mem_addr; 
    wire [15:0] mem_wdata, mem_rdata;
    wire [15:0] sp, bp, si, di; 
    wire [15:0] cs_bus, ds_bus, ss_bus, es_bus;
    wire        cf, pf, af, zf, sf, oflag;

    biu_8086 biu (
        .clk(clk),
        .reset(reset),
        .ready(ready),
        .cs(cs_bus),
        .fetch_ip(ip),
        .redirect(redirect),
        .redirect_ip(redirect_ip),
        .queue_pop(qpop),
        .queue_data(qdata),
        .queue_empty(qempty),
        .queue_full(qfull),
        .queue_count(queue_count),
        .mem_req(mem_req),
        .mem_write(mem_write),
        .mem_addr(mem_addr),
        .mem_wdata(mem_wdata),
        .mem_word(mem_word),
        .mem_ready(mem_ready),
        .mem_rdata(mem_rdata),
        .last_fetch_address(),
        .bus_state(),
        .fetch_cycles(fetch_cycles),
        .operand_cycles(operand_cycles),
        .wait_cycles(wait_cycles)
    );

    eu_8086 eu (
        .clk(clk),
        .reset(reset),
        .instruction_byte(qdata),
        .queue_empty(qempty),
        .queue_pop(qpop),
        .redirect(redirect),
        .redirect_ip(redirect_ip),
        .mem_req(mem_req),
        .mem_write(mem_write),
        .mem_addr(mem_addr),
        .mem_wdata(mem_wdata),
        .mem_word(mem_word),
        .mem_ready(mem_ready),
        .mem_rdata(mem_rdata),
        .halted(halted),
        .illegal_opcode(illegal_opcode),
        .offending_opcode(offending_opcode),
        .ip_out(ip),
        .ax(ax),
        .bx(bx),
        .cx(cx),
        .dx(dx),
        .sp(sp),
        .bp(bp),
        .si(si),
        .di(di),
        .cs_out(cs_bus),
        .ds_out(ds_bus),
        .ss_out(ss_bus),
        .es_out(es_bus),
        .cf(cf),
        .pf(pf),
        .af(af),
        .zf(zf),
        .sf(sf),
        .oflag(oflag),
        .retired(retired)
    );
endmodule
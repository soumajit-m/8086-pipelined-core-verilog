`timescale 1ns / 1ps
////////////////////////////////////////////////////////////////////////////////// 
// Engineer: Soumajit Mandal (Roll: 2023ETB016)
// 
// Create Date: 10/12/2026
// Design Name: 8086 Microprocessor
// Module Name: eu_8086
// Project Name: 8086 Verilog Implementation
// Description: Structural Execution Unit with combinational ALU and Register File paths.
// 
// Revision:
// Revision 0.10 - 10/13/2026 - Added CALL, RET, INC, DEC, SUB, CMP, logical ops, conditional jumps, and dynamic CS.
//////////////////////////////////////////////////////////////////////////////////

module eu_8086 (
    input  wire        clk,
    input  wire        reset,
    
    // BIU Queue Interface
    input  wire [7:0]  instruction_byte,
    input  wire        queue_empty,
    output wire        queue_pop, 
    
    // BIU Memory Control Interface
    output reg         redirect,
    output reg  [15:0] redirect_ip,
    output reg         mem_req,
    output reg         mem_write,
    output reg  [19:0] mem_addr,
    output reg  [15:0] mem_wdata,
    output reg         mem_word,
    input  wire        mem_ready,
    input  wire [15:0] mem_rdata,
    
    // Status Outputs
    output wire        halted,
    output reg         illegal_opcode,
    output reg  [7:0]  offending_opcode,
    output reg  [15:0] ip_out,
    
    // Register Probes
    output wire [15:0] ax,
    output wire [15:0] bx,
    output wire [15:0] cx,
    output wire [15:0] dx,
    output wire [15:0] sp,
    output wire [15:0] bp,
    output wire [15:0] si,
    output wire [15:0] di,
    
    // Segment Register Probes
    output wire [15:0] cs_out,
    output wire [15:0] ds_out,
    output wire [15:0] ss_out,
    output wire [15:0] es_out,
    
    // Flag Probes
    output reg         cf,
    output reg         pf,
    output reg         af,
    output reg         zf,
    output reg         sf,
    output reg         oflag,
    
    output reg  [31:0] retired
);

    wire       cu_inst_take;
    wire       cu_exec_start;
    wire [2:0] cu_state;
    
    wire       inst_valid = !queue_empty;
    reg        exec_done;
    reg        halted_in;
    
    control_unit_8086 inst_cu (
        .clk               (clk),
        .reset             (reset),
        .instruction_valid (inst_valid),
        .execute_done      (exec_done),
        .halted_in         (halted_in),
        .instruction_take  (cu_inst_take),
        .execute_start     (cu_exec_start),
        .halted            (halted),
        .state             (cu_state)
    );

    reg [7:0]  opcode_reg;
    reg [7:0]  modrm_reg;
    reg [15:0] imm16_reg;
    
    wire [5:0] dec_operation;
    wire       dec_supported;
    wire [2:0] dec_length_hint;

    reg  [2:0]  rf_write_reg;
    reg         rf_we, rf_byte_mode;
    reg  [7:0]  rf_byte_data;
    reg  [3:0]  rf_byte_reg;
    reg  [15:0] rf_write_data;
    
    wire [15:0] cs_val, ds_val, ss_val, es_val;
    assign cs_out = cs_val;
    assign ds_out = ds_val;
    assign ss_out = ss_val;
    assign es_out = es_val;

    // Helper functions for 8-bit and 16-bit register reads
    function [7:0] get_reg8;
        input [2:0] rcode;
        case (rcode)
            3'b000: get_reg8 = ax[7:0];   // AL
            3'b001: get_reg8 = cx[7:0];   // CL
            3'b010: get_reg8 = dx[7:0];   // DL
            3'b011: get_reg8 = bx[7:0];   // BL
            3'b100: get_reg8 = ax[15:8];  // AH
            3'b101: get_reg8 = cx[15:8];  // CH
            3'b110: get_reg8 = dx[15:8];  // DH
            3'b111: get_reg8 = bx[15:8];  // BH
        endcase
    endfunction

    function [15:0] get_reg16;
        input [2:0] rcode;
        case (rcode)
            3'b000: get_reg16 = ax;
            3'b001: get_reg16 = cx;
            3'b010: get_reg16 = dx;
            3'b011: get_reg16 = bx;
            3'b100: get_reg16 = sp;
            3'b101: get_reg16 = bp;
            3'b110: get_reg16 = si;
            3'b111: get_reg16 = di;
        endcase
    endfunction

    // Combinational wires for ALU and AU
    reg  [15:0] alu_a_comb, alu_b_comb;
    reg  [3:0]  alu_op_comb;
    reg         alu_width8_comb, alu_cin_comb;
    wire [15:0] alu_result;
    wire [5:0]  alu_flags; 

    reg  [2:0]  au_rm;
    reg  [1:0]  au_mod;
    reg  [15:0] au_disp;
    wire [19:0] au_phys_addr;
    wire [15:0] au_eff_offset;
    wire        au_uses_bp;
    
    wire [15:0] push_sp_target = sp - 16'd2;

    reg [3:0] exec_substate;
    reg       retired_flag;
    reg [15:0] xchg_tmp;
    
    localparam [3:0] 
        EX_START      = 4'd0, 
        EX_IMM2       = 4'd1, 
        EX_MODRM      = 4'd2,
        EX_DISP8      = 4'd3,
        EX_DISP16_L   = 4'd4,
        EX_DISP16_H   = 4'd5,
        EX_EA_CALC    = 4'd6,
        EX_MEM_WAIT   = 4'd7,
        EX_DO         = 4'd8,
        EX_PUSH_SETUP = 4'd9,
        EX_POP_WAIT   = 4'd10,
        EX_POP_FINISH = 4'd11,
        EX_CALL_SETUP = 4'd12,
        EX_RET_WAIT   = 4'd13,
        EX_XCHG_FIN   = 4'd14;

    wire is_modrm_op = (dec_operation == 6'd10 || dec_operation == 6'd11 || 
                        dec_operation == 6'd15 || dec_operation == 6'd16 || 
                        dec_operation == 6'd17 || dec_operation == 6'd18 || 
                        dec_operation == 6'd19);

    wire [2:0] dst_code = (opcode_reg[1] == 1'b1) ? modrm_reg[5:3] : modrm_reg[2:0];
    wire [2:0] src_code = (opcode_reg[1] == 1'b1) ? modrm_reg[2:0] : modrm_reg[5:3];

    // -------------------------------------------------------------------------
    // Combinational Logic blocks for Queue Popping
    // -------------------------------------------------------------------------
    reg do_pop;
    assign queue_pop = do_pop;

    always @(*) begin
        do_pop = 1'b0;
        if (cu_inst_take) begin
            do_pop = 1'b1;
        end else if (cu_state == 3'd2 && !exec_done) begin
            case (exec_substate)
                EX_START: begin
                    if (is_modrm_op) begin
                        if (!queue_empty) do_pop = 1'b1;
                    end else if (dec_length_hint > 3'd1) begin
                        if (!queue_empty) do_pop = 1'b1;
                    end
                end
                EX_IMM2: begin
                    if (!queue_empty) do_pop = 1'b1;
                end
                EX_DISP8: begin
                    if (!queue_empty) do_pop = 1'b1;
                end
                EX_DISP16_L: begin
                    if (!queue_empty) do_pop = 1'b1;
                end
                EX_DISP16_H: begin
                    if (!queue_empty) do_pop = 1'b1;
                end
                default: do_pop = 1'b0;
            endcase
        end
    end
    
    // ALU Input Combinational Multiplexing
    always @(*) begin
        alu_a_comb      = 16'b0;
        alu_b_comb      = 16'b0;
        alu_op_comb     = 4'h0;
        alu_width8_comb = 1'b0;
        alu_cin_comb    = cf;

        case (dec_operation)
            6'd3: begin // ADDI
                alu_op_comb     = 4'h0;
                alu_width8_comb = ~opcode_reg[0];
                alu_a_comb      = opcode_reg[0] ? ax : {8'b0, ax[7:0]};
                alu_b_comb      = opcode_reg[0] ? imm16_reg : {8'b0, imm16_reg[7:0]};
            end
            6'd14: begin // SUBI
                alu_op_comb     = 4'h2;
                alu_width8_comb = ~opcode_reg[0];
                alu_a_comb      = opcode_reg[0] ? ax : {8'b0, ax[7:0]};
                alu_b_comb      = opcode_reg[0] ? imm16_reg : {8'b0, imm16_reg[7:0]};
            end
            6'd32: begin // CMPI
                alu_op_comb     = 4'h2;
                alu_width8_comb = ~opcode_reg[0];
                alu_a_comb      = opcode_reg[0] ? ax : {8'b0, ax[7:0]};
                alu_b_comb      = opcode_reg[0] ? imm16_reg : {8'b0, imm16_reg[7:0]};
            end
            6'd33: begin // ANDI
                alu_op_comb     = 4'h4;
                alu_width8_comb = ~opcode_reg[0];
                alu_a_comb      = opcode_reg[0] ? ax : {8'b0, ax[7:0]};
                alu_b_comb      = opcode_reg[0] ? imm16_reg : {8'b0, imm16_reg[7:0]};
            end
            6'd34: begin // ORI
                alu_op_comb     = 4'h5;
                alu_width8_comb = ~opcode_reg[0];
                alu_a_comb      = opcode_reg[0] ? ax : {8'b0, ax[7:0]};
                alu_b_comb      = opcode_reg[0] ? imm16_reg : {8'b0, imm16_reg[7:0]};
            end
            6'd35: begin // XORI
                alu_op_comb     = 4'h6;
                alu_width8_comb = ~opcode_reg[0];
                alu_a_comb      = opcode_reg[0] ? ax : {8'b0, ax[7:0]};
                alu_b_comb      = opcode_reg[0] ? imm16_reg : {8'b0, imm16_reg[7:0]};
            end
            6'd11, 6'd15, 6'd16, 6'd17, 6'd18, 6'd19: begin // ADD, SUB, CMP, AND, OR, XOR
                case (dec_operation)
                    6'd11: alu_op_comb = 4'h0; // ADD
                    6'd15: alu_op_comb = 4'h2; // SUB
                    6'd16: alu_op_comb = 4'h2; // CMP
                    6'd17: alu_op_comb = 4'h4; // AND
                    6'd18: alu_op_comb = 4'h5; // OR
                    6'd19: alu_op_comb = 4'h6; // XOR
                    default: alu_op_comb = 4'h0;
                endcase
                alu_width8_comb = ~opcode_reg[0];
                if (exec_substate == EX_MEM_WAIT) begin
                    alu_a_comb = opcode_reg[0] ? get_reg16(modrm_reg[5:3]) : {8'b0, get_reg8(modrm_reg[5:3])};
                    alu_b_comb = opcode_reg[0] ? mem_rdata : {8'b0, mem_rdata[7:0]};
                end else begin
                    alu_a_comb = opcode_reg[0] ? get_reg16(dst_code) : {8'b0, get_reg8(dst_code)};
                    alu_b_comb = opcode_reg[0] ? get_reg16(src_code) : {8'b0, get_reg8(src_code)};
                end
            end
            6'd20: begin // INC
                alu_op_comb     = 4'h0;
                alu_width8_comb = 1'b0;
                alu_a_comb      = get_reg16(opcode_reg[2:0]);
                alu_b_comb      = 16'd1;
            end
            6'd21: begin // DEC
                alu_op_comb     = 4'h2;
                alu_width8_comb = 1'b0;
                alu_a_comb      = get_reg16(opcode_reg[2:0]);
                alu_b_comb      = 16'd1;
            end
            default: ;
        endcase
    end

    // -------------------------------------------------------------------------
    // Sequential State Machine
    // -------------------------------------------------------------------------
    always @(posedge clk) begin
        if (reset) begin
            redirect         <= 1'b0;
            redirect_ip      <= 16'b0;
            mem_req          <= 1'b0;
            mem_write        <= 1'b0;
            mem_addr         <= 20'b0;
            mem_wdata        <= 16'b0;
            mem_word         <= 1'b0;
            illegal_opcode   <= 1'b0;
            offending_opcode <= 8'b0;
            ip_out           <= 16'b0;
            retired          <= 32'b0;
            
            rf_we            <= 1'b0;
            rf_byte_mode     <= 1'b0;
            rf_write_reg     <= 3'd0;
            rf_byte_reg      <= 4'd0;
            rf_write_data    <= 16'd0;
            rf_byte_data     <= 8'd0;
            
            exec_done        <= 1'b0;
            halted_in        <= 1'b0;
            exec_substate    <= EX_START;
            retired_flag     <= 1'b0;
            xchg_tmp         <= 16'b0;
            
            au_rm   <= 3'b0;
            au_mod  <= 2'b0;
            au_disp <= 16'b0;
            
            cf <= 0; pf <= 0; af <= 0; zf <= 0; sf <= 0; oflag <= 0;
        end else begin
            redirect     <= 1'b0;
            rf_we        <= 1'b0;
            rf_byte_mode <= 1'b0;

            // 1. Fetch Phase
            if (cu_inst_take) begin
                opcode_reg <= instruction_byte;
                ip_out     <= ip_out + 1'b1;
            end 
            
            // 2. Decode Phase
            else if (cu_state == 3'd1) begin
                if (!dec_supported) begin
                    illegal_opcode   <= 1'b1;
                    offending_opcode <= opcode_reg;
                    halted_in        <= 1'b1;
                end
            end
            
            // 3. Execute Phase 
            else if (cu_state == 3'd2) begin 
                if (!exec_done) begin 
                    case (exec_substate)
                        EX_START: begin
                            if (is_modrm_op) begin
                                if (!queue_empty) begin
                                    modrm_reg     <= instruction_byte;
                                    ip_out        <= ip_out + 1'b1;
                                    exec_substate <= EX_MODRM;
                                end
                            end 
                            else if (dec_operation == 6'd12) begin // PUSH
                                exec_substate <= EX_PUSH_SETUP;
                            end
                            else if (dec_operation == 6'd13) begin // POP
                                mem_req       <= 1'b1;
                                mem_write     <= 1'b0;
                                mem_word      <= 1'b1;
                                mem_addr      <= {ss_val, 4'h0} + {4'h0, sp}; 
                                exec_substate <= EX_POP_WAIT;
                            end
                            else if (dec_operation == 6'd23) begin // RET
                                mem_req       <= 1'b1;
                                mem_write     <= 1'b0;
                                mem_word      <= 1'b1;
                                mem_addr      <= {ss_val, 4'h0} + {4'h0, sp}; 
                                exec_substate <= EX_RET_WAIT;
                            end
                            else if (dec_length_hint > 3'd1) begin
                                if (!queue_empty) begin
                                    imm16_reg[7:0] <= instruction_byte;
                                    ip_out         <= ip_out + 1'b1;
                                    exec_substate  <= (dec_length_hint == 3'd3) ? EX_IMM2 : EX_DO;
                                end
                            end else begin
                                exec_substate <= EX_DO;
                            end
                        end
                        
                        EX_IMM2: begin
                            if (!queue_empty) begin
                                imm16_reg[15:8] <= instruction_byte;
                                ip_out          <= ip_out + 1'b1;
                                if (dec_operation == 6'd22) begin // CALL
                                    exec_substate <= EX_CALL_SETUP;
                                end else begin
                                    exec_substate <= EX_DO;
                                end
                            end
                        end

                        EX_MODRM: begin
                            au_mod <= modrm_reg[7:6];
                            au_rm  <= modrm_reg[2:0];
                            if (modrm_reg[7:6] == 2'b01) exec_substate <= EX_DISP8;
                            else if (modrm_reg[7:6] == 2'b10 || (modrm_reg[7:6] == 2'b00 && modrm_reg[2:0] == 3'b110)) exec_substate <= EX_DISP16_L;
                            else exec_substate <= EX_EA_CALC;
                        end

                        EX_DISP8: begin
                            if (!queue_empty) begin
                                au_disp       <= {{8{instruction_byte[7]}}, instruction_byte}; 
                                ip_out        <= ip_out + 1'b1;
                                exec_substate <= EX_EA_CALC;
                            end
                        end
                        
                        EX_DISP16_L: begin
                            if (!queue_empty) begin
                                au_disp[7:0]  <= instruction_byte;
                                ip_out        <= ip_out + 1'b1;
                                exec_substate <= EX_DISP16_H;
                            end
                        end

                        EX_DISP16_H: begin
                            if (!queue_empty) begin
                                au_disp[15:8] <= instruction_byte;
                                ip_out        <= ip_out + 1'b1;
                                exec_substate <= EX_EA_CALC;
                            end
                        end

                        EX_EA_CALC: begin
                            if (au_mod != 2'b11) begin 
                                mem_req   <= 1'b1;
                                mem_addr  <= au_phys_addr;
                                mem_word  <= opcode_reg[0]; 
                                if (opcode_reg[1] == 1'b0) begin 
                                    mem_write <= 1'b1;
                                    mem_wdata <= opcode_reg[0] ? get_reg16(modrm_reg[5:3]) : {8'b0, get_reg8(modrm_reg[5:3])};
                                end else begin
                                    mem_write <= 1'b0; 
                                end
                                exec_substate <= EX_MEM_WAIT;
                            end else begin
                                exec_substate <= EX_DO; 
                            end
                        end

                        EX_MEM_WAIT: begin
                            if (mem_ready) begin
                                mem_req   <= 1'b0;
                                mem_write <= 1'b0;
                                if (dec_operation == 6'd22) begin // CALL complete
                                    redirect    <= 1'b1;
                                    redirect_ip <= ip_out + imm16_reg;
                                    ip_out      <= ip_out + imm16_reg;
                                end
                                else if (dec_operation == 6'd10 && opcode_reg[1] == 1'b1) begin // MOV reg, mem
                                    if (opcode_reg[0]) begin
                                        rf_we         <= 1'b1;
                                        rf_write_reg  <= modrm_reg[5:3];
                                        rf_write_data <= mem_rdata;
                                    end else begin
                                        rf_byte_mode  <= 1'b1;
                                        rf_byte_reg   <= {1'b0, modrm_reg[5:3]};
                                        rf_byte_data  <= mem_rdata[7:0];
                                    end
                                end
                                else if (is_modrm_op && opcode_reg[1] == 1'b1) begin // ALU reg, mem
                                    if (dec_operation != 6'd16) begin // Not CMP
                                        if (opcode_reg[0]) begin
                                            rf_we         <= 1'b1;
                                            rf_write_reg  <= modrm_reg[5:3];
                                            rf_write_data <= alu_result;
                                        end else begin
                                            rf_byte_mode  <= 1'b1;
                                            rf_byte_reg   <= {1'b0, modrm_reg[5:3]};
                                            rf_byte_data  <= alu_result[7:0];
                                        end
                                    end
                                    oflag <= alu_flags[5]; sf <= alu_flags[4];
                                    zf    <= alu_flags[3]; af <= alu_flags[2];
                                    pf    <= alu_flags[1]; cf <= alu_flags[0];
                                end
                                exec_done <= 1'b1;
                            end
                        end
                        
                        EX_PUSH_SETUP: begin
                            mem_req       <= 1'b1;
                            mem_write     <= 1'b1;
                            mem_word      <= 1'b1;
                            mem_addr      <= {ss_val, 4'h0} + {4'h0, push_sp_target}; 
                            mem_wdata     <= get_reg16(opcode_reg[2:0]); 
                            rf_we         <= 1'b1;
                            rf_byte_mode  <= 1'b0;
                            rf_write_reg  <= 3'd4;
                            rf_write_data <= push_sp_target;
                            exec_substate <= EX_MEM_WAIT;
                        end
                        
                        EX_POP_WAIT: begin
                            if (mem_ready) begin
                                mem_req       <= 1'b0;
                                rf_we         <= 1'b1;
                                rf_byte_mode  <= 1'b0;
                                rf_write_reg  <= opcode_reg[2:0]; 
                                rf_write_data <= mem_rdata;
                                exec_substate <= EX_POP_FINISH;
                            end
                        end
                        
                        EX_POP_FINISH: begin
                            rf_we         <= 1'b1;
                            rf_byte_mode  <= 1'b0;
                            rf_write_reg  <= 3'd4;
                            rf_write_data <= sp + 16'd2;
                            exec_done     <= 1'b1;
                        end

                        EX_CALL_SETUP: begin
                            mem_req       <= 1'b1;
                            mem_write     <= 1'b1;
                            mem_word      <= 1'b1;
                            mem_addr      <= {ss_val, 4'h0} + {4'h0, push_sp_target}; 
                            mem_wdata     <= ip_out; 
                            rf_we         <= 1'b1;
                            rf_byte_mode  <= 1'b0;
                            rf_write_reg  <= 3'd4;
                            rf_write_data <= push_sp_target;
                            exec_substate <= EX_MEM_WAIT;
                        end

                        EX_RET_WAIT: begin
                            if (mem_ready) begin
                                mem_req       <= 1'b0;
                                redirect      <= 1'b1;
                                redirect_ip   <= mem_rdata;
                                ip_out        <= mem_rdata;
                                rf_we         <= 1'b1;
                                rf_byte_mode  <= 1'b0;
                                rf_write_reg  <= 3'd4;
                                rf_write_data <= sp + 16'd2;
                                exec_done     <= 1'b1;
                            end
                        end
                        
                        EX_XCHG_FIN: begin
                            rf_we         <= 1'b1;
                            rf_byte_mode  <= 1'b0;
                            rf_write_reg  <= opcode_reg[2:0];
                            rf_write_data <= xchg_tmp;
                            exec_done     <= 1'b1;
                        end

                        EX_DO: begin
                            case (dec_operation)
                                6'd0: begin /* OP_NOP */ end
                                6'd1: halted_in <= 1'b1; // OP_HLT
                                
                                6'd2: begin // OP_MOVI
                                    if (opcode_reg[3] == 1'b0) begin 
                                        rf_byte_mode <= 1'b1;
                                        rf_byte_reg  <= {1'b0, opcode_reg[2:0]};
                                        rf_byte_data <= imm16_reg[7:0];
                                    end else begin 
                                        rf_we         <= 1'b1;
                                        rf_write_reg  <= opcode_reg[2:0];
                                        rf_write_data <= imm16_reg;
                                    end
                                end
                                
                                6'd3, 6'd14, 6'd32, 6'd33, 6'd34, 6'd35: begin // ADDI, SUBI, CMPI, ANDI, ORI, XORI
                                    if (dec_operation != 6'd32) begin // Not CMPI
                                        if (opcode_reg[0] == 1'b0) begin 
                                            rf_byte_mode <= 1'b1;
                                            rf_byte_reg  <= 4'd0; 
                                            rf_byte_data <= alu_result[7:0];
                                        end else begin 
                                            rf_we         <= 1'b1;
                                            rf_write_reg  <= 3'd0; 
                                            rf_write_data <= alu_result;
                                        end
                                    end
                                    oflag <= alu_flags[5]; sf <= alu_flags[4];
                                    zf    <= alu_flags[3]; af <= alu_flags[2];
                                    pf    <= alu_flags[1]; cf <= alu_flags[0];
                                end
                                
                                6'd4: begin // OP_JMP8
                                    redirect    <= 1'b1;
                                    redirect_ip <= ip_out + {{8{imm16_reg[7]}}, imm16_reg[7:0]};
                                    ip_out      <= ip_out + {{8{imm16_reg[7]}}, imm16_reg[7:0]};
                                end
                                
                                6'd5: begin // OP_JMP16
                                    redirect    <= 1'b1;
                                    redirect_ip <= ip_out + imm16_reg;
                                    ip_out      <= ip_out + imm16_reg;
                                end
                                
                                6'd6: begin // OP_JZ
                                    if (zf) begin
                                        redirect    <= 1'b1;
                                        redirect_ip <= ip_out + {{8{imm16_reg[7]}}, imm16_reg[7:0]};
                                        ip_out      <= ip_out + {{8{imm16_reg[7]}}, imm16_reg[7:0]};
                                    end
                                end
                                
                                6'd7: begin // OP_JNZ
                                    if (!zf) begin
                                        redirect    <= 1'b1;
                                        redirect_ip <= ip_out + {{8{imm16_reg[7]}}, imm16_reg[7:0]};
                                        ip_out      <= ip_out + {{8{imm16_reg[7]}}, imm16_reg[7:0]};
                                    end
                                end
                                
                                6'd24: begin // OP_JC
                                    if (cf) begin
                                        redirect    <= 1'b1;
                                        redirect_ip <= ip_out + {{8{imm16_reg[7]}}, imm16_reg[7:0]};
                                        ip_out      <= ip_out + {{8{imm16_reg[7]}}, imm16_reg[7:0]};
                                    end
                                end

                                6'd25: begin // OP_JNC
                                    if (!cf) begin
                                        redirect    <= 1'b1;
                                        redirect_ip <= ip_out + {{8{imm16_reg[7]}}, imm16_reg[7:0]};
                                        ip_out      <= ip_out + {{8{imm16_reg[7]}}, imm16_reg[7:0]};
                                    end
                                end

                                6'd26: begin // OP_JS
                                    if (sf) begin
                                        redirect    <= 1'b1;
                                        redirect_ip <= ip_out + {{8{imm16_reg[7]}}, imm16_reg[7:0]};
                                        ip_out      <= ip_out + {{8{imm16_reg[7]}}, imm16_reg[7:0]};
                                    end
                                end

                                6'd27: begin // OP_JNS
                                    if (!sf) begin
                                        redirect    <= 1'b1;
                                        redirect_ip <= ip_out + {{8{imm16_reg[7]}}, imm16_reg[7:0]};
                                        ip_out      <= ip_out + {{8{imm16_reg[7]}}, imm16_reg[7:0]};
                                    end
                                end

                                6'd28: begin // OP_JO
                                    if (oflag) begin
                                        redirect    <= 1'b1;
                                        redirect_ip <= ip_out + {{8{imm16_reg[7]}}, imm16_reg[7:0]};
                                        ip_out      <= ip_out + {{8{imm16_reg[7]}}, imm16_reg[7:0]};
                                    end
                                end

                                6'd29: begin // OP_JNO
                                    if (!oflag) begin
                                        redirect    <= 1'b1;
                                        redirect_ip <= ip_out + {{8{imm16_reg[7]}}, imm16_reg[7:0]};
                                        ip_out      <= ip_out + {{8{imm16_reg[7]}}, imm16_reg[7:0]};
                                    end
                                end
                                
                                6'd8:  cf <= 1'b0; // OP_CLC
                                6'd9:  cf <= 1'b1; // OP_STC
                                6'd30: cf <= ~cf;  // OP_CMC
                                
                                6'd10: begin // OP_MOV_RR
                                    if (au_mod == 2'b11) begin
                                        if (opcode_reg[0]) begin // Word
                                            rf_we         <= 1'b1;
                                            rf_write_reg  <= dst_code;
                                            rf_write_data <= get_reg16(src_code);
                                        end else begin // Byte
                                            rf_byte_mode <= 1'b1;
                                            rf_byte_reg  <= {1'b0, dst_code};
                                            rf_byte_data <= get_reg8(src_code);
                                        end
                                    end
                                end
                                
                                6'd11, 6'd15, 6'd16, 6'd17, 6'd18, 6'd19: begin // ADD, SUB, CMP, AND, OR, XOR (RR)
                                    if (au_mod == 2'b11) begin
                                        if (dec_operation != 6'd16) begin // Not CMP
                                            if (opcode_reg[0]) begin // Word
                                                rf_we         <= 1'b1;
                                                rf_write_reg  <= dst_code;
                                                rf_write_data <= alu_result;
                                            end else begin // Byte
                                                rf_byte_mode <= 1'b1;
                                                rf_byte_reg  <= {1'b0, dst_code};
                                                rf_byte_data <= alu_result[7:0];
                                            end
                                        end
                                        oflag <= alu_flags[5]; sf <= alu_flags[4];
                                        zf    <= alu_flags[3]; af <= alu_flags[2];
                                        pf    <= alu_flags[1]; cf <= alu_flags[0];
                                    end
                                end

                                6'd20, 6'd21: begin // INC, DEC reg16
                                    rf_we         <= 1'b1;
                                    rf_write_reg  <= opcode_reg[2:0];
                                    rf_write_data <= alu_result;
                                    oflag <= alu_flags[5]; sf <= alu_flags[4];
                                    zf    <= alu_flags[3]; af <= alu_flags[2];
                                    pf    <= alu_flags[1]; // CF preserved!
                                end

                                6'd31: begin // OP_XCHG_AX
                                    xchg_tmp      <= ax;
                                    rf_we         <= 1'b1;
                                    rf_write_reg  <= 3'd0;
                                    rf_write_data <= get_reg16(opcode_reg[2:0]);
                                    exec_substate <= EX_XCHG_FIN;
                                end
                                
                                default: begin
                                    illegal_opcode   <= 1'b1;
                                    offending_opcode <= opcode_reg;
                                    halted_in        <= 1'b1;
                                end
                            endcase
                            
                            if (dec_operation != 6'd31) begin
                                exec_done <= 1'b1; 
                            end
                        end
                    endcase
                end
            end 
            
            // 4. Retire Phase
            else if (cu_state == 3'd3) begin 
                exec_done     <= 1'b0;
                exec_substate <= EX_START;
                if (!retired_flag) begin
                    retired      <= retired + 1'b1;
                    retired_flag <= 1'b1;
                end
            end else begin
                exec_done    <= 1'b0;
                retired_flag <= 1'b0;
            end
        end
    end

    decoder_8086 inst_decoder (
        .opcode       (opcode_reg),
        .operation    (dec_operation),
        .supported    (dec_supported),
        .length_hint  (dec_length_hint)
    );

    alu_8086 inst_alu (
        .a            (alu_a_comb),
        .b            (alu_b_comb),
        .operation    (alu_op_comb),
        .width8       (alu_width8_comb),
        .carry_in     (alu_cin_comb),
        .result       (alu_result),
        .flags        (alu_flags)
    );

    register_file_8086 inst_rf (
        .clk          (clk),
        .reset        (reset),
        .read_a       (3'd0),
        .read_b       (3'd0),
        .data_a       (),
        .data_b       (),
        .write_enable (rf_we),
        .write_reg    (rf_write_reg),
        .write_data   (rf_write_data),
        .byte_mode    (rf_byte_mode),
        .byte_data    (rf_byte_data),
        .byte_reg     (rf_byte_reg),
        .seg_read     (au_uses_bp ? 3'b010 : 3'b011), 
        .seg_data     (),
        .seg_write    (1'b0),
        .seg_wreg     (2'b0), 
        .seg_wdata    (16'b0),
        .ax(ax), .bx(bx), .cx(cx), .dx(dx),
        .sp(sp), .bp(bp), .si(si), .di(di),
        .cs(cs_val), .ds(ds_val), .ss(ss_val), .es(es_val)
    );

    address_unit_8086 inst_au (
        .segment          (au_uses_bp ? ss_val : ds_val), 
        .offset           (au_eff_offset),                 
        .physical_address (au_phys_addr),
        .rm               (au_rm),
        .mod_field        (au_mod),
        .bx               (bx),
        .bp               (bp),
        .si               (si),
        .di               (di),
        .displacement     (au_disp),
        .effective_offset (au_eff_offset),
        .uses_bp          (au_uses_bp)
    );

endmodule
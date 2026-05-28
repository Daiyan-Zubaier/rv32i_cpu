module rv32i_core
  import rv32i_pkg::*;
#(
  parameter int unsigned ImemDepth = 1024,
  parameter int unsigned DmemDepth = 1024,
  parameter string ProgramPath = ""
) (
  input logic clk_i,
  input logic rst_ni
);
  localparam logic [1:0] WbSelMem = 2'b00;
  localparam logic [1:0] WbSelPc4 = 2'b10;

  logic [31:0] next_pc;
  logic [31:0] current_pc;
  logic [31:0] pc_plus_4;
  logic [31:0] pc_target;
  logic pc_sel;
  logic pc_en;

  logic [31:0] inst /*verilator public_flat_rd*/;

  if_id_t if_id_d;
  if_id_t if_id_q;
  logic if_id_en;
  logic if_id_flush;

  id_ex_t id_ex_d;
  id_ex_t id_ex_q;
  logic id_ex_flush;

  ex_mem_t ex_mem_d;
  ex_mem_t ex_mem_q;

  mem_wb_t mem_wb_d;
  mem_wb_t mem_wb_q;

  // Wires for instruction decode stage (ID)
  logic [4:0] id_rs1;
  logic [4:0] id_rs2;
  logic [4:0] id_rd;
  logic id_uses_rs1;
  logic id_uses_rs2;
  opcode_e id_opcode;
  logic id_reg_write_en;
  logic id_branch_unsigned;
  logic id_a_sel;
  logic id_b_sel;
  logic id_mem_write_en;
  logic [1:0] id_wb_sel;
  inst_type_e id_imm_sel;
  alu_op_e id_alu_sel;
  logic [31:0] id_data_a;
  logic [31:0] id_data_b;
  logic [31:0] id_imm;

  // Wires for execute stage (EX)
  logic [31:0] ex_data_a;
  logic [31:0] ex_data_b;
  logic [31:0] ex_mem_forward_data;
  logic [31:0] alu_input_a;
  logic [31:0] alu_input_b;
  logic [31:0] alu_result;
  logic ex_branch_lt;
  logic ex_branch_eq;
  logic ex_branch_taken;
  opcode_e ex_opcode;

  logic mem_write_en /*verilator public_flat_rd*/;
  logic [31:0] data_r;

  logic reg_write_en;
  logic [1:0] wb_sel /*verilator public_flat_rd*/;
  logic [31:0] wb;

  logic load_use_hazard;

  assign pc_plus_4 = current_pc + 32'd4;
  assign id_rs1 = if_id_q.inst[19:15];
  assign id_rs2 = if_id_q.inst[24:20];
  assign id_rd = if_id_q.inst[11:7];
  assign id_opcode = opcode_e'(if_id_q.inst[6:0]);
  assign ex_opcode = opcode_e'(id_ex_q.inst[6:0]);

  // combinational logic to determine which opcodes use rs1, rs2, and/or rd
  always_comb begin
    id_uses_rs1 = 1'b0;
    id_uses_rs2 = 1'b0;

    if (if_id_q.valid) begin
      unique case (id_opcode)
        OPCODE_OP: begin
          id_uses_rs1 = 1'b1;
          id_uses_rs2 = 1'b1;
        end

        OPCODE_OP_IMM, OPCODE_LOAD, OPCODE_JALR: begin
          id_uses_rs1 = 1'b1;
        end

        OPCODE_STORE, OPCODE_BRANCH: begin
          id_uses_rs1 = 1'b1;
          id_uses_rs2 = 1'b1;
        end

        default: begin
          // No source registers used
        end
      endcase
    end
  end

  /*
   * If the load instruction writes to a register that another opp needs for the EX stage,
   * with no WX forwarding we don't have access to a correct value, so for now we check if we have a
   * lw instruction in EX and an instruction like add in ID. If it is, we stall the add instruction
   */
  assign load_use_hazard =
      id_ex_q.valid && id_ex_q.reg_write_en && (id_ex_q.wb_sel == WbSelMem) &&
      (id_ex_q.rd != 5'd0) &&
      ((id_uses_rs1 && (id_ex_q.rd == id_rs1)) || (id_uses_rs2 && (id_ex_q.rd == id_rs2)));

  assign pc_en = !load_use_hazard || pc_sel;
  assign if_id_en = !load_use_hazard || pc_sel;
  assign if_id_flush = pc_sel;
  assign id_ex_flush = pc_sel || load_use_hazard;

  assign pc_target = (ex_opcode == OPCODE_JALR) ? {alu_result[31:1], 1'b0} : alu_result;
  assign next_pc = pc_sel ? pc_target : pc_plus_4;

  rv32i_pc_reg u_pc_reg (
    .next_pc_i(next_pc),
    .en_i(pc_en),
    .clk_i(clk_i),
    .rst_ni(rst_ni),
    .pc_o(current_pc)
  );

  rv32i_imem #(
    .Depth(ImemDepth),
    .ProgramPath(ProgramPath)
  ) u_imem (
    .addr_i(current_pc),
    .inst_o(inst)
  );

  always_comb begin
    if_id_d = '0;
    if_id_d.valid = 1'b1;          // Always 1 for next value
    if_id_d.pc = current_pc;
    if_id_d.pc_plus_4 = pc_plus_4;
    if_id_d.inst = inst;
  end

  rv32i_pipeline_register #(
    .DataT(if_id_t)
  ) u_if_id_reg (
    .clk_i(clk_i),
    .rst_ni(rst_ni),
    .en_i(if_id_en),
    .flush_i(if_id_flush),
    .d_i(if_id_d),
    .q_o(if_id_q)
  );

  rv32i_regfile u_regfile (
    .addr_a_i(id_rs1),
    .addr_b_i(id_rs2),
    .addr_d_i(mem_wb_q.rd),
    .data_d_i(wb),
    .reg_write_en_i(reg_write_en),
    .clk_i(clk_i),
    .data_a_o(id_data_a),
    .data_b_o(id_data_b)
  );

  rv32i_control_logic u_control_logic (
    .inst_i(if_id_q.inst),
    .imm_sel_o(id_imm_sel),
    .reg_w_en_o(id_reg_write_en),
    .br_unsign_o(id_branch_unsigned),
    .b_sel_o(id_b_sel),
    .a_sel_o(id_a_sel),
    .alu_sel_o(id_alu_sel),
    .mem_write_en_o(id_mem_write_en),
    .wb_sel_o(id_wb_sel)
  );

  always_comb begin
    id_ex_d = '0;
    id_ex_d.valid = if_id_q.valid;
    id_ex_d.pc = if_id_q.pc;
    id_ex_d.inst = if_id_q.inst;
    id_ex_d.pc_plus_4 = if_id_q.pc_plus_4;
    id_ex_d.data_a = id_data_a;
    id_ex_d.data_b = id_data_b;
    id_ex_d.imm = id_imm;
    id_ex_d.imm_sel = id_imm_sel;
    id_ex_d.rs1 = id_rs1;
    id_ex_d.rs2 = id_rs2;
    id_ex_d.rd = id_rd;
    id_ex_d.branch_unsigned = id_branch_unsigned;
    id_ex_d.a_sel = id_a_sel;
    id_ex_d.b_sel = id_b_sel;
    id_ex_d.alu_sel = id_alu_sel;
    id_ex_d.reg_write_en = id_reg_write_en;
    id_ex_d.mem_write_en = id_mem_write_en;
    id_ex_d.wb_sel = id_wb_sel;
  end

  rv32i_pipeline_register #(
    .DataT(id_ex_t)
  ) u_id_ex_reg (
    .clk_i(clk_i),
    .rst_ni(rst_ni),
    .en_i(1'b1),
    .flush_i(id_ex_flush),
    .d_i(id_ex_d),
    .q_o(id_ex_q)
  );

  rv32i_imm_gen u_imm_gen (
    .inst_i(if_id_q.inst[31:7]),
    .imm_sel_i(id_imm_sel),
    .imm_o(id_imm)
  );

  /*
   * Forwarding, handles MX + WX.
   * Case 1:
   * #1: add x1, x2, x3   IF  ID  EX  M  WB
   * #2: add x4, x1, x5       IF  ID  EX* M  WB
   * In instruction 2's EX stage, we clearly need the value from instruction 1's alu output
   *
   * Case 2:
   * #1: jal  x5, next
   * next:
   * #2: addi x6, x5, 8
   * Again same scenario, we need the data stored in x5 (pc+4) for the second instruction
   *
   * In other words, we need to forward when ex_mem_q.rd == id_ex_q.rs1/rs2, and we're writing back alu_result or pc+4 (wb_sel is useful)
   *
   * The WX is for case 1, where let's say there's an instruction in the middle, then when #1 is in WB, #2 needs data in EX
   */
  assign ex_mem_forward_data = (ex_mem_q.wb_sel == WbSelPc4) ? ex_mem_q.pc_plus_4 :
                               ex_mem_q.alu_result;

  always_comb begin
    ex_data_a = id_ex_q.data_a;
    ex_data_b = id_ex_q.data_b;

    if (ex_mem_q.valid && ex_mem_q.reg_write_en && (ex_mem_q.wb_sel != WbSelMem) &&
        (ex_mem_q.rd != 5'd0) && (ex_mem_q.rd == id_ex_q.rs1)) begin
      ex_data_a = ex_mem_forward_data;
    end else if (mem_wb_q.valid && mem_wb_q.reg_write_en && (mem_wb_q.rd != 5'd0) &&
                 (mem_wb_q.rd == id_ex_q.rs1)) begin
      ex_data_a = wb;
    end

    if (ex_mem_q.valid && ex_mem_q.reg_write_en && (ex_mem_q.wb_sel != WbSelMem) &&
        (ex_mem_q.rd != 5'd0) && (ex_mem_q.rd == id_ex_q.rs2)) begin
      ex_data_b = ex_mem_forward_data;
    end else if (mem_wb_q.valid && mem_wb_q.reg_write_en && (mem_wb_q.rd != 5'd0) &&
                 (mem_wb_q.rd == id_ex_q.rs2)) begin
      ex_data_b = wb;
    end
  end

  rv32i_branch_comp u_branch_comp (
    .a_i(ex_data_a),
    .b_i(ex_data_b),
    .branch_unsigned_i(id_ex_q.branch_unsigned),
    .branch_lt_o(ex_branch_lt),
    .branch_eq_o(ex_branch_eq)
  );

  assign alu_input_a = id_ex_q.a_sel ? id_ex_q.pc : ex_data_a;
  assign alu_input_b = id_ex_q.b_sel ? id_ex_q.imm : ex_data_b;

  rv32i_alu u_alu (
    .operand_a_i(alu_input_a),
    .operand_b_i(alu_input_b),
    .alu_sel_i(id_ex_q.alu_sel),
    .result_o(alu_result)
  );

  rv32i_branch_director u_branch_director (
    .opcode_i(ex_opcode),
    .funct3_i(id_ex_q.inst[14:12]),
    .branch_eq_i(ex_branch_eq),
    .branch_lt_i(ex_branch_lt),
    .branch_taken_o(ex_branch_taken)
  );

  assign pc_sel = id_ex_q.valid && ex_branch_taken;

  always_comb begin
    ex_mem_d = '0;
    ex_mem_d.valid = id_ex_q.valid;
    ex_mem_d.pc_plus_4 = id_ex_q.pc_plus_4;
    ex_mem_d.alu_result = alu_result;
    ex_mem_d.data_b = ex_data_b;
    ex_mem_d.rd = id_ex_q.rd;
    ex_mem_d.funct3 = id_ex_q.inst[14:12];
    ex_mem_d.reg_write_en = id_ex_q.reg_write_en;
    ex_mem_d.mem_write_en = id_ex_q.mem_write_en;
    ex_mem_d.wb_sel = id_ex_q.wb_sel;
  end

  rv32i_pipeline_register #(
    .DataT(ex_mem_t)
  ) u_ex_mem_reg (
    .clk_i(clk_i),
    .rst_ni(rst_ni),
    .en_i(1'b1),
    .flush_i(1'b0),
    .d_i(ex_mem_d),
    .q_o(ex_mem_q)
  );

  assign mem_write_en = ex_mem_q.valid && ex_mem_q.mem_write_en;

  rv32i_dmem #(
    .Depth(DmemDepth)
  ) u_dmem (
    .addr_i(ex_mem_q.alu_result),
    .data_w_i(ex_mem_q.data_b),
    .funct3_i(ex_mem_q.funct3),
    .mem_write_en_i(mem_write_en),
    .clk_i(clk_i),
    .data_r_o(data_r)
  );

  always_comb begin
    mem_wb_d = '0;
    mem_wb_d.valid = ex_mem_q.valid;
    mem_wb_d.pc_plus_4 = ex_mem_q.pc_plus_4;
    mem_wb_d.alu_result = ex_mem_q.alu_result;
    mem_wb_d.data_r = data_r;
    mem_wb_d.rd = ex_mem_q.rd;
    mem_wb_d.reg_write_en = ex_mem_q.reg_write_en;
    mem_wb_d.wb_sel = ex_mem_q.wb_sel;
  end

  rv32i_pipeline_register #(
    .DataT(mem_wb_t)
  ) u_mem_wb_reg (
    .clk_i(clk_i),
    .rst_ni(rst_ni),
    .en_i(1'b1),
    .flush_i(1'b0),
    .d_i(mem_wb_d),
    .q_o(mem_wb_q)
  );

  assign reg_write_en = mem_wb_q.valid && mem_wb_q.reg_write_en;
  assign wb_sel = mem_wb_q.wb_sel;

  rv32i_mux #(
    .Width(32),
    .Inputs(4)
  ) u_wb_mux (
    .in_i({32'b0, mem_wb_q.pc_plus_4, mem_wb_q.alu_result, mem_wb_q.data_r}),
    .sel_i(wb_sel),
    .out_o(wb)
  );

endmodule : rv32i_core

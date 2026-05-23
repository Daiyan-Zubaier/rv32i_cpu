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
  logic [31:0] next_pc;
  logic [31:0] current_pc;
  logic [31:0] pc_plus_4;
  logic [31:0] pc_target;
  logic pc_sel;

  logic [31:0] inst;
  logic reg_write_en;

  logic [31:0] data_a;
  logic [31:0] data_b;

  logic branch_un;
  logic branch_lt;
  logic branch_eq;

  logic a_sel;
  logic b_sel;

  inst_type_e imm_sel;
  logic [31:0] imm;

  logic [31:0] alu_input_a;
  logic [31:0] alu_input_b;
  alu_op_e alu_sel;
  logic [31:0] alu_result;

  logic mem_write_en;
  logic [31:0] data_r;

  logic [1:0] wb_sel;
  logic [31:0] wb;

  assign pc_plus_4 = current_pc + 32'd4;
  assign pc_target = (inst[6:0] == OPCODE_JALR) ? {alu_result[31:1], 1'b0} : alu_result;

  rv32i_mux #(
    .Width(32),
    .Inputs(2)
  ) u_pc_mux (
    .in_i({pc_target, pc_plus_4}),
    .sel_i(pc_sel),
    .out_o(next_pc)
  );

  rv32i_pc_reg u_pc_reg (
    .next_pc_i(next_pc),
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

  rv32i_regfile u_regfile (
    .addr_a_i(inst[19:15]),
    .addr_b_i(inst[24:20]),
    .addr_d_i(inst[11:7]),
    .data_d_i(wb),
    .reg_write_en_i(reg_write_en),
    .clk_i(clk_i),
    .data_a_o(data_a),
    .data_b_o(data_b)
  );

  rv32i_branch_comp u_branch_comp (
    .a_i(data_a),
    .b_i(data_b),
    .branch_unsigned_i(branch_un),
    .branch_lt_o(branch_lt),
    .branch_eq_o(branch_eq)
  );

  rv32i_imm_gen u_imm_gen (
    .inst_i(inst[31:7]),
    .imm_sel_i(imm_sel),
    .imm_o(imm)
  );

  rv32i_mux #(
    .Width(32),
    .Inputs(2)
  ) u_alu_input_a_mux (
    .in_i({current_pc, data_a}),
    .sel_i(a_sel),
    .out_o(alu_input_a)
  );

  rv32i_mux #(
    .Width(32),
    .Inputs(2)
  ) u_alu_input_b_mux (
    .in_i({imm, data_b}),
    .sel_i(b_sel),
    .out_o(alu_input_b)
  );

  rv32i_alu u_alu (
    .operand_a_i(alu_input_a),
    .operand_b_i(alu_input_b),
    .alu_sel_i(alu_sel),
    .result_o(alu_result)
  );

  rv32i_dmem #(
    .Depth(DmemDepth)
  ) u_dmem (
    .addr_i(alu_result),
    .data_w_i(data_b),
    .funct3_i(inst[14:12]),
    .mem_write_en_i(mem_write_en),
    .clk_i(clk_i),
    .data_r_o(data_r)
  );

  rv32i_mux #(
    .Width(32),
    .Inputs(3)
  ) u_wb_mux (
    .in_i({pc_plus_4, alu_result, data_r}),
    .sel_i(wb_sel),
    .out_o(wb)
  );

  rv32i_control_logic u_control_logic (
    .inst_i(inst[31:0]),
    .br_eq_i(branch_eq),
    .br_lt_i(branch_lt),
    .pc_sel_o(pc_sel),
    .imm_sel_o(imm_sel),
    .reg_w_en_o(reg_write_en),
    .br_unsign_o(branch_un),
    .b_sel_o(b_sel),
    .a_sel_o(a_sel),
    .alu_sel_o(alu_sel),
    .mem_write_en_o(mem_write_en),
    .wb_sel_o(wb_sel)
  );
endmodule : rv32i_core

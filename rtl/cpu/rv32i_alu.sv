module rv32i_alu
  import rv32i_pkg::*;
(
  input logic [31:0] operand_a_i,
  input logic [31:0] operand_b_i,
  input alu_op_e     alu_sel_i,

  output logic [31:0] result_o
);
  always_comb begin
    unique case (alu_sel_i)
      ALU_ADD:    result_o = operand_a_i + operand_b_i;
      ALU_SUB:    result_o = operand_a_i - operand_b_i;
      ALU_AND:    result_o = operand_a_i & operand_b_i;
      ALU_OR:     result_o = operand_a_i | operand_b_i;
      ALU_XOR:    result_o = operand_a_i ^ operand_b_i;
      ALU_SLL:    result_o = operand_a_i << operand_b_i[4:0];
      ALU_SRL:    result_o = operand_a_i >> operand_b_i[4:0];
      ALU_SRA:    result_o = $signed(operand_a_i) >>> operand_b_i[4:0];
      ALU_SLT:    result_o = ($signed(operand_a_i) < $signed(operand_b_i)) ? 32'd1 : 32'd0;
      ALU_SLTU:   result_o = (operand_a_i < operand_b_i) ? 32'd1 : 32'd0;
      ALU_PASS_A: result_o = operand_a_i;
      ALU_PASS_B: result_o = operand_b_i;
      default:   result_o = 32'd0;
    endcase
  end

endmodule : rv32i_alu

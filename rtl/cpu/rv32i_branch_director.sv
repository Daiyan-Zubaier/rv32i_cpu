module rv32i_branch_director
  import rv32i_pkg::*;
(
  input opcode_e     opcode_i,
  input logic [2:0]  funct3_i,
  input logic        branch_eq_i,
  input logic        branch_lt_i,

  output logic       branch_taken_o
);
  always_comb begin
    branch_taken_o = 1'b0;

    unique case (opcode_i)
      OPCODE_BRANCH: begin
        unique case (funct3_i)
          3'h0: branch_taken_o = branch_eq_i;
          3'h1: branch_taken_o = !branch_eq_i;
          3'h4, 3'h6: branch_taken_o = branch_lt_i;
          3'h5, 3'h7: branch_taken_o = !branch_lt_i;
          default: branch_taken_o = 1'b0;
        endcase
      end
      OPCODE_JAL, OPCODE_JALR: begin
        branch_taken_o = 1'b1;
      end
      default: begin
        branch_taken_o = 1'b0;
      end
    endcase
  end
endmodule : rv32i_branch_director

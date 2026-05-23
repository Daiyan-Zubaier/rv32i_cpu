module rv32i_branch_comp (
  input logic [31:0] a_i,
  input logic [31:0] b_i,
  input logic        branch_unsigned_i,

  output logic branch_lt_o,
  output logic branch_eq_o
);
  always_comb begin
    branch_eq_o = a_i == b_i;
    if (branch_unsigned_i) begin
      branch_lt_o = a_i < b_i;
    end else begin
      branch_lt_o = $signed(a_i) < $signed(b_i);
    end

  end

endmodule : rv32i_branch_comp

module rv32i_pc_reg (
  input logic [31:0]  next_pc_i,
  input logic         clk_i,
  input logic         rst_ni,

  output logic [31:0] pc_o
);
  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) pc_o <= 32'd0;
    else         pc_o <= next_pc_i;
  end

endmodule : rv32i_pc_reg

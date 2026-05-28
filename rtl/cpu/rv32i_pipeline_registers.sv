module rv32i_pipeline_register
  import rv32i_pkg::*;
#(
  parameter type DataT = logic [31:0]
) (
  input logic clk_i,
  input logic rst_ni,
  input logic en_i,
  input logic flush_i,
  input DataT d_i,

  output DataT q_o
);
  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      q_o <= '0;
    end else if (flush_i) begin
      q_o <= '0;
    end else if (en_i) begin
      q_o <= d_i;
    end
  end

endmodule : rv32i_pipeline_register

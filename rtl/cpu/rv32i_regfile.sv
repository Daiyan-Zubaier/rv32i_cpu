module rv32i_regfile (
  input logic [4:0]   addr_a_i,
  input logic [4:0]   addr_b_i,
  input logic [4:0]   addr_d_i,
  input logic [31:0]  data_d_i,
  input logic         reg_write_en_i,
  input logic         clk_i,

  output logic [31:0] data_a_o,
  output logic [31:0] data_b_o
);
  logic [31:0] registers[32];

  // Sloppy could change
  assign data_a_o = (addr_a_i == 0) ? 32'h0 : registers[addr_a_i];
  assign data_b_o = (addr_b_i == 0) ? 32'h0 : registers[addr_b_i];

  always_ff @(posedge clk_i) begin
    if (reg_write_en_i && addr_d_i != 5'd0) begin
      registers[addr_d_i] <= data_d_i;
    end
  end

endmodule : rv32i_regfile

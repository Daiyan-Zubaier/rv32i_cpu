// N to 1 mux
module rv32i_mux #(
  parameter int unsigned Width = 32,
  parameter int unsigned Inputs = 2
) (
  input logic [Inputs-1:0][Width-1:0] in_i,
  input logic [$clog2(Inputs)-1:0]    sel_i,

  output logic [Width-1:0] out_o
);
  assign out_o = in_i[sel_i];

endmodule : rv32i_mux

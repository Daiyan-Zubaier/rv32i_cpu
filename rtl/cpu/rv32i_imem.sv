module rv32i_imem #(
  parameter int unsigned Depth = 1024,
  parameter string ProgramPath = "programs/imem_smoke.S"
) (
  input logic [31:0] addr_i,

  output logic [31:0] inst_o
);
  logic [31:0] mem[Depth];
  logic [$clog2(Depth)-1:0] word_addr;
  logic unused_addr;

  assign word_addr = addr_i[$clog2(Depth)+1:2];
  assign unused_addr = ^{addr_i[31:$clog2(Depth)+2], addr_i[1:0]};
  assign inst_o = mem[word_addr];

  initial begin
    if (ProgramPath != "") begin
      $readmemh(ProgramPath, mem);
    end
  end

endmodule : rv32i_imem

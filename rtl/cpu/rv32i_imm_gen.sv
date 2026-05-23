module rv32i_imm_gen
  import rv32i_pkg::*;
(
  input logic [24:0]  inst_i,
  input inst_type_e   imm_sel_i,

  output logic [31:0] imm_o
);
  always_comb begin
    unique case (imm_sel_i)
      // {20{inst_i[24]}} is for sign extending
      R_TYPE: imm_o = 32'd0;
      I_TYPE: imm_o = {{20{inst_i[24]}}, inst_i[24:13]};
      S_TYPE: imm_o = {{20{inst_i[24]}}, inst_i[24:18], inst_i[4:0]};
      B_TYPE: imm_o = {{19{inst_i[24]}}, inst_i[24], inst_i[0], inst_i[23:18], inst_i[4:1], 1'b0};
      U_TYPE: imm_o = {inst_i[24:5], 12'h000};
      J_TYPE: imm_o = {{11{inst_i[24]}}, inst_i[24], inst_i[12:5], inst_i[13], inst_i[23:14], 1'b0};
      default: imm_o = 32'd0;
    endcase
  end

endmodule : rv32i_imm_gen

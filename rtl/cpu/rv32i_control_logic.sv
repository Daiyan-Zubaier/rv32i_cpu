module rv32i_control_logic
  import rv32i_pkg::*;
(
  input logic [31:0]  inst_i,
  input logic         br_eq_i,
  input logic         br_lt_i,

  output logic        pc_sel_o,
  output inst_type_e  imm_sel_o,
  output logic        reg_w_en_o,
  output logic        br_unsign_o,
  output logic        b_sel_o,
  output logic        a_sel_o,
  output alu_op_e     alu_sel_o,
  output logic        mem_write_en_o,
  output logic [1:0]  wb_sel_o
);
  opcode_e opcode;
  logic funct_7;
  logic [2:0] funct_3;
  logic unused_inst;

  assign opcode = opcode_e'(inst_i[6:0]);
  assign funct_7 = inst_i[30];  // Going for the important bit
  assign funct_3 = inst_i[14:12];
  assign unused_inst = ^{inst_i[31], inst_i[29:15], inst_i[11:7]};

  always_comb begin
    pc_sel_o = 1'b0;
    imm_sel_o = R_TYPE;
    reg_w_en_o = 1'b0;
    br_unsign_o = 1'b0;
    b_sel_o = 1'b0;
    a_sel_o = 1'b0;
    alu_sel_o = ALU_ADD;
    mem_write_en_o = 1'b0;
    wb_sel_o = 2'b01;

    unique case (opcode)
      OPCODE_OP: begin
        imm_sel_o = R_TYPE;
        reg_w_en_o = 1'b1;
        a_sel_o = 1'b0;
        b_sel_o = 1'b0;
        wb_sel_o = 2'b01;

        unique case (funct_3)
          3'h0: alu_sel_o = !funct_7 ? ALU_ADD : ALU_SUB;
          3'h4: alu_sel_o = ALU_XOR;
          3'h6: alu_sel_o = ALU_OR;
          3'h7: alu_sel_o = ALU_AND;
          3'h1: alu_sel_o = ALU_SLL;
          3'h5: alu_sel_o = !funct_7 ? ALU_SRL : ALU_SRA;
          3'h2: alu_sel_o = ALU_SLT;
          3'h3: alu_sel_o = ALU_SLTU;
          default: begin
            // do nothing
          end
        endcase
      end
      OPCODE_OP_IMM: begin
        imm_sel_o = I_TYPE;
        reg_w_en_o = 1'b1;
        a_sel_o = 1'b0;
        b_sel_o = 1'b1;
        wb_sel_o = 2'b01;

        unique case (funct_3)
          3'h0: alu_sel_o = ALU_ADD;
          3'h4: alu_sel_o = ALU_XOR;
          3'h6: alu_sel_o = ALU_OR;
          3'h7: alu_sel_o = ALU_AND;
          3'h1: alu_sel_o = ALU_SLL;
          3'h5: alu_sel_o = !funct_7 ? ALU_SRL : ALU_SRA;
          3'h2: alu_sel_o = ALU_SLT;
          3'h3: alu_sel_o = ALU_SLTU;
          default: begin
            // do nothing
          end
        endcase
      end
      OPCODE_LOAD: begin
        imm_sel_o = I_TYPE;
        reg_w_en_o = 1'b1;
        a_sel_o = 1'b0;
        b_sel_o = 1'b1;
        alu_sel_o = ALU_ADD;
        wb_sel_o = 2'b00;
      end
      OPCODE_STORE: begin
        imm_sel_o = S_TYPE;
        a_sel_o = 1'b0;
        b_sel_o = 1'b1;
        alu_sel_o = ALU_ADD;
        mem_write_en_o = 1'b1;
      end
      OPCODE_BRANCH: begin
        imm_sel_o = B_TYPE;
        a_sel_o = 1'b1;
        b_sel_o = 1'b1;
        alu_sel_o = ALU_ADD;

        unique case (funct_3)
          3'h0: pc_sel_o = br_eq_i;
          3'h1: pc_sel_o = !br_eq_i;
          3'h4: pc_sel_o = br_lt_i;
          3'h5: pc_sel_o = !br_lt_i;
          3'h6: begin
            br_unsign_o = 1'b1;
            pc_sel_o = br_lt_i;
          end
          3'h7: begin
            br_unsign_o = 1'b1;
            pc_sel_o = !br_lt_i;
          end
          default: begin
            // do nothing
          end
        endcase
      end
      OPCODE_JAL: begin
        pc_sel_o = 1'b1;
        imm_sel_o = J_TYPE;
        reg_w_en_o = 1'b1;
        a_sel_o = 1'b1;
        b_sel_o = 1'b1;
        alu_sel_o = ALU_ADD;
        wb_sel_o = 2'b10;
      end
      OPCODE_JALR: begin
        pc_sel_o = 1'b1;
        imm_sel_o = I_TYPE;
        reg_w_en_o = 1'b1;
        a_sel_o = 1'b0;
        b_sel_o = 1'b1;
        alu_sel_o = ALU_ADD;
        wb_sel_o = 2'b10;
      end
      OPCODE_LUI: begin
        imm_sel_o = U_TYPE;
        reg_w_en_o = 1'b1;
        b_sel_o = 1'b1;
        alu_sel_o = ALU_PASS_B;
        wb_sel_o = 2'b01;
      end
      OPCODE_AUIPC: begin
        imm_sel_o = U_TYPE;
        reg_w_en_o = 1'b1;
        a_sel_o = 1'b1;
        b_sel_o = 1'b1;
        alu_sel_o = ALU_ADD;
        wb_sel_o = 2'b01;
      end
      OPCODE_SYSTEM: begin
        imm_sel_o = I_TYPE;
        alu_sel_o = ALU_ADD;
      end
      default: begin
        // do nothing
      end
    endcase
  end
endmodule : rv32i_control_logic

package rv32i_pkg;
  typedef enum logic [3:0] {
    ALU_ADD  = 4'd0,
    ALU_SUB  = 4'd1,
    ALU_AND  = 4'd2,
    ALU_OR   = 4'd3,
    ALU_XOR  = 4'd4,
    ALU_SLL  = 4'd5,
    ALU_SRL  = 4'd6,
    ALU_SRA  = 4'd7,
    ALU_SLT  = 4'd8,
    ALU_SLTU = 4'd9,
    ALU_PASS_A = 4'd10,
    ALU_PASS_B = 4'd11
  } alu_op_e;

  typedef enum logic [2:0] {
    R_TYPE = 3'd0,
    I_TYPE = 3'd1,
    S_TYPE = 3'd2,
    B_TYPE = 3'd3,
    U_TYPE = 3'd4,
    J_TYPE = 3'd5
  } inst_type_e;

  typedef enum logic [6:0] {
    OPCODE_OP       = 7'b0110011,  // add, sub, xor, or, and, sll, srl, sra, slt, sltu
    OPCODE_OP_IMM   = 7'b0010011,  // addi, xori, ori, andi, slli, srli, srai, slti, sltiu
    OPCODE_LOAD     = 7'b0000011,  // lb, lh, lw, lbu, lhu
    OPCODE_STORE    = 7'b0100011,  // sb, sh, sw
    OPCODE_BRANCH   = 7'b1100011,  // beq, bne, blt, bge, bltu, bgeu
    OPCODE_JAL      = 7'b1101111,  // jal
    OPCODE_JALR     = 7'b1100111,  // jalr
    OPCODE_LUI      = 7'b0110111,  // lui
    OPCODE_AUIPC    = 7'b0010111,  // auipc
    OPCODE_SYSTEM   = 7'b1110011   // ecall, ebreak (csr ops added later)
  } opcode_e;
endpackage : rv32i_pkg

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

  /*
   * ===============================
   * Pipeline register defintions
   * ===============================
  */
  typedef struct packed {
    logic        valid;
    logic [31:0] pc;
    logic [31:0] pc_plus_4;
    logic [31:0] inst;
  } if_id_t;

  typedef struct packed {
    logic        valid;
    logic [31:0] pc;
    logic [31:0] inst;
    inst_type_e  imm_sel;
    logic [31:0] pc_plus_4;
    logic [31:0] data_a;
    logic [31:0] data_b;
    logic [31:0] imm;
    logic [4:0]  rs1;
    logic [4:0]  rs2;
    logic [4:0]  rd;
    logic        branch_unsigned;
    logic        a_sel;
    logic        b_sel;
    alu_op_e     alu_sel;
    logic        reg_write_en;
    logic        mem_write_en;
    logic [1:0]  wb_sel;
  } id_ex_t;

  typedef struct packed {
    logic        valid;
    logic [31:0] pc_plus_4;
    logic [31:0] alu_result;
    logic [31:0] data_b;
    logic [4:0]  rd;
    logic [2:0]  funct3;
    logic        reg_write_en;
    logic        mem_write_en;
    logic [1:0]  wb_sel;
  } ex_mem_t;

  typedef struct packed {
    logic        valid;
    logic [31:0] pc_plus_4;
    logic [31:0] alu_result;
    logic [31:0] data_r;
    logic [4:0]  rd;
    logic        reg_write_en;
    logic [1:0]  wb_sel;
  } mem_wb_t;

endpackage : rv32i_pkg

#include <verilated.h>

#include <cstdint>
#include <iostream>
#include <string>

#include "Vrv32i_control_logic.h"

// static hack
namespace {
constexpr uint8_t kAluAdd = 0;
constexpr uint8_t kAluSub = 1;
constexpr uint8_t kAluXor = 4;

constexpr uint8_t kRType = 0;
constexpr uint8_t kIType = 1;
constexpr uint8_t kSType = 2;
constexpr uint8_t kBType = 3;
constexpr uint8_t kJType = 5;

constexpr uint8_t kOpcodeOp = 0b0110011;
constexpr uint8_t kOpcodeOpImm = 0b0010011;
constexpr uint8_t kOpcodeLoad = 0b0000011;
constexpr uint8_t kOpcodeStore = 0b0100011;
constexpr uint8_t kOpcodeBranch = 0b1100011;
constexpr uint8_t kOpcodeJal = 0b1101111;

uint32_t r_inst(uint8_t funct7, uint8_t funct3) {
  return (static_cast<uint32_t>(funct7) << 25) | (2u << 20) | (1u << 15) | (static_cast<uint32_t>(funct3) << 12) | (3u << 7) | kOpcodeOp;
}

uint32_t i_inst(uint8_t funct3, uint8_t opcode) {
  return (1u << 20) | (1u << 15) | (static_cast<uint32_t>(funct3) << 12) | (3u << 7) | opcode;
}

uint32_t s_inst(uint8_t funct3) {
  return (2u << 20) | (1u << 15) | (static_cast<uint32_t>(funct3) << 12) | kOpcodeStore;
}

uint32_t b_inst(uint8_t funct3) {
  return (2u << 20) | (1u << 15) | (static_cast<uint32_t>(funct3) << 12) | kOpcodeBranch;
}

bool check_eq(const std::string &test_name, const std::string &signal_name, uint32_t actual, uint32_t expected) {
  if (actual == expected) {
    return true;
  }

  std::cerr << test_name << ": " << signal_name << " mismatch. expected=0x" << std::hex << expected << " actual=0x" << actual << std::dec << "\n";
  return false;
}

bool check_outputs(Vrv32i_control_logic &dut, const std::string &name, uint8_t exp_imm_sel, uint8_t exp_reg_w_en, uint8_t exp_br_unsign, uint8_t exp_a_sel, uint8_t exp_b_sel,
                   uint8_t exp_alu_sel, uint8_t exp_mem_write_en, uint8_t exp_wb_sel) {
  dut.eval();

  bool pass = true;
  pass &= check_eq(name, "imm_sel_o", dut.imm_sel_o, exp_imm_sel);
  pass &= check_eq(name, "reg_w_en_o", dut.reg_w_en_o, exp_reg_w_en);
  pass &= check_eq(name, "br_unsign_o", dut.br_unsign_o, exp_br_unsign);
  pass &= check_eq(name, "a_sel_o", dut.a_sel_o, exp_a_sel);
  pass &= check_eq(name, "b_sel_o", dut.b_sel_o, exp_b_sel);
  pass &= check_eq(name, "alu_sel_o", dut.alu_sel_o, exp_alu_sel);
  pass &= check_eq(name, "mem_write_en_o", dut.mem_write_en_o, exp_mem_write_en);
  pass &= check_eq(name, "wb_sel_o", dut.wb_sel_o, exp_wb_sel);
  return pass;
}
}  // namespace

int main(int argc, char **argv) {
  Verilated::commandArgs(argc, argv);

  Vrv32i_control_logic dut;
  bool pass = true;

  dut.inst_i = r_inst(0b0000000, 0x0);
  pass &= check_outputs(dut, "add", kRType, 1, 0, 0, 0, kAluAdd, 0, 0b01);

  dut.inst_i = r_inst(0b0100000, 0x0);
  pass &= check_outputs(dut, "sub", kRType, 1, 0, 0, 0, kAluSub, 0, 0b01);

  dut.inst_i = i_inst(0x0, kOpcodeOpImm);
  pass &= check_outputs(dut, "addi", kIType, 1, 0, 0, 1, kAluAdd, 0, 0b01);

  dut.inst_i = i_inst(0x4, kOpcodeOpImm);
  pass &= check_outputs(dut, "xori", kIType, 1, 0, 0, 1, kAluXor, 0, 0b01);

  dut.inst_i = i_inst(0x2, kOpcodeLoad);
  pass &= check_outputs(dut, "lw", kIType, 1, 0, 0, 1, kAluAdd, 0, 0b00);

  dut.inst_i = s_inst(0x2);
  pass &= check_outputs(dut, "sw", kSType, 0, 0, 0, 1, kAluAdd, 1, 0b01);

  dut.inst_i = b_inst(0x0);
  pass &= check_outputs(dut, "beq", kBType, 0, 0, 1, 1, kAluAdd, 0, 0b01);

  dut.inst_i = (1u << 15) | kOpcodeJal;
  pass &= check_outputs(dut, "jal", kJType, 1, 0, 1, 1, kAluAdd, 0, 0b10);

  dut.final();

  if (!pass) {
    return 1;
  }

  std::cout << "tb_rv32i_control_logic.cpp passed\n";
  return 0;
}

#include <cstdint>
#include <iostream>
#include <random>
#include <string>

#include "Vrv32i_alu.h"
#include "verilated.h"

namespace {
enum AluOperation : uint8_t {
  ALU_ADD = 0,
  ALU_SUB = 1,
  ALU_AND = 2,
  ALU_OR = 3,
  ALU_XOR = 4,
  ALU_SLL = 5,
  ALU_SRL = 6,
  ALU_SRA = 7,
  ALU_SLT = 8,
  ALU_SLTU = 9,
  ALU_PASS_A = 10,
  ALU_PASS_B = 11,
};

constexpr uint32_t kRandomIterations = 1000;

uint32_t arithmetic_shift_right(uint32_t operand_a, uint32_t shift_amount) {
  shift_amount &= 0x1f;

  if (shift_amount == 0) {
    return operand_a;
  }

  uint32_t shifted = operand_a >> shift_amount;
  if ((operand_a & 0x8000'0000) == 0) {
    return shifted;
  }

  uint32_t sign_mask = 0xffff'ffff << (32 - shift_amount);
  return shifted | sign_mask;
}

uint32_t expected_result(uint32_t operand_a, uint32_t operand_b, AluOperation alu_sel) {
  switch (alu_sel) {
    case ALU_ADD:
      return operand_a + operand_b;
    case ALU_SUB:
      return operand_a - operand_b;
    case ALU_AND:
      return operand_a & operand_b;
    case ALU_OR:
      return operand_a | operand_b;
    case ALU_XOR:
      return operand_a ^ operand_b;
    case ALU_SLL:
      return operand_a << (operand_b & 0x1f);
    case ALU_SRL:
      return operand_a >> (operand_b & 0x1f);
    case ALU_SRA:
      return arithmetic_shift_right(operand_a, operand_b);
    case ALU_SLT:
      return (static_cast<int32_t>(operand_a) < static_cast<int32_t>(operand_b)) ? 1 : 0;
    case ALU_SLTU:
      return (operand_a < operand_b) ? 1 : 0;
    case ALU_PASS_A:
      return operand_a;
    case ALU_PASS_B:
      return operand_b;
    default:
      return 0;
  }
}

bool check_eq(const std::string &test_name, uint32_t actual, uint32_t expected) {
  if (actual == expected) {
    return true;
  }

  std::cerr << test_name << " failed: expected=0x" << std::hex << expected << " actual=0x" << actual << std::dec << "\n";
  return false;
}

bool run_case(Vrv32i_alu &dut, const std::string &name, uint32_t operand_a, uint32_t operand_b, AluOperation alu_sel, uint32_t expected) {
  dut.operand_a_i = operand_a;
  dut.operand_b_i = operand_b;
  dut.alu_sel_i = alu_sel;
  dut.eval();

  return check_eq(name, dut.result_o, expected);
}

bool run_random_tests(Vrv32i_alu &dut) {
  std::mt19937 rng(0x5232'0001);
  std::uniform_int_distribution<uint32_t> operand_dist;

  bool pass = true;

  for (uint32_t iteration = 0; iteration < kRandomIterations; iteration++) {
    uint32_t operand_a = operand_dist(rng);
    uint32_t operand_b = operand_dist(rng);

    for (uint8_t alu_sel = ALU_ADD; alu_sel <= ALU_PASS_B; alu_sel++) {
      AluOperation operation = static_cast<AluOperation>(alu_sel);
      std::string name = "random iteration " + std::to_string(iteration) + " op " + std::to_string(alu_sel);

      pass &= run_case(dut, name, operand_a, operand_b, operation, expected_result(operand_a, operand_b, operation));
    }
  }

  return pass;
}
}  // namespace

int main(int argc, char **argv) {
  Verilated::commandArgs(argc, argv);

  Vrv32i_alu dut;
  bool pass = true;

  pass &= run_case(dut, "add", 5, 7, ALU_ADD, 12);
  pass &= run_case(dut, "sub", 5, 7, ALU_SUB, 0xffff'fffe);
  pass &= run_case(dut, "and", 5, 7, ALU_AND, 5);
  pass &= run_case(dut, "or", 5, 7, ALU_OR, 7);
  pass &= run_case(dut, "xor", 5, 7, ALU_XOR, 2);
  pass &= run_case(dut, "sll", 1, 3, ALU_SLL, 8);
  pass &= run_case(dut, "srl", 8, 1, ALU_SRL, 4);
  pass &= run_case(dut, "sra", 0xffff'fff8, 1, ALU_SRA, 0xffff'fffc);
  pass &= run_case(dut, "slt true", 0xffff'ffff, 1, ALU_SLT, 1);
  pass &= run_case(dut, "slt false", 1, 0xffff'ffff, ALU_SLT, 0);
  pass &= run_case(dut, "sltu true", 1, 0xffff'ffff, ALU_SLTU, 1);
  pass &= run_case(dut, "sltu false", 0xffff'ffff, 1, ALU_SLTU, 0);
  pass &= run_case(dut, "pass a", 0x1234'5678, 0, ALU_PASS_A, 0x1234'5678);
  pass &= run_case(dut, "pass b", 0, 0x89ab'cdef, ALU_PASS_B, 0x89ab'cdef);
  pass &= run_random_tests(dut);

  dut.final();

  if (!pass) {
    return 1;
  }

  std::cout << "tb_rv32i_alu.cpp passed\n";
  return 0;
}

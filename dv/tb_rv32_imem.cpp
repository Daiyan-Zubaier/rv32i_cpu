#include <verilated.h>

#include <array>
#include <cstdint>
#include <iostream>
#include <string>

#include "Vrv32i_imem.h"

/*
 * See programs/imem_smoke.S:
 *   addi x1, x0, 5
 *   ori  x2, x0, 7
 *   sll  x3, x1, x2
 *   sw   x3, 0(x0)
 *   jal  x0, halt
 */

// Not the best, could do some autogen, but too much work for a small project like this

namespace {
constexpr std::array<uint32_t, 5> kExpectedInstructions = {
  0x00500093,  // addi x1, x0, 5
  0x00706113,  // ori  x2, x0, 7
  0x002091b3,  // sll  x3, x1, x2
  0x00302023,  // sw   x3, 0(x0)
  0x0000006f,  // jal  x0, halt
};

bool check_eq(const std::string &test_name, uint32_t actual, uint32_t expected) {
  if (actual == expected) {
    return true;
  }

  std::cerr << test_name << " failed: expected=0x" << std::hex << expected << " actual=0x" << actual << std::dec << "\n";
  return false;
}

bool run_fetch_case(Vrv32i_imem &dut, const std::string &name, uint32_t addr, uint32_t expected) {
  dut.addr_i = addr;
  dut.eval();

  return check_eq(name, dut.inst_o, expected);
}
}  // namespace

int main(int argc, char **argv) {
  Verilated::commandArgs(argc, argv);

  Vrv32i_imem dut;
  bool pass = true;

  for (std::size_t i = 0; i < kExpectedInstructions.size(); i++) {
    pass &= run_fetch_case(dut, "fetch instruction " + std::to_string(i), static_cast<uint32_t>(i * 4), kExpectedInstructions[i]);
  }

  pass &= run_fetch_case(dut, "ignore byte offset bits", 0x00000002, kExpectedInstructions[0]);

  dut.final();

  if (!pass) {
    return 1;
  }

  std::cout << "tb_rv32_imem.cpp passed\n";
  return 0;
}

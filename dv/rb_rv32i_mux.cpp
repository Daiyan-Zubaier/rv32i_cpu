#include <array>
#include <cstdint>
#include <iostream>
#include <random>
#include <string>

#include "Vrv32i_mux.h"
#include "verilated.h"

namespace {
constexpr uint32_t kRandomIterations = 1000;

uint64_t pack_inputs(const std::array<uint32_t, 2> &inputs) {
  return (static_cast<uint64_t>(inputs[1]) << 32) | inputs[0];
}

bool check_eq(const std::string &test_name, uint32_t actual, uint32_t expected) {
  if (actual == expected) {
    return true;
  }

  std::cerr << test_name << " failed: expected=0x" << std::hex << expected << " actual=0x" << actual << std::dec << "\n";
  return false;
}

bool run_case(Vrv32i_mux &dut, const std::string &name, const std::array<uint32_t, 2> &inputs, uint8_t sel) {
  dut.in_i = pack_inputs(inputs);
  dut.sel_i = sel;
  dut.eval();

  return check_eq(name, dut.out_o, inputs[sel]);
}

bool run_random_tests(Vrv32i_mux &dut) {
  std::mt19937 rng(0x5232'0002);
  std::uniform_int_distribution<uint32_t> value_dist;

  bool pass = true;

  for (uint32_t iteration = 0; iteration < kRandomIterations; iteration++) {
    std::array<uint32_t, 2> inputs = {
      value_dist(rng),
      value_dist(rng),
    };

    pass &= run_case(dut, "random iteration " + std::to_string(iteration) + " sel 0", inputs, 0);
    pass &= run_case(dut, "random iteration " + std::to_string(iteration) + " sel 1", inputs, 1);
  }

  return pass;
}
}  // namespace

int main(int argc, char **argv) {
  Verilated::commandArgs(argc, argv);

  Vrv32i_mux dut;
  bool pass = true;

  pass &= run_case(dut, "select input 0", { 0x1111'2222, 0x3333'4444 }, 0);
  pass &= run_case(dut, "select input 1", { 0x1111'2222, 0x3333'4444 }, 1);
  pass &= run_case(dut, "zero input", { 0, 0xffff'ffff }, 0);
  pass &= run_case(dut, "all-ones input", { 0, 0xffff'ffff }, 1);
  pass &= run_random_tests(dut);

  dut.final();

  if (!pass) {
    return 1;
  }

  std::cout << "rb_rv32i_mux.cpp passed\n";
  return 0;
}

#include <verilated.h>

#include <cstdint>
#include <iostream>

#include "Vrv32i_core.h"
#include "Vrv32i_core___024root.h"
#include "verilated_vcd_c.h"

namespace {
constexpr uint32_t kMaxCycles = 20;

template <typename T>
unsigned signal_value(T value) {
  return static_cast<unsigned>(value);
}

void tick(Vrv32i_core &dut, VerilatedVcdC &trace, uint64_t &sim_time) {
  dut.clk_i = 0;
  dut.eval();
  trace.dump(sim_time++);

  dut.clk_i = 1;
  dut.eval();
  trace.dump(sim_time++);
}

void print_core_state(const Vrv32i_core &dut, uint32_t cycle) {
  const auto *root = dut.rootp;

  std::cout << "cycle=" << cycle << " pc=0x" << std::hex << root->rv32i_core__DOT__current_pc << " inst=0x" << root->rv32i_core__DOT__inst << std::dec
            << " pc_sel=" << signal_value(root->rv32i_core__DOT__pc_sel) << " reg_write_en=" << signal_value(root->rv32i_core__DOT__reg_write_en)
            << " mem_write_en=" << signal_value(root->rv32i_core__DOT__mem_write_en) << " wb_sel=" << signal_value(root->rv32i_core__DOT__wb_sel) << "\n";
}
}  // namespace

int main(int argc, char **argv) {
  Verilated::commandArgs(argc, argv);
  Verilated::traceEverOn(true);
  const bool print_core_trace = Verilated::commandArgsPlusMatch("print-core")[0] != '\0';

  Vrv32i_core dut;
  VerilatedVcdC trace;

  dut.trace(&trace, 99);
  trace.open("waves/rv32i_core.vcd");

  uint64_t sim_time = 0;

  dut.rst_ni = 0;
  tick(dut, trace, sim_time);
  tick(dut, trace, sim_time);

  dut.rst_ni = 1;
  for (uint32_t cycle = 0; cycle < kMaxCycles; cycle++) {
    tick(dut, trace, sim_time);
    if (print_core_trace) {
      print_core_state(dut, cycle);
    }
  }

  dut.final();
  trace.close();

  std::cout << "rv32i_core simulation finished. Waveform: waves/rv32i_core.vcd\n";
  return 0;
}

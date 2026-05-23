#include <verilated.h>

#include <array>
#include <cstdint>
#include <iostream>
#include <string>

#include "Vrv32i_dmem.h"

/**
 * Write the first three word addresses using sb, sh, and sw, then read each
 * address using lb, lh, lw, lbu, lhu, and an invalid/default funct3.
 */

namespace {
constexpr uint8_t kFunct3Lb = 0x0;
constexpr uint8_t kFunct3Lh = 0x1;
constexpr uint8_t kFunct3Lw = 0x2;
constexpr uint8_t kFunct3Invalid = 0x3;
constexpr uint8_t kFunct3Lbu = 0x4;
constexpr uint8_t kFunct3Lhu = 0x5;

constexpr uint8_t kFunct3Sb = 0x0;
constexpr uint8_t kFunct3Sh = 0x1;
constexpr uint8_t kFunct3Sw = 0x2;

struct ReadCase {
  const char *name;
  uint8_t funct3;
  uint32_t expected;
};

struct StoreCase {
  const char *name;
  uint32_t addr;
  uint8_t funct3;
  uint32_t data;
  std::array<ReadCase, 6> reads;
};

constexpr std::array<StoreCase, 3> kStoreCases = { {
    {
        "sb at word address 0",
        0x00000000,
        kFunct3Sb,
        0x00000080,
        { {
            { "lb", kFunct3Lb, 0xffffff80 },
            { "lh", kFunct3Lh, 0x00000080 },
            { "lw", kFunct3Lw, 0x00000080 },
            { "lbu", kFunct3Lbu, 0x00000080 },
            { "lhu", kFunct3Lhu, 0x00000080 },
            { "invalid", kFunct3Invalid, 0x00000000 },
        } },
    },
    {
        "sh at word address 1",
        0x00000004,
        kFunct3Sh,
        0x00008034,
        { {
            { "lb", kFunct3Lb, 0x00000034 },
            { "lh", kFunct3Lh, 0xffff8034 },
            { "lw", kFunct3Lw, 0x00008034 },
            { "lbu", kFunct3Lbu, 0x00000034 },
            { "lhu", kFunct3Lhu, 0x00008034 },
            { "invalid", kFunct3Invalid, 0x00000000 },
        } },
    },
    {
        "sw at word address 2",
        0x00000008,
        kFunct3Sw,
        0x89abcdef,
        { {
            { "lb", kFunct3Lb, 0xffffffef },
            { "lh", kFunct3Lh, 0xffffcdef },
            { "lw", kFunct3Lw, 0x89abcdef },
            { "lbu", kFunct3Lbu, 0x000000ef },
            { "lhu", kFunct3Lhu, 0x0000cdef },
            { "invalid", kFunct3Invalid, 0x00000000 },
        } },
    },
} };

bool check_eq(const std::string &test_name, uint32_t actual, uint32_t expected) {
  if (actual == expected) {
    return true;
  }

  std::cerr << test_name << " failed: expected=0x" << std::hex << expected << " actual=0x" << actual << std::dec << "\n";
  return false;
}

void tick(Vrv32i_dmem &dut) {
  dut.clk_i = 0;
  dut.eval();
  dut.clk_i = 1;
  dut.eval();
  dut.clk_i = 0;
  dut.eval();
}

void write_memory(Vrv32i_dmem &dut, uint32_t addr, uint8_t funct3, uint32_t data) {
  dut.addr_i = addr;
  dut.data_w_i = data;
  dut.funct3_i = funct3;
  dut.mem_write_en_i = 1;
  tick(dut);
  dut.mem_write_en_i = 0;
  dut.eval();
}

bool run_read_case(Vrv32i_dmem &dut, const std::string &test_name, uint32_t addr, uint8_t funct3, uint32_t expected) {
  dut.addr_i = addr;
  dut.data_w_i = 0;
  dut.funct3_i = funct3;
  dut.mem_write_en_i = 0;
  dut.eval();

  return check_eq(test_name, dut.data_r_o, expected);
}

}  // namespace

int main(int argc, char **argv) {
  Verilated::commandArgs(argc, argv);

  Vrv32i_dmem dut;
  bool pass = true;

  dut.clk_i = 0;
  dut.addr_i = 0;
  dut.data_w_i = 0;
  dut.funct3_i = 0;
  dut.mem_write_en_i = 0;
  dut.eval();

  for (const StoreCase &store_case : kStoreCases) {
    write_memory(dut, store_case.addr, kFunct3Sw, 0);
    write_memory(dut, store_case.addr, store_case.funct3, store_case.data);

    for (const ReadCase &read_case : store_case.reads) {
      pass &= run_read_case(dut, std::string(store_case.name) + " read " + read_case.name, store_case.addr, read_case.funct3, read_case.expected);
    }
  }

  dut.final();

  if (!pass) {
    return 1;
  }

  std::cout << "tb_rv32i_dmem.cpp passed\n";
  return 0;
}

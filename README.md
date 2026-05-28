# rv32i-cpu

A single-cycle RV32I processor in SystemVerilog, with the goal of pipelining and eventually targeting an FPGA (maybe). Code style follows the [lowRISC style guide](https://github.com/lowRISC/style-guides).

Simulation uses [Verilator](https://www.veripool.org/verilator/) and [GTKWave](https://gtkwave.sourceforge.net/) for viewing the resulting VCD waveforms. Testbenches are written as C++ harnesses around the Verilator-generated DUT, UVM was considered but skipped, as the methodology overhead isn't justified at this scale.

# Arch
Cool diagram I made!
![doc/rv32i_core.svg](doc/rv32i_core.svg)

## Profiler Results
```
Core profile: waves/rv32i_core.vcd
  cycles after reset: 220
  retired instructions: 104 total, 53 useful, 51 idle spin
  CPI / IPC: 2.1154 / 0.4727
  useful CPI / IPC: 1.2642 / 0.791
  issue-to-retire latency cycles: avg=3, min=3, max=3, samples=104
  events: load stalls=3, taken branches=56, mem writes=5, reg writes=85
  stage occupancy cycles: IF/ID=164, ID/EX=104, EX/MEM=104, MEM/WB=104
  retired classes: alu_imm=22, alu_reg=5, branch=14, jal=53, load=3, lui=2, store=5
```

# Sample Programs
Programs are written as bare-metal RV32I assembly and converted into Verilog
hex files for instruction memory.

## Build and Run

Prerequisites:
- Verilator
- GTKWave, for waveform viewing
- An RV32 bare-metal GCC toolchain. By default the Makefile expects `riscv64-unknown-elf-gcc` and `riscv64-unknown-elf-objcopy`.

Build the default sample program:
```sh
make program
```

Run the default sample program on the core:
```sh
make sim-program
```

Build and run a different assembly source:
```sh
make sim-program PROGRAM_SRC=programs/my_program.S
```

Or run an existing hex file directly:
```sh
make sim-core PROGRAM=programs/my_program.hex
```

Profile the default program:
```sh
make profile-core
```

Run the profiler with a shorter or longer post-reset simulation window:
```sh
make profile-core PROFILE_ARGS="--cycles 80"
```

Print the retired-instruction trace:
```sh
make profile-core PROFILE_ARGS="--trace"
```

Profile an existing VCD without rerunning simulation:
```sh
python3 tools/run_core_profile.py --skip-run --trace
```

Pass simulator plusargs directly:
```sh
make sim-program SIM_ARGS="+cycles=80 +print-core"
```

Waveforms are written to:
```text
waves/rv32i_core.raw.vcd
waves/rv32i_core.vcd
```

Use `waves/rv32i_core.vcd` for profiling and GTKWave.

The generated `.hex` file is loaded by `rv32i_imem` using `$readmemh`. The program is linked to start at address `0x0`, matching the core reset PC.

## Smoke Test

`smoke.S` / `smoke.hex` is a self-checking RV32I program for instruction memory. It covers:
- ALU register and immediate operations
- EX/MEM forwarding
- load-use stalls
- word, byte, and halfword data memory
- signed and unsigned branches
- jump flushing
- `lui`

Expected pass result:
- data memory word 0: `0x0000600d`
- data memory word 1: `0x00000152`

Expected fail result:
- data memory word 0: `0xffffffff`
- data memory word 1: small failing section ID

The profiler reports `idle spin` for retired halt-loop instructions after the smoke program has passed. For core performance, prefer the useful CPI/IPC numbers.

# TODO
Add WM forwarding. I was mostly looking at the waveforms to debug my core (checking pass and fail), should probably add in a tb to make it easier to debug.

I'd probably like to come back to this project and add in various peripherals that the cpu can use.

# rv32-cpu

A single-cycle RV32I processor in SystemVerilog, with the goal of pipelining and eventually targeting an FPGA. Code style follows the [lowRISC style guide](https://github.com/lowRISC/style-guides).

Simulation uses [Verilator](https://www.veripool.org/verilator/) and [GTKWave](https://gtkwave.sourceforge.net/) for viewing the resulting VCD waveforms. Testbenches are written as C++ harnesses around the Verilator-generated DUT, UVM was considered but skipped, as the methodology overhead isn't justified at this scale.

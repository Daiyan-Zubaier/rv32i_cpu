RTL_SOURCES = \
    rtl/cpu/rv32i_pkg.sv \
    rtl/cpu/rv32i_mux.sv \
    rtl/cpu/rv32i_pc_reg.sv \
    rtl/cpu/rv32i_imem.sv \
    rtl/cpu/rv32i_regfile.sv \
    rtl/cpu/rv32i_branch_comp.sv \
    rtl/cpu/rv32i_branch_director.sv \
    rtl/cpu/rv32i_imm_gen.sv \
    rtl/cpu/rv32i_alu.sv \
    rtl/cpu/rv32i_dmem.sv \
    rtl/cpu/rv32i_control_logic.sv \
    rtl/cpu/rv32i_pipeline_registers.sv \
    rtl/cpu/rv32i_core.sv

CONTROL_LOGIC_RTL_SOURCES = \
    rtl/cpu/rv32i_pkg.sv \
    rtl/cpu/rv32i_control_logic.sv

ALU_RTL_SOURCES = \
    rtl/cpu/rv32i_pkg.sv \
    rtl/cpu/rv32i_alu.sv

MUX_RTL_SOURCES = \
    rtl/cpu/rv32i_mux.sv

IMEM_RTL_SOURCES = \
		rtl/cpu/rv32i_imem.sv

DMEM_RTL_SOURCES = \
    rtl/cpu/rv32i_dmem.sv

RISCV_PREFIX ?= riscv64-unknown-elf
RISCV_GCC ?= $(RISCV_PREFIX)-gcc
RISCV_OBJCOPY ?= $(RISCV_PREFIX)-objcopy

PROGRAM_SRC ?= programs/smoke.S
PROGRAM_FROM_SRC = $(patsubst %.S,%.hex,$(PROGRAM_SRC))
PROGRAM ?= $(PROGRAM_FROM_SRC)
IMEM_PROGRAM_SRC ?= programs/imem_smoke.S
IMEM_PROGRAM = $(patsubst %.S,%.hex,$(IMEM_PROGRAM_SRC))

RISCV_ARCH ?= rv32i
RISCV_ABI ?= ilp32
RISCV_ASFLAGS ?= -march=$(RISCV_ARCH) -mabi=$(RISCV_ABI)
RISCV_LDFLAGS ?= -nostdlib -nostartfiles -Wl,-Ttext=0x0 -Wl,--no-relax -Wl,-e,_start
SIM_ARGS ?=

.PHONY: lint lint-alu lint-mux lint-control-logic program sim-program sim-alu sim-mux sim-control-logic sim-core sim-imem sim-dmem profile-core

lint:
	verilator --lint-only --timing --top-module rv32i_core $(RTL_SOURCES)

lint-control-logic:
	verilator --lint-only --timing --top-module rv32i_control_logic $(CONTROL_LOGIC_RTL_SOURCES)

lint-alu:
	verilator --lint-only --timing --top-module rv32i_alu $(ALU_RTL_SOURCES)

lint-mux:
	verilator --lint-only --timing --top-module rv32i_mux $(MUX_RTL_SOURCES)

program: $(PROGRAM)

%.elf: %.S
	$(RISCV_GCC) $(RISCV_ASFLAGS) $(RISCV_LDFLAGS) $< -o $@

%.hex: %.elf
	$(RISCV_OBJCOPY) -O verilog --verilog-data-width 4 -j .text $< $@
	chmod 0644 $@

sim-alu:
	verilator --cc --exe --build --timing --top-module rv32i_alu $(ALU_RTL_SOURCES) dv/tb_rv32i_alu.cpp
	./obj_dir/Vrv32i_alu

sim-mux:
	verilator --cc --exe --build --timing --top-module rv32i_mux $(MUX_RTL_SOURCES) dv/rb_rv32i_mux.cpp
	./obj_dir/Vrv32i_mux

sim-control-logic:
	verilator --cc --exe --build --timing --top-module rv32i_control_logic $(CONTROL_LOGIC_RTL_SOURCES) dv/tb_rv32i_control_logic.cpp
	./obj_dir/Vrv32i_control_logic

sim-program: PROGRAM = $(PROGRAM_FROM_SRC)
sim-program: sim-core

sim-core: $(PROGRAM)
	mkdir -p waves
	verilator --cc --exe --build --timing --trace --top-module rv32i_core -GProgramPath='"$(PROGRAM)"' $(RTL_SOURCES) dv/tb_rv32i_core.cpp
	./obj_dir/Vrv32i_core $(SIM_ARGS)
	python3 tools/dealias_vcd.py waves/rv32i_core.raw.vcd waves/rv32i_core.vcd

profile-core:
	python3 tools/run_core_profile.py --program $(PROGRAM) $(PROFILE_ARGS)

sim-imem: $(IMEM_PROGRAM)
	verilator --cc --exe --build --timing --top-module rv32i_imem -GProgramPath='"$(IMEM_PROGRAM)"' $(IMEM_RTL_SOURCES) dv/tb_rv32_imem.cpp
	./obj_dir/Vrv32i_imem

sim-dmem:
	verilator --cc --exe --build --timing --top-module rv32i_dmem $(DMEM_RTL_SOURCES) dv/tb_rv32i_dmem.cpp
	./obj_dir/Vrv32i_dmem

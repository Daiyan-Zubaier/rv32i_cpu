# Sample Programs

Programs are written as bare-metal RV32I assembly and converted into Verilog
hex files for instruction memory.

## Build and Run

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

The generated `.hex` file is loaded by `rv32i_imem` using `$readmemh`.
The program is linked to start at address `0x0`, matching the core reset PC.

## Smoke Test

`smoke.S` / `smoke.hex` is a tiny RV32I program for instruction memory:

```asm
addi x1, x0, 5
addi x2, x0, 7
add  x3, x1, x2
sw   x3, 0(x0)
halt:
jal  x0, halt
```

Expected result: data memory word 0 should become `12`.

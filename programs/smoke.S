.section .text
.globl _start

_start:
  addi x30, x0, 0

  # ALU operations and EX/MEM forwarding.
  addi x1, x0, 5
  addi x2, x0, 7
  add  x3, x1, x2
  addi x29, x0, 12
  bne  x3, x29, fail_alu

  sub  x4, x2, x1
  addi x29, x0, 2
  bne  x4, x29, fail_alu

  # Shift, logic, signed compare, and unsigned compare paths.
  slli x5, x1, 2
  srli x6, x5, 1
  addi x29, x0, 10
  bne  x6, x29, fail_shift

  addi x7, x0, -8
  srai x8, x7, 1
  addi x29, x0, -4
  bne  x8, x29, fail_shift

  andi x9, x5, 12
  ori  x10, x9, 3
  xori x11, x10, 2
  bne  x11, x1, fail_logic

  slt  x12, x7, x1
  sltu x13, x7, x1
  add  x14, x12, x13
  addi x29, x0, 1
  bne  x14, x29, fail_compare

  # Word, byte, and halfword memory. The checks after loads also exercise
  # the load-use stall path.
  sw   x3, 8(x0)
  lw   x15, 8(x0)
  addi x16, x15, 1
  addi x29, x0, 13
  bne  x16, x29, fail_mem

  sb   x3, 12(x0)
  lbu  x17, 12(x0)
  bne  x17, x3, fail_mem

  sh   x5, 16(x0)
  lhu  x18, 16(x0)
  bne  x18, x5, fail_mem

  # Taken and not-taken branches, including signed and unsigned compares.
  beq  x1, x2, fail_branch
  bne  x1, x2, branch_bne_ok
  jal  x0, fail_branch

branch_bne_ok:
  blt  x7, x1, branch_blt_ok
  jal  x0, fail_branch

branch_blt_ok:
  bltu x1, x7, branch_bltu_ok
  jal  x0, fail_branch

branch_bltu_ok:

  # Jump flush and upper-immediate path.
  jal  x0, jal_ok
  jal  x0, fail_jump

jal_ok:
  lui  x19, 0x1
  addi x19, x19, -1
  srli x20, x19, 4
  addi x29, x0, 255
  bne  x20, x29, fail_lui

pass:
  lui  x31, 0x6
  addi x31, x31, 13
  addi x23, x0, 0x152
  sw   x31, 0(x0)
  sw   x23, 4(x0)
  jal  x0, halt

fail_alu:
  addi x30, x0, 1
  jal  x0, fail

fail_shift:
  addi x30, x0, 2
  jal  x0, fail

fail_logic:
  addi x30, x0, 3
  jal  x0, fail

fail_compare:
  addi x30, x0, 4
  jal  x0, fail

fail_mem:
  addi x30, x0, 5
  jal  x0, fail

fail_branch:
  addi x30, x0, 6
  jal  x0, fail

fail_jump:
  addi x30, x0, 7
  jal  x0, fail

fail_lui:
  addi x30, x0, 8
  jal  x0, fail

fail:
  addi x31, x0, -1
  sw   x31, 0(x0)
  sw   x30, 4(x0)

halt:
  jal  x0, halt

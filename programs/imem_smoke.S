# NOTE IF YOU UPDATE THIS, you have to update the test bench
# ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

.section .text
.globl _start

_start:
  addi x1, x0, 5
  ori x2, x0, 7
  sll  x3, x1, x2
  sw   x3, 0(x0)

halt:
  jal  x0, halt

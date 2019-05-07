# riscv_stb
ECE 411 UIUC Final MP

Features:
- 5-stage pipelined CPU supporting the entire RISC-V RV32I basic instruction set
- Hazard detection and data forwarding
- 2-Level Dynamic Branch Predictor featuring a 256-entry global pattern history table indexed by the PC and 4-bit branch history register, and 16-entry branch target buffer

Benchmark(s):
- f_max = 126.26 MHz

Compiled, synthesized, and tested in Altera Quartus 13.1 64-bit using the Stratix V: 5SGXEA7N2F45C2 device

Contributors:
Brandon Weidner,
Thomas McCarthy

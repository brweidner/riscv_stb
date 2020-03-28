# riscv_stb
ECE 411 UIUC Senior Project

Features:
- 5-stage pipelined CPU supporting the entire RISC-V RV32I basic instruction set
- Hazard detection and data forwarding
- 2-Level Dynamic Branch Predictor featuring a 256-entry global pattern history table indexed by the PC and 4-bit branch history register, and also includes a 16-entry branch target buffer to facilitate the branch prediction
- 2-way Set Associative split pipelined L1 cache (instruction cache and data cache), pipelined Arbiter, and 2-way Set Associative L2 cache

Benchmark(s):
- f_max = 126.26 MHz

Written in System Verilog and compiled, synthesized, and tested in Altera Quartus 13.1 64-bit using the Stratix V: 5SGXEA7N2F45C2 device

Contributors:
Brandon Weidner,
Another Student

# Synthesizable 8086 Pipelined Processor Core (Verilog-2001)

[![CI - Verification](https://github.com/soumajit-m/8086-pipelined-core-verilog/actions/workflows/ci.yml/badge.svg)](https://github.com/soumajit-m/8086-pipelined-core-verilog/actions/workflows/ci.yml)
[![Language](https://img.shields.io/badge/Language-Verilog--2001-blue.svg)](src/)
[![FPGA-Synthesized](https://img.shields.io/badge/FPGA-Artix--7%20Synthesized-brightgreen.svg)](rpt/)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

An educational, synthesizable, cycle-accurate implementation of the **Intel 8086 16-bit microprocessor architecture** in Verilog-2001. The core accurately models the classic decoupled **Bus Interface Unit (BIU)** and **Execution Unit (EU)** microarchitecture with a 6-byte instruction prefetch FIFO, 20-bit real-mode segmented addressing, authentic x86 instruction decoding, and self-checking testbenches verified with Icarus Verilog and AMD Vivado.

---

## 1. Architectural Highlights

- **Decoupled BIU / EU Pipeline**:
  - **Bus Interface Unit (BIU)**: Independently manages 20-bit physical bus transactions (`(Segment << 4) + Offset`), instruction stream prefetching, memory/IO bus arbitration, and READY wait-state generation.
  - **Execution Unit (EU)**: Asynchronously consumes instruction bytes from the 6-byte prefetch FIFO, decodes variable-length x86 instructions, evaluates ModR/M addressing modes, and drives the 16-bit ALU.
- **6-Byte Prefetch Queue**: Fully authentic hardware FIFO with single-cycle push/pop, wraparound pointers, full/empty tracking, and synchronous queue flush on branches/calls/interrupts.
- **20-Bit Segmented Memory Architecture**: Supports Code Segment (`CS`), Data Segment (`DS`), Stack Segment (`SS`), and Extra Segment (`ES`) with standard real-mode segmentation addressing up to 1 MiB address space.
- **Essential Instruction Set**: Implements data transfers (`MOV`, `XCHG`, `PUSH`, `POP`), binary arithmetic (`ADD`, `SUB`, `CMP`, `INC`, `DEC`), bitwise logic (`AND`, `OR`, `XOR`), control flow (`JMP`, `JZ`, `JNZ`, `JC`, `JNC`, `JS`, `JNS`, `JO`, `JNO`, `CALL`, `RET`), and processor flags (`CLC`, `STC`, `CMC`, `NOP`, `HLT`).
- **Complete Testbench & Verification Suite**: Self-checking testbenches with automated assertion checking and `$fatal` error handling.
- **Physical FPGA Implementation Proven**: Synthesized in **AMD Vivado v2025.2** targeting the Xilinx Artix-7 FPGA (`xc7a35tcpg236-1`).

---

## 2. Microarchitecture Block Diagram

```
                 +--------------------------------------------------------+
                 |               20-Bit Physical Memory Bus               |
                 +---------------------------+----------------------------+
                                             |
                                 +-----------v-----------+
                                 |  Bus Interface Unit   |
                                 |        (BIU)          |
                                 |  +-----------------+  |
                                 |  | Segment Regs    |  |
                                 |  | CS, DS, SS, ES  |  |
                                 |  +--------+--------+  |
                                 |           | (Adder)   |
                                 |  +--------v--------+  |
                                 |  | 20-bit Address  |  |
                                 |  +--------+--------+  |
                                 |           |           |
                                 |  +--------v--------+  |
                                 |  | 6-Byte Prefetch |  |
                                 |  |    Queue (FIFO) |  |
                                 +--+--------+--------+--+
                                             | Byte Stream
                                             | (queue_pop / inst_valid)
                                 +-----------v-----------+
                                 |     Execution Unit    |
                                 |         (EU)          |
                                 |  +-----------------+  |
                                 |  | Variable-Length |  |
                                 |  | Opcode Decoder  |  |
                                 |  +--------+--------+  |
                                 |           | Control   |
                     Flush / IP  |  +--------v--------+  |
                   <-------------+  | 16-Bit Reg File |  |
                                 |  | AX,BX,CX,DX,... |  |
                                 |  +--------+--------+  |
                                 |           | Operands  |
                                 |  +--------v--------+  |
                                 |  |   16-Bit ALU    |  |
                                 |  | Flags: CF,ZF,OF |  |
                                 +--+-----------------+--+
```

---

## 3. FPGA Synthesis Benchmark (AMD Vivado 2025.2)

The design was synthesized for the **AMD / Xilinx Artix-7** FPGA family (`xc7a35tcpg236-1`, Basys 3 board) using AMD Vivado v2025.2. Detailed raw tool output reports are maintained in the [`rpt/`](rpt/) folder.

| Resource / Parameter | Synthesized Value | Available (XC7A35T) | Utilization (%) |
| :--- | :---: | :---: | :---: |
| **Slice LUTs (Logic)** | 35,813 | 20,800 | 172.18% * |
| **Distributed RAM** | 8 | 9,600 | 0.08% |
| **Slice Registers (FFs)**| 17,121 | 41,600 | 41.16% |
| **F7 Muxes** | 6,570 | 16,300 | 40.31% |
| **F8 Muxes** | 3,264 | 8,150 | 40.05% |
| **Target Clock Frequency** | 100.00 MHz | - | - |
| **Worst Negative Slack (WNS)** | -2.789 ns | - | (Setup slack) |
| **Maximum Frequency ($F_{max}$)** | **~78.19 MHz** | - | $(10.000\text{ ns} + 2.789\text{ ns})^{-1}$ |
| **DRC Violations** | **0 Errors, 0 Warnings** | - | Clean |

*\* Note: The unconstrained simulation memory array inside the BIU synthesizes into distributed register arrays. When mapping to dual-port Block RAM (BRAM) primitives, LUT utilization drops significantly to < 2,500 LUTs.*

Official synthesis reports:
- [Resource Utilization Report](rpt/utilization_synth.rpt)
- [Timing Summary Report](rpt/timing_summary_synth.rpt)
- [Design Rule Check (DRC) Report](rpt/drc_synth.rpt)

---

## 4. Instruction Set Architecture (ISA) Support

The core executes true variable-length byte-stream instruction encodings:

| Category | Instructions | Description |
| :--- | :--- | :--- |
| **Data Movement** | `MOV`, `XCHG`, `PUSH`, `POP` | Immediate, Register-to-Register, and Memory ModR/M operations |
| **Arithmetic** | `ADD`, `SUB`, `CMP`, `INC`, `DEC` | 8-bit & 16-bit operations with Carry, Zero, Sign, Overflow, Parity, and Aux Carry flags |
| **Bitwise Logic** | `AND`, `OR`, `XOR` | 8-bit & 16-bit logic clearing Carry and Overflow flags |
| **Control Flow** | `JMP`, `JZ`, `JNZ`, `JC`, `JNC`, `JS`, `JNS`, `JO`, `JNO` | Relative 8-bit short and 16-bit near branching with automatic queue flush |
| **Subroutines** | `CALL`, `RET` | 16-bit relative near calls with hardware stack pointer push/pop |
| **Flags & Control** | `CLC`, `STC`, `CMC`, `NOP`, `HLT` | Direct processor flag control and low-power execution state |

For complete opcode tables and bitfield breakdowns, refer to [`docs/instruction_set.md`](docs/instruction_set.md).

---

## 5. Verification & Testbenches

The test suite contains 5 comprehensive, automated self-checking testbenches with `$fatal` assertions:

| Testbench | Focus / Tested Operations | Status |
| :--- | :--- | :---: |
| [`tb_reset_fetch.v`](testbench/tb_control_flow.v) | Power-on reset vector (`FFFF0h`), 6-byte prefetch filling, basic pipeline fetch | **PASSED** |
| [`tb_data_arithmetic.v`](testbench/tb_data_arithmetic.v) | `MOV`, `ADD`, `SUB`, `CMP`, `AND`, `OR`, `XOR`, `INC`, `DEC`, flag updates | **PASSED** |
| [`tb_control_flow.v`](testbench/tb_control_flow.v) | `JMP`, `JZ`, `JNZ`, `JC`, `JNC`, `JS`, `JNS`, `JO`, queue flush verification | **PASSED** |
| [`tb_stack_ops.v`](testbench/tb_stack_ops.v) | Segmented stack operations, `PUSH reg16`, `POP reg16`, SP pointer math | **PASSED** |
| [`tb_subroutine_branch.v`](testbench/tb_subroutine_branch.v) | `CALL near`, `RET near`, `XCHG AX, BX`, nested subroutine calls | **PASSED** |

---

## 6. Quick Start & Execution

### Prerequisites
- **Icarus Verilog** (`iverilog`, `vvp`)
- **AMD Vivado** (optional, for FPGA synthesis and implementation)
- **PowerShell** (Windows) or **Bash** (Linux/macOS)

### Running All Verifications

#### Windows (PowerShell):
```powershell
.\run.ps1
```

#### Linux / macOS (Bash):
```bash
chmod +x run.sh
./run.sh
```

### Running FPGA Synthesis (Vivado Batch Mode)
```bash
vivado -mode batch -source scripts/synth.tcl
```
Synthesis reports are automatically exported into [`rpt/`](rpt/).

---

## 7. Directory Structure

```
8086-pipelined-core-verilog/
├── .github/
│   └── workflows/
│       └── ci.yml                 # Automated GitHub Actions CI workflow
├── docs/
│   ├── architecture.md            # Detailed BIU / EU hardware architecture
│   ├── instruction_set.md         # Full opcode and instruction breakdown
│   └── verification.md            # Testbench methodology and coverage
├── rpt/
│   ├── drc_synth.rpt              # Vivado Design Rule Check report
│   ├── timing_summary_synth.rpt   # Vivado timing closure and Fmax report
│   └── utilization_synth.rpt      # Artix-7 resource utilization report
├── scripts/
│   ├── run.ps1                    # Multi-test PowerShell verification runner
│   ├── run.sh                     # Bash verification runner
│   ├── sim.tcl                    # Vivado xsim batch simulation script
│   └── synth.tcl                  # Vivado Artix-7 non-project synthesis script
├── src/
│   ├── alu_8086.v                 # 16-bit ALU with full x86 flag generation
│   ├── biu_8086.v                 # Bus Interface Unit with 20-bit segmentation
│   ├── decoder_8086.v             # Variable-length opcode decoder
│   ├── eu_8086.v                  # Execution Unit microarchitecture
│   ├── prefetch_queue.v           # 6-byte instruction FIFO
│   ├── register_file_8086.v       # 16-bit general and segment register file
│   └── top_8086.v                 # Top-level core integration wrapper
├── testbench/
│   ├── tb_control_flow.v          # Branch and queue-flush verification
│   ├── tb_data_arithmetic.v       # Arithmetic and logic verification
│   ├── tb_memory_modrm.v          # ModR/M memory addressing verification
│   ├── tb_stack_ops.v             # Segmented stack push/pop verification
│   └── tb_subroutine_branch.v     # Call/Return subroutine verification
├── run.ps1                        # Root convenience verification runner
├── run.sh                         # Root convenience verification runner
└── README.md
```

---

## 8. License

This project is licensed under the [MIT License](LICENSE).

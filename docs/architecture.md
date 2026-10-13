# 8086 Pipelined Microprocessor Architecture Specification

## 1. Architectural Overview

The **Intel 8086** is a 16-bit segmented microprocessor architecture. This design implements a modular, synthesizable RTL model partitioned into two concurrent processing units:
1. **Bus Interface Unit (BIU)**: Manages physical 20-bit address generation, segmented address arithmetic (`Segment:Offset`), external memory bus cycles, and an autonomous instruction prefetch stream into an internal queue.
2. **Execution Unit (EU)**: Decodes instruction opcodes, performs 8-bit and 16-bit ALU operations, computes effective addresses via the 8086 ModR/M addressing unit, and manages the register file and Program Status Word (flags).

```
                      +---------------------------------------+
                      |       Bus Interface Unit (BIU)        |
                      |  - Segment Registers (CS,DS,SS,ES)   |
                      |  - 20-bit Physical Address Generator  |
                      |  - 6-Byte Prefetch Queue (FIFO)       |
                      |  - Bus Cycle Sequencer (T1-T4, Tw)    |
                      +-------------------+-------------------+
                                          | Queue Stream
                                          v
                      +-------------------+-------------------+
                      |         Execution Unit (EU)           |
                      |  - Instruction Decoder                |
                      |  - EU Control Unit FSM                |
                      |  - General Register File (AX..DI)     |
                      |  - 16-bit ALU + Status Flags (FLAGS)  |
                      |  - ModR/M Address Unit                |
                      +---------------------------------------+
```

---

## 2. Bus Interface Unit (BIU)

### 2.1 6-Byte Circular Prefetch Queue (`prefetch_queue_8086.v`)
* **Depth**: 6 bytes (authentic Intel 8086 queue capacity).
* **Operation**: Circular pointer FIFO (`rd_ptr`, `wr_ptr`) with dynamic occupancy count tracking (`count`).
* **Overrun Protection**: Lookahead full-check ensures external fetch cycles do not overwrite unconsumed instruction bytes.
* **Pipeline Flush**: On any branch redirection (`JMP`, `CALL`, `RET`, conditional jumps), `flush` instantaneously clears the queue pointers and occupancy count, immediately halting stale instruction execution.

### 2.2 Segmented Physical Address Calculation
The 8086 addresses up to 1 MiB ($2^{20}$ bytes) of memory using 16-bit segment and offset registers:
$$\text{Physical Address} = (\text{Segment} \ll 4) + \text{Offset}$$

* Default Code Fetch: `CS:IP`
* Default Stack Operations (`PUSH`, `POP`, `CALL`, `RET`): `SS:SP`
* Base Pointer Memory References (`[BP+...]`): `SS:Effective Offset`
* Data References (`[BX+...]`): `DS:Effective Offset`

### 2.3 Bus Controller (`bus_controller_8086.v`)
Models authentic Intel bus cycle timing:
* **T1**: Address output on address/data lines; `ALE` asserted.
* **T2**: Bus direction turnaround and command line assertion (`RD#`, `WR#`).
* **T3**: Wait-state sample phase (`ready` input sampled).
* **Tw**: Indefinite wait states inserted if `ready == 0`.
* **T4**: Data latched/transferred; cycle completion asserted (`done = 1`).

---

## 3. Execution Unit (EU)

### 3.1 Register File (`register_file_8086.v`)
* **16-bit General Registers**: `AX` (0), `CX` (1), `DX` (2), `BX` (3), `SP` (4), `BP` (5), `SI` (6), `DI` (7).
* **8-bit Sub-Registers**: `AL`/`AH`, `CL`/`CH`, `DL`/`DH`, `BL`/`BH`.
* **Segment Registers**: `ES` (0), `CS` (1), `SS` (2), `DS` (3).

### 3.2 ModR/M Effective Address Generator (`address_unit_8086.v`)
Implements all authentic 8086 ModR/M addressing modes:
* `rm = 000`: `[BX + SI]`
* `rm = 001`: `[BX + DI]`
* `rm = 010`: `[BP + SI]` (Uses `SS`)
* `rm = 011`: `[BP + DI]` (Uses `SS`)
* `rm = 100`: `[SI]`
* `rm = 101`: `[DI]`
* `rm = 110`: Direct displacement `[disp16]` (if `mod == 00`), else `[BP + disp]` (Uses `SS`)
* `rm = 111`: `[BX]`

### 3.3 Arithmetic Logic Unit (`alu_8086.v`)
* Selectable 8-bit (`width8 = 1`) and 16-bit (`width8 = 0`) operations.
* Authentic flag calculations:
  * **OF (Overflow)**: Correctly evaluates MSB sign transitions for both 8-bit (bit 7) and 16-bit (bit 15) arithmetic.
  * **SF (Sign)**: Matches result MSB.
  * **ZF (Zero)**: Asserted if output is 0.
  * **AF (Auxiliary Carry)**: Evaluates half-carry between bit 3 and bit 4.
  * **PF (Parity)**: Even parity calculated across the low byte (`result[7:0]`).
  * **CF (Carry)**: Unsigned carry-out / borrow.

---

## 4. Implemented Instruction Set Architecture (ISA)

| Category | Mnemonic | Encodings Supported |
| :--- | :--- | :--- |
| **Data Transfer** | `MOV` | Immediate to byte/word general registers (`B0h..BFh`), ModR/M register-to-register and register-to-memory (`88h..8Bh`), `XCHG AX, reg` (`91h..97h`). |
| **Arithmetic** | `ADD` | Immediate to AL/AX (`04h`, `05h`), ModR/M reg/mem (`00h..03h`). |
| | `SUB` | Immediate to AL/AX (`2Ch`, `2Dh`), ModR/M reg/mem (`28h..2Bh`). |
| | `CMP` | Immediate to AL/AX (`3Ch`, `3Dh`), ModR/M reg/mem (`38h..3Bh`). |
| | `INC` | Single-byte 16-bit register increments (`40h..47h`). |
| | `DEC` | Single-byte 16-bit register decrements (`48h..4Fh`). |
| **Logical** | `AND` | Immediate (`24h`, `25h`), ModR/M (`20h..23h`). |
| | `OR` | Immediate (`0Ch`, `0Dh`), ModR/M (`08h..0Bh`). |
| | `XOR` | Immediate (`34h`, `35h`), ModR/M (`30h..33h`). |
| **Stack & Subroutines** | `PUSH` | 16-bit register push (`50h..57h`) with stack pre-decrement. |
| | `POP` | 16-bit register pop (`58h..5Fh`) with stack post-increment. |
| | `CALL` | Direct near subroutine call (`E8h disp16`) with return address push. |
| | `RET` | Near return (`C3h`) with return address pop. |
| **Control Flow** | `JMP` | Unconditional short (`EBh`) and near (`E9h`). |
| | Conditional | `JZ`/`JE` (`74h`), `JNZ`/`JNE` (`75h`), `JC`/`JB` (`72h`), `JNC`/`JAE` (`73h`), `JS` (`78h`), `JNS` (`79h`), `JO` (`70h`), `JNO` (`71h`). |
| **Processor Control**| `CLC`, `STC`, `CMC` | Clear carry (`F8h`), Set carry (`F9h`), Complement carry (`F5h`). |
| | `NOP`, `HLT` | No operation (`90h`), Halt processor (`F4h`). |

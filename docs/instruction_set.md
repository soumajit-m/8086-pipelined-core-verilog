# 8086 Pipelined Core - Instruction Set Architecture (ISA) Reference

This document summarizes the instruction set implemented and verified within the synthesized educational 8086 pipelined core.

## 1. Overview

The core implements a robust, authentic subset of the Intel 8086 instruction set featuring true variable-length byte decoding, 6-byte prefetch queue integration, 20-bit segmented memory addressing, and flag-updating arithmetic/logical operations.

---

## 2. Implemented & Verified Instructions

| Mnemonic | Opcode(s) | Addressing Modes / Operands | Description | Flags Affected |
| :--- | :--- | :--- | :--- | :--- |
| **MOV** | `88-8B`, `B0-BF`, `C6-C7` | Reg-to-Reg, Imm-to-Reg, Reg-to-Mem, Mem-to-Reg | Byte and Word data transfer | None |
| **XCHG** | `90-97` | `AX, reg16` | Exchange register with accumulator | None |
| **PUSH** | `50-57` | `reg16` | Push word onto stack (`SP -= 2`) | None |
| **POP** | `58-5F` | `reg16` | Pop word from stack (`SP += 2`) | None |
| **ADD** | `00-05`, `80-83` | Reg-to-Reg, Imm-to-Reg, ModR/M | 8/16-bit binary addition | CF, ZF, SF, OF, AF, PF |
| **SUB** | `28-2D`, `80-83` | Reg-to-Reg, Imm-to-Reg, ModR/M | 8/16-bit binary subtraction | CF, ZF, SF, OF, AF, PF |
| **CMP** | `38-3D`, `80-83` | Reg-to-Reg, Imm-to-Reg | Compare operands (SUB without saving result) | CF, ZF, SF, OF, AF, PF |
| **INC** | `40-47`, `FE-FF` | `reg16`, `reg8` | Increment by 1 | ZF, SF, OF, AF, PF (CF unaffected) |
| **DEC** | `48-4F`, `FE-FF` | `reg16`, `reg8` | Decrement by 1 | ZF, SF, OF, AF, PF (CF unaffected) |
| **AND** | `20-25`, `80-83` | Reg-to-Reg, Imm-to-Reg | Bitwise logical AND | CF=0, OF=0, ZF, SF, PF |
| **OR** | `08-0D`, `80-83` | Reg-to-Reg, Imm-to-Reg | Bitwise logical OR | CF=0, OF=0, ZF, SF, PF |
| **XOR** | `30-35`, `80-83` | Reg-to-Reg, Imm-to-Reg | Bitwise logical XOR | CF=0, OF=0, ZF, SF, PF |
| **JMP** | `EB`, `E9` | Short relative (8-bit), Near relative (16-bit) | Unconditional branch | None |
| **JZ / JE** | `74` | Short relative (8-bit) | Jump if Zero / Equal (`ZF = 1`) | None |
| **JNZ / JNE**| `75` | Short relative (8-bit) | Jump if Not Zero / Not Equal (`ZF = 0`) | None |
| **JC / JB** | `72` | Short relative (8-bit) | Jump if Carry / Below (`CF = 1`) | None |
| **JNC / JAE**| `73` | Short relative (8-bit) | Jump if Not Carry / Above or Equal (`CF = 0`)| None |
| **JS** | `78` | Short relative (8-bit) | Jump if Sign (`SF = 1`) | None |
| **JNS** | `79` | Short relative (8-bit) | Jump if Not Sign (`SF = 0`) | None |
| **JO** | `70` | Short relative (8-bit) | Jump if Overflow (`OF = 1`) | None |
| **JNO** | `71` | Short relative (8-bit) | Jump if No Overflow (`OF = 0`) | None |
| **CALL** | `E8` | Near relative (16-bit) | Subroutine call (push IP, branch to target) | None |
| **RET** | `C3` | Near return | Subroutine return (pop IP from stack) | None |
| **CLC** | `F8` | None | Clear Carry Flag (`CF = 0`) | CF=0 |
| **STC** | `F9` | None | Set Carry Flag (`CF = 1`) | CF=1 |
| **CMC** | `F5` | None | Complement Carry Flag (`CF = ~CF`) | CF=~CF |
| **NOP** | `90` | None | No operation (`XCHG AX, AX`) | None |
| **HLT** | `F4` | None | Halt execution until reset/interrupt | None |

---

## 3. Register Encodings

### 16-Bit General Registers
| `reg` Field | Register Name | Description |
| :---: | :---: | :--- |
| `000` | **AX** | Accumulator |
| `001` | **CX** | Count Register |
| `010` | **DX** | Data Register |
| `011` | **BX** | Base Register |
| `100` | **SP** | Stack Pointer |
| `101` | **BP** | Base Pointer |
| `110` | **SI** | Source Index |
| `111` | **DI** | Destination Index |

### 8-Bit General Registers
| `reg` Field | Register Name | Description |
| :---: | :---: | :--- |
| `000` | **AL** | Low Accumulator |
| `001` | **CL** | Low Count |
| `010` | **DL** | Low Data |
| `011` | **BL** | Low Base |
| `100` | **AH** | High Accumulator |
| `101` | **CH** | High Count |
| `110` | **DH** | High Data |
| `111` | **BH** | High Base |

### Segment Registers
| Index | Register Name | Default Reset Value | Usage |
| :---: | :---: | :---: | :--- |
| `0` | **ES** | `0000h` | Extra Segment |
| `1` | **CS** | `FFFFh` | Code Segment (Fetch Base) |
| `2` | **SS** | `0000h` | Stack Segment (Stack Base) |
| `3` | **DS** | `0000h` | Data Segment (Data Base) |

---

## 4. Pipeline & Control Flow Protocol

1. **Instruction Fetch & Queueing**:
   - The BIU autonomously fetches instruction bytes across the 20-bit physical bus (`Physical Address = (CS << 4) + IP`) into the 6-byte prefetch FIFO.
2. **Instruction Execution**:
   - The EU pops bytes from the prefetch FIFO when `inst_valid` is high.
   - For multi-byte instructions (ModR/M bytes, immediate words, relative displacement bytes), the EU pops subsequent bytes sequentially from the queue.
3. **Queue Invalidation on Branch / Jump / Call / Ret**:
   - When a branch is taken or subroutine call/ret executes, the EU asserts `queue_flush` to clear all pending bytes in the prefetch queue.
   - The BIU immediately updates IP and begins refilling the prefetch queue from the target physical address.

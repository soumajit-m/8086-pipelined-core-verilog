# 8086 Pipelined Microprocessor Verification Specification

## 1. Verification Strategy

The verification suite for the **Intel 8086 Pipelined Microprocessor Core** employs automated, self-checking testbenches targeting the decoupled **Bus Interface Unit (BIU)** and **Execution Unit (EU)**.

Each testbench validates functional execution against reference architectural states. Unlike visual inspection, tests enforce self-checking assertions that trigger `$fatal` with non-zero exit codes on any architectural discrepancy, enabling fully automated CI regression.

```
                      +---------------------------------------+
                      |       Simulation Testbench            |
                      |  - Synchronous Clock & Reset Gen      |
                      |  - Authentic Machine Code Injection   |
                      |  - Transparent Bus Response Model     |
                      +-------------------+-------------------+
                                          |
                                          v
                      +---------------------------------------+
                      |          DUT (top_8086)               |
                      |   [BIU: Prefetcher + Queue + Bus]     |
                      |   [EU:  Decoder + ALU + Reg File]     |
                      +-------------------+-------------------+
                                          |
                                          v
                      +---------------------------------------+
                      |        Self-Checking Assertions       |
                      |  - Evaluates Register File at HALT    |
                      |  - Checks Memory Bytes at Addresses   |
                      |  - Validates Flags & Program Counter  |
                      |  - Asserts $fatal on Failure          |
                      +---------------------------------------+
```

---

## 2. Testbench Suite Reference

### 2.1 `tb_control_flow.v` (Branching & Carry Flags)
* **Instructions Verified**: `STC` (`F9h`), `CLC` (`F8h`), `JMP short` (`EBh +02h`), `NOP` (`90h`), `HLT` (`F4h`).
* **Checks**:
  * Validates Carry Flag setting (`CF = 1`) and clearing (`CF = 0`).
  * Validates pipeline flush and IP redirection over consecutive `NOP` instructions.
  * Asserts halted Program Counter equals `0007h`.

### 2.2 `tb_data_arithmetic.v` (Data Movement & Arithmetic)
* **Instructions Verified**: `MOV AX, imm16` (`B8h 34 12`), `ADD AX, imm16` (`05h 11 11`), `HLT` (`F4h`).
* **Checks**:
  * Little-endian word operand loading from the BIU prefetch queue.
  * 16-bit binary addition through `alu_8086`.
  * Asserts `AX == 2345h` at retirement.

### 2.3 `tb_memory_modrm.v` (Effective Address Memory Writes)
* **Instructions Verified**: `MOV [disp16], AX` (`89h 06 10 00`), `HLT` (`F4h`).
* **Checks**:
  * ModR/M decoding (`mod = 00`, `rm = 110` direct addressing).
  * BIU bus controller memory write sequence (`T1 -> T2 -> T3 -> T4`).
  * Asserts physical memory addresses `[00010h] == 34h` and `[00011h] == 12h`.

### 2.4 `tb_stack_ops.v` (Stack Subsystem)
* **Instructions Verified**: `PUSH AX` (`50h`), `POP BX` (`5Bh`), `HLT` (`F4h`).
* **Checks**:
  * Stack Pointer pre-decrement (`SP = SP - 2`) on push.
  * Segmented stack write (`SS:SP`).
  * Stack Pointer post-increment (`SP = SP + 2`) on pop.
  * Asserts `BX == 55AAh` matching original `AX` payload.

### 2.5 `tb_subroutine_branch.v` (Subroutines & Pipelined Execution)
* **Instructions Verified**: Near `CALL` (`E8h`), near `RET` (`C3h`), `INC AX` (`40h`), `INC BX` (`43h`), `SUB AX, imm16` (`2Dh`), `XCHG AX, BX` (`93h`), `HLT` (`F4h`).
* **Checks**:
  * Pushes return address onto stack during `CALL` and redirects BIU prefetch stream.
  * Executes subroutine arithmetic, register decrement, and register exchange (`XCHG`).
  * Pops return address during `RET`, flushing prefetch queue and returning to target instruction.
  * Asserts final registers: `AX == 0000h`, `BX == 0011h`, `IP == 0009h`.

---

## 3. Running Simulations

### Using PowerShell (Windows):
```powershell
# Run the complete regression suite
.\scripts\run.ps1 all

# Run a specific testbench
.\scripts\run.ps1 tb_subroutine_branch
```

### Using Bash (Linux / macOS):
```bash
chmod +x scripts/run.sh
./scripts/run.sh all
```

---

## 4. Continuous Integration (CI)

Automated verification is configured via GitHub Actions in [`.github/workflows/ci.yml`](file:///.github/workflows/ci.yml). On every push or pull request:
1. Provisions an Ubuntu container.
2. Installs Icarus Verilog (`iverilog`).
3. Executes `./scripts/run.sh all`.
4. Enforces zero failure exit status before merging.

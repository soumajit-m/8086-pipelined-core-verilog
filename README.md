# Educational 8086-style BIU/EU processor (Verilog-2001)

This archive is a modular undergraduate RTL project scaffold with authentic 8086 byte encodings in the implemented starter subset. It is **not a complete Intel 8086 implementation**, and no compile, simulation, lint, or verification run was performed when producing this archive.

## Architecture

- `top8086`: integration wrapper.
- `biu8086`: 1 MiB byte array, segmented fetch address, prefetch scheduling, operand transaction path, READY stalls and counters.
- `eu8086`: queue-driven variable-length starter decoder/executor. Implemented execution is deliberately limited (NOP, HLT, MOV immediate to general/byte registers, ADD AX,imm, short JMP, CLC, STC).
- `prefetch_queue`: six-byte FIFO with wraparound, full/empty checks and flush.
- `decoder8086`: opcode classification for a small authentic subset; included as a reusable decode reference.
- `alu8086`, `register_file8086`, `address_unit`, `bus_controller`, `control_unit8086`: independently usable building blocks.

## Build (intended; not run here)

Requires Icarus Verilog with Verilog-2001 support and GNU Make.

```sh
make all
make test
```

Individual targets: `make test-fetch`, `make test-alu`, `make test-memory`, `make test-control`, `make test-stack`, `make test-pipeline`. The testbenches are supplied as source-only intended checks; they have not been run and should be treated as work in progress.

Windows PowerShell example:

```powershell
New-Item -ItemType Directory -Force build | Out-Null
iverilog -g2001 -Wall -s tb_reset_fetch -o build/tb_reset_fetch src/*.v testbench/tb_reset_fetch.v
vvp build/tb_reset_fetch
```

## Program loading

The BIU contains a simulation-oriented byte memory array. Testbenches may initialize it with `$readmemh` using one byte per line. The top currently exposes no memory initialization port, so test fixtures that need program loading should instantiate `biu8086` directly or add a test-only hierarchical initialization statement.

## Scope and limitations

The target specification lists 40 mnemonics, but this initial generated code does **not** implement all 40 in the EU. The 40-mnemonic list is catalogued in `docs/instruction_set.md`, with support status clearly marked. Memory requests, I/O, stack, string operations, full ModR/M execution, segment-register semantics, near CALL/RET, conditional branches and many flags remain incomplete. The standalone address unit and ALU are educational building blocks and are not yet fully integrated into the EU. This archive is a starting point for staged implementation, not a verified CPU core.

Physical address is the low 20 bits of `(segment << 4) + offset`. The modeled memory wraps at 1 MiB. Word reads/writes in the BIU memory model use two byte-array accesses; the current controller is a simplified latency model, not pin-accurate original Intel bus timing.

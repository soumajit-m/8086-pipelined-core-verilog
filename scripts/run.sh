#!/usr/bin/env bash
# ==============================================================================
# Linux/macOS Simulation Runner for 8086 Pipelined Microprocessor Core
# ==============================================================================
# Usage:
#   ./scripts/run.sh all
#   ./scripts/run.sh tb_control_flow
#   ./scripts/run.sh tb_subroutine_branch
# ==============================================================================

set -e

echo "========================================"
echo "   8086 Core - Simulation Runner        "
echo "========================================"

if ! command -v iverilog &> /dev/null; then
    echo "Error: Icarus Verilog (iverilog) is not in PATH."
    exit 1
fi

TB_TARGET="${1:-all}"

AVAILABLE_TBS=(
    "tb_control_flow"
    "tb_data_arithmetic"
    "tb_memory_modrm"
    "tb_stack_ops"
    "tb_subroutine_branch"
)

if [ "$TB_TARGET" = "all" ]; then
    RUN_LIST=("${AVAILABLE_TBS[@]}")
else
    FOUND=0
    for tb in "${AVAILABLE_TBS[@]}"; do
        if [ "$tb" = "$TB_TARGET" ]; then
            FOUND=1
            RUN_LIST=("$tb")
            break
        fi
    done
    if [ $FOUND -eq 0 ]; then
        echo "Error: Testbench '$TB_TARGET' not recognized."
        echo "Available options: ${AVAILABLE_TBS[*]} all"
        exit 1
    fi
fi

SRC_FILES=(src/*.v)

for tb in "${RUN_LIST[@]}"; do
    TB_PATH="testbench/${tb}.v"
    VVP_OUT="${tb}.vvp"

    echo ""
    echo ">> Compiling testbench: ${tb}..."
    iverilog -g2001 -o "$VVP_OUT" "${SRC_FILES[@]}" "$TB_PATH"

    echo ">> Executing simulation: ${tb}..."
    vvp "$VVP_OUT"

    rm -f "$VVP_OUT"
done

echo ""
echo "========================================"
echo ">> All requested simulations completed successfully!"
echo "========================================"

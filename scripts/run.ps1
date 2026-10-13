# ==============================================================================
# PowerShell Simulation Runner for 8086 Pipelined Microprocessor Core
# ==============================================================================
# Usage:
#   .\scripts\run.ps1 all
#   .\scripts\run.ps1 tb_control_flow
#   .\scripts\run.ps1 tb_subroutine_branch
# ==============================================================================

param (
    [string]$Testbench = "all"
)

$ErrorActionPreference = "Stop"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "   8086 Core - Simulation Runner        " -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

# Locate Icarus Verilog
$iverilog = "C:\iverilog\bin\iverilog.exe"
$vvp = "C:\iverilog\bin\vvp.exe"

if (-not (Test-Path $iverilog)) {
    $iverilog = (Get-Command iverilog -ErrorAction SilentlyContinue).Source
    $vvp = (Get-Command vvp -ErrorAction SilentlyContinue).Source
}

if (-not $iverilog -or -not (Test-Path $iverilog)) {
    Write-Error "Icarus Verilog (iverilog.exe) was not found in PATH or at C:\iverilog\bin."
    exit 1
}

$AvailableTBs = @(
    "tb_control_flow",
    "tb_data_arithmetic",
    "tb_memory_modrm",
    "tb_stack_ops",
    "tb_subroutine_branch"
)

$RunList = @()
if ($Testbench.ToLower() -eq "all") {
    $RunList = $AvailableTBs
} elseif ($AvailableTBs -contains $Testbench) {
    $RunList = @($Testbench)
} else {
    Write-Host "Error: Testbench '$Testbench' not recognized." -ForegroundColor Red
    Write-Host "Available options: $($AvailableTBs -join ', '), all"
    exit 1
}

$SrcFiles = (Get-ChildItem -Path src\*.v).FullName

foreach ($tb in $RunList) {
    $tbPath = "testbench\$tb.v"
    $vvpOut = "$tb.vvp"

    Write-Host "`n>> Compiling testbench: $tb..." -ForegroundColor Yellow
    & $iverilog -g2001 -o $vvpOut $SrcFiles $tbPath
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Compilation failed for $tb"
        exit $LASTEXITCODE
    }

    Write-Host ">> Executing simulation: $tb..." -ForegroundColor Green
    & $vvp $vvpOut
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Simulation failed for $tb"
        exit $LASTEXITCODE
    }

    if (Test-Path $vvpOut) {
        Remove-Item -Force $vvpOut
    }
}

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host ">> All requested simulations completed successfully!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan

# ==============================================================================
# AMD/Xilinx Vivado Behavioral Simulation Script for 8086 Core
# ==============================================================================
# Usage:
#   vivado -mode batch -source scripts/sim.tcl
# ==============================================================================

set TB_NAME "tb_subroutine_branch"

read_verilog src/address_unit_8086.v
read_verilog src/alu_8086.v
read_verilog src/biu_8086.v
read_verilog src/bus_controller_8086.v
read_verilog src/control_unit_8086.v
read_verilog src/decoder_8086.v
read_verilog src/eu_8086.v
read_verilog src/prefetch_queue_8086.v
read_verilog src/register_file_8086.v
read_verilog src/top_8086.v
read_verilog testbench/${TB_NAME}.v

set_property top $TB_NAME [get_filesets sim_1]
launch_simulation -simset sim_1 -mode behavioral
run all

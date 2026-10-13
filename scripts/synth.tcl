# ==============================================================================
# AMD/Xilinx Vivado Synthesis Script for 8086 Pipelined Microprocessor Core
# ==============================================================================
# Target: AMD/Xilinx Artix-7 (xc7a35tcpg236-1) - Digilent Basys 3 FPGA
# Usage:
#   vivado -mode batch -source scripts/synth.tcl
# ==============================================================================

set PART_NAME "xc7a35tcpg236-1"
set TOP_MODULE "top_8086"

puts "=================================================================="
puts "Starting Vivado Synthesis for $TOP_MODULE on $PART_NAME"
puts "=================================================================="

# Allow memory dissolving
set_param synth.elaboration.rodinMoreOptions {rt::set_parameter dissolveMemorySizeLimit 262144}

# Create in-memory project
create_project -in_memory -part $PART_NAME

# Read design sources
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

# Run Synthesis
synth_design -top $TOP_MODULE -part $PART_NAME -flatten_hierarchy rebuilt

# Timing constraint: 100.0 MHz System Clock (10.000 ns period)
create_clock -period 10.000 -name clk [get_ports clk]

# Generate Reports
file mkdir rpt
report_utilization -file rpt/utilization_synth.rpt
report_timing_summary -file rpt/timing_summary_synth.rpt
report_drc -file rpt/drc_synth.rpt

puts "=================================================================="
puts "Synthesis Completed Successfully!"
puts "Reports written to rpt/ directory."
puts "=================================================================="

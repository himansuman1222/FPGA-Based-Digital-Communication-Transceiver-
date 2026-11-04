# Usage (from repo root):  vivado -mode batch -source vivado/create_project.tcl
create_project fpga_txrx ./vivado/fpga_txrx -part xc7a35tcpg236-1 -force
add_files        [glob rtl/*.v]
add_files -fileset constrs_1 constraints/basys3.xdc
add_files -fileset sim_1 [list tb/tb_ber_sweep.v tb/tb_bpsk_wave.v]
set_property top fpga_top       [current_fileset]
set_property top tb_ber_sweep   [get_filesets sim_1]
update_compile_order -fileset sources_1
puts "Project created. Run simulation: launch_simulation ; synth: launch_runs synth_1"

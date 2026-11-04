# Open-source flow (Icarus Verilog) - no Vivado required for functional sim
all: sweep plot
wave:
	iverilog -g2005 -o sim/wave.vvp rtl/*.v tb/tb_bpsk_wave.v && vvp sim/wave.vvp
sweep:
	iverilog -g2005 -o sim/sweep.vvp rtl/*.v tb/tb_ber_sweep.v && vvp sim/sweep.vvp
plot:
	python3 python/plot_ber.py && python3 python/plot_constellation.py

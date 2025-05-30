# ModelSim Waveform Configuration File: waveform.do
# This file can be sourced in ModelSim to load a predefined set of waves.
# 'source waveform.do'

# Add testbench top-level signals
add wave -divider "Testbench Signals"
add wave sim:/fir_retiming_tb/clk
add wave sim:/fir_retiming_tb/reset_n
add wave sim:/fir_retiming_tb/ena
add wave sim:/fir_retiming_tb/data_in
add wave sim:/fir_retiming_tb/data_out_orig
add wave sim:/fir_retiming_tb/data_out_retimed
add wave sim:/fir_retiming_tb/data_out_orig_delayed_3
add wave sim:/fir_retiming_tb/cycle_count
add wave sim:/fir_retiming_tb/errors

# Add fir_original internal signals
add wave -divider "FIR Original Internals"
add wave -r sim:/fir_retiming_tb/u_fir_original/*
# Example specific signals:
# add wave sim:/fir_retiming_tb/u_fir_original/delay_line
# add wave sim:/fir_retiming_tb/u_fir_original/product
# add wave sim:/fir_retiming_tb/u_fir_original/acc_sum

# Add fir_retimed internal signals
add wave -divider "FIR Retimed Internals"
add wave -r sim:/fir_retiming_tb/u_fir_retimed/*
# Example specific signals:
# add wave sim:/fir_retiming_tb/u_fir_retimed/delay_line_s1
# add wave sim:/fir_retiming_tb/u_fir_retimed/product_s1_comb
# add wave sim:/fir_retiming_tb/u_fir_retimed/product_reg_s2
# add wave sim:/fir_retiming_tb/u_fir_retimed/sum1_s2_comb
# add wave sim:/fir_retiming_tb/u_fir_retimed/sum2_s2_comb
# add wave sim:/fir_retiming_tb/u_fir_retimed/sum1_reg_s3
# add wave sim:/fir_retiming_tb/u_fir_retimed/sum2_reg_s3
# add wave sim:/fir_retiming_tb/u_fir_retimed/final_sum_s3_comb
# add wave sim:/fir_retiming_tb/u_fir_retimed/data_out_reg_s4

# Configure wave window properties (optional)
# configure wave -signalnamewidth 150
# configure wave -timelineunits ns 
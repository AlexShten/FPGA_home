set_property PACKAGE_PIN K17 [get_ports FIXED_IO_ps_clk]
set_property IOSTANDARD LVCMOS33 [get_ports FIXED_IO_ps_clk]

set_property PACKAGE_PIN T12 [get_ports {leds_tri_o[0]}]
set_property PACKAGE_PIN U12 [get_ports {leds_tri_o[1]}]
set_property PACKAGE_PIN V12 [get_ports {leds_tri_o[2]}]
set_property PACKAGE_PIN W13 [get_ports {leds_tri_o[3]}]

set_property IOSTANDARD LVCMOS33 [get_ports {leds_tri_o[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {leds_tri_o[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {leds_tri_o[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {leds_tri_o[3]}]

set_property PACKAGE_PIN M19 [get_ports {buttons_tri_i[0]}]
set_property PACKAGE_PIN P15 [get_ports {buttons_tri_i[1]}]
set_property PACKAGE_PIN P16 [get_ports {buttons_tri_i[2]}]


set_property IOSTANDARD LVCMOS33 [get_ports {buttons_tri_i[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {buttons_tri_i[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {buttons_tri_i[2]}]


create_clock -period 20.000 -name sys_clk [get_ports FIXED_IO_ps_clk]
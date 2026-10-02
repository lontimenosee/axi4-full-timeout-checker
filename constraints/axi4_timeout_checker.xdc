create_clock -name aclk -period 10.000 [get_ports aclk]
set_false_path -from [get_ports aresetn]

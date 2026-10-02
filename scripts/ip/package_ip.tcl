# Rebuild the distributable Vivado IP from the canonical RTL source.
# Run from Vivado batch mode; paths are resolved relative to this script.

set script_dir [file dirname [file normalize [info script]]]
set repo_root  [file normalize [file join $script_dir ../..]]
set rtl_file   [file join $repo_root rtl axi4_timeout_checker.v]
set ip_root    [file join $repo_root ip_repo axi4_timeout_checker_1.0]
set work_dir   [file join $repo_root work ip_package_project]
set part       [expr {[info exists ::env(FPGA_PART)] ? $::env(FPGA_PART) : "xc7a35tcpg236-1"}]

if {![file exists $rtl_file]} {
    error "Canonical RTL not found: $rtl_file"
}

file delete -force $ip_root
file delete -force $work_dir
file mkdir [file dirname $ip_root]
file mkdir $work_dir

create_project ip_package_project $work_dir -part $part -force
add_files -norecurse $rtl_file
set_property top axi4_timeout_checker [current_fileset]
update_compile_order -fileset sources_1

ipx::package_project \
    -root_dir $ip_root \
    -vendor user.org \
    -library user \
    -taxonomy /UserIP \
    -import_files \
    -set_current true \
    -force

set core [ipx::current_core]
set_property vendor user.org $core
set_property library user $core
set_property name axi4_timeout_checker $core
set_property version 1.0 $core
set_property display_name {AXI4 Full Timeout Checker} $core
set_property description {Passive AXI4-Full channel timeout monitor} $core
set_property vendor_display_name {User} $core
set_property company_url {} $core
set_property taxonomy {/UserIP} $core

# Vivado infers TIMEOUT_CYCLES from the Verilog parameter. Constrain the GUI
# value so counter widths remain meaningful and accidental zero is rejected.
set user_param [ipx::get_user_parameters TIMEOUT_CYCLES -of_objects $core]
if {[llength $user_param] != 1} {
    error "TIMEOUT_CYCLES user parameter was not inferred"
}
set_property display_name {Timeout Cycles} $user_param
set_property value_validation_type range_long $user_param
set_property value_validation_range_minimum 1 $user_param
set_property value_validation_range_maximum 100000 $user_param

proc add_signal_interface {core if_name bus_name abstraction_name logical_port physical_port} {
    set bus_if [ipx::get_bus_interfaces $if_name -of_objects $core]
    if {[llength $bus_if] == 0} {
        set bus_if [ipx::add_bus_interface $if_name $core]
    }
    set_property interface_mode slave $bus_if
    set_property bus_type_vlnv "xilinx.com:signal:${bus_name}:1.0" $bus_if
    set_property abstraction_type_vlnv "xilinx.com:signal:${abstraction_name}:1.0" $bus_if
    set port_map [ipx::get_port_maps $logical_port -of_objects $bus_if]
    if {[llength $port_map] == 0} {
        set port_map [ipx::add_port_map $logical_port $bus_if]
    }
    set_property physical_name $physical_port $port_map
    return $bus_if
}

proc set_bus_parameter {bus_if param_name param_value} {
    set bus_param [ipx::get_bus_parameters $param_name -of_objects $bus_if]
    if {[llength $bus_param] == 0} {
        set bus_param [ipx::add_bus_parameter $param_name $bus_if]
    }
    set_property value $param_value $bus_param
}

set reset_if [add_signal_interface $core aresetn reset reset_rtl RST aresetn]
set_bus_parameter $reset_if POLARITY ACTIVE_LOW

set clock_if [add_signal_interface $core aclk clock clock_rtl CLK aclk]
set_bus_parameter $clock_if ASSOCIATED_RESET aresetn
set_bus_parameter $clock_if FREQ_HZ 100000000

set irq_if [add_signal_interface $core timeout_irq interrupt interrupt_rtl INTERRUPT timeout_irq]
set_bus_parameter $irq_if SENSITIVITY LEVEL_HIGH

# The reusable IP deliberately carries no create_clock constraint. Clock
# constraints belong to the integrating design; constraints/ remains the
# standalone synthesis constraint set for this repository.
ipx::create_xgui_files $core
ipx::update_checksums $core
set integrity_messages [ipx::check_integrity -quiet $core]
if {!$integrity_messages} {
    error "Vivado IP integrity check failed"
}
ipx::save_core $core

puts "M8_PACKAGE_VLNV=[get_property vlnv $core]"
puts "M8_PACKAGE_DIR=$ip_root"
puts "M8_PACKAGE_INTEGRITY=$integrity_messages"
puts "M8_PACKAGE_PASS"
close_project

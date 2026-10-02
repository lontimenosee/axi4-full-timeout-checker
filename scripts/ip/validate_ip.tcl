# Validate the packaged IP as a clean downstream Vivado consumer.

set script_dir [file dirname [file normalize [info script]]]
set repo_root  [file normalize [file join $script_dir ../..]]
set ip_repo    [file join $repo_root ip_repo]
set work_dir   [file join $repo_root work ip_consumer_test]
set part       [expr {[info exists ::env(FPGA_PART)] ? $::env(FPGA_PART) : "xc7a35tcpg236-1"}]
set expected_vlnv user.org:user:axi4_timeout_checker:1.0

file delete -force $work_dir
file mkdir $work_dir
create_project ip_consumer_test $work_dir -part $part -force
set_property ip_repo_paths [list $ip_repo] [current_project]
update_ip_catalog

if {[llength [get_ipdefs -all $expected_vlnv]] != 1} {
    error "Packaged IP not found in catalog: $expected_vlnv"
}

create_ip -vlnv $expected_vlnv -module_name dut_timeout_checker
set_property -dict [list CONFIG.TIMEOUT_CYCLES {7}] [get_ips dut_timeout_checker]
if {[get_property CONFIG.TIMEOUT_CYCLES [get_ips dut_timeout_checker]] ne "7"} {
    error "TIMEOUT_CYCLES customization did not take effect"
}

generate_target all [get_ips dut_timeout_checker]
create_ip_run [get_ips dut_timeout_checker]
set ip_run [get_runs dut_timeout_checker_synth_1]
launch_runs $ip_run -jobs 1
wait_on_run $ip_run

set run_status [get_property STATUS $ip_run]
set dcp_file [get_property DIRECTORY $ip_run]/dut_timeout_checker.dcp
if {![string match "synth_design Complete*" $run_status]} {
    error "IP synthesis did not complete: $run_status"
}
if {![file exists $dcp_file]} {
    error "IP synthesis checkpoint was not generated: $dcp_file"
}

puts "M8_VALIDATE_VLNV=$expected_vlnv"
puts "M8_VALIDATE_TIMEOUT_CYCLES=[get_property CONFIG.TIMEOUT_CYCLES [get_ips dut_timeout_checker]]"
puts "M8_VALIDATE_RUN_STATUS=$run_status"
puts "M8_VALIDATE_DCP=$dcp_file"
puts "M8_VALIDATE_PASS"
close_project

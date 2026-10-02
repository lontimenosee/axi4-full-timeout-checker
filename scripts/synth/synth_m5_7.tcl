set root [file normalize [file join [file dirname [info script]] ../..]]
set part [expr {[info exists ::env(FPGA_PART)] ? $::env(FPGA_PART) : "xc7a35tcpg236-1"}]
set out [file join $root reports synth]
file mkdir $out
read_verilog [file join $root rtl axi4_timeout_checker.v]
read_xdc [file join $root constraints axi4_timeout_checker.xdc]
synth_design -top axi4_timeout_checker -part $part -generic TIMEOUT_CYCLES=16
opt_design
report_utilization -file [file join $out utilization.rpt]
report_timing_summary -delay_type max -max_paths 10 -file [file join $out timing_summary.rpt]
report_methodology -file [file join $out methodology.rpt]
write_checkpoint -force [file join $out axi4_timeout_checker_synth.dcp]
set wns [get_property SLACK [lindex [get_timing_paths -delay_type max -max_paths 1] 0]]
puts "M5_7_SYNTH_PART=$part"
puts "M5_7_SYNTH_WNS=$wns"
if {$wns < 0} { error "Timing failed: WNS=$wns" }
puts "M5_7_SYNTH_PASS"

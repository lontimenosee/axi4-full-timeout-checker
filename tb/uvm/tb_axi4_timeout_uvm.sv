`timescale 1ns/1ps
module tb_axi4_timeout_uvm;
 import uvm_pkg::*; import axi_timeout_pkg::*;
 logic aclk=0; always #5 aclk=~aclk;
 axi_timeout_if intf(aclk);
 axi4_timeout_checker #(.TIMEOUT_CYCLES(4)) dut(.aclk(aclk),.aresetn(intf.aresetn),.awvalid(intf.awvalid),.awready(intf.awready),.wvalid(intf.wvalid),.wready(intf.wready),.wlast(intf.wlast),.bvalid(intf.bvalid),.bready(intf.bready),.arvalid(intf.arvalid),.arready(intf.arready),.rvalid(intf.rvalid),.rready(intf.rready),.rlast(intf.rlast),.timeout_irq(intf.timeout_irq),.timeout_status(intf.timeout_status));
 initial begin intf.aresetn=0;intf.awvalid=0;intf.awready=0;intf.wvalid=0;intf.wready=0;intf.wlast=0;intf.bvalid=0;intf.bready=0;intf.arvalid=0;intf.arready=0;intf.rvalid=0;intf.rready=0;intf.rlast=0;uvm_config_db#(virtual axi_timeout_if)::set(null,"*","vif",intf);uvm_config_db#(int)::set(null,"*","timeout_cycles",4);run_test();end
endmodule

module axi4_timeout_checker_sva(
  input wire aclk, aresetn,
  input wire awvalid,awready,wvalid,wready,wlast,bvalid,bready,
  input wire arvalid,arready,rvalid,rready,rlast,
  input wire timeout_irq,input wire [4:0] timeout_status,
  input wire [1:0] write_state,input wire read_state
);
  localparam [1:0] WR_IDLE=0,WR_WAIT_W=1,WR_WAIT_B=2;
  localparam RD_IDLE=0,RD_WAIT_R=1;
  default clocking cb @(posedge aclk); endclocking
  ap_reset: assert property (!aresetn |-> (timeout_irq==0 && timeout_status==0));
  ap_known: assert property (aresetn |-> !$isunknown({timeout_irq,timeout_status,write_state,read_state}));
  ap_write_legal: assert property (aresetn |-> write_state inside {WR_IDLE,WR_WAIT_W,WR_WAIT_B});
  ap_read_legal: assert property (aresetn |-> read_state inside {RD_IDLE,RD_WAIT_R});
  ap_status_sticky: assert property (aresetn && $past(aresetn) |->
                                     (timeout_status | $past(timeout_status))==timeout_status);
  ap_aw_to_w: assert property (disable iff(!aresetn)
    write_state==WR_IDLE && awvalid&&awready && !(wvalid&&wready&&wlast) |=> write_state==WR_WAIT_W);
  ap_aw_wlast_to_b: assert property (disable iff(!aresetn)
    write_state==WR_IDLE && awvalid&&awready && wvalid&&wready&&wlast |=> write_state==WR_WAIT_B);
  ap_wlast_to_b: assert property (disable iff(!aresetn)
    write_state==WR_WAIT_W && wvalid&&wready&&wlast |=> write_state==WR_WAIT_B);
  ap_b_to_idle: assert property (disable iff(!aresetn)
    write_state==WR_WAIT_B && bvalid&&bready |=> write_state==WR_IDLE);
  ap_ar_to_r: assert property (disable iff(!aresetn)
    read_state==RD_IDLE && arvalid&&arready && !(rvalid&&rready&&rlast) |=> read_state==RD_WAIT_R);
  ap_ar_rlast_idle: assert property (disable iff(!aresetn)
    read_state==RD_IDLE && arvalid&&arready && rvalid&&rready&&rlast |=> read_state==RD_IDLE);
  ap_rlast_idle: assert property (disable iff(!aresetn)
    read_state==RD_WAIT_R && rvalid&&rready&&rlast |=> read_state==RD_IDLE);
endmodule

bind axi4_timeout_checker axi4_timeout_checker_sva sva_i(
 .aclk(aclk),.aresetn(aresetn),.awvalid(awvalid),.awready(awready),
 .wvalid(wvalid),.wready(wready),.wlast(wlast),.bvalid(bvalid),.bready(bready),
 .arvalid(arvalid),.arready(arready),.rvalid(rvalid),.rready(rready),.rlast(rlast),
 .timeout_irq(timeout_irq),.timeout_status(timeout_status),.write_state(write_state),.read_state(read_state));

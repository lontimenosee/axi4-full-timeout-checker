interface axi_timeout_if(input logic aclk);
  logic aresetn;
  logic awvalid, awready;
  logic wvalid, wready, wlast;
  logic bvalid, bready;
  logic arvalid, arready;
  logic rvalid, rready, rlast;
  logic timeout_irq;
  logic [4:0] timeout_status;
endinterface

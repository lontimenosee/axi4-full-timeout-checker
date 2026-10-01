`timescale 1ns/1ps

module tb_axi4_timeout_checker_timeout1;
    reg aclk = 0;
    reg aresetn = 1;
    reg awvalid = 0, awready = 0;
    reg wvalid = 0, wready = 0, wlast = 0;
    reg bvalid = 0, bready = 0;
    reg arvalid = 0, arready = 0;
    reg rvalid = 0, rready = 0, rlast = 0;
    wire timeout_irq;
    wire [4:0] timeout_status;

    always #5 aclk = ~aclk;

    axi4_timeout_checker #(.TIMEOUT_CYCLES(1)) dut (
        .aclk(aclk), .aresetn(aresetn),
        .awvalid(awvalid), .awready(awready),
        .wvalid(wvalid), .wready(wready), .wlast(wlast),
        .bvalid(bvalid), .bready(bready),
        .arvalid(arvalid), .arready(arready),
        .rvalid(rvalid), .rready(rready), .rlast(rlast),
        .timeout_irq(timeout_irq), .timeout_status(timeout_status)
    );

    initial begin
        #1 aresetn = 0;
        #1;
        if (timeout_status !== 5'b00000)
            $fatal(1, "TIMEOUT_CYCLES=1 reset status failed");
        repeat (2) @(posedge aclk);
        @(negedge aclk); aresetn = 1; awvalid = 1;
        @(posedge aclk); #1;
        if (timeout_status !== 5'b00001 || timeout_irq !== 1'b1)
            $fatal(1, "TIMEOUT_CYCLES=1 must timeout on first stalled cycle");
        @(posedge aclk); #1;
        if (timeout_status !== 5'b00001 || timeout_irq !== 1'b0)
            $fatal(1, "TIMEOUT_CYCLES=1 irq must be one-shot and status sticky");
        $display("M2 TIMEOUT_CYCLES=1 TEST PASSED");
        $finish;
    end
endmodule

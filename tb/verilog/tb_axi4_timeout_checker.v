`timescale 1ns/1ps

module tb_axi4_timeout_checker;
    localparam integer TIMEOUT_CYCLES = 4;
    localparam integer CLK_PERIOD_NS  = 10;

    reg aclk, aresetn;
    reg awvalid, awready;
    reg wvalid, wready, wlast;
    reg bvalid, bready;
    reg arvalid, arready;
    reg rvalid, rready, rlast;
    wire timeout_irq;
    wire [4:0] timeout_status;
    integer irq_count;

    axi4_timeout_checker #(.TIMEOUT_CYCLES(TIMEOUT_CYCLES)) dut (
        .aclk(aclk), .aresetn(aresetn),
        .awvalid(awvalid), .awready(awready),
        .wvalid(wvalid), .wready(wready), .wlast(wlast),
        .bvalid(bvalid), .bready(bready),
        .arvalid(arvalid), .arready(arready),
        .rvalid(rvalid), .rready(rready), .rlast(rlast),
        .timeout_irq(timeout_irq), .timeout_status(timeout_status)
    );

    initial aclk = 0;
    always #(CLK_PERIOD_NS/2) aclk = ~aclk;

    always @(posedge aclk or negedge aresetn) begin
        if (!aresetn)
            irq_count <= 0;
        else if (timeout_irq)
            irq_count <= irq_count + 1;
    end

    task drive_idle;
        begin
            awvalid = 0; awready = 0;
            wvalid = 0; wready = 0; wlast = 0;
            bvalid = 0; bready = 0;
            arvalid = 0; arready = 0;
            rvalid = 0; rready = 0; rlast = 0;
        end
    endtask

    task reset_dut;
        begin
            @(negedge aclk);
            drive_idle();
            aresetn = 0;
            #1;
            if (timeout_status !== 5'b00000 || timeout_irq !== 1'b0)
                $fatal(1, "reset did not clear timeout outputs");
            repeat (2) @(posedge aclk);
            @(negedge aclk);
            aresetn = 1;
        end
    endtask

    task expect_outputs;
        input [4:0] expected_status;
        input       expected_irq;
        input [8*80-1:0] test_name;
        begin
            #1;
            if (timeout_status !== expected_status || timeout_irq !== expected_irq) begin
                $display("FAIL: %0s", test_name);
                $display("      status expected %05b got %05b; irq expected %0b got %0b",
                         expected_status, timeout_status, expected_irq, timeout_irq);
                $fatal(1, "M2 TESTS FAILED");
            end
        end
    endtask

    task aw_handshake;
        begin
            @(negedge aclk); awvalid = 1; awready = 1;
            @(posedge aclk);
            @(negedge aclk); awvalid = 0; awready = 0;
        end
    endtask

    task w_handshake;
        input last;
        begin
            @(negedge aclk); wvalid = 1; wready = 1; wlast = last;
            @(posedge aclk);
            @(negedge aclk); wvalid = 0; wready = 0; wlast = 0;
        end
    endtask

    task b_handshake;
        begin
            @(negedge aclk); bvalid = 1; bready = 1;
            @(posedge aclk);
            @(negedge aclk); bvalid = 0; bready = 0;
        end
    endtask

    task ar_handshake;
        begin
            @(negedge aclk); arvalid = 1; arready = 1;
            @(posedge aclk);
            @(negedge aclk); arvalid = 0; arready = 0;
        end
    endtask

    task r_handshake;
        input last;
        begin
            @(negedge aclk); rvalid = 1; rready = 1; rlast = last;
            @(posedge aclk);
            @(negedge aclk); rvalid = 0; rready = 0; rlast = 0;
        end
    endtask

    task test_normal_write;
        begin
            $display("TEST: normal burst write has no timeout");
            reset_dut();
            aw_handshake();
            w_handshake(0);
            w_handshake(0);
            w_handshake(1);
            b_handshake();
            expect_outputs(5'b00000, 0, "normal burst write");
        end
    endtask

    task test_aw_timeout_and_one_shot;
        begin
            $display("TEST: AW timeout boundary and one-shot");
            reset_dut();
            @(negedge aclk); awvalid = 1; awready = 0;
            repeat (TIMEOUT_CYCLES-1) @(posedge aclk);
            expect_outputs(5'b00000, 0, "AW must not timeout before threshold");
            @(posedge aclk);
            expect_outputs(5'b00001, 1, "AW must timeout at threshold");
            repeat (TIMEOUT_CYCLES+1) @(posedge aclk);
            expect_outputs(5'b00001, 0, "AW timeout must be one-shot");
            if (irq_count !== 1)
                $fatal(1, "AW one-shot expected one irq, got %0d", irq_count);
        end
    endtask

    task test_aw_boundary_handshake;
        begin
            $display("TEST: AW handshake wins on timeout boundary");
            reset_dut();
            @(negedge aclk); awvalid = 1; awready = 0;
            repeat (TIMEOUT_CYCLES-1) @(posedge aclk);
            @(negedge aclk); awready = 1;
            @(posedge aclk);
            expect_outputs(5'b00000, 0, "AW boundary handshake");
            @(negedge aclk); awvalid = 0; awready = 0;
            w_handshake(1);
            b_handshake();
        end
    endtask

    task test_w_timeout_and_recovery;
        begin
            $display("TEST: W timeout, one-shot, recovery, and next transaction");
            reset_dut();
            aw_handshake();
            repeat (TIMEOUT_CYCLES) @(posedge aclk);
            expect_outputs(5'b00010, 1, "W timeout missing");
            repeat (TIMEOUT_CYCLES+1) @(posedge aclk);
            expect_outputs(5'b00010, 0, "W timeout must be one-shot");
            if (irq_count !== 1)
                $fatal(1, "W one-shot expected one irq, got %0d", irq_count);
            w_handshake(1);
            b_handshake();
            aw_handshake();
            repeat (TIMEOUT_CYCLES) @(posedge aclk);
            expect_outputs(5'b00010, 1, "new write transaction must report W timeout again");
        end
    endtask

    task test_w_progress_and_boundary;
        begin
            $display("TEST: W beat resets counter and boundary handshake wins");
            reset_dut();
            aw_handshake();
            repeat (TIMEOUT_CYCLES-1) @(posedge aclk);
            w_handshake(0);
            repeat (TIMEOUT_CYCLES-1) @(posedge aclk);
            expect_outputs(5'b00000, 0, "W progress must reset timeout counter");
            w_handshake(1);
            expect_outputs(5'b00000, 0, "W boundary handshake must win");
            b_handshake();
        end
    endtask

    task test_b_timeout_and_recovery;
        begin
            $display("TEST: B timeout, one-shot, and recovery");
            reset_dut();
            aw_handshake();
            w_handshake(1);
            repeat (TIMEOUT_CYCLES) @(posedge aclk);
            expect_outputs(5'b00100, 1, "B timeout missing");
            repeat (TIMEOUT_CYCLES+1) @(posedge aclk);
            expect_outputs(5'b00100, 0, "B timeout must be one-shot");
            if (irq_count !== 1)
                $fatal(1, "B one-shot expected one irq, got %0d", irq_count);
            b_handshake();
            expect_outputs(5'b00100, 0, "B timeout status must remain sticky after recovery");
        end
    endtask

    task test_normal_read;
        begin
            $display("TEST: normal burst read has no timeout");
            reset_dut();
            ar_handshake();
            r_handshake(0);
            r_handshake(0);
            r_handshake(1);
            expect_outputs(5'b00000, 0, "normal burst read");
        end
    endtask

    task test_ar_timeout_and_boundary;
        begin
            $display("TEST: AR timeout, one-shot, and boundary handshake");
            reset_dut();
            @(negedge aclk); arvalid = 1; arready = 0;
            repeat (TIMEOUT_CYCLES-1) @(posedge aclk);
            expect_outputs(5'b00000, 0, "AR must not timeout before threshold");
            @(posedge aclk);
            expect_outputs(5'b01000, 1, "AR timeout missing");
            repeat (TIMEOUT_CYCLES+1) @(posedge aclk);
            expect_outputs(5'b01000, 0, "AR timeout must be one-shot");
            if (irq_count !== 1)
                $fatal(1, "AR one-shot expected one irq, got %0d", irq_count);

            reset_dut();
            @(negedge aclk); arvalid = 1; arready = 0;
            repeat (TIMEOUT_CYCLES-1) @(posedge aclk);
            @(negedge aclk); arready = 1;
            @(posedge aclk);
            expect_outputs(5'b00000, 0, "AR boundary handshake must win");
            @(negedge aclk); arvalid = 0; arready = 0;
            r_handshake(1);
        end
    endtask

    task test_r_timeout_and_recovery;
        begin
            $display("TEST: R timeout, one-shot, recovery, and next transaction");
            reset_dut();
            ar_handshake();
            repeat (TIMEOUT_CYCLES) @(posedge aclk);
            expect_outputs(5'b10000, 1, "R timeout missing");
            repeat (TIMEOUT_CYCLES+1) @(posedge aclk);
            expect_outputs(5'b10000, 0, "R timeout must be one-shot");
            if (irq_count !== 1)
                $fatal(1, "R one-shot expected one irq, got %0d", irq_count);
            r_handshake(1);
            ar_handshake();
            repeat (TIMEOUT_CYCLES) @(posedge aclk);
            expect_outputs(5'b10000, 1, "new read transaction must report R timeout again");
        end
    endtask

    task test_r_progress_and_boundary;
        begin
            $display("TEST: R beat resets counter and boundary handshake wins");
            reset_dut();
            ar_handshake();
            repeat (TIMEOUT_CYCLES-1) @(posedge aclk);
            r_handshake(0);
            repeat (TIMEOUT_CYCLES-1) @(posedge aclk);
            expect_outputs(5'b00000, 0, "R progress must reset timeout counter");
            r_handshake(1);
            expect_outputs(5'b00000, 0, "R boundary handshake must win");
        end
    endtask

    task test_parallel_timeouts;
        begin
            $display("TEST: simultaneous W and R timeouts preserve both status bits");
            reset_dut();
            @(negedge aclk);
            awvalid = 1; awready = 1;
            arvalid = 1; arready = 1;
            @(posedge aclk);
            @(negedge aclk);
            awvalid = 0; awready = 0;
            arvalid = 0; arready = 0;
            repeat (TIMEOUT_CYCLES) @(posedge aclk);
            expect_outputs(5'b10010, 1, "simultaneous W and R timeout");
            @(posedge aclk);
            expect_outputs(5'b10010, 0, "parallel timeout irq must last one cycle");
            if (irq_count !== 1)
                $fatal(1, "parallel timeouts should share one irq pulse, got %0d", irq_count);
        end
    endtask

    task test_async_reset_mid_transaction;
        begin
            $display("TEST: asynchronous reset clears active transactions and sticky status");
            reset_dut();
            aw_handshake();
            repeat (TIMEOUT_CYCLES) @(posedge aclk);
            expect_outputs(5'b00010, 1, "precondition W timeout");

            @(negedge aclk);
            #2 aresetn = 0;
            #1;
            if (timeout_status !== 5'b00000 || timeout_irq !== 1'b0)
                $fatal(1, "asynchronous reset failed to clear outputs immediately");
            drive_idle();
            repeat (2) @(posedge aclk);
            @(negedge aclk); aresetn = 1;
            repeat (TIMEOUT_CYCLES+1) @(posedge aclk);
            expect_outputs(5'b00000, 0, "reset must discard active transaction state");
        end
    endtask

    initial begin
        aresetn = 0;
        drive_idle();
        test_normal_write();
        test_aw_timeout_and_one_shot();
        test_aw_boundary_handshake();
        test_w_timeout_and_recovery();
        test_w_progress_and_boundary();
        test_b_timeout_and_recovery();
        test_normal_read();
        test_ar_timeout_and_boundary();
        test_r_timeout_and_recovery();
        test_r_progress_and_boundary();
        test_parallel_timeouts();
        test_async_reset_mid_transaction();
        $display("M2 TESTS PASSED");
        $finish;
    end
endmodule

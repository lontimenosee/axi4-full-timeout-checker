`timescale 1ns/1ps

module axi4_timeout_checker #(
    parameter integer TIMEOUT_CYCLES = 16
)(
    input  wire       aclk,
    input  wire       aresetn,
    input  wire       awvalid,
    input  wire       awready,
    input  wire       wvalid,
    input  wire       wready,
    input  wire       wlast,
    input  wire       bvalid,
    input  wire       bready,
    input  wire       arvalid,
    input  wire       arready,
    input  wire       rvalid,
    input  wire       rready,
    input  wire       rlast,
    output reg        timeout_irq,
    output reg [4:0]  timeout_status
);

    function integer clog2;
        input integer value;
        integer temp;
        begin
            temp = value - 1;
            clog2 = 0;
            while (temp > 0) begin
                temp = temp >> 1;
                clog2 = clog2 + 1;
            end
        end
    endfunction

    localparam integer TIMEOUT_CNT_WIDTH =
        (TIMEOUT_CYCLES <= 1) ? 1 : clog2(TIMEOUT_CYCLES);
    localparam [TIMEOUT_CNT_WIDTH-1:0] TIMEOUT_LIMIT = TIMEOUT_CYCLES - 1;

    localparam [1:0] WR_IDLE   = 2'd0;
    localparam [1:0] WR_WAIT_W = 2'd1;
    localparam [1:0] WR_WAIT_B = 2'd2;
    localparam       RD_IDLE   = 1'b0;
    localparam       RD_WAIT_R = 1'b1;

    reg [1:0] write_state;
    reg       read_state;
    reg [TIMEOUT_CNT_WIDTH-1:0] aw_timeout_cnt;
    reg [TIMEOUT_CNT_WIDTH-1:0] w_timeout_cnt;
    reg [TIMEOUT_CNT_WIDTH-1:0] b_timeout_cnt;
    reg aw_timeout_reported;
    reg w_timeout_reported;
    reg b_timeout_reported;
    reg [TIMEOUT_CNT_WIDTH-1:0] ar_timeout_cnt;
    reg [TIMEOUT_CNT_WIDTH-1:0] r_timeout_cnt;
    reg ar_timeout_reported;
    reg r_timeout_reported;

    always @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            write_state         <= WR_IDLE;
            aw_timeout_cnt      <= {TIMEOUT_CNT_WIDTH{1'b0}};
            w_timeout_cnt       <= {TIMEOUT_CNT_WIDTH{1'b0}};
            b_timeout_cnt       <= {TIMEOUT_CNT_WIDTH{1'b0}};
            aw_timeout_reported <= 1'b0;
            w_timeout_reported  <= 1'b0;
            b_timeout_reported  <= 1'b0;
            read_state          <= RD_IDLE;
            ar_timeout_cnt      <= {TIMEOUT_CNT_WIDTH{1'b0}};
            r_timeout_cnt       <= {TIMEOUT_CNT_WIDTH{1'b0}};
            ar_timeout_reported <= 1'b0;
            r_timeout_reported  <= 1'b0;
            timeout_irq         <= 1'b0;
            timeout_status      <= 5'b00000;
        end else begin
            timeout_irq <= 1'b0;

            case (write_state)
                WR_IDLE: begin
                    w_timeout_cnt      <= {TIMEOUT_CNT_WIDTH{1'b0}};
                    b_timeout_cnt      <= {TIMEOUT_CNT_WIDTH{1'b0}};
                    w_timeout_reported <= 1'b0;
                    b_timeout_reported <= 1'b0;

                    if (awvalid && awready) begin
                        aw_timeout_cnt      <= {TIMEOUT_CNT_WIDTH{1'b0}};
                        aw_timeout_reported <= 1'b0;

                        if (wvalid && wready && wlast)
                            write_state <= WR_WAIT_B;
                        else
                            write_state <= WR_WAIT_W;
                    end else if (awvalid) begin
                        if (!aw_timeout_reported) begin
                            if (aw_timeout_cnt == TIMEOUT_LIMIT) begin
                                timeout_status[0] <= 1'b1;
                                timeout_irq         <= 1'b1;
                                aw_timeout_reported <= 1'b1;
                            end else begin
                                aw_timeout_cnt <= aw_timeout_cnt + 1'b1;
                            end
                        end
                    end else begin
                        aw_timeout_cnt      <= {TIMEOUT_CNT_WIDTH{1'b0}};
                        aw_timeout_reported <= 1'b0;
                    end
                end

                WR_WAIT_W: begin
                    aw_timeout_cnt      <= {TIMEOUT_CNT_WIDTH{1'b0}};
                    b_timeout_cnt       <= {TIMEOUT_CNT_WIDTH{1'b0}};
                    aw_timeout_reported <= 1'b0;
                    b_timeout_reported  <= 1'b0;

                    if (wvalid && wready) begin
                        w_timeout_cnt <= {TIMEOUT_CNT_WIDTH{1'b0}};
                        if (wlast) begin
                            w_timeout_reported <= 1'b0;
                            write_state        <= WR_WAIT_B;
                        end
                    end else if (!w_timeout_reported) begin
                        if (w_timeout_cnt == TIMEOUT_LIMIT) begin
                            timeout_status[1] <= 1'b1;
                            timeout_irq        <= 1'b1;
                            w_timeout_reported <= 1'b1;
                        end else begin
                            w_timeout_cnt <= w_timeout_cnt + 1'b1;
                        end
                    end
                end

                WR_WAIT_B: begin
                    aw_timeout_cnt      <= {TIMEOUT_CNT_WIDTH{1'b0}};
                    w_timeout_cnt       <= {TIMEOUT_CNT_WIDTH{1'b0}};
                    aw_timeout_reported <= 1'b0;
                    w_timeout_reported  <= 1'b0;

                    if (bvalid && bready) begin
                        b_timeout_cnt      <= {TIMEOUT_CNT_WIDTH{1'b0}};
                        b_timeout_reported <= 1'b0;
                        write_state        <= WR_IDLE;
                    end else if (!b_timeout_reported) begin
                        if (b_timeout_cnt == TIMEOUT_LIMIT) begin
                            timeout_status[2] <= 1'b1;
                            timeout_irq        <= 1'b1;
                            b_timeout_reported <= 1'b1;
                        end else begin
                            b_timeout_cnt <= b_timeout_cnt + 1'b1;
                        end
                    end
                end

                default: begin
                    write_state         <= WR_IDLE;
                    aw_timeout_cnt      <= {TIMEOUT_CNT_WIDTH{1'b0}};
                    w_timeout_cnt       <= {TIMEOUT_CNT_WIDTH{1'b0}};
                    b_timeout_cnt       <= {TIMEOUT_CNT_WIDTH{1'b0}};
                    aw_timeout_reported <= 1'b0;
                    w_timeout_reported  <= 1'b0;
                    b_timeout_reported  <= 1'b0;
                end
            endcase

            case (read_state)
                RD_IDLE: begin
                    r_timeout_cnt      <= {TIMEOUT_CNT_WIDTH{1'b0}};
                    r_timeout_reported <= 1'b0;

                    if (arvalid && arready) begin
                        ar_timeout_cnt      <= {TIMEOUT_CNT_WIDTH{1'b0}};
                        ar_timeout_reported <= 1'b0;

                        if (rvalid && rready && rlast)
                            read_state <= RD_IDLE;
                        else
                            read_state <= RD_WAIT_R;
                    end else if (arvalid) begin
                        if (!ar_timeout_reported) begin
                            if (ar_timeout_cnt == TIMEOUT_LIMIT) begin
                                timeout_status[3] <= 1'b1;
                                timeout_irq         <= 1'b1;
                                ar_timeout_reported <= 1'b1;
                            end else begin
                                ar_timeout_cnt <= ar_timeout_cnt + 1'b1;
                            end
                        end
                    end else begin
                        ar_timeout_cnt      <= {TIMEOUT_CNT_WIDTH{1'b0}};
                        ar_timeout_reported <= 1'b0;
                    end
                end

                RD_WAIT_R: begin
                    ar_timeout_cnt      <= {TIMEOUT_CNT_WIDTH{1'b0}};
                    ar_timeout_reported <= 1'b0;

                    if (rvalid && rready) begin
                        r_timeout_cnt <= {TIMEOUT_CNT_WIDTH{1'b0}};
                        if (rlast) begin
                            r_timeout_reported <= 1'b0;
                            read_state         <= RD_IDLE;
                        end
                    end else if (!r_timeout_reported) begin
                        if (r_timeout_cnt == TIMEOUT_LIMIT) begin
                            timeout_status[4] <= 1'b1;
                            timeout_irq        <= 1'b1;
                            r_timeout_reported <= 1'b1;
                        end else begin
                            r_timeout_cnt <= r_timeout_cnt + 1'b1;
                        end
                    end
                end

                default: begin
                    read_state          <= RD_IDLE;
                    ar_timeout_cnt      <= {TIMEOUT_CNT_WIDTH{1'b0}};
                    r_timeout_cnt       <= {TIMEOUT_CNT_WIDTH{1'b0}};
                    ar_timeout_reported <= 1'b0;
                    r_timeout_reported  <= 1'b0;
                end
            endcase
        end
    end

endmodule

# AXI4-Full Timeout Checker 设计方案

## 1. 文档目的

本文档描述 AXI4-Full Timeout Checker v0.1 的 RTL 微架构设计。

设计依据为：

- `docs/specification.md`

当前版本主要目标是在有限开发周期内完成一个可综合、可验证、可进行 Lint、综合以及 Vivado IP 封装的 AXI4-Full 超时检查器。

本设计采用旁路监控结构，不参与 AXI 数据传输。

---

## 2. 总体架构

Timeout Checker 主要由以下几个部分组成：

1. 写地址 AW 超时监控
2. 写事务状态机
3. 写数据 W 超时监控
4. 写响应 B 超时监控
5. 读地址 AR 超时监控
6. 读事务状态机
7. 读数据 R 超时监控
8. Timeout 状态记录与中断生成

总体结构如下：

```text
                         AXI4-Full Bus
                               │
          ┌────────────────────┼────────────────────┐
          │                    │                    │
          ▼                    ▼                    ▼
   Write Address          Write Data         Write Response
        AW                    W                    B
          │                    │                    │
          └──────────────┬─────┴─────┬──────────────┘
                         │
                         ▼
                  Write Monitor
                         │
                         ▼
                Write State Machine

                    WR_IDLE
                        │
                        ▼
                    WR_WAIT_W
                        │
                        ▼
                    WR_WAIT_B
                        │
                        ▼
                    WR_IDLE


   Read Address                              Read Data
       AR                                       R
        │                                       │
        └──────────────────┬────────────────────┘
                           │
                           ▼
                     Read Monitor
                           │
                           ▼
                   Read State Machine

                     RD_IDLE
                        │
                        ▼
                     RD_WAIT_R
                        │
                        ▼
                     RD_IDLE


              Write Monitor    Read Monitor
                    │              │
                    └──────┬───────┘
                           ▼
                   Timeout Event Logic
                           │
                  ┌────────┴─────────┐
                  ▼                  ▼
          timeout_status       timeout_irq
```

---

## 3. 顶层模块

顶层模块名称：

```text
axi4_timeout_checker
```

RTL 文件：

```text
rtl/axi4_timeout_checker.v
```

当前 MVP 版本优先采用单模块实现。

原因是当前设计规模较小，如果过度拆分模块，会增加接口连接、调试和验证工作量。

当后续版本增加 Multi-Outstanding、ID Tracker 等功能时，再将 Write Tracker、Read Tracker 等功能独立拆分为子模块。

---

## 4. 顶层输入输出

### 4.1 时钟与复位

```verilog
input wire aclk;
input wire aresetn;
```

所有状态和计数逻辑工作在 `aclk` 时钟域。

RTL 采用低有效异步复位形式：

```verilog
always @(posedge aclk or negedge aresetn)
```

设计假定 `aresetn` 的释放满足系统时钟域要求。

如果系统输入复位为完全异步信号，应在系统级完成同步释放处理。

---

## 5. AXI 输入信号

当前 Checker 只观察完成超时检测所需要的 AXI4-Full 信号。

### 5.1 AW Channel

```verilog
input wire awvalid;
input wire awready;
```

### 5.2 W Channel

```verilog
input wire wvalid;
input wire wready;
input wire wlast;
```

### 5.3 B Channel

```verilog
input wire bvalid;
input wire bready;
```

### 5.4 AR Channel

```verilog
input wire arvalid;
input wire arready;
```

### 5.5 R Channel

```verilog
input wire rvalid;
input wire rready;
input wire rlast;
```

Checker 不驱动以上任何 AXI 信号。

---

## 6. 输出信号

### 6.1 timeout_irq

```verilog
output reg timeout_irq;
```

检测到新的超时事件时：

```text
timeout_irq = 1
```

持续一个时钟周期。

之后自动恢复为：

```text
timeout_irq = 0
```

### 6.2 timeout_status

```verilog
output reg [4:0] timeout_status;
```

定义如下：

| Bit | Timeout 类型 |
| --- | --- |
| `timeout_status[0]` | AW_TIMEOUT |
| `timeout_status[1]` | W_TIMEOUT |
| `timeout_status[2]` | B_TIMEOUT |
| `timeout_status[3]` | AR_TIMEOUT |
| `timeout_status[4]` | R_TIMEOUT |

`timeout_status` 为 sticky 状态。

对应 timeout 发生以后，相应 bit 置 1，并保持到复位。

---

## 7. Write Transaction 状态机

写事务采用三状态 FSM：

```text
WR_IDLE
WR_WAIT_W
WR_WAIT_B
```

状态转移如下：

```text
                           AW handshake
                ┌─────────────────────────┐
                │                         ▼
          ┌───────────┐             ┌───────────┐
          │  WR_IDLE  │             │ WR_WAIT_W │
          └───────────┘             └─────┬─────┘
                ▲                         │
                │                         │ WLAST handshake
                │                         ▼
                │                   ┌───────────┐
                └───────────────────│ WR_WAIT_B │
                    B handshake     └───────────┘
```

### 7.1 WR_IDLE

表示当前不存在正在跟踪的写事务。

在此状态：

- AW timeout monitor 有效。

如果发生：

```text
awvalid && awready
```

则认为写地址握手完成，状态进入：

```text
WR_WAIT_W
```

### 7.2 WR_WAIT_W

表示写地址已经完成，等待写数据传输。

每次发生：

```text
wvalid && wready
```

表示成功传输一个 Write Data Beat。

如果发生：

```text
wvalid && wready && wlast
```

表示最后一个 Write Data Beat 完成，状态进入：

```text
WR_WAIT_B
```

### 7.3 WR_WAIT_B

表示 Write Burst 已经发送完毕，等待 Write Response。

当发生：

```text
bvalid && bready
```

时，写事务完成，状态返回：

```text
WR_IDLE
```

---

## 8. Read Transaction 状态机

读事务采用两个状态：

```text
RD_IDLE
RD_WAIT_R
```

状态转移如下：

```text
                         AR handshake
                ┌─────────────────────────┐
                │                         ▼
          ┌───────────┐             ┌───────────┐
          │  RD_IDLE  │             │ RD_WAIT_R │
          └───────────┘             └─────┬─────┘
                ▲                         │
                │                         │ RLAST handshake
                └─────────────────────────┘
```

### 8.1 RD_IDLE

表示当前没有正在跟踪的读事务。

AR timeout monitor 有效。

当发生：

```text
arvalid && arready
```

后，状态进入：

```text
RD_WAIT_R
```

### 8.2 RD_WAIT_R

表示已经完成 AR handshake，正在等待 Read Data。

每次发生：

```text
rvalid && rready
```

表示一个 Read Data Beat 成功传输。

当发生：

```text
rvalid && rready && rlast
```

时，表示整个 Read Burst 完成，状态返回：

```text
RD_IDLE
```

---

## 9. Timeout Counter 设计

当前版本使用 5 个独立计数器：

```text
aw_timeout_cnt
w_timeout_cnt
b_timeout_cnt
ar_timeout_cnt
r_timeout_cnt
```

虽然 W 和 B 不会同时处于有效监控状态，理论上可以共用一个 Write Timeout Counter，但当前版本仍采用独立计数器。

原因如下：

- RTL 更直观
- 验证更简单
- 波形更容易观察
- 资源开销很小
- 减少状态复用导致的潜在错误

---

## 10. Counter 位宽

Counter 位宽根据 `TIMEOUT_CYCLES` 自动计算。

由于 RTL 使用 Verilog HDL，设计内部实现一个 `clog2` 函数。

示例：

```verilog
function integer clog2;
    input integer value;
    integer i;
    begin
        value = value - 1;
        for (i = 0; value > 0; i = i + 1)
            value = value >> 1;
        clog2 = i;
    end
endfunction
```

然后：

```verilog
localparam TIMEOUT_CNT_WIDTH =
    (TIMEOUT_CYCLES <= 1) ? 1 : clog2(TIMEOUT_CYCLES);
```

这样可以避免直接使用固定 32 bit counter。

---

## 11. Timeout 判定规则

假设：

```text
TIMEOUT_CYCLES = 4
```

初始：

```text
counter = 0
```

连续无进展时：

```text
第 1 个无进展周期：counter = 1
第 2 个无进展周期：counter = 2
第 3 个无进展周期：counter = 3
第 4 个无进展周期：产生 timeout
```

RTL 判断形式计划为：

```verilog
if (timeout_cnt == TIMEOUT_CYCLES - 1)
```

但必须保证：

> handshake 判断优先于 timeout 判断。

例如第 4 个周期同时出现：

```text
awvalid = 1
awready = 1
```

则认为 AW handshake 成功，不产生 AW_TIMEOUT。

---

## 12. AW Timeout 设计

AW monitor 只在：

```text
write_state == WR_IDLE
```

时工作。

如果：

```text
awvalid && awready
```

则：

```text
aw_timeout_cnt = 0
```

并进入 `WR_WAIT_W`。

如果：

```text
awvalid && !awready
```

则累计 AW timeout counter。

如果：

```text
awvalid == 0
```

说明当前没有有效 AW 请求，此时：

```text
aw_timeout_cnt = 0
```

避免把不同 AWVALID 请求之间的空闲周期累积起来。

---

## 13. W Timeout 设计

W timeout monitor 只在：

```text
write_state == WR_WAIT_W
```

时工作。

如果：

```text
wvalid && wready
```

发生，说明写事务产生有效进展：

```text
w_timeout_cnt = 0
```

如果同时：

```text
wlast == 1
```

则进入：

```text
WR_WAIT_B
```

如果在 `WR_WAIT_W` 中连续没有发生：

```text
wvalid && wready
```

则 counter 累计。

达到 `TIMEOUT_CYCLES` 后产生：

```text
W_TIMEOUT
```

---

## 14. B Timeout 设计

B monitor 只在：

```text
write_state == WR_WAIT_B
```

时工作。

正常结束条件：

```text
bvalid && bready
```

发生 handshake 后：

```text
b_timeout_cnt = 0
write_state   = WR_IDLE
```

如果长时间没有 B handshake，则产生：

```text
B_TIMEOUT
```

---

## 15. AR Timeout 设计

AR monitor 只在：

```text
read_state == RD_IDLE
```

时工作。

当：

```text
arvalid && arready
```

成功后：

```text
ar_timeout_cnt = 0
read_state     = RD_WAIT_R
```

如果：

```text
arvalid && !arready
```

则 counter 累计。

如果：

```text
arvalid == 0
```

则 counter 清零。

---

## 16. R Timeout 设计

R monitor 仅在：

```text
read_state == RD_WAIT_R
```

时工作。

每次发生：

```text
rvalid && rready
```

说明读事务正常推进：

```text
r_timeout_cnt = 0
```

如果：

```text
rvalid && rready && rlast
```

发生，表示当前 Read Burst 完成，状态返回：

```text
RD_IDLE
```

如果连续 `TIMEOUT_CYCLES` 个周期没有任何：

```text
rvalid && rready
```

则产生：

```text
R_TIMEOUT
```

---

## 17. Timeout One-Shot 机制

如果总线发生超时后一直没有恢复，例如：

```text
AWVALID = 1
AWREADY = 0
```

保持很多周期，不能每隔 `TIMEOUT_CYCLES` 就不断产生一次 `timeout_irq`。

因此每种 timeout 增加一个内部记录标志：

```text
aw_timeout_reported
w_timeout_reported
b_timeout_reported
ar_timeout_reported
r_timeout_reported
```

当第一次发生 timeout 后：

```text
xxx_timeout_reported = 1
```

后续即使继续 stall，也不重复产生该类型的 `timeout_irq`。

---

## 18. Timeout Reported Flag 清除

### 18.1 AW

当 AWVALID 拉低，或者 AW handshake 成功时：

```text
aw_timeout_reported = 0
```

允许下一次 AW request 再次产生 AW_TIMEOUT。

### 18.2 AR

行为与 AW 相同。

### 18.3 W

进入新的 `WR_WAIT_W` 时：

```text
w_timeout_reported = 0
```

同一写数据阶段只报告一次 W_TIMEOUT。

### 18.4 B

进入新的 `WR_WAIT_B` 时：

```text
b_timeout_reported = 0
```

同一写响应阶段只报告一次 B_TIMEOUT。

### 18.5 R

进入新的 `RD_WAIT_R` 时：

```text
r_timeout_reported = 0
```

同一读事务只报告一次 R_TIMEOUT。

---

## 19. timeout_irq 生成

每个时钟周期默认：

```text
timeout_irq = 0
```

如果该周期任意新的 timeout event 发生，则：

```text
timeout_irq = 1
```

逻辑上可以表达为：

```text
timeout_irq =
    new_aw_timeout |
    new_w_timeout  |
    new_b_timeout  |
    new_ar_timeout |
    new_r_timeout;
```

即使同一个周期有多个 timeout：

```text
timeout_irq = 1
```

仍只表现为一个周期的高电平。

`timeout_status` 则允许多个 bit 同时置位。

---

## 20. Timeout 后事务处理

Checker 属于 Passive Monitor。

因此 timeout 后：

- 不改变 AXI 总线信号
- 不主动产生 BRESP
- 不主动产生 RRESP
- 不强制终止 Transaction
- 不因为 timeout 自动退出当前事务状态

例如：

```text
WR_WAIT_B
   │
   │ B_TIMEOUT
   │
   ├── timeout_status[B] = 1
   ├── timeout_irq       = 1 cycle
   │
   ▼
仍保持 WR_WAIT_B
```

如果之后 B response 恢复：

```text
bvalid && bready
```

事务仍然可以正常结束。

---

## 21. 同周期多个 Timeout

Write Tracker 和 Read Tracker 相互独立。

因此允许同一个时钟周期发生：

```text
W_TIMEOUT
+
R_TIMEOUT
```

此时：

```text
timeout_status[1] = 1
timeout_status[4] = 1
timeout_irq       = 1
```

不会丢失 timeout 类型。

---

## 22. RTL 编码原则

当前项目 RTL 遵循以下原则：

- 使用 Verilog HDL
- 时序逻辑使用非阻塞赋值 `<=`
- 组合逻辑使用阻塞赋值 `=`
- 避免 latch
- 避免无意义初值
- 所有状态在 reset 中初始化
- 所有 counter 明确定义清零条件
- 不使用 `#delay`
- 不使用不可综合语句
- 不依赖 testbench 行为
- 参数化 timeout threshold
- 保证 `TIMEOUT_CYCLES = 1` 时仍可正常工作

---

## 23. 验证关注点

后续验证重点如下。

### 23.1 Normal Transaction

- 正常 Single Beat Write
- 正常 Burst Write
- 正常 Single Beat Read
- 正常 Burst Read

### 23.2 Timeout

- AW_TIMEOUT
- W_TIMEOUT
- B_TIMEOUT
- AR_TIMEOUT
- R_TIMEOUT

### 23.3 Boundary

- stall = `TIMEOUT_CYCLES - 1`
- stall = `TIMEOUT_CYCLES`
- handshake exactly at boundary

### 23.4 Recovery

- timeout 后 transaction 恢复
- timeout 后最终正常完成

### 23.5 Reset

- transaction 中 reset
- timeout counter 中 reset
- timeout_status reset

### 23.6 Parallel

- Read 和 Write 同时进行
- Read / Write 同周期发生不同 timeout

---

## 24. 当前微架构总结

v0.1 使用：

```text
2 个 FSM

Write FSM:
WR_IDLE
WR_WAIT_W
WR_WAIT_B

Read FSM:
RD_IDLE
RD_WAIT_R
```

以及：

```text
5 个 timeout counters
5 个 timeout reported flags
5 bit sticky timeout_status
1 bit one-cycle timeout_irq
```

该设计结构简单、易于验证，并具有较低综合资源开销，适合作为 AXI4-Full Timeout Checker 的首个 MVP 版本。

---

## 25. 后续扩展

如果继续开发 v0.2，可以将当前：

```text
单事务 FSM
```

升级为：

```text
Outstanding Transaction Table
```

并记录：

```text
ID
Address
Burst Length
Transaction State
Timeout Counter
```

从而进一步支持：

- 多 Outstanding
- AXI ID
- 同 ID 多事务
- Out-of-Order Response
- 事务上下文记录
- 独立通道 Timeout Threshold
- 软件运行时配置
- Timeout Recovery

# AXI4-Full Timeout Checker 验证方案

## 验证目标

证明五类超时检测、边界握手、one-shot 中断、sticky 状态、超时恢复、读写并发及复位行为符合 `docs/design.md`，并确认 RTL 可综合且满足 100 MHz 约束。

## 验证层次

1. Verilator `--lint-only --Wall`：静态 RTL 质量。
2. 原生 Verilog TB：基本功能和 `TIMEOUT_CYCLES=1`。
3. UVM 1.2：driver/monitor/scoreboard 独立参考模型与四组 testcase。
4. SVA：复位、合法状态、sticky status、关键状态转移。
5. 功能覆盖率：五类 status、irq、各通道握手、reset 和读写并发。
6. Vivado 2020.2：Artix-7 综合、资源和 100 MHz 时序。

## 通过准则

- Lint 零 warning/error。
- 所有仿真脚本退出码为 0。
- UVM_ERROR/UVM_FATAL 为 0，scoreboard 无 mismatch。
- SVA failure 为 0。
- 功能覆盖率 100%。
- Vivado 综合零 error/critical warning/warning，WNS 非负。

## 回归用例

- `axi_timeout_smoke_test`：正常读写及 AW/W/B/AR/R timeout。
- `axi_timeout_boundary_test`：阈值边界、beat 进展、同周期完成。
- `axi_timeout_recovery_test`：one-shot、恢复、下一事务重报。
- `axi_timeout_parallel_reset_test`：读写并发、同时超时、事务中复位。

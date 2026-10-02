# AXI4-Full Timeout Checker 验证报告

## 结论

M5-7 验证与综合通过。Lint、原生仿真、UVM scoreboard、SVA 和 Vivado 综合均未发现功能错误。

## 工具

- ModelSim SE-64 2020.4 / UVM 1.2
- Verilator 5.050
- Vivado 2020.2
- Icarus Verilog 14.0 development build

## 验证结果

| 项目 | 结果 |
| --- | --- |
| Verilator Lint | 0 warning, 0 error |
| M2 ModelSim | PASS |
| M2 Icarus | PASS |
| UVM smoke/boundary/recovery/parallel-reset | 全部 PASS |
| UVM_ERROR / UVM_FATAL | 0 / 0 |
| SVA failures | 0 |
| 合并功能覆盖率 | 100%（20/20 bins） |
| DUT branch coverage | 89.13%（41/46） |
| Interface toggle coverage | 100%（40/40） |

## 综合结果

目标器件 `xc7a35tcpg236-1`，`TIMEOUT_CYCLES=16`，时钟约束 10 ns（100 MHz）。

| 指标 | 结果 |
| --- | ---: |
| Slice LUT | 44 / 20800（0.21%） |
| Slice Register | 34 / 41600（0.08%） |
| WNS | 6.643 ns |
| TNS | 0.000 ns |
| Failing endpoints | 0 |

所有用户时序约束满足。综合过程为 0 error、0 critical warning、0 warning。

`report_methodology` 另报告 18 条 TIMING-18（顶层输入/输出未设置 I/O delay）。本 IP 是独立可复用监控模块，当前没有绑定具体 PCB、上游/下游器件或板级接口时序，因此只约束内部 100 MHz 时钟并如实保留这些系统集成提示；集成到具体 SoC/FPGA 顶层时应由系统 XDC 补充 I/O delay。

## 证据

- `logs/sim/m4_uvm.log`
- `reports/coverage/m5_7_coverage.txt`
- `reports/coverage/m5_7_merged.ucdb`
- `logs/synth/m5_7_vivado.log`
- `reports/synth/utilization.rpt`
- `reports/synth/timing_summary.rpt`
- `reports/synth/methodology.rpt`
- `reports/synth/axi4_timeout_checker_synth.dcp`

## 已知范围限制

本版本仍为单读、单写 outstanding 的旁路监控器，不支持 AXI ID、乱序响应、主动恢复或完整 AXI 协议检查。

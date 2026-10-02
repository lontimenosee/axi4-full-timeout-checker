# AXI4-Full 接口超时检查器

这是一个使用 Verilog HDL 实现的、可综合的 AXI4-Full 总线超时检查器。

本项目按照一个完整 IP 开发流程进行组织，包含 RTL 设计、SystemVerilog/UVM 验证、SVA 断言、功能覆盖率、Lint、综合、工具运行日志以及 Vivado IP 封装等内容。

## 项目目标

本项目实现一个旁路式 AXI4-Full 超时检查器。

该模块只监控 AXI4-Full 总线上的握手和事务完成情况，不修改总线行为。当某一阶段长时间未完成时，模块输出对应的超时信息。

本项目首个版本以“可完成、可验证、可综合、可交付”为目标，在有限开发周期内完成一个完整的 RTL 到 IP 封装闭环。

## 计划实现功能

- AXI4-Full 接口监控
- AW 通道超时检测
- W 通道超时检测
- B 通道超时检测
- AR 通道超时检测
- R 通道超时检测
- Burst 事务完成跟踪
- 可配置超时阈值
- 可综合 Verilog RTL
- SystemVerilog/UVM 验证环境
- SystemVerilog Assertions（SVA）
- 功能覆盖率
- Lint 检查
- Vivado 综合
- Vivado IP 封装
- 工具运行日志及验证报告

## 当前版本范围

首个版本采用简化的事务跟踪模型，以控制项目复杂度并保证在有限开发周期内完成完整交付。

当前版本计划支持：

- 最多 1 笔未完成读事务
- 最多 1 笔未完成写事务
- 支持 AXI4-Full Burst 事务
- 通过 WLAST 判断写数据阶段结束
- 通过 RLAST 判断读数据阶段结束
- 超时阈值参数化
- 旁路监控模式

## 当前版本限制

首个版本暂不支持：

- 多笔 Read Outstanding
- 多笔 Write Outstanding
- 同 ID 多事务并发
- Out-of-Order Response
- 基于 ID 的复杂事务跟踪
- 超时后的总线恢复
- 主动产生 BRESP/RRESP
- 完整 AXI 协议检查

这些功能会作为后续版本的扩展方向。

## 项目目录

```text
axi4-full-timeout-checker/
│
├── docs/           规格书、设计方案、验证方案、验证报告
├── rtl/            Verilog RTL 源码
├── tb/             SystemVerilog/UVM 验证环境
├── scripts/        Lint、仿真、综合等自动化脚本
├── logs/           关键工具运行日志
├── reports/        覆盖率、综合、时序等报告
└── ip_repo/        Vivado 封装后的 IP
```

## Vivado IP 一键打包与验证

在仓库根目录使用 PowerShell 运行：

```powershell
.\scripts\ip\run_m8_ip.ps1
```

脚本会从正式 RTL 重新生成 IP、执行完整性检查，然后在干净工程中加入 IP Catalog，将 `TIMEOUT_CYCLES` 改为 7 并完成 OOC 综合和 DCP 检查。IP 的 VLNV 是 `user.org:user:axi4_timeout_checker:1.0`。

默认使用 `D:\FPGA\Vivado\Vivado\2020.2\bin\vivado.bat`。其他安装位置可以通过环境变量覆盖：

```powershell
$env:VIVADO_BIN = 'D:\your_path\Vivado\bin\vivado.bat'
.\scripts\ip\run_m8_ip.ps1
```

最终 IP 位于 `ip_repo/axi4_timeout_checker_1.0/`，日志位于 `logs/ip/`。脚本产生的消费端工程位于 `work/`，已由 `.gitignore` 排除。

IP 包不携带全局 `create_clock` 约束，避免与集成工程的顶层时钟约束冲突。`constraints/axi4_timeout_checker.xdc` 仅用于本项目的独立综合与时序检查。

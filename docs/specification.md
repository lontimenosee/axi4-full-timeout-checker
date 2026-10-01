# AXI4-Full Timeout Checker IP 规格书

## 1. 文档信息

| 项目 | 内容 |
| --- | --- |
| IP 名称 | AXI4-Full Timeout Checker |
| RTL 语言 | Verilog HDL |
| 验证语言 | SystemVerilog / UVM |
| 当前版本 | v0.1 |
| 当前状态 | MVP 规格定义 |
| 设计目标 | AXI4-Full 总线超时监控 |

---

## 2. IP 概述

AXI4-Full Timeout Checker 是一个旁路式AXI总线监控模块。

该模块连接到 AXI-Full 总线相关握手信号，对写地址、写数据、读地址、读数据、写响应通道进行超时检测。


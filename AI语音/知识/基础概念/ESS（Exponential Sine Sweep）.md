---
title: ESS（Exponential Sine Sweep）
类型: 概念
发表时间:
时间依据: 经典声学测量方法；当前笔记未绑定单一发表物
相关任务:
  - 语音增强
aliases:
  - Exponential Sine Sweep（ESS）
  - ESS
  - Exponential Sine Sweep
  - ess
tags:
  - 类型/对象
  - 方向/AI语音
  - 任务/语音增强
---

# ESS（Exponential Sine Sweep）

## 1. 身份

在音频处理里，ESS 通常指 **Exponential Sine Sweep**：一段从低频到高频按指数/对数规律扫过的正弦激励信号。它常用于测量扬声器、房间、麦克风链路或其他音频系统的脉冲响应（Impulse Response, IR）。

边界：这里的 ESS 不是储能系统（Energy Storage System），也不是语音增强模型名；它是测量用激励信号和反卷积流程的一部分。

## 2. 用途

- 测量房间或设备的 IR，用于卷积混响、均衡、校准和声学分析。
- 在房间声学里获得 RIR，再分析 RT60、频响、相位、早期反射和能量衰减。
- 对非线性系统，扫频反卷积可以把线性响应和部分谐波失真响应在时间上分离。
- 在 AI 语音增强中，ESS 更像真实 RIR 采集入口；规模化训练数据通常仍依赖仿真或公开 RIR 数据集。

## 3. 基本流程

1. 生成一段覆盖目标频段的 ESS，例如 20 Hz 到 20 kHz。
2. 通过被测系统播放并同步录音。
3. 用对应的 inverse sweep 对录音做反卷积。
4. 得到 IR / RIR，再截取直达声、早期反射和混响尾部做分析或导出。

## 4. 实操注意

- 播放电平要低于削波阈值；削波会污染失真分量和 IR。
- sweep 后要留足静音尾巴，避免房间尾音或系统延迟被截断。
- 采样率、设备时钟和输入输出延迟会影响峰值位置，需要做延迟校正。
- 麦克风、声卡和扬声器本身会进入测量链路；严肃测量需要校准文件或参考通道。
- 环境噪声高时，提高 sweep 时长或多次平均，比盲目提高音量更稳。

## 5. 关键来源

- [Angelo Farina - Simultaneous Measurement of Impulse Response and Distortion with a Swept-Sine Technique](https://angelofarina.it/Public/Papers/134-AES00.PDF)
  - 内容定位：ESS / swept-sine 测量 IR 与失真的经典方法来源。
  - 用途：建立理论入口和“线性响应/谐波失真可分离”的出处。
  - 核验日期：2026-07-28
- [MathWorks - Measure and Manage Impulse Responses](https://www.mathworks.com/help/audio/ug/impulse-response-measurer-walkthrough.html)
  - 内容定位：Audio Toolbox 中用 ESS 或 MLS 获取 IR 的工程流程。
  - 用途：确认实际软件如何暴露 ESS 测量参数。
  - 核验日期：2026-07-28
- [REW - Room EQ Wizard Features](https://www.roomeqwizard.com/features.html)
  - 内容定位：用 logarithmically swept sine 做房间声学和音频性能测量的工具入口。
  - 用途：记录免费测量工具与常见输出图表。
  - 核验日期：2026-07-28

## 6. 相关对象

- [[方向/AI语音/知识/基础概念/Reverberation Modeling（混响建模）|混响建模]]：ESS 是真实 RIR 测量的一种常见激励方式。
- [[方向/AI语音/知识/基础概念/TSP（Time-Stretched Pulse）|TSP]]：更宽的 time-stretched pulse / sweep 测量家族；ESS / log-TSP 可视作相邻的指数/对数扫频实现。
- [[方向/AI语音增强/README|AI 语音增强]]：ESS 采集的 RIR 可用于去混响评测和数据构造，但不是增强模型本身。
- MLS：另一类 IR 测量激励，适合作为后续对比项；当前未建独立笔记。

## 7. 待验证

- 真实语音增强评测里，ESS 实测 RIR 与仿真 RIR 对模型鲁棒性的差异有多大。
- 手机/笔记本内置扬声器和麦克风链路下，ESS 测量结果是否足够稳定可复用。

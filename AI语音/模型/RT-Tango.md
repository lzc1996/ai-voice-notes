---
title: RT-Tango（实时分布式双耳语音增强）
类型: 模型
任务:
  - 双耳语音增强
  - 助听设备实时增强
开放状态:
  - paper
aliases:
  - RT-Tango
  - Real-Time Distributed Binaural Speech Enhancement for Low-Power Hearing Aid Devices
tags:
  - 类型/对象
  - 方向/AI语音
  - 任务/多通道增强
  - 主题/分布式阵列
  - 主题/高效化
---

# RT-Tango（实时分布式双耳语音增强）

## 0. 背景

**问题现场**：低功耗助听设备需要流式双耳语音增强，且必须同时考虑计算延迟与左右设备之间的通信成本。

**RT-Tango 的切入点**：两阶段分布式结构处理双耳信号，配合 ERB 特征压缩、轻量分组循环掩码估计和时间稀疏化，降低设备侧计算与通信负担。

## 1. 身份

RT-Tango 面向低功耗助听设备的流式双耳增强，联合考虑计算延迟与左右设备之间的通信成本。

## 2. 核心机制

- 采用两阶段分布式结构处理双耳信号。
- 结合符合听觉感知的 ERB 特征压缩、轻量分组循环掩码估计和时间稀疏化，降低设备侧计算与通信负担。
- 论文将方案定位为可在资源受限平台实时运行的分布式系统。

## 3. 边界

摘要未给出完整通信协议、功耗、端到端延迟和空间线索损失；这些指标决定其实际助听可用性。

## 4. 来源

- [RT-Tango: Real-Time Distributed Binaural Speech Enhancement for Low-Power Hearing Aid Devices（arXiv:2607.01834）](https://arxiv.org/abs/2607.01834)

## 5. 相关对象

- [[方向/AI语音/知识/技术路线/Distributed Multichannel SE（分布式异步多通道增强）]]
- [[方向/AI语音/知识/技术路线/Efficient Multichannel SE（多通道语音增强高效化）]]

## 6. 待验证

- 实际助听器平台、分段延迟、无线通信量、功耗、量化精度和双耳线索保持指标。

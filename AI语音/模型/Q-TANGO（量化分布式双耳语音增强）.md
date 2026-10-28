---
title: Q-TANGO（量化分布式双耳语音增强）
类型: 模型
任务:
  - 双耳语音增强
  - 低功耗端侧部署
开放状态:
  - paper
aliases:
  - Q-TANGO
  - It Takes Few to TANGO: A Quantized Distributed Model for Binaural Speech Enhancement
tags:
  - 类型/对象
  - 方向/AI语音
  - 任务/多通道增强
  - 主题/分布式阵列
  - 主题/高效化
---

# Q-TANGO（量化分布式双耳语音增强）

## 0. 背景

**问题现场**：分布式双耳增强系统 TANGO 需要部署到资源受限设备，降低计算和存储开销。

**Q-TANGO 的切入点**：对 TANGO 的神经掩码估计组件做低精度推理，比较后训练量化与量化感知训练，并分析量化对增强质量和系统成本的影响。

## 1. 身份

Q-TANGO 研究如何将分布式双耳增强系统 TANGO 部署到资源受限设备，通过低精度推理降低计算和存储开销。

## 2. 核心机制

- TANGO 将神经掩码估计与空间滤波组合成分布式双耳增强系统。
- 论文比较后训练量化与量化感知训练，并分析量化对增强质量和系统成本的影响。

## 3. 边界

摘要只覆盖 TANGO 神经组件的量化研究；不能据此推断信号处理部分也被量化，或量化后所有硬件都能达到实时。

## 4. 来源

- [It Takes Few to TANGO: A Quantized Distributed Model for Binaural Speech Enhancement（arXiv:2607.08645）](https://arxiv.org/abs/2607.08645)

## 5. 相关对象

- [[方向/AI语音/知识/技术路线/Distributed Multichannel SE（分布式异步多通道增强）]]
- [[方向/AI语音/知识/技术路线/Efficient Multichannel SE（多通道语音增强高效化）]]
- [[方向/AI语音/模型/RT-Tango]]

## 6. 待验证

- 量化位宽、量化张量范围、增强质量下降、通信量和真实硬件测量结果。

---
title: NeuralPMWF（小网络控制多通道维纳滤波）
类型: 模型
任务:
  - 多通道语音增强
开放状态:
  - paper
aliases:
  - TinyNN-PMWF
  - NeuralPMWF
  - Controlling the Parameterized Multi-channel Wiener Filter using a tiny neural network
tags:
  - 类型/对象
  - 方向/AI语音
  - 任务/多通道增强
  - 主题/传统神经混合
---

# NeuralPMWF（小网络控制多通道维纳滤波）

## 0. 背景

**问题现场**：多通道语音增强中，纯神经网络抑噪能力强但可能引入较大语音失真，传统滤波器权衡可控但适应能力有限。

**前序路线的缺口**：纯神经方法语音失真大，传统滤波器适应能力有限，两者各有短板。

**NeuralPMWF 的切入点**：用低延迟、小计算量神经网络控制参数化多通道 Wiener 滤波器（PMWF）的参数，由显式多通道滤波完成增强。

## 1. 身份

NeuralPMWF 用低延迟、小计算量神经网络控制参数化多通道 Wiener 滤波器（PMWF），以保留传统滤波器可调节抑制与语音失真的优点。

## 2. 核心机制

- 神经网络预测或控制 PMWF 参数，由显式多通道滤波完成增强。
- 方法针对纯神经网络抑噪能力强但可能引入较大语音失真、传统滤波器权衡可控但适应能力有限这一矛盾。
- 摘要报告在相近计算资源下，相较多个竞争基线改善主观与客观增强表现。

## 3. 边界

摘要没有交代控制参数、训练目标、滤波器估计方式及实时平台，性能比较需以全文设置为准。

## 4. 来源

- [Controlling the Parameterized Multi-channel Wiener Filter using a tiny neural network（arXiv:2507.13863）](https://arxiv.org/abs/2507.13863)

## 5. 相关对象

- [[方向/AI语音/知识/技术路线/Hybrid Array SE（传统神经混合阵列增强）]]
- [[方向/AI语音/知识/基础概念/MVDR（最小方差无失真响应）]]

## 6. 待验证

- PMWF 参数化方式、神经网络输出、参数量与 MACs、端侧时延和失真控制指标。

---
title: CabinSep（异构阵列车载语音分离）
类型: 模型
任务:
  - 车载多说话人分离
  - 语音识别前端
开放状态:
  - paper
aliases:
  - CabinSep
  - IR-Augmented Mask-Based MVDR for Real-Time In-Car Speech Separation with Distributed Heterogeneous Arrays
tags:
  - 类型/对象
  - 方向/AI语音
  - 任务/多通道分离
  - 主题/分布式阵列
  - 主题/高效化
---

# CabinSep（异构阵列车载语音分离）

## 0. 背景

**问题现场**：车内多说话人重叠场景下，需要在分布式异构麦克风阵列上做实时分离，目标是降低下游 ASR 的识别错误并满足实时应用需要。

**CabinSep 的切入点**：以多通道信息构造空间特征改善语音与噪声掩码估计，推理时采用 MVDR 减小语音失真使输出更适合 ASR，训练加入 IR augmentation。

## 1. 身份

CabinSep 面向车内重叠说话人分离，使用分布式异构麦克风阵列，目标是降低下游 ASR 的识别错误并满足实时应用需要。

## 2. 核心机制

- 以多通道信息构造空间特征，改善语音与噪声掩码估计。
- 推理时采用 MVDR，以减小语音失真并使输出更适合作为 ASR 输入。
- 训练加入 IR augmentation；摘要将其与轻量掩码 MVDR 分离链路一并列为主要设计。

## 3. 边界

这是车载和异构阵列场景的系统方案，不宜直接当作通用远场阵列结果。实时性、IR 扰动策略及 ASR 收益数值尚未核对。

## 4. 来源

- [CabinSep: IR-Augmented Mask-Based MVDR for Real-Time In-Car Speech Separation with Distributed Heterogeneous Arrays（arXiv:2509.01399）](https://arxiv.org/abs/2509.01399)

## 5. 相关对象

- [[方向/AI语音/知识/技术路线/Distributed Multichannel SE（分布式异步多通道增强）]]
- [[方向/AI语音/知识/基础概念/MVDR（最小方差无失真响应）]]

## 6. 待验证

- 车内阵列布局、IR 增强生成方式、实时延迟、分离指标及下游 ASR 对照设置。

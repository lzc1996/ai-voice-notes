---
title: Online Per-Channel Mask Beamforming（分通道掩码在线波束形成）
类型: 模型
任务:
  - 空间分布麦克风语音增强
  - 在线波束形成
开放状态:
  - paper
aliases:
  - Online-PerChannel-BF
  - Online Mask-Based Beamforming Using Per-Channel Masking for Spatially Distributed Microphones
tags:
  - 类型/对象
  - 方向/AI语音
  - 任务/多通道增强
  - 主题/分布式阵列
---

# Online Per-Channel Mask Beamforming（分通道掩码在线波束形成）

## 0. 背景

**问题现场**：空间分布麦克风上做在线掩码波束形成时，紧凑阵列常用的"所有通道共享一个掩码"在不同位置的麦克风之间可能不合适。

**前序路线的缺口**：共享掩码无法表示空间分散麦克风之间不同的信号特征。

**Online Per-Channel Mask Beamforming 的切入点**：将共享掩码扩展为每通道掩码，从逐通道估计中获得更合适的空间协方差并在线执行波束形成。

## 1. 身份

该方法研究空间分布麦克风上的在线掩码波束形成，针对紧凑阵列常用的“所有通道共享一个掩码”在不同位置麦克风间可能不合适的问题。

## 2. 核心机制

- 将传统共享掩码扩展为每通道掩码，以表示空间分散麦克风之间不同的信号特征。
- 目标是从逐通道估计中获得更合适的空间协方差并在线执行波束形成。

## 3. 边界

摘要描述的是空间分布麦克风设置；分通道掩码是否在紧凑阵列上退化为共享掩码，以及在线协方差估计稳定性尚未核对。

## 4. 来源

- [A Study on Online Mask-Based Beamforming Using Per-Channel Masking for Spatially Distributed Microphones（arXiv:2607.26623）](https://arxiv.org/abs/2607.26623)

## 5. 相关对象

- [[方向/AI语音/知识/技术路线/Distributed Multichannel SE（分布式异步多通道增强）]]
- [[方向/AI语音/知识/基础概念/MVDR（最小方差无失真响应）]]

## 6. 待验证

- 每通道掩码训练目标、在线协方差更新、阵列间距范围及与共享掩码的定量比较。

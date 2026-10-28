---
title: GAF-Net（全局自适应傅里叶双耳增强）
类型: 模型
任务:
  - 双耳语音增强
  - 空间线索保持
开放状态:
  - paper
aliases:
  - GAF-Net
  - FBN-BSE
  - Global Adaptive Fourier Network
  - A Lightweight Fourier-Based Network for Binaural Speech Enhancement with Spatial Cue Preservation
tags:
  - 类型/对象
  - 方向/AI语音
  - 任务/多通道增强
  - 主题/空间引导
  - 主题/高效化
---

# GAF-Net（全局自适应傅里叶双耳增强）

## 0. 背景

**问题现场**：双耳语音增强需要在降噪的同时保持空间线索。

**前序路线的缺口**：高性能模型计算量大，轻量模型又容易损害空间线索，二者难以兼顾。

**GAF-Net 的切入点**：STFT 与 gammatone 双特征编码器 + 深度复数建模，以空间线索保持为设计目标的轻量 Fourier 网络。

## 1. 身份

GAF-Net 是轻量双耳语音增强网络，针对高性能模型计算量大、轻量模型容易损害空间线索的折中问题设计。

## 2. 核心机制

- 双特征编码器结合 STFT 与 gammatone 特征。
- 网络采用深度复数建模，并以空间线索保持为设计目标。
- 摘要将其定位为兼顾增强表现与计算效率的轻量方案。

## 3. 边界

当前摘要摘录未覆盖完整模块结构、空间损失和实时硬件结果；“轻量”需结合参数量、运算量和设备测量核对。

## 4. 来源

- [A Lightweight Fourier-Based Network for Binaural Speech Enhancement with Spatial Cue Preservation（arXiv:2509.14076）](https://arxiv.org/abs/2509.14076)

## 5. 相关对象

- [[方向/AI语音/知识/技术路线/Efficient Multichannel SE（多通道语音增强高效化）]]
- [[方向/AI语音/知识/技术路线/Spatial-Guided SE（空间引导与多模态增强）]]
- [[方向/AI语音/知识/基础概念/ILD（双耳声级差）]]

## 6. 待验证

- Fourier 模块定义、空间线索损失、参数/MACs、主观听测和与大模型的质量差异。

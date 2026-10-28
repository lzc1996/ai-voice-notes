---
title: WTFormer（小波 Conformer 多通道语音增强）
类型: 模型
任务:
  - 多通道语音增强
  - 空间线索保持
开放状态:
  - paper
aliases:
  - WTFormer
  - Wavelet Conformer Network for MIMO Speech Enhancement
tags:
  - 类型/对象
  - 方向/AI语音
  - 任务/多通道增强
  - 主题/空间引导
---

# WTFormer（小波 Conformer 多通道语音增强）

## 0. 背景

**问题现场**：MIMO 语音增强不仅要去噪，还要在保留多个输出间时空结构的同时保持空间线索。

**WTFormer 的切入点**：利用小波变换的多分辨率特性与多维协同注意力建模分布式空间特征，用 Conformer 建模时频关系，并以结合 MUSIC 的多任务损失监督空间信息保持。

## 1. 身份

WTFormer 是面向多输入多输出（MIMO）语音增强的网络，重点在去噪同时保留输出间的时空结构，而非只增强一个参考通道。

## 2. 核心机制

- 利用小波变换的多分辨率特性和多维协同注意力建模分布式空间特征。
- 使用 Conformer 建模时频关系，并以结合 MUSIC 的多任务损失监督空间信息保持。
- 摘要报告在 LibriSpeech 上以 0.98M 参数达到有竞争力的去噪表现，并改善空间线索保持。

## 3. 边界

摘要没有说明 MIMO 输出通道定义、空间保持指标、训练阵列几何及与基线的逐项比较。

## 4. 来源

- [WTFormer: A Wavelet Conformer Network for MIMO Speech Enhancement with Spatial Cues Preservation（arXiv:2506.22001）](https://arxiv.org/abs/2506.22001)

## 5. 相关对象

- [[方向/AI语音/知识/技术路线/Spatial-Guided SE（空间引导与多模态增强）]]
- [[方向/AI语音/知识/技术路线/Hybrid Array SE（传统神经混合阵列增强）]]

## 6. 待验证

- 多任务损失的定义、MUSIC 标签构造、参数量口径和空间保真度的评估细节。

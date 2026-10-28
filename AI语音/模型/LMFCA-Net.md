---
title: LMFCA-Net（轻量多通道语音增强网络）
类型: 模型
任务:
  - 多通道语音增强
开放状态:
  - paper
aliases:
  - LMFCA-Net
  - Lightweight Model for Multi-Channel Speech Enhancement with Efficient Narrow-Band and Cross-Band Attention
tags:
  - 类型/对象
  - 方向/AI语音
  - 任务/多通道增强
  - 主题/高效化
---

# LMFCA-Net（轻量多通道语音增强网络）

## 0. 背景

**问题现场**：多通道语音增强的端到端模型计算量较高，资源受限设备难以承受。

**LMFCA-Net 的切入点**：解耦全连接注意力——T-FCA 沿时间轴建模长程窄带依赖、F-FCA 沿频率轴建模跨带依赖，结合多通道空间信息，避免使用循环单元以降低复杂度和延迟。

## 1. 身份

LMFCA-Net 是一类面向资源受限设备的轻量多通道增强网络。它针对端到端模型计算量较高的问题，用解耦全连接注意力建模窄带和跨带信息，并避免使用循环单元。

## 2. 核心机制

- T-FCA 沿时间轴建模长程窄带依赖。
- F-FCA 沿频率轴建模跨带依赖。
- 网络结合多通道空间信息，论文摘要报告其性能可与先进方法相比，同时显著降低计算复杂度和延迟。

## 3. 结果与边界

摘要支持“低复杂度、低延迟且增强表现有竞争力”的结论；具体参数量、MACs、延迟设备、数据集和对照表尚未从全文核对。

## 4. 来源

- [LMFCA-Net: A Lightweight Model for Multi-Channel Speech Enhancement with Efficient Narrow-Band and Cross-Band Attention（arXiv:2502.11462）](https://arxiv.org/abs/2502.11462)
  - 内容定位：原始论文摘要与题名。
  - 用途：确认 T-FCA、F-FCA 的分工及摘要级效率结论。

## 5. 相关对象

- [[方向/AI语音/知识/技术路线/Efficient Multichannel SE（多通道语音增强高效化）]]
- [[方向/AI语音/模型/TF-GridNet]]

## 6. 待验证

- 全文中的模型规模、复杂度计算口径、实时测试平台、训练数据与跨阵列泛化结果。

---
title: Binaural-CRNN（复数卷积循环双耳增强）
类型: 模型
任务:
  - 双耳语音增强
  - 空间线索保持
开放状态:
  - paper
aliases:
  - Binaural-CRNN
  - Binaural Speech Enhancement Using Complex Convolutional Recurrent Networks
tags:
  - 类型/对象
  - 方向/AI语音
  - 任务/多通道增强
  - 主题/空间引导
---

# Binaural-CRNN（复数卷积循环双耳增强）

## 0. 背景

**问题现场**：助听与 AR/VR 场景的双耳语音增强，需要在提高可懂度、降低噪声的同时保持空间信息。

**Binaural-CRNN 的切入点**：使用复数卷积循环网络的编码器-解码器结构（中间放复数 LSTM），损失函数除语音增强目标外也强调双耳空间信息保持。

## 1. 身份

Binaural-CRNN 是面向助听与 AR/VR 的端到端双耳语音增强网络，在提高可懂度、降低噪声的同时将空间信息纳入训练目标。

## 2. 核心机制

- 使用复数卷积循环网络的编码器-解码器结构，并在中间放置复数 LSTM 模块。
- 损失函数除语音增强目标外，也强调双耳空间信息保持。

## 3. 边界

摘要未说明具体空间损失、耳间指标、助听器实时约束和与传统双耳方法的结果差异。

## 4. 来源

- [Binaural Speech Enhancement Using Complex Convolutional Recurrent Networks（arXiv:2507.20023）](https://arxiv.org/abs/2507.20023)

## 5. 相关对象

- [[方向/AI语音/知识/技术路线/Spatial-Guided SE（空间引导与多模态增强）]]
- [[方向/AI语音/知识/基础概念/ILD（双耳声级差）]]

## 6. 待验证

- 网络复数表示方式、空间损失定义、左右耳信号指标、数据集及运行时成本。

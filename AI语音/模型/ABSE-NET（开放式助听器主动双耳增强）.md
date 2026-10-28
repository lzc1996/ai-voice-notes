---
title: ABSE-NET（开放式助听器主动双耳增强）
类型: 模型
任务:
  - 双耳语音增强
  - 声学泄漏抑制
开放状态:
  - paper
aliases:
  - ABSE-NET
  - Alternate Binaural Speech Enhancement Network
tags:
  - 类型/对象
  - 方向/AI语音
  - 任务/多通道增强
  - 主题/空间引导
---

# ABSE-NET（开放式助听器主动双耳增强）

## 0. 背景

**问题现场**：开放式助听器的开放佩戴会让耳道声学泄漏损害双耳语音增强，需要同时处理目标语音增强与泄漏声控制。

**ABSE-NET 的切入点**：把主动噪声控制（ANC）与双耳语音增强联合起来：先做双耳 MVDR（BMVDR），再接轻量神经模块做主动泄漏抑制。

## 1. 身份

ABSE-NET 面向开放式助听器。开放佩戴带来的耳道声学泄漏会损害双耳增强，因此该方法将主动噪声控制（ANC）与双耳语音增强联合起来处理目标语音和泄漏声。

## 2. 核心机制

- 摘要描述的流水线先使用双耳 MVDR（BMVDR），再接入轻量神经模块处理主动泄漏抑制。
- 方案针对开放式佩戴下“增强目标语音”和“控制耳道泄漏”同时存在的声学问题。

## 3. 边界

该方法与耳道/扬声器回路和开放式助听器结构紧密相关，不等于一般会议阵列的回声消除方案。

## 4. 来源

- [ABSE-NET: A Lightweight Neural Model for Active Binaural Speech Enhancement in Open-Fit Hearing Aids（arXiv:2609.00966）](https://arxiv.org/abs/2609.00966)

## 5. 相关对象

- [[方向/AI语音/知识/技术路线/Spatial-Guided SE（空间引导与多模态增强）]]
- [[方向/AI语音/知识/基础概念/MVDR（最小方差无失真响应）]]

## 6. 待验证

- ANC 参考信号、耳道泄漏路径建模、闭环稳定性、双耳线索及助听器实测结果。

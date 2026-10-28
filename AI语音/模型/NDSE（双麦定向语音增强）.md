---
title: NDSE（双麦定向语音增强）
类型: 模型
任务:
  - 多通道语音增强
  - 定向语音提取
开放状态:
  - paper
aliases:
  - Neural Directed Speech Enhancement
  - NDSE
tags:
  - 类型/对象
  - 方向/AI语音
  - 任务/多通道增强
  - 任务/目标说话人提取
  - 主题/空间引导
---

# NDSE（双麦定向语音增强）

## 0. 背景

**问题现场**：高噪声、多说话人场景下的双麦克风定向增强，需要能调节保留目标语音的角度范围。

**NDSE 的切入点**：用三个 steering vectors 构成空间选择框架控制增强方向与宽度，因果 Directed U-Net（CDUNet）直接接收多通道语音和期望增强宽度作条件，双麦系统参数量小、可实时运行。

## 1. 身份

NDSE 面向高噪声、多说话人场景下的双麦克风定向增强。它把目标方向与期望增强区域作为条件，使系统能够调节保留目标语音的角度范围。

## 2. 核心机制

- 使用三个 steering vectors 构成空间选择框架，控制增强方向和宽度。
- 因果 Directed U-Net（CDUNet）直接接收多通道语音和期望增强宽度，并根据信号方向调整增强区域。
- 摘要报告该双麦系统参数量较小、可实时运行，并改善语音质量及下游任务表现。

## 3. 边界

摘要未说明目标方向是否由外部提供、三组 steering vectors 的构造方式，以及“增强宽度”的精确定义。

## 4. 来源

- [Neural Directed Speech Enhancement with Dual Microphone Array in High Noise Scenario（arXiv:2412.18141）](https://arxiv.org/abs/2412.18141)

## 5. 相关对象

- [[方向/AI语音/知识/技术路线/Spatial-Guided SE（空间引导与多模态增强）]]
- [[方向/AI语音/知识/基础概念/DOA（到达方向）]]

## 6. 待验证

- 全文中的参数量、实时设备、SNR 范围、宽度控制实验及下游任务指标。

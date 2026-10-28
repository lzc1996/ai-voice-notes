---
title: HRTF-TSE（HRTF 引导双耳目标说话人提取）
类型: 模型
任务:
  - 双耳目标说话人提取
  - 空间音频增强
开放状态:
  - paper
aliases:
  - HRTF-TSE
  - HRTF-guided Binaural Target Speaker Extraction with Real-World Validation
tags:
  - 类型/对象
  - 方向/AI语音
  - 任务/目标说话人提取
  - 主题/空间引导
---

# HRTF-TSE（HRTF 引导双耳目标说话人提取）

## 0. 背景

**问题现场**：双耳目标说话人提取需要从多声源混合中定位并提取目标，同时保持目标在听者处的感知空间位置。

**前序路线的缺口**：既有 TSE 依赖 DOA 或说话人注册语音来指定目标，且提取过程容易破坏目标的感知空间位置。

**HRTF-TSE 的切入点**：用听者 HRTF 作为显式空间先验指定目标的双耳空间特征，把多通道深度盲源分离骨干改造成双耳 TSE，并以真实场景验证为目标。

## 1. 身份

HRTF-TSE 使用头相关传递函数作为显式空间先验，从多声源混合中提取目标说话人，并以真实场景验证为目标。

## 2. 核心机制

- 不只依赖 DOA 或说话人注册语音，而是用听者 HRTF 指定目标的双耳空间特征。
- 基于多通道深度盲源分离骨干改造成双耳 TSE，并使用来自不同人群测量的 HRTF 训练。
- 设计动机之一是避免提取后目标的感知空间位置被破坏。

## 3. 边界

跨个体 HRTF 偏差、测量 HRTF 与实际耳廓差异以及真实验证规模需要阅读全文确认。

## 4. 来源

- [HRTF-guided Binaural Target Speaker Extraction with Real-World Validation（arXiv:2603.16668）](https://arxiv.org/abs/2603.16668)

## 5. 相关对象

- [[方向/AI语音/知识/技术路线/Spatial-Guided SE（空间引导与多模态增强）]]
- [[方向/AI语音/知识/基础概念/DOA（到达方向）]]

## 6. 待验证

- HRTF 条件表示、真实录音设置、不同个体泛化、空间定位误差和语音质量结果。

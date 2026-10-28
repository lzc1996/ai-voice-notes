---
title: MC-LExt（起始提示多通道目标说话人提取）
类型: 模型
任务:
  - 多通道目标说话人提取
开放状态:
  - paper
aliases:
  - MC-LExt
  - MC-LEXT
  - Multi-Channel Target Speaker Extraction with Onset-Prompted Speaker Conditioning Mechanism
tags:
  - 类型/对象
  - 方向/AI语音
  - 任务/目标说话人提取
  - 主题/空间引导
---

# MC-LExt（起始提示多通道目标说话人提取）

## 0. 背景

**问题现场**：从多说话人、多麦克风的混合信号中提取指定目标说话人的语音。

**前序路线的缺口**：仅依赖 DOA 或隐式说话人表示的条件方式较脆弱——方向估计易受阵列几何影响，说话人 embedding 在噪声下可能退化。

**MC-LExt 的切入点**：将目标语音的起始（onset）事件作为提示线索构造说话人条件（onset-prompted speaker conditioning）。

## 1. 身份

MC-LExt 是多通道目标说话人提取方法，通过 onset-prompted speaker conditioning 为目标身份提供条件，处理方向估计易受阵列几何影响、说话人 embedding 在噪声下可能退化的问题。

## 2. 核心机制

- 从多说话人、多麦克风混合中提取指定目标语音。
- 将目标语音起始事件作为提示线索，构造说话人条件；论文针对仅依赖 DOA 或隐式说话人表示的脆弱性提出该机制。

## 3. 边界

“onset”提示的具体获取方式、提示长度和说话人重叠条件需阅读全文确认；摘要未提供不同提示策略的量化比较。

## 4. 来源

- [MC-LEXT: Multi-Channel Target Speaker Extraction with Onset-Prompted Speaker Conditioning Mechanism（arXiv:2510.15437）](https://arxiv.org/abs/2510.15437)

## 5. 相关对象

- [[方向/AI语音/知识/技术路线/Spatial-Guided SE（空间引导与多模态增强）]]
- [[方向/AI语音/知识/基础概念/DOA（到达方向）]]

## 6. 待验证

- onset 提示标注/检测方法、条件注入位置、跨说话人与跨阵列测试结果。

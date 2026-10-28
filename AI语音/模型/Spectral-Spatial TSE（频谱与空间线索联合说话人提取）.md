---
title: Spectral-Spatial TSE（频谱与空间线索联合说话人提取）
类型: 模型
任务:
  - 多通道目标说话人提取
开放状态:
  - paper
aliases:
  - Spectral-Spatial TSE
  - Spectral or Spatial? Leveraging Both for Speaker Extraction in Challenging Data Conditions
tags:
  - 类型/对象
  - 方向/AI语音
  - 任务/目标说话人提取
  - 主题/空间引导
---

# Spectral-Spatial TSE（频谱与空间线索联合说话人提取）

## 0. 背景

**问题现场**：多通道目标说话人提取中，参考信息可能不准确——空间线索或频谱线索中某一类退化或误导时提取会失效。

**Spectral-Spatial TSE 的切入点**：不单独依赖一类线索，用专门网络动态平衡频谱与空间线索对目标提取的贡献。

## 1. 身份

该方法面向参考信息不准确的多通道目标说话人提取，不只依赖空间线索或频谱线索中的一种，而是希望在其中一类线索退化或误导时仍保持稳定。

## 2. 核心机制

- 输入为噪声混合及两类可能不可靠的目标参考线索。
- 专门网络动态平衡频谱与空间线索对目标提取的贡献。

## 3. 边界

摘要未说明两类参考线索的具体表示、可靠度估计机制和失效分桶，不能仅据摘要断言模型能识别所有错误提示。

## 4. 来源

- [Spectral or Spatial? Leveraging Both for Speaker Extraction in Challenging Data Conditions（arXiv:2512.20165）](https://arxiv.org/abs/2512.20165)

## 5. 相关对象

- [[方向/AI语音/知识/技术路线/Spatial-Guided SE（空间引导与多模态增强）]]
- [[方向/AI语音/知识/基础概念/DOA（到达方向）]]

## 6. 待验证

- 参考线索定义、动态权重机制、错误提示构造及不同退化条件下的鲁棒性结果。

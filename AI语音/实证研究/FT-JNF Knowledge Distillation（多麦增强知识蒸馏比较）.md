---
title: FT-JNF Knowledge Distillation（多麦增强知识蒸馏比较）
类型: 论文
任务:
  - 多通道语音增强
  - 模型压缩
aliases:
  - FT-JNF-KD
  - Comparison of Knowledge Distillation Methods for Low-complexity Multi-microphone Speech Enhancement using the FT-JNF Architecture
tags:
  - 类型/对象
  - 方向/AI语音
  - 任务/多通道增强
  - 主题/高效化
---

# FT-JNF Knowledge Distillation（多麦增强知识蒸馏比较）

## 1. 研究问题

这项工作比较如何用知识蒸馏降低多麦克风增强模型的部署成本，同时尽量保留教师网络性能；研究固定在 [[方向/AI语音/模型/FT-JNF（Frequency-Time Joint Non-linear Filter）|FT-JNF]] 架构上。

## 2. 方法范围

- 比较多种知识蒸馏方法在 FT-JNF 学生模型上的效果。
- 研究动机是单纯减小参数量可能明显损伤增强质量，蒸馏则尝试把教师性能转移到较小模型。

## 3. 边界

这是特定架构上的蒸馏方法比较，不是对所有多通道增强模型均成立的通用压缩结论。摘要未提供最优蒸馏策略和指标数值。

## 4. 来源

- [Comparison of Knowledge Distillation Methods for Low-complexity Multi-microphone Speech Enhancement using the FT-JNF Architecture（arXiv:2507.19208）](https://arxiv.org/abs/2507.19208)

## 5. 相关对象

- [[方向/AI语音/模型/FT-JNF（Frequency-Time Joint Non-linear Filter）]]：蒸馏比较使用的多通道增强架构。
- [[方向/AI语音/知识/技术路线/Efficient Multichannel SE（多通道语音增强高效化）]]
- [[方向/AI语音/知识/技术路线/Hybrid Array SE（传统神经混合阵列增强）]]

## 6. 待验证

- 教师与学生配置、蒸馏损失、参数量和实时性口径，以及性能-复杂度折中曲线。

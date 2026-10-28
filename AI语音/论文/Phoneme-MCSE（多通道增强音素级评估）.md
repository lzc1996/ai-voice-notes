---
title: Phoneme-MCSE（多通道增强音素级评估）
类型: 论文
任务:
  - 多通道语音增强评估
aliases:
  - Evaluating Multichannel Speech Enhancement Algorithms at the Phoneme Scale Across Genders
  - Phoneme-MCSE
tags:
  - 类型/对象
  - 方向/AI语音
  - 主题/评估
  - 任务/多通道增强
---

# Phoneme-MCSE（多通道增强音素级评估）

## 1. 研究问题

这项研究检查多通道语音增强的差异是否会被整句平均指标掩盖，重点比较不同音素类别及不同性别语音的增强表现。

## 2. 方法与发现

- 将评估粒度从整句扩展到音素，并按音素类别与说话人性别分析增强差异。
- 摘要报告性别间整句差异较小，但音素级差异明显；测试算法对女性语音中的爆破音、擦音和元音表现出较强干扰抑制与较少伪影，感知和识别指标也更好。

## 3. 使用边界

这是评估分析，不是新的增强模型。摘要结论限于论文测试的算法、语料和分桶方法，不能视为所有系统都存在相同性别差异。

## 4. 来源

- [Evaluating Multichannel Speech Enhancement Algorithms at the Phoneme Scale Across Genders（arXiv:2506.18691）](https://arxiv.org/abs/2506.18691)

## 5. 相关对象

- [[方向/AI语音/知识/技术路线/Hybrid Array SE（传统神经混合阵列增强）]]
- [[方向/AI语音/知识/调研与地图/Array Speech Enhancement Frontier（阵列语音增强前沿调研）]]

## 6. 待验证

- 论文评估的具体算法、数据集、音素对齐流程、样本量和各指标的分层统计。

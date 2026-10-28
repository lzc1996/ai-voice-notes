---
title: VI-NBFNet（视觉引导神经波束形成）
类型: 模型
任务:
  - 音视频语音增强
  - 多通道波束形成
开放状态:
  - paper
aliases:
  - VI-NBFNet
  - VI-BF-SE
  - Visual-Informed Speech Enhancement Using Attention-Based Beamforming
tags:
  - 类型/对象
  - 方向/AI语音
  - 任务/多通道增强
  - 主题/多模态
  - 主题/空间引导
---

# VI-NBFNet（视觉引导神经波束形成）

## 0. 背景

**问题现场**：低 SNR、强混响、说话人移动和重叠语音等场景是单通道增强难以处理的。

**VI-NBFNet 的切入点**：将视觉说话人线索接入注意力式神经波束形成，融合麦克风阵列信号与视觉信息辅助目标选择和空间增强（visual-informed neural beamforming，而非识别后处理）。

## 1. 身份

VI-NBFNet 将视觉说话人线索接入注意力式神经波束形成，面向低 SNR、强混响、说话人移动和重叠语音等单通道增强难以处理的场景。

## 2. 核心机制

- 融合麦克风阵列信号与视觉信息，利用视觉线索辅助目标选择和空间增强。
- 论文摘要将其定位为 visual-informed neural beamforming，而非单纯的视频说话人识别后处理。

## 3. 边界

视觉线索质量、音视频同步误差和目标离开视野时的回退行为尚未从全文核对。

## 4. 来源

- [Visual-Informed Speech Enhancement Using Attention-Based Beamforming（arXiv:2603.05270）](https://arxiv.org/abs/2603.05270)

## 5. 相关对象

- [[方向/AI语音/知识/技术路线/Spatial-Guided SE（空间引导与多模态增强）]]
- [[方向/AI语音/知识/基础概念/DOA（到达方向）]]

## 6. 待验证

- 视觉编码与阵列融合位置、同步容忍度、无视觉回退策略及真实音视频数据评估。

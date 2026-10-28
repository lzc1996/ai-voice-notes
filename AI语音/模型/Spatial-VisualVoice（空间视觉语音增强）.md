---
title: Spatial-VisualVoice（空间视觉语音增强）
类型: 模型
任务:
  - 音视频语音增强
  - 双耳空间音频增强
开放状态:
  - paper
aliases:
  - Spatial-VisualVoice
  - Audio-Visual Speech Enhancement for Spatial Audio
  - MAVE
tags:
  - 类型/对象
  - 方向/AI语音
  - 任务/多通道增强
  - 主题/空间引导
  - 主题/多模态
---

# Spatial-VisualVoice（空间视觉语音增强）

## 0. 背景

**问题现场**：低信噪比条件下的语音增强需要利用视觉线索辅助，同时 AR/VR 场景还要求保持空间听感而不只提升清晰度。

**Spatial-VisualVoice 的切入点**：融合可穿戴麦克风阵列音频与视觉线索做目标语音增强，并把空间音频的左右/方向信息作为任务约束。

## 1. 身份

Spatial-VisualVoice 研究面向空间音频的音视频语音增强，目标是在低信噪比条件下利用视觉线索辅助增强，同时关注 AR/VR 场景中的空间听感。论文同时介绍 MAVE 数据资源。

## 2. 核心机制

- 融合可穿戴麦克风阵列音频与视觉线索进行目标语音增强。
- 将空间音频的左右/方向信息作为任务约束，避免只提升语音清晰度而丢失空间呈现。
- MAVE 面向该研究设置提供音视频数据支持；本页不将其等同于通用音视频增强基准。

## 3. 边界

调研页已有摘要级提及，但此前没有独立对象页。本文页按单篇论文建立；MAVE 是否需要独立数据集页，待后续确认其复用价值。

## 4. 来源

- [Audio-Visual Speech Enhancement for Spatial Audio: Spatial-VisualVoice and the MAVE Database（arXiv:2510.16437）](https://arxiv.org/abs/2510.16437)

## 5. 相关对象

- [[方向/AI语音/知识/技术路线/Spatial-Guided SE（空间引导与多模态增强）]]
- [[方向/AI语音/知识/调研与地图/Array Speech Enhancement Frontier（阵列语音增强前沿调研）]]

## 6. 待验证

- MAVE 的采集设备、空间标注、训练/测试划分，以及视觉条件对空间保真和低 SNR 性能的独立贡献。

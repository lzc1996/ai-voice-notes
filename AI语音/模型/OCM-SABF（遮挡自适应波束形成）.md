---
title: OCM-SABF（遮挡自适应波束形成）
类型: 模型
任务:
  - 头戴阵列语音增强
  - 自声增强
开放状态:
  - paper
aliases:
  - OCM-SABF
  - Microphone Occlusion Mitigation for Own-Voice Enhancement in Head-Worn Microphone Arrays Using Switching-Adaptive Beamforming
tags:
  - 类型/对象
  - 方向/AI语音
  - 任务/多通道增强
  - 主题/传统神经混合
---

# OCM-SABF（遮挡自适应波束形成）

## 0. 背景

**问题现场**：头戴麦克风阵列做自声增强时，皮肤、头发或衣物的遮挡会改变麦克风传递函数，使固定波束权重失配。

**OCM-SABF 的切入点**：系统比较三种遮挡应对方式——传统自适应波束形成、在遮挡与未遮挡状态的预估权重间切换，以及切换与自适应结合的混合波束形成。

## 1. 身份

OCM-SABF 研究头戴麦克风阵列中的自声增强：皮肤、头发或衣物遮挡会改变麦克风传递函数，使固定波束权重失配。

## 2. 核心机制

论文比较三种遮挡应对方式：传统自适应波束形成、在遮挡与未遮挡状态的预估权重间切换，以及切换与自适应结合的混合波束形成。

## 3. 边界

研究对象是头戴阵列和麦克风遮挡引起的传递函数变化；不能仅据摘要推断对任意阵列故障或移动声源均有效。结果细节尚未核对。

## 4. 来源

- [Microphone Occlusion Mitigation for Own-Voice Enhancement in Head-Worn Microphone Arrays Using Switching-Adaptive Beamforming（arXiv:2507.09350）](https://arxiv.org/abs/2507.09350)

## 5. 相关对象

- [[方向/AI语音/知识/技术路线/Hybrid Array SE（传统神经混合阵列增强）]]
- [[方向/AI语音/模型/WNG-MVDR]]

## 6. 待验证

- 三种策略的切换判据、真实录音结果、遮挡类型覆盖及对自声与噪声 RTF 变化的适应速度。

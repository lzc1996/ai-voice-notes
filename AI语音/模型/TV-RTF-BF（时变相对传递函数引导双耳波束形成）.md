---
title: TV-RTF-BF（时变相对传递函数引导双耳波束形成）
类型: 模型
任务:
  - 动态说话人语音增强
  - 双耳波束形成
开放状态:
  - paper
aliases:
  - TV-RTF-BF
  - Interpretable Binaural Deep Beamforming Guided by Time-Varying Relative Transfer Function
tags:
  - 类型/对象
  - 方向/AI语音
  - 任务/多通道增强
  - 主题/空间引导
---

# TV-RTF-BF（时变相对传递函数引导双耳波束形成）

## 0. 背景

**问题现场**：移动目标说话人场景下，双耳波束形成需要在动态环境中保持空间行为可控。

**TV-RTF-BF 的切入点**：DNN 从多通道含噪信号学习时变波束权重，用连续跟踪移动目标的时变 RTF 作为显式空间条件。

## 1. 身份

TV-RTF-BF 面向移动目标说话人，通过时变相对传递函数（RTF）引导深度双耳波束形成，重点考察动态环境中的空间行为。

## 2. 核心机制

- DNN 根据多通道含噪信号学习时变波束权重。
- RTF 连续跟踪移动目标，为权重提供显式空间条件。
- 论文在 8 麦线阵上比较真值 RTF、子空间跟踪估计 RTF 和无 RTF 引导三种模式，并分析窄带/宽带方向图。

## 3. 边界

摘要中的方向图分析不等于真实移动场景的全面泛化证明；RTF 估计误差和跟踪延迟可能影响效果。

## 4. 来源

- [Interpretable Binaural Deep Beamforming Guided by Time-Varying Relative Transfer Function（arXiv:2511.10168）](https://arxiv.org/abs/2511.10168)

## 5. 相关对象

- [[方向/AI语音/知识/技术路线/Spatial-Guided SE（空间引导与多模态增强）]]
- [[方向/AI语音/知识/基础概念/steering vector（导向矢量）]]

## 6. 待验证

- RTF 跟踪算法、双耳目标定义、动态轨迹设置、跟踪滞后与空间/语音指标的联合结果。

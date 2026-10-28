---
title: SSM-NBF（说话人选择神经波束形成）
类型: 模型
任务:
  - 多说话人语音分离
  - 神经波束形成
开放状态:
  - paper
aliases:
  - SSM-NBF
  - Target Speaker Selection for Neural Network Beamforming in Multi-Speaker Scenarios
tags:
  - 类型/对象
  - 方向/AI语音
  - 任务/多通道分离
  - 主题/空间引导
---

# SSM-NBF（说话人选择神经波束形成）

## 0. 背景

**问题现场**：多说话人场景下，神经波束形成网络需要学会在多个候选说话人中聚焦目标。

**SSM-NBF 的切入点**：训练时加入说话人选择机制（SSM），利用听者与说话人位置关系及目标方向的 undershot angle 选择关注对象；推理阶段只需音频信息。

## 1. 身份

SSM-NBF 在训练阶段为多说话人神经波束形成网络加入说话人选择机制（SSM），帮助模型学会在多个候选说话人中聚焦目标。

## 2. 核心机制

- 训练时利用听者与说话人的位置关系及目标方向的 undershot angle 选择关注对象。
- 推理阶段只需音频信息，不需要额外的位置输入。
- 摘要报告仿真实验中语音可懂度、质量和失真指标相较 MVDR 及未加入 SSM 的同一网络有所提升。

## 3. 边界

位置关系是训练信号还是模型输入的具体实现需阅读全文确认；摘要结果基于声学仿真，不能直接外推到真实动态会议。

## 4. 来源

- [Target Speaker Selection for Neural Network Beamforming in Multi-Speaker Scenarios（arXiv:2503.18590）](https://arxiv.org/abs/2503.18590)

## 5. 相关对象

- [[方向/AI语音/知识/技术路线/Spatial-Guided SE（空间引导与多模态增强）]]
- [[方向/AI语音/知识/基础概念/Beamforming（波束形成）]]

## 6. 待验证

- SSM 的训练损失和采样策略、undershot angle 分布、实验数据及主观可懂度评估设置。

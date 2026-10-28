---
title: CycBF-DNN（循环平稳波束形成与神经去噪）
类型: 模型
任务:
  - 低信噪比语音增强
  - 谐波噪声抑制
开放状态:
  - paper
aliases:
  - CycBF-DNN
  - Speech Enhancement using Cyclostationary Beamforming and DNNs
tags:
  - 类型/对象
  - 方向/AI语音
  - 任务/多通道增强
  - 主题/传统神经混合
---

# CycBF-DNN（循环平稳波束形成与神经去噪）

## 0. 背景

**问题现场**：谐波噪声主导的低 SNR 场景下，语音增强需要有效压制循环平稳的谐波成分。

**CycBF-DNN 的切入点**：先用 cyclic MPDR 频谱波束形成利用循环平稳噪声的谱相关性压制谐波成分，再串接轻量 DNN 做学习式增强，且不需要修改 DNN 架构。

## 1. 身份

CycBF-DNN 面向谐波噪声主导的低 SNR 场景，将利用周期统计结构的波束形成预处理与轻量 DNN 去噪串接。

## 2. 核心机制

- 先用 cyclic [[方向/AI语音/知识/基础概念/MPDR（最小功率无失真响应）|MPDR]]（cMPDR）频谱波束形成器利用循环平稳噪声的谱相关性，压制谐波成分。
- 再由轻量 DNN 执行学习式增强；摘要称该预处理不需要修改 DNN 架构。

## 3. 边界

方法针对具有可利用循环平稳结构的噪声；对非周期或快速变化噪声的收益不能由摘要推出。

## 4. 来源

- [A Two-Step Approach for Speech Enhancement in Low-SNR Scenarios Using Cyclostationary Beamforming and DNNs（arXiv:2602.12986）](https://arxiv.org/abs/2602.12986)

## 5. 相关对象

- [[方向/AI语音/知识/技术路线/Hybrid Array SE（传统神经混合阵列增强）]]
- [[方向/AI语音/知识/基础概念/Beamforming（波束形成）]]

## 6. 待验证

- 循环平稳统计量估计、噪声类型、预处理增益、神经后端和低 SNR 分桶结果。

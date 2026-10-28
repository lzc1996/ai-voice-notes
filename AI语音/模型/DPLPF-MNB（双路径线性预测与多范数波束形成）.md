---
title: DPLPF-MNB（双路径线性预测与多范数波束形成）
类型: 模型
任务:
  - 多通道语音增强
  - 去混响
开放状态:
  - paper
aliases:
  - DPLPF-MNB
  - Speech Enhancement with Dual-path Multi-Channel Linear Prediction Filter and Multi-norm Beamforming
tags:
  - 类型/对象
  - 方向/AI语音
  - 任务/多通道增强
  - 主题/传统神经混合
---

# DPLPF-MNB（双路径线性预测与多范数波束形成）

## 0. 背景

**问题现场**：多通道语音增强需要同时抑制混响尾部与干扰信号。

**DPLPF-MNB 的切入点**：将双路径（时间+频率）多通道线性预测滤波与多范数波束形成结合——MCLP 处理混响尾部，波束形成在最小化输出功率与 L1 范数的同时保留目标方向，并提出可适应不同混响时间的预测阶数选择方法。

## 1. 身份

DPLPF-MNB 将多通道线性预测滤波（MCLP）与多范数波束形成结合，用预测滤波处理混响尾部，再以目标方向约束抑制干扰。

## 2. 核心机制

- MCLP 使用时间与频率两个维度的双路径滤波器。
- 波束形成同时最小化阵列输出功率和增强信号的 L1 范数，并保留目标方向信号。
- 论文提出预测阶数选择方法，摘要称其能适应不同混响时间。

## 3. 边界

摘要没有给出优化细节、目标方向先验来源或对比结果数值；“适应不同 T60”需结合实验范围理解。

## 4. 来源

- [Speech Enhancement with Dual-path Multi-Channel Linear Prediction Filter and Multi-norm Beamforming（arXiv:2507.18350）](https://arxiv.org/abs/2507.18350)

## 5. 相关对象

- [[方向/AI语音/知识/技术路线/Hybrid Array SE（传统神经混合阵列增强）]]
- [[方向/AI语音/知识/基础概念/WPE（加权预测误差）]]

## 6. 待验证

- 双路径滤波公式、预测阶数选择、优化准则和不同混响时间下的分项结果。

---
title: Binaural Cue Preservation Loss（双耳线索保持损失）
类型: 方法
发表时间: 2026-08
时间依据: arXiv 首次提交日
任务:
  - 语音增强
  - 双耳增强
开放状态:
  - paper
aliases:
  - A Novel Binaural Cue Preservation Loss for DNN-Based Binaural Speech Enhancement
  - Binaural Cue Preservation Loss
  - Binaural Reconstruction Error Loss
  - 双耳线索保持损失
  - 双耳重建误差损失
tags:
  - 类型/对象
  - 方向/AI语音
  - 任务/语音增强
  - 主题/双耳增强
  - 主题/助听器
---

# Binaural Cue Preservation Loss（双耳线索保持损失）

## 0. 背景

**问题现场**：DNN 双耳语音增强降噪能力强，但常扭曲左右信号之间的关系，破坏空间定位所需的耳间线索（ILD / IPD）。

**前序路线的缺口**：此前 SOTA 基线 cue loss 把 ILD 误差与 IPD 误差分开惩罚，未直接针对左右频谱关系本身。

**Binaural Cue Preservation Loss 的切入点**：提出两种训练损失——双耳重建误差损失直接惩罚掩蔽诱导的左右频谱关系失真，双耳线索损失联合建模 ILD 与 IPD，在降噪的同时保住双耳结构。

## 1. 身份

`Binaural Cue Preservation Loss`（双耳线索保持损失）是 arXiv:2608.16299（2026-08-17 v1，eess.AS / cs.SD；作者列表待补）针对**助听器双耳语音增强**提出的两种损失。背景：DNN 双耳增强降噪强，但常扭曲左右信号之间的关系，破坏空间定位所需的耳间线索（interaural cues）。

边界：不是新的模型结构，是**训练损失**；针对双耳（助听）而非单通道或多麦克风阵列；目标不是只降噪，而是在降噪的同时保住 ILD / IPD 双耳线索。

## 2. 核心机制（两项损失）

1. **双耳重建误差损失（binaural reconstruction error loss）**：直接惩罚**掩蔽（masking）诱导的左右频谱关系失真**——提供比此前工作分开算 ILD 误差与 IPD 误差更直接的双耳一致性度量。
2. **双耳线索损失（binaural cue loss）**：**联合建模 ILD 与 IPD**，保持双耳结构（而非把两个线索当作独立目标）。

对比点：此前 SOTA 基线 cue loss 把 ILD / IPD 误差分开惩罚；本文两种损失都更直接地针对"左右频谱关系"本身。

## 3. 结果口径

- 摘要级：两种损失均保持强降噪性能，并**减少掩蔽诱导失真**（相比 SOTA 基线 cue loss）。
- 第二种联合 binaural cue loss 还在 **ILD 保持**上优于基线。
- 具体数值（数据集、指标对比）待全文（见待验证）。

## 4. 使用判断

- 适合：双耳 / 助听语音增强的训练损失设计；任何需要降噪同时保住空间定位线索的场景。
- 不适合：单通道增强（无耳间线索）；纯降噪指标优先的场景。
- 风险：2026-08 刚出，待复现；联合 ILD/IPD 建模的公式细节与数值待全文。

## 5. 关键来源

- [A Novel Binaural Cue Preservation Loss for DNN-Based Binaural Speech Enhancement（arXiv:2608.16299）](https://arxiv.org/abs/2608.16299)
  - 内容定位：原始论文，两项损失定义与实验（2026-08-17 v1）。
  - 用途：双耳增强损失设计的方法口径与结果。
  - 核验日期：2026-08-19

## 6. 相关对象

- [[方向/AI语音/知识/基础概念/ILD（双耳声级差）|ILD]]：损失联合建模的耳间线索之一（能量差）。
- [[方向/AI语音/知识/基础概念/IPD（通道间相位差）|IPD]]：损失联合建模的耳间线索之一（相位差）。
- [[方向/AI语音/知识/基础概念/TF Mask（时频掩码）|TF Mask]]：掩蔽诱导失真（masking-induced distortion）的来源——本文损失直接惩罚其副作用。

## 7. 待验证

- 作者完整列表与机构。
- 全文数值：数据集、基线、ILD / IPD / 降噪指标的定量对比。
- 两项损失的公式细节：重建误差的度量方式、ILD 与 IPD 联合建模的实现。

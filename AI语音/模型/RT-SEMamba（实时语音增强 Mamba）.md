---
title: RT-SEMamba（实时语音增强 Mamba）
类型: 方法
发表时间: 2026-08
时间依据: arXiv 首次提交日
任务:
  - 语音增强
  - 实时增强
开放状态:
  - paper
aliases:
  - "RT-SEMamba: Real-Time Speech Enhancement Mamba via Progressive Knowledge Distillation"
  - RT-SEMamba
  - 实时语音增强 Mamba
  - Progressive Knowledge Distillation
tags:
  - 类型/对象
  - 方向/AI语音
  - 任务/语音增强
  - 主题/Mamba
  - 主题/知识蒸馏
  - 主题/实时增强
---

# RT-SEMamba（实时语音增强 Mamba）

## 0. 背景

**问题现场**：实时语音增强需要在长音频上低延迟、低内存地持续推理。

**前序路线的缺口**：Transformer 系增强依赖不断增长的 KV cache，长音频推理内存与带宽开销大。

**RT-SEMamba 的切入点**：用因果时频 Mamba 块的固定大小循环状态替代注意力，再以渐进式知识蒸馏把 8 层 teacher 压缩为浅层 student，兼顾质量与实时性。

## 1. 身份

`RT-SEMamba`（arXiv:2608.12099，2026-08-12 v1，INTERSPEECH 2026，cs.SD / cs.CL；提交者 Rong Chao，作者列表待补）是**全因果实时语音增强模型**，基于因果时频 Mamba 块。动机：Transformer 系增强依赖不断增长的 KV cache，长音频推理内存/带宽开销大；Mamba 每层传播**固定大小循环状态**，实现内存与带宽高效的长时推理。

边界：不是 Transformer 注意力架构；是 **SSM（状态空间模型）**；专为实时 / 流式长音频设计；配合**渐进式知识蒸馏**压缩深度。

## 2. 核心机制

1. **因果时频 Mamba 块**：固定大小循环状态（per layer），无增长 KV cache——长时推理内存与带宽高效。
2. **渐进式知识蒸馏（progressive KD）**：把 **8 层 teacher 压缩为浅层 1 层 student**，联合蒸馏复杂谱输出 + 中间表示。

## 3. 结果口径（Voicebank-DEMAND）

- 8 层 RT-SEMamba：**3.32 PESQ** @ **25 ms 算法延迟约束**。
- 蒸馏 1 层 student：3.06 → **3.18 PESQ**（vs 朴素 1 层基线），**稳态 RTF 不变**，比 teacher **2.75× 加速**。
- 结论：状态空间模型 + 渐进式 KD 提供有竞争力的质量-延迟权衡。

## 4. 使用判断

- 适合：实时 / 流式低延迟增强；长音频推理（会议、语音 Agent）；端侧算力受限场景（Mamba 固定状态、内存高效）。
- 不适合：非因果离线高指标场景（蒸馏后 1 层只有 3.18 PESQ，低于非实时大模型）。
- 风险：2026-08 刚出，待复现；25 ms 算法延迟的工程实现细节待全文。

## 5. 关键来源

- [RT-SEMamba: Real-Time Speech Enhancement Mamba via Progressive Knowledge Distillation（arXiv:2608.12099）](https://arxiv.org/abs/2608.12099)
  - 内容定位：原始论文，INTERSPEECH 2026（2026-08-12 v1）。
  - 用途：实时 Mamba 增强 + 渐进式 KD 的方法口径与结果。
  - 核验日期：2026-08-19

## 6. 相关对象

- [[方向/AI语音/知识/调研与地图/SE SOTA（语音增强模型表现）|SE SOTA]]：Mamba 系增强（USEMamba、MambAttention）的谱系位置。
- [[方向/AI语音/知识/基础概念/SDPA（缩放点积注意力）|SDPA]]：Mamba / SSM 替代注意力是端侧主趋势（vault 已记录）。
- [[方向/AI语音/数据集/VoiceBank-DEMAND|VoiceBank-DEMAND]]：实验基准（SEMamba 等 Mamba 系增强也在此报告）。

## 7. 待验证

- 作者完整列表与机构。
- 25 ms 延迟的具体实现（块长、因果窗）；逐层 / 中间表示的蒸馏细节。
- 与 8 层 teacher 的完整质量对比表（PESQ / SI-SDR / STOI）。

---
title: LLM-SE Training Recipe（借鉴 NLP LLM 的语音增强训练配方）
类型: 技术路线
发表时间:
时间依据: 对话沉淀；非单一发表物
相关任务:
  - 语音增强
  - 语音恢复
  - speech-token conditional reconstruction
相关主题:
  - LLM
  - 训练配方
  - 语音增强
aliases:
  - 使用 NLP LLM 经验训练 LLM-SE
  - LLM-based SE training recipe
  - Speech-token conditional reconstruction
  - 语音增强的 LLM 训练配方
tags:
  - 类型/对象
  - 方向/AI语音
  - 任务/语音增强
  - 主题/大模型
  - 主题/训练
---

# LLM-SE Training Recipe（借鉴 NLP LLM 的语音增强训练配方）

## 1. 核心判断

LLM-SE 不应被定义成“语音版翻译/文本纠错”，而应定义成：

```text
degraded acoustic evidence + speech tokens
  -> clean speech tokens / enhanced acoustic representation
  -> enhanced waveform
```

借鉴 NLP LLM 的重点不是某个相似任务，而是 **tokenization、可扩展预训练、阶段式训练、数据 mixture、稳定性 recipe 和 alignment 方法**。SE 的底线仍然是内容、说话人、时间结构、频谱和相位保真。

## 2. 类比定位

- **不像普通翻译**：翻译允许意译和重排；SE 必须保持内容、说话人、时间对齐和声学细节。
- **不像文本纠错**：文本纠错多是离散符号少量错误修复；SE 要处理噪声、混响、带宽、削波、丢包、相位和频谱等连续退化。
- **更像退化观测下的条件重建**：输入是 degraded acoustic evidence，输出是 clean speech representation；LLM 提供长上下文和 clean speech prior，但不能脱离原始观测自由生成。
- **真正可借鉴的是 NLP LLM 的训练体系**：tokenizer 设计、clean token LM 预训练、阶段式训练、数据 mixture、稳定性 recipe 和偏好对齐，而不是把 SE 硬套成某个 NLP 任务。

## 3. 和 SELM 的关系

[[方向/AI语音/模型/SELM]] 是“离散 token + language model 做语音增强”的具体早期模型；当前 recipe 是把这条路线扩展成分阶段训练框架。

```text
SELM:
  noisy token -> LM -> clean token -> vocoder

当前 recipe:
  degraded acoustic evidence
  + semantic token
  + optional acoustic token
  + clean speech prior
  -> conditional reconstruction
  -> task-specific decoder
  -> perceptual / preference alignment
```

如果只做最小实现，当前方案会退化成 SELM 风格 baseline。真正拉开差距的是：Stage 0 表示分工、Stage 1 clean semantic prior、Stage 2 continuous evidence conditioned NTP、Stage 3 waveform fidelity，以及 Stage 4 偏好对齐。

## 4. 和 UniSE 的关系

[[方向/AI语音/模型/UniSE（Unified Speech Enhancement）]] 是当前 recipe 的强参考实现：它已经采用 WavLM 条件、decoder-only LM、离散 codec token 和感知后训练来统一 SR / TSE / SS。当前 recipe 与 UniSE 的关系不是替代，而是把 UniSE 这类路线拆成可控阶段：表示空间、clean prior、条件恢复、波形保真和偏好对齐。

```text
UniSE-style direct training:
  p(clean target tokens | WavLM condition)

Prior-first recipe:
  Stage 1: p(clean semantic tokens)
  Stage 2: p(clean semantic / acoustic tokens | degraded evidence)
```

Stage 1 不是硬前置。像 UniSE 一样直接训练 Stage 2 也会隐式学习 clean token 分布；Stage 1 的价值在于利用 clean-only 数据、降低 paired 数据压力、提高强退化场景下的 prior 可诊断性，并避免模型过早拟合训练集 clean target 的音质分布。

## 5. 阶段索引

| 阶段 | 笔记 | 核心目标 | 主要产物 |
|---|---|---|---|
| Stage 0 | [[方向/AI语音/知识/技术路线/LLM-SE Stage 0（表示空间准备）]] | 明确 token 定义、信息分工和重建上限 | tokenizer / codec / acoustic encoder / decoder |
| Stage 1 | [[方向/AI语音/知识/技术路线/LLM-SE Stage 1（Clean Speech Token LM 预训练）]] | 可选：学 clean semantic speech prior | semantic speech LM |
| Stage 2 | [[方向/AI语音/知识/技术路线/LLM-SE Stage 2（多退化条件重建）]] | 把 NTP 扩展为 degraded evidence conditioned clean token prediction | degradation-conditioned LLM-SE |
| Stage 3 | [[方向/AI语音/知识/技术路线/LLM-SE Stage 3（声学保真）]] | 针对 SE / dereverb / BWE 等任务优化波形保真 | task-specific enhancer |
| Stage 4 | [[方向/AI语音/知识/技术路线/LLM-SE Stage 4（感知与偏好对齐）]] | 用感知、ASR、speaker 偏好进一步对齐 | aligned LLM-SE |

## 6. 最小实现路线

有两条可并行验证的路线：

```text
Path A: UniSE-style direct conditional training
  Stage 0 -> Stage 2 -> Stage 3 -> Stage 4

Path B: prior-first training
  Stage 0 -> Stage 1 -> Stage 2 -> Stage 3 -> Stage 4
```

如果 paired degraded-clean 数据足够、目标是快速复现强 baseline，先做 Path A；如果 clean-only 数据多、强退化和缺失场景多，或想验证 LLM clean prior 是否有独立收益，再做 Path B。

```text
Stage 0:
  选 semantic tokenizer + acoustic evidence encoder

Stage 1 optional:
  clean speech -> semantic token
  train clean semantic token LM

Stage 2:
  degraded speech -> continuous acoustic evidence
  initialize from Stage 1 LM
  train conditional NTP to predict s_clean

Stage 3:
  LLM hidden / s_hat + gated acoustic evidence
  train decoder / vocoder / FM head for enhanced waveform

Stage 4:
  small-step preference tuning with content / speaker / quality rewards
```

第一版可以先不引入 acoustic token：

```text
v1: e_degraded + s_clean
v2: e_degraded + s_clean + coarse a_clean
v3: e_degraded + s_clean + multi-codebook a_clean + preference tuning
```

## 7. 训练稳定性通用规则

- Stage 0 不稳定，后面不要继续堆 LLM；先修 token 空间。
- Stage 1 看 LM loss、token probe、speaker leakage。
- Stage 2 看 conditional recovery，不要只看 clean token perplexity。
- Stage 3 看 waveform / spectrum / speaker / content 的联合指标。
- Stage 4 看 reward 分项和 hard case，不要只看总 reward。
- 长序列 attention 可考虑 [[方向/大模型/模型结构/QK-Norm]]、更长 warmup、gradient clipping、分模块 LR 和严格 resume checklist。

## 8. 最小实验矩阵

1. **Stage 0 baseline**：现成 semantic tokenizer + 现成 codec + continuous acoustic evidence。
2. **Stage 1 baseline**：clean semantic token LM。
3. **Stage 2 baseline**：degraded evidence -> clean semantic token。
4. **Stage 3 baseline**：无 LLM acoustic encoder-decoder，用来确认声学头上限。
5. **LLM ablation**：frozen LLM、LoRA LLM、部分解冻对比。
6. **evidence ablation**：去掉 continuous evidence，看是否出现语义脑补。
7. **loss ablation**：去掉 STFT / speaker / ASR consistency，看幻觉和保真如何变化。

## 9. 一句话经验

**Stage 0 定义语音表示空间；Stage 1 学 clean semantic prior；Stage 2 学退化条件恢复；Stage 3 学具体增强任务的声学保真；Stage 4 做感知和偏好对齐。LLM 可以参与训练，但必须被 acoustic evidence 和 fidelity losses 约束。**

## 10. 相关对象

- [[方向/AI语音/知识/技术路线/LLM-SE Training Recipe v2（显式解耦训练配方）]]
- [[方向/AI语音/知识/技术路线/LLM 与 Agent 对语音增强的影响]]
- [[方向/AI语音/知识/技术路线/LLM Backbone（使用 LLM 作为骨干训练其他任务）]]
- [[方向/AI语音/知识/技术路线/语音生成 tokenizer codec 技术路线]]
- [[方向/AI语音/知识/基础概念/SE（语音增强）导论]]
- [[方向/AI语音/思考/Error-Correcting Speech Token（可纠错语音 Token）]]
- [[方向/AI语音/模型/SELM]]
- [[方向/AI语音/模型/UniSE（Unified Speech Enhancement）]]
- [[方向/AI语音/模型/L3-SE]]
- [[方向/AI语音/模型/StableToken]]
- [[方向/大模型/训练/LLM Training Recipe（大模型训练配方总览）]]
- [[方向/大模型/训练/Data Curation（LLM 数据清洗与质量过滤）]]
- [[方向/大模型/训练/Training Stability（LLM 训练稳定性诊断）]]
- [[方向/大模型/训练/Training Resume Checklist（断点续训检查表）]]

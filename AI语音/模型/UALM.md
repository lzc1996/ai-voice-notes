---
title: UALM
类型: 模型
参数量: 7B
发表时间: 2025-10-13
时间依据: arXiv v1 首次提交日；ICLR 2026 oral
任务:
  - 音频理解
  - 音频生成
  - 文本推理
  - 多模态推理
开放状态:
  - paper
  - code
  - demo
aliases:
  - Unified Audio Language Model
  - UALM-Gen
  - UALM-Reason
  - "UALM: Unified Audio Language Model for Understanding, Generation and Reasoning"
tags:
  - 类型/对象
  - 方向/AI语音
  - 任务/音频理解
  - 任务/音频生成
  - 主题/多模态推理
---

# UALM

## 0. 背景

**问题现场**：音频理解、text-to-audio 生成、文本求解与跨模态推理分散在不同模型中，希望在一个 7B LLM 内统一。

**UALM 的切入点**：把音频输出 token 直接放进 decoder-only LLM 的词表与训练目标（输入侧保留连续 acoustic encoder、输出侧用 X-Codec 离散 token + delay pattern），并验证统一混训时文本能力不明显回退。

## 1. 身份

`UALM`（Unified Audio Language Model）是 NVIDIA ADLR 等提出的 7B 音频语言模型，目标是在单个 LLM 中统一音频理解、text-to-audio 生成、文本问题求解和跨模态推理。它先用 `UALM-Gen` 验证 decoder-only audio token 生成，再扩展到统一理解与生成，最后用 `UALM-Reason` 探索带音频中间步骤的生成式推理。

边界：UALM 不是纯音频理解模型，也不是扩散式 text-to-audio 模型；它的观察价值在于把 audio token generation 放进语言模型训练框架，并验证统一音频/文本任务时文本能力不明显回退。

## 2. 核心信息

- **统一任务**：文本问题求解、音频理解、text-to-audio generation、多模态 reasoning。
- **生成路线**：`UALM-Gen` 直接预测 audio tokens，对照扩散式 text-to-audio 模型。
- **训练要点**：混合多模态数据，生成数据上采样；先做 modality alignment warmup，再解冻完整语言模型。
- **推理扩展**：`UALM-Reason` 支持 imaginary prompt enrichment、dialogue、self-reflection 等跨模态生成推理示例。
- **定位**：更像 [[方向/AI语音/模型/Audex]] 的研究前身；Audex 后续把统一 audio-text LLM 放到更强的 Nemotron-Cascade MoE 基座上。

## 3. 核心机制

### 3.1. 输入到输出流水线

```text
音频理解：16 kHz mono audio -> acoustic encoder（25 Hz，30s sliding window）-> single-layer MLP adapter -> Qwen2.5-7B decoder-only LLM -> text tokens -> 理解答案 / 转写 / 文本推理输出。

Text-to-audio：文本 prompt -> 扩展 audio vocabulary 的 decoder-only LLM -> X-Codec audio tokens（50 Hz，每帧 8 个 RVQ token）-> delay pattern 并行预测多层 codebook -> codec decoder -> 16 kHz mono waveform -> enhancement VAE -> 48 kHz stereo audio。

UALM-Reason：用户目标 / 文本 prompt -> 生成 rich prompt 或多轮 dialogue -> 生成音频候选 -> 音频理解分支回读候选并 critique -> self-reflection 修正 prompt / audio tokens -> 更可控的音频输出。
```

UALM 的关键机制不是接一个独立音频生成器，而是把音频输出 token 放进 decoder-only LLM 的词表和训练目标；输入侧保留连续 acoustic encoder 表示以减少理解信息损失，输出侧用 [[方向/AI语音/模型/X-Codec]] 离散 token 适配自回归生成。

### 3.2. 核心公式

训练时只在输出 token 上算 loss；每个音频帧含 8 个 RVQ token，因此单个 audio token 的权重按 $1/8$ 缩放，可写成：

$$
\mathcal{L}_{\text{out}}=-\sum_{i\in\mathcal{O}}w_i\log p_{\theta}(x_i\mid x_{<i}),\quad
w_i=\begin{cases}
1, & x_i\text{ 为文本 token}\\
\frac{1}{8}, & x_i\text{ 为单个 audio RVQ token}
\end{cases}
$$

[[方向/AI语音/模型/X-Codec]] 的 RVQ 对每个音频帧逐层量化残差：

$$
\hat{x}=\sum_{n=1}^{n_q}c_{n,i_n},\quad
i_n=\arg\min_k\lVert r_{n-1}-c_{n,k}\rVert,\quad
r_0=x,\quad r_n=r_{n-1}-c_{n,i_n}
$$

delay pattern 将第 $n$ 个 codebook 在帧 $t$ 的 token 放到自回归步 $s=t+n-1$ 预测；等价地，第 $s$ 步并行预测：

$$
\{A_{1,s},A_{2,s-1},\cdots,A_{n_q,s-n_q+1}\}
$$

因此采样步数从扁平化的 $T\times n_q$ 接近压到 $T+n_q-1$，UALM 使用 $n_q=8$、50 Hz，所以 10 秒音频约为 4000 个 codec token，但只需约 507 个自回归步。

### 3.3. 机制要点

- **输入连续、输出离散**：理解侧用 acoustic encoder + adapter，生成侧用 audio codec token。
- **LLM 词表扩展**：音频 token embedding 随 MLP adapter 初始化并参与训练。
- **delay pattern 是效率关键**：保留 RVQ 多层依赖，同时避免把每帧 8 个 token 完全串行展开。
- **Reason 分支偏控制性**：imaginary prompt、dialogue、self-reflection 让音频生成可以被中间文本/音频步骤修正。

## 4. 使用判断

- 看**研究路线**：适合跟踪 decoder-only audio token 生成能否替代扩散模型。
- 看**统一训练**：适合研究音频理解、生成和文本推理混训时如何避免能力互相伤害。
- 看**跨模态推理**：`UALM-Reason` 是音频生成任务里引入可交互推理步骤的早期样例。

## 5. 相关对象

- [[方向/AI语音/MOC - 音频大模型]]：方向地图。
- [[方向/AI语音/模型/Audex]]：NVIDIA 后续统一 audio-text LLM，对文本能力保留做得更强。
- [[方向/AI语音/模型/AudioLM]]：audio token LM 路线早期代表。
- [[方向/AI语音/模型/FireRedAudio]]：同属理解 + 生成统一音频语言模型，对照连续表示路线。
- [[方向/AI语音/模型/X-Codec]]：UALM 的 audio output tokenizer。

## 6. 来源

- [UALM: Unified Audio Language Model for Understanding, Generation and Reasoning（arXiv:2510.12000）](https://arxiv.org/abs/2510.12000)
  - 内容定位：技术论文入口，说明 UALM-Gen、UALM、UALM-Reason 三段设计与统一训练目标。
  - 用途：确认模型定位、任务范围、训练策略和 arXiv 首次提交日期。
  - 核验日期：2026-09-01
- [UALM: Unified Audio Language Model for Understanding, Generation, and Reasoning - NVIDIA ADLR](https://research.nvidia.com/labs/adlr/UALM/)
  - 内容定位：官方项目页，包含 UALM / UALM-Reason 简介和音频 demo。
  - 用途：确认 7B 模型口径、能力展示和官方项目归属。
  - 核验日期：2026-09-01
- [NVIDIA/audio-intelligence - UALM](https://github.com/NVIDIA/audio-intelligence/blob/main/README.md)
  - 内容定位：NVIDIA audio-intelligence 统一仓库索引，列出 UALM 为 ICLR 2026 oral。
  - 用途：确认代码入口、会议状态和在 NVIDIA 音频模型线中的位置。
  - 核验日期：2026-09-01

## 7. 待验证

- 公开代码是否足够复现 UALM-Gen / UALM / UALM-Reason 的完整训练或仅支持 demo / 推理。
- UALM 相比 Audex 在 audio generation、text reasoning 和 speech task 上的能力差距。
- 使用的 [[方向/AI语音/模型/X-Codec]] 与 [[方向/AI语音/模型/X-Codec2]] / EnCodec / MusicGen token pattern 的具体差异。

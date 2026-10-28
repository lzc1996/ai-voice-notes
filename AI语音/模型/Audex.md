---
title: Audex
类型: 模型
参数量: 30B MoE / 3B 激活参数；另有 2B 版本
发表时间: 2026-07-06
时间依据: arXiv v1 首次提交日
任务:
  - 音频理解
  - ASR
  - 语音翻译
  - TTS
  - 音频生成
  - 语音到语音生成
开放状态:
  - paper
  - weights
aliases:
  - Nemotron-Labs-Audex-30B-A3B
  - Audex-30B-A3B
  - Nemotron-Labs-Audex
  - NVIDIA Audex
  - Nemotron-Labs-Audex-2B
tags:
  - 类型/对象
  - 方向/AI语音
  - 领域/大模型
  - 任务/音频理解
  - 任务/ASR
  - 任务/TTS
  - 主题/多模态
---

# Audex

## 0. 背景

**问题现场**：给文本 LLM 加入音频理解与生成能力时，需要尽量保留原文本模型的 reasoning、alignment、knowledge、long-context 和 agentic 能力（不回退）。

**Audex 的切入点**：单一 Transformer decoder 承载 audio-text 到 audio-text：音频输入经 AF-Whisper + MLP adapter 投到文本 embedding space，输出侧扩展词表直接生成离散音频 token（语音/非语音用不同 codec dispatch），训练顺序上分阶段混合音频与 text-only 数据降低文本能力回退。

## 1. 身份

`Audex`（Nemotron-Labs-Audex-30B-A3B）是 NVIDIA 提出的统一 audio-text LLM，基于 Nemotron-Cascade-2-30B-A3B 文本 MoE 基座，把音频输入、文本 token 和量化音频输出 token 接到同一个 Transformer decoder 里。目标是在加入音频理解/生成能力时，尽量保留原文本模型的 reasoning、alignment、knowledge、long-context 和 agentic 能力。

边界：Audex 不是只做 ASR/TTS 的专用系统，也不是只做音频理解的 encoder-LLM；它是一个 audio-text 到 audio-text 的统一模型，适合和 [[方向/AI语音/模型/UALM]]、[[方向/AI语音/模型/FireRedAudio]]、[[方向/AI语音/模型/Qwen3-Omni]] 放在一起看。

## 2. 核心信息

- **基座**：Nemotron-Cascade-2-30B-A3B，30B MoE / 3B activated parameters，支持 thinking 与 instruct 两种模式。
- **统一 decoder**：音频输入经 audio encoder + MLP adapter 投到 text embedding space；输出侧扩展 vocabulary，直接生成离散 speech/audio tokens 和 text tokens。
- **训练数据**：论文口径为 157.4B audio tokens + 320.5B text tokens，多阶段 SFT 后接 text-only Cascade RL 和 multi-domain on-policy distillation。
- **任务面**：audio understanding、speech recognition / translation、TTS、text-to-audio、speech-to-speech generation。
- **上下文**：Hugging Face 模型卡标注支持 up to 1M-token context；不同音频任务有不同 vLLM / Transformers / SGLang 推理路径。
- **开放形态**：公开 30B-A3B 权重，并有 2B 小模型入口；具体许可与商用限制以 Hugging Face 模型卡为准。

## 3. 核心机制

### 3.1. 输入到输出流水线

```text
音频理解 / ASR / AST：16 kHz audio -> AF-Whisper（每 30s 输出 750×1280，25 Hz）-> 2-layer MLP adapter -> Nemotron-Cascade-2-30B-A3B embedding space -> 单一 MoE Transformer decoder -> text tokens -> 答案 / 转写 / 翻译。

TTS：文本 prompt -> 扩展 vocabulary 的 Audex decoder -> <speechgen_start> ... <speechcodec_id> ... <speechgen_end> -> X-Codec2 speech codec（50 Hz，FSQ，65,536 codebook）-> streaming decoder / vocoder -> 语音波形。

Text-to-audio：文本 caption / instruction -> Audex decoder -> <audiogen_start> ... <audiocodec_id> ... <audiogen_end> -> X-Codec non-speech tokens（50 Hz，使用 4 层 RVQ）-> audio decoder + enhancement VAE -> 48 kHz audio。
```

Audex 的机制核心是「单 decoder」：音频输入先投到文本 embedding space，文本 token 与量化音频输出 token 在同一个 Transformer decoder 内自回归建模；训练流程把 audio warmup、audio generation SFT、audio understanding SFT 与 text-only 数据混合，用来降低文本能力回退。

### 3.2. 核心公式

Audex 对文本 token 和音频 token 使用同一标准 LLM 目标，只在 trainable token 上最大化条件似然：

$$
\max_{\theta}\left\{\frac{1}{\#\text{Trainable tokens}}\sum_{i:\ x_i\text{ is trainable}}\log p_{\theta}(x_i\mid x_{<i})\right\}
$$

packed sequence 中使用 square averaging loss，避免长样本主导 batch：

$$
\mathrm{Scaled\text{-}Loss}(\{L_1,\cdots,L_k\})=
\left(\sum_{j=1}^{k}\frac{\mathrm{sum}(L_j)}{\sqrt{|L_j|}}\right)
\cdot
\left(\sum_{j=1}^{k}\sqrt{|L_j|}\right)^{-1}
$$

生成任务使用 CFG 采样，把有条件分布和无条件分布拉开：

$$
p_{\theta}^{\mathrm{CFG}}(\cdot\mid x_{<i})=
p_{\theta}(\cdot\mid x_{<i})+(\lambda-1)\left[p_{\theta}(\cdot\mid x_{<i})-p_{\theta}(\cdot\mid\emptyset)\right]
$$

词表扩展口径：

$$
|V_{\text{Audex}}|=131072+65536+8192+5=204805\quad(\text{训练中 padding 到 }205312)
$$

### 3.3. 机制要点

- **理解侧是连续投影**：AF-Whisper 特征经 MLP 进入 text embedding space，不把输入音频先离散化。
- **生成侧是离散词表**：speech 用 [[方向/AI语音/模型/X-Codec2]] 单层 FSQ，non-speech 用 [[方向/AI语音/模型/X-Codec]] RVQ token。
- **codec dispatch 降低冲突**：语音与一般音频分开用专门 codec，避免一个 codec 同时承担所有声学结构。
- **训练顺序服务于“不回退”**：先冻结/暖启动新增音频组件，再逐步加入生成、理解和 text-only 保持数据。

## 4. 使用判断

- 看**能力不回退**：核心问题是 audio 扩展后文本推理和 agentic 能力是否保持，而不只是音频榜单得分。
- 看**工程落地**：统一 decoder + 标准 LLM serving 兼容性是优势，但 audio task 的模板、依赖和推理后处理仍较重。
- 看**自部署**：30B-A3B 适合服务器侧 MoE；快速试验可先看 2B 版本。

## 5. 相关对象

- [[方向/AI语音/MOC - 音频大模型]]：方向地图。
- [[方向/AI语音/模型/UALM]]：NVIDIA 早期统一理解/生成/推理音频语言模型。
- [[方向/AI语音/模型/FireRedAudio]]：同属理解 + 生成统一音频语言模型，对照连续表示拆分路线。
- [[方向/AI语音/模型/Qwen3-Omni]]：全模态 Omni MoE 对照。
- [[方向/AI语音/模型/StepAudio 2.5]] / [[方向/AI语音/模型/Step-Audio R1]]：音频理解、生成与推理能力对照线。
- [[方向/AI语音/模型/X-Codec]] / [[方向/AI语音/模型/X-Codec2]]：Audex 输出侧 audio codec token 对照。

## 6. 来源

- [Unified Audio Intelligence Without Regressing on Text Intelligence（arXiv:2607.05196）](https://arxiv.org/abs/2607.05196)
  - 内容定位：Audex 技术论文，描述模型架构、训练数据、训练流程、任务范围和能力不回退目标。
  - 用途：确认 Audex 身份、基座、任务面、训练 token 规模和 arXiv 首次提交日期。
  - 核验日期：2026-09-01
- [nvidia/Nemotron-Labs-Audex-30B-A3B（Hugging Face）](https://huggingface.co/nvidia/Nemotron-Labs-Audex-30B-A3B)
  - 内容定位：官方 30B-A3B 权重页，包含模型卡、推理模板、vLLM / Transformers / SGLang 用法和 license 入口。
  - 用途：确认开放权重、1M context、部署路径和任务模板。
  - 核验日期：2026-09-01
- [Unified Audio Intelligence Without Regressing on Text Intelligence（Hugging Face Papers）](https://huggingface.co/papers/2607.05196)
  - 内容定位：论文聚合页，列出 30B-A3B 与 2B 官方模型入口。
  - 用途：确认 2B 版本存在和模型生态入口。
  - 核验日期：2026-09-01

## 7. 待验证

- 本地加载 30B-A3B 的实际显存、吞吐、音频 I/O 模板复杂度和依赖兼容性。
- 1M context 在混合 audio-text 长上下文任务中的真实可用长度。
- 与 [[方向/AI语音/模型/FireRedAudio]]、[[方向/AI语音/模型/Qwen3-Omni]]、[[方向/AI语音/模型/StepAudio 2.5]] 在中文语音、长音频和 speech-to-speech 任务上的第三方复测差异。

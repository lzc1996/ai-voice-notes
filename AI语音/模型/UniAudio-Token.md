---
title: UniAudio-Token
类型: 模型
发表时间: 2026-05-29
时间依据: arXiv v1 首次提交日
任务:
  - 音频表示
  - 音频理解
  - 音频生成
  - TTS
  - 语音重建
开放状态:
  - paper
  - code
  - weights
aliases:
  - UAT
  - Universal Audio Tokenizer
  - UniAudio Token
  - Tencent Universal Audio Tokenizer
  - tencent/Universal_Audio_Tokenizer
  - "UniAudio-Token: Empowering Semantic Speech Tokenizers with General Audio Perception"
tags:
  - 类型/对象
  - 方向/AI语音
  - 主题/音频tokenizer
  - 主题/语音表示
  - 任务/音频理解
  - 任务/TTS
---

# UniAudio-Token

## 0. 背景

**问题现场**：语义音频 tokenizer 要在保留单码本、语言对齐与 LLM 友好特性的同时，覆盖音色、情绪、口音、环境声与音乐/音效等 general audio 感知。

**前序路线的缺口**：ASR 初始化的 semantic speech tokenizer 语义对齐强、token 流短，但容易产生 acoustic blindness——只保"说了什么"，忽略声学细节。

**UniAudio-Token 的切入点**：监督层用 Semantic-Acoustic Primitives（SAP）显式拆分语言内容/说话人属性/声学场景，结构层用 Semantic-Acoustic Equilibrium（SAE）内容感知 gate 把浅层声学细节注回深层语义，再单码本 VQ 成 25 Hz token。

## 1. 内容定位

`UniAudio-Token`（UAT / Universal Audio Tokenizer）是 Tencent / WeChat AI 等提出的单码本语义音频 tokenizer。它要解决的问题是：ASR 初始化的 semantic speech tokenizer 语义对齐强、token 流短，但容易产生 acoustic blindness，只保“说了什么”，忽略音色、情绪、口音、环境声和音乐/音效事件。

边界：本页的 UAT 指 `UniAudio-Token / Universal Audio Tokenizer`，不是软件工程里的 User Acceptance Testing（本库已有 [[知识wiki/计算机/集成经验/UAT]]），也不是另一个同名论文 `UAT: Unified Audio-Text Diffusion for Audio Generation, Editing, and Captioning`。它也不是 [[方向/AI语音/模型/UniAudio 2.0]] 的同名后续：UniAudio 2.0 是统一 audio LLM，UniAudio-Token 是可接入 Audio-LLM 的 tokenizer / 表示层。

## 2. 核心信息

- **核心目标**：保留 semantic speech tokenizer 的单码本、语言对齐和 LLM 友好特性，同时补上 general audio perception。
- **SAP 监督**：Semantic-Acoustic Primitives 把音频描述拆成 linguistic content、vocal attributes、auditory scene 三层；vocal attributes 包括 Age、Gender、Emotion、Accent、Prosody、Timbre。
- **SAE 融合**：Semantic-Acoustic Equilibrium 用内容感知 gate 把浅层声学细节注入深层语义表示，缓解 ASR 深层特征丢失声学信息的问题。
- **量化口径**：单 codebook，vocabulary size 8,192，token frame rate 25 Hz；比多码本 RVQ 更容易直接接 decoder-only LLM。
- **训练方式**：从 Whisper-large-v3 初始化 encoder/decoder；Stage 1 绕过 VQ 训练 SAE + SAP decoder，Stage 2 插入 VQ 主要优化 codebook。
- **下游验证**：统一接 Qwen2.5 LLM backbone，评估 tokenizer 级别的语音重建、ESC 聚类，以及 MMAU / MMAR / MMSU 上的 audio understanding。

## 3. 核心机制

### 3.1. 输入到输出流水线

```text
SAP 构造：原始音频 + ASR transcript -> audio-language captioner 生成声学描述 -> LLM teacher 归一化为 SAP JSON（linguistic content / vocal attributes / auditory scene）-> SAP-Instruct QA / MCQ / True-False 数据。

Tokenizer 训练：音频 waveform -> Whisper-large-v3 初始化的 audio encoder -> 深层语义特征 H_deep + 浅层声学特征 H_shallow -> SAE gate 融合 -> H_combined -> 单码本 VQ -> 25 Hz / 8192-vocab audio token -> SAP decoder 预测结构化 SAP。

下游 Audio-LLM：输入音频 -> UniAudio-Token 离散 token -> Qwen2.5 LLM backbone -> audio understanding / reasoning 输出；TTS 或重建时，音频 token -> flow matching reconstruction model -> speech waveform。
```

机制重点是“补齐语义 tokenizer 的声学盲区”：不放弃单码本 semantic token 的 LLM 友好性，而是在监督层用 SAP 显式拆分语言内容、说话人/韵律属性和声学场景，在结构层用 SAE 从浅层拉回细粒度声学信息。

### 3.2. 核心公式

SAE 先把浅层特征投到深层语义空间：

$$
\mathbf{H}_{\text{ada\_shallow}}=\mathbf{MLP}_{\text{adapter}}(\mathbf{H}_{\text{shallow}})
$$

内容感知 gate：

$$
\mathbf{g}=\sigma\left(\mathbf{MLP}_{\text{gate}}\left([\mathbf{H}_{\text{deep}};\mathbf{H}_{\text{shallow}}]\right)\right)
$$

最终融合表示：

$$
\mathbf{H}_{\text{combined}}=\mathbf{H}_{\text{deep}}+\mathbf{g}\odot\mathbf{H}_{\text{ada\_shallow}}
$$

单码本 VQ：

$$
\mathcal{C}=\{\mathbf{e}_{k}\}_{k=1}^{K}\subset\mathbb{R}^{D},\quad
\mathbf{h}_{t}^{q}=\mathbf{e}_{k},\quad
k=\arg\min_j\lVert\mathbf{h}_{t}-\mathbf{e}_{j}\rVert_2^2
$$

训练目标：

$$
\mathcal{L}=\mathcal{L}_{\text{SAP}}+
\lambda_1\underbrace{\lVert\operatorname{sg}[\mathbf{h}]-\mathbf{h}^{q}\rVert_2^2}_{\mathcal{L}_{\text{quantization}}}+
\lambda_2\underbrace{\lVert\mathbf{h}-\operatorname{sg}[\mathbf{h}^{q}]\rVert_2^2}_{\mathcal{L}_{\text{commitment}}}
$$

token histogram 用于检查 general audio 的聚类可分性：

$$
H=[h_0,h_1,\ldots,h_{V-1}]\in\mathbb{N}^{V},\quad
h_i=\sum_{k=0}^{n}\mathbb{I}(t_k=i)
$$

### 3.3. 机制要点

- **监督层补声学**：SAP 不只看 transcript，还显式标注 vocal attributes 和 auditory scene。
- **结构层补浅层细节**：SAE 根据内容动态决定拉多少浅层声学信息，避免粗暴 concat 冲淡语言抽象。
- **单码本保 LLM 友好**：25 Hz / 8192 vocab 的 flat token 直接适配标准 LLM，比多层 RVQ 更省接口复杂度。
- **理解与生成都可接**：输入侧服务 Audio-LLM 理解，输出侧可接 flow matching reconstruction / TTS 合成链路。

## 4. 使用判断

- 看**音频 tokenizer**：UniAudio-Token 是“semantic speech tokenizer 如何扩到 general audio”的代表。
- 看**和 X-Codec 的差异**：[[方向/AI语音/模型/X-Codec]] 是 acoustic codec 前融合 SSL semantic feature；UniAudio-Token 是 semantic tokenizer 上补 SAP/SAE，保持单码本。
- 看**和 X-Codec2 的差异**：[[方向/AI语音/模型/X-Codec2]] 偏 low-bitrate speech codec；UniAudio-Token 偏 Audio-LLM 输入/输出统一接口。
- 看**和 S3 / StableToken 的关系**：同属 supervised semantic tokenizer 线，但 UAT 把监督从 speech transcript 扩展到 vocal/audio scene。

## 5. 测试基准与性能

| 场景 | 指标 | UniAudio-Token 口径 | 对照 |
|---|---:|---:|---:|
| ESC-10 clustering | Silhouette / Purity ↑ | 0.091 / 0.730 | WavTokenizer -0.030 / 0.450；StableToken -0.035 / 0.468 |
| ESC-50 clustering | Silhouette / Purity ↑ | 0.023 / 0.390 | WavTokenizer -0.108 / 0.215；StableToken -0.096 / 0.174 |
| Speech reconstruction | Avg WER ↓ / MOS ↑ | 3.68 / 4.19 | StableToken 4.47 / 4.03；GLM-4-Voice-Tokenizer 5.04 / 4.08 |
| Audio-LLM understanding | MMAU / MMAR / MMSU overall ↑ | 61.10 / 45.80 / 43.54 | best baseline overall 55.20 / 40.10 / 40.56 |

## 6. 相关对象

- [[方向/AI语音/MOC - 音频大模型]]：本页归属的方向地图。
- [[方向/AI语音/知识/技术路线/语音生成 tokenizer codec 技术路线]]：音频 tokenizer / codec 路线总入口。
- [[方向/AI语音/知识/技术路线/语音模型 tokenizer 与 LLM tokenizer 对比]]：区分文本 tokenizer、semantic speech tokenizer、codec token 和 continuous latent。
- [[方向/AI语音/模型/X-Codec]]：语义增强 codec 对照，核心差异是 acoustic codec vs semantic tokenizer 起点不同。
- [[方向/AI语音/模型/X-Codec2]]：单层低码率 speech codec 对照。
- [[方向/AI语音/模型/S3 Tokenizer]]：supervised semantic speech tokenizer 对照。
- [[方向/AI语音/模型/StableToken]]：noise-robust semantic speech tokenizer 对照。
- WavTokenizer：single-codebook acoustic-centric tokenizer 对照；本库暂未建独立页。
- [[方向/AI语音/模型/Whisper]]：UAT encoder/decoder 初始化来源。
- [[方向/AI语音/模型/Qwen3-Omni]]：SAP captioner 和下游 Audio-LLM 评估相关对照。
- [[方向/AI语音/模型/UniAudio 2.0]]：同名但不同层级；UniAudio 2.0 是统一 audio LLM，UAT 是 tokenizer。

## 7. 来源

- [UniAudio-Token: Empowering Semantic Speech Tokenizers with General Audio Perception（arXiv:2605.31521）](https://arxiv.org/abs/2605.31521)
  - 内容定位：技术论文入口，提出 SAP、SAE、单码本 25 Hz tokenizer 和 Audio-LLM 下游评估。
  - 用途：确认模型身份、发表时间、核心机制、公式和实验口径。
  - 核验日期：2026-09-02
- [UniAudio-Token arXiv HTML](https://arxiv.org/html/2605.31521)
  - 内容定位：论文 HTML，可检索 SAP 结构、SAE/VQ/训练目标公式和实验表格。
  - 用途：抽取输入到输出机制、核心公式和性能指标。
  - 核验日期：2026-09-02
- [Tencent/Universal_Audio_Tokenizer（GitHub）](https://github.com/Tencent/Universal_Audio_Tokenizer)
  - 内容定位：官方代码仓库，包含训练/推理脚本、example usage、checkpoint 下载和 performance 表格。
  - 用途：确认开源状态、工程入口和官方模型名 `Universal Audio Tokenizer`。
  - 核验日期：2026-09-02
- [tencent/Universal_Audio_Tokenizer（Hugging Face）](https://huggingface.co/tencent/Universal_Audio_Tokenizer)
  - 内容定位：官方权重页，说明 compact single-codebook audio tokenizer、general audio perception 和 linguistic alignment。
  - 用途：确认权重开放、模型卡定位和下载入口。
  - 核验日期：2026-09-02

## 8. 待验证

- `UAT` 缩写在后续检索中是否会和 Unified Audio-Text Diffusion 持续冲突；必要时保留 `UniAudio-Token` 为主入口。
- UniAudio-Token 与 [[方向/AI语音/模型/S3 Tokenizer]]、[[方向/AI语音/模型/StableToken]]、CosyVoice2 tokenizer 在中文长文本 TTS 和强情绪/方言语音上的真实差异。
- SAP 自动标注中的 Qwen3-Omni-Captioner / Qwen3 teacher 是否会把 teacher 偏差写进 tokenizer。
- 25 Hz / 8192 vocab 单码本在长音频上下文、低延迟流式生成和 voice cloning 中的稳定性。

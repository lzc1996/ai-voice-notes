---
title: X-Codec
类型: 模型
发表时间: 2024-08-30
时间依据: arXiv v1 首次提交日；AAAI 2025 论文
任务:
  - 音频表示
  - 音频生成
  - TTS
  - 音乐续写
  - 文本到音频生成
开放状态:
  - paper
  - code
  - demo
  - weights
aliases:
  - XCodec
  - X-codec
  - X codec
  - Codec Does Matter
  - "Codec Does Matter: Exploring the Semantic Shortcoming of Codec for Audio Language Model"
tags:
  - 类型/对象
  - 方向/AI语音
  - 主题/音频tokenizer
  - 主题/语音表示
  - 任务/TTS
---

# X-Codec

## 0. 背景

**问题现场**：audio LLM 用 codec token 做语音/音频生成时，TTS 出现漏词、错词和语义漂移。

**前序路线的缺口**：普通 acoustic codec（如 EnCodec / DAC）作为 audio LLM tokenizer 时语义不够稳。

**X-Codec 的切入点**：在 acoustic encoder 与 RVQ 之前融合预训练 SSL 语义特征，让统一 RVQ 的每层 token 同时含语义与声学信息，上层 LLM 仍按单流 codec token 序列处理。

## 1. 内容定位

`X-Codec` 是 HKUST / Microsoft 等提出的语义增强神经音频 codec，论文题目是 *Codec Does Matter: Exploring the Semantic Shortcoming of Codec for Audio Language Model*。它针对的问题不是传统压缩率，而是普通 acoustic codec（如 EnCodec / DAC）作为 audio LLM tokenizer 时语义不够稳，导致 TTS / 音频生成中的漏词、错词和语义漂移。

边界：X-Codec 是多层 [[方向/AI语音/知识/基础概念/RVQ（残差向量量化）]] codec/tokenizer，不是 [[方向/AI语音/模型/X-Codec2]] 的单层 FSQ 路线；也不是完整 TTS 或 audio LLM，上层 VALL-E / MusicGen / UALM / Audex 这类模型负责生成 token，X-Codec 负责把音频和离散 token 互转。

## 2. 核心信息

- **核心思想**：在 acoustic encoder 和 RVQ 前融合预训练 SSL semantic encoder（HuBERT / WavLM / HuBERT-General-Audio）特征，让每层 codec token 同时含语义与声学信息。
- **X-shaped 结构**：两个输入分支（acoustic feature + semantic feature）和两个输出目标（waveform reconstruction + semantic reconstruction）在统一 RVQ 中交汇。
- **模型细节**：16 kHz 音频；acoustic encoder 4 个卷积块，下采样倍率 $[2,4,5,8]$，合计 320x，即约 50 Hz 帧率；RVQ 训练时随机选 $n_q\in\{1,2,3,4,8\}$。
- **应用验证**：论文用 VALL-E 风格 zero-shot TTS、music continuation、text-to-sound 和 ARCH semantic representation benchmark 验证 codec 对 audio LLM 的影响。
- **结果口径**：在 LibriSpeech test-clean / VALL-E 设置下，X-Codec-wavlm-base-plus 的 AR+NAR WER 为 3.26%，低于 SpeechTokenizer 5.24% 和 baseline acoustic codec 7.70%。
- **开源形态**：官方 GitHub 提供训练/推理代码和 demo；Transformers 文档已加入 `XcodecModel`，并列出多个 speech / general audio checkpoint 入口。

## 3. 核心机制

### 3.1. 输入到输出流水线

```text
基础 acoustic codec：raw waveform X -> acoustic encoder -> acoustic feature A -> RVQ -> discrete codes Q / quantized feature A_q -> acoustic decoder -> reconstructed waveform X_hat。

X-Codec：
raw waveform X
  |-> acoustic encoder -> A
  `-> pretrained semantic encoder（HuBERT / WavLM / HuBERT-General-Audio）-> S* -> semantic encoder -> S

[A, S] -> concat + projection -> unified feature U
       -> RVQ -> codes Q / quantized U_q
          |-> semantic projector -> S*_hat
          `-> acoustic projector + decoder -> X_hat

接 audio LLM：训练音频 -> X-Codec codes Q -> VALL-E / MusicGen / GPT-style audio LM 自回归预测 token -> X-Codec decoder -> 语音 / 音乐 / 音效输出。
```

X-Codec 的机制重点是「不把语义只压在第一层 token 或另一路 token 里」，而是让统一 RVQ 的每层 token 都看见 semantic + acoustic 融合特征。这样上层 LLM 仍然可以把 codec token 当统一离散序列处理，不需要为 semantic/acoustic 分支重写结构。

### 3.2. 核心公式

普通 acoustic codec 的编码口径：

$$
\mathbf{A}=E_a(\mathbf{X}),\quad \mathbf{Q}=\mathrm{RVQ}(\mathbf{A}),\quad \hat{\mathbf{X}}=D_a(\mathbf{A}_q)
$$

X-Codec 先取预训练语义特征，再和声学特征融合：

$$
\mathbf{S}^{*}=E_s^{\mathrm{SSL}}(\mathbf{X}),\quad \mathbf{S}=E_s(\mathbf{S}^{*})
$$

论文给出的统一特征公式：

$$
\mathbf{U}=\mathrm{concat}(\phi_s(\mathbf{S}),\phi_a(\mathbf{A}))
$$

统一 RVQ 产生离散 token，并分别投回语义/声学解码目标：

$$
\mathbf{Q}=\mathrm{RVQ}(\mathbf{U}),\quad
\hat{\mathbf{S}}^{*}=\beta_s(\mathbf{U}_q),\quad
\hat{\mathbf{X}}=D_a(\beta_a(\mathbf{U}_q))
$$

语义重建损失用 MSE，并以常数 $\gamma$ 调整量级：

$$
\mathcal{L}_{\mathrm{sem}}=\left\lVert \hat{\mathbf{S}}^{*}-\mathbf{S}^{*}\right\rVert_2^2
$$

整体训练目标可按「声学重建 + 量化约束 + 语义重建」理解：

$$
\mathcal{L}=\mathcal{L}_{\mathrm{mel}}+\mathcal{L}_{\mathrm{STFT}}+\mathcal{L}_{\mathrm{GAN}}+\mathcal{L}_{\mathrm{commit}}+\gamma\mathcal{L}_{\mathrm{sem}}
$$

token 帧率由卷积下采样倍率决定：

$$
R_{\mathrm{tok}}=\frac{16000}{2\cdot4\cdot5\cdot8}=50\ \mathrm{frames/s}
$$

### 3.3. 机制要点

- **语义先验进量化前**：不是事后给 codec token 加标签，而是在 RVQ 前让声学特征和 SSL 语义特征融合。
- **每层 RVQ 都带语义压力**：相比只让第一层 token 承载内容，X-Codec 让多层 token 都改善 phonetic discriminability。
- **兼容单流 audio LM**：仍输出统一 codec token 序列，适配 flattened token、delay pattern 或 GPT-style 生成。
- **牺牲点在压缩效率**：额外 semantic branch 带来开销，论文也承认语义增强可能略影响原始压缩/传输用途。

## 4. 使用判断

- 看**audio LLM tokenizer**：X-Codec 适合作为「codec token 要不要带语义」的核心证据，比只看 codec 重建 MOS 更相关。
- 看**TTS 漏词/错词**：如果上层 LM 经常错读内容，优先比较 X-Codec / SpeechTokenizer / [[方向/AI语音/模型/S3 Tokenizer]] / [[方向/AI语音/模型/BiCodec]]，而不只是换更大 LLM。
- 看**通用音频生成**：general audio 版本说明语义增强不只对语音有效，也可迁移到 music continuation 和 text-to-sound。
- 看**和 X-Codec2 的差异**：X-Codec 是多层 RVQ + semantic reconstruction；X-Codec2 是 LLM-friendly 单层 speech codec，路线相近但不是同一个 tokenizer。

## 5. 测试基准与性能

| 场景 | 指标 | X-Codec 口径 | 对照 |
|---|---:|---:|---:|
| VALL-E AR+NAR zero-shot TTS | WER ↓ | 3.26%（X-Codec-wavlm-base-plus） | SpeechTokenizer 5.24%；baseline acoustic codec 7.70% |
| Phonetic discriminability | ABX within / across ↓ | 3.3 / 4.3（$n_q=8$） | EnCodec 17.5 / 27.0；DAC 21.7 / 33.2 |
| Music continuation | FAD ↓ | 1.37 | acoustic codec 1.43 |
| Text-to-sound | FAD ↓ / CLAP ↑ | 4.10 / 0.483 | acoustic codec 6.19 / 0.417 |

## 6. 相关对象

- [[方向/AI语音/MOC - 音频大模型]]：本页归属的方向地图。
- [[方向/AI语音/知识/基础概念/NAC（神经音频 Codec）]]：X-Codec 属于 neural audio codec / codec token 路线。
- [[方向/AI语音/知识/基础概念/RVQ（残差向量量化）]]：X-Codec 的核心量化模块。
- [[方向/AI语音/模型/X-Codec2]]：后续/相邻 speech codec 路线，强调单层 FSQ / 50 tokens/s。
- [[方向/AI语音/模型/UALM]]：使用 X-Codec 作为 audio output tokenizer。
- [[方向/AI语音/模型/Audex]]：speech 用 X-Codec2，non-speech audio generation 使用 X-Codec 类 RVQ token。
- [[方向/AI语音/模型/AudioLM]] / [[方向/AI语音/模型/Moshi]]：codec token audio LM 的上层建模对照。
- [[方向/AI语音/模型/BiCodec]] / [[方向/AI语音/模型/S3 Tokenizer]]：LLM-friendly speech tokenizer 对照。

## 7. 来源

- [Codec Does Matter: Exploring the Semantic Shortcoming of Codec for Audio Language Model（arXiv:2408.17175）](https://arxiv.org/abs/2408.17175)
  - 内容定位：X-Codec 技术论文入口，提出语义增强 codec、X-shaped 结构和 TTS / music / text-to-sound 评测。
  - 用途：确认发表时间、任务定位、机制和核心实验结果。
  - 核验日期：2026-09-01
- [Codec Does Matter: Exploring the Semantic Shortcoming of Codec for Audio Language Model（arXiv HTML）](https://arxiv.org/html/2408.17175)
  - 内容定位：论文 HTML，可检索方法、公式、模型细节、实验表格和 limitation。
  - 用途：抽取 `U=concat(...)`、RVQ/semantic reconstruction 机制、50 Hz 帧率和实验指标。
  - 核验日期：2026-09-01
- [zhenye234/xcodec（GitHub）](https://github.com/zhenye234/xcodec)
  - 内容定位：官方代码仓库，含 X-Codec README、训练/推理代码、模型目录和 demo 入口。
  - 用途：确认开源状态、实现入口和与 X-Codec2 的仓库关系。
  - 核验日期：2026-09-01
- [ZhenYe234/xcodec（Hugging Face）](https://huggingface.co/ZhenYe234/xcodec)
  - 内容定位：官方 checkpoint 页面，包含 speech / general audio 多个 X-Codec 权重与配置文件。
  - 用途：确认权重开放、checkpoint 版本和工程下载入口。
  - 核验日期：2026-09-02
- [X-Codec project page](https://x-codec-audio.github.io/)
  - 内容定位：官方 demo / project page，展示语音、音乐、音效生成样例。
  - 用途：确认 demo 入口和任务展示范围。
  - 核验日期：2026-09-01
- [X-Codec - Hugging Face Transformers docs](https://huggingface.co/docs/transformers/model_doc/xcodec)
  - 内容定位：Transformers 官方模型文档，说明 `XcodecModel`、encode/decode 接口、16 kHz、目标带宽和 checkpoint 入口。
  - 用途：确认工程接入口和已纳入 Transformers 的实现口径。
  - 核验日期：2026-09-01

## 8. 待验证

- 官方 checkpoint 在 speech / general audio 不同版本间的训练数据、SSL encoder 和 target bandwidth 差异。
- X-Codec 与 [[方向/AI语音/模型/X-Codec2]] 的作者线、训练代码和权重继承关系。
- 在中文 TTS、低 SNR 语音和长音频生成中，语义增强是否仍显著降低漏词/错词。
- 额外 semantic branch 对实时 codec/tokenizer 延迟和部署成本的影响。

---
title: NAC（神经音频 Codec）
类型: 概念
发表时间: 2021-07-07
时间依据: SoundStream arXiv 首次提交日（神经音频 codec 代表起点）
相关主题:
  - 语音表示
  - 语音生成
相关模型:
  - "[[方向/AI语音/模型/DAC（Descript Audio Codec）]]"
  - "[[方向/AI语音/模型/BiCodec]]"
  - "[[方向/AI语音/模型/S3 Tokenizer]]"
  - "[[方向/AI语音/模型/X-Codec]]"
  - "[[方向/AI语音/模型/X-Codec2]]"
  - "[[方向/AI语音/模型/UniAudio-Token]]"
  - "[[方向/AI语音/模型/CleanCodec]]"
  - "[[方向/AI语音/模型/Qwen-Audio-VAE]]"
  - "[[方向/AI语音/模型/UniSE（Unified Speech Enhancement）]]"
aliases:
  - 神经音频 Codec（NAC）
  - NAC
  - 神经音频 Codec
  - nac
tags:
  - 类型/对象
  - 方向/AI语音
  - 主题/语音表示
  - 主题/语音生成
---

# NAC（神经音频 Codec）

## 1. 身份

神经音频 Codec 是把连续音频压缩成可建模表示，再从该表示重建波形的 encoder-decoder。它在语音生成里常被当作 audio tokenizer：encoder 把波形变成离散 token 或连续 latent，decoder / vocoder 再把模型输出还原成可听音频。

`NAC` 在这组笔记里按 **Neural Audio Codec** 处理，作为神经音频 Codec 的英文缩写入口。

边界：传统通信 codec 主要服务压缩传输；神经音频 codec 更常服务生成模型、TTS、语音增强、语音编辑和 codec LM。它不是 ASR encoder，也不是文本 tokenizer；核心约束是压缩率、重建质量、延迟和可被语言模型建模的难度。

## 2. Codec 是什么

Codec = **coder + decoder**。在音频里，它回答的是：“怎样把高采样率连续波形压成更短的表示，并且还能还原成可听音频？”

```text
原始音频
  -> encoder / coder：压缩成 token、码流或 latent
  -> 中间表示：离散码本 token / [[方向/AI语音/知识/基础概念/RVQ（残差向量量化）|RVQ]] codes / continuous latent
  -> decoder：重建 waveform
```

需要分清两层意思：

| 语境 | 目标 | 例子 |
|---|---|---|
| 通信 / 存储 codec | 压缩传输、节省带宽 | Opus、AAC、MP3、AMR |
| 神经音频 codec | 给生成模型提供短表示，并能重建波形 | SoundStream、EnCodec、[[方向/AI语音/模型/DAC（Descript Audio Codec）]]、[[方向/AI语音/模型/BiCodec]] |

语音模型里说 codec，通常指第二类：不是为了把文件压小而已，而是为了把音频变成 LLM、diffusion、[[方向/AI语音/知识/基础概念/Flow Matching（流匹配）|Flow Matching]] 或 TTS 模型更容易建模的 token / latent。

## 3. 基本链路

```text
音频波形 -> codec encoder -> token / latent -> 生成模型 -> codec decoder / vocoder -> 音频波形
```

- **Encoder**：把高采样率波形压成短序列，常见输出是 [[方向/AI语音/知识/基础概念/RVQ（残差向量量化）|RVQ]] 离散码、semantic token、global token 或连续 latent。
- **Decoder / [[方向/AI语音/知识/基础概念/Vocoder（声码器）|vocoder]]**：把 token / latent 还原成波形，决定音质、音色保持、边界伪影和流式能力。
- **语言模型接口**：离散 token 更容易接入 decoder-only LM；连续 latent 更适合 diffusion / flow / VAE 类生成。

## 4. 关键设计变量

| 变量 | 影响 |
|---|---|
| 帧率 | 每秒产生多少 token / latent；帧率越低，生成越快，但细节越难保留 |
| 码率 | 压缩后每秒信息量；码率低有利于建模，代价是重建上限下降 |
| 码本 / [[方向/AI语音/知识/基础概念/RVQ（残差向量量化）]] 层数 | 离散 codec 的容量；层数越多信息越细，token 流越长 |
| 表示类型 | 离散 token 适合 LM；连续 latent 适合 DiT / diffusion / flow |
| decoder 质量 | 最终音质上限；上游模型再强也不能补掉 decoder 自身失真 |
| 流式能力 | 决定首包延迟、chunk 边界伪影和实时可用性 |

## 5. 常见路线

| 路线 | 代表 | 优点 | 代价 |
|---|---|---|---|
| 高帧率离散 codec | SoundStream、EnCodec | 重建稳、信息细 | token 长，AR 生成慢 |
| 语义增强 codec | [[方向/AI语音/模型/X-Codec]] | 在 RVQ 前融合 SSL 语义特征，更适合 audio LLM 保内容 | 额外 semantic branch 增加复杂度 |
| 通用感知单码本 tokenizer | [[方向/AI语音/模型/UniAudio-Token]] | 25 Hz / 8192 vocab，兼顾 linguistic alignment 和 general audio perception | 依赖 SAP/SAE 设计，跨域稳健性要复测 |
| 有监督语义 tokenizer | [[方向/AI语音/模型/S3 Tokenizer]] | 语义 token 更贴近文本和副语言信息 | 不是完整 codec，重建依赖 flow/vocoder |
| LLM-friendly 单层 codec | [[方向/AI语音/模型/X-Codec2]] | 单层大码本、token 流更适合自回归 LLM | 50 tokens/s 仍需实测延迟和重建质量 |
| 感知引导去噪 codec | [[方向/AI语音/模型/CleanCodec]] | 12.5 tokens/s，优先编码语义、音色和韵律，丢弃不重要噪声 | 不是 lossless，背景/环境细节可能被主动抹掉 |
| 低帧率 speech tokenizer | Qwen3-TTS 12Hz tokenizer | 低延迟、低成本 | 需要生成模型补韵律和细节 |
| 解耦 speech codec | [[方向/AI语音/模型/BiCodec]] | 把语义 token 和说话人/风格 token 拆开 | decoder 质量和属性解耦稳定性要实测 |
| 连续 audio latent | [[方向/AI语音/模型/Qwen-Audio-VAE]]、[[方向/AI语音/模型/DAC（Descript Audio Codec）]] / VAE latent | 适合 DiT / flow / 通用音频生成 | 训练和解码链路更复杂 |

## 6. 什么时候关注

- **TTS / voice cloning**：codec 决定每秒 token 数、首包延迟、音质和音色保持。
- **codec LM / SELM / UniSE**：把 [[方向/AI语音/知识/基础概念/SR（语音恢复）|语音恢复]] 或生成改写成“预测离散音频 token”的语言建模问题。
- **DiT / flow 语音增强**：codec 或 VAE latent 可以作为连续生成空间，减少直接波形建模成本。
- **真实退化建模**：低码率 codec 伪影本身也是语音增强、VoIP 和远场链路里的失真来源。

## 7. 使用注意

- 通信 codec 伪影和神经 codec 表示是两件事：前者是待修复的失真，后者是模型内部表示工具。
- 离散 token 不等于可纠错 token：普通 codec 可能把噪声、混响和录音伪影也编码成合法 token；是否能区分“有效信息”和“偏移”见 [[方向/AI语音/思考/Error-Correcting Speech Token（可纠错语音 Token）]]。
- token 越短不一定越好：低帧率能降延迟，但可能牺牲瞬态、韵律和音色细节。
- 重建指标要和下游任务一起看：MOS / PESQ / STOI 不足以覆盖 voice cloning、ASR 可懂度和说话人保持。
- codec decoder 是上限瓶颈：上游 LM 预测再好，decoder 失真也会锁死最终音质。
- 不要把 SSL 表示当 codec token：[[方向/AI语音/知识/基础概念/SSL 编码器|SSL 编码器]]通常输出不可直接重建的 hidden states。
- 不要把 codec decoder 和 [[方向/AI语音/知识/基础概念/Vocoder（声码器）|vocoder]] 完全等同：两者都能还原波形，但 codec decoder 通常服务“压缩表示 -> 波形”，vocoder 常服务“声学特征 / mel -> 波形”。

判断规则可以写得更机械一点：

```text
codec token / RVQ code / continuous latent -> waveform        = codec decoder
mel / spectrogram / acoustic feature -> waveform              = vocoder
codec token / latent -> mel / acoustic feature -> waveform    = codec decoder + vocoder 两段
```

所以 Qwen2.5-Omni 这类 `speech code -> Mel -> BigVGAN -> waveform` 是两段式；Moshi/Mimi、FireRedAudio/RedAE 这类 `codec token 或 latent -> waveform` 更接近 codec decoder / autoencoder decoder。

## 8. 关键来源

- [SoundStream: An End-to-End Neural Audio Codec](https://arxiv.org/abs/2107.03312)
  - 内容定位：端到端神经音频 codec 论文，记录 RVQ 低码率音频压缩和重建路线。
  - 用途：建立 neural audio codec 的基本范式。
  - 核验日期：2026-07-29
- [High Fidelity Neural Audio Compression](https://arxiv.org/abs/2210.13438)
  - 内容定位：EnCodec 论文，记录高保真神经音频压缩和低码率离散表示。
  - 用途：作为高帧率离散 codec / audio tokenizer 的代表。
  - 核验日期：2026-07-29
- [Descript Audio Codec: High-Fidelity Audio Compression](https://arxiv.org/abs/2306.06546)
  - 内容定位：DAC 论文，记录高保真 neural audio codec 和开源实现路线。
  - 用途：支撑 continuous latent / codec VAE、DiT 语音生成路线的背景。
  - 核验日期：2026-07-29
- [Codec Does Matter: Exploring the Semantic Shortcoming of Codec for Audio Language Model](https://arxiv.org/abs/2408.17175)
  - 内容定位：X-Codec 论文，说明普通 acoustic codec 用作 audio LLM tokenizer 时的语义短板。
  - 用途：支撑语义增强 neural audio codec 路线。
  - 核验日期：2026-09-02
- [UniAudio-Token: Empowering Semantic Speech Tokenizers with General Audio Perception](https://arxiv.org/abs/2605.31521)
  - 内容定位：UniAudio-Token 论文，说明 semantic speech tokenizer 的 acoustic blindness 与 SAP/SAE 修正方案。
  - 用途：支撑通用感知 single-codebook audio tokenizer 路线。
  - 核验日期：2026-09-02

## 9. 相关对象

- [[方向/AI语音/知识/技术路线/语音生成 tokenizer codec 技术路线|语音生成 tokenizer codec 技术路线]]：更具体的语音生成选型路线图。
- [[方向/AI语音/知识/技术路线/语音模型 tokenizer 与 LLM tokenizer 对比|语音模型 tokenizer 与 LLM tokenizer 对比]]：区分文本 tokenizer、speech tokenizer、codec token 和 latent。
- [[方向/AI语音/思考/Error-Correcting Speech Token（可纠错语音 Token）]]：区分“离散化”和“可纠错表示”，解释 robust semantic tokens 与 clean acoustic tokens 的分工。
- [[方向/AI语音/知识/基础概念/RVQ（残差向量量化）|RVQ]]：神经音频 codec 中常见的多级离散量化方式。
- [[方向/AI语音/知识/基础概念/Vocoder（声码器）|声码器]]：把声学表示、latent 或 token 还原成 waveform 的输出侧模块。
- [[方向/AI语音/知识/技术路线/语音网络结构与模块|语音网络结构与模块]]：说明 codec encoder-decoder、vocoder 和 latent 在不同语音任务里的模块位置。
- [[方向/AI语音/模型/S3 Tokenizer|S3 Tokenizer]]：CosyVoice 的 supervised semantic speech tokenizer。
- [[方向/AI语音/模型/DAC（Descript Audio Codec）]]：Descript 的高保真通用 neural audio codec。
- [[方向/AI语音/模型/BiCodec|BiCodec]]：解耦 speech token codec 的具体案例。
- [[方向/AI语音/模型/X-Codec]]：语义增强多层 RVQ codec，融合 SSL semantic feature 和 acoustic feature。
- [[方向/AI语音/模型/X-Codec2|X-Codec2]]：LLaSA 使用的单层大码本 speech codec / tokenizer。
- [[方向/AI语音/模型/UniAudio-Token]]：单码本 semantic audio tokenizer，补 general audio perception。
- [[方向/AI语音/模型/CleanCodec]]：低帧率、感知引导、去噪式 speech tokenizer。
- [[方向/AI语音/模型/SELM|SELM]]：离散 token + language model 做语音增强的早期范式。
- [[方向/AI语音/模型/UniSE（Unified Speech Enhancement）|UniSE]]：codec LM 统一语音增强案例。
- [[方向/AI语音/知识/生成式语音增强/DiT 与语音增强（DiT-based Speech Enhancement）|DiT 与语音增强]]：用 codec / VAE latent 做连续生成空间。

## 10. 待验证

- 当前音频处理链路更适合离散 codec token、低帧率 tokenizer，还是连续 latent。
- codec 压缩是否会放大漏音、混响或低码率通信伪影。
- S3 Tokenizer、UniAudio-Token、X-Codec、X-Codec2、BiCodec、EnCodec、SoundStream、DAC、Qwen3-TTS tokenizer 在中文语音和长文本 TTS 里的真实差异。

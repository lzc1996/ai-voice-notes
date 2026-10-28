---
title: FastSpeech
类型: 模型
发表时间: 2019-05-22
时间依据: FastSpeech arXiv v1 submitted 2019-05-22；FastSpeech 2 arXiv v1 submitted 2020-06-08
任务:
  - TTS
开放状态:
  - paper
aliases:
  - fastspeech
  - Fastspeech
  - FastSpeech 1
  - FastSpeech 2
  - FastSpeech 2s
  - Fast, Robust and Controllable Text to Speech
  - Fast and High-Quality End-to-End Text to Speech
  - 非自回归 TTS
  - 非自回归语音合成
tags:
  - 类型/对象
  - 方向/AI语音
  - 任务/TTS
  - 主题/非自回归
  - 主题/韵律控制
---

# FastSpeech

## 0. 背景

- **非自回归 TTS 基线**：FastSpeech 把 TTS 从 attention-based AR decoder 转向显式 duration + 并行 acoustic decoding。
- **可控性入口**：duration 控语速；FastSpeech 2 的 pitch / energy predictors 给韵律控制提供了清晰接口。
- **鲁棒性来源**：显式 alignment 替代推理期 attention 搜索，降低漏词和重复词风险。
- **后续借鉴点**：很多 TTS / VC / 语音生成系统里的 F0、energy、duration 条件，都可以回看 FastSpeech 2 variance adaptor 这一类设计。

## 1. 身份

`FastSpeech` 是微软亚洲研究院等提出的非自回归 TTS 架构家族。核心目标不是做语音大模型，而是把早期 autoregressive TTS 的逐帧 mel 生成改成并行生成，从而提升推理速度、减少漏词/重复词，并把时长、语速、韵律控制显式化。

边界：FastSpeech 是 TTS acoustic model / text-to-mel 路线，不是 [[方向/AI语音/知识/基础概念/Vocoder（声码器）|vocoder]]，也不是 codec-token / LLM-based TTS。生成音频通常还要接 WaveGlow、HiFi-GAN 一类 vocoder。

## 2. 核心机制

```text
text / phoneme
-> phoneme encoder
-> duration predictor / length regulator
-> expanded hidden sequence
-> mel decoder
-> vocoder
-> waveform
```mermaid

- **FastSpeech v1**：用 autoregressive teacher model 的 attention alignment 提取 phoneme duration；length regulator 按 duration 展开 encoder hidden；decoder 并行生成 mel-spectrogram。
- **知识蒸馏**：v1 用 teacher 生成的 mel 作为训练目标，降低 target 侧分布复杂度，但也引入 teacher 信息损失和两阶段训练成本。
- **FastSpeech 2**：去掉 teacher mel 蒸馏，直接用 ground-truth mel 训练；variance adaptor 显式加入 duration、pitch、energy，缓解 TTS 的 one-to-many 映射。
- **FastSpeech 2s**：进一步尝试直接从文本并行生成 waveform，减少 text-to-mel + vocoder 的级联边界。

### 2.1. 架构示意（概念级）

> [!note] 架构示意（概念级）
> 按本页已有输入—中间表示—输出链路整理，不替代论文结构图。

```
flowchart LR
  A["Phoneme / text input"] --> B["Phoneme encoder"]
  B --> C["Duration predictor + length regulator"]
  C --> D["Mel decoder"]
  D --> E["Vocoder"]
  E --> F["语音波形"]
```

## 3. 和相邻路线的区别

- **Tacotron / Transformer TTS**：通常 autoregressive 生成 mel，质量自然但推理慢，且 attention 错位会导致漏词/重复。
- **FastSpeech**：先预测 duration，再并行生成 mel；速度快，控制直接，但依赖 duration/variance 预测质量。
- **LLM-based TTS**：把语音表示成 codec / semantic token 后用 LLM 自回归生成；重点在语言模型与语音 token，不是显式 length regulator。
- **Flow / Diffusion TTS**：常在 mel、latent 或 waveform 空间做连续生成；重点在生成分布建模，不是 FastSpeech 式 feed-forward Transformer。

## 4. 对 LLM-SE 的可借鉴点

在 [[方向/AI语音/知识/技术路线/LLM-SE Stage 0（表示空间准备）]] 里，FastSpeech 2 最有用的不是整套 TTS pipeline，而是“把 prosody 拆成 frame-level 条件”的思想：duration / F0 / energy 不必塞进一个全局语义 token，可以作为单独条件通道进入后端生成器。

注意边界：FastSpeech 2 的 variance adaptor 是 TTS 里从文本到语音的条件补足；把它借到语音增强时，只能说明“韵律条件可以显式建模”，不能直接推出增强模型该用同样的训练目标或同样的 predictor 结构。

## 5. 常见误读

- **不是完全端到端音频生成**：主线 FastSpeech / FastSpeech 2 输出 mel，仍需 vocoder；FastSpeech 2s 才尝试 text-to-waveform。
- **不是不需要对齐**：它把对齐显式化为 duration，训练时仍要来自 teacher attention 或 forced alignment。
- **不是 LLM-TTS**：FastSpeech 的主干是 feed-forward Transformer acoustic model，不是 decoder-only LLM 预测 speech tokens。
- **不是只靠并行就更自然**：自然度依赖 duration、pitch、energy 和 vocoder；并行主要解决速度与 attention 鲁棒性。

## 6. 关键来源

- [FastSpeech: Fast, Robust and Controllable Text to Speech](https://arxiv.org/abs/1905.09263)
  - 内容定位：FastSpeech v1 原始论文，提出 feed-forward Transformer、duration predictor、length regulator 和并行 mel 生成。
  - 用途：确认模型身份、并行生成动机、teacher alignment / distillation 机制和速度收益。
- [FastSpeech 2: Fast and High-Quality End-to-End Text to Speech](https://arxiv.org/abs/2006.04558)
  - 内容定位：FastSpeech 2 / 2s 原始论文，提出 ground-truth mel 训练、variance adaptor、duration / pitch / energy 条件和 text-to-waveform 尝试。
  - 用途：解释 FastSpeech 2 为什么成为 prosody 条件和 variance adaptor 的常用参照。
- 核验日期：2026-09-04

## 7. 相关笔记

- [[方向/AI语音/MOC - TTS]]：FastSpeech 属于传统/经典 TTS 架构对象。
- [[方向/AI语音/模型/CosyVoice]]：LLM + speech token / flow 路线，对比 FastSpeech 的显式 duration acoustic model。
- [[方向/AI语音/模型/Qwen3-TTS]]：现代低帧率 speech-token TTS 路线。
- [[方向/大模型/训练/Teacher Forcing（教师强制）]]：对比 autoregressive decoder 训练/推理落差。
- [[方向/AI语音/知识/基础概念/F0（基频）]]：FastSpeech 2 variance adaptor 里的 pitch 条件。

## 8. 待验证

- 是否需要单独拆 `VITS`、`Tacotron`、`F5-TTS` 等经典/现代 TTS 架构对象页。
- LLM-SE 的 prosody 条件是否应只借鉴 FastSpeech 2 的变量分解，而不复用其 predictor / loss 细节。

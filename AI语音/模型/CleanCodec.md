---
title: CleanCodec
类型: 模型
发表时间: 2026-06-03
时间依据: arXiv 首次提交日
任务:
  - 语音表示
  - 语音生成
  - TTS
开放状态:
  - paper
aliases:
  - "CleanCodec: Efficient and Robust Speech Tokenization via Perceptually Guided Encoding"
  - Efficient and Robust Speech Tokenization via Perceptually Guided Encoding
  - denoising audio codec
  - perceptually guided speech tokenizer
tags:
  - 类型/对象
  - 方向/AI语音
  - 主题/语音表示
  - 主题/语音生成
---

# CleanCodec

## 0. 背景

- **适合 LLM/SLM**：12.5 tokens/s 显著缩短音频序列，降低自回归 TTS / speech LM 的训练和推理成本。
- **不是纯压缩指标**：CleanCodec 的核心价值是“更少 token 仍保留 speech intelligibility 与 speaker similarity”，不是传统 codec 的文件压缩率。
- **对噪声更鲁棒**：训练目标主动鼓励丢弃不重要的背景噪声和录音 artifact，适合真实采集语音而不是只服务干净数据。

## 1. 身份

`CleanCodec` 是一个面向语音生成和下游建模的**去噪式神经语音 codec / speech tokenizer**。它把语音 tokenization 重新表述为 selective information bottleneck：不追求保留录音里的所有细节，而是优先编码人耳和任务真正关心的语义、音色和韵律，丢掉背景噪声、录音伪影等感知上不重要的信息。

边界：CleanCodec 不是 TTS 模型本身，也不是 ASR encoder；它是 `audio waveform <-> discrete token / codec representation` 的底层表示模块。上层 TTS / voice conversion / speech LM 负责生成或变换 token，CleanCodec 负责压缩和重建。

## 2. 核心链路

```text
noisy / imperfect speech
  -> perceptually guided codec encoder
  -> low-rate local speech tokens（最低 12.5 tokens/s）
  -> codec decoder / vocoder
  -> cleaner reconstructed speech
```

## 3. 关键设计

- **选择性编码**：把 codec 训练目标从“重建一切”改成“保留感知重要信息”，避免把码率浪费在噪声和录音伪影上。
- **联合语音增强训练**：训练时耦合普通重建任务和 speech enhancement 任务，让 encoder 学会优先编码干净语音结构。
- **条件约束**：论文使用 SSL / speaker conditioning 类目标促进 token 保留语言内容和 timbre / speaker 信息。
- **低 token rate**：主打 `12.5 tokens/s`，也评估 `31.25`、`62.5 tokens/s` 变体，用于比较 token 效率和重建质量。

## 4. 测试基准与性能

- 论文摘要报告：CleanCodec 在 `12.5 tokens/s` 下达到 state-of-the-art tokenization efficiency，并在 speaker similarity 和 speech intelligibility 上优于同低 token-rate codec。
- 重建评测：CleanCodec@12.5 在多个数据集上和 FocalCodec / Kanade 等 12.5 t/s codec 对比，显著改善 SIM 与 WER / CER。
- 下游 VC：VCTK voice conversion 结果中，CleanCodec@12.5 的 SIM 为 0.81，高于 Kanade 的 0.52。
- 下游 TTS：Seed-TTS-eval 口径下，CleanCodec@12.5 的 TTS 训练时间约 1:00，RTF 0.170（约 5.9x），SIM 0.56，WER 3.9；论文称相对 Qwen3-TTS-Tokenizer 最高带来 10x 训练加速和 17x 推理加速。

## 5. 使用注意

- **cleaner 不是 lossless**：CleanCodec 会主动丢弃“感知不重要”的信息；如果任务需要保留背景、房间声或取证级录音细节，它可能不合适。
- **token rate 要按任务选**：12.5 t/s 利于生成效率；31.25 / 62.5 t/s 可能更适合重建或特定说话人保持场景，需实测。
- **代码 / 权重未见官方入口**：arXiv 页面可见论文，但本轮未找到稳定官方 GitHub 或 Hugging Face 发布页。
- **深伪风险**：论文也承认更强 speech tokenization 可能降低 voice cloning / deepfake 门槛，产品化要接评估和授权流程。

## 6. 关键来源

- [CleanCodec: Efficient and Robust Speech Tokenization via Perceptually Guided Encoding](https://arxiv.org/abs/2606.04418)
  - 内容定位：原始论文，提出 perceptually guided denoising audio codec，记录 12.5 tokens/s、重建、VC、TTS 和效率评估。
  - 用途：方法定义、核心指标和开放状态依据。
  - 核验日期：2026-08-11

## 7. 相关对象

- [[方向/AI语音/知识/基础概念/NAC（神经音频 Codec）]]：CleanCodec 属于神经语音 codec / audio tokenizer。
- [[方向/AI语音/知识/技术路线/语音生成 tokenizer codec 技术路线]]：CleanCodec 是低帧率、感知引导、去噪式 codec 路线。
- [[方向/AI语音/模型/X-Codec2]]：同属 LLM-friendly speech codec，对比 50 tokens/s 单层 codec。
- [[方向/AI语音/模型/BiCodec]]：同属可接 TTS / speech LM 的 speech codec，对比解耦 speaker / semantic 信息的方式。
- [[方向/AI语音/模型/Qwen3-TTS]]：论文下游 TTS 速度对比中涉及 Qwen3-TTS tokenizer。
- [[方向/AI语音/知识/基础概念/SR（语音恢复）]]：CleanCodec 的训练目标和 speech enhancement / denoising 目标相邻。

## 8. 待验证

- 官方代码、权重、许可证和推理接口是否发布。
- 12.5 / 31.25 / 62.5 tokens/s 三档在中文、远场、带混响、带漏音语音上的真实差异。
- 与 X-Codec2、BiCodec、Qwen3-TTS tokenizer、DAC、EnCodec 在同一中文 TTS / VC 小样本上的 SIM、WER、RTF 和主观听感。
- CleanCodec 主动丢弃噪声的机制是否会影响需要保留背景音、情绪气声或环境线索的应用。

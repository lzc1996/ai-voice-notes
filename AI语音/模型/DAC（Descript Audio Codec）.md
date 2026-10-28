---
title: DAC（Descript Audio Codec）
类型: 模型
发表时间: 2023-06-11
时间依据: arXiv v1 首次提交日；NeurIPS 2023 论文
任务:
  - 音频压缩
  - 音频表示
  - 音频生成
  - 语音增强
相关主题:
  - 神经音频 Codec
  - 音频 tokenizer
  - 生成式语音增强
开放状态:
  - paper
  - code
  - demo
  - weights
aliases:
  - DAC
  - Descript Audio Codec
  - descript-audio-codec
  - High-Fidelity Audio Compression with Improved RVQGAN
  - Improved RVQGAN
tags:
  - 类型/对象
  - 方向/AI语音
  - 主题/音频tokenizer
  - 主题/语音表示
  - 主题/语音增强
---

# DAC（Descript Audio Codec）

## 0. 背景

**问题现场**：audio LM、TTS、音频生成与生成式语音增强需要一种高保真、帧率低、更可建模的音频离散表示。

**DAC 的切入点**：encoder → RVQ → decoder 的高保真通用神经音频 codec，沿用 VQ-GAN / RVQ 路线并通过 codebook 学习、对抗/重建损失与音频周期性归纳偏置改善重建，44.1 kHz 可压至 8 kbps（约 90 倍）。

## 1. 内容定位

`DAC`（Descript Audio Codec）是 Descript 提出的高保真通用神经音频 codec。它把 waveform 压成低帧率离散 codec codes / quantized latent，再由 decoder 重建 waveform，可作为 audio LM、TTS、音频生成和生成式语音增强的底层表示。

边界：这里的 DAC 不是数模转换器（digital-to-analog converter）。在本组 AI 语音笔记里，DAC 指 Descript Audio Codec；它是 [[方向/AI语音/知识/基础概念/NAC（神经音频 Codec）]] 的具体模型，不是 ASR encoder，也不是文本 tokenizer。

## 2. 核心信息

- **模型定位**：高保真、通用 neural audio codec，覆盖 speech、music、environment sound 等多域音频。
- **压缩口径**：官方 README 宣称可把 44.1 kHz audio 压到 8 kbps discrete codes，约 90x compression。
- **开源形态**：官方仓库提供训练 / 推理脚本、`.dac` 文件格式、16 kHz / 24 kHz / 44.1 kHz 权重下载入口。
- **结构口径**：encoder -> [[方向/AI语音/知识/基础概念/RVQ（残差向量量化）]] -> decoder；论文的 44.1 kHz / 8 kbps 配置使用 512x striding、约 86 Hz 帧率、9 个 10-bit codebook。
- **在语音增强里的位置**：DiTSE 等生成式增强可把 DAC / codec VAE latent 当作连续或量化潜空间，降低直接 waveform 建模成本。

## 3. 核心机制

```text
raw waveform
  -> convolutional encoder
  -> continuous latent z
  -> RVQ quantizer -> discrete codes / quantized latent
  -> convolutional decoder
  -> reconstructed waveform
```

DAC 的关键不是只把音频“压小”，而是给生成模型提供更短、更可建模的音频表示。论文题名里的 `Improved RVQGAN` 指它沿用 VQ-GAN / RVQ codec 路线，并通过 codebook 学习、对抗损失、重建损失和音频周期性归纳偏置改善高保真重建。

## 4. 使用判断

- **做 audio LM / codec LM**：DAC 可以作为 EnCodec / SoundStream 类 acoustic codec 的对照 baseline。
- **做 DiT / diffusion / flow 语音增强**：DAC latent 可作为压缩后的生成空间，但 decoder 重建质量会锁定最终音质上限。
- **做语义保持任务**：普通 acoustic codec 不保证语义最优；若上层 LLM 出现漏词 / 错词，应和 [[方向/AI语音/模型/X-Codec]]、[[方向/AI语音/模型/X-Codec2]]、[[方向/AI语音/模型/CleanCodec]] 这类 LLM-friendly tokenizer 对比。
- **做真实退化修复**：DAC 可能把噪声、混响或录音伪影也编码成合法 latent / code；用于增强时要配合内容、说话人和音色指标检查。

## 5. 容易混淆

- **数模转换器 DAC**：硬件概念，把数字信号转成模拟电压；与本页无关。
- **通信 codec**：Opus / AAC / MP3 等服务传输和存储；DAC 更常被语音生成和音频大模型当作可学习表示。
- **[[方向/AI语音/知识/基础概念/Vocoder（声码器）]]**：vocoder 常从 mel / acoustic feature 还原 waveform；DAC decoder 从 codec latent / codes 还原 waveform。
- **[[方向/AI语音/模型/Qwen-Audio-VAE]]**：连续 audio latent 路线；DAC 主要以 RVQ 离散 codec code / quantized latent 形式使用，但也可取 encoder latent 给 DiT / flow 系统用。

## 6. 相关对象

- [[方向/AI语音/知识/基础概念/NAC（神经音频 Codec）]]：DAC 所属的神经音频 codec 大类。
- [[方向/AI语音/知识/基础概念/RVQ（残差向量量化）]]：DAC 的核心量化方式。
- [[方向/AI语音/知识/基础概念/Vocoder（声码器）]]：与 codec decoder 的输出侧角色相邻。
- [[方向/AI语音/知识/技术路线/语音生成 tokenizer codec 技术路线]]：DAC 在语音生成 tokenizer / codec 选型中的位置。
- [[方向/AI语音/知识/生成式语音增强/DiT 与语音增强（DiT-based Speech Enhancement）]]：DiTSE 使用 DAC / codec VAE latent 的路线入口。
- [[方向/AI语音/模型/X-Codec]]：针对 EnCodec / DAC 这类 acoustic codec 的语义短板做增强。
- [[方向/AI语音/模型/Qwen-Audio-VAE]]：连续 latent 路线对照。

## 7. 来源

- [High-Fidelity Audio Compression with Improved RVQGAN](https://arxiv.org/abs/2306.06546)
  - 内容定位：DAC / Improved RVQGAN 原始论文，记录 44.1 kHz、8 kbps、约 90x compression、通用音频压缩和开源权重。
  - 用途：确认模型身份、发表时间、核心目标和技术路线。
  - 核验日期：2026-09-16
- [descriptinc/descript-audio-codec](https://github.com/descriptinc/descript-audio-codec)
  - 内容定位：官方 GitHub 仓库，包含训练 / 推理脚本、`.dac` 编解码命令、权重下载和模型类型。
  - 用途：确认开源状态、工程接口和 16 kHz / 24 kHz / 44.1 kHz 权重入口。
  - 核验日期：2026-09-16
- [Hugging Face Transformers - DAC](https://huggingface.co/docs/transformers/model_doc/dac)
  - 内容定位：Transformers 中的 DAC 模型文档，按 encoder、RVQ、decoder 三阶段解释结构。
  - 用途：确认生态接入口和结构口径。
  - 核验日期：2026-09-16

## 8. 待验证

- DiTSE 使用的 DAC / codec VAE latent 是否为原始 DAC checkpoint、重训版还是只复用 DAC 式结构。
- DAC 在中文语音增强、远场会议、强混响和低码率 codec 伪影上的重建误差类型。
- DAC latent / codes 与 [[方向/AI语音/评估/SpkSim]]、CER / WER、[[方向/AI语音/评估/NISQA]] 子维度之间的相关性。
- 与 EnCodec、Mimi、[[方向/AI语音/模型/X-Codec]]、[[方向/AI语音/模型/X-Codec2]]、[[方向/AI语音/模型/Qwen-Audio-VAE]] 的同基准延迟、码率和音质对比。

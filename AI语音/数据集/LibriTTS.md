---
title: LibriTTS
类型: 数据集
aliases:
  - LibriTTS corpus
  - SLR60
  - LibriTTS-R
  - SLR141
  - LibriTTS 语音数据集
tags:
  - 类型/对象
  - 方向/AI语音
  - 任务/TTS
  - 资源/数据集
---

# LibriTTS

## 1. 身份

`LibriTTS` 是 OpenSLR SLR60 托管的多说话人英文朗读语音 TTS 语料，由 LibriSpeech 的原始材料派生而来，面向 text-to-speech 研究。它和 [[方向/AI语音/数据集/LibriSpeech|LibriSpeech]] 同源，但切分、采样率和文本信息更适合 TTS。

## 2. 核心信息

- 规模：约 585 小时英文朗读语音。
- 采样率：24 kHz。
- 许可证：CC BY 4.0。
- 来源：LibriVox 公版有声书音频 + Project Gutenberg 文本，沿用 LibriSpeech 原始材料。
- 主要 split：`train-clean-100`、`train-clean-360`、`train-other-500`、`dev-clean`、`dev-other`、`test-clean`、`test-other`。
- 相比 LibriSpeech：句子级切分，包含原始文本和 normalized text，可提取邻近句上下文，并排除了明显背景噪声 utterance。

## 3. LibriTTS-R

`LibriTTS-R` 是 OpenSLR SLR141 托管的 LibriTTS 音质增强版本。它与 LibriTTS 样本集合一致，但用 [[方向/AI语音/模型/Miipher|Miipher]] speech restoration model 改善音质。

- 许可证：CC BY 4.0。
- 用途：更适合高质量 TTS 训练或作为现代 TTS 语料来源。
- 注意：LibriTTS-R 是修复版本，不是新采集语料；比较实验时要说明使用的是 SLR60 还是 SLR141。

## 4. 用途

- 训练英文多说话人 TTS、voice cloning、vocoder 和 speech tokenizer。
- 作为 TTS 论文的基础公开语料，常与 VCTK、LJSpeech、AISHELL-3、Emilia、WenetSpeech4TTS 对比。
- 作为 [[方向/AI语音/数据集/VoxBox|VoxBox]] 等大规模 TTS 语料集合的来源之一。
- 做 ASR/SE 任务时只能作为干净朗读语音来源；噪声、混响、真实对话要额外合成或换数据集。

## 5. 使用注意

- 不要把 LibriTTS 当成真实对话、会议、电话或中文 TTS 数据；它偏英文、有声书、朗读风格。
- 训练高质量 TTS 时优先确认是否使用 LibriTTS-R；很多新数据合集引用的是 `LibriTTS-R` 而不是原始 LibriTTS。
- 报告实验时写清 split 和采样率，尤其是 24 kHz 与模型内部重采样策略。
- 与 LibriSpeech 共源，不适合在 ASR/TTS 混合实验里同时当作完全独立数据来源。

## 6. 相关对象

- [[方向/AI语音/MOC - TTS|TTS]]：LibriTTS 是经典英文 TTS 训练语料。
- [[方向/AI语音/数据集/LibriSpeech|LibriSpeech]]：同源 ASR 语料，LibriTTS 从其原始材料派生。
- [[方向/AI语音/数据集/VCTK|VCTK]]：同属英文多说话人公开 TTS/voice conversion 语料生态。
- [[方向/AI语音/数据集/VoxBox|VoxBox]]：VoxBox 聚合来源中包含 LibriTTS-R。
- [[方向/AI语音/数据集/OpenSLR|OpenSLR]]：LibriTTS / LibriTTS-R 的官方托管入口。
- [[方向/AI语音/数据集/Emilia|Emilia]]：更大规模的 in-the-wild speech generation 数据集，可与 LibriTTS 的干净朗读风格对照。
- [[方向/AI语音/模型/Miipher|Miipher]]：LibriTTS-R 使用的 speech restoration 模型。

## 7. 关键资源

- [OpenSLR - LibriTTS corpus](https://www.openslr.org/60/)
  - 内容定位：官方 SLR60 数据页，记录约 585 小时、24 kHz、CC BY 4.0、split 下载和与 LibriSpeech 的差异。
  - 用途：下载、许可核对和 canonical split 命名。
  - 核验日期：2026-08-05
- [LibriTTS paper](https://arxiv.org/abs/1904.02882)
  - 内容定位：`LibriTTS: A Corpus Derived from LibriSpeech for Text-to-Speech` 论文。
  - 用途：引用数据构建方法和 TTS 研究定位。
  - 核验日期：2026-08-05
- [OpenSLR - LibriTTS-R](https://www.openslr.org/141/)
  - 内容定位：官方 SLR141 数据页，记录 LibriTTS-R 是 LibriTTS 的音质增强版本，样本一致且由 [[方向/AI语音/模型/Miipher|Miipher]] 修复。
  - 用途：下载修复版数据和区分 SLR60 / SLR141。
  - 核验日期：2026-08-05
- [LibriTTS-R paper](https://arxiv.org/abs/2305.18802)
  - 内容定位：`LibriTTS-R: A Restored Multi-Speaker Text-to-Speech Corpus` 论文。
  - 用途：引用修复流程、音质改进和实验设定。
  - 核验日期：2026-08-05

## 8. 待验证

- 本地 TTS 实验是否默认使用 LibriTTS-R，而不是原始 LibriTTS。
- 是否需要只缓存 train-clean-100 / dev-clean / test-clean，避免直接下载全部 80GB+。
- LibriTTS、VCTK、LJSpeech、AISHELL-3、Emilia、WenetSpeech4TTS 的训练采样比例是否需要统一成一张数据表。

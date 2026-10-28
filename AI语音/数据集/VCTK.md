---
title: VCTK
类型: 数据集
aliases:
  - CSTR VCTK Corpus
  - CSTR VCTK Corpus v0.92
  - Voice Clone Toolkit Corpus
tags:
  - 类型/对象
  - 方向/AI语音
  - 任务/TTS
  - 任务/ASR
  - 资源/数据集
---

# VCTK

## 1. 身份

`VCTK`（CSTR VCTK Corpus）是爱丁堡大学 CSTR 发布的英语多说话人语音数据集。v0.92 DataShare 页面记录为 110 位带有不同口音的英语说话人，每人约 400 句；录音原始规格为 96 kHz / 24-bit，公开包转换为 16-bit、48 kHz，并做了人工端点处理。

它最初面向 HMM-based / speaker-adaptive TTS，也常被后续 DNN TTS、voice cloning、voice conversion、神经波形建模和 ASR 原型实验使用。

## 2. 用途

- 多说话人英文 TTS / voice cloning 的轻量训练与复现实验语料。
- voice conversion、speaker adaptation、speaker embedding 等需要多说话人干净语音的实验。
- ASR / TTS 原型数据；Hugging Face 版本把任务标到 ASR、TTS 和 text-to-audio。
- 作为 [[方向/AI语音/数据集/VoiceBank-DEMAND|VoiceBank-DEMAND]] 等语音增强基准的同源干净语音背景线索。

## 3. 使用注意

- 数据集是英文多口音，不是多语种数据集；中文、多语种或强跨语种 TTS 不应只看它。
- Hugging Face 数据集卡记录其约 44 小时、48 kHz FLAC、无预设 split；论文复现时要核对具体 speaker split。
- DataShare v0.92 记录 `p315` 的文本转写丢失，只有 109/110 位说话人的 `/txt` 转写完整。
- 这是人声音频数据；涉及声音克隆、身份相似度或产品化使用时，需要单独确认授权、匿名化和滥用边界。

## 4. 相关对象

- [[方向/AI语音/MOC - TTS|TTS]]：VCTK 是常见英文多说话人 TTS 数据集候选。
- [[方向/AI语音/数据集/VoiceBank-DEMAND|VoiceBank-DEMAND]]：使用同源 VoiceBank/VCTK 干净语音构建语音增强基准。
- [[方向/AI语音/数据集/OpenSLR|OpenSLR]]：同属公开语音资源入口，但 OpenSLR 是资源索引，不是单一数据集。

## 5. 关键资源

- [Edinburgh DataShare - CSTR VCTK Corpus v0.92](https://datashare.ed.ac.uk/handle/10283/3443)
  - 内容定位：官方数据集页面，记录作者、版本、说话人数量、录音规格、用途、缺失转写和下载文件。
  - 用途：作为当前 canonical 数据源和引用入口。
  - 核验日期：2026-07-30
- [CSTR Downloads](https://www.cstr.ed.ac.uk/downloads/)
  - 内容定位：CSTR 公开语音资源索引，列出 VCTK corpus 作为 Voice Clone Toolkit 语料。
  - 用途：确认其归属到 CSTR corpus/data set 资源集合。
  - 核验日期：2026-07-30
- [Hugging Face - CSTR-Edinburgh/vctk](https://huggingface.co/datasets/CSTR-Edinburgh/vctk)
  - 内容定位：可用 `datasets` 加载的镜像/数据集卡，记录任务标签、字段、48 kHz 音频格式和约 44 小时规模。
  - 用途：工程实验入口；下载和许可证仍需回看 DataShare 原始包。
  - 核验日期：2026-07-30

## 6. 待验证

- 当前 TTS / voice conversion 论文最常用的 VCTK speaker split 是否已形成事实标准。
- 具体实验应该使用 DataShare 原包、96 kHz 版本，还是 Hugging Face wrapper。
- v0.92 DataShare 与 Hugging Face 数据集卡上的许可证标注是否完全一致。

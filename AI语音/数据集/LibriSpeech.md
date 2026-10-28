---
title: LibriSpeech
类型: 数据集
aliases:
  - LibriSpeech ASR corpus
  - SLR12
  - Librispeech
tags:
  - 类型/对象
  - 方向/AI语音
  - 任务/ASR
  - 资源/数据集
---

# LibriSpeech

## 1. 身份

`LibriSpeech` 是 OpenSLR SLR12 托管的英语朗读语音 ASR 语料。官方页面记录其规模约 1000 小时、16 kHz，来源于 LibriVox 公版有声书，并经过切分和文本对齐；许可证为 CC BY 4.0。

边界：它是干净/较干净的英文朗读书籍语音基准，不代表会议、电话、远场、中文方言、强噪声或真实语音 Agent 场景。

## 2. 数据构成

- `train-clean-100`：100 小时 clean 训练集。
- `train-clean-360`：360 小时 clean 训练集。
- `train-other-500`：500 小时 more challenging 训练集。
- `dev-clean` / `dev-other`：开发集，区分 clean 与 other。
- `test-clean` / `test-other`：测试集，常用于报告 ASR WER。
- 辅助包：原始 LibriVox MP3、Project Gutenberg 文本、raw metadata、MD5 校验等。

## 3. 用途

- 英文 ASR 模型训练、复现和基准评测，尤其是 `test-clean` / `test-other` WER。
- 自监督/半监督语音预训练的下游 fine-tuning 与评测基准。
- 与 SLR11 的语言模型、词表、lexicon、G2P 和 n-gram LM 资源配套使用。
- 作为 [[方向/AI语音/模型/Whisper|Whisper]]、HuBERT、wav2vec 2.0、Emformer、Conformer 等 ASR 论文/模型的常见评测背景。

## 4. 使用注意

- 不要把 LibriSpeech 高分直接外推到真实会议或语音 Agent；它偏英文、朗读、有声书、相对规整。
- `clean` 与 `other` 难度不同，报告结果时要注明 split，不能只报 `test-clean`。
- 需要传统 LM / lexicon / G2P 时，优先看 OpenSLR SLR11，而不是从 SLR12 音频包里临时拼。
- 下载包较大，OpenSLR 页面建议使用靠近自己的镜像；本地缓存时保留 MD5 校验。

## 5. 相关对象

- [[方向/AI语音/MOC - ASR|ASR]]：LibriSpeech 是英文 ASR 常用基准数据集。
- [[方向/AI语音/数据集/OpenSLR|OpenSLR]]：LibriSpeech 的官方托管入口是 OpenSLR SLR12。
- [[工具/Kaldi|Kaldi]]：LibriSpeech 与 Kaldi recipe / acoustic model 资源长期一起出现。
- [[方向/AI语音/模型/HuBERT|HuBERT]]：HuBERT 等自监督语音模型常在 LibriSpeech / Libri-Light 设置上评估。
- [[方向/AI语音/模型/Emformer|Emformer]]：TorchAudio 的在线 ASR 示例使用 `EMFORMER_RNNT_BASE_LIBRISPEECH`。

## 6. 关键资源

- [OpenSLR - LibriSpeech ASR corpus](https://www.openslr.org/12/)
  - 内容定位：官方 SLR12 数据页面，记录 1000 小时、16 kHz、LibriVox 来源、split 下载、CC BY 4.0 和校验文件。
  - 用途：作为数据下载、许可证和 split 命名的 canonical 入口。
  - 核验日期：2026-08-03
- [LibriSpeech paper - ICASSP 2015](https://www.danielpovey.com/files/2015_icassp_librispeech.pdf)
  - 内容定位：`LibriSpeech: an ASR corpus based on public domain audio books` 论文。
  - 用途：引用语料构建方法、切分/对齐流程和基准设定。
  - 核验日期：2026-08-03
- [OpenSLR - LibriSpeech language models, vocabulary and G2P models](https://www.openslr.org/11/)
  - 内容定位：SLR11 语言模型、词表、发音词典、G2P 和 3-gram / 4-gram ARPA LM 资源。
  - 用途：需要传统 ASR LM / lexicon / rescoring 资源时配套使用。
  - 核验日期：2026-08-03

## 7. 待验证

- 当前本地 ASR 实验应优先下载 full 960h、100h subset，还是只保留 dev/test 做模型横评。
- 和 Libri-Light、Multilingual LibriSpeech、LibriTTS、LibriCSS 的边界是否需要拆成独立笔记。
- 本地复现实验是否要建立统一结果表：模型、训练数据、是否外部 LM、`test-clean`、`test-other`、实时因子。

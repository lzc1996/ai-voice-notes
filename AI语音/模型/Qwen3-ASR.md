---
title: Qwen3-ASR
类型: 模型
参数量: 1.7B；0.6B
发表时间: 2026-01-29
时间依据: arXiv 首次提交日
任务:
  - ASR
相关模型:
  - "[[方向/AI语音/模型/Qwen3-ForcedAligner]]"
开放状态:
  - paper
  - code
  - weights
  - api
aliases:
  - qwen-asr
  - Qwen ASR
  - Qwen3-ASR-Flash
tags:
  - 类型/对象
  - 领域/AI语音
  - 任务/ASR
---

# Qwen3-ASR

## 0. 背景

**问题现场**：需要覆盖多语言/方言、本地与云端多形态部署的开源 ASR 服务线，兼顾准确率与吞吐/成本。

**Qwen3-ASR 的切入点**：LLM-based ASR——音频编码后与文本 token 一起做 next-token 预测，开源 1.7B/0.6B 权重，云端另设 realtime 与 filetrans 两个 Flash 模型。

## 1. 内容定位

Qwen3-ASR 是 Qwen 团队的自动语音识别模型/服务线。本笔记用于索引开源权重、云端 API、技术报告和选型边界。

## 2. 核心信息

- 开源模型：`Qwen3-ASR-1.7B`、`Qwen3-ASR-0.6B`，支持语言识别和 52 种语言/方言 ASR。
- 对齐模型：[[方向/AI语音/模型/Qwen3-ForcedAligner|Qwen3-ForcedAligner-0.6B]]，用于文本-语音强制对齐和时间戳预测。
- 推理形态：官方工具链覆盖本地 Python 包、vLLM、Docker、Gradio、离线/流式统一推理。
- 云端模型：`qwen3-asr-flash-realtime` 用于实时 WebSocket；`qwen3-asr-flash-filetrans` 用于异步文件转写。
- 选型边界：Qwen3-ASR-Flash 有情绪识别；说话人分离应优先看 `fun-asr` 批处理模型。

## 3. 核心公式

Qwen3-ASR 是 LLM-based ASR：音频经编码器与投影器变成 LLM 可读的 token 序列，与文本 token 一起做 next-token 预测。以下为该类模型的标准数学形式。

- 语音编码：

$$\mathbf{Z} = \mathrm{Proj}\big(\mathrm{Encoder}(X)\big) \in \mathbb{R}^{T \times d}$$

说明：$X$ 为声学特征（log-Mel 或波形卷积前端输出），$\mathrm{Encoder}$ 输出帧级表示，$\mathrm{Proj}$ 将其映射/压缩为 LLM 输入空间中的音频 token 序列 $\mathbf{Z}$（$T$ 为帧/token 数，$d$ 为隐维度）。

- 自回归解码：

$$P(y_t \mid y_{<t}, \mathbf{Z}) = \mathrm{softmax}\left(W \mathbf{h}_t\right), \quad \mathbf{h}_t = \mathrm{LLM}\big([\mathbf{Z};\ \mathbf{E}(y_{<t})]\big)$$

说明：音频 token 与文本 token 拼接后送入 decoder-only LLM，$\mathbf{h}_t$ 为第 $t$ 步隐状态，$W$ 为词表投影，$\mathbf{E}$ 为文本嵌入；$y_{<t}$ 为已识别文本。

- 训练目标（next-token 交叉熵）：

$$\mathcal{L} = -\sum_{t=1}^{T_y} \log P(y_t \mid y_{<t}, \mathbf{Z})$$

说明：与 LLM 预训练一致的序列交叉熵；语言识别、52 种语言/方言等能力通过把任务要求编进指令/输出 token 实现。

## 4. 测试基准与性能

**测试基准**（均为 README 官方评测表口径，WER%↓）

- 英文：LibriSpeech test-clean/other、GigaSpeech、Common Voice en、Fleurs en、MLS en、Tedlium、VoxPopuli。
- 中文：WenetSpeech（net/meeting）、AISHELL-2、SpeechIO、Fleurs zh、Common Voice zh、KeSpeech。
- 方言：Fleurs yue、Common Voice yue / zh-tw、WenetSpeech-Yue（short/long）、WenetSpeech-Chuan（easy/hard）。
- 内部集：Dialog-Accented English（16 口音）、Elders&Kids、ExtremeNoise、TongueTwister、Dialog-Mandarin / Cantonese / Chinese Dialects（22 方言）。
- 多语言：MLS、CommonVoice、MLC-SLM、Fleurs（另含 +8 / +10 语言扩展）、News-Multilingual（15 语言）。
- 附加评测：唱歌转写（M4Singer、MIR-1k、Opencpop、Popcs、EntireSongs）、语言识别准确率、强制对齐（AAS，ms↓）。

**性能指标**（WER%，来源：README 官方评测表）

| 基准 | Qwen3-ASR-1.7B | Qwen3-ASR-0.6B |
| --- | --- | --- |
| LibriSpeech test-clean / other | 1.63 / 3.38 | 2.11 / 4.55 |
| WenetSpeech net / meeting | 4.97 / 5.88 | 5.97 / 6.88 |
| AISHELL-2 test | 2.71 | 3.15 |
| Fleurs en / zh | 3.35 / 2.41 | 4.39 / 2.88 |
| GigaSpeech | 8.45 | 8.88 |
| Common Voice en / zh | 7.39 / 5.35 | 9.92 / 6.89 |
| KeSpeech | 5.10 | 7.08 |
| WenetSpeech-Yue short / long | 5.82 / 8.85 | 7.54 / 9.92 |
| 内部集：ExtremeNoise / Elders&Kids | 16.17 / 3.81 | 17.88 / 4.48 |

- 流式 vs 离线：1.7B 在 LibriSpeech 上 1.63/3.38（离线）→ 1.95/4.51（流式）（README）。
- 语言识别平均准确率：1.7B 97.9%、0.6B 96.8%（MLS / CV / MLC-SLM / Fleurs 平均，README）。
- 强制对齐 AAS 均值：[[方向/AI语音/模型/Qwen3-ForcedAligner|Qwen3-ForcedAligner-0.6B]] 42.9 ms，优于 Monotonic-Aligner 161.1 / NFA 129.8 / WhisperX 133.2 ms（README）。
- 吞吐与延迟：0.6B 平均 TTFT 低至 92 ms，128 并发下每秒转写 2000 秒语音（arXiv 摘要）。
- 定性：1.7B 为开源 ASR 中 SOTA、与最强闭源 API 竞争（arXiv 摘要）。

## 5. 发展脉络

Qwen3-ASR 是 Qwen 语音线从 `Qwen-Audio` 的通用音频理解，到 `Qwen2-Audio` 的语音交互，再到 `Qwen3-Omni` 全模态 foundation model 后拆出的专用 ASR 分支。完整时间线见 [[方向/AI语音/选型/Qwen 语音模型发展脉络|Qwen 语音模型发展脉络]]。

技术分工和后续深挖问题见 [[方向/AI语音/选型/Qwen 语音模型技术路线图|Qwen 语音模型技术路线图]]。

与 [[方向/AI语音/模型/Whisper|Whisper]]、[[方向/AI语音/模型/FunASR|FunASR]]、GPT-4o Transcribe、[[方向/AI语音/模型/Seed-ASR|Seed-ASR]] 的工程对比见 [[方向/AI语音/选型/ASR 模型选型矩阵|ASR 模型选型矩阵]]。

与 Omni 和专用 TTS/ASR 组件的架构边界见 [[方向/AI语音/选型/Omni vs ASR TTS 专用模型选型|Omni vs ASR TTS 专用模型选型]]。

## 6. 选型

- 本地准确率优先：`Qwen3-ASR-1.7B`。
- 本地吞吐/成本优先：`Qwen3-ASR-0.6B`。
- 实时字幕/语音助手：`qwen3-asr-flash-realtime`。
- 录音文件批处理：`qwen3-asr-flash-filetrans`。
- 热词、说话人分离、稳定术语表：先评估 Fun-ASR 或 Qwen-Omni 的上下文方案。

## 7. 相关对象

- [[方向/AI语音/选型/ASR 模型选型矩阵|ASR 模型选型矩阵]]：Qwen3-ASR 与其他 ASR 路线的工程选型对比。
- [[方向/AI语音/选型/Omni vs ASR TTS 专用模型选型|Omni vs ASR TTS 专用模型选型]]：全模态模型与专用 ASR/TTS 组件的架构边界。
- [[方向/AI语音/选型/Qwen 语音模型技术路线图|Qwen 语音模型技术路线图]]：Qwen 语音模型的技术分工、选型边界和深挖入口。
- [[方向/AI语音/选型/Qwen 语音模型发展脉络|Qwen 语音模型发展脉络]]：Qwen-ASR / Qwen-TTS 的共同上游和分支时间线。
- [[方向/AI语音/模型/Qwen3-TTS|Qwen3-TTS]]：同属 Qwen 语音模型线，常和 ASR 组成语音交互链路。
- [[方向/大模型/LLM/模型/Qwen3|Qwen3]]：Qwen 模型家族入口。
- [[知识wiki/商业/DashScope 阿里云MaaS平台|DashScope 阿里云 MaaS 平台]]：QwenCloud / DashScope API 的平台上下文。

## 8. 来源

- [Qwen3-ASR README](https://github.com/QwenLM/Qwen3-ASR/blob/main/README.md)
  - 内容定位：官方开源仓库，记录模型家族、安装、推理、部署、评测和 Citation。
  - 用途：本地部署、模型列表、能力边界和官方评测入口。
  - 核验日期：2026-07-23
- [Qwen/Qwen3-ASR-1.7B-hf](https://huggingface.co/Qwen/Qwen3-ASR-1.7B-hf)
  - 内容定位：Hugging Face 模型卡，记录 Transformers 原生调用、模型卡参数、评测和用法示例。
  - 用途：Transformers 推理、模型下载和实验复现。
  - 核验日期：2026-07-23
- [Qwen3-ASR Technical Report](https://arxiv.org/abs/2601.21337)
  - 内容定位：技术报告，记录训练/架构、52 语言/方言 ASR、强制对齐模型和系统评测。
  - 用途：引用模型能力和评测结论时的论文依据。
  - 核验日期：2026-07-23
- [Speech-to-text models - QwenCloud](https://docs.qwencloud.com/developer-guides/speech/speech-to-text-models)
  - 内容定位：QwenCloud 模型选择页，比较 Qwen3-ASR、Fun-ASR、Qwen-Omni 的实时/批处理、情绪识别、说话人分离和语言覆盖。
  - 用途：云 API 选型和能力边界判断。
  - 核验日期：2026-07-23
- [Audio file transcription - QwenCloud](https://docs.qwencloud.com/developer-guides/speech/asr)
  - 内容定位：音频文件转写 API 文档，包含 `qwen3-asr-flash-filetrans` 的异步调用示例和限制。
  - 用途：文件转写实现入口。
  - 核验日期：2026-07-23

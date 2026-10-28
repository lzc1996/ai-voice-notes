---
title: GPT-4o Transcribe
类型: 模型
发表时间: 2025-03-20
时间依据: OpenAI 官方发布日
任务:
  - ASR
开放状态:
  - api
aliases:
  - gpt-4o-transcribe
  - GPT-4o Transcribe 系列
  - GPT-4o speech-to-text
tags:
  - 类型/对象
  - 方向/AI语音
  - 任务/ASR
---

# GPT-4o Transcribe

## 0. 背景

**问题现场**：云端 speech-to-text 需要在多语言、口音、噪声等场景下提供比既有 API 更高的转写准确率，并支持流式输出。

**前序路线的缺口**：`whisper-1` API 在词错误率、语言识别和准确率上不及新一代模型，且不支持文件转写流式路径。

**GPT-4o Transcribe 的切入点**：OpenAI 新一代云端 STT API，支持流式转写事件、prompt 词汇偏置和 token logprobs 置信度输出。

## 1. 身份

GPT-4o Transcribe 是 OpenAI 的云端 speech-to-text 模型，模型 ID 为 `gpt-4o-transcribe`，用于把音频转写成文本。它的定位是比原始 Whisper API 提供更好的词错误率、语言识别和准确率。

边界：它不是本地/开源 ASR，也不是完整会议系统。说话人标注需要使用独立的 `gpt-4o-transcribe-diarize`；新建通用转写链路时，还要同时评估 OpenAI 文档当前推荐的 `gpt-transcribe`。

## 2. 用途

- 云端高质量文件转写，尤其是希望比 `whisper-1` 获得更高准确率的场景。
- 已有 OpenAI 音频管线中替换或对比 [[方向/AI语音/模型/Whisper|Whisper]] / `whisper-1`。
- 语音 Agent 或字幕流水线的快速产品验证，前提是能接受闭源 API、网络依赖和云端合规约束。

## 3. 核心信息

- API：主要通过 `/v1/audio/transcriptions` 使用；模型页也列出 Realtime transcription 会话入口。
- 输出：`gpt-4o-transcribe` / `gpt-4o-mini-transcribe` 的转写响应格式仅支持 `json`；需要说话人片段时使用 `gpt-4o-transcribe-diarize` + `diarized_json`。
- 流式：文件转写可设置 `stream=true` 返回 `transcript.text.delta` 和最终 `transcript.text.done` 事件；`whisper-1` 不支持该文件转写流式路径。
- 提示：`gpt-4o-transcribe` 支持用 prompt 改善名称、缩写、格式或录音上下文词汇；diarize 变体不支持 prompt。
- 置信度：`include[]=logprobs` 可在 `json` 输出中返回 token log probabilities，用于粗略定位低置信片段。
- 价格口径：模型页按 audio tokens 计费，当前页面显示 input $2.50 / 1M tokens、output $10.00 / 1M tokens；实际落地前看实时价格页。

## 4. 核心公式

`gpt-4o-transcribe` 为闭源云端 API，无公开论文与权重，以下按通用 ASR 的标准目标形式给出（具体实现未公开，见待验证）。

- 声学编码（通用形式）：

$$\mathbf{H} = f_\theta(X)$$

说明：$X$ 为声学特征（如 log-Mel spectrogram），$f_\theta$ 为音频编码器，$\mathbf{H}$ 为帧级表示；具体架构未公开，见待验证。

- 文本序列概率与训练目标（标准 ASR 序列形式）：

$$P(Y \mid X) = \prod_{t} P(y_t \mid y_{<t}, X), \qquad \mathcal{L} = -\log P(Y \mid X)$$

说明：$Y$ 为参考转写文本，$y_{<t}$ 为已生成前缀；无论采用 CTC、attention 还是 LLM 式解码，对参考文本的负对数似然都是该任务的标准目标形式。`gpt-4o-transcribe` 具体用哪种目标、prompt 条件化与 logprob 输出如何实现，均为 API 产品行为，未经官方技术披露。

## 5. 测试基准与性能

**测试基准**

- FLEURS（100+ 语言多语言基准；官方博客称优于 Whisper v2 / v3）。
- OpenAI 内部评测：口音、噪声环境、语速变化等挑战场景（官方博客；具体基准名未公开）。
- 第三方参考：Artificial Analysis、MikuTools 等汇总榜（非官方口径）。

**性能指标**

- 官方口径：相对原 Whisper 模型 WER 改进、语言识别更准确（官方博客；具体数字未在公开页给出，待核）。
- 官方口径：gpt-4o-transcribe / gpt-4o-mini-transcribe 在 FLEURS 上均优于 Whisper v2 / v3（官方博客）。
- 第三方参考：英语最优条件 WER ≈ 2.46%（第三方汇总，待核）；普通话约 7%、印度语 / 达罗毗荼语系接近 30%（内部基准报道，待核）。

## 6. 什么时候选 GPT-4o Transcribe

- 需要云端 ASR，且比本地可控性更看重接入速度和准确率。
- 需要对 `whisper-1` 做 OpenAI 内部升级对比，但还不想改成新的 `gpt-transcribe` 路线。
- 需要文件转写流式输出，而不是等待整段录音一次性完成。

## 7. 不适合直接承担的任务

- **私有化部署**：它是闭源云端 API，不适合强本地化或离线合规场景。
- **会议系统**：普通 `gpt-4o-transcribe` 不负责 VAD、段落合并、摘要和会议后处理；说话人标注要用 diarize 变体，并且 Realtime transcription sessions 不支持 speaker labeling。
- **SRT/VTT/词级时间戳优先链路**：当前 API 参考把普通 `gpt-4o-transcribe` 限定为 `json`，不要默认它能直接输出字幕格式。

## 8. 关键资源

- [GPT-4o Transcribe model page](https://developers.openai.com/api/docs/models/gpt-4o-transcribe)
  - 内容定位：模型身份、端点、上下文窗口、输出上限、价格口径和 rate limit。
  - 用途：确认 `gpt-4o-transcribe` 的当前模型入口。
  - 核验日期：2026-07-29
- [Speech to text - OpenAI Docs](https://platform.openai.com/docs/guides/speech-to-text)
  - 内容定位：文件转写、prompt、streaming、diarization 和 translation 边界。
  - 用途：确认 GPT-4o Transcribe 系列在实际转写链路里的使用方式。
  - 核验日期：2026-07-29
- [Audio API Reference - Create transcription](https://platform.openai.com/docs/api-reference/audio/createTranscription)
  - 内容定位：`/v1/audio/transcriptions` 参数、模型枚举、`response_format`、`include=logprobs`、stream 和 diarize 返回对象。
  - 用途：确认可用参数和输出约束。
  - 核验日期：2026-07-29

## 9. 相关对象

- [[方向/AI语音/MOC - ASR|ASR]]：GPT-4o Transcribe 属于云端 ASR / speech-to-text 路线。
- [[方向/AI语音/选型/ASR 模型选型矩阵|ASR 模型选型矩阵]]：与 Qwen3-ASR、FunASR、Whisper、Seed-ASR 做工程选型对比。
- [[方向/AI语音/模型/Whisper|Whisper]]：OpenAI ASR 通用基线和 `whisper-1` API 参照。
- [[方向/AI语音/模型/FunASR|FunASR]]：会议转写工程链路参照。

## 10. 待验证

- `gpt-transcribe`、`gpt-4o-transcribe`、`gpt-4o-mini-transcribe`、`whisper-1` 在中文、方言、噪声、长音频上的实际差距。
- `gpt-4o-transcribe-diarize` 在真实会议录音里的说话人切换、已知 speaker reference 和长音频稳定性。
- 如果下游要字幕格式，是否先用 JSON 转写后自行生成 SRT/VTT，还是改用支持字幕格式的模型链路。
- `gpt-4o-transcribe` / `gpt-4o-mini-transcribe` 的具体架构、训练目标与损失函数未公开；「核心公式」中的形式为通用 ASR 标准目标，未经官方确认。
- 官方博客的 WER 具体数值（各语言改进百分比、FLEURS 逐语言数字）未抓到原文（openai.com 对抓取返回 403），待核；当前仅有官方定性口径与第三方参考数字。


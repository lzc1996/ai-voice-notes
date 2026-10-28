---
title: Seed-ASR
类型: 模型
发表时间: 2024-07-05
时间依据: arXiv 首次提交日
任务:
  - ASR
开放状态:
  - paper
  - demo
  - api
aliases:
  - Seed ASR
  - ByteDance Seed-ASR
  - LLM-based ASR
  - Understanding Diverse Speech and Contexts with LLM-based Speech Recognition
tags:
  - 类型/对象
  - 方向/AI语音
  - 任务/ASR
---

# Seed-ASR

## 0. 背景

**问题现场**：传统端到端 ASR 在领域术语、人名、方言、口音和复杂语境下的识别稳定性不足。

**Seed-ASR 的切入点**：把 ASR 放进 audio-conditioned LLM 框架，语音表示、任务指令与上下文共同前缀化，靠大语言模型的上下文理解能力配合分阶段大规模训练改进识别。

## 1. 身份

Seed-ASR 是 ByteDance Seed 团队提出的 LLM-based speech recognition 模型，论文全名是 *Seed-ASR: Understanding Diverse Speech and Contexts with LLM-based Speech Recognition*。它把 ASR 放进 audio-conditioned LLM 框架里，强调利用大语言模型的上下文理解能力处理领域术语、人名、方言、口音和复杂语境。

边界：Seed-ASR 当前更适合作为论文前沿和产品能力线索跟踪；工程落地前需要先确认公开权重、API、许可证、延迟和输出格式。不要默认把它当作可直接私有化部署的组件。

## 2. 核心思路

- 用 speech encoder 把语音转成连续 speech representations。
- 把 speech representations、task instruction 和相关上下文一起送入预训练 LLM。
- 通过分阶段大规模训练和 context-aware 能力激发，让模型在多领域、多口音/方言、多语言场景下改进识别。
- 相比传统端到端 ASR，重点不只是 WER/CER，而是上下文词、专有名词、历史信息和语义约束下的识别稳定性。

## 3. 核心公式

Seed-ASR 的核心是 audio-conditioned LLM：连续 speech representations 与 task instruction、相关上下文文本一起作为 LLM 前缀。以下为该框架的标准数学形式。

- 语音连续表示：

$$\mathbf{S} = \mathrm{Downsample}\big(\mathrm{SpeechEncoder}(\mathbf{x})\big)$$

说明：$\mathbf{x}$ 为输入波形，$\mathrm{SpeechEncoder}$ 得到帧级连续表示，$\mathrm{Downsample}$ 降低帧率以匹配 LLM 的 token 节奏。

- 上下文拼接（instruction / context 与语音表示共同前缀化）：

$$\mathbf{P} = [\mathbf{S};\ \mathbf{E}(c_{\mathrm{inst}});\ \mathbf{E}(c_{\mathrm{ctx}})], \quad \mathbf{h}_t = \mathrm{LLM}(\mathbf{P}, y_{<t})$$

说明：$c_{\mathrm{inst}}$ 为任务指令（如转写/翻译），$c_{\mathrm{ctx}}$ 为相关上下文（历史字幕、人名、术语），$\mathbf{E}$ 为文本嵌入；拼接后的 $\mathbf{P}$ 作为前缀参与整段 attention。

- 解码与训练目标：

$$P(y_t \mid y_{<t}, \mathbf{P}) = \mathrm{softmax}(W \mathbf{h}_t), \qquad \mathcal{L} = -\sum_{t=1}^{T_y} \log P(y_t \mid y_{<t}, \mathbf{P})$$

说明：标准 next-token 交叉熵；上下文参与 attention 使模型能利用领域词、专有名词和历史信息修正转写，这是相对传统端到端 ASR 的核心差异。

## 4. 测试基准与性能

**测试基准**

- 中文 / 英文公开测试集（论文口径；具体基准名单待核）。
- 多领域、多口音 / 方言、多语言综合评测集（论文摘要）。
- demo 页覆盖：吴语、粤语、四川话等方言，多口音，噪声音频，以及上下文场景（对话历史、人名、术语）。

**性能指标**

- 相对传统端到端模型：中文、英文公开测试集上 WER（中文为 CER）降低 10%–40%（arXiv 摘要）。
- 绝对 WER/CER 数值：待核（论文正文评测表未抓取）。

## 5. 什么时候关注 Seed-ASR

- 研究 LLM-ASR：语音编码器如何接入 LLM，以及上下文如何帮助转写。
- 领域词/人名/术语识别：需要模型利用外部上下文或历史字幕信息。
- 方言/口音/多语言 ASR：关注复杂真实语音条件下的泛化。
- 做 ASR 技术调研：和 [[方向/AI语音/模型/Qwen3-ASR|Qwen3-ASR]]、[[方向/AI语音/模型/FunASR|FunASR]]、[[方向/AI语音/模型/Whisper|Whisper]]、GPT-4o Transcribe 对比上限。

## 6. 不适合直接承担的任务

- 需要稳定开源本地部署：先选 [[方向/AI语音/模型/FunASR|FunASR]]、[[方向/AI语音/模型/Whisper|Whisper]] 或 [[方向/AI语音/模型/Qwen3-ASR|Qwen3-ASR]]。
- 需要完整会议系统：仍要 VAD、diarization、标点、段落、热词和后处理链路。
- 需要强制对齐/字幕校准：优先看专用 forced aligner。

## 7. 关键资源

- [Seed-ASR demo](https://bytedancespeech.github.io/seedasr_tech_report/)
  - 内容定位：ByteDance Speech demo 页，展示 Seed-ASR 的 LLM-based ASR、上下文推理、人名/术语、方言等能力样例。
  - 用途：快速理解模型能力主张和 demo 场景。
  - 核验日期：2026-07-29
- [Seed-ASR Technical Report](https://arxiv.org/abs/2407.04675)
  - 内容定位：技术报告，记录 audio-conditioned LLM 框架、分阶段训练和多领域/方言/语言评测。
  - 用途：方法和评测主来源。
  - 核验日期：2026-07-29
- [ByteDance Seed blog - Seed-ASR](https://seed.bytedance.com/blog/doubao-s-listening-skills-unboxing-live-see-how-seed-asr-overcomes-the-speech-recognition-bottleneck)
  - 内容定位：ByteDance Seed 团队博客，介绍 Seed-ASR 在豆包等产品中的语音识别能力和上下文识别样例。
  - 用途：产品化线索和能力展示入口。
  - 核验日期：2026-07-29

## 8. 相关对象

- [[方向/AI语音/MOC - ASR|ASR]]：Seed-ASR 属于 LLM-based ASR 前沿路线。
- [[方向/AI语音/选型/ASR 模型选型矩阵|ASR 模型选型矩阵]]：Seed-ASR 当前适合作为论文前沿对标，不默认视为工程可用组件。
- [[方向/AI语音/模型/Qwen3-ASR|Qwen3-ASR]]：同属新一代 ASR，对比本地开源/云端产品化边界。
- [[方向/AI语音/模型/FunASR|FunASR]]：会议转写和企业 ASR 工程链路对照。
- [[方向/AI语音/模型/Whisper|Whisper]]：离线开源通用 baseline。
- [[方向/AI语音/评估/CER（Character Error Rate）|CER]]：中文 ASR 对比时常用字符级错误率。

## 9. 待验证

- 2026-07-29 快速复核：公开入口仍主要是 demo、arXiv 技术报告和 ByteDance Seed 博客；暂不把它归入可直接部署/可调 API 路线。
- 是否存在公开可用权重、API 或只作为 ByteDance 内部/产品能力。
- Seed-ASR 的上下文输入格式、最大上下文长度和热词/术语约束强度。
- 中文方言、会议多人、嘈杂远场、长音频上的真实 CER/WER 和延迟。
- 与 Qwen3-ASR、FunASR、Whisper、GPT-4o Transcribe 在同一小样本集上的工程成本差异。
- Seed-ASR 在 LibriSpeech、Common Voice、Earnings-22 等具体基准上的绝对 WER/CER 数值待核（当前仅有「降低 10%–40%」的相对口径）。



---
title: ASR 模型选型矩阵
类型: 概念
发表时间:
时间依据: 综合选型矩阵；非单一发表物
aliases:
  - ASR selection matrix
  - 语音识别模型选型
tags:
  - 类型/对象
  - 领域/AI语音
  - 任务/ASR
---

# ASR 模型选型矩阵

## 1. 内容定位

这篇用于做工程选型，不做排行榜复述。核心问题是：给定语音 Agent、视频理解、会议转写、字幕生成、长音频批处理等场景，应该选 Qwen3-ASR、FunASR、Whisper、[[方向/AI语音/模型/GPT-4o Transcribe|GPT-4o Transcribe]]、Seed-ASR，还是 Qwen-Omni 路线。

## 2. 快速结论

- **本地可控 + 中文/方言 + 强制对齐**：优先 `Qwen3-ASR` / `Qwen3-ForcedAligner`。
- **会议系统 + 说话人分离 + VAD/标点/热词工程链路**：优先 [[方向/AI语音/模型/FunASR|FunASR]] 或云端 `fun-asr`。
- **离线通用基线 + 多语言转写/翻译**：优先 [[方向/AI语音/模型/Whisper|Whisper]]，再按领域数据二次处理。
- **云端高质量转写 + 流式 + 可接受闭源依赖**：优先 [[方向/AI语音/模型/GPT-4o Transcribe|GPT-4o Transcribe]] 系列。
- **带上下文术语解释或多模态理解**：优先 `Qwen-Omni` prompt-context transcription，而不是裸 ASR。
- **论文前沿对标**：看 [[方向/AI语音/模型/Seed-ASR|Seed-ASR]]，但先确认可用权重/API，不把它当默认工程组件。

## 3. 选型矩阵

| 模型/路线 | 部署形态 | 强项 | 弱项 | 首选场景 |
|---|---|---|---|---|
| `Qwen3-ASR` 开源 | 本地/私有化 | 52 种语言/方言、中文方言、离线/流式统一、长音频、歌曲/复杂声学、ForcedAligner | 不自带完整会议系统；说话人分离不是主能力 | 本地语音 Agent、字幕、视频 ASR、强制对齐 |
| QwenCloud `qwen3-asr-flash-*` | 云端实时/文件 | 实时 WebSocket、文件异步转写、情绪识别、QwenCloud 接入简单 | 语言覆盖和功能边界以云端文档为准；不适合说话人分离 | 快速接入云端 ASR、实时字幕、录音文件转写 |
| [[方向/AI语音/模型/FunASR]] / 云端 `fun-asr` | 本地工具链/云端批处理 | VAD、标点、时间戳、热词、说话人分离等工程配套强 | 更像 ASR 工程套件；多模态上下文能力弱 | 会议转写、电话质检、企业语音批处理 |
| [[方向/AI语音/模型/Whisper]] | 本地/开源/API | 稳定通用基线；多语言识别、语音翻译、语言识别；生态成熟 | 原生无说话人分离；热词/术语控制弱；工程增强常依赖外部项目 | 离线通用转写、低成本基线、研究复现 |
| [[方向/AI语音/模型/GPT-4o Transcribe]] 系列 | 云端 API | 闭源云端高质量转写、流式、可结合 OpenAI 语音/Agent 栈；部分模型支持 diarization 输出 | 不能私有化；成本、合规和网络依赖明显 | 快速产品验证、英文/多语言云端转写、Agent 语音入口 |
| [[方向/AI语音/模型/Seed-ASR]] | 论文/闭源或半开放生态 | LLM-based ASR；上下文、人名、术语、方言/口音识别方向值得参考 | 工程可用性取决于权重/API；不应默认列为可落地组件 | 技术调研、论文对比、指标上限参考 |
| `Qwen-Omni` prompt-context transcription | 云端/全模态模型 | 可用 prompt 提供术语和上下文；适合把转写和理解合在一起 | 不是纯 ASR 组件；延迟、成本、时间戳和说话人分离不如专用链路 | 视频理解、领域术语转写、语音问答、跨模态 Agent |

## 4. 按场景选择

### 4.1. 视频理解 / 视侦 Agent

推荐：`Qwen3-ASR` 或 [[方向/AI语音/模型/Whisper|Whisper]] 先生成字幕，再交给 VLM/LLM；如果问题依赖画面、音频、上下文一起推理，再用 `Qwen-Omni`。

不要把 Omni 当成所有视频 ASR 的默认入口。批量视频索引需要可缓存、可复查、可对齐的文本产物，专用 ASR 更省。

### 4.2. 会议转写

推荐：[[方向/AI语音/模型/FunASR|FunASR]] / 云端 `fun-asr` 优先，因为会议转写不是只有 WER，还要 VAD、说话人分离、标点、时间戳、段落合并和术语修正。

`Qwen3-ASR` 可以做高质量转写或强制对齐，但需要外接说话人分离和会议后处理。

### 4.3. 实时语音 Agent

推荐：云端快速验证用 `qwen3-asr-flash-realtime` 或 [[方向/AI语音/模型/GPT-4o Transcribe|GPT-4o Transcribe]]；本地/私有化用 `Qwen3-ASR-0.6B` 或轻量 [[方向/AI语音/模型/FunASR|FunASR]] 方案。

关键评估项不是离线 WER，而是端到端延迟、首包、断句、增量稳定性、打断恢复和噪声场景。

### 4.4. 中文方言 / 多语言

推荐：优先评估 `Qwen3-ASR` 和 [[方向/AI语音/模型/FunASR|FunASR]]。`Qwen3-ASR` 明确覆盖中文方言；FunASR 在中文工程生态和企业语音链路中更成熟。

如果是多语言泛化基线，[[方向/AI语音/模型/Whisper|Whisper]] 仍然是必须跑的参照。

### 4.5. 强制对齐 / 字幕校准

推荐：[[方向/AI语音/模型/Qwen3-ForcedAligner|Qwen3-ForcedAligner]]。它是 Qwen3-ASR 同线发布的专用对齐模型，比把普通 ASR 时间戳硬当 aligner 更稳。

字幕生产一般需要：ASR 初稿 → 文本规范化 → forced alignment → 分句/断行 → 人工抽检。

### 4.6. 术语/热词强约束

推荐：[[方向/AI语音/模型/FunASR|FunASR]] 热词链路或 Qwen-Omni prompt-context transcription。`Qwen3-ASR` 可通过 prompt/context 做一定上下文引导，但稳定术语表仍要实测。

[[方向/AI语音/模型/Whisper|Whisper]] 的 prompt 更像提示，不要把它当严格热词系统。

## 5. 评估清单

- **准确率**：WER、[[方向/AI语音/评估/CER（Character Error Rate）|CER]]、实体词错误率、数字/英文夹杂错误率。
- **实时性**：首包、稳定 partial 输出、最终输出延迟、断句延迟。
- **鲁棒性**：噪声、混响、远场、多人说话、音乐/背景声。
- **中文能力**：普通话、方言、口音、代码切换、中文数字。
- **工程输出**：时间戳、词级时间戳、说话人、VAD、标点、置信度。
- **控制能力**：热词、上下文 prompt、术语表、领域词修正。
- **部署成本**：GPU/CPU、吞吐、批处理、云端计费、隐私合规。

## 6. 最小验证集

不要先跑大 benchmark。先拿 30 条真实音频：

- 5 条干净普通话短句。
- 5 条中文方言/口音。
- 5 条会议多人对话。
- 5 条带背景噪声/音乐。
- 5 条专业术语/英文夹杂。
- 5 条长音频切片。

每个模型输出统一转成 JSONL：`audio_id`、`model`、`text`、`segments`、`speakers`、`latency_ms`、`notes`。先人工看错误类型，再决定是否跑大规模指标。

## 7. 相关对象

- [[方向/AI语音/选型/Qwen 语音模型技术路线图|Qwen 语音模型技术路线图]]：ASR 属于 Qwen 语音路线图里的专用识别分支。
- [[方向/AI语音/模型/Qwen3-ASR|Qwen3-ASR]]：Qwen 专用 ASR 分支。
- [[方向/AI语音/模型/Whisper|Whisper]]：OpenAI ASR 通用基线。
- [[方向/AI语音/模型/GPT-4o Transcribe|GPT-4o Transcribe]]：OpenAI 云端 GPT-4o speech-to-text 模型线。
- [[方向/AI语音/模型/FunASR|FunASR]]：会议转写和企业语音工程链路。
- [[方向/AI语音/模型/Seed-ASR|Seed-ASR]]：LLM-based ASR 前沿对标。
- [[方向/AI语音/选型/Qwen 语音模型发展脉络|Qwen 语音模型发展脉络]]：Qwen 语音模型时间线。
- [[知识wiki/商业/DashScope 阿里云MaaS平台|DashScope 阿里云 MaaS 平台]]：QwenCloud / DashScope ASR API 平台上下文。

## 8. 来源

- [Qwen3-ASR Technical Report](https://arxiv.org/abs/2601.21337)
  - 内容定位：Qwen3-ASR 技术报告，记录 Qwen3-ASR、Qwen3-ForcedAligner、52 语言/方言、流式/离线和评测。
  - 用途：判断 Qwen3-ASR 的能力边界和本地选型价值。
  - 核验日期：2026-07-24
- [Speech-to-text models - QwenCloud](https://docs.qwencloud.com/developer-guides/speech/speech-to-text-models)
  - 内容定位：QwenCloud ASR 模型选择页，比较 Qwen3-ASR、Fun-ASR、Qwen-Omni 的语言覆盖、实时/批处理、说话人分离、情绪识别和热词。
  - 用途：区分 Qwen3-ASR-Flash、Fun-ASR、Qwen-Omni 的云端产品边界。
  - 核验日期：2026-07-24
- [FunASR README](https://github.com/modelscope/FunASR)
  - 内容定位：FunASR 官方仓库，记录 ASR、VAD、标点、说话人分离、时间戳、热词和部署工具链。
  - 用途：判断会议转写和工程链路能力。
  - 核验日期：2026-07-24
- [OpenAI Whisper model page](https://developers.openai.com/api/docs/models/whisper-1)
  - 内容定位：OpenAI `whisper-1` 当前 API 模型入口，记录 speech recognition、transcription 和 translation 端点。
  - 用途：确认 Whisper API 形态和当前模型入口。
  - 核验日期：2026-07-24
- [Robust Speech Recognition via Large-Scale Weak Supervision](https://arxiv.org/abs/2212.04356)
  - 内容定位：Whisper 论文，记录大规模弱监督、多语言识别和翻译能力。
  - 用途：引用 Whisper 作为通用基线的来源。
  - 核验日期：2026-07-24
- [Speech to text - OpenAI Docs](https://platform.openai.com/docs/guides/speech-to-text)
  - 内容定位：OpenAI Speech to text 官方文档，记录 `gpt-4o-transcribe`、`gpt-4o-mini-transcribe` 和流式转写能力。
  - 用途：判断 GPT-4o Transcribe 云端 ASR 路线。
  - 核验日期：2026-07-24
- [Create transcription - OpenAI API Reference](https://platform.openai.com/docs/api-reference/audio/createTranscription)
  - 内容定位：OpenAI Audio transcription API 参考，记录模型、输出格式、时间戳粒度、diarized JSON 等参数。
  - 用途：确认 GPT-4o Transcribe 的 API 输出能力。
  - 核验日期：2026-07-24
- [Seed-ASR Technical Report](https://arxiv.org/abs/2407.04675)
  - 内容定位：Seed-ASR 技术报告，记录 LLM-based ASR、上下文理解和多领域/口音/语言评测。
  - 用途：作为 ASR 前沿技术对标，不默认视为工程可用组件。
  - 核验日期：2026-07-24



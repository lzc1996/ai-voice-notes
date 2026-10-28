---
title: MOC - ASR
aliases:
  - Automatic Speech Recognition
  - Speech-to-Text
  - 语音识别
  - 自动语音识别
tags:
  - MOC
  - 类型/索引
  - 类型/方向
  - 方向/AI语音
  - 任务/ASR
---

# MOC - ASR

## 研究边界

ASR（Automatic Speech Recognition，自动语音识别）关注把语音音频转换成可校验、可对齐、可后处理的文本。这个方向覆盖离线/流式转写、长音频、时间戳、强制对齐、热词/术语、方言多语言、噪声混响鲁棒性和会议工程链路。

不把 TTS、语音增强或全模态音视频理解作为主线；它们只作为上下游组件、评测条件或架构边界保留。

## 核心问题

- 端到端 ASR、传统 ASR 工具链和 Omni prompt-context transcription 的边界如何划分。
- 低延迟流式识别、长音频稳定性、术语控制和时间戳质量之间如何取舍。
- 中文方言、多语言、代码切换、噪声、混响、音乐背景和远场条件下的鲁棒性如何验证。
- 会议转写是否应拆成 [[方向/AI语音/知识/基础概念/VAD（Voice Activity Detection）|VAD]]、说话人分离、ASR、标点、分段、摘要等可替换组件。
- ASR 结果如何用 WER/CER 之外的指标评估：实体词错误、数字错误、时间戳、说话人和下游任务收益。

## 种子对象

- [[方向/AI语音/选型/ASR 模型选型矩阵|ASR 模型选型矩阵]]：Qwen3-ASR、FunASR、Whisper、[[方向/AI语音/模型/GPT-4o Transcribe|GPT-4o Transcribe]]、Seed-ASR 和 Qwen-Omni 的工程选型入口。
- [[方向/AI语音/知识/技术路线/语音网络结构与模块|语音网络结构与模块]]：ASR encoder、Conformer/Transformer、[[方向/AI语音/知识/基础概念/CTC（连接时序分类）|CTC]]/RNNT/[[方向/AI语音/知识/基础概念/AED（注意力编码器-解码器）|AED]]、VAD/chunking 与音频 LLM adapter 的架构入口。
- [[方向/大模型/基础知识/MTP（Multi-Token Prediction）|MTP]]：Multi-Token Prediction，多 token 预测头；StepAudio 2.5 用 MTP-5 加速 ASR 解码。
- [[方向/AI语音/评估/CER（Character Error Rate）|CER（Character Error Rate）]]：ASR 字符级错误率指标，中文和代码切换场景常用。
- [[方向/AI语音/知识/基础概念/Levenshtein Alignment（莱文斯坦对齐）]]：WER/CER 的离散序列编辑对齐与错误分析基础。
- [[方向/AI语音/模型/Qwen3-ASR|Qwen3-ASR]]：Qwen 专用 ASR 模型线。
- [[方向/AI语音/模型/Qwen3-ForcedAligner|Qwen3-ForcedAligner]]：Qwen3-ASR 同线发布的 NAR 强制对齐模型，输出词/字符级时间戳。
- [[方向/AI语音/模型/Whisper|Whisper]]：OpenAI ASR 通用基线，也有 `whisper-1` API 形态。
- [[方向/AI语音/模型/GPT-4o Transcribe|GPT-4o Transcribe]]：OpenAI 云端 GPT-4o speech-to-text 模型线。
- [[方向/AI语音/模型/FunASR|FunASR]]：会议转写、[[方向/AI语音/知识/基础概念/VAD（Voice Activity Detection）|VAD]]、标点、热词和说话人分离工程链路。
- [[方向/AI语音/模型/Seed-ASR|Seed-ASR]]：ByteDance Seed 的 LLM-based ASR 前沿路线。
- [[方向/AI语音/模型/StepAudio 2.5|StepAudio 2.5]]：统一音频-语言模型，覆盖 ASR、TTS 和实时语音交互，适合比较 Omni 架构里的 ASR 专项能力。
- [[工具/Kaldi|Kaldi]]：传统 ASR 研究和 recipe 工具链入口。
- [[方向/AI语音/工具/Audio Speech Analysis Toolchain（音频语音分析工具链）|音频语音分析工具链]]：WhisperX、pyannote.audio、MFA、Praat 和 torchaudio 等转写 / 对齐 / 说话人 / 特征分析入口。
- [[方向/AI语音/数据集/LibriSpeech|LibriSpeech]]：英文朗读语音 ASR 训练与评测基准。
- [[方向/AI语音/数据集/OpenSLR|OpenSLR]]：公开语音和语言资源索引，常作为 ASR 数据入口。
- [[方向/AI语音/选型/Omni vs ASR TTS 专用模型选型|Omni vs ASR TTS 专用模型选型]]：语音 Agent 里是否拆 ASR/LLM/TTS 三层的架构判断。
- [[方向/AI语音/知识/基础概念/Reverberation Modeling（混响建模）|混响建模]]：远场 ASR 和去混响评测的声学条件入口。

## 上下游

- 上游：语音采集、[[方向/AI语音/知识/基础概念/音频数据预处理|音频数据预处理]]、[[方向/AI语音/知识/基础概念/VAD（Voice Activity Detection）|VAD]]、降噪、去混响、说话人分离、音频切分、采样率和通道处理。
- 下游：字幕、会议纪要、视频理解、语音 Agent、电话质检、检索索引、强制对齐和语音数据清洗。
- 相邻方向：[[方向/AI语音/MOC - TTS|TTS]]、[[方向/AI语音增强/README|AI 语音增强]]、说话人识别、[[方向/AI语音/知识/基础概念/SS（语音分离）|语音分离]]、音频理解。

## 关键资源

- [[方向/AI语音/信息源/语音会议与期刊|语音会议与期刊]]
  - 内容定位：Interspeech、ICASSP、SLT、ASRU、TASLP 等语音论文入口。
  - 用途：追踪 ASR 论文、workshop、challenge 和期刊扩展版。
  - 核验日期：2026-07-31
- [Qwen3-ASR Technical Report](https://arxiv.org/abs/2601.21337)
  - 内容定位：Qwen3-ASR、Qwen3-ForcedAligner、52 语言/方言、流式/离线和评测。
  - 用途：判断 Qwen 专用 ASR 线的能力边界。
  - 核验日期：2026-07-28
- [FunASR README](https://github.com/modelscope/FunASR)
  - 内容定位：ASR、VAD、标点、说话人分离、时间戳、热词和部署工具链。
  - 用途：会议转写和企业语音工程链路入口。
  - 核验日期：2026-07-28
- [OpenAI Whisper model page](https://developers.openai.com/api/docs/models/whisper-1)
  - 内容定位：OpenAI `whisper-1` 当前 API 模型入口，记录 speech recognition、transcription 和 translation 端点。
  - 用途：确认 Whisper API 形态和当前模型入口。
  - 核验日期：2026-07-28
- [Speech-to-text models - QwenCloud](https://docs.qwencloud.com/developer-guides/speech/speech-to-text-models)
  - 内容定位：QwenCloud ASR、Fun-ASR 和 Omni transcription 的云端模型选择页。
  - 用途：云端实时/文件转写和模型边界查询。
  - 核验日期：2026-07-28
- [Seed-ASR Technical Report](https://arxiv.org/abs/2407.04675)
  - 内容定位：ByteDance Seed-ASR 技术报告，记录 LLM-based ASR、上下文理解和多领域/口音/语言评测。
  - 用途：论文前沿对标。
  - 核验日期：2026-07-29

## 待深挖

- 是否需要单独建立 ASR 数据集清单：AISHELL、WenetSpeech、Common Voice、GigaSpeech、OpenSLR 资源。
- 是否需要拆出 ASR 评估框架：WER、[[方向/AI语音/评估/CER（Character Error Rate）|CER]]、实体错误、数字错误、时间戳、diarization、延迟和下游任务收益。
- 是否需要为“会议转写”和“实时语音 Agent”分别建立工程链路笔记。
- [[方向/AI语音/模型/Whisper|Whisper]]、[[方向/AI语音/模型/FunASR|FunASR]]、Qwen3-ASR、[[方向/AI语音/模型/GPT-4o Transcribe|GPT-4o Transcribe]] 的真实中文/方言/混响小样本对比是否要沉淀成实验表。



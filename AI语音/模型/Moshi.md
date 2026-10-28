---
title: Moshi
类型: 模型
参数量: 7B（Helium text LLM）
发表时间: 2024-09-19
时间依据: 开源权重与推理代码发布日（技术报告 2024-10）
任务:
  - 实时语音交互
  - 语音对话
开放状态:
  - paper
  - code
  - weights
  - demo
aliases:
  - Kyutai Moshi
  - moshi
  - Moshi speech-text foundation model
  - Mimi
tags:
  - 类型/对象
  - 方向/AI语音
  - 任务/实时语音交互
---

# Moshi

## 0. 背景

**问题现场**：实现单一模型内的实时全双工语音对话，原生处理重叠与打断。

**前序路线的缺口**：传统 VAD → ASR → 对话 → TTS 级联链路无法做到单模型全双工、延迟高。

**Moshi 的切入点**：Helium 7B 文本 LLM + Mimi 流式 codec（12.5 Hz / 1.1 kbps / 80ms），同时建模 Moshi 与用户两路音频流，并以 Inner Monologue（先生成文本 token 再生成语音 token）提升语音质量。

## 1. 内容定位

Moshi 是法国 Kyutai 实验室 2024 年发布的[[方向/AI语音/知识/基础概念/Full-Duplex（全双工）|全双工]]语音-文本基础模型，号称首个实时全双工 spoken LLM：不用 VAD → ASR → 对话 → TTS 级联，而是单一模型同时建模用户流与模型流。它是「codec token 神经语言模型」路线（[[方向/AI语音/模型/AudioLM|AudioLM]] 线）的标志性开源实现，也是本库衡量实时全双工能力的基准参照点（见 [[工程/语音 Agent 实时链路|语音 Agent 实时链路]]）。

## 2. 核心信息

- **底座**：Helium 7B 文本 LLM，在 2.1T 公开英文 token 上训练，提供推理与语言能力。
- **Mimi codec**：流式神经音频 codec，24 kHz 音频压到 12.5 Hz 表示、1.1 kbps 码率，帧级延迟 80ms；官方称优于同期的非流式 SpeechTokenizer（50 Hz, 4 kbps）与 SemantiCodec（50 Hz, 1.3 kbps）。语义 token 蒸馏自自监督模型（WavLM 类），与声学 token 分层建模。
- **多流全双工**：同时建模两路音频流（Moshi 自己 + 用户），原生处理重叠与打断，不需要独立 VAD 轮替。
- **Inner Monologue**：生成语音 token 前先预测对应文本 token，用文本对齐提升语音生成质量，也便于训练时利用文本数据。
- **延迟**：理论延迟 160ms（80ms 帧 + 80ms 声学延迟），实测约 200ms。
- **开源形态**：权重 + 技术报告 + PyTorch / Rust（生产）/ MLX（端侧）三套推理栈，官方提供在线 demo；语音为合成音色。

## 3. 发展脉络

谱系上承 [[方向/AI语音/模型/AudioLM|AudioLM]] / SpeechGPT 的「音频离散 token + LLM」思路，是第一个把**[[方向/AI语音/知识/基础概念/Full-Duplex（全双工）|全双工]]**做成单模型内机制的公开工作。后续全双工与低延迟方向的对照见 [[方向/AI语音/模型/Qwen3-Omni|Qwen3-Omni]]（冷启动首包理论延迟 234ms 量级）与 [[方向/AI语音/模型/StepAudio 2.5|StepAudio 2.5]]。时序综述 [Speech-to-Speech Models](https://itzsid.github.io/speech-to-speech-review/) 收录了从 SpeechGPT 到 Qwen3-Omni 的演进。

## 4. 边界

- 以英语为主，发布音色为固定合成音色，声音克隆/多语言不是其目标。
- 7B 规模决定了语言理解与推理能力上限，远弱于同期文本旗舰与后续商业实时 API。
- 价值在**机制验证**（单模型全双工 + 流式 codec + Inner Monologue）与完全开源，而非产品质量。

## 5. 相关对象

- [[方向/AI语音/知识/基础概念/NAC（神经音频 Codec）|NAC（神经音频 Codec）]]：Mimi 所属的神经音频 codec 概念。
- [[方向/AI语音/模型/Mini-Omni|Mini-Omni]] / [[方向/AI语音/模型/LLaMA-Omni|LLaMA-Omni]]：同期开源社区的简化端到端语音对话实现。
- [[方向/AI语音/模型/Qwen3-Omni|Qwen3-Omni]]：后续「端到端语音原生」路线的规模化代表。
- [[方向/AI语音/知识/技术路线/语音生成 tokenizer codec 技术路线|语音生成 tokenizer codec 技术路线]]：音频表示路线总入口。
- [[方向/AI语音/MOC - 音频大模型|MOC - 音频大模型]]：方向地图。

## 6. 来源

- [Moshi: a speech-text foundation model for real-time dialogue（arXiv:2410.00037）](https://arxiv.org/abs/2410.00037)
  - 内容定位：技术报告，覆盖 Helium 底座、Mimi codec、多流全双工、Inner Monologue 与延迟数字。
  - 用途：架构与机制判断的论文依据。
  - 核验日期：2026-08-07
- [kyutai-labs/moshi（GitHub）](https://github.com/kyutai-labs/moshi)
  - 内容定位：官方仓库，Mimi 指标（12.5 Hz / 1.1 kbps / 80ms）、PyTorch/Rust/MLX 推理栈与 demo 入口。
  - 用途：开源形态与复现入口。
  - 核验日期：2026-08-07

## 7. 待验证

- Moshi 后续版本（如多语言/新音色更新）与 Kyutai 最新语音栈的演进。

---
title: GLM-4-Voice
类型: 模型
发表时间: 2024-12-03
时间依据: arXiv 首次提交日
任务:
  - 实时语音交互
  - TTS
  - 语音对话
开放状态:
  - paper
  - code
  - weights
  - demo
aliases:
  - glm-4-voice
  - GLM-4-Voice-9B
  - 智谱 GLM-4-Voice
tags:
  - 类型/对象
  - 方向/AI语音
  - 任务/实时语音交互
---

# GLM-4-Voice

## 0. 背景

**问题现场**：语音对话若走 ASR/TTS 级联，难以直接利用语音中的情感、语调等信息，也难以用语音原生的方式回应。

**GLM-4-Voice 的切入点**：端到端路线——把语音压成约 12.5 tokens/s 的离散 token（Whisper encoder + VQ），在 GLM-4-9B 内直接理解与生成，配 CosyVoice 系 Flow Matching 流式解码器，支持情感/语调/语速/方言的指令可控。

## 1. 内容定位

GLM-4-Voice 是智谱 AI 2024 年底发布的端到端中英文语音对话模型：不用 ASR/TTS 级联，直接把语音表示为离散 token 在同一个模型内理解并生成，主打情感、语调、语速、方言可控的拟人实时对话。它是国产开源端到端语音原生路线的早期代表。

## 2. 核心信息

- **三件套**：
  - GLM-4-Voice-Tokenizer：Whisper encoder 插入向量量化（VQ）模块，ASR 数据有监督训练，把连续语音压成约 12.5 tokens/s 的离散序列（词表 16384）。
  - GLM-4-Voice-9B：在 GLM-4-9B 上于数百万小时音频与语音-文本交错数据继续预训练并对齐。
  - GLM-4-Voice-Decoder：基于 CosyVoice 的 Flow Matching 流式解码器，语音 token → 波形，拿到 10 个 token 即可起播。
- **可控性**：支持自然语言指令调节情感、语调、语速与方言。
- **开源**：权重（含 Int4 推理选项）、代码与 web demo 全部开放。

## 3. 发展脉络

与 [[方向/AI语音/模型/Moshi|Moshi]]、[[方向/AI语音/模型/LLaMA-Omni|LLaMA-Omni]] 同属 2024 年端到端语音对话浪潮；其 Tokenizer/Decoder 组件被后续工作复用（如 LLaMA-Omni2 的流式解码参考其实现）。智谱自身语音线后续演进见 GLM 系列发布。

## 4. 边界

- 轮替对话而非全双工，打断/抢话机制不在模型内。
- 知识型问答能力弱于同代文本旗舰（第三方评测共识）；复杂 QA 需外挂 RAG。
- 仅中英文；多语言场景看 [[方向/AI语音/模型/Qwen3-Omni|Qwen3-Omni]]。

## 5. 相关对象

- [[方向/AI语音/模型/Whisper|Whisper]]：Tokenizer 的编码器来源。
- [[方向/AI语音/知识/基础概念/Flow Matching（流匹配）|Flow Matching（流匹配）]]：Decoder 的生成范式。
- [[方向/AI语音/模型/LLaMA-Omni|LLaMA-Omni]] / [[方向/AI语音/模型/Mini-Omni|Mini-Omni]]：同期开源对照。
- [[工程/语音 Agent 实时链路|语音 Agent 实时链路]]：流式起播 token 数的工程含义。
- [[方向/AI语音/MOC - 音频大模型|MOC - 音频大模型]]：方向地图。

## 6. 来源

- [GLM-4-Voice: Towards Intelligent and Human-Like End-to-End Spoken Chatbot（arXiv:2412.02612）](https://arxiv.org/abs/2412.02612)
  - 内容定位：论文，Tokenizer/9B/Decoder 三件套设计、训练数据与对话能力评测。
  - 用途：架构与能力判断依据。
  - 核验日期：2026-08-07
- [THUDM/GLM-4-Voice（GitHub）](https://github.com/THUDM/GLM-4-Voice)
  - 内容定位：官方仓库，权重、推理代码与 demo。
  - 用途：复现入口。
  - 核验日期：2026-08-07

## 7. 待验证

- 智谱后续语音模型（GLM 系新版）相对 GLM-4-Voice 的迭代点。

---
title: Mini-Omni
类型: 模型
参数量: 0.5B（Qwen2-0.5B 底座）
发表时间: 2024-08-29
时间依据: arXiv 首次提交日
任务:
  - 实时语音交互
  - 语音对话
开放状态:
  - paper
  - code
  - weights
aliases:
  - mini-omni
  - gpt-omni Mini-Omni
  - Mini-Omni2
tags:
  - 类型/对象
  - 方向/AI语音
  - 任务/实时语音交互
---

# Mini-Omni

## 0. 背景

**问题现场**：实现低成本、完全端到端的实时语音对话，听、想、说同时进行。

**前序路线的缺口**：传统 ASR→LLM→TTS 级联链路存在串行等待，难以实时。

**Mini-Omni 的切入点**：在 0.5B（Qwen2-0.5B）小模型上做文本 + 音频 token 并行生成（"talk while thinking"），配合 Batch Parallel Decoding 让语音生成分摊文本推理能力。

## 1. 内容定位

Mini-Omni 是 gpt-omni 团队（Inspirai 与清华）2024 年发布的小型端到端语音对话模型，自称首个完全端到端的开源实时语音交互模型。它用极小规模（0.5B）验证了「文本+音频 token 并行生成」的低成本实时语音对话路径，是研究端到端语音原生路线时最易复现的入门对象之一。

## 2. 核心信息

- **底座**：Qwen2-0.5B 文本 LLM（24 层、隐维 896）；语音编码器为 Whisper-small encoder + 两层 MLP 适配器；TTS 适配器在原模型上扩展 6 个 transformer 块。
- **并行生成**：文本与音频 token 同步输出（"talk while thinking"），配合 Batch Parallel Decoding 让语音生成分摊文本推理能力，消除 ASR→LLM→TTS 串行等待。
- **音频表示**：SNAC 类离散音频 token 作生成目标（以论文/仓库为准）。
- **数据**：自建合成数据集 VoiceAssistant-400K，已开源。
- **训练规模**：8×A100；开源权重、推理代码与 demo。
- **后续版本**：Mini-Omni2（arXiv:2410.11190）加入视觉模态与听觉打断机制，对标开源版 GPT-4o 全模态。

## 3. 发展脉络

与 [[方向/AI语音/模型/Moshi|Moshi]]、[[方向/AI语音/模型/LLaMA-Omni|LLaMA-Omni]] 同属 2024 年开源社区追赶 GPT-4o 实时语音能力的一波；后续被 VocalNet、LLaMA-Omni2 等更小/更强开源实现继承。时序谱系见 [Speech-to-Speech Models](https://itzsid.github.io/speech-to-speech-review/)。

## 4. 边界

- 0.5B 规模决定其语言理解与知识能力很弱，只适合机制研究与教学复现。
- 音色自然度、多语言与鲁棒性远弱于商业实时 API 与 [[方向/AI语音/模型/Qwen3-Omni|Qwen3-Omni]] 级模型。
- 非全双工：打断机制到 Mini-Omni2 才出现。

## 5. 相关对象

- [[方向/AI语音/模型/Moshi|Moshi]]：同期的全双工开源参照，机制更完整。
- [[方向/AI语音/模型/LLaMA-Omni|LLaMA-Omni]]：同期更大底座的低延迟语音指令模型。
- [[方向/AI语音/模型/Whisper|Whisper]]：其语音编码器来源。
- [[方向/AI语音/知识/技术路线/语音生成 tokenizer codec 技术路线|语音生成 tokenizer codec 技术路线]]：音频 token 表示背景。
- [[方向/AI语音/MOC - 音频大模型|MOC - 音频大模型]]：方向地图。

## 6. 来源

- [Mini-Omni: Language Models Can Hear, Talk While Thinking in Streaming（arXiv:2408.16725）](https://arxiv.org/abs/2408.16725)
  - 内容定位：论文，覆盖并行生成、Batch Parallel Decoding、模型配置与训练设置。
  - 用途：架构与训练细节依据。
  - 核验日期：2026-08-07
- [Mini-Omni2: Towards Open-source GPT-4o with Vision, Speech and Duplex Capabilities（arXiv:2410.11190）](https://arxiv.org/abs/2410.11190)
  - 内容定位：后续版本论文，视觉+语音+打断机制。
  - 用途：版本演进判断。
  - 核验日期：2026-08-07
- [gpt-omni/mini-omni（GitHub）](https://github.com/gpt-omni/mini-omni)
  - 内容定位：官方仓库，权重、推理代码与 VoiceAssistant-400K 数据。
  - 用途：复现入口。
  - 核验日期：2026-08-07

## 7. 待验证

- SNAC 版本与论文版音频解码器的差异；Mini-Omni2 打断机制的实测延迟。

---
title: MiniCPM-o
类型: 模型
发表时间: 2025-01
时间依据: MiniCPM-o 2.6 官方发布（GitHub/Notion）
任务:
  - 实时语音交互
  - 音频理解
  - 语音对话
开放状态:
  - code
  - weights
  - demo
aliases:
  - MiniCPM-o 2.6
  - minicpm-o
  - 面壁 MiniCPM-o
  - MiniCPM-o 4.5
tags:
  - 类型/对象
  - 方向/AI语音
  - 任务/实时语音交互
  - 主题/多模态
---

# MiniCPM-o

## 0. 背景

**问题现场**：在手机等端侧设备上跑出 GPT-4o 级的"看、听、说"实时多模态交互。

**MiniCPM-o 的切入点**：各模态编解码器与 LLM 端到端联合训练，用时分复用（TDM）把并行多模态流切成小时间片顺序处理，在单模型内实现全双工 live streaming；8B/9B 规模 + int4 推理主打端侧部署。

## 1. 内容定位

MiniCPM-o 是面壁智能（OpenBMB）的端侧全模态模型系列，目标是在手机上跑出 GPT-4o 级的「看、听、说」实时交互。代表版本 MiniCPM-o 2.6（8B，2025-01）以全端到端训练 + 时分复用（TDM）流式机制实现全双工多模态 live streaming；后续 MiniCPM-o 4.5（9B，2026）引入 Omni-Flow 全双工架构。

## 2. 核心信息

- **端到端全模态架构**：各模态编码器/解码器与 LLM 端到端联合训练，仅用 CE loss。
- **TDM 流式机制**：把离线编码/解码器改造成在线流式版本；在 LLM 骨干内以时分复用把并行多模态流切成小时间片顺序处理，从而在单模型内实现全双工 live streaming。
- **可配置语音**：多模态 system prompt 引入「音频 system prompt」决定助手音色，推理期即可配置，支持端到端声音克隆与描述式音色创造。
- **端侧取向**：8B/9B 规模 + int4 推理模式，提供 chat 与 streaming 两种推理模式，主打手机/边缘部署。
- **开放**：权重与代码开源（OpenBMB/MiniCPM-o）。

## 3. 发展脉络

MiniCPM-o 2.6（2025-01，8B）→ MiniCPM-o 4.5（2026，9B，Omni-Flow 全双工）。与 [[Qwen2.5-Omni|Qwen2.5-Omni]] 同属全模态 Omni 线，差异化在端侧效率与 TDM 全双工机制（机制目标类似 [[方向/AI语音/模型/Moshi|Moshi]] 的多流，但工程路线不同）。

## 4. 边界

- 端侧规模限制了知识与推理深度；复杂任务仍需云端大模型。
- 全双工演示效果与商用实时 API 的成熟度有差距，实测延迟资料有限。
- 语音/视觉联合任务强，纯音频深度理解非其专长。

## 5. 相关对象

- [[方向/AI语音/模型/Moshi|Moshi]]：全双工机制的对照路线。
- [[Qwen2.5-Omni|Qwen2.5-Omni]] / [[方向/AI语音/模型/Qwen3-Omni|Qwen3-Omni]]：全模态 Omni 线的云端大模型对照。
- [[工程/语音 Agent 实时链路|语音 Agent 实时链路]]：TDM 与全双工实现的工程背景。
- [[方向/AI语音/评估/可控 TTS 与声音克隆评估框架|可控 TTS 与声音克隆评估框架]]：其声音克隆能力的评估框架。
- [[方向/AI语音/MOC - 音频大模型|MOC - 音频大模型]]：方向地图。

## 6. 来源

- [OpenBMB/MiniCPM-o（GitHub）](https://github.com/OpenBMB/MiniCPM-o)
  - 内容定位：官方仓库，2.6 架构说明（端到端 omni、TDM、音频 system prompt）、权重与推理模式。
  - 用途：架构与开放形态依据。
  - 核验日期：2026-08-07
- [MiniCPM-o 4.5: A 9B Model That Can See, Hear, and Speak at the Same Time（LearnOpenCV）](https://learnopencv.com/minicpm-o-4-5-a-9b-model-that-can-see-hear-and-speak-at-the-same-time/)
  - 内容定位：MiniCPM-o 4.5 的 Omni-Flow 全双工实测介绍。
  - 用途：版本演进判断。
  - 核验日期：2026-08-07

## 7. 待验证

- MiniCPM-o 2.6 / 4.5 的技术报告 arXiv 编号与全双工延迟的官方数字。

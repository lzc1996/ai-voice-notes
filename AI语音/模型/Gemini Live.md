---
title: Gemini Live
类型: 模型
发表时间: 2025-06-03
时间依据: Gemini 2.5 native audio 经 Live API 开放日（官方博客）
任务:
  - 实时语音交互
  - 语音对话
  - 音频理解
开放状态:
  - api
aliases:
  - Gemini Live API
  - gemini-live
  - Gemini native audio
  - gemini-2.5-flash-native-audio
tags:
  - 类型/对象
  - 方向/AI语音
  - 任务/实时语音交互
---

# Gemini Live

## 0. 背景

**问题现场**：实时语音对话服务需要端到端的音频理解与生成，在低延迟下保持自然对话韵律并支持打断、主动发言等主动式交互。

**Gemini Live 的切入点**：依托 Gemini 2.5 native audio 能力，经 WebSocket 双向流（BidiGenerateContent）提供端到端语音对话，取代早期 LLM+独立 TTS 的 half-cascade 架构。

## 1. 内容定位

Gemini Live API 是 Google 的实时语音对话服务线，依托 Gemini 2.5 的 **native audio** 能力做端到端语音理解与生成。它是「端到端语音原生」路线中与 [[方向/AI语音/模型/OpenAI Realtime|OpenAI Realtime]] 并列的商业标杆，特色是自然对话韵律与主动式交互。

## 2. 核心信息

- **两代架构**：
  - **native audio 模型**（如 `gemini-2.5-flash-native-audio-preview-09-2025` / `preview-12-2025`，及 `gemini-2.5-flash-native-audio-latest`）：端到端原生音频输出，对话自然度、情感表现（affective dialog）、主动发言（proactive audio）为卖点；官方与社区口径显示其已取代 half-cascade 成为主推路线。
  - **half-cascade 模型**（如 `gemini-live-2.5-flash-preview`）：LLM + 独立 TTS 的半级联，实时转写/翻译等场景曾更稳，2025 年下半年起逐步被 native audio 替换（社区有恢复呼声）。
- **接入**：WebSocket 双向流（`BidiGenerateContent` 端点），支持音频/文本输入与音频输出。
- **能力**：实时语音对话、打断、多语言、情感化回应；native audio 线持续高频更新（09/12-2025 多个 preview）。

## 3. 边界

- preview 模型稳定性风险：社区报告过 `native-audio-latest` 在 2026-05 出现高比例 mid-turn 断连（code 1011）事故，生产使用需锁版本并评估。
- 闭源按量计费；细节（延迟口径、打断策略）以实测为准，官方公开数字少。

## 4. 相关对象

- [[方向/AI语音/模型/OpenAI Realtime|OpenAI Realtime]]：直接竞品。
- [[方向/AI语音/模型/Qwen3-Omni|Qwen3-Omni]]：开源对照（官方报告曾与 Gemini-2.5-Pro 对比）。
- [[工程/语音 Agent 实时链路|语音 Agent 实时链路]]：实时链路工程背景。
- [[方向/AI语音/MOC - 音频大模型|MOC - 音频大模型]]：方向地图。

## 5. 来源

- [Advanced audio dialog and generation with Gemini 2.5（The Keyword）](https://blog.google/innovation-and-ai/models-and-research/google-deepmind/gemini-2.5-native-audio/)
  - 内容定位：官方博客，Gemini 2.5 native audio 经 Live API 开放的能力介绍。
  - 用途：native audio 能力与发布时间依据。
  - 核验日期：2026-08-07
- [Google AI 开发者论坛：Half cascade vs native audio 讨论](https://discuss.ai.google.dev/t/bring-back-the-half-cascade-gemini-live-2-5-flash-preview-model/111736)
  - 内容定位：社区确认 half-cascade 被 native audio 替换的过程与场景差异。
  - 用途：两代架构的边界判断。
  - 核验日期：2026-08-07

## 6. 待验证

- Live API 官方文档（ai.google.dev/gemini-api/docs/live）的延迟与打断细节（本次抓取重定向失败）。
- native audio 正式版（非 preview）模型名与计费口径。

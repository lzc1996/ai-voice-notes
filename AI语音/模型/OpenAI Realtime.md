---
title: OpenAI Realtime
类型: 模型
发表时间: 2025-08-28
时间依据: Realtime API 结束 Beta 正式 GA 日
任务:
  - 实时语音交互
  - 语音对话
  - 音频理解
开放状态:
  - api
aliases:
  - gpt-realtime
  - OpenAI Realtime API
  - GPT Realtime
  - gpt-realtime-2.1
tags:
  - 类型/对象
  - 方向/AI语音
  - 任务/实时语音交互
---

# OpenAI Realtime

## 0. 背景

**问题现场**：云端语音对话此前走 STT→LLM→TTS 串联链路，不是端到端语音原生的形态，难以做到低延迟并捕捉笑声、口音等副语言细节。

**前序路线的缺口**：STT→LLM→TTS 串联链路被单一 speech-to-speech 模型所取代，即串联形态本身被官方视为需要替换的对象。

**OpenAI Realtime 的切入点**：用单一端到端 speech-to-speech 模型承载语音对话、流式转写与连续翻译三类会话，经 WebRTC / WebSocket / SIP 接入生产级 voice-agent 服务。

## 1. 内容定位

OpenAI Realtime API 与 `gpt-realtime` 是 OpenAI 的生产级端到端语音-语音服务线：2025-08-28 结束 Beta 全面开放，用单一 speech-to-speech 模型取代 STT→LLM→TTS 串联链路。它是「端到端语音原生」路线的商业标杆，也是本库做语音 Agent 选型时的云端对照（[[方向/AI语音/选型/Omni vs ASR TTS 专用模型选型|Omni vs ASR TTS 专用模型选型]]）。

## 2. 核心信息

- **模型**：`gpt-realtime`（GA 版 `gpt-realtime-2025-08-28`）；官方文档当前列 `gpt-realtime-2.1`（Realtime 2 引入 `reasoning.effort` 推理档位，用推理换延迟/复杂度平衡）。
- **能力口径**：端到端低延迟、可捕捉笑声/口音等副语言细节、句中多语言切换；官方称 Big Bench Audio 准确率 65.6%→82.8%（相对前代），降价 20%（音频输入 $32 / 输出 $64 每百万 token 口径）。
- **会话形态**：voice-agent（对话+工具）、transcription（流式转写）、translation（连续翻译）三种会话，端点与延迟预算不同。
- **接入**：WebRTC（浏览器/移动端）、WebSocket（服务端媒体管道）、SIP（电话）；GA 新增图像输入、远程 MCP 服务器，专属声音 Cedar、Marin。
- **安全**：支持 `OpenAI-Safety-Identifier` 请求头做用户级安全归因（见 [[方向/AI语音/知识/调研与地图/LALM Trust and Safety（音频大模型信任与安全）|LALM Trust and Safety]]）。

## 3. 边界

- 闭源按量计费，长会话成本高（社区口径实时语音约 $18/小时量级）；延迟与自然度优势需按场景实测。
- 全双工体验依赖服务端 VAD/打断策略，细节不透明；自建可控性看开源线（[[方向/AI语音/模型/Moshi|Moshi]]、[[方向/AI语音/模型/Qwen3-Omni|Qwen3-Omni]]）。

## 4. 相关对象

- [[方向/AI语音/模型/GPT-4o Transcribe|GPT-4o Transcribe]]：同厂转写线。
- [[方向/AI语音/模型/Gemini Live|Gemini Live]]：直接竞品。
- [[方向/AI语音/模型/Qwen3-Omni|Qwen3-Omni]]：开源对照。
- [[工程/语音 Agent 实时链路|语音 Agent 实时链路]]：会话形态、传输与延迟预算的工程拆解。
- [[方向/AI语音/MOC - 音频大模型|MOC - 音频大模型]]：方向地图。

## 5. 来源

- [Introducing gpt-realtime and Realtime API updates for production voice agents（OpenAI）](https://openai.com/index/introducing-gpt-realtime/)
  - 内容定位：GA 发布公告，模型版本、图像输入/SIP/MCP、价格与准确率口径。
  - 用途：发布事实与能力口径依据。
  - 核验日期：2026-08-07
- [OpenAI Realtime API 指南](https://platform.openai.com/docs/guides/realtime)
  - 内容定位：会话类型、传输选择（WebRTC/WebSocket/SIP）、reasoning 档位与安全标识。
  - 用途：工程接入口径。
  - 核验日期：2026-08-07

## 6. 待验证

- gpt-realtime-2.1 相对 2025-08 版的延迟与价格变化；实测打断行为。

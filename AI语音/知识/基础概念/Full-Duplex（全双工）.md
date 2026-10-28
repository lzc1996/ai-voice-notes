---
title: Full-Duplex（全双工）
类型: 概念
相关主题:
  - 语音对话
  - 实时语音
  - 语音 Agent
aliases:
  - Full-Duplex
  - full-duplex
  - 全双工
  - 双工
  - 半双工
  - turn-based
  - 可打断对话
tags:
  - 类型/对象
  - 方向/AI语音
  - 任务/语音对话
  - 主题/实时语音
  - 主题/语音 Agent
---
# Full-Duplex（全双工）

## 1. 身份

`全双工`（Full-Duplex，通信术语"同时双向传输"借入语音对话模型）：模型**一边生成回复语音、一边接收用户语音**——可随时打断（barge-in）、边说边听。对照**半双工 / turn-based**（听完整句再答，如 [[方向/AI语音/模型/GLM-4-Voice|GLM-4-Voice]]）。[[方向/AI语音/模型/Moshi|Moshi]]（Kyutai 2024）是首个把全双工做成**单模型内机制**的公开实现。

边界：全双工 ≠ 低延迟（可以有低延迟 turn-based，也可以高延迟全双工）；全双工 ≠ 端到端单模型（级联系统也可实现系统级全双工，靠模块切换）。

## 2. 为什么难

- **生成与监听并行**：自回归生成当前 token 的同时，还要流式处理正在到达的用户语音——输入流与输出流并发。
- **打断（barge-in）**：用户开口 → 立即停止生成并切换接收——打断检测的延迟直接决定体验。
- **自听 / 回声**：模型自己的输出被麦克风拾回——**[[方向/AI语音/知识/基础概念/AEC（声学回声消除）]] 是刚需**，与语音增强前端交汇（见 [[方向/AI语音/知识/基础概念/Audio Leakage（漏音）|Audio Leakage]] 相关问题）。
- **事件对齐**：谁在说、何时说——流式活动检测（[[方向/AI语音/知识/基础概念/VAD（Voice Activity Detection）|VAD]]）+ 双流 token 的时序协调。

## 3. 实现谱系

| 方案 | 代表 | 机制 |
|---|---|---|
| 级联（伪全双工） | 传统 VAD → ASR → LLM → TTS | 各段独立，靠系统级状态切换 |
| 单模型全双工 | [[方向/AI语音/模型/Moshi]] | 双流建模（用户流 + 模型流）+ streaming token 机制 |
| 语音原生流式 | Qwen3-Omni / Gemini Live / OpenAI Realtime | 端到端多模态 token 流，边听边答 |
| turn-based 但流式 | [[方向/AI语音/模型/GLM-4-Voice]] | "Streaming thoughts" 文本-语音交替，快速起播但**不可打断** |

## 4. 与语音增强的交汇

- **[[方向/AI语音/知识/基础概念/AEC（声学回声消除）]]**：全双工下模型自听 → 回声消除是硬前提（增强前端组件之一）。
- **打断检测与 VAD**：增强前端提供干净的语音活动判断。
- **多流感知**：ECHI 类"同时听多人"与全双工的"听 + 说"共享流式多通道处理难题。

## 5. 相关对象

- [[方向/AI语音/模型/Moshi|Moshi]]：单模型全双工开创实现。
- [[方向/AI语音/模型/GLM-4-Voice|GLM-4-Voice]]：turn-based 流式对照。
- [[方向/AI语音/模型/Qwen3-Omni|Qwen3-Omni]]、[[方向/AI语音/模型/StepAudio 2.5|StepAudio 2.5]]：语音原生流式线。
- [[方向/AI语音/工程/语音 Agent 实时链路|语音 Agent 实时链路]]：延迟口径参照。
- [[方向/AI语音/知识/基础概念/AEC（声学回声消除）]]：全双工链路里处理模型自听和扬声器回灌的前端模块。
- [[方向/AI语音/知识/基础概念/VAD（Voice Activity Detection）|VAD]]、[[方向/AI语音/知识/基础概念/Audio Leakage（漏音）|Audio Leakage]]：全双工的前端组件与问题域。

## 6. 待验证

- 主流全双工模型（Moshi / Qwen3-Omni / Realtime）的打断延迟实测对比。
- AEC 与全双工 LLM 的集成方案（模型内回声建模 vs 前端 AEC）。

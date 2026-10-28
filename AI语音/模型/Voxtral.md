---
title: Voxtral
类型: 模型
发表时间: 2025-07-15
时间依据: 官方发布日
任务:
  - ASR
  - 音频理解
  - 语音翻译
开放状态:
  - weights
  - api
aliases:
  - voxtral
  - Voxtral Small
  - Voxtral Mini
  - Voxtral Small 24B
tags:
  - 类型/对象
  - 方向/AI语音
  - 任务/ASR
---

# Voxtral

## 0. 背景

**问题现场**：生产环境需要稳定的语音转写与音频理解能力，但开源 ASR 易出错、闭源 API 昂贵。

**前序路线的缺口**：开源 ASR 质量不可靠，闭源 API 成本高，两者之间存在空档。

**Voxtral 的切入点**：以 Apache 2.0 开放权重的语音理解模型家族（Mini 3B / Small 24B）主打生产级转写 + 音频理解，直接从音频做转写、翻译、问答与摘要。

## 1. 内容定位

Voxtral 是 Mistral AI 2025 年 7 月发布的开放权重**语音理解**模型家族（Apache 2.0）：主打生产级转写 + 音频理解，定位是填平「易出错的开源 ASR」与「昂贵闭源 API」之间的空档。注意它只做音频输入→文本输出，不做语音生成与对话，与 Omni/对话线是不同物种。

## 2. 核心信息

- **两个尺寸**：Voxtral Mini 3B（本地/边缘）与 Voxtral Small 24B（生产环境，基于 Mistral Small 3.1 24B 骨干）。
- **上下文**：32K token，约 40 分钟连续音频。
- **能力**：直接从音频做转写、翻译、问答与摘要，支持 8+ 语言。
- **开放与成本**：HF 权重 + Mistral API（官方口径价格约为多数商业方案的一半以下，约 $0.001/音频分钟）。

## 3. 发展脉络

属「LLM-based 语音理解」线（对照 [[方向/AI语音/模型/Qwen3-ASR|Qwen3-ASR]]、[[方向/AI语音/模型/Seed-ASR|Seed-ASR]] 的专用化思路），差异在开放权重 + 理解问答一体。选型对比见 [[方向/AI语音/选型/ASR 模型选型矩阵|ASR 模型选型矩阵]]。

## 4. 边界

- 无语音生成/对话能力；实时流式与全双工不是其目标（该场景看 [[工程/语音 Agent 实时链路|语音 Agent 实时链路]] 所列模型）。
- 说话人分离、强制对齐等工程件需另配（与 Qwen3-ASR 家族对比时的常见缺口）。

## 5. 相关对象

- [[方向/AI语音/模型/Whisper|Whisper]]：开放 ASR 基线的上一代参照。
- [[方向/AI语音/模型/Qwen3-ASR|Qwen3-ASR]]：专用 ASR 线对照。
- [[方向/AI语音/模型/GPT-4o Transcribe|GPT-4o Transcribe]]：闭源云端对照。
- [[方向/AI语音/选型/ASR 模型选型矩阵|ASR 模型选型矩阵]]：工程选型对比。
- [[方向/AI语音/MOC - 音频大模型|MOC - 音频大模型]]：方向地图。

## 6. 来源

- [Mistral AI 官方发布（Voxtral Mini 3B & Small 24B）](https://mistral.ai/news/voxtral)
  - 内容定位：官方发布页，两个尺寸、Apache 2.0、能力与价格口径。（以官方页面为准，本次经由多篇二手报道交叉确认关键事实）
  - 用途：能力与开放形态依据。
  - 核验日期：2026-08-07

## 7. 待验证

- Voxtral 是否有技术报告/模型卡给出的基准对比官方表；实时流式版本（Voxtral Realtime 类）的发布状态。

---
title: VAD（Voice Activity Detection）
类型: 概念
发表时间:
时间依据: 经典任务/技术类别；非单一发表物
相关任务:
  - ASR
相关主题:
  - 音频处理
相关模型:
  - "[[方向/AI语音/模型/FunASR]]"
aliases:
  - Voice Activity Detection（VAD）
  - VAD
  - Voice Activity Detection
  - vad
tags:
  - 类型/对象
  - 方向/AI语音
  - 任务/ASR
  - 主题/音频处理
---

# VAD（Voice Activity Detection）

## 1. 身份

VAD 是 **Voice Activity Detection，语音活动检测**：判断音频里哪些时间段有人声，哪些时间段是静音、背景声或非语音噪声。它不负责识别“说了什么”，只负责给出“哪里有人在说话”。

边界：VAD 不是 ASR，不输出文字；也不是 diarization，不判断是谁说话。端点检测（endpointing）通常建立在 VAD 之上，用来判断一句话什么时候开始和结束。

## 2. 在语音链路里的位置

```text
长音频
  -> VAD 找语音片段
  -> 切块 / endpointing
  -> 降噪 / 去混响 / ASR
  -> 标点 / 分段 / 说话人分离 / 摘要
```

- **长音频转写**：先去掉静音和非语音片段，减少 ASR 成本。
- **实时语音 Agent**：判断用户什么时候开始说、什么时候说完，影响打断和响应延迟。
- **会议转写**：作为 ASR、说话人分离、标点和段落合并之前的工程前置。
- **语音增强**：可辅助区分语音段和噪声段，但强噪声、音乐和重叠说话会让 VAD 变难。

## 3. 和相邻模块的区别

| 模块 | 回答的问题 |
|---|---|
| VAD | 这段有没有人在说话 |
| ASR | 人说了什么文字 |
| Diarization | 这句话是谁说的 |
| Speaker Verification | 这个人是不是指定说话人 |
| Speech Enhancement | 怎么把语音变清楚 |

## 4. 难点

- 背景音乐、键盘声、风噪、咳嗽会造成误触发。
- 多人重叠说话、远场会议室、强混响会造成漏检或边界不准。
- 实时场景不能等未来上下文，端点判断更容易过早或过晚。
- 对语音 Agent 来说，VAD 延迟会直接吃掉全链路响应预算。

## 5. 关键入口

- [[方向/AI语音/知识/基础概念/Energy-based VAD（基于能量的语音活动检测）|Energy-based VAD]]：最小可解释的能量阈值基线，适合静音裁剪和调试。
- [[方向/AI语音/模型/FunASR|FunASR]]：工程组件里包含 FSMN-VAD，可用于长音频切分和端点检测。
- WebRTC VAD：传统实时通信场景常用的轻量 VAD 基线。
- Silero VAD：常见神经 VAD 工程基线，适合本地批处理或实时前置。

## 6. 相关对象

- [[方向/AI语音/知识/基础概念/音频数据预处理|音频数据预处理]]：VAD 是长音频切分、静音处理和 endpointing 的关键步骤。
- [[方向/AI语音/知识/基础概念/Enrollment（说话人注册）|Enrollment]]：说话人注册前通常先用 VAD 切出有效语音，避免静音和噪声污染 speaker profile。
- [[方向/AI语音/MOC - ASR|ASR]]：VAD 是 ASR 上游切分与端点检测模块。
- [[方向/AI语音/模型/FunASR|FunASR]]：包含 VAD、ASR、标点、时间戳和说话人相关组件。
- [[方向/AI语音/选型/ASR 模型选型矩阵|ASR 模型选型矩阵]]：会议转写选型需要把 VAD 作为工程输出项看。
- [[方向/AI语音/知识/基础概念/Audio Leakage（漏音）|漏音]]：语音 Agent 中 AEC、barge-in 和 ASR VAD 的责任边界需要分清。

## 7. 待验证

- 当前实时语音 Agent 链路里，VAD 端点延迟预算应控制在多少毫秒。
- FunASR FSMN-VAD、WebRTC VAD、Silero VAD 在中文远场、键盘声、背景音乐和漏音场景里的误触发差异。
- VAD 是放在语音增强前、增强后，还是两侧都放，哪种对 ASR 更稳。


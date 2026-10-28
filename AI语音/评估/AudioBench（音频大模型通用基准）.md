---
title: AudioBench（音频大模型通用基准）
类型: 评测基准
发表时间: 2024-06
时间依据: arXiv 首次提交日
aliases:
  - AudioBench
  - audiobench
  - AudioBench: A Universal Benchmark for Audio Large Language Models
tags:
  - 类型/对象
  - 方向/AI语音
  - 主题/评测基准
---

# AudioBench（音频大模型通用基准）

## 0. 背景

**问题现场**：音频大模型（LALM）出现后，SUPERB/[[方向/AI语音/评估/HEAR（音频表示整体评估）|HEAR]] 的"冻结表示 + 轻量探针"范式不再适用，需要评测"听懂音频并按指令回答"的完整模型链路。

**切入点**：第一批端到端 Audio LLM 通用横评基准，覆盖语音理解、音频场景问答与语音指令跟随三大方向，并维护公开 leaderboard。

## 1. 身份

`AudioBench`（A Universal Benchmark for Audio Large Language Models，2024，新加坡 A*STAR 等，arXiv:2406.16020）是第一批专门面向**端到端音频大模型**（Audio LLM / LALM）的通用横评基准，把评测对象从 [[方向/AI语音/评估/SUPERB（语音处理通用性能基准）|SUPERB]] 时代的 frozen 表示换成了「听懂音频并按指令回答」的完整模型。

## 2. 任务口径

覆盖三大方向的多任务集合（以论文为准）：

- **语音理解**：ASR、语音翻译、说话人/情感等副语言任务。
- **音频场景问答**：环境声、音乐等通用音频的理解问答。
- **语音指令跟随**：以口语指令驱动的开放式生成任务。

论文对当时多个 AudioLLM（Qwen-Audio、SALMONN、WavLLM 等）做了统一横评，并维护公开 leaderboard。

## 3. 使用注意

- 评测的是**理解+生成回答**的完整链路，与 SUPERB/[[方向/AI语音/评估/HEAR（音频表示整体评估）|HEAR]] 的表示评测范式不同代。
- 题目难度偏感知与浅层理解；考察深度推理时应看 [[方向/AI语音/评估/MMAU（大规模多任务音频理解与推理基准）|MMAU]]、[[方向/AI语音/评估/MMAR（音频深度推理基准）|MMAR]]。
- 不同子集指标口径不一（准确率/WER/模型打分），横向比数字前先确认口径。

## 4. 关键来源

- [AudioBench: A Universal Benchmark for Audio Large Language Models（arXiv:2406.16020）](https://arxiv.org/abs/2406.16020)
  - 内容定位：基准论文，任务集合、评测协议与首批 AudioLLM 横评结果。
  - 用途：任务口径与协议依据。
  - 核验日期：2026-08-07

## 5. 相关对象

- [[方向/AI语音/评估/SUPERB（语音处理通用性能基准）|SUPERB]] / [[方向/AI语音/评估/HEAR（音频表示整体评估）|HEAR]]：表示评测时代的上一代基准。
- [[方向/AI语音/评估/MMAU（大规模多任务音频理解与推理基准）|MMAU]] / [[方向/AI语音/评估/MMAR（音频深度推理基准）|MMAR]]：更难的专家级/推理向基准。
- [[方向/AI语音/知识/技术路线/Audio Reasoning（音频推理）|Audio Reasoning（音频推理）]]：推理评测线的背景。
- [[方向/AI语音/MOC - 音频大模型|MOC - 音频大模型]]：方向地图。

## 6. 待验证

- AudioBench leaderboard 当前维护状态与新模型（Qwen3-Omni、Step-Audio 系）成绩收录情况。

---
title: MMAR（音频深度推理基准）
类型: 评测基准
发表时间: 2025-05
时间依据: arXiv 首次提交日
aliases:
  - MMAR
  - mmar
  - MMAR: A Challenging Benchmark for Deep Reasoning in Speech Audio Music and Their Mix
tags:
  - 类型/对象
  - 方向/AI语音
  - 主题/评测基准
---

# MMAR（音频深度推理基准）

## 0. 背景

**问题现场**：音频语言模型在浅层感知基准上分数尚可，但串联听觉线索与知识的多步深度推理缺乏困难基准。

**切入点**：覆盖 speech/audio/music 及其混合场景的多步推理题，区分"真在听"与"靠文本先验猜"，与 MMAU/SAKURA 同属音频推理评测线。

## 1. 身份

`MMAR`（A Challenging Benchmark for Deep Reasoning in Speech, Audio, Music, and Their Mix，Ziyang Ma 等，arXiv:2505.13032）是 2025 年面向音频语言模型**深度推理**能力的困难基准，与 [[方向/AI语音/评估/MMAU（大规模多任务音频理解与推理基准）|MMAU]]、[[方向/AI语音/评估/SAKURA（语音多跳推理基准）|SAKURA]] 同属音频推理评测线，常被音频推理综述与 RL 后训练工作引用。

## 2. 任务口径

- **覆盖域**：speech、audio（环境声）、music，以及三者的**混合**场景（如同时含语音与背景声/音乐的复合推理）。
- **题目特征**：多步推理题，要求模型串联听觉线索与常识/知识推理，而非单步感知判断。
- **构造方式**：真实音频 + 人工设计/校验的推理题（规模与细节以论文为准）。

## 3. 使用注意

- 难度定位比 MMAU 更偏「深推理」；模型在该基准上的低分常被用作 Audio-CoT/RL 后训练必要性的论据（见 [[方向/AI语音/知识/技术路线/Audio Reasoning（音频推理）|Audio Reasoning（音频推理）]]）。
- 混合域题目对「听觉 grounding」敏感，能区分「真在听」与「靠文本先验猜」的模型。
- 评测理解与推理，不覆盖生成与对话。

## 4. 关键来源

- [MMAR: A Challenging Benchmark for Deep Reasoning in Speech, Audio, Music, and Their Mix（arXiv:2505.13032）](https://arxiv.org/abs/2505.13032)
  - 内容定位：基准论文，任务构造、难度设计与现有模型失败模式分析。
  - 用途：任务口径与结论依据。
  - 核验日期：2026-08-07

## 5. 相关对象

- [[方向/AI语音/评估/MMAU（大规模多任务音频理解与推理基准）|MMAU]] / [[方向/AI语音/评估/SAKURA（语音多跳推理基准）|SAKURA]]：同属音频推理评测线。
- [[方向/AI语音/模型/Step-Audio R1|Step-Audio R1]]：以此类基准验证 RL 后训练收益的代表模型。
- [[方向/AI语音/知识/技术路线/Audio Reasoning（音频推理）|Audio Reasoning（音频推理）]]：该基准支撑的路线。
- [[方向/AI语音/MOC - 音频大模型|MOC - 音频大模型]]：方向地图。

## 6. 待验证

- 题目规模、train/dev/test 划分细节与 leaderboard 维护状态。

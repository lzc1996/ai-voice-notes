---
title: MMAU（大规模多任务音频理解与推理基准）
类型: 评测基准
发表时间: 2024-10-23
时间依据: arXiv 首次提交日（ICLR 2025 收录）
aliases:
  - MMAU
  - mmau
  - Massive Multi-Task Audio Understanding and Reasoning Benchmark
  - MMAU-Pro
tags:
  - 类型/对象
  - 方向/AI语音
  - 主题/评测基准
---

# MMAU（大规模多任务音频理解与推理基准）

## 0. 背景

**问题现场**：已有音频基准多停在感知与浅层理解，音频大模型的专家级理解与推理能力缺乏难度足够的测量。

**切入点**：约 1 万条音频配专家级多选题，覆盖 speech/sound/music 与约 27 项技能，专考深度理解与多步推理；核心结论之一是当时 LALM 远不及人类。

## 1. 身份

`MMAU`（Massive Multi-Task Audio Understanding and Reasoning Benchmark，马里兰大学等，arXiv:2410.19168，ICLR 2025）是当前音频大模型**专家级理解与推理**评测的核心标尺：约一万条音频配人工精心设计的多选问答，强调需要专家知识与复杂推理，而不是浅层感知。

## 2. 任务口径

- **三大音频域**：speech、sound（环境声）、music，下分约 27 项技能（信息提取、推理计算、情感/意图判断、乐理分析等）。
- **题型**：多选题（专家级难度），考察对音频内容的深度理解与多步推理。
- **规模**：约 10k 条音频；常用 `test-mini` 子集做快速对比，完整 `test` 集作正式评测。
- **版本**：MMAU-v05.15.25 修订约 25% 题目提升质量；官方评测 2026-01 起迁至 Hugging Face Space。后续发布更难的 **MMAU-Pro**（arXiv:2508.13992）。

## 3. 使用注意

- 头部模型与人类水平差距明显——MMAU 论文的核心结论之一就是当时 LALM 在该基准上远不及人类，这是「音频推理仍有大量空间」的常用论据。
- 报分数时必须注明是 `test-mini` 还是完整 `test`，以及题目版本（v05 修订前后不可直接比）。
- 只看理解问答；不覆盖语音生成、对话与实时能力。

## 4. 关键来源

- [MMAU: A Massive Multi-Task Audio Understanding and Reasoning Benchmark（arXiv:2410.19168）](https://arxiv.org/abs/2410.19168)
  - 内容定位：基准论文（ICLR 2025），任务设计、技能分类与头部 LALM 评测结果。
  - 用途：任务口径与结论依据。
  - 核验日期：2026-08-07
- [Sakshi113/MMAU（GitHub）](https://github.com/Sakshi113/MMAU)
  - 内容定位：评测代码、test-mini/test 数据、版本更新公告与 HF Space 评测入口。
  - 用途：跑评测与确认版本。
  - 核验日期：2026-08-07
- [MMAU-Pro（arXiv:2508.13992）](https://arxiv.org/abs/2508.13992)
  - 内容定位：更难、更全面的后续版本。
  - 用途：判断新一代模型的天花板。
  - 核验日期：2026-08-07

## 5. 相关对象

- [[方向/AI语音/评估/MMAR（音频深度推理基准）|MMAR]] / [[方向/AI语音/评估/SAKURA（语音多跳推理基准）|SAKURA]]：同属音频推理评测线。
- [[方向/AI语音/评估/AudioBench（音频大模型通用基准）|AudioBench]]：更早的通用横评基准。
- [[方向/AI语音/模型/Step-Audio R1|Step-Audio R1]]：以 MMAU 等为主要评测的推理模型。
- [[方向/AI语音/知识/技术路线/Audio Reasoning（音频推理）|Audio Reasoning（音频推理）]]：该基准支撑的路线。
- [[方向/AI语音/MOC - 音频大模型|MOC - 音频大模型]]：方向地图。

## 6. 待验证

- MMAU-Pro 与原版在各旗舰模型上的分差；v05 修订对历史榜单可比性的影响。

---
title: Dynamic-SUPERB（动态语音指令基准）
类型: 评测基准
发表时间: 2023-09-18
时间依据: Phase-1 arXiv 首次提交日
aliases:
  - Dynamic-SUPERB
  - dynamic-superb
  - Dynamic SUPERB
  - Dynamic-SUPERB Phase-2
tags:
  - 类型/对象
  - 方向/AI语音
  - 主题/评测基准
---

# Dynamic-SUPERB（动态语音指令基准）

## 0. 背景

**问题现场**：[[方向/AI语音/评估/SUPERB（语音处理通用性能基准）|SUPERB]] 评测的是冻结表示的固定任务集，无法衡量通用语音模型"听指令做事"的能力；指令跟随型 spoken language model 缺少系统评测。

**切入点**：社区共建的指令化基准——文本指令 + 音频组件构成任务，零样本考察指令跟随广度；Phase-2 扩到 180 个任务。

## 1. 身份

`Dynamic-SUPERB`（台大等发起的社区共建基准）是 [[方向/AI语音/评估/SUPERB（语音处理通用性能基准）|SUPERB]] 的指令化后继：评测**通用语音模型**能否不微调、按自然语言指令零样本完成大量任务。Phase-1（arXiv:2309.09510，2023）是首个语音指令微调评测基准；Phase-2（arXiv:2411.05361，ICLR 2025）扩到 180 个任务，是指令型 universal speech model 的最大评测面。

## 2. 任务口径

- **评测对象**：接受 speech/music/audio 输入、无需微调、跟随自然语言指令执行的通用模型——即 LALM 的前身 spoken language model。
- **任务结构**：文本指令 + 音频组件（输入/输出至少一端含音频）+ 可选文本组件；每个任务配多条不同指令考察指令理解。
- **Phase-2 规模**：180 个任务（社区贡献 91 个新任务）；核心任务由 SUPERB（语音）、MARBLE（音乐）、[[方向/AI语音/评估/HEAR（音频表示整体评估）|HEAR]]（音频）改造而来；仅提供测试数据。
- **已知局限**：以理解任务为主，缺系统的语音生成任务（Phase-2 论文自述）。

## 3. 使用注意

- 核心结论：近期模型在特定任务上表现好，但在 SUPERB 类常见任务上泛化差——「指令跟随的广度」与「单任务深度」尚未兼得。
- 适合衡量模型的指令覆盖广度；深度推理看 [[方向/AI语音/评估/MMAU（大规模多任务音频理解与推理基准）|MMAU]]/[[方向/AI语音/评估/MMAR（音频深度推理基准）|MMAR]]，开放生成看 [[方向/AI语音/评估/AudioBench（音频大模型通用基准）|AudioBench]]。
- 任务多、指标杂，横向对比时按官方 task taxonomy 分组看。

## 4. 关键来源

- [Dynamic-SUPERB: Towards A Dynamic, Collaborative, and Comprehensive Instruction-Tuning Benchmark for Speech（arXiv:2309.09510）](https://arxiv.org/abs/2309.09510)
  - 内容定位：Phase-1 论文，指令化评测框架与首批任务。
  - 用途：框架来源。
  - 核验日期：2026-08-07
- [Dynamic-SUPERB Phase-2（arXiv:2411.05361，ICLR 2025）](https://arxiv.org/abs/2411.05361)
  - 内容定位：Phase-2 论文，180 任务、任务分类法与模型泛化分析。
  - 用途：任务口径与结论依据。
  - 核验日期：2026-08-07

## 5. 相关对象

- [[方向/AI语音/评估/SUPERB（语音处理通用性能基准）|SUPERB]] / [[方向/AI语音/评估/HEAR（音频表示整体评估）|HEAR]]：核心任务的改造来源。
- [[方向/AI语音/评估/MMSU（口语理解推理基准）|MMSU]]：同属指令型口语模型评测线。
- [[方向/AI语音/模型/Kimi-Audio|Kimi-Audio]]：以此类任务为目标的通用音频底座代表。
- [[方向/AI语音/MOC - 音频大模型|MOC - 音频大模型]]：方向地图。

## 6. 待验证

- 社区任务贡献通道是否仍开放、Phase-3 动向。

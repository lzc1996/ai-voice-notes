---
title: SUPERB（语音处理通用性能基准）
类型: 评测基准
发表时间: 2021-05
时间依据: arXiv 首次提交（Interspeech 2021 发表）
aliases:
  - SUPERB
  - superb
  - Speech processing Universal PERformance Benchmark
  - ML-SUPERB
tags:
  - 类型/对象
  - 方向/AI语音
  - 主题/评测基准
---

# SUPERB（语音处理通用性能基准）

## 0. 背景

**问题现场**：SSL 预训练语音模型大量涌现，各论文用不同下游任务自证，互不可比；需要统一口径回答"这个表示的通用性到底如何"。

**切入点**：固定轻量下游结构、冻结（或轻调）上游表示，在 10 个任务上统一评测并以公开 leaderboard 排名。

## 1. 身份

`SUPERB`（Speech processing Universal PERformance Benchmark）是台大、MIT、Meta AI、JHU、Amazon、CMU 等 2021 年推出的语音自监督表示通用评测基准：固定下游结构、以最小改动评测一个共享预训练模型在多种语音任务上的通用性，并以公开 leaderboard 运作。它是「SSL 表示学习时代」评测语音编码器的标准口径，[[方向/AI语音/模型/HuBERT|HuBERT]]、[[方向/AI语音/模型/WavLM|WavLM]] 等 SSL 模型的排名都以此为主要战场。

## 2. 任务口径

10 个任务分四类（官方口径）：

- **内容（content）**：关键词检测 KS、音素识别 PR、ASR、按例检索 QbE。
- **说话人（speaker）**：说话人识别 SID、说话人验证 ASV、说话人日志 SD。
- **语义（semantic）**：意图分类 IC、槽位填充 SF。
- **副语言（paralinguistic）**：情感识别 ER。

评测方式：冻结（或轻量微调）上游表示 + 统一轻量下游头，权重各层加权和作为表示；总分跨任务汇总排名。

## 3. 数据与扩展

- 原版：英文为主的 10 任务 leaderboard（superbbenchmark.github.io）。
- 扩展版：SUPERB-SG（语义与生成方向加强）、ML-SUPERB（多语言版，覆盖百余语言的 ASR/语种识别单调评测，arXiv:2305.10615）等。

## 4. 使用注意

- 评测对象是 **frozen 表示/编码器**，不是端到端音频大模型；把 SUPERB 分数当作 LALM 能力证据是范畴错误。
- 适合回答「这个 SSL 编码器通用性如何」——即 Omni/LALM 编码侧底座的选型问题（[[方向/AI语音/知识/基础概念/SSL 编码器|SSL 编码器]]）。
- 端到端音频大模型的通用性评测应看 [[方向/AI语音/评估/AudioBench（音频大模型通用基准）|AudioBench]]、[[方向/AI语音/评估/MMAU（大规模多任务音频理解与推理基准）|MMAU]] 这一代。

## 5. 关键来源

- [SUPERB: Speech processing Universal PERformance Benchmark（arXiv:2105.01051）](https://arxiv.org/abs/2105.01051)
  - 内容定位：原始论文（Interspeech 2021），任务定义、评测协议与首批 SSL 模型排名。
  - 用途：任务口径与评测协议依据。
  - 核验日期：2026-08-07
- [SUPERB 官方 leaderboard](https://superbbenchmark.github.io/)
  - 内容定位：持续更新的排行榜与各扩展版入口。
  - 用途：查最新模型排名。
  - 核验日期：2026-08-07
- [ML-SUPERB（arXiv:2305.10615）](https://arxiv.org/abs/2305.10615)
  - 内容定位：多语言扩展版。
  - 用途：多语言表示评测口径。
  - 核验日期：2026-08-07

## 6. 相关对象

- [[方向/AI语音/模型/HuBERT|HuBERT]] / [[方向/AI语音/模型/WavLM|WavLM]]：SUPERB 榜单上的标志性 SSL 模型。
- [[方向/AI语音/评估/HEAR（音频表示整体评估）|HEAR]]：同时期面向全音频（含音乐、环境声）的表示评测。
- [[方向/AI语音/评估/AudioBench（音频大模型通用基准）|AudioBench]] / [[方向/AI语音/评估/MMAU（大规模多任务音频理解与推理基准）|MMAU]]：端到端音频大模型时代的后继基准。
- [[方向/AI语音/MOC - 音频大模型|MOC - 音频大模型]]：方向地图。

## 7. 待验证

- SUPERB 各扩展版（SG/XL/ML）当前是否仍活跃维护、leaderboard 最近更新时间。

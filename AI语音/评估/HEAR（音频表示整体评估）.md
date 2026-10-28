---
title: HEAR（音频表示整体评估）
类型: 评测基准
发表时间: 2021-12-13
时间依据: NeurIPS 2021 竞赛举办日（论文 2022 年 PMLR 发表）
aliases:
  - HEAR
  - hear
  - Holistic Evaluation of Audio Representations
  - HEAR Challenge
tags:
  - 类型/对象
  - 方向/AI语音
  - 主题/评测基准
---

# HEAR（音频表示整体评估）

## 0. 背景

**问题现场**：SUPERB 只覆盖语音，环境声/音乐编码器的跨域通用性没有对应评测；通用音频表示需要"一个表示走天下"的整体检验。

**切入点**：NeurIPS 2021 竞赛形式，19 个下游任务（含 14 个盲测秘密任务）+ 统一 embedding API，专门考泛化而非针对性调参。

## 1. 身份

`HEAR`（Holistic Evaluation of Audio Representations）是 NeurIPS 2021 竞赛形式的通用**音频**表示评测基准（Google 等发起，论文 2022 年发表于 PMLR）。与只覆盖语音的 [[方向/AI语音/评估/SUPERB（语音处理通用性能基准）|SUPERB]] 互补，HEAR 把评测面扩到语音、环境声、音乐等开放音频域，强调「一个表示走天下」的迁移能力。

## 2. 任务口径

- 19 个下游任务，覆盖语音（如 CREMA-D 情感、Speech Commands、VoxLingua）、环境声（如 ESC-50、gunshot triage）、音乐（如 NSynth 音高/乐器、GTZAN 流派）等。
- 竞赛设计：5 个开放任务（数据公开）+ 14 个秘密任务（参赛者完全盲测），专门考验表示的泛化而非针对性调参。
- 评测协议：统一 API（提交模型按 `hear` 接口输出 embedding），用 `heareval` 工具包在低资源下游（浅层/轻量探针）上评估；换模型只需改一行代码。

## 3. 使用注意

- 评测对象是**通用音频表示**（frozen embedding），不是端到端音频大模型；结论用于判断「这个音频编码器跨域迁移能力如何」。
- 低资源下游协议意味着 HEAR 衡量的是表示的即插即用性，而非 fine-tune 后上限。
- 对 LALM 选型场景，HEAR 结论可参考编码侧底座（如 [[方向/AI语音/模型/Qwen-Audio-VAE|Qwen-Audio-VAE]] 类通用表示）的跨域潜力；端到端理解能力看 [[方向/AI语音/评估/AudioBench（音频大模型通用基准）|AudioBench]] / [[方向/AI语音/评估/MMAU（大规模多任务音频理解与推理基准）|MMAU]]。

## 4. 关键来源

- [HEAR: Holistic Evaluation of Audio Representations（arXiv:2203.03022）](https://arxiv.org/abs/2203.03022)
  - 内容定位：竞赛总结论文（PMLR v176），任务设计、评测协议与参赛结果分析。
  - 用途：任务口径与协议依据。
  - 核验日期：2026-08-07
- [HEAR 官方网站](https://hearbenchmark.com/)
  - 内容定位：任务列表、heareval 工具包与榜单入口。
  - 用途：复现与最新任务确认。
  - 核验日期：2026-08-07

## 5. 相关对象

- [[方向/AI语音/评估/SUPERB（语音处理通用性能基准）|SUPERB]]：同时期语音域表示评测，互补关系。
- [[方向/AI语音/知识/基础概念/SSL 编码器|SSL 编码器]]：HEAR 评测的对象类别。
- [[方向/AI语音/评估/AudioBench（音频大模型通用基准）|AudioBench]]：端到端音频 LLM 时代的后继。
- [[方向/AI语音/MOC - 音频大模型|MOC - 音频大模型]]：方向地图。

## 6. 待验证

- heareval 当前维护状态与近年新模型（大模型时代编码器）在 HEAR 上的系统性复测。

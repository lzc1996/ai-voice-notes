---
title: MMSU（口语理解推理基准）
类型: 评测基准
发表时间: 2025-06-05
时间依据: arXiv 首次提交日
aliases:
  - MMSU
  - mmsu
  - Massive Multi-task Spoken Language Understanding and Reasoning Benchmark
tags:
  - 类型/对象
  - 方向/AI语音
  - 主题/评测基准
---

# MMSU（口语理解推理基准）

## 0. 背景

**问题现场**：口语特有信息（韵律、语调、情绪等副语言）的细粒度感知与推理在通用音频基准中被掩盖，缺乏语言学扎根的系统性评测。

**切入点**：5,000 条人工策划问答、47 个任务，按语音学/韵律/修辞/句法/语义/副语言六层组织，专测口语理解与推理。

## 1. 身份

`MMSU`（Massive Multi-task Spoken Language Understanding and Reasoning Benchmark，arXiv:2506.04779）是面向**口语**（spoken language）理解与推理的综合基准，特色是把评测系统性地扎根于语言学现象：语音学、韵律、修辞、句法、语义与副语言——测的不只是「听懂内容」，还有对语调、节奏、情绪等口语特有信息的细粒度感知与推理。

## 2. 任务口径

- **规模**：5,000 条人工策划的音频-问答三元组，47 个任务。
- **语言学分层**：phonetics（语音学）、prosody（韵律）、rhetoric（修辞）、syntactics（句法）、semantics（语义）、paralinguistics（副语言）。
- **评测对象**：SpeechLLM；官方评测 14 个先进模型，结论是现有模型仍有很大提升空间。
- **版本**：v1 2025-06，持续修订（v2 2026-01，v3 2026-03）。

## 3. 使用注意

- 与 [[方向/AI语音/评估/MMAU（大规模多任务音频理解与推理基准）|MMAU]] 的差异：MMSU 只覆盖口语（不含音乐/环境声），但语言学分层更细，适合诊断副语言与韵律维度的短板。
- 与 [[方向/AI语音/评估/SpeechR（语音推理基准）|SpeechR]] 互补：MMSU 偏感知+理解的任务广度，SpeechR 偏推理链质量与声学依赖性。
- 注意题目版本（v1/v2/v3 修订）对分数可比性的影响。

## 4. 关键来源

- [MMSU: A Massive Multi-task Spoken Language Understanding and Reasoning Benchmark（arXiv:2506.04779）](https://arxiv.org/abs/2506.04779)
  - 内容定位：基准论文，5000 题、47 任务、语言学分层与 14 模型评测。
  - 用途：任务口径与结论依据。
  - 核验日期：2026-08-07

## 5. 相关对象

- [[方向/AI语音/评估/SpeechR（语音推理基准）|SpeechR]] / [[方向/AI语音/评估/SAKURA（语音多跳推理基准）|SAKURA]]：口语推理近邻基准。
- [[方向/AI语音/评估/Dynamic-SUPERB（动态语音指令基准）|Dynamic-SUPERB]]：指令型口语模型评测线。
- [[方向/AI语音/知识/技术路线/Audio Reasoning（音频推理）|Audio Reasoning（音频推理）]]：该基准支撑的路线。
- [[方向/AI语音/MOC - 音频大模型|MOC - 音频大模型]]：方向地图。

## 6. 待验证

- 官方数据/评测代码仓库地址与 2026 年新模型成绩。

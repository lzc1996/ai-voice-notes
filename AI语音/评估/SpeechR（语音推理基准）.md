---
title: SpeechR（语音推理基准）
类型: 评测基准
发表时间: 2025-08-04
时间依据: arXiv 首次提交日
aliases:
  - SpeechR
  - speechr
  - SpeechR Benchmark
tags:
  - 类型/对象
  - 方向/AI语音
  - 主题/评测基准
---

# SpeechR（语音推理基准）

## 0. 背景

**问题现场**：现有语音评测集中在转写、情感等表层感知，语境化、推断驱动的语音推理能力缺乏系统测量。

**切入点**：三推理维度（事实检索/程序性推断/规范性判断）× 三评测格式（多选/生成/声学特征），其中声学特征版直接检验推理是否依赖声学线索。

## 1. 身份

`SpeechR`（SpeechR: A Benchmark for Speech Reasoning in Large Audio-Language Models，arXiv:2508.02018，Yanda Li 等）是专测**语音场景推理**的统一基准。其出发点是：现有评测集中在句级转写、情感识别等表层感知，模型在语境化、推断驱动的语音推理上的能力缺乏系统测量。

## 2. 任务口径

- **三个推理维度**：事实检索（factual retrieval）、程序性推断（procedural inference）、规范性判断（normative judgment）。
- **三种评测格式**：
  - 多选版：测答案选择准确率。
  - 生成版：评估推理链的连贯性与逻辑一致性。
  - 声学特征版：考察重音、情绪等声学变化是否影响推理表现——直接测试「推理是否依赖声学线索」。
- **规模**：官方评测了 11 个 SOTA LALM（题目数量以论文为准）。

## 3. 使用注意

- 核心结论：**高转写准确率不等于强推理能力**——与 [[方向/AI语音/评估/SAKURA（语音多跳推理基准）|SAKURA]] 的「感知对但推理接不上」互为印证。
- 声学特征版是独有设计，适合诊断模型是否真利用副语言信息（衔接 [[方向/AI语音/模型/Step-Audio R1|Step-Audio R1]] 的 Textual Surrogate Reasoning 诊断）。
- 覆盖的是口语对话式推理；音乐/环境声深度推理看 [[方向/AI语音/评估/MMAR（音频深度推理基准）|MMAR]]。

## 4. 关键来源

- [SpeechR: A Benchmark for Speech Reasoning in Large Audio-Language Models（arXiv:2508.02018）](https://arxiv.org/abs/2508.02018)
  - 内容定位：基准论文，三维度三格式设计与 11 个 LALM 评测结果。
  - 用途：任务口径与结论依据。
  - 核验日期：2026-08-07

## 5. 相关对象

- [[方向/AI语音/评估/SAKURA（语音多跳推理基准）|SAKURA]] / [[方向/AI语音/评估/MMAR（音频深度推理基准）|MMAR]] / [[方向/AI语音/评估/MMAU（大规模多任务音频理解与推理基准）|MMAU]]：同属音频推理评测线。
- [[方向/AI语音/评估/MMSU（口语理解推理基准）|MMSU]]：口语理解推理的近邻基准。
- [[方向/AI语音/知识/技术路线/Audio Reasoning（音频推理）|Audio Reasoning（音频推理）]]：该基准支撑的路线。
- [[方向/AI语音/MOC - 音频大模型|MOC - 音频大模型]]：方向地图。

## 6. 待验证

- 题目规模、数据构造方式与官方榜单。

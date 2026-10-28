---
title: SAKURA（语音多跳推理基准）
类型: 评测基准
发表时间: 2025-05-19
时间依据: arXiv 首次提交日（Interspeech 2025 收录）
aliases:
  - SAKURA
  - sakura
  - Speech and Audio-based Question-answering Benchmark for Multi-hop Reasoning
tags:
  - 类型/对象
  - 方向/AI语音
  - 主题/评测基准
---

# SAKURA（语音多跳推理基准）

## 0. 背景

**问题现场**：需要把"感知失败"与"推理失败"区分开——音频大模型可能感知到了属性，却接不上基于该属性的后续推理。

**切入点**：四条轨道各设 single-hop 与 multi-hop 对照（共 4000 道多选题），以感知与推理的解耦测量诊断多跳推理能力。

## 1. 身份

`SAKURA`（Speech and Audio-based Question-answering Benchmark for Multi-hop Reasoning of Large Audio-Language Models，arXiv:2505.13237，Interspeech 2025）是系统考察音频大模型**多跳推理**的基准：模型必须先感知语音/音频属性，再基于这些线索做进一步推理。论文核心结论是现有 LALM 的多跳推理明显不足——它们常在「感知对了但推理接不上」处失败。

## 2. 任务口径

- **四条轨道**：说话人性别、所说语言、说话人情绪、动物声音。
- **单跳 vs 多跳**：每条轨道分 single-hop（直接感知属性，如「声音里是什么动物？」）与 multi-hop（基于感知结果再推理，如「该动物的哪个外形特征与选项最符？」）两个子轨。
- **规模**：每子轨 500 道多选题，共 4000 道人工核验多选题。
- **设计意图**：single-hop 与 multi-hop 的对照可以把「感知失败」与「推理失败」区分开。

## 3. 使用注意

- 适合诊断模型是否真的把听觉线索**保持并用于后续推理**，而不是感知完就丢。
- 轨道集中在四类属性，覆盖面比 [[方向/AI语音/评估/MMAU（大规模多任务音频理解与推理基准）|MMAU]] 窄，但测量更可控。
- 常被用作「语音指令理解 → 推理」过渡带（perception → reasoning bridge）的测量工具，见 [[方向/AI语音/知识/技术路线/Audio Reasoning（音频推理）|Audio Reasoning（音频推理）]]。

## 4. 关键来源

- [SAKURA: On the Multi-hop Reasoning of Large Audio-Language Models Based on Speech and Audio Information（arXiv:2505.13237）](https://arxiv.org/abs/2505.13237)
  - 内容定位：基准论文（Interspeech 2025），四轨道设计、单跳/多跳对照与 LALM 多跳失败分析。
  - 用途：任务口径与结论依据。
  - 核验日期：2026-08-07
- [SAKURA 官方 GitHub](https://github.com/b08202033/SAKURA)
  - 内容定位：数据与评测代码。
  - 用途：跑评测入口。
  - 核验日期：2026-08-07

## 5. 相关对象

- [[方向/AI语音/评估/MMAU（大规模多任务音频理解与推理基准）|MMAU]] / [[方向/AI语音/评估/MMAR（音频深度推理基准）|MMAR]]：同属音频推理评测线。
- [[方向/AI语音/模型/Step-Audio R1|Step-Audio R1]]：以多跳/推理类基准验证的推理模型。
- [[方向/AI语音/知识/技术路线/Audio Reasoning（音频推理）|Audio Reasoning（音频推理）]]：该基准支撑的路线。
- [[方向/AI语音/MOC - 音频大模型|MOC - 音频大模型]]：方向地图。

## 6. 待验证

- 题目语言分布（中英占比）与新版模型在 multi-hop 子轨上的最新差距。

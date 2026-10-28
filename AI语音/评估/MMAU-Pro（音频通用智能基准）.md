---
title: MMAU-Pro（音频通用智能基准）
类型: 评测基准
发表时间: 2025-08-19
时间依据: arXiv 首次提交日
aliases:
  - MMAU-Pro
  - mmau-pro
  - MMAU Pro
tags:
  - 类型/对象
  - 方向/AI语音
  - 主题/评测基准
---

# MMAU-Pro（音频通用智能基准）

## 0. 背景

**问题现场**：[[方向/AI语音/评估/MMAU（大规模多任务音频理解与推理基准）|MMAU]] 之后头部模型分数迅速饱和，长音频、空间音频、多音频组合等复杂维度仍未覆盖。

**切入点**：同团队升级版——5,305 个野外音频实例、49 项技能、全部要求多跳推理，增加多选与开放题，自称当时最全面的音频通用智能评测。

## 1. 身份

`MMAU-Pro`（MMAU-Pro: A Challenging and Comprehensive Benchmark for Holistic Evaluation of Audio General Intelligence，arXiv:2508.13992）是 [[方向/AI语音/评估/MMAU（大规模多任务音频理解与推理基准）|MMAU]] 同团队（马里兰大学等）2025 年 8 月推出的全面升级版，自称当时最全面、策划最严格的音频智能评测，目标是把测量推向「音频通用智能」。

## 2. 任务口径

- **规模**：5,305 个实例，每个实例含 1 条或多条音频 + 专家撰写的问答对。
- **域与技能**：speech、sound、music 及其组合，覆盖 **49 项独特技能**。
- **新增难度维度**：长音频理解、空间音频推理、多音频理解等原版未覆盖的复杂维度。
- **题型**：多选 + 开放式回答，全部题目要求多跳推理。
- **数据**：音频直接来自「野外」（非已知分布的现成数据集），降低数据泄漏与过拟合风险。

## 3. 基线与结果

官方评测 22 个领先开源/闭源多模态模型：最强的 Gemini 2.5 Flash 仅 59.2%，Audio Flamingo 3 为 51.7%，多个类别接近随机水平——头部模型在该基准上仍有明显天花板。

## 4. 使用注意

- 与原版 MMAU 的关系：更难、更广，含开放题；两者数字不可直接比。
- 适合作为新一代旗舰模型（Gemini 系、Qwen-Omni 系、Audio Flamingo 系）的区分度测量；老模型容易集体垫底。
- 开放题部分需要评分协议（人工或模型判分），复现时注意口径。

## 5. 关键来源

- [MMAU-Pro: A Challenging and Comprehensive Benchmark for Holistic Evaluation of Audio General Intelligence（arXiv:2508.13992）](https://arxiv.org/abs/2508.13992)
  - 内容定位：基准论文，5305 实例、49 技能、22 模型评测与失败分析。
  - 用途：任务口径与头部模型数字依据。
  - 核验日期：2026-08-07

## 6. 相关对象

- [[方向/AI语音/评估/MMAU（大规模多任务音频理解与推理基准）|MMAU]]：原版基准。
- [[方向/AI语音/评估/MMAR（音频深度推理基准）|MMAR]] / [[方向/AI语音/评估/SAKURA（语音多跳推理基准）|SAKURA]]：同属音频推理评测线。
- [[方向/AI语音/知识/技术路线/Audio Reasoning（音频推理）|Audio Reasoning（音频推理）]]：该基准支撑的路线。
- [[方向/AI语音/MOC - 音频大模型|MOC - 音频大模型]]：方向地图。

## 7. 待验证

- 官方 leaderboard 地址与 2026 年新模型（Gemini 3 系、Step-Audio R1.5 等）成绩。

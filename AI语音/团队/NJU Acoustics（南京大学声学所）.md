---
title: NJU Acoustics（南京大学声学所）
类型: 团队
aliases:
  - 南京大学声学所
  - NJU Acoustics
  - NJU-Horizon
  - Jing Lu 组
tags:
  - 类型/对象
  - 方向/AI语音
  - 任务/语音增强
---

# NJU Acoustics（南京大学声学所）

## 1. 身份

南京大学声学研究所（Jing Lu 卢晶组，含 Xiaobin Rong 等），URGENT 挑战赛 2024–2026 连续参赛并走完"判别式 → 生成式 → 融合式"完整演进的团队。单通道/通用增强为主，是 [[方向/AI语音增强/README|本方向目标场景]] 的"大模型增强技术源"必跟团队。

## 2. 代表作

- **URGENT 参赛系统线**：TS-URGENet（URGENT 2025 优胜，三阶段预测式）→ [[方向/AI语音/模型/UniPASE|UniPASE]]（perceptual tokenizer 表示回归）→ [[方向/AI语音/模型/GAP-URGENet|GAP-URGENet]]（URGENT 2026 Track 1 objective 第一，生成-预测融合）。
- **[[方向/AI语音/模型/L3-SE|L3-SE]]**（与小米 MiLM Plus 合作，2026）：noise-invariant acoustic-semantic distillation 降 LM 增强的语言幻觉（[arXiv](https://arxiv.org/html/2605.08608v1)）——作者 Xiaobin Rong、Tianyi Tan（NJU）+ Hang Su 等（MiLM Plus）、通讯 Jing Lu。
- **GTCRN**：48.2K 参数超轻量单通道增强（[GitHub](https://github.com/Xiaobin-Rong/gtcrn)）；DPDFNet 等轻量线。

## 3. 与阵列团队的交叉

- 本身不做阵列/多通道研究（URGENT 主线是单通道通用增强）；其 GAP-URGENet 的预测分支用 TF-GridNet（[[方向/AI语音/团队/Z.-Q. Wang Group（Zhong-Qiu Wang 组）|Z.-Q. Wang 组]] 的多通道基线架构的单通道用法）——属"方法借用"级交叉。
- 与小米 MiLM Plus 有稳定产学合作（L3-SE）。

## 4. 可信度依据

- URGENT 2026 客观指标第一 + 连续多届头部，挑战赛验证硬。
- 数据筛选方法论（2500h 精选 700h）影响 URGENT 官方基线。
- 开源好（GTCRN 等）。

## 5. 相关笔记

- [[方向/AI语音/知识/调研与地图/Array Speech Enhancement Team Map（阵列增强团队地图）|阵列增强团队地图]]
- [[方向/AI语音/评估/URGENT（通用语音增强挑战）|URGENT]]

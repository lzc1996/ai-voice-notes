---
title: Audio-WestlakeU（西湖大学音频实验室）
类型: 团队
aliases:
  - 西湖大学音频实验室
  - Westlake 音频组
  - Audio-WestlakeU
tags:
  - 类型/对象
  - 方向/AI语音
  - 任务/语音增强
  - 任务/多通道增强
---

# Audio-WestlakeU（西湖大学音频实验室）

## 1. 身份

西湖大学音频方向实验室（GitHub 组织 audio-westlakeu），国内做在线/流式多通道语音增强最集中的团队，工程可复现性强。

## 2. 代表作

- **[[方向/AI语音/模型/McNet|McNet 系列]]**：在线多通道语音增强框架。
- **[[方向/AI语音/模型/McNet|Mel-McNet]]**（Interspeech 2025）：把多通道 STFT 压缩到 Mel 域，计算量降低 60%，输出 enhanced LogMel 供 ASR 使用；本质仍是多通道增强，不是 ASR 模型（[GitHub](https://github.com/audio-westlakeu/mel-mcnet)）。
- **生成式/概率模型线（阵列团队里生成式积累较系统的一家）**：RVAE-EM（ICASSP 2024，循环 VAE + CTF 生成式去混响，[GitHub](https://github.com/Audio-WestlakeU/RVAE-EM)）、VINP（变分贝叶斯 + 神经语音先验，联合去混响与盲 RIR 辨识，[arXiv](https://arxiv.org/html/2502.07205)）、[[方向/AI语音/模型/CleanMel|CleanMel]]（Mel 谱增强兼顾质量与 ASR，[GitHub](https://github.com/Audio-WestlakeU/CleanMel)）。
- **与 USTC-NERCSLIP 的合作**：[[方向/AI语音/模型/PGUSE|PGUSE]]（预测-生成融合 monaural universal SE）——作者 Jie Zhang、Haoyin Yan（NERC-SLIP）+ Xiaofei Li（西湖），是"阵列团队 × LM 增强团队"的直接合作案例。

## 3. 可信度依据

- 开源维护好（代码、配置齐全），可复现性强。
- 方向聚焦：流式多通道增强 + 面向 ASR 的高效前端，与工业需求对齐。

## 4. 相关笔记

- [[方向/AI语音/知识/调研与地图/Array Speech Enhancement Team Map（阵列增强团队地图）|阵列增强团队地图]]
- [[方向/AI语音/知识/调研与地图/Array Speech Enhancement Frontier（阵列语音增强前沿调研）|阵列语音增强前沿调研]]

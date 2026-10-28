---
title: Meta Audio AI（Meta 音频 AI 团队）
类型: 团队
aliases:
  - Meta 音频 AI 团队
  - Meta Audio AI
  - Ashutosh Pandey
  - Meta Reality Labs Audio
tags:
  - 类型/对象
  - 方向/AI语音
  - 任务/语音增强
  - 任务/多通道增强
---

# Meta Audio AI（Meta 音频 AI 团队）

## 1. 身份

Meta 的音频 AI 研究团队（Ashutosh Pandey 等 + Reality Labs 音频方向），多通道增强工程导向最强的团队之一，研究直接对准穿戴与消费级产品形态。

## 2. 代表作

- **Ad-hoc 阵列时域增强**（Interspeech 2022）：分布式/ad-hoc 麦克风阵列 DNN 增强的常用基线（TAC 模块出处）。
- **Ultra low-compute complex spectral masking**（ICASSP 2025，Pandey & Azcarreta）：多通道增强的超低算力复数掩码方案。
- **Spatial-Magnifier**（Interspeech 2026）：多通道"空间上采样"，从少量麦克风恢复接近全阵列 oracle 性能（[arXiv](https://arxiv.org/abs/2605.04749)）。
- **[[方向/AI语音/模型/Cloud-Boosted MC-SE（云端增强低算力多通道增强）|Cloud-Boosted MC-SE]]**（Interspeech 2026）：云-边协同增强——服务器延迟输出 + 逐层特征提升 + 协同 MWF（[arXiv](https://arxiv.org/abs/2608.07423)）。
- **[[方向/AI语音/模型/HyBeam|HyBeam]]**（与 Ben-Gurion 大学合作）：穿戴式 array-agnostic 增强（[arXiv](https://arxiv.org/abs/2510.22637)）。
- ~~ArrayDPS 系列~~（2026-08 更正：ArrayDPS / ArrayDPS-Refine / Uni-ArrayDPS 实为 [[方向/AI语音/团队/UIUC SiNRG（UIUC 信号推断研究组）|UIUC SiNRG]] × Z.-Q. Wang 的工作，与 Meta 无关；Meta 的 TADRN/[[方向/AI语音/模型/FaSNet（滤波求和网络）|FaSNet]]-TAC 在论文中只是被精修的判别式基线）。

## 3. 可信度依据

- 方法成为公共基线：TAC 模块是分布式阵列增强的标准组件。
- 方向卡位准且成体系：少麦设备、穿戴形态、生成式精修三条 2026 年主线都有代表作。
- 研究与产品（Reality Labs 眼镜/耳机）同源。

## 4. 相关笔记

- [[方向/AI语音/知识/调研与地图/Array Speech Enhancement Team Map（阵列增强团队地图）|阵列增强团队地图]]
- [[方向/AI语音/知识/调研与地图/Array Speech Enhancement Frontier（阵列语音增强前沿调研）|阵列语音增强前沿调研]]
- [[方向/AI语音/模型/ArrayDPS-Refine|ArrayDPS-Refine]]
- [[方向/AI语音/模型/HyBeam|HyBeam]]

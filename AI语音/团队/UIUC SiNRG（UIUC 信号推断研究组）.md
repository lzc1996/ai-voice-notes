---
title: UIUC SiNRG（UIUC 信号推断研究组）
类型: 团队
aliases:
  - UIUC SiNRG
  - Signals Inference Research Group
  - Romit Roy Choudhury 组
  - Zhongweiyang Xu
tags:
  - 类型/对象
  - 方向/AI语音
  - 任务/语音增强
  - 任务/多通道增强
---

# UIUC SiNRG（UIUC 信号推断研究组）

## 1. 身份

伊利诺伊大学厄巴纳-香槟分校（UIUC）Signals Inference Research Group（Romit Roy Choudhury 组，[主页](https://sinrg.csl.illinois.edu/publications)），以移动/感知系统见长的实验室，近年在"扩散先验解阵列逆问题"方向产出 ArrayDPS 系列，与 [[方向/AI语音/团队/Z.-Q. Wang Group（Zhong-Qiu Wang 组）|Z.-Q. Wang（OSU）]] 稳定合作。

## 2. 代表作

- **ArrayDPS**（ICML 2025）：无监督、array-agnostic 的扩散先验盲语音分离（Zhongweiyang Xu, Xulin Fan, Zhong-Qiu Wang, Xilin Jiang, R. R. Choudhury，[PMLR](https://proceedings.mlr.press/v267/xu25f.html)、[GitHub](https://github.com/ArrayDPS/ArrayDPS)）。
- **[[方向/AI语音/模型/ArrayDPS-Refine|ArrayDPS-Refine]]**（ICASSP 2026）：training-free 扩散精修任意判别式多通道增强输出（[arXiv](https://arxiv.org/abs/2603.24385)）。
- **Uni-ArrayDPS**：增强 + 分离统一的扩散精修框架。
- **Unsupervised Multi-channel Speech Dereverberation via Diffusion**（WASPAA 2025，Yulun Wu, Zhongweiyang Xu, Jianchong Chen, Zhong-Qiu Wang, R. R. Choudhury）。

## 3. 与阵列团队的交叉

- 与 Z.-Q. Wang（OSU）是固定合作班底（ArrayDPS 三篇 + WASPAA 2025 均共同署名）。
- 方法上把单通道扩散先验（DPS/DDRM 一脉，StoRM、Diffiner 为其单通道前驱）引入多通道盲逆问题——是"生成式团队 × 阵列团队"交叉的样板。

## 4. 可信度依据

- ICML/ICASSP/WASPAA 连续命中，代码与 demo 开放。
- 范式开创性：training-free、array-agnostic 的生成式多通道精修，2026 年被广泛跟进。

## 5. 相关笔记

- [[方向/AI语音/知识/调研与地图/Array Speech Enhancement Team Map（阵列增强团队地图）|阵列增强团队地图]]
- [[方向/AI语音/知识/调研与地图/Array Speech Enhancement Frontier（阵列语音增强前沿调研）|阵列语音增强前沿调研]]

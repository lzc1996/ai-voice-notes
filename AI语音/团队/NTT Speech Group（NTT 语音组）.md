---
title: NTT Speech Group（NTT 语音组）
类型: 团队
aliases:
  - NTT 语音组
  - NTT Speech Lab
  - Marc Delcroix
  - Tomohiro Nakatani
tags:
  - 类型/对象
  - 方向/AI语音
  - 任务/语音增强
  - 任务/多通道增强
---

# NTT Speech Group（NTT 语音组）

## 1. 身份

日本 NTT 通信科学实验室的语音研究团队（Marc Delcroix、Tomohiro Nakatani 等），工业界实验室但完全按学界方式产出，远场多通道语音增强与识别系统工程的标杆。

## 2. 代表作

- **WPE 去混响**（Nakatani 等）：Weighted Prediction Error 去混响，多通道前端的标准组件之一。
- **CHiME 多次冠军系统**：CHiME-8 DASR 达 22.0% tcpWER（[slides](https://www.chimechallenge.org/workshops/chime2024/papers/11_slides.pdf)）；TS-VAD 说话人日志也是该组代表作。
- **Loose Coupling of Spectral and Spatial Models**（与 Paderborn 合作，ICASSP 2026，[arXiv](https://arxiv.org/abs/2601.16077)）。
- **MIMO 生成式增强（与阵列团队交叉的直接证据）**：mSGMSE——*Diffusion model-based MIMO speech denoising and dereverberation*（ICASSPW 2024，Kimura、Nakatani、Kamo、Delcroix、Araki、Ueda、Makino）；*Multi-stream diffusion model for probabilistic integration of model-based and data-driven speech enhancement*（IWAENC 2024）；**DiffCBF**——扩散 + 卷积波束形成的联合分离/去噪/去混响（EUSIPCO 2025）。NTT 是阵列团队中生成式布局最系统的。

## 3. 可信度依据

- 挑战赛名次：CHiME 系列多次冠军，最硬的公开验证。
- 方法成为公共组件：WPE、TS-VAD 被广泛复用。
- 系统工程极扎实，参赛系统的工程细节公开充分。

## 4. 相关笔记

- [[方向/AI语音/知识/调研与地图/Array Speech Enhancement Team Map（阵列增强团队地图）|阵列增强团队地图]]
- [[方向/AI语音/知识/调研与地图/Array Speech Enhancement Frontier（阵列语音增强前沿调研）|阵列语音增强前沿调研]]

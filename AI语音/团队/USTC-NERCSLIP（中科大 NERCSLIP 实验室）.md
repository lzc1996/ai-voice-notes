---
title: USTC-NERCSLIP（中科大 NERCSLIP 实验室）
类型: 团队
aliases:
  - 中科大 NERCSLIP
  - USTC-NERCSLIP
  - NERCSLIP
  - NELSLIP
  - 语音及语言信息处理国家工程研究中心
  - 中国科大语音实验室
tags:
  - 类型/对象
  - 方向/AI语音
  - 任务/语音增强
  - 任务/多通道增强
---

# USTC-NERCSLIP（中科大 NERCSLIP 实验室）

## 1. 身份

中国科学技术大学**语音及语言信息处理国家工程研究中心**（NERC-SLIP，前身为国家工程实验室 NELSLIP）。中心主任刘庆峰，USTC 侧学术带头人杜俊教授（与 Chin-Hui Lee 长期合作），见[中心师资页](https://nelslip.ustc.edu.cn/26916/list.htm)。与科大讯飞联合组队打 CHiME 系列，已连续六届夺冠（截至 2026 CHiME-9）。

**定位（2026-08 核实）：ASR / 日志 / 多模态识别为主线，但具备自研增强/分离全栈能力**——增强以"挑战赛系统前端 + 前端-ASR 联合训练"形式出现，是其特色而非外包。

## 2. 阵列增强相关工作

- **DNN 语音增强奠基论文之一**：Xu, Du, Dai, Lee, *A regression approach to speech enhancement based on DNNs*, IEEE/ACM TASLP 2015（杜俊为共同作者）。
- **CHiME-5/6**：自研两阶段说话人相关分离（SD-SS）与 MGSS/BGSS 前端。
- **CHiME-7 DASR**（2023，[arXiv](https://ar5iv.labs.arxiv.org/html/2308.14638)）：自研 SE 模块与 SSLR/说话人识别/ASR 联合微调，自研 SINR 通道选择、cACGMM 空间信息修正。
- **CHiME-8 NOTSOFAR-1**（2024，[arXiv](https://pdf.arxiv.org/pdf/2409.02041)）：前端数据驱动联合训练；配套 *Incorporating Spatial Cues in Modular Speaker Diarization*（ICASSP 2025）——重叠段自研多通道 CSS，非重叠段波束形成。
- **音视频增强**：Neural Networks 2021 的 embedding-aware 音视频增强双塔架构，被 CHiME-9 直接沿用。
- **CHiME-9 [[方向/AI语音/评估/MCoRec（多模态上下文识别）|MCoRec]] 冠军**（2026，[arXiv](https://arxiv.org/abs/2603.01415)）：**四套全自研 AVTSE 系统**（BRAVEn 编码器 + Conformer/IRM、全脸三模态、TSE-ASR 联合优化、音视频双塔），并实测 AV-Speformer/USEV/SeaNet 等外部提取方案在该场景反而降性能。
- **独立分离论文**：Han, Chen, Wang, Du et al., *Hierarchical Contrastive Learning with Speech Language Model for Separating Similar Speakers*, ICASSP 2026。
- **NERC-SLIP 的 LM 增强线（2026-08 补查，修正"只做 ASR"的印象）**：Jie Zhang、Haoyin Yan 等在单通道通用/LM 增强方向有持续产出——[[方向/AI语音/模型/PGUSE|PGUSE]]（预测-生成融合，与西湖大学 Xiaofei Li 合作）、[[方向/AI语音/模型/UniSE（Unified Speech Enhancement）|UniSE]]（Interspeech 2026，decoder-only LM 统一增强/提取/分离，一作 Haoyin Yan）。即该实验室内部同时存在 ASR 主线与 LM 增强线。

## 3. 可信度依据

- 挑战赛名次最硬：CHiME 连续六届冠军，且 CHiME-7/8/9 前端（CSS、cACGMM 修正、AVTSE）均为自研模块。
- 增强能力体现在"前端-ASR 联合训练"的系统工程上，独立增强论文近年较少但存在。

## 4. 相关笔记

- [[方向/AI语音/知识/调研与地图/Array Speech Enhancement Team Map（阵列增强团队地图）|阵列增强团队地图]]
- [[方向/AI语音/知识/调研与地图/Array Speech Enhancement Frontier（阵列语音增强前沿调研）|阵列语音增强前沿调研]]

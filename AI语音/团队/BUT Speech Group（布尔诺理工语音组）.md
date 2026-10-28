---
title: BUT Speech Group（布尔诺理工语音组）
类型: 团队
aliases:
  - 布尔诺理工语音组
  - BUT Speech@FIT
  - BUT Speech Group
  - Brno University of Technology Speech Group
tags:
  - 类型/对象
  - 方向/AI语音
  - 任务/语音增强
  - 任务/多通道增强
---

# BUT Speech Group（布尔诺理工语音组）

## 1. 身份

布尔诺理工大学（Brno University of Technology, FIT）语音组，捷克老牌语音实验室。

**定位（2026-08 核实）：以 ASR / 说话人日志为主的团队**，不是增强大组。但存在一条小而明确的目标说话人提取（TSE）研究线（Kateřina Žmolíková 与 NTT 合作产出），成果集中在 2017–2022 年，近年重心已回到日志（VBx、EEND 变体）与长音频 AV-ASR。

## 2. 阵列增强相关工作

- Žmolíková et al., *Speaker-aware neural network based beamformer for speaker extraction*, Interspeech 2017：TSE 引导的波束形成。
- **SpeakerBeam**（与 NTT Delcroix 合作，ICASSP 2018 / IEEE JSTSP 2019）：目标说话人提取的高被引代表作（[JSTSP 版](https://www.fit.vut.cz/research/group/speech/public/publi/2019/zmolikova_IEEEjournal2019_08736286.pdf)）。
- Time-domain SpeakerBeam（ICASSP 2020，[arXiv](https://arxiv.org/pdf/2001.08378)）；TSE 辅助损失（Interspeech 2021）；*Listen only to me!*（Interspeech 2022，TSE 误触发问题）。
- **Clarity CEC1 参赛系统**（2021）：[[方向/AI语音/知识/基础概念/MVDR（最小方差无失真响应）|MVDR]]（CGMM 掩码）+ 因果 ConvTasNet 后增强——BUT 少有的独立增强系统参赛记录（[论文](https://claritychallenge.org/clarity2021-workshop/papers/Clarity_2021_CEC1_paper_final_zmolikova.pdf)）。

## 3. CHiME 参赛系统的增强前端来源

- CHiME-6：官方基线前端（WPE + 波束形成），重心在 VBx 日志与声学模型。
- CHiME-7 DASR：明确"heavily relied on [[方向/AI语音/知识/基础概念/GSS（引导源分离）|GSS]]"，用 Paderborn/fgnt 的**外部** GSS 工具，非自研。
- CHiME-9 [[方向/AI语音/评估/MCoRec（多模态上下文识别）|MCoRec]]（2026，[arXiv](https://arxiv.org/abs/2604.27436)）：**没有独立增强/提取模块**——提出长上下文 AV-TS-ASR，把提取隐式做进 ASR（Parakeet-v2 用 AV-HuBERT 视觉表征条件化，单次解码整段录音）。

## 4. 可信度依据

- 收录理由从"增强团队"修正为：**TSE 高被引方法（SpeakerBeam 谱系）+ 日志/ASR 强组**；看他们的论文应重点看日志与 AV-ASR，增强前端不必跟踪。

## 5. 相关笔记

- [[方向/AI语音/数据集/BUT ReverbDB]]：BUT Speech@FIT 发布的真实 RIR / 噪声 / 重放语音数据集。
- [[方向/AI语音/知识/调研与地图/Array Speech Enhancement Team Map（阵列增强团队地图）|阵列增强团队地图]]
- [[方向/AI语音/知识/调研与地图/Array Speech Enhancement Frontier（阵列语音增强前沿调研）|阵列语音增强前沿调研]]

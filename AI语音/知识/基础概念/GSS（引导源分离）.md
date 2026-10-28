---
title: GSS（引导源分离）
类型: 方法
发表时间: 2018
时间依据: CHiME 2018 workshop 论文发表年份
相关任务:
  - 语音分离
  - ASR
相关主题:
  - 阵列信号
  - 远场语音
相关模型:
  - "[[方向/AI语音/模型/TF-GridNet]]"
相关评估:
  - "[[方向/AI语音/评估/CHiME（语音分离与识别挑战赛）]]"
  - "[[方向/AI语音/评估/NOTSOFAR-1（远场会议转写挑战）]]"
aliases:
  - 引导源分离（GSS）
  - GSS
  - 引导源分离
  - gss
tags:
  - 类型/对象
  - 方向/AI语音
  - 任务/语音分离
  - 任务/ASR
  - 主题/阵列信号
  - 主题/远场语音
---

# GSS（引导源分离）

## 1. 身份

`GSS` 是 Guided Source Separation，用说话人活动信息 / diarization 结果去引导多通道盲源分离，常作为远场会议 ASR 系统里的前端增强模块。

边界：GSS 不是单独的 ASR 模型，也不是纯 [[方向/AI语音/知识/基础概念/SE（语音增强）导论|语音增强]] benchmark。它的价值通常通过下游 WER / DA-WER / tcpWER 体现；输出听起来是否最自然不是它的主要评价口径。

## 2. 核心机制

- **输入**：多通道会议音频 + 预先估计的 speaker activity / diarization。
- **引导点**：用 diarization 约束说话人数、活动区间和频率 bin 之间的 speaker permutation，避免完全 blind BSS 不稳定。
- **分离前端**：基于 BSS / 空间混合模型估计每个目标说话人的时频 mask。
- **波束形成**：用 mask 估计空间协方差，再接 [[方向/AI语音/知识/基础概念/MVDR（最小方差无失真响应）|MVDR]] / beamforming 输出目标说话人流。
- **常见组合**：[[方向/AI语音/知识/基础概念/WPE（加权预测误差）|WPE]] dereverberation → GSS → beamforming → ASR。

## 3. 和相邻方法的区别

| 方法 | 核心差异 |
|---|---|
| Blind Source Separation | GSS 不是完全盲分离；它依赖 diarization / speaker activity 引导。 |
| [[方向/AI语音/知识/基础概念/Beamforming（波束形成）]] | beamforming 是空间滤波器；GSS 更像“用 diarization 估 mask / SCM，再交给 beamformer”。 |
| [[方向/AI语音/知识/基础概念/TSE（目标说话人提取）]] | TSE 通常用 enrollment / speaker cue 指定目标；GSS 通常用会议 diarization 活动区间指定目标。 |
| 神经 CSS / separation | GSS 传统上不是监督学习方法，不能直接吃大规模仿真训练集；现代挑战赛常把它作为强基线或补充分支。 |

## 4. 使用判断

- 适合：远场多通道会议转写、稀疏重叠说话、已有较好 diarization 的场景。
- 不适合：只看主观音质、实时超低延迟、缺少可靠 speaker activity、阵列几何 / 同步很差的场景。
- 风险：diarization 错会直接引导错分离；计算量也曾是主要瓶颈，后续 GPU 版主要解决这个问题。

## 5. 关键来源

- [Front-end processing for the CHiME-5 dinner party scenario](https://www.isca-archive.org/chime_2018/boeddecker18_chime.html)
  - 内容定位：CHiME-5 前端论文，提出把 blind source separation 适配为 Guided Source Separation，并与 WPE / beamforming 组合降低 WER。
  - 用途：GSS 原始出处和发表时间依据。
  - 核验日期：2026-08-05
- [GPU-accelerated Guided Source Separation for Meeting Transcription](https://arxiv.org/abs/2212.05271)
  - 内容定位：把 GSS 定义为依赖预计算 speaker activities 和 BSS 的 target-speaker extraction 方法，并给出 GPU 加速实现。
  - 用途：理解 GSS 的工程瓶颈、加速方向和会议转写复现链路。
  - 核验日期：2026-08-05
- [CHiME-8 Task 2 - NOTSOFAR](https://www.chimechallenge.org/challenges/chime8/task2/index)
  - 内容定位：说明 CHiME-7 DASR 参赛者主要依赖 GSS，并用 NOTSOFAR-1 推动 data-driven separation / enhancement 前端。
  - 用途：理解 GSS 在 CHiME-7/8 远场会议转写中的基线地位。
  - 核验日期：2026-08-05
- [The IACAS-Thinkit System for CHiME-7 Challenge](https://www.isca-archive.org/chime_2023/ye23_chime.html)
  - 内容定位：CHiME-7 系统论文，把 TS-VAD diarization、GSS multi-channel separation 和 WavLM ASR 串成完整远场转写系统。
  - 用途：观察 GSS 在现代 CHiME 系统里的位置。
  - 核验日期：2026-08-05

## 6. 相关对象

- [[方向/AI语音/评估/CHiME（语音分离与识别挑战赛）|CHiME]]：GSS 是 CHiME-5/6/7/8 DASR 系统常见前端。
- [[方向/AI语音/评估/NOTSOFAR-1（远场会议转写挑战）|NOTSOFAR-1]]：GSS 是上一代 CHiME DASR 强基线，NOTSOFAR-1 试图推动 data-driven 前端替代或补充它。
- [[方向/AI语音/知识/基础概念/SS（语音分离）|SS]]：GSS 属于会议语音分离 / 目标说话人流提取路线。
- [[方向/AI语音/知识/基础概念/Beamforming（波束形成）|Beamforming]]、[[方向/AI语音/知识/基础概念/MVDR（最小方差无失真响应）|MVDR]]：GSS 常为 beamforming 提供 mask / SCM。
- [[方向/AI语音/知识/基础概念/VAD（Voice Activity Detection）|VAD]]、[[方向/AI语音/知识/基础概念/TSE（目标说话人提取）|TSE]]：GSS 依赖说话人活动信息，和目标说话人前端紧密相关。

## 7. 待验证

- 在本地会议样本上，GSS 与神经 CSS / [[方向/AI语音/模型/TF-GridNet|TF-GridNet]] / NOTSOFAR data-driven baseline 的 tcpWER 差异。
- GPU GSS recipes 是否足够稳定复现 [[方向/AI语音/数据集/AMI Meeting Corpus（会议语料库）]] / AliMeeting / LibriCSS 结果。

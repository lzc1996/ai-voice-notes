---
title: DNS Challenge（深度噪声抑制挑战）
类型: 评测基准
aliases:
  - DNS Challenge
  - Deep Noise Suppression Challenge
  - DNS挑战赛
  - 深度噪声抑制挑战
  - Microsoft DNS Challenge
tags:
  - 类型/对象
  - 方向/AI语音
  - 任务/语音增强
  - 基准/语音增强
---

# DNS Challenge（深度噪声抑制挑战）

## 0. 背景

**问题现场**：实时通话降噪在 2020 年前后从传统 DSP 转向深度学习，但缺少统一的大规模数据、baseline 与评测协议。

**切入点**：Microsoft 组织的公开挑战赛系列：数据 + baseline + 规则 + P.835 主观评测/DNSMOS 工具链打包发布，成为通信语音增强的标准 benchmark 入口。

## 1. 身份

`DNS Challenge`（Deep Noise Suppression Challenge，深度噪声抑制挑战）是 Microsoft 组织的语音增强/噪声抑制公开挑战赛与 benchmark 系列。官方仓库提供挑战脚本、模型、训练/测试相关文件、DNSMOS 工具和历届资料入口。

边界：DNS Challenge 不是单一模型，也不只是一个数据集。它更像通信语音增强 benchmark：由数据、baseline、规则、主观/客观指标和参赛系统共同构成。

## 2. 用途

- 实时通话、会议、语音 Agent 前端的噪声抑制 / speech enhancement benchmark。
- 获取噪声、RIR、clean speech、blind test、baseline 和 DNSMOS 等评测工具线索。
- 作为 [[方向/AI语音增强/README|AI 语音增强]] 从经典小基准走向真实通信场景评测的过渡入口。
- 和 [[方向/AI语音/评估/URGENT（通用语音增强挑战）|URGENT]] 对照：DNS 更偏通信降噪/实时语音增强，URGENT 更偏 universal SE 的多语言、多失真泛化。

## 3. 届次脉络

- Interspeech 2020：早期 DNS Challenge 入口，聚焦 deep noise suppression。
- ICASSP 2021 / 2022：继续围绕实时 deep noise suppression、P.835 主观评测和个性化/全带宽等方向扩展。
- ICASSP 2023：官方资料称这一届为 DNS Challenge 5，关注 suppress background noise、reverberation、neighboring talkers，并提升 speech signal quality。

## 4. 评估口径

- 主观评测：DNS 系列常用 ITU-T P.835 风格，把语音信号质量、背景噪声质量和总体质量分开看。
- 自动指标：DNSMOS / [[方向/AI语音/评估/OVRL_MOS|OVRL_MOS]] 是 DNS 系列的重要自动化代理指标。
- 参考指标：[[方向/AI语音/评估/PESQ|PESQ]]、[[方向/AI语音/评估/STOI 与 ESTOI|STOI / ESTOI]]、[[方向/AI语音/评估/SI-SDR|SI-SDR]] 可做补充，但不能单独代表真实通话听感。

## 5. 使用注意

- 不要把 DNS Challenge 简化成“DNSMOS 分数”。挑战本身包含数据、规则、盲测、主观听测和参赛系统。
- 和 [[方向/AI语音/数据集/VoiceBank-DEMAND|VoiceBank-DEMAND]] 相比，DNS 更贴近通信降噪和真实噪声；和 URGENT 相比，它的任务空间通常更窄。
- 引用结果时要注明届次、track、采样率、是否 personalized、是否 real-time、是否使用额外训练数据。

## 6. 相关对象

- [[方向/AI语音增强/README|AI 语音增强]]：DNS Challenge 是该方向的 benchmark / 数据 / 指标入口之一。
- [[方向/AI语音/评估/语音增强评估指标体系|语音增强评估指标体系]]：解释 DNSMOS、P.835、PESQ、ESTOI、SI-SDR 等指标关系。
- [[方向/AI语音/评估/OVRL_MOS|OVRL_MOS]]：DNSMOS / P.835 风格总体听感指标入口。
- [[方向/AI语音/评估/URGENT（通用语音增强挑战）|URGENT]]：更后来的 universal speech enhancement 挑战，可和 DNS 分工对照。
- [[方向/AI语音/数据集/VoiceBank-DEMAND|VoiceBank-DEMAND]]：经典但较小、较饱和的语音增强基准。
- [[方向/AI语音/知识/基础概念/Reverberation Modeling（混响建模）|Reverberation Modeling]]：DNS Challenge 也提供/使用 RIR 与真实噪声相关资源。

## 7. 关键来源

- [microsoft/DNS-Challenge](https://github.com/microsoft/DNS-Challenge)
  - 内容定位：官方 GitHub 仓库，含挑战脚本、模型、所需文件、DNSMOS 与历届资料入口。
  - 用途：作为代码、数据和评测工具 canonical 入口。
  - 核验日期：2026-08-03
- [Microsoft Research - ICASSP 2023 Deep Noise Suppression Challenge](https://www.microsoft.com/en-us/research/academic-program/deep-noise-suppression-challenge-icassp-2023/)
  - 内容定位：ICASSP 2023 DNS Challenge 官方页面，说明第 5 届定位和任务关注点。
  - 用途：确认挑战赛系列定位和 2023 届边界。
  - 核验日期：2026-08-03
- [Microsoft Research - ICASSP 2023 DNS Challenge Rules](https://www.microsoft.com/en-us/research/academic-program/deep-noise-suppression-challenge-icassp-2023/rules/)
  - 内容定位：2023 官方规则页，记录评审重点和 P.835 主观质量评估权重。
  - 用途：确认 DNS Challenge 的评估机制。
  - 核验日期：2026-08-03

## 8. 待验证

- 是否需要把 DNS Challenge 数据资源、DNSMOS 工具和历届 leaderboard 拆成子笔记。
- DNS Challenge 与 URGENT 在当前实验设计里的分工：通信实时降噪 vs universal 多失真增强。
- 本地语音增强实验是否应优先使用 DNS 训练/测试资源，还是只把它作为外部泛化评测。


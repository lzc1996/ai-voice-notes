---
title: SS（语音分离）
类型: 概念
发表时间: 1953
时间依据: Cherry 1953 cocktail party problem 作为早期问题表述；非现代神经语音分离模型发布时间
相关任务:
  - 语音分离
相关方向:
  - 语音增强
相关主题:
  - 说话人
相关模型:
  - "[[方向/AI语音/模型/UniSE（Unified Speech Enhancement）]]"
  - "[[方向/AI语音/模型/WavLM]]"
  - "[[方向/AI语音/模型/TF-GridNet]]"
相关评估:
  - "[[方向/AI语音/评估/SI-SDR]]"
  - "[[方向/AI语音/评估/STOI 与 ESTOI]]"
aliases:
  - 语音分离（SS）
  - SS
  - 语音分离
  - ss
tags:
  - 类型/对象
  - 方向/AI语音
  - 任务/语音分离
  - 主题/说话人
---

# SS（语音分离）

## 1. 身份

`SS` 在当前 AI 语音笔记里按 **Speech Separation（语音分离）** 处理：给一段包含两个或多个说话人的混合语音，输出每个说话人各自的一路音频。它可以被 [[方向/AI语音增强/README|AI 语音增强]] 方向作为相邻技术跟踪，但严格任务标签应写 `任务/语音分离`，不要因为和增强共享前端、指标或生成式精修方法就写成 `任务/语音增强`。

最小定义是：输入 `mixture`，输出 `speaker_1, speaker_2, ... speaker_n`。它通常不要求提前给目标说话人的参考音频；如果给了目标 clue 并只输出一路，就更接近 [[方向/AI语音/知识/基础概念/TSE（目标说话人提取）|目标说话人提取]]。

## 2. 和相邻任务的区别

| 任务 | 输入条件 | 输出 | 核心问题 |
|---|---|---|---|
| 语音分离（SS） | 混合语音 | 多个说话人音频轨 | 估计人数、输出排列、跨段一致性 |
| [[方向/AI语音/知识/基础概念/TSE（目标说话人提取）]] | 混合语音 + 目标说话人线索 | 目标说话人一路音频 | 锁定指定说话人 |
| [[方向/AI语音/知识/基础概念/Reverse TSE（反向目标说话人提取）]] | 混合语音 + 目标说话人线索 | 去掉目标后的音频 | 定向抑制某个说话人 |
| [[方向/AI语音/知识/基础概念/SE（语音增强）导论]] | 带噪或受损主语音 | 更干净的一路主语音 | 降噪、去混响、保内容 |

边界：SS 不是 diarization。Diarization 主要输出“谁在什么时候说话”的时间标注；SS 要输出可听的分离波形。

## 3. 典型路线

- **经典 BSS / [[方向/AI语音/知识/基础概念/Beamforming（波束形成）|beamforming]]**：ICA、NMF、CASA、波束形成等，适合多通道或可解释管线，但强混响和单通道多人重叠时上限有限。
- **频谱 mask / deep clustering**：在 STFT 时频单元上学习聚类或 mask，是深度学习语音分离早期主线。
- **[[方向/AI语音/知识/基础概念/PIT（置换不变训练）|PIT / uPIT]]**：训练时枚举输出与目标说话人的排列，解决“输出 1/2 到底对应谁”的 permutation problem。
- **时域分离**：TasNet / Conv-TasNet 类路线直接在 waveform 或 learned basis 上分离，绕开固定 STFT 表示。
- **统一框架 / token LM**：[[方向/AI语音/模型/UniSE（Unified Speech Enhancement）|UniSE]] 把 SR / TSE / SS 放进统一 decoder-only LM-based speech enhancement 框架。

## 4. 工程难点

- **输出排列问题**：模型输出的第 1 路、第 2 路没有天然 speaker label，训练和评估都要处理 permutation。
- **人数不确定**：真实会议里说话人数和重叠人数会变，固定 `2-speaker` 模型不一定能直接迁移。
- **跨段一致性**：长音频 chunk 化后，同一个人可能在不同 chunk 被分到不同输出轨。
- **混响和噪声**：真实房间里分离、去混响、降噪往往缠在一起。
- **实时性**：高质量 SS 常依赖整段上下文；实时系统要单独验证延迟和 chunk 边界伪影。

## 5. 评估

- **波形保真**：[[方向/AI语音/评估/SI-SDR|SI-SDR]] / SI-SNR、SDR、[[方向/AI语音/评估/SIR（信号干扰比）|SIR]]、SAR。
- **可懂度和感知质量**：[[方向/AI语音/评估/STOI 与 ESTOI|ESTOI]]、PESQ、DNSMOS / OVRL。
- **下游任务**：ASR WER/CER、speaker diarization 一致性、目标说话人残留。
- **人工听测**：多人重叠、声线相近和强混响场景仍需要主观复核。

## 6. 相关对象

- [[方向/AI语音/知识/基础概念/Source Separation（源分离）|Source Separation（源分离）]]：上位概念入口，本页是其 speech 侧子任务。
- [[方向/AI语音/知识/基础概念/TSE（目标说话人提取）|目标说话人提取]]：SS 输出所有说话人；TSE 给定 clue 后只输出目标说话人。
- [[方向/AI语音/知识/基础概念/Reverse TSE（反向目标说话人提取）|反向目标说话人提取]]：可以先做 SS，再匹配并丢弃某个目标说话人。
- [[方向/AI语音/知识/基础概念/SR（语音恢复）|语音恢复]]：SR 通常修复一路主语音；SS 处理多人混合。
- [[方向/AI语音/模型/UniSE（Unified Speech Enhancement）|UniSE]]：把 SS 与 SR / TSE 放进统一框架。
- [[方向/AI语音/知识/基础概念/Beamforming（波束形成）|Beamforming]]：多通道 SS 中常用的空间滤波前端。
- [[方向/AI语音/模型/WavLM|WavLM]]：可作为分离、说话人一致性或条件特征来源。
- [[方向/AI语音/评估/SI-SDR|SI-SDR]]：SS 常用的侵入式波形指标。

## 7. 关键来源

- [Some Experiments on the Recognition of Speech, with One and with Two Ears](https://doi.org/10.1121/1.1907229)
  - 内容定位：Cherry 1953 对 cocktail party problem 的早期实验表述。
  - 用途：给“多人同时说话如何听出/分开目标语音”这一问题的历史锚点。
  - 核验日期：2026-08-03
- [Deep clustering: Discriminative embeddings for segmentation and separation](https://arxiv.org/abs/1508.04306)
  - 内容定位：用深度 embedding 对时频单元聚类，面向语音分离。
  - 用途：建立神经 speech separation 早期代表路线。
  - 核验日期：2026-08-03
- [Permutation Invariant Training of Deep Models for Speaker-Independent Multi-talker Speech Separation](https://arxiv.org/abs/1607.00325)
  - 内容定位：PIT 训练准则，直接处理多说话人分离里的输出排列问题。
  - 用途：说明 SS 的核心训练难点。
  - 核验日期：2026-08-03
- [Conv-TasNet: Surpassing Ideal Time-Frequency Magnitude Masking for Speech Separation](https://arxiv.org/abs/1809.07454)
  - 内容定位：时域端到端语音分离代表工作。
  - 用途：定位从频谱 mask 到 waveform 分离路线的转折。
  - 核验日期：2026-08-03

## 8. 待验证

- 当前中文会议/多人 Agent 场景里，[[方向/AI语音/模型/TF-GridNet|TF-GridNet]]、SepFormer、Conv-TasNet、UniSE 系路线的延迟和跨段 speaker consistency。
- 是否需要单独拆出“音乐源分离 / vocal separation”，避免和 speech separation 混在一个入口里。



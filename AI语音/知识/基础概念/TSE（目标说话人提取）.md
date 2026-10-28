---
title: TSE（目标说话人提取）
类型: 概念
发表时间: 2017
时间依据: Interspeech 2017 speaker-aware extraction 代表性早期工作；非概念首次提出断言
相关任务:
  - 语音增强
  - 语音分离
相关主题:
  - 说话人
相关模型:
  - "[[方向/AI语音/模型/UniSE（Unified Speech Enhancement）]]"
  - "[[方向/AI语音/模型/WavLM]]"
相关评估:
  - "[[方向/AI语音/评估/SI-SDR]]"
aliases:
  - 目标说话人提取（TSE）
  - TSE
  - 目标说话人提取
  - tse
tags:
  - 类型/对象
  - 方向/AI语音
  - 任务/语音增强
  - 任务/语音分离
  - 主题/说话人
---

# TSE（目标说话人提取）

## 1. 身份

`TSE`（Target Speaker Extraction / Target Speech Extraction）是在多人混杂语音里，**只提取指定目标说话人**的语音。它通常需要一个 clue：目标说话人的 [[方向/AI语音/知识/基础概念/Enrollment（说话人注册）|enrollment]] / adaptation utterance、speaker embedding、视觉线索、方向角或其他身份条件。

边界：TSE 和普通[[方向/AI语音/知识/基础概念/SS（语音分离）|语音分离（Speech Separation, SS）]]很接近，但目标不同。SS 通常要把混合语音拆成所有说话人的多个输出；TSE 只输出目标说话人一路，因此能绕开“输出顺序/标签置换”和“到底有几个人”的一部分工程问题。

## 2. 和语音分离的区别

| 任务 | 输入条件 | 输出 | 主要难点 |
|---|---|---|---|
| [[方向/AI语音/知识/基础概念/SS（语音分离）]] | 混合语音 | 每个说话人一路音频 | 估计人数、输出排列、多人一致性 |
| 目标说话人提取（TSE） | 混合语音 + 目标说话人线索 | 目标说话人一路音频 | 目标身份锁定、同声线干扰、跨段一致性 |
| 语音增强（SE） | 带噪单人或主目标语音 | 更干净的主语音 | 降噪、去混响、保内容和音色 |

## 3. 常见线索

- **[[方向/AI语音/知识/基础概念/Enrollment（说话人注册）|Enrollment utterance]]**：给一段目标说话人的干净参考音频，抽 speaker embedding。
- **Speaker embedding / x-vector / d-vector**：作为条件输入，引导网络只保留目标声线。
- **方向 / 麦克风阵列空间特征**：在多通道录音里用 [[方向/AI语音/知识/基础概念/DOA（到达方向）|DOA]]、[[方向/AI语音/知识/基础概念/Beamforming（波束形成）|beamforming]] 或 [[方向/AI语音/知识/基础概念/IPD（通道间相位差）|IPD]] 辅助定位目标。
- **视觉线索**：用脸、唇动或看向某人的交互动作锁定目标说话人。

## 4. 典型路线

- **Mask / [[方向/AI语音/知识/基础概念/Beamforming（波束形成）|beamformer]] 路线**：Speaker-aware mask、beamformer 或 spectrogram mask，适合和传统多通道处理结合。
- **VoiceFilter 路线**：speaker embedding + spectrogram masking，目标是提升拥挤多人场景下的 ASR。
- **SpeakerBeam / time-domain 路线**：用 adaptation utterance 生成目标说话人条件，在频域或时域网络中提取目标语音。
- **统一框架路线**：[[方向/AI语音/模型/UniSE（Unified Speech Enhancement）|UniSE]] 把 Speech Restoration、TSE 和 [[方向/AI语音/知识/基础概念/SS（语音分离）|Speech Separation]] 放进同一个 decoder-only LM-based 框架。

## 5. 使用注意

- TSE 不是 diarization：diarization 主要回答“谁在什么时候说话”，TSE 要直接产出目标说话人的增强波形。
- TSE 不是 ASR 热词或说话人识别：speaker embedding 只是条件，最终目标是音频提取。
- Enrollment 质量决定上限：参考音频太短、带噪、和目标通道差异大，会导致抽错或漏抽。
- 实时产品要单独验证延迟：很多高质量 TSE/SS 系统依赖双向上下文或整段条件，不天然适合逐帧流式。

## 6. 相关对象

- [[方向/AI语音/知识/基础概念/SE（语音增强）导论|语音增强]]：TSE 是相邻任务，也可被统一增强框架覆盖。
- [[方向/AI语音/知识/基础概念/SS（语音分离）|语音分离]]：SS 输出所有说话人，TSE 只输出给定 clue 对应的目标说话人。
- [[方向/AI语音/知识/基础概念/Reverse TSE（反向目标说话人提取）|反向目标说话人提取]]：同样使用目标说话人线索，但目标是抑制/移除该说话人而不是提取它。
- [[方向/AI语音/知识/基础概念/Enrollment（说话人注册）|Enrollment]]：TSE 最常见的目标说话人线索来源。
- [[方向/AI语音/模型/UniSE（Unified Speech Enhancement）|UniSE]]：统一 SR / TSE / SS 的 decoder-only LM-based 框架。
- [[方向/AI语音/模型/WavLM|WavLM]]：常作为条件特征或说话人/语音表示来源。
- [[方向/AI语音/知识/基础概念/SSL 编码器|SSL 编码器]]：抽取鲁棒语音和说话人表示的常见前端。
- [[方向/AI语音/知识/基础概念/Audio Leakage（漏音）|漏音]]：TSE 可作为漏音或非目标说话人污染的后处理方案。
- [[方向/AI语音/知识/基础概念/DOA（到达方向）|DOA]]：多通道 TSE 中的方向线索。
- [[方向/AI语音/知识/基础概念/Beamforming（波束形成）|Beamforming]]：多通道 TSE 中可作为定向提取前端。
- [[方向/AI语音/知识/基础概念/IPD（通道间相位差）|IPD]]：多通道 TSE 中可作为空间特征辅助锁定目标。
- [[方向/AI语音/评估/SI-SDR|SI-SDR]]：语音分离和 TSE 常用波形保真指标。

## 7. 关键来源

- [Speaker-Aware Neural Network Based Beamformer for Speaker Extraction in Speech Mixtures](https://www.isca-archive.org/interspeech_2017/zmolikova17_interspeech.html)
  - 内容定位：Interspeech 2017 早期 speaker-aware extraction 工作，说明用目标说话人信息解决多说话人 mask permutation 问题。
  - 用途：建立 TSE / speaker extraction 的早期代表来源。
  - 核验日期：2026-08-03
- [VoiceFilter: Targeted Voice Separation by Speaker-Conditioned Spectrogram Masking](https://arxiv.org/abs/1810.04826)
  - 内容定位：speaker embedding + spectrogram mask 的 targeted voice separation 系统，面向多说话人 ASR 前端。
  - 用途：理解 TSE 和 ASR 前端的连接。
  - 核验日期：2026-08-03
- [Improving speaker discrimination of target speech extraction with time-domain SpeakerBeam](https://arxiv.org/abs/2001.08378)
  - 内容定位：time-domain SpeakerBeam，明确说明 TSE 利用目标说话人线索抽取单一目标声源，并作为语音分离的实用替代路线。
  - 用途：理解 TSE 与普通语音分离的工程区别。
  - 核验日期：2026-08-03
- [UniSE: A Unified Framework for Decoder-Only Autoregressive LM-Based Speech Enhancement](https://arxiv.org/abs/2510.20441)
  - 内容定位：把 SR / TSE / SS 放进统一 decoder-only LM-based speech enhancement 框架。
  - 用途：跟踪 TSE 在新一代统一增强框架里的位置。
  - 核验日期：2026-08-03

- [[方向/AI语音/知识/调研与地图/Personalized SE（个性化语音分离产品线调研）|Personalized SE（个性化语音分离产品线调研）]]：本页概念的产品化现状——Teams/Zoom 声纹注册、AirPods 听力图、Google Personal VAD 三条产品线，以及学术 TSE 与产品的三处差距。

## 8. 待验证

- 当前实时 TSE 中，SpeakerBeam-SS、FlowTSE、神经 [[方向/AI语音/知识/基础概念/Beamforming（波束形成）|beamforming]] 和 UniSE 系路线的延迟/音质/内容保持取舍。
- TSE 在中文会议、近场漏音、同声线多人场景里的稳定性。



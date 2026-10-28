---
title: Reverse TSE（反向目标说话人提取）
类型: 概念
发表时间:
时间依据: 任务变体/工程口径；非单一发表物
相关任务:
  - 语音增强
  - 语音分离
相关主题:
  - 说话人
相关评估:
  - "[[方向/AI语音/评估/SI-SDR]]"
aliases:
  - 反向目标说话人提取（Reverse TSE）
  - Reverse TSE
  - 反向目标说话人提取
  - reverse tse
tags:
  - 类型/对象
  - 方向/AI语音
  - 任务/语音增强
  - 任务/语音分离
  - 主题/说话人
---

# Reverse TSE（反向目标说话人提取）

## 1. 身份

`反向 TSE` 是 [[方向/AI语音/知识/基础概念/TSE（目标说话人提取）|目标说话人提取]] 的任务变体：给定目标说话人的线索，不是输出这个目标说话人，而是**抑制或移除该目标说话人，尽量保留其他说话人、环境声或主轨道内容**。

一个最小工程定义是：输入 `mixture + target speaker clue`，输出 `mixture minus target speaker`。因此它也可被叫作 Target Speaker Suppression / Target Speaker Removal。

## 2. 和 TSE 的区别

| 任务 | 输入条件 | 输出 | 目标 |
|---|---|---|---|
| TSE | 混合语音 + 目标说话人线索 | 目标说话人一路音频 | 把目标说话人提出来 |
| 反向 TSE | 混合语音 + 目标说话人线索 | 非目标部分 / 去目标后的音频 | 把目标说话人压下去 |
| [[方向/AI语音/知识/基础概念/SS（语音分离）]] | 混合语音 | 多个说话人输出 | 尽量拆出所有声源 |
| 语音增强 | 带噪或受损语音 | 更干净的主语音 | 降噪、去混响、保内容 |

边界：反向 TSE 不是普通降噪，也不是 diarization；它关心的是“已知某个说话人后，能否定向把这个人从音频里移除”。

## 3. 典型用途

- **隐私遮蔽**：已知某个说话人身份时，把他的语音从会议、采访或录音中压低。
- **漏音清理**：在 [[方向/AI语音/知识/基础概念/Audio Leakage（漏音）|漏音]] 场景里，已知串入的非目标说话人后，尝试定向抑制该声源。
- **多人 ASR 前处理**：在只关心非目标发言人时，先移除固定干扰说话人。
- **后期制作**：从混合语音里去掉特定人声，但要单独验证残留、相位和音质。

## 4. 实现路线

- **TSE 后相减**：先用 TSE 得到目标估计 `s_hat`，再做 `mixture - s_hat`；实现简单，但容易留下相位、音乐噪声或过减痕迹。
- **Mask 互补**：估计目标说话人的 mask，再使用互补 mask 得到非目标部分；适合频域或多通道管线。
- **多说话人分离后丢弃目标**：先做普通[[方向/AI语音/知识/基础概念/SS（语音分离）|语音分离]]，再用 speaker embedding 匹配并移除目标轨。
- **直接训练抑制模型**：把 speaker clue 作为条件，直接优化“保留非目标、压制目标”的输出。

## 5. 使用注意

- 不能把 `mixture - s_hat` 当成无损操作；目标估计误差会变成残留或伪影。
- 声线相近、同频共振、多人重叠说话时，容易误删非目标内容。
- 隐私场景不能只凭听感验收；需要检查目标说话人残留、非目标失真和 ASR 侧影响。
- 如果有播放参考信号，扬声器漏进麦克风的问题应优先考虑 AEC，而不是反向 TSE。

## 6. 相关对象

- [[方向/AI语音/知识/基础概念/TSE（目标说话人提取）|目标说话人提取]]：反向 TSE 复用目标说话人线索，但目标是移除而不是提取。
- [[方向/AI语音/知识/基础概念/Audio Leakage（漏音）|漏音]]：已知泄漏说话人时，可把反向 TSE 当成后处理备选。
- [[方向/AI语音/知识/基础概念/SE（语音增强）导论|语音增强]]：反向 TSE 可被视为 speaker-conditioned enhancement / separation 的交叉任务。
- [[方向/AI语音/评估/SI-SDR|SI-SDR]]：可评估波形层面的保真和分离效果，但隐私残留仍需额外指标。

## 7. 关键来源

- [VoiceFilter: Targeted Voice Separation by Speaker-Conditioned Spectrogram Masking](https://arxiv.org/abs/1810.04826)
  - 内容定位：speaker embedding + spectrogram mask 的目标说话人提取路线。
  - 用途：说明反向 TSE 可从 speaker-conditioned mask / TSE 输出工程反向得到，但原论文目标仍是提取目标说话人。
  - 核验日期：2026-08-03
- [Improving speaker discrimination of target speech extraction with time-domain SpeakerBeam](https://arxiv.org/abs/2001.08378)
  - 内容定位：time-domain SpeakerBeam 使用目标说话人线索做 TSE。
  - 用途：作为“先提取目标、再构造非目标输出”的路线参照。
  - 核验日期：2026-08-03
- [Speaker-Aware Neural Network Based Beamformer for Speaker Extraction in Speech Mixtures](https://www.isca-archive.org/interspeech_2017/zmolikova17_interspeech.html)
  - 内容定位：早期 speaker-aware extraction / beamformer 工作。
  - 用途：给“用说话人线索控制分离目标”的技术背景。
  - 核验日期：2026-08-03

## 8. 待验证

- 是否有专门以 Target Speaker Suppression / Removal 命名、且比 TSE 反向相减更稳的近年模型。
- 对隐私删除任务，目标说话人残留应使用 speaker verification score、ASR 泄漏率还是人工复核作为主指标。


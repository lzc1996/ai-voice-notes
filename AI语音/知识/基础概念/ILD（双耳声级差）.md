---
title: ILD（双耳声级差）
类型: 概念
相关主题:
  - 阵列信号
  - 多通道增强
aliases:
  - Interaural Level Difference
  - interaural level difference
  - Inter-channel Level Difference
  - inter-channel level difference
  - ILD
  - ild
  - 双耳声级差
  - 通道间能量差
tags:
  - 类型/对象
  - 方向/AI语音
  - 主题/阵列信号
  - 主题/多通道增强
---
# ILD（双耳声级差）

## 1. 身份

`ILD`（Interaural Level Difference，双耳声级差）是双耳或 [[方向/AI语音/知识/基础概念/Array Audio Signal（阵列音频信号）|麦克风阵列]] 两个通道在某个时频点上的**能量差**。经典意义来自双耳听觉：头部的遮挡（head shadow）让靠近声源一侧的耳朵听到更响，形成定位线索；在阵列处理里推广为通道间能量差，是多通道语音增强、[[方向/AI语音/知识/基础概念/DOA（到达方向）|DOA]] 估计和 neural beamforming 的常见空间特征。

最小公式：

$$
\text{ILD}_{ij}(t, f) = 20 \log_{10} \frac{|X_i(t, f)|}{|X_j(t, f)|}
$$

其中 $X_i(t, f)$ 和 $X_j(t, f)$ 是两个通道的 STFT。正值表示通道 $i$ 能量更强。实际使用时常做幅值压缩或 clip，避免噪声地板导致比值爆炸。

## 2. 边界

- ILD 不是 IPD：ILD 看能量差，[[方向/AI语音/知识/基础概念/IPD（通道间相位差）|IPD]] 看相位差，两者互补——ILD 高频有效，IPD 低频有效。
- ILD 不是 DOA：ILD 是通道间能量线索，DOA 是由阵列几何和空间模型估出的方向。
- ILD 不是 beamforming：beamforming 用方向、相位/时延或 mask 形成空间滤波器，ILD 只是常见输入线索之一。

## 3. 为什么重要

- **能量域线索更稳健**：没有相位 wrap 问题，计算简单，对采样漂移不敏感。
- **高频 / 近场 / 遮挡场景有效**：短波长下声影效应明显；近场距离差和障碍物遮挡也会产生能量差，这些场景相位线索反而易混淆。
- **辅助分离目标**：不同方向或不同距离的声源在 ILD 上可能呈现不同模式，可作为神经模型的输入特征。

## 4. 使用注意

- **通道增益失配直接污染 ILD**：通道校准、AGC 或麦克风灵敏度差异会伪造能量差，需先做增益归一化。
- **噪声和混响拉平能量差**：扩散噪声场和晚期混响会让两通道能量趋于一致，低 SNR 下 ILD 信息量下降。
- **远场平面波近似下能量差小**：远场且无障碍时，两通道能量接近，ILD 主要靠近场或遮挡提供信息。
- **趋势**：阵列增强前沿中手工 IPD / ILD 特征正逐步被可学习空间滤波（跨通道 conv、帧级 DOA 编码、GNN 通道建模）取代。

## 5. 关键来源

- [Microphone Array Signal Processing and Deep Learning for Speech Enhancement](https://arxiv.org/abs/2501.07215)
  - 内容定位：麦克风阵列信号处理与深度学习语音增强综述，覆盖多通道空间特征。
  - 用途：确认 IPD / ILD / transfer function 等特征在多通道 SE 中的位置。
  - 核验日期：2026-08-04
- [Advances in Microphone Array Processing and Multichannel Speech Enhancement](https://arxiv.org/abs/2502.09037)
  - 内容定位：麦克风阵列处理与多通道语音增强综述。
  - 用途：把 ILD 放回 DOA、beamforming、神经多通道增强的整体地图。
  - 核验日期：2026-08-04

## 6. 相关对象

- [[方向/AI语音/知识/基础概念/Array Audio Signal（阵列音频信号）|Array Audio Signal]]：ILD 来自多通道阵列信号。
- [[方向/AI语音/知识/基础概念/IPD（通道间相位差）|IPD]]：相位差线索，与 ILD 互补（低频 vs 高频）。
- [[方向/AI语音/知识/基础概念/ITD（耳间时间差）|ITD]]：时间差线索，与 ILD 互补（Duplex theory：低频 ITD / 高频 ILD）。
- [[方向/AI语音/知识/基础概念/DOA（到达方向）|DOA]]：ILD 是估计声源方向的空间线索之一。
- [[方向/AI语音/知识/基础概念/Beamforming（波束形成）|Beamforming]]：ILD 可作为 neural beamformer 或 mask 估计的输入特征。
- [[方向/AI语音/知识/基础概念/Spectrogram（声谱图）|Spectrogram]]：ILD 通常基于多通道 STFT 幅度计算。

## 7. 待验证

- 当前目标硬件阵列下，ILD 在近场 vs 远场场景的可区分度。
- 双耳（耳间）语境下，head shadow / HRTF 对 ILD 的定量影响是否需要用仿真验证。
- 显式 ILD + IPD 联合特征 vs 端到端可学习空间滤波，在实时中文会议 / 语音 Agent 链路里哪个更稳。

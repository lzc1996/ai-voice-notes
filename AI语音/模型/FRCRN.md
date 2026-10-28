---
title: FRCRN
类型: 模型
发表时间: "2022"
时间依据: ICASSP 2022 论文；arXiv 2022-06-14 首次公开
任务:
  - 单通道语音增强
  - 实时降噪
  - 去混响
  - 全带宽语音增强
相关主题:
  - CRED
  - FSMN
  - complex ideal ratio mask
  - real-time speech enhancement
相关评估:
  - DNS Challenge
  - DNS-2020
  - VoiceBank+DEMAND
  - PESQ
  - STOI
  - SI-SNR
  - DNSMOS
开放状态:
  - paper
  - code
  - pretrained-inference
aliases:
  - "FRCRN: Boosting Feature Representation Using Frequency Recurrence for Monaural Speech Enhancement"
  - Frequency Recurrent CRN
  - Full-Band FRCRN
tags:
  - 类型/对象
  - 方向/AI语音
  - 任务/语音增强
  - 任务/降噪
  - 主题/实时推理
  - 主题/复杂谱建模
---

# FRCRN

## 0. 背景

**问题现场**：单通道实时语音增强需要在低延迟约束下对复杂谱中远距离频率关系建模。

**前序路线的缺口**：普通 CRN 在频率轴上的卷积感受野有限，局部卷积对远距离频率关系建模不足。

**FRCRN 的切入点**：在卷积编解码器内部加入 frequency recurrence（CFSMN 传播跨频率信息），在复数谱域估计 cIRM，兼顾频率长程相关与实时延迟。

## 1. 身份

`FRCRN`（Frequency Recurrent Convolutional Recurrent Neural Network）是 Alibaba Speech Lab 与 NTU 提出的单通道语音增强模型。它针对普通 CRN 在频率轴上的卷积感受野有限这一问题，在卷积编码器-解码器内部加入 frequency recurrence，用 FSMN 建模跨频率的长程相关。

模型同时覆盖 16 kHz wideband 和 48 kHz fullband 语音，并以低延迟、实时语音增强和 DNS Challenge 为主要应用语境。

## 2. 核心链路

```text
noisy / reverberant waveform
  -> complex STFT
  -> CRED: complex convolution + BN + LeakyReLU + CFSMN
  -> two stacked temporal CFSMN layers
  -> complex ideal ratio mask (cIRM)
  -> complex mask x noisy spectrogram
  -> inverse STFT
  -> enhanced waveform
```

## 3. 关键机制

- **CRED**：把普通 convolutional encoder-decoder 扩展为 convolutional recurrent encoder-decoder。
- **Frequency recurrence**：每个时间帧沿频率轴组织序列，用 CFSMN 传播跨频率信息，弥补局部卷积对远距离频率关系建模不足。
- **Temporal recurrence**：编码器与解码器之间再放置两层 stacked CFSMN，建模长时动态。
- **Complex-domain processing**：在复数频谱域估计 cIRM，同时处理幅度和相位相关信息。
- **Joint loss**：联合优化时域 SI-SNR loss 与 cIRM 的实部/虚部 MSE，论文中取两者权重系数 `λ = 1`。
- **Causal time convolution**：时间维使用非对称 padding，面向低延迟推理。

## 4. 配置与实时性

### 4.1. Wideband 16 kHz

- STFT window：20 ms；frame shift：10 ms。
- STFT length：640。
- 总算法延迟：约 30 ms。
- FRCRN：约 6.9M 参数。
- FRCRN-Lite：约 2.1M 参数，通过减少卷积通道和 CFSMN 单元降低复杂度。

### 4.2. Fullband 48 kHz

- 保持 20 ms window / 10 ms shift，因此算法延迟仍约 30 ms。
- STFT length：1920。
- 将频率轴切分为 3 个输入通道，适配更宽频带。
- 参数量：约 10.27M。
- 计算量：约 12.30 GMACS/s。

## 5. 论文结果

- **WSJ0**：FRCRN 达到 PESQ 3.62、STOI 98.24、SI-SNR 21.33；FRCRN-Lite 达到 PESQ 3.21。
- **DNS-2020 non-blind test**：FRCRN 报告 WB-PESQ 3.23、PESQ 3.60、STOI 97.69、SI-SNR 19.78。
- **VoiceBank+DEMAND**：FRCRN 报告 WB-PESQ 3.21、CSIG 4.23、CBAK 3.64、COVL 3.73。
- **DNS-2022**：论文报告 FRCRN 在实时 fullband non-personalized track 中获得第 2 名；开发集 DNSMOS OVRL 为 3.545，Word Accuracy 为 0.641。

这些数字绑定论文自己的数据生成、采样率、延迟和评测版本，不能直接与不同采样率或不同 DNS 赛道的结果混排。

## 6. 使用判断

- **适合**：实时单麦克风降噪、去混响、16 kHz/48 kHz 语音前端、DNS Challenge baseline。
- **优势**：在复杂谱域建模、频率长程相关和实时延迟之间取得较好的平衡；FRCRN-Lite 适合作为低复杂度变体。
- **限制**：主目标仍是噪声和混响抑制，不是 VoiceFixer / GSR 级别的削波、带宽缺失、codec 伪影和多退化生成式恢复。
- **与 NSNet2**：FRCRN 结构更复杂、使用复数谱与频率 recurrence；NSNet2 更小、更偏实值增益 mask 和低成本部署。
- **与 DEMUCS**：FRCRN 是单通道语音增强；DEMUCS 主要是音乐 stem 分离，不能混为同一任务。
- **与 GSR**：FRCRN 可作为 GSR 的判别式/实时 baseline，但覆盖范围不等于完整 GSR。

## 7. 版本与实现边界

- **论文模型**：`FRCRN` 原始论文包含 wideband、fullband、FRCRN-Lite 和消融实验。
- **官方仓库**：Alibaba Speech Lab 的 `alibabasglab/FRCRN` 提供 16 kHz 单通道增强、训练、推理和 DNS 评测入口。
- **ModelScope 推理模型**：`damo/speech_frcrn_ans_cirm_16k` 对应 16 kHz 单通道 cIRM 管线。
- **后续工程方向**：FRCRN 仓库 README 指向 `ClearerVoice-Studio` 作为后续语音前端处理和预训练模型集成入口。
- 不同实现可能在 STFT、归一化、checkpoint、后处理和 chunking 上不同；复现时不能只写“FRCRN”而不写配置。

## 8. 相关对象

- [[方向/AI语音/模型/NSNet2]]：低复杂度实时降噪对照。
- [[方向/AI语音/模型/DEMUCS]]：波形/混合域音乐源分离对照。
- [[方向/AI语音/模型/VoiceFixer]]：多退化、高保真语音恢复对照。
- [[方向/AI语音/知识/基础概念/SE（语音增强）导论]]：FRCRN 的任务归属。
- [[方向/AI语音/知识/基础概念/GSR（General Speech Restoration，通用语音恢复）]]：FRCRN 可作为实时判别式 baseline。
- [[方向/AI语音/评估/DNS Challenge（深度噪声抑制挑战）]]：主要挑战赛语境。

## 9. 关键来源

- [FRCRN: Boosting Feature Representation Using Frequency Recurrence for Monaural Speech Enhancement](https://arxiv.org/abs/2206.07293)
  - 内容定位：原始论文；记录 CRED、frequency recurrence、CFSMN、cIRM、联合损失和 DNS 结果。
  - 用途：确认模型机制、参数量、延迟和实验数字。
  - 核验日期：2026-09-20
- [Alibaba Speech Lab FRCRN repository](https://github.com/alibabasglab/FRCRN)
  - 内容定位：训练、推理、ModelScope 和 DNS 评测入口。
  - 用途：工程复现与版本核验。
  - 核验日期：2026-09-20
- [ModelScope: damo/speech_frcrn_ans_cirm_16k](https://modelscope.cn/models/damo/speech_frcrn_ans_cirm_16k)
  - 内容定位：16 kHz 单通道 cIRM 预训练推理模型。
  - 用途：检查可用 checkpoint 和推理接口。
  - 核验日期：2026-09-20
- [ClearerVoice-Studio](https://github.com/modelscope/ClearerVoice-Studio)
  - 内容定位：FRCRN 仓库指向的后续语音前端和预训练模型工程入口。
  - 用途：追踪后续维护与模型集成。
  - 核验日期：2026-09-20

## 10. 待验证

- [ ] 固定本地部署的采样率、STFT 配置、chunk 长度、归一化和后处理。
- [ ] 在同一 DNS/VCTK GSR 条件下比较 FRCRN、NSNet2、VoiceFixer 和一个生成式模型的 WER、DNSMOS、SpkSim 与 RTF。

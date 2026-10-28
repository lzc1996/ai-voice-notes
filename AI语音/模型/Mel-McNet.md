---
title: Mel-McNet
类型: 模型
发表时间: 2025-05
时间依据: arXiv 首次提交（2025-05）；Interspeech 2025 发表
任务:
  - 语音增强
  - 多通道增强
团队:
  - "[[方向/AI语音/团队/Audio-WestlakeU（西湖大学音频实验室）]]"
开放状态:
  - paper
  - code
aliases:
  - Mel McNet
  - "Mel-McNet: A Mel-Scale Framework for Online Multichannel Speech Enhancement"
  - A Mel-Scale Framework for Online Multichannel Speech Enhancement
tags:
  - 类型/对象
  - 方向/AI语音
  - 任务/语音增强
  - 任务/多通道增强
  - 主题/阵列信号
---

# Mel-McNet

## 0. 背景

- **算力 −60%**：论文在 CHiME-3 上报告约 60% 复杂度下降，增强与下游 ASR 表现接近原 McNet。
- **对齐"增强—理解一体化"趋势**：输出 enhanced LogMel 可直接接入 Whisper 类编码器，是"面向识别的增强"的工程形态（见 [[方向/AI语音/知识/调研与地图/Array Speech Enhancement Frontier（阵列语音增强前沿调研）|阵列增强前沿]] 的与 ASR 联合主线）。
- **在线多通道框架**：与 McNet 同一在线框架，可复现性强（官方代码开源）。

## 1. 身份

`Mel-McNet`（Interspeech 2025）是 [[方向/AI语音/模型/McNet|McNet]] 的 **Mel 域在线版本**：先用 STFT-to-Mel module 把多通道 STFT 特征压缩到 Mel-frequency 表示，再用 modified McNet backbone 直接输出 **enhanced LogMel spectra**，供 ASR 消费。它仍是多通道增强模型，不是 ASR 模型——输出形态更接近 ASR 前端特征。

边界：与 McNet 相比，Mel-McNet 牺牲了线性频率域的相位和细频率结构，换取算力与"增强→识别"链路的衔接效率。目标场景是低算力部署和服务 ASR 的增强前端。

## 2. 核心链路

```text
noisy multi-channel waveform
  -> STFT
  -> STFT-to-Mel module（多通道特征压到 Mel 域）
  -> modified McNet backbone
  -> enhanced LogMel spectra
  -> ASR（直连）或 vocoder 重建波形（听感评估）
```

## 3. 核心公式

Mel 压缩（STFT-to-Mel module 的理论基础）：

$$f_{\mathrm{mel}} = 2595\,\log_{10}\Big(1 + \frac{f}{700}\Big), \qquad X_{\mathrm{mel}}(b,t) = \sum_{f} W_{\mathrm{mel}}(b,f)\,\big|X(t,f)\big|^{2}, \qquad Y_{\mathrm{mel}} = \log\big(X_{\mathrm{mel}} + \epsilon\big)$$

其中 $\mathbf{W}_{\mathrm{mel}} \in \mathbb{R}^{B\times F}$ 为 Mel 滤波器组，把线性频率轴压缩为 $B$ 个 Mel 频带，$\epsilon$ 为数值下界；STFT-to-Mel module 把多通道 STFT 特征压缩到 Mel 域供 backbone 使用（多通道特征的具体构成待核，见待验证）。

增强输出（直接回归 LogMel）：

$$\hat{\mathbf{Y}}(b,t) = \mathrm{Mel\text{-}McNet}\Big(\big\{\mathbf{Z}^{(c)}_{\mathrm{mel}}\big\}_{c=1}^{M}\Big) \in \mathbb{R}^{B\times T}$$

其中 $\mathbf{Z}^{(c)}_{\mathrm{mel}}$ 为第 $c$ 个通道的 Mel 域特征，输出 enhanced LogMel 谱 $\hat{\mathbf{Y}}$ 可直接供 ASR / vocoder 消费；相位与线性频率细结构在该表示中不保留。

训练目标（待核）：

$$\mathcal{L} = \big\|\hat{\mathbf{Y}} - \mathbf{Y}_{\mathrm{clean}}\big\|_1 \quad \text{（具体形式待核，见待验证）}$$

其中 $\mathbf{Y}_{\mathrm{clean}}$ 为干净目标 LogMel；LogMel 域重建损失是"面向 ASR 的增强前端"的常用目标，论文的具体损失函数待核。

## 4. 测试基准与性能

**测试基准**（ar5iv）：

- 数据：CHiME-3 模拟集 6 通道（开发 1,640 / 测试 1,320 句），平板 6 麦、第 5 通道参考；训练用 DNS Challenge 100 h 干净语音 + CHiME-3 噪声在 SNR −5~10 dB 下即时合成（16 kHz、无混响、纯延迟）。
- 前端：512 点（32 ms）Hann 窗 / 128 点（8 ms）hop，80 Mel bin，因果 / 在线处理。
- 基线（同设置重训的在线多通道方法）：EaBNet、oSpatialnet-mamba、McNet；参考条件 Noisy / Clean / Clean Mel+Vocos（上限）。
- 下游：ASR 用预训练 ESPnet E-branchformer（WSJ），听感重建用 Vocos；指标含 DNSMOS P.835、WB-PESQ、STOI(%)、WER(%)、参数量 / FLOPs。

**性能指标**（ar5iv Table 1）：

| 方法 | 参数(M) | FLOPs(G/s) | DNSMOS OVR | WB-PESQ | STOI(%) | WER(%) |
|---|---|---|---|---|---|---|
| McNet | 1.85 | 115.13 | 3.12 | 2.80 | 97.7 | 4.4 |
| **Mel-McNet** | 15.24（本体 2.04 + vocoder 13.20） | **46.96** | **3.14** | 2.44 | 95.4 | **4.4** |

- 复杂度：FLOPs 115.13 → 46.96 G/s（↓≈59%，即「为什么重要」所称约 60%）；CPU RTF ≈ 0.799（Intel i7-9700）。
- 增强质量：DNSMOS OVR 最优（3.14）、WER 与 McNet 并列最优（4.4%）；WB-PESQ / STOI 略低于 McNet（2.44 vs 2.80、95.4 vs 97.7），论文归因于 vocoder 有损。
- 消融：Separate FCB+TSB（幅度 / 相位分离分支）最优（DNSMOS OVR 3.14 / WB-PESQ 2.44 / WER 4.4%）。

## 5. 使用注意

- **Mel 压缩有损**：压缩频率轴、丢相位，高保真听感场景不能只看 ASR 指标。
- **评估口径**：增强质量（PESQ/STOI）与下游 ASR（WER）要分开看；Mel 域输出直连 ASR 与先 vocoder 重建再 ASR 的差异需实测。
- **定位**：属于"判别式神经增强前端"，与生成式精修（[[方向/AI语音/模型/ArrayDPS-Refine|ArrayDPS-Refine]] 类）互补而非竞争。

## 6. 关键来源

- [Mel-McNet: A Mel-Scale Framework for Online Multichannel Speech Enhancement](https://arxiv.org/abs/2505.19576)
  - 内容定位：Mel-McNet 原始论文，报告 CHiME-3 上约 60% 复杂度下降，增强与下游 ASR 表现接近 McNet。
  - 用途：方法定义、架构与评测结果。
  - 核验日期：2026-08-05
- [Audio-WestlakeU/Mel-McNet](https://github.com/Audio-WestlakeU/Mel-McNet)
  - 内容定位：官方 PyTorch 实现。
  - 用途：复现 Mel 域多通道增强实验。
  - 核验日期：2026-08-05

## 7. 相关对象

- [[方向/AI语音/模型/McNet|McNet]]：前身 / 同框架基础，Mel-McNet 是其 Mel 域在线变体。
- [[方向/AI语音/团队/Audio-WestlakeU（西湖大学音频实验室）|Audio-WestlakeU]]：主要团队入口。
- [[方向/AI语音/知识/基础概念/STFT（短时傅里叶变换）|STFT]]、[[方向/AI语音/知识/基础概念/Spectrogram（声谱图）|Spectrogram]]：Mel-McNet 的输入输出表示基础。
- [[方向/AI语音/评估/CHiME（语音分离与识别挑战赛）|CHiME]]：常在 CHiME-3 多通道 noisy ASR 场景上评估。
- [[方向/AI语音/知识/基础概念/Array Audio Signal（阵列音频信号）|Array Audio Signal]]：多通道增强前端范式的一部分。

## 8. 待验证

- 在本地会议阵列样本上的增强指标、WER 和实时性（与 McNet 笔记共用口径）。
- Mel 域输出直接接 ASR 与先 vocoder 重建再 ASR 的差异。
- Mel 域多通道思路对"阵列前端对接音频大模型"的参考价值（[[方向/AI语音/知识/调研与地图/Array Speech Enhancement Frontier（阵列语音增强前沿调研）|阵列增强前沿]] 待深挖项）。
- STFT-to-Mel 模块的具体特征构成（多通道特征压缩方式、相位处理）与训练损失的具体形式待核。

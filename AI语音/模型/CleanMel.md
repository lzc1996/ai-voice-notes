---
title: CleanMel
类型: 模型
发表时间: 2025-02
时间依据: arXiv 首次提交日 2025-02-27；GitHub README 标注 TASLP 2025 accepted
任务:
  - 语音增强
  - ASR 前端
团队:
  - "[[方向/AI语音/团队/Audio-WestlakeU（西湖大学音频实验室）]]"
开放状态:
  - paper
  - code
  - weights
  - demo
aliases:
  - "CleanMel: Mel-Spectrogram Enhancement for Improving Both Speech Quality and ASR"
  - Mel-Spectrogram Enhancement for Improving Both Speech Quality and ASR
  - CleanMel speech enhancement
tags:
  - 类型/对象
  - 方向/AI语音
  - 任务/语音增强
  - 任务/ASR前端
---

# CleanMel

## 0. 背景

**问题现场**：单通道增强需要同时改善听感语音质量与 ASR 表现，且增强输出要能直接对接 ASR 前端。

**CleanMel 的切入点**：把增强目标放在 Mel/logMel 表示上（比线性频率或时域更紧凑、更贴近 ASR 前端）：先在线性频率域处理 STFT 复数特征，再进 Mel 频率域输出 clean logMel，可直接喂 ASR 或经神经 vocoder 还原波形。

## 1. 身份

`CleanMel` 是 Audio-WestlakeU 提出的**单通道 Mel 谱增强模型**：输入 noisy / reverberant microphone recording，预测 clean Mel-spectrogram，用于同时改善听感语音质量和 ASR 表现。增强后的 Mel 谱可以直接送入 ASR，也可以通过神经 vocoder 还原成 waveform。

边界：CleanMel 不是 ASR，也不是多通道阵列增强；它把增强目标放在 Mel / logMel 表示上，核心假设是 Mel 频率表示比线性频率或时域 waveform 更紧凑、更容易学习，同时更贴近 ASR 前端。

## 2. 核心链路

```text
noisy/reverberant waveform
  -> STFT complex feature
  -> interleaved cross-band + narrow-band processing
  -> Mel filterbank / Mel-frequency processing
  -> enhanced clean logMel spectrogram
  -> ASR directly or neural vocoder -> waveform
```

## 3. 关键设计

- **学习目标**：论文比较 clean logMel mapping 与 Mel ratio mask；mapping 直接回归 clean logMel，mask 预测 Mel ratio mask。
- **网络骨架**：从 SpatialNet / SpatialNet-Mamba 路线改造而来，先在线性频率域处理 STFT 复数特征，再进入 Mel 频率域。
- **输出用途**：ASR 侧可直接使用 enhanced Mel-spectrogram；听感侧用 GAN-based neural vocoder 转 waveform。
- **数值细节**：logMel 使用较大的 clip value（如 $\epsilon=1e-5$），论文报告对 speech quality 和 ASR 几乎无损，同时降低低能量噪声 bin 的预测难度。

## 4. 测试基准与性能

- 数据覆盖：CHiME4、DNS、VoiceBank+Demand、REVERB、EARS、RealMAN static，包含英文和中文场景。
- ASR 主结果：CleanMel-L-mask 在 CHiME4 simu / real WER 为 9.6 / 7.7，RealMAN static CER 为 14.4；对应 unprocessed 为 15.3 / 13.1 / 20.1。
- vocoder 影响：直接用 enhanced Mel-spectrogram 做 ASR 通常优于先 vocoder 成 waveform 再 ASR，但 waveform 版本仍可作为不用重训 ASR 前端时的折中。
- 复杂度注意：Mel 频率数少于线性频率，计算量相对 FullSubNet / oSpatialNet / SpatialNet(-Mamba) 这类线性频率 narrow-band 方法更低，但频率独立 narrow-band block 仍带来较高 FLOPs。

## 5. 使用注意

- **ASR 口径要对齐**：log 底数、Mel bin 数、采样率、clip value 和 ASR 前端设置必须一致，否则直接喂 ASR 会错位。
- **听感与识别分开看**：mask 可能 PESQ 更高，mapping 可能 DNSMOS 更稳；ASR 指标和 waveform 听感不一定同向。
- **vocoder 不是无损逆变换**：vocoder 会修改 Mel 谱并降低 ASR fidelity，适合作为兼容 waveform 系统的次优路径。
- **单通道定位**：远场阵列场景仍要和 [[方向/AI语音/知识/基础概念/Beamforming（波束形成）|Beamforming]]、[[方向/AI语音/知识/基础概念/Array Audio Signal（阵列音频信号）|Array Audio Signal]] 分工看。

## 6. 关键来源

- [CleanMel paper](https://arxiv.org/abs/2502.20040)
  - 内容定位：CleanMel 原始论文，定义 Mel 谱增强目标、网络结构、英文/中文测试集和 ASR / speech quality 结果。
  - 用途：方法定义、架构和性能指标。
  - 核验日期：2026-08-11
- [Audio-WestlakeU/CleanMel](https://github.com/Audio-WestlakeU/CleanMel)
  - 内容定位：官方 PyTorch 实现，README 标注 TASLP 2025 accepted，并提供 checkpoint / demo / 推理入口。
  - 用途：代码复现和模型权重入口。
  - 核验日期：2026-08-11
- [CleanMel demo page](https://audio.westlake.edu.cn/Research/CleanMel.html)
  - 内容定位：官方项目页，提供摘要、代码、PDF 和音频 demo 入口。
  - 用途：快速听样例和确认项目归属。
  - 核验日期：2026-08-11

## 7. 相关对象

- [[方向/AI语音/团队/Audio-WestlakeU（西湖大学音频实验室）]]：CleanMel 的团队入口。
- [[方向/AI语音/模型/Mel-McNet]]：同属 Mel 域增强 / ASR 前端友好路线，但 Mel-McNet 是在线多通道框架。
- [[方向/AI语音/知识/基础概念/Spectrogram（声谱图）]]、[[方向/AI语音/知识/基础概念/STFT（短时傅里叶变换）]]：CleanMel 的表示基础。
- [[方向/AI语音/评估/CHiME（语音分离与识别挑战赛）]]：CleanMel 的 CHiME4 ASR / enhancement 评测入口。

## 8. 待验证

- 官方 pretrained checkpoints 的具体模型名、采样率、Mel bin 和推理命令是否与论文设置完全一致。
- 中文实时语音 Agent 场景中，direct Mel-to-ASR 与 vocoder waveform 路径的 WER / 延迟差异。
- 与 Mel-McNet、SenSE、[[方向/AI语音/模型/AnyEnhance]] 在同一小样本中文集上的听感、ASR 和 RTF 对比。

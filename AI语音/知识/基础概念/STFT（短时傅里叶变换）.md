---
title: STFT（短时傅里叶变换）
类型: 概念
发表时间:
时间依据: 基础信号处理变换；非单篇模型、论文或产品发布
相关主题:
  - 信号处理
  - 音频表示
aliases:
  - STFT
  - stft
  - Short-Time Fourier Transform
  - short-time Fourier transform
  - 短时傅里叶变换
  - 短时傅立叶变换
tags:
  - 类型/对象
  - 方向/AI语音
  - 主题/信号处理
  - 主题/音频表示
---

# STFT（短时傅里叶变换）

## 1. 身份

STFT 就是用移动的窗函数将长信号切块，对每一块分别做傅里叶变换，从而把一维的时域声音信号变成二维的“时域-频域”语谱图。
`STFT`（Short-Time Fourier Transform，短时傅里叶变换）是把一维波形切成**重叠短窗**、逐窗做傅里叶变换，得到**时间 × 频率 × 复数值**的时频表示 $X(t, f)$。它是语音增强、分离、波束形成、ASR/TTS 前端的事实默认变换——大部分语音模型不是在 waveform 上工作，就是在 STFT 上工作。

最小形式：

$$
X(t, f) = \sum_{n} x(n) \cdot w(n - t \cdot \text{hop}) \cdot e^{-j 2 \pi f n / N}
$$

其中 `w` 是窗函数（Hann / Hamming 等），`hop` 是帧移，`N` 是 FFT 长度。每个时频点都是复数：幅度对内容、相位对时序/空间结构（见 [[方向/AI语音/知识/基础概念/IPD（通道间相位差）|IPD]]）。

## 2. 边界

- **STFT ≠ spectrogram**：[[方向/AI语音/知识/基础概念/Spectrogram（声谱图）|Spectrogram]] 是取 STFT 幅度/功率后的二维表示，丢了相位；STFT 是含相位的复变换。
- **STFT ≠ mel**：mel spectrogram 是对 STFT 功率谱再做 filterbank 压缩，频率轴重分配、信息有损。
- **STFT ≠ waveform 域**：时域模型（Conv-TasNet 类）直接建模波形，不走 STFT；两者是并行的表示路线。

## 3. 关键参数

- `window length`（窗长，如 25 ms）：决定频率分辨率——窗越长频率分得越细，时间分辨率越差。
- `hop length`（帧移，如 10 ms / 50% 重叠）：决定时间轴密度与序列长度。
- `n_fft`：FFT 点数，通常 ≥ 窗长，多余补零。
- `window function`：Hann / Hamming 等，减少窗边缘频谱泄漏。
- 参数必须与 `sample rate` 配套：同一窗长在不同采样率下对应的毫秒数不同。

## 4. 为什么重要

- **语音增强 / 分离的默认域**：mask、deep filtering、complex spectral mapping（[[方向/AI语音/模型/TF-GridNet|TF-GridNet]]、SGMSE+）都在 STFT 上做。
- **多通道处理的基础**：[[方向/AI语音/知识/基础概念/MVDR（最小方差无失真响应）|MVDR]] / [[方向/AI语音/知识/基础概念/WPE（加权预测误差）|WPE]] 逐频点算权重 / 预测；[[方向/AI语音/知识/基础概念/IPD（通道间相位差）|IPD]] / [[方向/AI语音/知识/基础概念/ILD（双耳声级差）|ILD]] 是 STFT 域特征。
- **训练保真约束**：STFT loss / multi-resolution STFT loss 是生成式语音系统防止幻觉的常用约束。

## 5. 使用注意

- **时频分辨率不可兼得**：窗长是时间 vs 频率分辨率的唯一取舍旋钮。
- **相位重建难**：只处理幅度会丢相位；还原波形要估相位（如 iSTFT + Griffin-Lim）或靠神经 vocoder / decoder。
- **数值尺度**：幅度动态范围大，常做 log / dB 压缩后再喂模型。
- **iSTFT 可逆性**：窗函数 + 帧移需满足 COLA（constant overlap-add）条件才能无损重建。

## 6. 关键来源

- [SciPy ShortTimeFFT](https://docs.scipy.org/doc/scipy/reference/generated/scipy.signal.ShortTimeFFT.html)
  - 内容定位：STFT 的规范定义与参数（窗、hop、FFT、COLA 重建）。
  - 用途：确认变换定义、参数语义和可逆重建条件。
  - 核验日期：2026-08-06
- [librosa.stft](https://librosa.org/doc/latest/generated/librosa.stft.html)
  - 内容定位：Python 音频库中 STFT 的工程接口和参数。
  - 用途：复现实验时固定窗 / hop / n_fft 参数的实现入口。
  - 核验日期：2026-08-06

## 7. 相关对象

- [[方向/AI语音/知识/基础概念/Spectrogram（声谱图）|Spectrogram]]：STFT 的幅度/功率表示，丢弃相位。
- [[方向/AI语音/知识/基础概念/IPD（通道间相位差）|IPD]]、[[方向/AI语音/知识/基础概念/ILD（双耳声级差）|ILD]]：多通道 STFT 上计算的空间特征。
- [[方向/AI语音/知识/基础概念/MVDR（最小方差无失真响应）|MVDR]]、[[方向/AI语音/知识/基础概念/WPE（加权预测误差）|WPE]]、[[方向/AI语音/知识/基础概念/Beamforming（波束形成）|Beamforming]]：STFT 域的多通道处理。
- [[方向/AI语音/模型/TF-GridNet|TF-GridNet]]：complex STFT 域建模的代表模型。
- [[方向/AI语音/知识/基础概念/Vocoder（声码器）|Vocoder]]：把 STFT / mel 表示还原为波形的输出侧。
- [[方向/AI语音/知识/技术路线/语音网络结构与模块|语音网络结构与模块]]：STFT/mel 前端在语音模型中的位置。

## 8. 待验证

- 目标设备上窗长 / hop / n_fft 与实时链路的延迟、算力关系是否需要单独列表。
- STFT loss、multi-resolution STFT loss 与 SI-SDR 在训练目标里的组合取舍（与 Spectrogram 笔记共用待验证项）。

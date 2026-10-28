---
title: Fbank（滤波器组特征）
类型: 概念
aliases:
  - fbank
  - Fbank
  - FBANK
  - filterbank features
  - filter bank features
  - log-Mel filterbank features
  - Mel filterbank features
  - 滤波器组特征
  - 梅尔滤波器组特征
tags:
  - 方向/AI语音
  - 类型/对象
  - 主题/音频表示
  - 主题/特征提取
  - 任务/ASR
---

# Fbank（滤波器组特征）

## 1. 身份

`fbank` 在 ASR / 语音模型里通常指 **filterbank features**，更常见的是 log-Mel filterbank features：先把 waveform 变成短时频谱，再用一组 Mel 滤波器把线性频率 bins 汇总成 Mel 频带，最后取 log / dB 压缩。

边界：这里的 fbank 是**声学特征表示**，不是空间滤波器组，也不是可逆音频格式。它常作为 ASR encoder、Whisper-like encoder 或语音 tokenizer 前端输入。

## 2. 怎么得到

典型链路：

```text
waveform
  -> pre-emphasis / dithering / framing
  -> windowing
  -> STFT / power spectrum
  -> Mel filterbank
  -> log compression
  -> per-frame fbank feature
```

常见实现还会做 CMVN（cepstral mean and variance normalization）或全局均值方差归一化。是否包含 pitch、delta / delta-delta、能量项，要看具体 recipe。

## 3. 和相邻表示的区别

- **spectrogram**：线性频率轴上的时频能量图；fbank 是经过滤波器组压缩后的频带特征。
- **Mel spectrogram**：和 fbank 很接近，很多深度学习代码里几乎等价；差别通常来自实现细节、是否取 log、是否做归一化。
- **MFCC**：在 log-Mel fbank 后再做 DCT，把频带能量压成倒谱系数；传统 GMM/HMM ASR 常用。
- **waveform**：保留原始时域信号；fbank 已经丢掉相位和部分频率细节。

## 4. 为什么 ASR 常用

- **压缩频率轴**：把高维频谱压成几十到一百多个 Mel bins，序列模型更容易处理。
- **贴近语音感知**：低频分辨率更细，高频更粗，符合语音识别常用的听觉尺度假设。
- **工程稳定**：相比直接吃 waveform，fbank 前端更可控，参数和归一化容易固定。
- **足够支撑文本监督**：ASR 只需要保留足够识别内容的声学线索，不要求无损重建波形。

## 5. 常见参数

- **sample rate**：常见 16 kHz；必须和模型训练配置一致。
- **frame length / shift**：常见 25 ms 窗、10 ms hop；决定时间分辨率。
- **num mel bins**：常见 80，也有 40、64、128；决定每帧特征维度。
- **fmin / fmax**：Mel 滤波器覆盖频段；影响低频噪声和高频擦音保留。
- **log base / dB scale**：不同库的 log 和 dynamic range 截断不完全一致。
- **CMVN**：训练和推理必须保持同一套归一化口径。

## 6. 在 LLM-SE 里的位置

在语义 tokenizer 路线里，fbank 是 ASR encoder 的输入特征：

```text
waveform -> fbank -> ASR encoder -> semantic representation / token
```

它提供的是声学证据，不是干净语义本身。直接量化 fbank 往往只能得到低层声学格子；需要 ASR encoder 和文本监督把表示推向“足以预测文本”的语义空间。

## 7. 常见误读

- **不是 clean target**：noisy fbank 仍包含噪声、混响、信道和压缩伪影。
- **不是可逆表示**：丢了相位和细频率结构，不能靠固定反变换还原高质量 waveform。
- **不是所有 filterbank**：阵列语音里的 spatial filter bank 是空间滤波；这里是频率滤波器组特征。
- **不能跨库默认兼容**：Kaldi、torchaudio、librosa、Whisper 风格 log-Mel 的参数和数值尺度可能不同。

## 8. 相关对象

- [[方向/AI语音/知识/基础概念/STFT（短时傅里叶变换）]]：fbank 通常从 STFT 功率谱继续变换得到。
- [[方向/AI语音/知识/基础概念/Spectrogram（声谱图）]]：fbank 是 spectrogram 的 Mel 频带压缩形态。
- [[方向/AI语音/知识/基础概念/音频数据预处理]]：fbank 属于特征提取阶段。
- [[方向/AI语音/知识/技术路线/LLM-SE Stage 0（表示空间准备）]]：semantic tokenizer 的 ASR encoder 输入。
- [[方向/AI语音/模型/Whisper]]：使用 log-Mel spectrogram / fbank 风格前端的 ASR 代表。
- [[方向/AI语音/工具/librosa（Python 音频分析库）]]：常用于提取 mel spectrogram、MFCC 等相邻特征。

## 9. 关键来源

- [Kaldi Tools - compute-fbank-feats](https://kaldi-asr.org/doc/tools.html)
  - 内容定位：Kaldi `compute-fbank-feats` 工具，用于创建 Mel-filter bank（FBANK）特征文件。
  - 用途：fbank 作为 ASR 声学特征的工程语境。
  - 核验日期：2026-09-04
- [torchaudio.compliance.kaldi.fbank](https://docs.pytorch.org/audio/stable/generated/torchaudio.compliance.kaldi.fbank.html)
  - 内容定位：PyTorch / torchaudio 中兼容 Kaldi 的 fbank 特征函数和参数。
  - 用途：核对常见工程参数名。
  - 核验日期：2026-09-04

## 10. 待验证

- 当前 LLM-SE 方案里 fbank 是否固定为 80-bin、25 ms / 10 ms，还是沿用具体 ASR encoder 的原始配置。
- 是否需要单独拆出 `MFCC` 概念页。

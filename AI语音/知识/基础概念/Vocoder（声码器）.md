---
title: Vocoder（声码器）
类型: 概念
发表时间:
时间依据: 基础语音合成/音频生成模块；非单一发表物
相关主题:
  - 语音生成
  - 音频表示
相关模型:
  - "[[方向/AI语音/模型/X-Codec2]]"
aliases:
  - 声码器（Vocoder）
  - Vocoder
  - 声码器
  - vocoder
tags:
  - 类型/对象
  - 方向/AI语音
  - 主题/语音生成
  - 主题/音频表示
---

# Vocoder（声码器）

## 1. 身份

Vocoder 是把声学表示还原成可听波形的模块。现代语音模型里，它通常负责 **mel / spectrogram / SSL 表示 / latent -> waveform**，是 TTS、语音增强、语音生成和部分 codec 路线的最后一段。

边界：vocoder 不是 ASR encoder，也不是完整 codec。[[方向/AI语音/知识/基础概念/NAC（神经音频 Codec）|Codec]] 通常包含 encoder + decoder；vocoder 更常指“给定声学条件后生成波形”的 decoder-only 模块。某些 codec decoder 可以承担 vocoder 角色，但两者不能完全等同。

## 2. 基本链路

```text
text / noisy speech / latent
  -> acoustic model / enhancer / generator
  -> mel / spectrogram / SSL representation / latent
  -> vocoder
  -> waveform
```

TTS 里常见链路：

```text
text -> acoustic model -> mel spectrogram -> vocoder -> speech waveform
```

这里的 `mel spectrogram -> waveform` 不是固定可逆转换。Mel 已经压缩频率轴且通常丢掉相位，多个 waveform 可以对应很接近的 mel；vocoder 的作用就是根据训练学到的语音/音频先验，补回相位、瞬态、谐波和高频细节。

```text
完整 complex STFT -> iSTFT -> waveform        # 可用固定反变换
magnitude spectrogram -> phase estimation -> waveform
mel spectrogram -> neural vocoder -> waveform # 通常需要学习模块
```

语音增强 / 生成式恢复里常见链路：

```text
degraded speech -> model -> enhanced representation -> vocoder -> enhanced waveform
```

## 3. 输入类型

| 输入表示 | 常见场景 | 主要风险 |
|---|---|---|
| [[方向/AI语音/知识/基础概念/Spectrogram（声谱图）]] / mel spectrogram | TTS、FlowSE 类 mel 生成 | 相位由 vocoder 重建，音质受 vocoder 上限限制 |
| STFT / linear spectrogram | 频域增强、传统 analysis-synthesis | 相位和复数谱处理更麻烦 |
| SSL 表示 | UniPASE / PASE 类表示回归 | 表示层选择会影响内容、音色和幻觉 |
| codec token / latent | codec LM、DiT latent、VAE latent | decoder 质量和压缩损失锁上限 |

## 4. 常见路线

| 路线 | 代表 | 特点 |
|---|---|---|
| 传统参数声码器 | WORLD、STRAIGHT | 可解释、可控，但自然度有限 |
| 自回归神经 vocoder | WaveNet、WaveRNN | 音质高但慢 |
| GAN vocoder | HiFi-GAN、MelGAN、Parallel WaveGAN | 快，TTS 工程常用 |
| 扩散 vocoder | DiffWave、WaveGrad | 质量高，采样慢 |
| Flow / ODE vocoder | flow / rectified-flow 系 | 试图用少步采样平衡质量和速度 |
| Vocos / codec decoder | Vocos、DAC decoder、BiCodec decoder、[[方向/AI语音/模型/X-Codec2]] decoder | 常接 codec / latent / 表示回归路线 |

## 5. 为什么重要

- **音质上限**：上游预测再好，vocoder 失真、金属音、过平滑或相位错误都会直接进入最终音频。
- **延迟瓶颈**：实时 TTS / 语音增强不仅看主模型，还要看 vocoder 推理和首包延迟。
- **幻觉与音色**：表示到波形的重建会影响说话人相似度、音色稳定性和内容可懂度。
- **跨任务复用**：同一个 vocoder 思路可服务 TTS、增强、带宽扩展、codec LM 和音频生成。

## 6. 和相邻概念的区别

- **vocoder vs codec**：vocoder 通常是表示到波形的生成器；codec 是压缩-重建系统，包含 encoder 和 decoder。
- **vocoder vs codec decoder**：输入是 mel / spectrogram / acoustic feature 时通常叫 vocoder；输入是 codec token / RVQ code / continuous latent 时通常叫 codec decoder。若链路是 `token / latent -> mel -> waveform`，就是 codec decoder / acoustic decoder 加 vocoder 两段。
- **vocoder vs spectrogram**：[[方向/AI语音/知识/基础概念/Spectrogram（声谱图）|spectrogram]] 是表示，vocoder 是把表示变回波形的模型。
- **vocoder vs ASR decoder**：ASR decoder 输出文字 token；vocoder 输出音频波形。
- **vocoder vs Flow Matching**：[[方向/AI语音/知识/基础概念/Flow Matching（流匹配）|Flow Matching]] 是训练/采样范式，vocoder 是输出波形模块；两者可以组合。

## 7. 使用注意

- 不要只评估 mel loss：mel 接近不代表 waveform 听感、相位、瞬态和说话人都对。
- vocoder 要和输入表示匹配：训练在 80-bin mel 上的 vocoder 不能随便接别的 mel 参数或 SSL latent。
- 生成式增强里要测内容保持：vocoder 可能让音频更自然，但也可能掩盖内容改写。
- 流式场景要测 chunk 边界：vocoder 可能产生爆音、音色跳变或上下文不连续。

## 8. 相关对象

- [[方向/AI语音/知识/基础概念/Spectrogram（声谱图）|声谱图]]：mel / spectrogram 常作为 vocoder 输入。
- [[方向/AI语音/知识/基础概念/Spectral Envelope（频谱包络）|Spectral Envelope（频谱包络）]]：vocoder 输出质量会直接影响谱包络、音色和元音/formant 结构。
- [[方向/AI语音/知识/基础概念/NAC（神经音频 Codec）|神经音频 Codec]]：codec decoder 与 vocoder 相邻但不完全等同。
- [[方向/AI语音/模型/X-Codec2|X-Codec2]]：speech token 到 waveform 的 codec decoder 案例。
- [[方向/AI语音/知识/技术路线/语音网络结构与模块|语音网络结构与模块]]：vocoder 是语音模型输出侧模块。
- [[方向/AI语音/MOC - TTS|TTS]]：TTS 常用 acoustic model + vocoder 或 codec/tokenizer 路线。
- [[方向/AI语音/知识/基础概念/Flow Matching（流匹配）|Flow Matching]]：mel/latent 生成后通常仍需 vocoder / decoder 还原波形。

## 9. 待验证

- 当前 TTS / 语音增强链路更适合 HiFi-GAN / Vocos / codec decoder / flow vocoder 哪类输出头。
- 长音频和流式场景下，vocoder 是否是首包延迟和边界伪影的主要来源。
- 中文、方言、漏音和混响样本中，不同 vocoder 对说话人保持和内容保持的影响。

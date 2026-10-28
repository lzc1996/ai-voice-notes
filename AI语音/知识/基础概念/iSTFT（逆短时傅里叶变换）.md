---
title: iSTFT（逆短时傅里叶变换）
类型: 算法
aliases:
  - ISTFT
  - iSTFT
  - Inverse Short-Time Fourier Transform
  - inverse short-time Fourier transform
  - 逆短时傅里叶变换
tags:
  - 类型/对象
  - 方向/AI语音
  - 主题/信号处理
  - 主题/音频表示
---

# iSTFT（逆短时傅里叶变换）

## 1. 身份

iSTFT 是 STFT 的合成过程：把按帧排列的复数频谱恢复为时域波形。它需要频谱的幅度与相位；只有幅度时，必须先用 Griffin-Lim 或神经声码器等方法补回相位信息。

## 2. 核心机制

数据流：

```text
复数 STFT -> 每帧逆 FFT -> 乘合成窗 -> 按 hop 重叠相加 -> 波形
```

对第 $m$ 帧频谱 $X_m[k]$ 做逆离散傅里叶变换得到帧信号 $y_m[n]$，再按帧移 $H$ 放回时间轴。若窗函数为 $w[n]$，重建信号可写为：

$$
\hat{x}[n] = \frac{\sum_m w[n-mH] y_m[n-mH]}{\sum_m w^2[n-mH]}
$$

分母是窗口平方的重叠和；实现通常在分母非零时做归一化。$H$ 是 hop length，$m$ 是帧索引，$n$ 是帧内采样索引。

## 3. 可逆条件与边界

- **窗与帧移必须匹配**：重叠区域的窗口平方和应保持可归一化；COLA/NOLA 条件不满足时，可能出现幅度起伏、边界伪影或无法稳定重建。
- **中心填充要一致**：STFT 是否 `center`、边界如何补零，必须与 iSTFT 使用同一约定，否则波形会产生时间偏移或长度差异。
- **频谱信息必须完整**：mel 频谱、幅度谱或经过压缩的表示不是 iSTFT 的直接输入，通常要先恢复线性频率轴和相位。
- **长度需要显式处理**：padding、最后一帧和 `length` 参数会影响输出样本数；实时系统还需考虑窗口缓冲带来的算法延迟。

## 4. 在语音系统中的位置

iSTFT 常作为语音增强、分离和频域生成模型的输出层：模型预测目标复谱或掩码后，经 iSTFT 输出波形。声码器也可能内部预测复谱，再用 iSTFT 完成最终合成。

## 5. 相关对象

- [[方向/AI语音/知识/基础概念/STFT（短时傅里叶变换）]]：分析变换，iSTFT 是其合成对应过程。
- [[方向/AI语音/知识/基础概念/Spectrogram（声谱图）]]：通常只保留 STFT 的幅度或功率，不能直接无损地 iSTFT。
- [[方向/AI语音/知识/基础概念/Vocoder（声码器）]]：可负责从非复数声学表示生成波形，或把 iSTFT 作为内部合成步骤。

## 6. 关键来源

- [SciPy ShortTimeFFT](https://docs.scipy.org/doc/scipy/reference/generated/scipy.signal.ShortTimeFFT.html)
  - 内容定位：STFT/iSTFT 参数、窗口重叠和重建约定。
  - 用途：核对实现中的窗函数、帧移与边界行为。

## 7. 待验证

- 在当前实时语音链路中，`center`、padding、`hop length` 与目标输出长度是否统一。
- 不同窗函数和 hop 配置对重建误差、延迟及边界伪影的实际影响。

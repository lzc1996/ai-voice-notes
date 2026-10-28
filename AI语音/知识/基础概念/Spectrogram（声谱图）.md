---
title: Spectrogram（声谱图）
类型: 概念
发表时间:
时间依据: 基础信号处理表示；非单篇模型、论文或产品发布
相关主题:
  - 信号处理
  - 音频表示
相关模型:
  - "[[方向/AI语音/模型/Whisper]]"
aliases:
  - 声谱图（Spectrogram）
  - Spectrogram
  - 声谱图
  - 语谱图
  - spectrogram
  - spectro
tags:
  - 类型/对象
  - 方向/AI语音
  - 主题/信号处理
  - 主题/音频表示
---

# Spectrogram（声谱图）

## 1. 身份

Spectrogram 是把一段一维音频信号展开成 **时间 × 频率 × 能量** 的二维表示。横轴通常是时间，纵轴是频率，颜色或数值表示该时间窗内不同频率成分的强度。

边界：spectrogram 不是模型，也不是音频本身；它是特征表示。模型看到的是这个表示，是否还能还原成高质量波形，取决于相位、窗口参数、decoder / vocoder 和下游任务。

## 2. 怎么得到

- **STFT spectrogram**：先对音频做 [[方向/AI语音/知识/基础概念/STFT（短时傅里叶变换）|STFT]]（重叠窗口逐窗变换），再取幅度或功率。
- **log spectrogram**：对幅度或功率取对数，让动态范围更接近人耳和神经网络可处理尺度。
- **mel spectrogram**：把频率轴映射到 mel 听觉尺度，常用于 ASR、TTS、音频分类。
- **log-Mel spectrogram**：mel spectrogram 再取 log；[[方向/AI语音/模型/Whisper|Whisper]] 这类 ASR 模型常用这种输入。

## 3. Mel 是什么

Mel 是一种更接近人耳听感的频率尺度：低频分得更细，高频压得更粗。mel spectrogram 不是直接看线性 Hz 频率轴，而是先做 STFT 得到功率谱，再乘上一组 mel filterbank，把线性频率 bins 汇总成若干个 mel bands。

```text
waveform
  -> STFT
  -> magnitude / power spectrogram
  -> mel filterbank
  -> mel spectrogram
  -> log / dB compression
  -> log-Mel spectrogram
```

直觉：mel 把“模型需要看的频率细节”按人耳和语音任务重新分配。语音的音素、共振峰和可懂度主要集中在较低频段，所以 mel 对 ASR、TTS 和音频分类很实用；但它压缩了频率轴、丢了相位，不适合直接当作高保真恢复的唯一输出。

注意：`mel -> waveform` 不是固定逆变换。只有保留复数谱（幅度 + 相位）时，`complex STFT -> iSTFT -> waveform` 才是明确的信号处理反变换；mel spectrogram 通常要交给 [[方向/AI语音/知识/基础概念/Vocoder（声码器）|vocoder]] 或相位重建算法来补回缺失信息。

## 4. 怎么读图

- **横轴看时间**：音节、爆破音、停顿、切块边界和尾音拖影都沿时间轴观察。
- **纵轴看频率**：低频看 [[方向/AI语音/知识/基础概念/F0（基频）]] 和浊音能量，中频看 [[方向/AI语音/知识/基础概念/Vowel（元音）]] / [[方向/AI语音/知识/基础概念/Formant（共振峰）]]，高频看 [[方向/AI语音/知识/基础概念/Fricative（擦音）]]、齿音、噪声和带宽。
- **颜色看能量**：颜色越深或越亮通常表示能量越强；不同软件配色不同，要看图例或设置。
- **细横线多是谐波**：有稳定 [[方向/AI语音/知识/基础概念/F0（基频）]] 的浊音会出现一排平行谐波线。
- **宽暗带多是 formant**：[[方向/AI语音/知识/基础概念/Vowel（元音）]] 区常看到随时间缓慢变化的宽频带结构。
- **垂直短条多是瞬态**：爆破音、点击声、拼接点和削波常表现为很短的宽带竖纹。

## 5. 在 Praat 里看

在 [[方向/AI语音/工具/Praat（语音学分析工具）]] 中，打开音频后进入 `View & Edit`，用 `Spectrum` -> `Show spectrogram` 开启声谱图。语音诊断先用 `0-8000 Hz` 作为起点；宽带 TTS、48 kHz 录音、[[方向/AI语音/知识/基础概念/Fricative（擦音）]] 或高频伪影再提高频率上限。

常用做法是把 noisy / enhanced / clean 三段音频对齐听看：先听主观差异，再看对应时间段的频谱结构是否变化。

## 6. 语音增强读图

- **降噪是否过度**：背景噪声被压掉后，语音谐波和 formant 不应一起被抹平。
- **是否有音乐噪声**：增强后出现随机小岛状亮点，常对应 musical noise。
- **是否有金属感 / 振铃**：固定频带或周期性细纹可能对应神经增强伪影。
- **是否改写内容**：[[方向/AI语音/知识/基础概念/Vowel（元音）]] formant、[[方向/AI语音/知识/基础概念/Fricative（擦音）]] 高频、爆破音瞬态、句尾弱音被改变时，要怀疑内容保持问题。
- **是否有切块边界**：chunk 拼接点附近若出现竖线、能量突变或频谱断裂，要回查 overlap-add / crossfade。
- **是否带宽缺失**：高频整片空白通常意味着采样率、重采样、codec 或模型输出带宽受限。

## 7. 关键参数

- `sample rate`：决定可表示的最高频率。
- `window length` / `n_fft`：窗口越长，频率分辨率越高，时间分辨率越低。
- `hop length`：相邻窗口的步长；越小越平滑，但计算和序列长度更高。
- `window function`：Hann、Hamming 等，用来减少窗口边缘泄漏。
- `magnitude / power / log-power`：决定数值尺度和损失函数行为。
- `mel bins` / `n_mels`：mel spectrogram 的频带数量，影响 ASR/TTS 输入维度和细节保留；常见是 80 或 128，但必须跟模型训练配置一致。
- `fmin` / `fmax`：mel filterbank 覆盖的最低/最高频率；会影响低频噪声、高频 [[方向/AI语音/知识/基础概念/Fricative（擦音）]] 和带宽扩展任务。

## 8. 什么时候用

- ASR：把原始波形转成 log-Mel spectrogram，再交给 encoder。
- TTS：作为声学中间表示或 vocoder 条件，传统声学模型和部分 neural vocoder 常用。
- 语音增强：在频谱域做 mask、deep filtering、predictive enhancement 或 STFT loss。
- 音频分类：用二维时频图喂给 CNN / Transformer。
- Flow / diffusion 语音生成：可以在 mel 或 latent 上生成，再用 vocoder / decoder 还原波形。

## 9. 使用注意

- 时间分辨率和频率分辨率不能同时无限提高；窗口参数就是这个取舍。
- 只看 magnitude 会丢相位；重建波形时要么估相位，要么用神经 vocoder / decoder。
- 不要把 mel 当成可直接固定还原的音频格式；它是压缩过的声学特征，不是 lossless representation。
- mel spectrogram 适合听觉和语音任务，但不一定适合 ECG、工业振动等非音频一维信号。
- 对生成式语音系统，spectrogram loss 能约束频谱保真，但不能单独保证内容不幻觉。
- 不同库的 mel 实现可能不同：HTK / Slaney 标度、归一化方式、功率谱还是幅度谱、log 还是 dB 都会导致数值不兼容；复现实验时要固定实现和参数。

## 10. 相关对象

- [[方向/AI语音/知识/基础概念/STFT（短时傅里叶变换）|STFT]]：spectrogram 由 STFT 幅度/功率得到，是含相位的完整变换。
- [[方向/AI语音/知识/基础概念/Fbank（滤波器组特征）|Fbank]]：把 STFT 功率谱经 Mel filterbank 压缩成 ASR 常用声学特征。
- [[方向/AI语音/知识/基础概念/F0（基频）]]：F0 决定浊音谐波间距。
- [[方向/AI语音/知识/基础概念/音频数据预处理|音频数据预处理]]：spectrogram 是常见特征提取结果。
- [[方向/AI语音/知识/基础概念/Spectral Envelope（频谱包络）|Spectral Envelope（频谱包络）]]：从短时频谱中抽取的平滑频谱外形。
- [[方向/AI语音/模型/Whisper|Whisper]]：输入音频会转换为 log-Mel spectrogram。
- [[方向/AI语音/知识/基础概念/Vocoder（声码器）|声码器]]：常把 mel / spectrogram 还原成 waveform。
- [[方向/AI语音/知识/基础概念/SE（语音增强）导论|语音增强]]：频谱域增强和 STFT loss 是常见路线。
- [[方向/AI语音/知识/基础概念/Flow Matching（流匹配）|Flow Matching]]：mel + vocoder 是一种可用生成空间，但相位和 decoder 上限要单独评估。
- [[方向/AI语音/知识/技术路线/音频方案迁移到一维信号|音频方案迁移到一维信号]]：mel spectrogram 不能原封不动迁移到非音频信号。
- [[方向/AI语音/知识/基础概念/NAC（神经音频 Codec）|神经音频 Codec]]：codec token / latent 是另一类音频表示，不等同于 spectrogram。

## 11. 关键来源

- [SciPy ShortTimeFFT.spectrogram](https://docs.scipy.org/doc/scipy/reference/generated/scipy.signal.ShortTimeFFT.spectrogram.html)
  - 内容定位：说明 spectrogram 可由 STFT 的平方幅度得到。
  - 用途：确认 STFT spectrogram 的信号处理定义。
  - 核验日期：2026-07-30
- [librosa.feature.melspectrogram](https://librosa.org/doc/latest/generated/librosa.feature.melspectrogram.html)
  - 内容定位：Python 音频库中 mel spectrogram 的工程接口和参数。
  - 用途：确认 mel spectrogram 的常见实现入口。
  - 核验日期：2026-07-30
- [OpenAI Whisper 发布页](https://openai.com/index/whisper/)
  - 内容定位：说明 Whisper 把 30 秒音频片段转换成 log-Mel spectrogram 后送入 encoder。
  - 用途：作为 ASR 模型使用 log-Mel spectrogram 的具体例子。
  - 核验日期：2026-07-30

## 12. 待验证

- 当前 ASR / TTS 实验里常用的 mel bins、window 和 hop 参数是否需要单独列成表。
- 语音增强任务里 STFT loss、multi-resolution STFT loss 和 SI-SDR 的组合取舍（与 [[方向/AI语音/知识/基础概念/STFT（短时傅里叶变换）|STFT]] 笔记共用）。

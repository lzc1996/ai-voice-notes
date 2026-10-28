---
title: PCM16（16-bit Pulse Code Modulation）
类型: 概念
发表时间:
时间依据: 数字音频基础格式；非单一发表物
相关任务:
  - 音频数据预处理
  - ASR
  - TTS
  - 语音增强
相关主题:
  - 音频编码
  - waveform
  - 位深
aliases:
  - PCM16
  - PCM 16
  - 16-bit PCM
  - 16 bit PCM
  - signed 16-bit PCM
  - 16位 PCM
  - 16位脉冲编码调制
  - 脉冲编码调制
tags:
  - 类型/对象
  - 方向/AI语音
  - 主题/音频处理
  - 主题/音频编码
  - 主题/waveform
---

# PCM16（16-bit Pulse Code Modulation）

## 1. 身份

`PCM`（Pulse-Code Modulation，脉冲编码调制）是把连续信号按时间采样，再把每个采样值量化并编码成数字序列的方法；它不是单一位深或文件容器。`PCM16` 是其中一种具体格式：用 16 位整数表示每个音频采样点的未压缩线性 PCM waveform，描述的是**采样值的量化格式 / 位深**，不是采样率、声道数，也不是 WAV/FLAC 这类容器。

典型数据流：连续音频 -> 抗混叠滤波与采样 -> 幅度量化 -> 整数编码。PCM 描述这条表示/编码方式；`sample rate` 决定每秒采样次数，bit depth 决定量化级数与动态范围，channels 决定并行波形数。PCM 也可使用 8、16、24、32-bit 整数或浮点表示，因此 PCM 不等于 PCM16。

边界：`16 kHz` 说的是 [[方向/AI语音/知识/基础概念/Sample Rate（采样率）]]；`PCM16` 说的是每个 sample 用多少 bit、以什么整数范围存。一个音频可以是 `16 kHz mono PCM16`，也可以是 `24 kHz mono PCM16` 或 `48 kHz stereo PCM16`。

## 2. 核心口径

- **数值范围**：常见 signed PCM16 样本是 `int16`，范围为 $[-32768, 32767]$。
- **归一化到 float**：工程里常转成 `float32` waveform，近似映射到 $[-1, 1)$，常见写法是 $x=s/32768$。
- **满刻度**：PCM16 的最大可表示幅度对应 [[方向/AI语音/知识/基础概念/dBFS（满刻度分贝）]] 的参考点；超过范围会 clipping。
- **码率计算**：未压缩 PCM 的数据量约为 `sample_rate × channels × bits_per_sample / 8` bytes/s。
- **端序和容器**：WAV/RIFF 里常见 PCM16 是 little-endian；裸 `.pcm` 没有头信息，必须另行记录采样率、声道数、端序和是否 signed。

## 3. 数据流

```text
麦克风 / 音频文件
  -> PCM16 int16 samples
  -> float32 waveform [-1, 1)
  -> 重采样 / 转单声道 / 音量归一化
  -> STFT / mel / SSL encoder / codec tokenizer
```

训练和推理通常不直接在 `int16` 上做神经网络计算，而是在加载阶段把 PCM16 转成 `float32`；导出、实时 API、声卡 I/O 或压缩编码前后才经常回到 PCM16。

## 4. 什么时候用

- **文件交换**：WAV PCM16 是语音数据集中最常见的无损交换格式之一。
- **实时音频接口**：很多语音 API、WebSocket、声卡和嵌入式链路要求传 `PCM16 mono`。
- **训练数据落盘**：比 `float32 WAV` 省一半空间，精度足够多数语音任务。
- **模型输入前处理**：先读 PCM16，再统一到模型要求的采样率、声道和 float waveform。

## 5. 常见坑

- **把 PCM16 当成 16 kHz**：二者完全不同；一个是位深，一个是采样率。
- **忘记归一化**：把 `int16` 直接喂给模型会让幅度尺度差 32768 倍。
- **重复归一化**：音频库已经返回 `[-1,1]` float 时，再除以 32768 会把音量压到几乎静音。
- **裸 PCM 缺元数据**：没有 WAV header 时，必须手动知道 `sample_rate / channels / endian / sample format`。
- **导出 clipping**：float waveform 写回 PCM16 前要 clip 到安全范围，否则超过 full scale 的样本会被截断或溢出。

## 6. 相关对象

- [[方向/AI语音/知识/基础概念/PCM（脉冲编码调制）]]：上位概念；本页只讨论 16-bit 整数 PCM 格式。
- [[方向/AI语音/知识/基础概念/音频数据预处理]]：PCM16 常出现在格式统一、位深统一和实时输入输出阶段。
- [[方向/AI语音/知识/基础概念/Sample Rate（采样率）]]：采样率决定每秒多少个 sample；PCM16 决定每个 sample 怎么存。
- [[方向/AI语音/知识/基础概念/dBFS（满刻度分贝）]]：PCM 固定点满刻度是 dBFS 的常见参考。
- [[方向/AI语音/知识/基础概念/Spectrogram（声谱图）]]：PCM16 读成 waveform 后，常进一步转 STFT / spectrogram。
- [[方向/AI语音/模型/OpenAI Realtime]]：实时语音链路中常见 `PCM16 mono` 这类传输口径。

## 7. 关键来源

- [Microsoft WAVEFORMATEX structure](https://learn.microsoft.com/en-us/windows/win32/api/mmreg/ns-mmreg-waveformatex)
  - 内容定位：WAVE 格式头中的 `nSamplesPerSec`、`nChannels`、`wBitsPerSample`、`nBlockAlign` 等字段。
  - 用途：确认 PCM 音频里采样率、声道数、位深和字节对齐是分开的格式字段。
  - 核验日期：2026-09-17
- [SciPy scipy.io.wavfile.read](https://docs.scipy.org/doc/scipy/reference/generated/scipy.io.wavfile.read.html)
  - 内容定位：WAV PCM 位深与 NumPy dtype 的对应关系，包括 16-bit PCM 使用 `int16` 范围。
  - 用途：确认 PCM16 的 signed integer 表示和常见数值范围。
  - 核验日期：2026-09-17
- [Python wave module](https://docs.python.org/3/library/wave.html)
  - 内容定位：Python 标准库 `wave` 读写 WAV，支持 uncompressed PCM encoded wave files。
  - 用途：确认 WAV PCM 是常见无压缩音频交换口径。
  - 核验日期：2026-09-17

## 8. 工程待决策

- **格式口径**：`PCM16` 只说明位深；实时链路必须在接口或配置中同时写明 `sample_rate / channels / endian / sample format`，因此本页不替具体项目决定 `16 kHz` 还是 `24 kHz`。
- **对象结构**：暂不单独创建 `Float32 Audio` 页；当前转换规则已在本页覆盖，等出现独立的量化误差或数据交换问题再拆。
- **QA 建议**：数据 QA 固定记录 `dtype / sample_rate / channels / peak dBFS / clipping rate`；这是工程字段约定，不需要继续留在待验证区。

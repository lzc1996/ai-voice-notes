---
title: dBFS（满刻度分贝）
类型: 概念
相关任务:
  - VAD
相关主题:
  - 音频处理
aliases:
  - dB FS
  - Decibels relative to full scale
  - 满刻度分贝
  - 分贝满刻度
  - 数字满刻度分贝
tags:
  - 类型/对象
  - 方向/AI语音
  - 主题/音频处理
---

# dBFS（满刻度分贝）

## 1. 身份

`dBFS` 是 **decibels relative to full scale**：把数字音频系统的 full scale 当作 0 dB 参考点来表示幅度或电平。它回答的是“离数字满刻度还有多少余量”，不是房间里的真实声压，也不是人的主观响度。

边界：`dBFS` 常见于 PCM、DAW、音频库和 VAD 阈值；声学声压用 [[方向/AI语音/知识/基础概念/SPL（声压级）|dB SPL]]，广播/流媒体响度常用 LUFS。不同工具还要分清 peak dBFS、RMS dBFS、AES17 sine reference 和相对峰值归一化 dB。

## 2. 最小公式

幅度量常用：

$$
\mathrm{dBFS} = 20\log_{10}\left(\frac{|x|}{x_{FS}}\right)
$$

- `0 dBFS`：达到选定的数字满刻度参考。
- 负值：低于满刻度，例如 `-20 dBFS`。
- `-inf dBFS`：完全静音或幅度为 0 时的对数结果。
- `> 0 dBFS`：固定点 PCM / 导出 / DAC 侧通常意味着削波风险；浮点内部链路可能临时超过，但不能把它当作安全输出电平。

## 3. 工程用途

- **静音裁剪 / VAD**：用 `-40 dBFS`、`-30 dBFS` 这类阈值粗分静音和非静音。
- **录音 QA**：检查峰值是否接近 0 dBFS，判断是否有 clipping 或 headroom 不足。
- **音量归一**：把样本 RMS / peak 调到指定 dBFS，但这不等于主观响度一致。
- **特征尺度**：log spectrogram 或 amplitude-to-dB 常借用 dB 公式；只有参考点是 full scale 时才应叫 dBFS。

## 4. 常见坑

- **阈值不可裸迁移**：麦克风增益、归一化、声卡、通道混合和预处理都会改变 dBFS 读数。
- **peak 与 RMS 不可混用**：同一个音频的 peak dBFS 和 RMS dBFS 可以差很多，VAD 阈值必须写清楚口径。
- **dBFS 不是响度**：同样 `-20 dBFS` 的信号，播放设备和监听音量不同，实际声压完全不同。
- **相对 dB 不是 dBFS**：`ref=np.max` 这类写法得到的是相对当前信号峰值的 dB，不是相对数字满刻度。

## 5. 关键来源

- [FADGI - Decibels relative to full scale](https://www.digitizationguidelines.gov/term.php?term=decibelsrelativetofullscale)
  - 内容定位：定义 dB FS / dBFS 是数字系统中相对 full scale 的幅度电平单位，并说明 0 dB FS 与最大可用峰值的关系。
  - 用途：建立概念定义和标准口径提醒。
  - 核验日期：2026-08-11
- [librosa.amplitude_to_db](https://librosa.org/doc/latest/generated/librosa.amplitude_to_db.html)
  - 内容定位：记录幅度到 dB 的工程公式、参考值 `ref` 和 `top_db` 截断。
  - 用途：区分一般 amplitude-to-dB 与真正 dBFS 的参考点差异。
  - 核验日期：2026-08-11
- [pydub silence utilities](https://github.com/jiaaro/pydub/blob/master/API.markdown)
  - 内容定位：`silence_thresh` 使用 dBFS 作为静音阈值口径。
  - 用途：连接 dBFS 和工程里的静音裁剪 / VAD 阈值。
  - 核验日期：2026-08-11

## 6. 相关对象

- [[方向/AI语音/知识/基础概念/Level（电平）]]：电平总入口，用来区分 dBFS、dB SPL、RMS、peak 和响度。
- [[方向/AI语音/知识/基础概念/Energy-based VAD（基于能量的语音活动检测）|Energy-based VAD]]：常把 RMS / dBFS 当作最小阈值特征。
- [[方向/AI语音/知识/基础概念/VAD（Voice Activity Detection）|VAD]]：dBFS 阈值能做低成本 baseline，但不负责语义或说话人判断。
- [[方向/AI语音/知识/基础概念/PCM16（16-bit Pulse Code Modulation）]]：固定点 PCM 的 full scale 是 dBFS 最常见的工程参考点之一。
- [[方向/AI语音/知识/基础概念/音频数据预处理|音频数据预处理]]：dBFS 常用于音量检查、静音裁剪和训练数据 QA。
- [[方向/AI语音/知识/基础概念/Spectrogram（声谱图）|Spectrogram]]：log / dB 压缩要写清参考点，避免把相对 dB 误称为 dBFS。

## 7. 待验证

- 当前语音 Agent 采集链路里，VAD 阈值应该用 peak dBFS、RMS dBFS 还是短时能量的相对 dB。
- 中文远场会议和近讲麦克风的静音阈值是否需要分两套默认值。
- 训练数据 QA 中是否需要同时记录 peak dBFS、RMS dBFS、LUFS 和 clipping rate。

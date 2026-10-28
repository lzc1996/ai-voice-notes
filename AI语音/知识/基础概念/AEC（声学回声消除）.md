---
title: AEC（声学回声消除）
类型: 概念
发表时间:
时间依据: 实时通信音频处理基础概念；非单一发表物
相关任务:
  - 语音增强
  - 实时语音交互
  - 多通道增强
aliases:
  - AEC
  - Acoustic Echo Cancellation
  - acoustic echo cancellation
  - Acoustic Echo Canceller
  - 回声消除
  - 声学回声消除
  - 回声抵消
tags:
  - 类型/对象
  - 方向/AI语音
  - 任务/语音增强
  - 任务/实时语音交互
  - 主题/回声消除
---

# AEC（声学回声消除）

## 0. 背景

回声问题的两个现场：一是**电话网络**——2/4 线转换的混合线圈（hybrid）阻抗失配让远端声音泄漏回发送方向，形成线路回声，长距离电路的时延让它变成对方听得见的"自己回声"；二是**免提与会议终端**——扬声器播放的声音被同一房间的麦克风重新拾取，"扬声器 -> 房间 -> 麦克风"的声学回灌随着免提通话和视频会议普及成为日常问题。

前序方案是**回声抑制器**（echo suppressor）：检测到远端单讲时直接衰减/断开返回通道。它是开关系列处理，代价是半双工感——抢话（double-talk）时近端语音被切、自然对话的打断与重叠全被破坏，这也是"抑制"（suppress）与"消除"（cancellation）的分界。

转折是**自适应滤波回声消除**：用自适应 FIR（LMS 一类算法， Widrow & Hoff 1960 奠基）在线估计回声路径，从麦克风信号里减去回声估计，近端语音不再需要被开关。工程落地沿三条线推进：电话网络的数字回声消除器（ITU-T G.165，后由 G.168 迭代）→ 声学回声消除（免提电话与会议室，需面对房间混响与非线性的声学路径）→ 实时通信软件栈（SpeexDSP、WebRTC AEC/AEC3 等把 AEC 变成通用前端正件）。近年两个方向：全频带实时化（WebRTC AEC3 以鲁棒性优先）与神经 AEC（用网络处理非线性残余，或与传统 AEC/beamforming 联合）。

## 1. 身份

`AEC`（Acoustic Echo Cancellation，声学回声消除）是实时通话、会议设备和语音 Agent 前端里的回声抑制模块：用**播放参考信号**估计“扬声器 -> 房间 -> 麦克风”的声学回声路径，再从麦克风信号里抵消这部分回灌声音。

最小链路：

```text
far-end / TTS playback reference
  + near-end microphone signal
  -> AEC
  -> echo-reduced microphone signal
```

边界：AEC 不是普通降噪，也不是 [[方向/AI语音/知识/基础概念/Beamforming（波束形成）|beamforming]]。AEC 处理的是**已知播放参考**回灌到麦克风的问题；降噪处理未知噪声；beamforming 利用阵列空间差异增强目标方向。

## 2. 为什么重要

- **全双工刚需**：Agent 一边说话一边听用户时，TTS 外放会被麦克风收回；没有 AEC，ASR / VAD 可能把模型自己的声音当成用户输入。
- **通话体验底线**：远端用户听到自己声音回传，会形成回声、双声或啸叫感。
- **前端顺序关键**：有播放参考时，通常先做 AEC，再做 VAD、DOA、beamforming、NS / post-filter；否则后续模块会在“回声污染”上估计错误。
- **不是大模型能兜底的问题**：回声路径、延迟、设备路由和声学反馈是物理链路问题，后端 LLM 很难可靠修正。

## 3. 基本原理

麦克风信号可粗略写成：

$$
y(t)=s(t)+h(t)*x(t)+n(t)
$$

其中 $s(t)$ 是近端用户语音，$x(t)$ 是播放参考，$h(t)$ 是扬声器到麦克风的声学回声路径，$n(t)$ 是噪声。AEC 估计 $\hat{h}(t)$，构造回声估计 $\hat{e}(t)=\hat{h}(t)*x(t)$，再输出：

$$
\hat{s}(t)=y(t)-\hat{e}(t)
$$

实际系统通常还要处理非线性失真、双讲（double-talk）、时钟漂移、设备延迟变化、残余回声抑制和舒适噪声。

## 4. 关键失败模式

- **参考信号不准**：拿不到真实播放参考，或参考与扬声器实际输出不同步 / 被系统混音改写。
- **延迟漂移**：播放参考与麦克风回灌之间的延迟变化，导致自适应滤波器跟不上。
- **双讲场景**：用户和扬声器同时发声，AEC 不能把近端用户语音误当回声消掉。
- **非线性回声**：扬声器削波、AGC、动态压缩和设备外壳振动会让线性回声模型失配。
- **残余回声**：主回声被抵消后仍有尾音，通常还要 residual echo suppressor / neural post-filter。

## 5. 评估口径

- **ERLE（Echo Return Loss Enhancement）**：AEC 前后回声能量抑制量，常用 dB 表示。
- **近端语音保真**：双讲时不能明显挖空用户声音，需看语音失真、ASR WER/CER 和主观听感。
- **残余回声**：听感上是否仍有远端/TTS 声音、双声或尾音。
- **实时性**：AEC 本身延迟、算法帧长、CPU/DSP 占用，以及和 VAD / barge-in 的联动延迟。

## 6. 工程位置

```text
playback reference + microphone signal
  -> AEC
  -> VAD / barge-in
  -> DOA / beamforming（多麦时）
  -> noise suppression / neural post-filter
  -> ASR / audio LLM
```

语音 Agent 里，AEC 和 barge-in 要一起设计：AEC 负责去掉“模型自听”，VAD / interruption detector 决定用户是否真的在打断；两者混在一起会导致误打断或漏打断。

## 7. 关键来源

- [WebRTC Audio Processing Module](https://webrtc.googlesource.com/src/+/refs/heads/main/modules/audio_processing/g3doc/audio_processing_module.md)
  - 内容定位：WebRTC APM 中 AEC、noise suppression、AGC 等实时通信音频处理模块入口。
  - 用途：确认 AEC 在实时通信音频前端的位置。
  - 发表日期：文档页无明确发表日期
  - 核验日期：2026-08-25
- [Speex manual - Acoustic Echo Cancellation](https://www.speex.org/docs/manual/speex-manual/node7.html)
  - 内容定位：SpeexDSP AEC API 与播放参考信号、麦克风输入、输出信号的基本处理关系。
  - 用途：建立 AEC 的最小工程抽象。
  - 发表日期：文档页无明确发表日期
  - 核验日期：2026-08-25

## 8. 相关对象

- [[方向/AI语音/知识/基础概念/Audio Leakage（漏音）]]：AEC 处理的是扬声器到麦克风的声学泄漏。
- [[方向/AI语音/知识/基础概念/Full-Duplex（全双工）]]：全双工语音 Agent 中 AEC 是硬前提。
- [[方向/AI语音/知识/基础概念/VAD（Voice Activity Detection）]]：AEC 后的语音活动判断更可靠。
- [[方向/AI语音/知识/基础概念/Beamforming（波束形成）]]：多麦系统中常与 AEC、DOA、post-filter 联用。
- [[方向/AI语音/知识/基础概念/AGC（自动增益控制）]]：链路中放在 AEC 之后的闭环增益模块；过早开启会改变回声路径增益并引入非线性回声。
- [[方向/AI语音/知识/基础概念/Reverse TSE（反向目标说话人提取）]]：区分已知播放参考回声和未知泄漏声源。

## 9. 待验证

- 0. 背景的时间线（1920s 回声抑制器商用、Widrow & Hoff 1960 与 LMS 的关系、G.165 1993 / G.168 2002 版本年份）未逐条核一手文献，引用前需核对 ITU-T 建议书原文。
- 当前目标设备能否拿到真实播放参考信号，还是只能做 blind echo suppression。
- AEC 与 beamforming 的顺序：按设备形态选择 per-channel AEC、post-beamforming AEC，还是联合神经 AEC + beamforming。
- 语音 Agent 中 AEC、VAD、barge-in、ASR partial 的延迟预算和误触发率。

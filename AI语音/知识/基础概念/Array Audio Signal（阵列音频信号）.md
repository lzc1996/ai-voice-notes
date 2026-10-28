---
title: Array Audio Signal（阵列音频信号）
类型: 概念
发表时间:
时间依据: 阵列语音处理方案笔记；非单一发表物
相关任务:
  - 语音增强
相关主题:
  - 阵列信号
  - 音频大模型
相关评估:
  - "[[方向/AI语音/评估/CHiME（语音分离与识别挑战赛）]]"
  - "[[方向/AI语音/评估/NOTSOFAR-1（远场会议转写挑战）]]"
aliases:
  - 阵列音频信号（Array Audio Signal）
  - Array Audio Signal
  - 阵列音频信号
  - array audio signal
tags:
  - 类型/对象
  - 方向/AI语音
  - 任务/语音增强
  - 主题/阵列信号
  - 主题/音频大模型
---

# Array Audio Signal（阵列音频信号）

## 1. 身份

阵列音频信号是多个麦克风同步采到的多通道语音信号。它不仅有每一路的波形，还包含**空间信息**：不同麦克风之间的到达时间差、[[方向/AI语音/知识/基础概念/IPD（通道间相位差）|相位差]]、能量差和阵列几何关系。

最小形式：

```text
X(t) = [x1(t), x2(t), ..., xM(t)]
```

其中 `M` 是麦克风数量。阵列信号的价值不只是“多几个通道”，而是能利用空间差异把目标说话人、噪声、回声和混响分开。

## 2. 为什么先区分普通增强和阵列增强

调研阵列音频增强时，第一步应先把它和普通单通道增强分开；否则很容易把“降噪模型效果好”误判成“阵列前端问题已解决”。

| 维度 | 普通音频 / 单通道语音增强 | 阵列音频增强 | 来源 |
|---|---|---|---|
| 输入假设 | 通常是一条 noisy waveform / STFT，目标是 `noisy -> clean` | 多个同步麦克风通道，目标是同时利用时间差、相位差、能量差和阵列几何 | [ESPnet-SE](https://arxiv.org/abs/2011.03706)、[Advances in Microphone Array Processing and Multichannel Speech Enhancement](https://arxiv.org/abs/2502.09037) |
| 主要信息 | 语音内容、频谱、噪声和混响尾部 | 额外包含 DOA、TDOA、[[方向/AI语音/知识/基础概念/IPD（通道间相位差）]]、[[方向/AI语音/知识/基础概念/ILD（双耳声级差）]]、transfer function 等空间线索 | [Microphone Array Signal Processing and Deep Learning for Speech Enhancement](https://arxiv.org/abs/2501.07215)、[Advances in Microphone Array Processing and Multichannel Speech Enhancement](https://arxiv.org/abs/2502.09037) |
| 主要算法 | denoising、dereverberation、source separation、deep filtering、生成式修复 | AEC、[[方向/AI语音/知识/基础概念/Beamforming（波束形成）]]、WPE、mask-based / neural beamformer、多通道神经增强 | [ESPnet-SE](https://arxiv.org/abs/2011.03706)、[ESPnet-SE++](https://arxiv.org/abs/2207.09514)、[Joint Neural AEC and Beamforming](https://arxiv.org/abs/2111.04904) |
| 工程风险 | 过降噪、音乐噪声、语音失真、生成式幻觉 | 通道不同步、阵列几何错误、麦克风坏道、回声路径变化、移动声源 | [Advances in Microphone Array Processing and Multichannel Speech Enhancement](https://arxiv.org/abs/2502.09037)、[CHiME-7 DASR Task](https://www.chimechallenge.org/challenges/chime7/task1/index) |
| 大模型位置 | 可直接接增强后音频做 ASR / QA / 质量评价 | 更适合吃阵列前端输出的 enhanced stream 和 metadata，不适合直接替代阵列物理前端 | [When Large Language Models Meet Speech](https://aclanthology.org/2025.findings-acl.1041/)、[Qwen3-Omni README](https://github.com/QwenLM/Qwen3-Omni)、[Directional-SpeechLLaMA](https://www.isca-archive.org/interspeech_2025/xie25_interspeech.html) |

## 3. 两类方案

### 3.1. 方案 A：传统阵列前端 + 语音增强

适合实时通话、会议转写、语音 Agent 前端。

```text
多通道麦克风
  -> 同步 / 增益 / 通道健康检查
  -> AEC（有播放参考时）
  -> VAD / [[方向/AI语音/知识/基础概念/DOA（到达方向）|DOA]] / 声源活动估计
  -> [[方向/AI语音/知识/基础概念/Beamforming（波束形成）|beamforming]]（Delay-and-Sum / [[方向/AI语音/知识/基础概念/MVDR（最小方差无失真响应）|MVDR]] / GSC）
  -> WPE 去混响 / neural denoise / deep filtering
  -> 单通道 enhanced speech
  -> ASR / LLM / 录音归档
```

优点：低延迟、可解释、可控、内容保真更强。  
代价：需要知道阵列几何、同步质量和声学链路；强非稳态噪声、多说话人重叠和强混响下仍可能失效。

### 3.2. 方案 B：阵列前端 + 音频大模型

适合需要理解、转写、问答、会议纪要、语音 Agent 的系统。

```text
多通道麦克风
  -> 阵列前端先压成 clean mono / target stream
  -> 附带 metadata：VAD、[[方向/AI语音/知识/基础概念/DOA（到达方向）|DOA]]、speaker turn、SNR、confidence
  -> ASR / audio LLM / multimodal LLM
  -> 文本理解、摘要、决策、对话
```

关键判断：**音频大模型通常不应该直接替代阵列前端**。多数音频大模型默认吃 mono / stereo 或已经规整过的音频；阵列信号里的同步、相位、[[方向/AI语音/知识/基础概念/DOA（到达方向）|DOA]]、回声路径、麦克风坏道这些问题，仍更适合由 DSP / array SE 前端先处理。

## 4. 调研结论（2026-08）

当前阵列音频增强可以分成三层：

1. **信号层**：解决同步、回声、方向、空间滤波、去混响、降噪。
2. **增强层**：输出 clean mono / target stream，服务人听和机器听。
3. **大模型层**：做 ASR、摘要、问答、会议理解、质量解释和交互决策。

结论：**产品方案优先走“阵列语音增强前端 + 音频大模型后端”，不要把 raw multichannel 直接丢给音频大模型。**

| 维度 | 语音增强方案 | 音频大模型方案 |
|---|---|---|
| 输入 | 原始多通道阵列音频、播放参考、阵列几何 | 通常是增强后的 mono / stereo，或少数研究型多通道编码 |
| 目标 | 保真地分离目标声、降噪、去混响、控回声 | 理解内容、转写、摘要、问答、质量解释 |
| 强项 | 相位/时延/[[方向/AI语音/知识/基础概念/DOA（到达方向）]]/AEC/[[方向/AI语音/知识/基础概念/Beamforming（波束形成）]] 等物理问题 | 语义推理、跨模态理解、自然语言输出 |
| 主要风险 | 配置复杂、需要硬件标定、强重叠下失效 | 幻觉、通道/空间信息训练不足、延迟和成本高 |
| 推荐位置 | 前端，越靠近采集越好 | 后端，吃增强结果和 metadata |

### 4.1. 语音增强方案主线

多通道 SE 的成熟路线是把阵列信号先变成可控的 enhanced stream，再交给 ASR / LLM。公开工具和论文也沿这个方向：ESPnet-SE 明确支持 single-channel / multi-channel 输入，覆盖 dereverberation、denoising、source separation，并强调和 ASR 集成；ESPnet-SE++ 进一步把 SE 前端接到 ASR、speech translation、spoken language understanding 等后端任务，尤其指出多通道场景下前后端集成有价值。

### 4.2. 学界方案脉络

下面两张表按“一条调研信息 -> 对应来源”组织；来源优先取论文、官方挑战页和厂商文档。

多通道 SE / 阵列 SE 具体方案如何引入阵列信息，见 [[方向/AI语音/知识/调研与地图/Array Speech Enhancement Frontier（阵列语音增强前沿调研）#1.3. 多通道方案如何引入阵列信息|多通道方案如何引入阵列信息]]。

| 方向 | 调研信息 | 来源 |
|---|---|---|
| 阵列处理综述 | 2025 年综述把麦克风阵列处理、多通道语音增强、商业化应用和 all-neural beamformer 作为同一条技术演进线讨论 | [Advances in Microphone Array Processing and Multichannel Speech Enhancement](https://arxiv.org/abs/2502.09037) |
| 传统 + 深度学习混合 | 学界把 model-based、pure data-driven、hybrid approaches 分开比较，hybrid 的动机是结合模型驱动信号处理和深度学习的优点 | [Microphone Array Signal Processing and Deep Learning for Speech Enhancement](https://arxiv.org/abs/2501.07215) |
| 工具链 | ESPnet-SE 支持 single-channel / multi-channel 数据，覆盖 dereverberation、denoising、source separation，并面向 ASR 集成设计 | [ESPnet-SE](https://arxiv.org/abs/2011.03706) |
| 前后端集成 | ESPnet-SE++ 设计了可把 SE front-end 接到 ASR、speech translation、SLU 的接口，并报告 multi-channel 场景下前后端集成特别有价值 | [ESPnet-SE++](https://arxiv.org/abs/2207.09514) |
| 真实远场识别 benchmark | [[方向/AI语音/评估/CHiME（语音分离与识别挑战赛）]] 系列：主线是 noisy / distant ASR 与 diarization；其中 [[方向/AI语音/评估/NOTSOFAR-1（远场会议转写挑战）]] 可用来观察已知几何阵列前端对会议转写的下游收益，但不是阵列增强榜 | [CHiME-3 Overview](https://www.chimechallenge.org/challenges/chime3/overview.html)、[CHiME-6 Overview](https://chimechallenge.github.io/chime6/overview.html)、[CHiME-7 DASR Task](https://www.chimechallenge.org/challenges/chime7/task1/index)、[CHiME-8 NOTSOFAR](https://www.chimechallenge.org/challenges/chime8/task2/index) |
| 研究型音频大模型 | Directional-SpeechLLaMA 使用 smart glasses 麦克风阵列、[[方向/AI语音/知识/基础概念/Beamforming（波束形成）]] 和 speech LLM 做 target-direction ASR / source localization，说明 raw multichannel + LLM 仍处研究探索 | [Directional-SpeechLLaMA](https://www.isca-archive.org/interspeech_2025/xie25_interspeech.html) |

工程推荐：

```text
raw multichannel
  -> channel QA / sync / gain
  -> AEC（如果有播放参考）
  -> VAD / [[方向/AI语音/知识/基础概念/DOA（到达方向）|DOA]] / speaker activity
  -> [[方向/AI语音/知识/基础概念/Beamforming（波束形成）|beamforming]] / WPE / neural SE
  -> enhanced mono + metadata
  -> ASR / audio LLM / meeting agent
```

适用边界：

- 实时：优先 AEC + [[方向/AI语音/知识/基础概念/MVDR（最小方差无失真响应）|MVDR]] / GSC / Delay-and-Sum + 轻量 neural post-filter。
- 会议转写：优先多通道增强 + diarization + ASR，再把文本和时间戳交给 LLM。
- 多人重叠：优先 SS / TSE / directional ASR，而不是指望大模型从混音里猜。
- 离线修复：可以叠加多通道神经增强、生成式修复和人工复核，但必须保留原始多通道。

### 4.3. 音频大模型方案主线

音频大模型更适合做后端。Qwen3-Omni 这类 omni-modal model 已支持 audio/video/text 输入和实时语音响应；2025 年语音 + LLM 综述把主流集成方式分成 text-based、latent-representation-based、audio-token-based 三类；但这些路线主要解决“把音频接入 LLM 的语义空间”，不是替代阵列前端的相位、回声和空间滤波。

### 4.4. 工业界方案脉络

| 厂商 / 产品线 | 调研信息 | 来源 |
|---|---|---|
| WebRTC APM | WebRTC Audio Processing Module 把 AEC、noise suppression、AGC 作为 VoIP calling 所需音频处理模块 | [WebRTC APM](https://webrtc.googlesource.com/src/+/refs/heads/main/modules/audio_processing/g3doc/audio_processing_module.md) |
| XMOS VocalFusion | XVF3800 面向 Teams / Zoom 认证会议设备，提供 AEC、noise suppression、adaptive multiple beamformers；XVF3620 进一步把 AI denoising、AEC、two-mic beamforming、AGC 放进 on-chip pipeline | [XMOS XVF3800](https://www.xmos.com/xvf3800/)、[XMOS XVF3620 launch](https://www.xmos.com/xmos-launches-ai-voice-processing-in-new-vocalfusion-xvf3620-voice-processor) |
| Shure IntelliMix | IntelliMix Room 提供 automatic mixing、matrix mixer、AEC、noise reduction、AGC、AI denoiser 等会议室 DSP；P300 提供 8 路麦克风处理、AEC、noise reduction、AGC、automatic mixing 和 matrix mixing | [Shure IntelliMix Room User Guide](https://www.shure.com/en-US/docs/guide/IntelliMixRoom)、[Shure P300](https://www.shure.com/en-US/products/mixers/p300?variant=P300-IMX) |
| NVIDIA Maxine AFX | NVIDIA Audio Effects SDK 提供实时 AEC、denoise、dereverb、speaker focus、studio voice 等音频效果，定位 broadcast / collaboration / content creation，不是阵列物理前端替代 | [NVIDIA Audio Effects SDK](https://docs.nvidia.com/maxine/afx/latest/index.html) |
| Google Meet | Google Meet 的 noise cancellation 可在 device / cloud 间切换以优化性能；Google Workspace blog 也说明 Meet 使用 backend processing 和 cloud denoiser 提升会议音质 | [Google Meet Help](https://support.google.com/meet/answer/9919960)、[Google Workspace Blog](https://blog.google/products-and-platforms/products/workspace/adaptive-audio-google-meet/) |
| Amazon Echo / Alexa | Amazon 曾开放 Echo 的 7-mic far-field microphone array 和 voice processing 技术，包含 wake word recognition、beamforming、noise reduction、echo cancellation | [Amazon Press Center](https://press.aboutamazon.com/2017/4/amazon-makes-the-high-performance-7-mic-voice-processing-technology-from-amazon-echo-available-to-third-party-device-makers) |
| Microsoft Teams Rooms | Teams Intelligent Speakers 关注会议室内说话人识别和 live transcription 的身份归属；它属于增强后端应用层，不替代前端 AEC/beamforming | [Microsoft Teams Intelligent Speakers](https://support.microsoft.com/en-us/teams/calls-devices/use-microsoft-teams-intelligent-speakers-to-identify-in-room-participants-in-a-meeting-transcription)、[Teams meeting devices](https://learn.microsoft.com/en-us/microsoftteams/hybrid-meetings-device-select) |
| Apple Voice Isolation | Apple 的 Voice Isolation / Automatic Mic Mode 用于通话时阻断环境噪声或自动选择合适麦克风模式，是端侧普通音频增强能力，不等同于开放的阵列处理方案 | [Apple Support - Mic modes](https://support.apple.com/en-us/101993) |

可用形态：

- **ASR / speech translation 后端**：吃增强后的单通道语音，输出文字和语义结果。
- **质量评估后端**：audio LLM 可做自然语言质量解释、MOS / A/B 判断辅助。
- **空间音频研究路线**：Directional-SpeechLLaMA 这类工作开始探索多通道 / smart glasses 阵列输入，用 [[方向/AI语音/知识/基础概念/Beamforming（波束形成）|beamforming]] 前端和方向提示做 target-direction ASR，但仍是研究路线，不是通用阵列增强替代品。

## 5. 方案建议

短期工程落地：

```text
阵列麦克风
  -> WebRTC/自研 AEC + [[方向/AI语音/知识/基础概念/Beamforming（波束形成）|beamforming]] + neural denoise
  -> ASR
  -> LLM 摘要/问答/Agent 决策
```

中期增强：

```text
阵列麦克风
  -> 多通道神经增强 / TSE / diarization
  -> enhanced stream + speaker turn + [[方向/AI语音/知识/基础概念/DOA（到达方向）|DOA]] + confidence
  -> audio/text LLM
```

研究探索：

```text
阵列麦克风
  -> 多方向 [[方向/AI语音/知识/基础概念/Beamforming（波束形成）|beamformed streams]]
  -> audio encoder + adapter
  -> speech LLM 做 directional ASR / source localization
```

判断标准：如果目标是**听得清、低延迟、可验证**，阵列 SE 是主方案；如果目标是**理解、总结、交互、解释质量**，音频大模型是后端方案；如果目标是“raw multichannel 直接进大模型”，目前应作为研究题，不作为主工程路径。

## 6. 推荐分工

| 场景 | 推荐方案 | 原因 |
|---|---|---|
| 实时通话 / 语音 Agent | AEC + [[方向/AI语音/知识/基础概念/Beamforming（波束形成）]] + 轻量 SE，再接 ASR/LLM | 延迟和回声控制优先，大模型不能兜住物理链路问题 |
| 会议转写 | 阵列增强 + diarization / ASR，再交给 LLM 摘要 | 阵列负责“听清楚”，大模型负责“理解和组织” |
| 多人重叠说话 | [[方向/AI语音/知识/基础概念/Beamforming（波束形成）]] / SS / TSE，再接大模型 | 先拆声源，避免大模型把多人内容混在一起 |
| 离线高质量修复 | 多通道神经增强 + 生成式修复 | 可牺牲延迟换质量，但仍要防内容幻觉 |
| 设备评测 / 数据采集 | 保留原始多通道 + 增强后单通道 | 原始阵列用于回放、诊断和算法复现 |

## 7. 常见特征

- **TDOA / ITD**：到达时间差，支撑声源定位和 [[方向/AI语音/知识/基础概念/Beamforming（波束形成）|波束形成]]。
- **[[方向/AI语音/知识/基础概念/IPD（通道间相位差）|IPD]]**：通道间相位差，频域多通道模型常用。
- **[[方向/AI语音/知识/基础概念/ILD（双耳声级差）|ILD]]**：通道间能量差，近场或遮挡场景有用。
- **[[方向/AI语音/知识/基础概念/DOA（到达方向）|DOA]]**：声源方向估计，可作为 [[方向/AI语音/知识/基础概念/Beamforming（波束形成）|beamforming]] 或 TSE 条件。
- **RIR / transfer function**：房间和阵列共同决定的传播响应，可用 [[方向/AI语音/知识/基础概念/TSP（Time-Stretched Pulse）|TSP]] / [[方向/AI语音/知识/基础概念/ESS（Exponential Sine Sweep）|ESS]] 测量。

## 8. 不要直接丢给大模型的原因

- **相位和同步很脆弱**：阵列优势来自微秒级时间差；重采样、漂移、通道错位会直接毁掉空间信息。
- **训练分布不匹配**：很多音频大模型不是按原始多通道阵列输入训练的。
- **物理问题要物理处理**：AEC、麦克风坏道、声卡 loopback、阵列几何错误，大模型很难可靠修。
- **幻觉风险**：强噪声和多人重叠下，大模型可能“听懂”错内容；阵列前端的目标是先把信号保真地变清楚。

## 9. 工程检查表

- 采样率和通道数是否固定。
- 各通道是否同步，有无 drift / drop / swapped channel。
- 麦克风几何、间距、朝向是否记录。
- 是否有播放参考信号；有则 AEC 应放在前面。
- 近场/远场、单说话人/多人、静态/移动声源是否分开评测。
- 输出是否同时保存原始多通道和增强后单通道，方便回归测试。

## 10. 关键资源

- [Advances in Microphone Array Processing and Multichannel Speech Enhancement](https://arxiv.org/abs/2502.09037)
  - 内容定位：2025 年麦克风阵列处理与多通道语音增强综述，覆盖传统阵列、深度学习和 all-neural beamformer 趋势。
  - 用途：建立阵列增强方案的技术地图。
  - 核验日期：2026-08-04
- [ESPnet-SE](https://arxiv.org/abs/2011.03706)
  - 内容定位：端到端 speech enhancement / separation 工具，支持 single-channel / multi-channel、dereverberation、denoising、source separation，并和 ASR 集成。
  - 用途：确认“SE 前端 + ASR 后端”的工程主线。
  - 核验日期：2026-08-04
- [ESPnet-SE++](https://arxiv.org/abs/2207.09514)
  - 内容定位：把 SE 前端扩展到 robust ASR、speech translation、spoken language understanding 等后端任务。
  - 用途：确认多通道 SE 与下游语音理解任务集成的价值。
  - 核验日期：2026-08-04
- [When Large Language Models Meet Speech](https://aclanthology.org/2025.findings-acl.1041/)
  - 内容定位：2025 年 speech + LLM 集成综述，三类路线是 text-based、latent-representation-based、audio-token-based。
  - 用途：定位音频大模型方案属于“语义后端 / 表示接入”，不是阵列前端替代。
  - 核验日期：2026-08-04
- [Qwen3-Omni README](https://github.com/QwenLM/Qwen3-Omni)
  - 内容定位：Qwen3-Omni 官方说明，支持 text/image/audio/video 输入和实时 text/speech 输出。
  - 用途：定位当前 omni-modal 音频大模型能力边界。
  - 核验日期：2026-08-04
- [Thinking in Directivity: Speech Large Language Model for Multi-Talker Directional Speech Recognition](https://www.isca-archive.org/interspeech_2025/xie25_interspeech.html)
  - 内容定位：用 smart glasses 麦克风阵列、beamforming 和 speech LLM 做 directional ASR / source localization。
  - 用途：记录“多通道音频大模型”仍处研究探索阶段。
  - 核验日期：2026-08-04
- [Audio Large Language Models Can Be Descriptive Speech Quality Evaluators](https://mlanthology.org/iclr/2025/chen2025iclr-audio/)
  - 内容定位：用 audio LLM 做自然语言式语音质量评价。
  - 用途：说明大模型在阵列增强链路里可作为质量解释/裁判，而非只做增强器。
  - 核验日期：2026-08-04

## 11. 相关对象

- [[方向/AI语音/知识/基础概念/SE（语音增强）导论]]：阵列增强属于多通道 SE 路线。
- [[方向/AI语音/知识/技术路线/LLM 与 Agent 对语音增强的影响]]：音频大模型适合理解/裁判/语义层，不应直接替代保真前端。
- [[方向/AI语音/知识/基础概念/Audio Leakage（漏音）]]：外放回收、mic bleed 和 AEC 是阵列前端必须先处理的问题。
- [[方向/AI语音/知识/基础概念/AEC（声学回声消除）]]：有播放参考时，先处理扬声器到麦克风的回声泄漏。
- [[方向/AI语音/知识/基础概念/Reverberation Modeling（混响建模）]]：阵列信号中的空间信息和 RIR/DRR/T60 直接相关。
- [[方向/AI语音/知识/基础概念/Array Aperture（阵列孔径）]]：阵列几何尺度，影响低频指向性与空间分辨率。
- [[方向/AI语音/知识/基础概念/DOA（到达方向）|DOA]]：阵列前端估计声源方向并输出空间 metadata。
- [[方向/AI语音/知识/基础概念/IPD（通道间相位差）|IPD]]：阵列信号中最常用的通道间相位线索。
- [[方向/AI语音/知识/基础概念/Beamforming（波束形成）|Beamforming]]：阵列前端把多通道压成目标方向 enhanced stream。
- [[方向/AI语音/知识/基础概念/MVDR（最小方差无失真响应）|MVDR]]：会议和远场 ASR 中常见的阵列 beamforming 算法。
- [[方向/AI语音/评估/CHiME（语音分离与识别挑战赛）|CHiME]]：经典多通道 noisy / distant ASR benchmark 系列；阵列增强多作为识别前端。
- [[方向/AI语音/知识/基础概念/SS（语音分离）]]、[[方向/AI语音/知识/基础概念/TSE（目标说话人提取）]]：多人阵列场景常和分离/提取联用。
- [[方向/AI语音/知识/基础概念/音频数据预处理]]：多通道保留、通道检查和训练样本构造入口。

## 12. 待验证

- 当前目标硬件的麦克风数量、阵列几何和是否有播放参考信号。
- 是否需要继续拆 DAS、GSC、AEC + beamforming 联合前端等子页。
- 音频大模型输入前，保留哪些 metadata（DOA、SNR、speaker turn、confidence）最有用。

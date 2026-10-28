---
title: CHiME（语音分离与识别挑战赛）
类型: 评测基准
发表时间:
时间依据: CHiME 是系列挑战赛；单届发布时间见各届小节
aliases:
  - CHiME
  - CHiME Challenge
  - CHiME Challenges
  - CHiME Speech Separation and Recognition Challenge
  - CHiME 语音挑战赛
  - CHiME 语音分离与识别挑战赛
  - CHiME-8
  - CHiME8
  - CHiME-3
  - CHiME3
  - The 3rd CHiME Challenge
  - 第三届 CHiME 挑战赛
  - 第三届 CHiME 语音分离与识别挑战赛
tags:
  - 类型/对象
  - 方向/AI语音
  - 任务/ASR
  - 任务/语音增强
  - 主题/阵列信号
  - 主题/远场语音
---

# CHiME（语音分离与识别挑战赛）

## 0. 背景

**问题现场**：远场/嘈杂/多通道条件下的语音识别与说话人日志需要公开可比的基准，而真实环境数据采集与标注成本高。

**切入点**：系列挑战赛逐届演化数据与任务设置（多通道 tablet、日常家庭、多设备任意阵列、多模态），主线始终是 far-field ASR 与 diarization 而非语音增强本身。

## 1. 身份

Computational Hearing in Multisource Environments
`CHiME` 是一组围绕 noisy / distant / multi-channel speech 的语音分离与识别挑战赛。主线是**远场 / 嘈杂 / 多通道 ASR 与 diarization**，不是 [[方向/AI语音/评估/DNS Challenge（深度噪声抑制挑战）|DNS Challenge]] 或 [[方向/AI语音/评估/URGENT（通用语音增强挑战）|URGENT]] 那种语音增强评测。不同数字后缀（如 `CHiME-3`、`CHiME-7`、`CHiME-9`）表示不同届次 / 任务设置，而不是完全独立的概念。

当前 vault 约定：默认只落一个 CHiME 总页；具体届次先放在本页小节里。只有某一届需要大量数据拆分、leaderboard、复现实验或脚本时，再单独拆子页。

## 2. 届次速览

| 届次 | 主任务 | 和阵列增强的关系 |
|---|---|---|
| CHiME-3 | 6 通道 tablet noisy WSJ ASR | 有多通道前端和 [[方向/AI语音/知识/基础概念/Beamforming（波束形成）]]，但核心指标是 ASR WER |
| CHiME-6 | 日常家庭环境 distant multi-microphone conversational speech diarization and recognition | 主要是远场会话识别 / diarization；增强是前处理手段 |
| CHiME-7 / CHiME-8 DASR | 多设备、任意阵列、diarization + ASR | 识别与日志主线；[[方向/AI语音/知识/基础概念/GSS（引导源分离）]] / beamforming 常作系统前端 |
| [[方向/AI语音/评估/NOTSOFAR-1（远场会议转写挑战）]] | 已知几何会议室、真实会议 + 仿真数据 | 远场会议转写 benchmark；可间接检验阵列前端是否降低 tcpWER，但不是阵列增强指标榜 |
| CHiME-9 | [[方向/AI语音/评估/MCoRec（多模态上下文识别）]] 与 [[方向/AI语音/评估/ECHI（助听对话增强）]]，偏多模态会话记录和助听增强 | MCoRec 偏转写；ECHI 是助听对话增强（20 ms 流式 + 主观听测定榜） |

## 3. 各届麦克风形态（"多通道"的具体意义）

CHiME 各届的"多通道"都是[[方向/AI语音/知识/基础概念/Array vs Multi-Channel（阵列与多通道）|阵列意义]]的拾音——空间分布的麦克风同步采样同一声场、利用通道间时延/相位/能量差——但阵列的组织方式逐届演化：

| 届次 | 麦克风形态 | 多通道意义的变化 |
|---|---|---|
| CHiME-1 / 2 | 双耳（binaural）2 通道录音（客厅环境） | 最早"多通道"= 双耳拾音，通道数最少 |
| CHiME-3 / 4 | 单个 tablet 6 麦阵列（2×3 排布）+ close-talk 参考麦 | 标准单阵列：几何已知、通道同步 |
| CHiME-5 / 6 | 晚宴场景 4× Kinect 型 4 麦阵列（房间内分布） | 多阵列：阵内同步、阵间仅粗同步 |
| CHiME-7 / 8 DASR | 多设备 ad-hoc：每设备自带 1 麦或小阵列，异步 | 分布式阵列：采样率偏移 / 时钟不同步，逼出 array-agnostic 前端 |
| CHiME-8 NOTSOFAR-1 | 已知几何会议室固定阵列 | 回到"已知几何"，便于检验阵列前端对下游转写的收益 |
| CHiME-9 MCoRec | 360° 音视频多通道拾音 | 多模态会话记录 |
| CHiME-9 [[方向/AI语音/评估/ECHI（助听对话增强）]] | 双耳助听器（binaural） | 助听协同，回到双耳形态，20 ms 流式 |

一句话：**2 通道双耳 → 单 6 麦阵列 → 多 4 麦阵列 → 分布式多设备 → 回到双耳助听**，多通道的组织形态一直在变，但"空间拾音、利用空间信息"这一阵列意义始终不变。

## 4. 和阵列音频增强的关系

CHiME 系列不应整体归类为“阵列音频增强 benchmark”。更准确的口径是：

- **识别主线**：CHiME-3、CHiME-6、CHiME-7/8 DASR 主要评测远场 / 嘈杂 / 多通道 ASR 或 diarization + ASR。
- **阵列增强作为手段**：[[方向/AI语音/知识/基础概念/MVDR（最小方差无失真响应）|MVDR]]、[[方向/AI语音/知识/基础概念/GSS（引导源分离）|GSS]]、mask-based beamforming、WPE 和 neural post-filter 常用来降低 WER，但不是最终评测对象。
- **最容易误归类的入口**：[[方向/AI语音/评估/NOTSOFAR-1（远场会议转写挑战）|CHiME-8 NOTSOFAR-1]] 有真实会议、已知几何和仿真数据，所以常被拿来验证阵列前端；但它的任务和排名仍是会议转写，不是纯 SE / MOS / 阵列增强口径。

## 5. CHiME-3：第三届挑战赛

`CHiME-3` 是第三届 CHiME Speech Separation and Recognition Challenge，也是 IEEE ASRU 2015 的官方挑战任务。它面向**日常噪声环境中的多麦克风 tablet ASR**：说话人朗读 WSJ 句子，声音由 tablet 上的 6 通道麦克风阵列采集，并包含真实录制和模拟混合两类 noisy speech。

边界：CHiME-3 不是通用 MOS / 听感增强 benchmark；它的核心是 noisy / distant / multi-channel ASR，重点看前端增强、[[方向/AI语音/知识/基础概念/Beamforming（波束形成）|beamforming]]、特征和识别后端是否能降低 WER。

### 5.1. 数据和任务口径

- **任务**：基于 WSJ0 5k vocabulary 的 noisy ASR，延续 CHiME-2 的 WSJ evaluation framework。
- **阵列**：tablet frame 上的 6-channel microphone array，同时有 close-talk channel 作为参考录音。
- **环境**：bus（BUS）、cafe（CAF）、pedestrian area（PED）、street junction（STR）；booth（BTH）用于构造模拟数据。
- **数据形态**：real noisy、simulated noisy、clean / original speech、background noise、baseline enhanced speech。
- **训练规模**：官方数据页给出 training set 为 `1600 real + 7138 simulated = 8738 noisy utterances`。
- **分发采样率**：官方数据页说明分发音频为 16 kHz；原始录制流程使用 24-bit / 48 kHz。

### 5.2. 为什么重要

- **真实录制更强**：相比早期只做人工混合的 noisy speech，CHiME-3 增加了真实环境里 live-recorded speech。
- **阵列前端基准**：能测试 channel selection、[[方向/AI语音/知识/基础概念/MVDR（最小方差无失真响应）|MVDR]]、mask-based beamforming、dereverberation 和 neural post-filter。
- **ASR 导向清晰**：很多增强算法在 CHiME-3 上不是只报 PESQ/STOI，而是直接看增强后 ASR WER。

### 5.3. 典型使用方式

```text
6-channel noisy speech
  -> channel selection / covariance estimation
  -> MVDR / GSC / neural beamformer
  -> enhanced speech or enhanced features
  -> ASR acoustic model + language model
  -> WER
```

适合用来比较：多通道语音增强前端是否提升 noisy ASR、DNN mask + beamformer 是否优于单通道增强、阵列算法在真实噪声和模拟噪声上的差距。

不适合直接代表：中文会议、多人自由对话、强重叠说话、现代 universal speech enhancement、端到端 speech LLM 输入质量。

## 6. 关键来源

- [CHiME-3 Overview](https://www.chimechallenge.org/challenges/chime3/overview.html)
  - 内容定位：官方概览，说明 CHiME-3 场景、6 通道阵列、真实声学混合和四类噪声环境。
  - 用途：建立 CHiME-3 的任务定义和场景边界。
  - 核验日期：2026-08-04
- [CHiME-3 Data](https://www.chimechallenge.org/challenges/chime3/data)
  - 内容定位：官方数据页，说明 16 kHz 分发数据、real / simulated / clean 数据结构和训练集规模。
  - 用途：确认数据拆分、通道编号和训练集规模。
  - 核验日期：2026-08-04
- [CHiME-3 Results](https://www.chimechallenge.org/challenges/chime3/results)
  - 内容定位：官方结果和参赛系统列表。
  - 用途：追踪多通道增强、mask、RNN / ASR 后端等系统路线。
  - 核验日期：2026-08-04
- [CHiME3 - Linguistic Data Consortium](https://catalog.ldc.upenn.edu/LDC2017S24)
  - 内容定位：LDC 语料库条目，说明 CHiME3 由 noisy English speech / transcripts 和 background audio 组成。
  - 用途：确认语料归档和长期引用入口。
  - 核验日期：2026-08-04
- [CHiME-6 Overview](https://chimechallenge.github.io/chime6/overview.html)
  - 内容定位：CHiME-6 distant multi-microphone conversational speech diarization and recognition。
  - 用途：记录 CHiME 系列从读句 noisy ASR 走向真实会话远场识别。
  - 核验日期：2026-08-04
- [CHiME-7 DASR Task](https://www.chimechallenge.org/challenges/chime7/task1/index)
  - 内容定位：CHiME-7 DASR 远场多设备、多阵列拓扑任务。
  - 用途：记录 CHiME 后续 array-agnostic / meeting ASR 方向。
  - 核验日期：2026-08-04
- [CHiME-8 Task 2 - NOTSOFAR](https://www.chimechallenge.org/challenges/chime8/task2/index)
  - 内容定位：CHiME-8 中的 NOTSOFAR-1 远场会议转写任务，含 SC / known-geometry MC 双 track。
  - 用途：记录 CHiME-8 中可用于观察阵列前端下游转写收益的子任务。
  - 核验日期：2026-08-05
- [CHiME-9 Challenge](https://www.chimechallenge.org/challenges/chime9/index)
  - 内容定位：CHiME-9 官方任务入口。
  - 用途：跟踪 [[方向/AI语音/评估/MCoRec（多模态上下文识别）|MCoRec]]、[[方向/AI语音/评估/ECHI（助听对话增强）|ECHI]] 等多模态会话记录和助听增强方向。
  - 核验日期：2026-08-04

## 7. 相关对象

- [[方向/AI语音/知识/基础概念/Array Audio Signal（阵列音频信号）|Array Audio Signal]]：CHiME 是多通道 noisy / distant ASR benchmark 系列，不是纯阵列增强 benchmark。
- [[方向/AI语音/评估/NOTSOFAR-1（远场会议转写挑战）|NOTSOFAR-1]]：CHiME-8 Task 2，已知几何会议室远场转写 benchmark。
- [[方向/AI语音/知识/基础概念/Beamforming（波束形成）|Beamforming]]、[[方向/AI语音/知识/基础概念/MVDR（最小方差无失真响应）|MVDR]]：常见 CHiME 识别系统前端路线。
- [[方向/AI语音/知识/基础概念/GSS（引导源分离）|GSS]]：CHiME-5 之后常见的 diarization-guided multi-channel separation 前端。
- [[方向/AI语音/知识/基础概念/IPD（通道间相位差）|IPD]]：多通道神经前端可利用的空间特征。
- [[方向/AI语音/知识/基础概念/SE（语音增强）导论|SE（语音增强）导论]]：CHiME 适合回答“增强前端是否帮助 ASR”，不适合直接代表主观音质增强。
- [[方向/AI语音/评估/DNS Challenge（深度噪声抑制挑战）|DNS Challenge]]、[[方向/AI语音/评估/URGENT（通用语音增强挑战）|URGENT]]：更偏通信降噪 / universal SE 的评估口径。
- [[方向/AI语音/评估/CHiME and URGENT Chinese Industry Labs（国内工业界参赛记录）|国内工业界 CHiME / URGENT 参赛记录]]：阿里、腾讯、字节、华为 2012 的公开参赛证据梳理。
- [[方向/AI语音/评估/CER（Character Error Rate）|CER]]、[[方向/AI语音/评估/WER（词错误率）|WER]]：识别评估指标入口；CHiME-3 主要是英文 WER 口径。

## 8. 待验证

- 补齐 CHiME-1/2/4/5 的任务差异与数据细节（麦克风形态已补，见「各届麦克风形态」）。
- CHiME-1/2 双耳 2 通道口径、CHiME-9 MCoRec 具体通道数待对照官方页核验。
- 补齐 [[方向/AI语音/评估/NOTSOFAR-1（远场会议转写挑战）|NOTSOFAR-1]] 官方 top systems 的具体链路和 tcpWER。
- 是否需要单独核验 CHiME-9 ECHI 是否应归入助听增强评测。
- WER 独立笔记已建（[[方向/AI语音/评估/WER（词错误率）|WER]]），与 CER 并列。

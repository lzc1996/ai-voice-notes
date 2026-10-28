---
title: NOTSOFAR-1（远场会议转写挑战）
类型: 评测基准
发表时间: 2024-01-16
时间依据: arXiv 首次提交日
aliases:
  - NOTSOFAR-1
  - NOTSOFAR1
  - CHiME-8 NOTSOFAR-1
  - CHiME8 NOTSOFAR1
  - Natural Office Talkers in Settings Of Far-field Audio Recordings
  - NOTSOFAR-1 Challenge
  - 远场会议转写挑战
tags:
  - 类型/对象
  - 方向/AI语音
  - 任务/ASR
  - 任务/说话人日志
  - 主题/远场语音
  - 主题/阵列信号
---

# NOTSOFAR-1（远场会议转写挑战）

## 0. 背景

- 它把会议转写评估从“任意多设备泛化”拉回到更常见的会议室单设备部署：单个摄像头/会议设备 + 已知阵列几何。
- 它给多通道神经前端提供了更匹配的监督数据：真实会议 close-talk 标注 + 仿真 separated components。
- 对阵列前端工程有间接价值：最终指标仍是 WER/tcpWER，只能检验 [[方向/AI语音/知识/基础概念/Beamforming（波束形成）|beamforming]]、CSS、mask estimation、dereverberation 等前端是否降低会议转写错误，而不是直接评价增强音质。

## 1. 身份

`NOTSOFAR-1` 是 CHiME-8 Task 2，全名是 *Natural Office Talkers in Settings Of Far-field Audio Recordings*。它面向真实办公室会议的 distant speaker diarization + ASR，核心不是主观语音增强，而是**远场会议转写**。

边界：NOTSOFAR-1 不是阵列语音增强 benchmark；它的目标是远场会议转写。多通道 track 使用单个已知圆形阵列设备，因此可以**间接**评估“阵列前端是否降低 ASR / diarization 错误”，但不能直接代表 MOS、通信降噪质量或阵列增强本身。

## 2. 任务口径

- **SC track**：single-channel distant meeting transcription，来自不同商用单通道设备。
- **MC track**：known-geometry multi-channel distant meeting transcription，使用特定圆形阵列几何：中心麦 + 周围 6 个麦。
- **排序指标**：speaker-attributed `tcpWER`；补充看 speaker-agnostic `tcORC WER`。
- **和 CHiME-8 DASR 的关系**：CHiME-8 DASR 更强调 geometry-agnostic / 多设备泛化；NOTSOFAR-1 则固定单设备和已知几何，便于研究 geometry-specific 前端。
- **和 GSS 的关系**：CHiME-7 DASR 参赛者多依赖 [[方向/AI语音/知识/基础概念/GSS（引导源分离）|GSS]]；NOTSOFAR-1 通过匹配仿真训练集鼓励 data-driven separation / enhancement 前端替代或补充 GSS。

## 3. 数据口径

- **挑战赛口径**：官网说明最终约 280 场、每场 5–7 分钟会议；论文早期版本写过 315 场，官网注释说明后来为未来挑战预留部分会议。
- **当前开放数据口径**：官方 GitHub/Hugging Face 开放版本记录为 237 场会议，平均 6 分钟，30 个会议室，4–8 名参会者，35 名唯一说话人。
- **仿真训练集**：约 1000 小时，匹配多通道设备阵列几何；包含 15,000 个真实会议室 ATF，提供分离语音和噪声组件，可用于训练 CSS / beamforming / enhancement 前端，但最终仍按转写指标评价。
- **注意事项**：训练 / 开发集存在参与者重叠；open release 删除或限制了部分 dev/eval 子集，复现实验必须记录使用的 subset 名称。

## 4. 典型系统链路

```text
single device audio
  -> VAD / diarization / speaker counting
  -> CSS or beamforming / enhancement front-end
  -> ASR
  -> speaker-attributed transcript
  -> tcpWER / tcORC WER
```

## 5. 关键来源

- [CHiME-8 Task 2 - NOTSOFAR](https://www.chimechallenge.org/challenges/chime8/task2/index)
  - 内容定位：官方任务页，说明 SC / MC 双 track、约 280 场会议、约 1000 小时仿真训练集和 tcpWER 评估。
  - 用途：建立挑战赛任务定义和 CHiME-8 DASR 的关系。
  - 核验日期：2026-08-05
- [CHiME-8 Task 2 - NOTSOFAR Data](https://www.chimechallenge.org/challenges/chime8/task2/data)
  - 内容定位：官方数据页，说明单设备推理限制、设备类型、会议室元数据、ATF 和 overlap 统计。
  - 用途：核对真实会议、设备和仿真训练集口径。
  - 核验日期：2026-08-05
- [microsoft/NOTSOFAR1-Challenge](https://github.com/microsoft/NOTSOFAR1-Challenge)
  - 内容定位：官方代码、数据下载、当前 open research release 和引用信息。
  - 用途：下载数据、跑 baseline、确认开放数据版本差异和许可。
  - 核验日期：2026-08-05
- [NOTSOFAR-1 Challenge: New Datasets, Baseline, and Tasks for Distant Meeting Transcription](https://arxiv.org/abs/2401.08887)
  - 内容定位：Interspeech 2024 论文，提出 NOTSOFAR-1 challenge、数据集和 baseline。
  - 用途：引用挑战赛和理解 benchmark 设计动机。
  - 核验日期：2026-08-05
- [The CHiME-8 DASR Challenge for Generalizable and Array Agnostic Distant Automatic Speech Recognition and Diarization](https://arxiv.org/abs/2407.16447)
  - 内容定位：CHiME-8 DASR 总结论文，说明 NOTSOFAR-1 作为新增 office / corporate meeting scenario。
  - 用途：区分 NOTSOFAR-1 与 CHiME-8 DASR 主任务。
  - 核验日期：2026-08-05

## 6. 相关对象

- [[方向/AI语音/评估/CHiME（语音分离与识别挑战赛）|CHiME]]：NOTSOFAR-1 是 CHiME-8 Task 2。
- [[方向/AI语音/知识/基础概念/Array Audio Signal（阵列音频信号）|Array Audio Signal]]：NOTSOFAR-1 可用于观察真实会议转写中阵列前端的下游收益。
- [[方向/AI语音/知识/基础概念/Beamforming（波束形成）|Beamforming]]、[[方向/AI语音/知识/基础概念/MVDR（最小方差无失真响应）|MVDR]]：多通道 track 的典型前端路线。
- [[方向/AI语音/知识/基础概念/GSS（引导源分离）|GSS]]：NOTSOFAR-1 的前序 CHiME DASR 系统常用前端。
- [[方向/AI语音/知识/基础概念/SS（语音分离）|SS]]：CSS / meeting separation 是 NOTSOFAR-1 系统链路中的关键前端。
- [[方向/AI语音/评估/CER（Character Error Rate）|CER]]：字级评估入口；NOTSOFAR-1 官方主要是 WER / tcpWER。

## 7. 待验证

- 记录 CHiME-8 NOTSOFAR-1 官方 top systems 的具体链路和 tcpWER。
- 评估其是否适合作为本地会议阵列增强实验的首选 benchmark，还是更应选 M2MeT / [[方向/AI语音/数据集/AMI Meeting Corpus（会议语料库）]] / AliMeeting。

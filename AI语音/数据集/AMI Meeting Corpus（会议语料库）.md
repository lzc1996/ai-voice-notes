---
title: AMI Meeting Corpus（会议语料库）
类型: 数据集
发表时间: 2006
时间依据: Carletta 2006 AMI Corpus overview
aliases:
  - AMI
  - AMI Corpus
  - AMI Meeting Corpus
  - AMI 会议语料库
tags:
  - 类型/对象
  - 方向/AI语音
  - 任务/会议转写
  - 任务/说话人分离
  - 资源/数据集
---

# AMI Meeting Corpus（会议语料库）

## 1. 身份

`AMI Meeting Corpus` 是经典英文多人会议语料库，包含约 **100 小时会议录音**，面向会议 ASR、speaker diarization、speaker-attributed ASR、远场前端增强和多模态会议理解。

- 约三分之二是设计团队角色扮演会议，其余为自然发生会议。
- 会议在三个声学属性不同的房间录制，包含大量非母语英语说话人。
- 同步采集近讲麦、远场麦克风、个人/房间视频、投影、白板和电子笔等多模态信号。

## 2. 数据构成

| 维度 | 内容 |
|------|------|
| 语言 | 英语 |
| 规模 | 约 100 小时会议录音 |
| 场景 | 设计团队角色扮演会议 + 自然会议 |
| 音频流 | individual headsets、headset mix、individual lapels、lapel mix、microphone array、RealMedia audio mix |
| 标注 | 正字转写、词级时间、dialog acts、topic segmentation、摘要、命名实体、手势、凝视、头部运动等 |
| 许可 | signals、transcription 和部分 annotations 公开为 CC BY 4.0 |

常见音频口径：

- **IHM（Individual Headset Microphone）**：近讲头戴麦，ASR 难度最低，常作为上界或训练口径。
- **SDM（Single Distant Microphone）**：单远场通道，更接近会议设备单麦场景。
- **MDM（Multiple Distant Microphones）**：远场多麦 / 阵列输入，常用于 beamforming、GSS、[[方向/AI语音/知识/基础概念/CSS（连续语音分离）|CSS]] 和会议前端评测。

## 3. 用途

- **会议 ASR**：多人、重叠说话、远场、混响和非母语英语使其比朗读语料更接近真实会议转写。
- **Diarization**：有多说话人时间对齐转写，可做“谁在什么时候说话”。
- **远场前端增强**：同一会议有近讲和远场/多通道信号，适合评估 beamforming、[[方向/AI语音/知识/基础概念/GSS（引导源分离）]]、CSS、去混响和降噪。
- **Speaker-attributed ASR**：同时考验识别内容和说话人归属。
- **多模态会议理解**：视频、白板、投影、手势、dialog acts 和摘要标注适合会议浏览、摘要和行为分析。

## 4. 划分口径

官方给出三个常用 partition，论文必须说明使用哪一个；如果没有声明，官方建议默认理解为 scenario-only partition。

| 划分 | 说明 |
|------|------|
| Scenario-only | 只用角色扮演设计会议；用于多数早期自动标注任务。 |
| Full-corpus | Scenario-only 的严格超集，加入非场景自然会议。 |
| Full-corpus-ASR | 面向 ASR 的划分，训练数据更多；官方说明约 81 小时训练，dev/eval 各约 9 小时量级。 |

## 5. 使用注意

- **不要混用划分**：Scenario-only、Full-corpus、Full-corpus-ASR 不等价，跨论文比较 WER / DER 时必须核对 partition。
- **不要混用麦克风口径**：IHM、SDM、MDM 难度差异很大；同一个模型在近讲和远场上的 WER 不能直接横比。
- **会议转写不只看 WER**：多人会议还需要看 DER、cpWER/tcpWER、speaker-attributed WER 和重叠说话区域表现。
- **语料偏英文会议**：用于中文会议、电话会议或强噪声通话链路时只能作为方法验证，不能代表目标域。
- **多模态资源大且格式老**：标注使用 NXT 格式，下载信号需要按会议和媒体流选择；工程上通常先用现成 Kaldi/ESPnet/NeMo recipe 或 Hugging Face 镜像。

## 6. 相关对象

- [[方向/AI语音/评估/NOTSOFAR-1（远场会议转写挑战）]]：更现代的远场会议转写挑战。
- [[方向/AI语音/知识/基础概念/GSS（引导源分离）]]：AMI 是 GSS / diarization-conditioned separation 的经典复现对象之一。
- [[方向/AI语音/知识/基础概念/Reverberation Modeling（混响建模）]]：AMI 远场麦包含真实房间混响。
- [[方向/AI语音/评估/语音增强评估指标体系]]：会议前端不能只看听感，还要看 ASR 和说话人归属。

## 7. 关键资源

- [AMI Corpus official site](https://groups.inf.ed.ac.uk/ami/corpus/)
  - 内容定位：官方入口，说明 100 小时、多模态信号、角色扮演/自然会议构成与 CC BY 4.0 许可。
  - 核验日期：2026-08-18
- [AMI Corpus overview](https://groups.inf.ed.ac.uk/ami/corpus/overview.shtml)
  - 内容定位：Carletta 2006 corpus overview，说明采集设备、会议设计、标注类型和数据特点。
  - 核验日期：2026-08-18
- [AMI Corpus download](https://groups.inf.ed.ac.uk/ami/download/)
  - 内容定位：下载 signals、transcription、manual / automatic annotations 和各媒体流。
  - 核验日期：2026-08-18
- [AMI official train/dev/eval partitions](https://groups.inf.ed.ac.uk/ami/corpus/datasets.shtml)
  - 内容定位：Scenario-only、Full-corpus、Full-corpus-ASR 划分说明。
  - 核验日期：2026-08-18
- [OpenSLR AMI mirror](https://www.openslr.org/16/)
  - 内容定位：OpenSLR 镜像入口，便于脚本化下载。
  - 核验日期：2026-08-18

## 8. 待验证

- 本地会议阵列增强实验应优先采用 AMI、AliMeeting、M2MeT、LibriCSS 还是 [[方向/AI语音/评估/NOTSOFAR-1（远场会议转写挑战）]]。
- 当前主流 recipe 对 AMI 的 IHM / SDM / MDM 标准 WER、DER、tcpWER 口径。
- 是否需要拆独立笔记记录 AMI 的 Kaldi、ESPnet、NeMo、SpeechBrain recipe 差异。

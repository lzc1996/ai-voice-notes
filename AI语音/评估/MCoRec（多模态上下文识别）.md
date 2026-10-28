---
title: MCoRec（多模态上下文识别）
类型: 评测基准
发表时间: 2025-07-01
时间依据: 挑战赛数据发布日
aliases:
  - MCoRec
  - mcorec
  - MCoRec Challenge
  - CHiME-9 Task 1
  - CHiME-9 MCoRec
  - Multi-Modal Context-aware Recognition
  - Multi-Modal Context-Aware Recognition Challenge
  - 多模态上下文识别
  - 多模态上下文感知识别
  - 多会话分离转录
  - 360° 音视频多会话分离转录
tags:
  - 类型/对象
  - 方向/AI语音
  - 任务/ASR
  - 任务/说话人日志
  - 主题/多模态
  - 主题/远场语音
---

# MCoRec（多模态上下文识别）

## 0. 背景

**问题现场**：真实社交场景中多场对话同时发生，"分离 + 转写"范式不足以回答"谁在哪个对话里说了什么"。

**切入点**：CHiME-9 Task 1 用 360° 音视频单设备录制多会话场景，任务升级为逐说话人时间对齐转写 + 会话聚类，以 JACER 定榜。

## 1. 身份

`MCoRec`（Multi-Modal Context-aware Recognition，多模态上下文识别）是 **CHiME-9 Task 1**：对单个 360° 音视频录制中**同时发生的多场对话**做转写与理解，核心任务有两件：**逐说话人时间对齐转写**（输出 .vtt）与**会话聚类**（说话人→会话分组映射）。

边界：它不是语音增强 / 阵列增强 benchmark——相机居中单麦录制，没有多通道阵列自由度；它把目标从"分离+转写"升级为"转写+会话结构理解"，是 [[方向/AI语音/知识/调研与地图/Array Speech Enhancement Frontier（阵列语音增强前沿调研）|阵列增强前沿]] 里"前端被下游任务吸收"的极端形态（冠军系统甚至不做独立增强/提取模块）。

## 2. 任务口径

- **任务 1（Individual Speaker Transcription）**：对评测区间内每个目标说话人生成时间对齐转写（WebVTT）。
- **任务 2（Conversation Clustering）**：通过说话人到会话的映射，把参与者归入各自的对话。
- **排序指标**：Joint ASR-Clustering Error Rate（**JACER**，联合转写+聚类错误率）为主；辅以逐说话人 WER 与会话聚类 pairwise F1。

## 3. 数据口径

- **场景**：单房间最多 8 个活跃说话人、最多 4 场同时对话（每场 2–4 人），语音重叠率可达 **100%**；会话约 6 分钟，真实无脚本日常话题。
- **录制**：桌中心 GoPro Max 360°（4K 视频 25fps + 单通道 16kHz 音频）；训练集额外含逐说话人手机视频（720p）与贴身领夹麦，**dev/eval 只有中央 360° 音视频**。
- **规模**：训练 56 场（5.6 h）、dev 25 场（2.5 h）、eval 69 场（6.9 h）；2025-07-01 发布，eval 数据 2026-01-28 发布，最终提交 2026-02-06。

## 4. 基线与结果

官方基线五件套：ASD（人脸裁剪 + 音频判断谁在说话）→ 人脸关键点 / 嘴部裁剪（RetinaFace + FAN）→ 视频切段（滞后阈值，≤15 s）→ AVSR（音频+视觉联合转写）→ 基于时间的会话聚类（同时说话→异会话，先后说话→同会话，凝聚聚类）。

- **基线 dev**：聚类 F1 0.8153；最佳逐说话人 WER 0.4990（AV-HuBERT + MCoRec 微调）；最佳 JACER 0.3548。
- **冠军 USTC-NERCSLIP + 讯飞**（2026，[arXiv:2603.01415](https://arxiv.org/abs/2603.01415)）：级联改进 ASD / AVTSE / AVSR（Whisper + LLM 技术）；dev 逐说话人 WER 32.44%（单系统）→ 31.40%（ROVER 融合）；LLM 零样本聚类 F1 **1.0**；最终 JACER **15.70%**。
- **AUVIS**（2026，[ISCA 报告](https://www.isca-archive.org/chime_2026/ackermann26_chime.html)）：专注会话聚类流水线，聚类 F1 相对提升 14.8%，WER 相对降 0.9%，JACER 相对降 17.09%（dev）。
- **BUT**（2026，[arXiv:2604.27436](https://arxiv.org/abs/2604.27436)）：**没有独立增强/提取模块**——长上下文 AV-TS-ASR 把提取隐式做进 ASR（Parakeet-v2 用 AV-HuBERT 视觉表征条件化，单次解码整段录音）。

## 5. 使用注意

- 评估"前端是否值得做"的参考口径：冠军系统不依赖独立增强/提取模块，仍拿下 JACER 15.70%，说明该场景下**多模态 ASR 端到端吸收分离**是可行路线。
- 与 [[方向/AI语音/评估/CHiME（语音分离与识别挑战赛）|CHiME]] 系列其它届不同，MCoRec 无多通道阵列自由度，不能当阵列增强 benchmark 用。
- 结果 2026-05-04 HSCMA&CHiME 2026 workshop 公布，注意区分 dev 自测与官方 eval 榜单数字。

## 6. 关键来源

- [CHiME-9 Task 1 MCoRec 官网](https://www.chimechallenge.org/challenges/chime9/task1/index)
  - 内容定位：任务定义、数据、评测指标与赛程。
  - 用途：任务口径与指标确认。
  - 核验日期：2026-08-06
- [MCoRec 官方基线（GitHub）](https://github.com/MCoRec/mcorec_baseline)
  - 内容定位：ASD + 嘴部裁剪 + AVSR + 聚类五件套基线实现与 dev 分数。
  - 用途：基线机制与数值。
  - 核验日期：2026-08-06
- [The USTC-NERCSLIP Systems for the CHiME-9 MCoRec Challenge（arXiv:2603.01415）](https://arxiv.org/abs/2603.01415)
  - 内容定位：冠军系统技术报告。
  - 用途：冠军路线与数字。
  - 核验日期：2026-08-06

## 7. 相关对象

- [[方向/AI语音/评估/CHiME（语音分离与识别挑战赛）|CHiME]]：MCoRec 是 CHiME-9 Task 1，与 [[方向/AI语音/评估/ECHI（助听对话增强）|ECHI]]（Task 2）并列。
- [[方向/AI语音/评估/NOTSOFAR-1（远场会议转写挑战）|NOTSOFAR-1]]：CHiME-8 的会议转写任务，同系列上一代。
- [[方向/AI语音/知识/调研与地图/Array Speech Enhancement Frontier（阵列语音增强前沿调研）|阵列语音增强前沿调研]]：CHiME-9 / MCoRec 调研条目。
- [[方向/AI语音/团队/USTC-NERCSLIP（中科大 NERCSLIP 实验室）|USTC-NERCSLIP]]：冠军系统。
- [[方向/AI语音/团队/BUT Speech Group（布尔诺理工语音组）|BUT Speech Group]]：长上下文 AV-TS-ASR 路线。
- [[方向/AI语音/知识/基础概念/TSE（目标说话人提取）|TSE]]：AVTSE 是冠军系统关键模块；本挑战"提取隐式做进 ASR"是其反面路线。

## 8. 待验证

- 官方 eval 榜最终数字（workshop 2026-05-04 公布后）与 ECHI（CHiME-9 Task 2）的任务指标口径。
- 冠军路线在"前端 + 大模型"工程分工下的可迁移性（会议、助听、机器人对话等真实产品场景）。

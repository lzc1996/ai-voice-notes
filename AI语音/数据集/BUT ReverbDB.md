---
title: BUT ReverbDB
类型: 数据集
aliases:
  - BUT Speech@FIT Reverb Database
  - BUT Speech@FIT Reverb Dataset
  - BUT Reverb
  - 布尔诺理工混响数据库
tags:
  - 类型/对象
  - 方向/AI语音
  - 任务/语音增强
  - 任务/远场ASR
  - 资源/数据集
---

# BUT ReverbDB

## 1. 身份

`BUT ReverbDB` 是 Brno University of Technology / BUT Speech@FIT 发布的真实房间混响数据库，正式名为 **BUT Speech@FIT Reverb Database**。它收集真实测量的房间冲激响应（RIR）、房间环境噪声、重放语音和麦克风 / 扬声器位置元数据，用于远场 ASR、说话人识别（SID）和麦克风阵列实验。

边界：它是**真实 RIR + 噪声 + 重放语音资源**，不是增强模型；和 [[方向/AI语音/数据集/C4DM RIR|C4DM RIR]] 一样可作为混响增强源，但 BUT ReverbDB 更强调多房间、多麦克风位置、真实噪声和远场 ASR/SID 复现实验。

## 2. 数据构成

- **房间**：官网 2019-06 release 列出 9 个房间，覆盖办公室、楼梯、酒店房、会议室和讲堂。
- **采集配置**：每个房间放置 31 个麦克风，扬声器平均约 5 个位置；RIR 使用 exponential sine sweep（ESS）测量。
- **附加数据**：包含环境噪声；部分扬声器位置重放 LibriSpeech test-clean，另有 HUB5 2000 RT eval 和 NIST SRE 2010 子集（后两者受 LDC 原始数据许可限制）。
- **元数据**：麦克风和扬声器位置以绝对 / 相对坐标、笛卡尔 / 极坐标形式存储。
- **许可与分发**：官网标注 CC-BY 4.0；RIR-only 包约 8.7 GB，LibriSpeech retransmission 包约 117 GB。

## 3. 用途

- 构造远场 ASR / SID / 语音增强训练或测试数据：干净语音与真实 RIR 卷积，再叠加匹配房间噪声。
- 对比真实 RIR 与镜像源法等人工 RIR 的效果，尤其是遮挡、非标准麦克风位置这类难仿真条件。
- 作为 [[方向/AI语音/知识/基础概念/Reverberation Modeling（混响建模）|Reverberation Modeling]] 的真实采集基准，补足纯仿真 RIR 的泛化缺口。

## 4. 相关对象

- [[方向/AI语音/团队/BUT Speech Group（布尔诺理工语音组）]]：发布 / 维护团队。
- [[方向/AI语音/数据集/C4DM RIR]]：同属真实 RIR 数据集，可在公开 RIR 资源对比中并列。
- [[方向/AI语音/知识/基础概念/ESS（Exponential Sine Sweep）]]：BUT ReverbDB 的 RIR 测量方法。
- [[方向/AI语音/知识/基础概念/Reverberation Modeling（混响建模）]]：RIR 卷积、真实 / 仿真混响建模的上位概念。

## 5. 关键来源

- [BUT Speech@FIT Reverb Database](https://speech.fit.vut.cz/software/but-speech-fit-reverb-database)
  - 内容定位：官方数据集页，列出 release 包、许可、9 个房间、RIR / 噪声 / 重放语音 / 元数据范围。
  - 用途：确认名称、分发入口、数据组成和许可。
  - 核验日期：2026-08-18
- [Building and Evaluation of a Real Room Impulse Response Dataset](https://arxiv.org/abs/1811.06795)
  - 内容定位：BUT ReverbDB 论文，描述采集方法、数据集目标和 ASR 数据增强实验。
  - 用途：确认研究定位：真实 RIR、背景噪声、重放语音，以及真实 RIR 与人工 RIR 的实验结论。
  - 核验日期：2026-08-18
- [IEEE JSTSP 2019 published paper](https://www.fit.vut.cz/research/group/speech/public/publi/2019/szoke_IEEEjournal_2019_final_published_08717722-1.pdf)
  - 内容定位：正式发表版，给出 8-room 论文口径、31 麦克风、平均多个扬声器位置、坐标元数据等细节。
  - 用途：保留论文版本与官网 release 版本（9 rooms）的口径差异。
  - 核验日期：2026-08-18

## 6. 待验证

- 官网 9-room release 与论文 8-room 口径之间新增房间的完整变更记录。
- 当前下载包是否仍可直接访问，以及大包下载是否需要镜像或断点续传。

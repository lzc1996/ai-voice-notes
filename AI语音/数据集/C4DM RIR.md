---
title: C4DM RIR
类型: 数据集
发表时间: 2010-03-14
时间依据: Stewart & Sandler 论文发表于 ICASSP 2010（2010-03-14 会议开幕）
aliases:
  - C4DM
  - C4DM 混响
  - C4DM RIR Data Set
  - C4DM Room Impulse Response Data Set
  - Room Impulse Response Data Set
tags:
  - 类型/对象
  - 方向/AI语音
  - 任务/语音增强
  - 资源/数据集
---

# C4DM RIR

## 1. 身份

`C4DM RIR` 是伦敦玛丽女王大学 **Centre for Digital Music（C4DM）** 发布的真实测量房间脉冲响应（RIR）数据集，论文为 Stewart & Sandler《Database of Omnidirectional and B-Format Room Impulse Responses》（ICASSP 2010）。它是语音增强 / 去混响 / ASR 训练中最常用的**真实 RIR 增强源**之一。

边界：C4DM 是实验室名（Centre for Digital Music），不是模型或算法；说"C4DM 混响"时指的都是这批 RIR 数据。它只含 RIR，不含语音或噪声——需与干净语音卷积使用，这一点和 [[方向/AI语音/数据集/VoiceBank-DEMAND|VoiceBank-DEMAND]]（成品 noisy–clean 对）不同。

## 2. 数据构成

- **房间**：3 个真实房间——Great Hall、Octagon、Classroom。
- **规模**：约 **700 条** RIR（每个房间多个声源/接收位置组合）。
- **格式**：[[方向/AI语音/知识/基础概念/Omni Mic（全向麦克风）|全指向（omni）]] + 一阶 Ambisonic [[方向/AI语音/知识/基础概念/B-format（一阶 Ambisonics）|B-format]]。
- **测量方法**：[[方向/AI语音/知识/基础概念/ESS（Exponential Sine Sweep）|ESS（Exponential Sine Sweep）]]——指数正弦扫频激励，抗噪性好、SNR 高，是当时 RIR 测量的主流方案。

## 3. 用途

- 干净语音卷积 C4DM RIR 得到真实感混响语音，用于有监督去混响 / 语音增强 / 鲁棒 ASR 的训练数据合成。
- [[方向/AI语音/评估/URGENT（通用语音增强挑战）|URGENT]] 系列挑战赛等多失真增强评测的训练数据中使用过真实 RIR（含 C4DM 这类公开集）。
- 常作为 RIR 数据集综述/对比表里的经典基线（同期：AIR、MARDY、ACE）。

## 4. 使用注意

- **房间数少（3 个）**：多样性有限，单独使用容易过拟合到特定声学环境；新工作通常与更大规模数据集（MeshRIR、ARNI、[[方向/AI语音/数据集/BUT ReverbDB|BUT ReverbDB]]、OpenAIR）混合，或辅以合成 RIR（如 [[方向/AI语音/知识/基础概念/Reverberation Modeling（混响建模）|镜像源法]] 生成）。
- 分发渠道几经迁移：早期在 isophonics.net（C4DM 项目站），现主要靠 RIR 汇总仓库（如 RoyJames/room-impulse-responses）的镜像下载，链接可能失效。
- 采样率和 [[方向/AI语音/知识/基础概念/B-format（一阶 Ambisonics）|B-format]] 通道顺序（WXYZ / FuMa）使用前需确认，避免和训练管线假设不一致。

## 5. 相关对象

- [[方向/AI语音/知识/基础概念/ESS（Exponential Sine Sweep）|ESS]]：C4DM RIR 的测量手段。
- [[方向/AI语音/知识/基础概念/Reverberation Modeling（混响建模）|Reverberation Modeling]]：真实 RIR 与合成 RIR 的建模对照。
- [[方向/AI语音/数据集/VoiceBank-DEMAND|VoiceBank-DEMAND]]：成品混响/带噪语音基准，与"RIR 原始素材"定位不同。
- [[方向/AI语音/数据集/WHAM|WHAM]]：噪声侧的经典增强源，与 C4DM（混响侧）常在同一增强管线中组合使用。

## 6. 关键来源

- [Database of Omnidirectional and B-Format Room Impulse Responses (Stewart & Sandler, ICASSP 2010)](https://ieeexplore.ieee.org/document/5495703)
  - 内容定位：C4DM RIR 原始论文，描述测量方法与数据格式。
  - 用途：确认名称、测量手段和数据定位。
  - 核验日期：2026-08-03
- [HARP: A Large-Scale Higher-Order Ambisonic RIR Dataset（对比表）](https://arxiv.org/html/2411.14207)
  - 内容定位：Ambisonic RIR 数据集对比，给出 C4DM 的规模（约 700 条、3 房间、一阶）。
  - 用途：确认数据规模和格式。
  - 核验日期：2026-08-03
- [RoyJames/room-impulse-responses](https://github.com/RoyJames/room-impulse-responses)
  - 内容定位：公开 RIR 数据集汇总与下载脚本仓库。
  - 用途：实际获取 C4DM RIR 的镜像入口。
  - 核验日期：2026-08-03

## 7. 待验证

- isophonics.net 原始分发页是否仍可访问，以及许条款原文。
- 700 条的精确计数（不同汇总来源口径可能略有出入）。

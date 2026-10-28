---
title: TSP（Time-Stretched Pulse）
类型: 概念
发表时间:
时间依据: 经典声学测量方法；当前笔记未绑定单一发表物
相关任务:
  - 语音增强
相关主题:
  - 声学测量
aliases:
  - Time-Stretched Pulse（TSP）
  - TSP
  - Time-Stretched Pulse
  - tsp
tags:
  - 类型/对象
  - 方向/AI语音
  - 任务/语音增强
  - 主题/声学测量
---

# TSP（Time-Stretched Pulse）

## 1. 身份

TSP 是 **Time-Stretched Pulse**，中文可叫时间拉伸脉冲。它是一类用于测量音频系统或房间 **Impulse Response / Room Impulse Response（IR/RIR）** 的激励信号：把本来很短、能量集中的脉冲在时间上“拉长”为扫频信号，播放并录音后，再用对应的 inverse TSP 反卷积，把响应压回脉冲响应。

边界：这里的 TSP 不是旅行商问题（Traveling Salesman Problem），也不是语音增强模型；它是采集 RIR、扬声器响应、麦克风阵列传递函数的测量方法。

## 2. 基本流程

1. 生成 TSP / log-TSP / ESS 类扫频激励。
2. 用扬声器播放，同时用麦克风或麦克风阵列录音。
3. 用 inverse TSP 对录音反卷积。
4. 得到 IR / RIR，再截取直达声、早期反射、晚期混响尾部。

核心直觉：直接播放一个短脉冲很容易被噪声淹没、也容易受扬声器峰值能力限制；TSP 把能量摊到较长时间里，测量时 SNR 更稳，反卷积后仍能还原系统的脉冲响应。

## 3. 与 ESS 的关系

- **TSP 是更宽的扫频/拉伸脉冲测量家族**，常见说法包括 linear TSP、log-TSP、warped TSP 等。
- [[方向/AI语音/知识/基础概念/ESS（Exponential Sine Sweep）|ESS]] 是指数/对数正弦扫频；在很多工程语境里，ESS / log sweep / log-TSP 会被放在同一类“扫频反卷积测 IR”的方法里讨论。
- 区分重点不在名字，而在 sweep 的频率时间分布、inverse filter 设计、对低频 SNR、谐波失真和时变噪声的鲁棒性。

## 4. 在 AI 语音里的位置

- **真实 RIR 采集**：测得房间 RIR 后，可把干净语音与 RIR 卷积，构造去混响 / 远场 ASR / 语音增强训练和评测数据。
- **麦克风阵列传递函数**：机器人听觉、[[方向/AI语音/知识/基础概念/Beamforming（波束形成）|波束形成]]、声源定位系统常用多次 TSP 录音估计 transfer function。
- **设备链路校准**：测扬声器、麦克风、声卡、房间整体响应；注意测到的是整条链路，不只是房间。

## 5. 实操注意

- sweep 后要留足静音尾巴，否则混响尾部会被截断。
- 播放音量要避免扬声器或声卡削波；非线性失真会污染 IR。
- 多次 TSP 可平均提升 SNR，但环境移动、人走动、空调变化会引入时变误差。
- 严肃测量要记录采样率、播放/录音设备、麦克风位置、声源位置、[[方向/AI语音/知识/基础概念/SPL（声压级）|声压级]]和同步方式。

## 6. 关键资源

- [HARK Cookbook - Recording impulse response](https://www.hark.jp/document/3.1.0/hark-cookbook-en/subsec-InputDataGeneration-002.html)
  - 内容定位：用 TSP 录制 impulse response 的机器人听觉工程流程。
  - 用途：确认 TSP 播放、录音、inverse TSP 反卷积的实际步骤。
  - 核验日期：2026-08-04
- [HARKTOOL5 - Generating Transfer Functions](https://www.hark.jp/document/tf/generating_transfer_functions/Generating_a_Transfer_Function_Using_HARKTOOL5.html)
  - 内容定位：用 recorded TSP responses / impulse responses 生成 transfer function。
  - 用途：理解麦克风阵列和传递函数测量中的 TSP 角色。
  - 核验日期：2026-08-04
- [Warped-TSP paper](https://onlinelibrary.wiley.com/doi/pdf/10.1002/ecjc.20260)
  - 内容定位：讨论 linear TSP、log-TSP 和 warped TSP 在背景噪声、谐波失真下的鲁棒性。
  - 用途：区分 TSP 家族内部变体。
  - 核验日期：2026-08-04

## 7. 相关对象

- [[方向/AI语音/知识/基础概念/ESS（Exponential Sine Sweep）|ESS]]：TSP 家族中最常见的工程相邻概念；都用 sweep + inverse filter 测 IR。
- [[方向/AI语音/知识/基础概念/Reverberation Modeling（混响建模）|Reverberation Modeling]]：TSP/ESS 实测 RIR 是混响建模的一种真实测量入口。
- [[方向/AI语音/知识/基础概念/Beamforming（波束形成）|Beamforming]]：阵列传递函数测量可用于 beamforming 校准。
- [[方向/AI语音/知识/基础概念/Sabine Formula（赛宾公式）|Sabine Formula]]：TSP/ESS 是实测；赛宾公式是从房间体积和吸声量估算 RT60。
- [[方向/AI语音/数据集/C4DM RIR|C4DM RIR]]：真实 RIR 数据集，记录了使用 ESS 类扫频测量。

## 8. 待验证

- 当前语音增强数据集里，哪些公开 RIR 是 TSP / ESS / MLS 测得，哪些是仿真生成。
- 手机、笔记本和低端扬声器链路下，TSP 测得的 RIR 是否足够稳定用于小样本评测。

---
title: Project Denmark（多设备云端 ad-hoc 组阵会议转写）
类型: 模型
发表时间: 2019-09
时间依据: Interspeech 2019 论文；MSR 博客 2019-09-13
任务:
  - 会议转写
  - 说话人日志
  - ad-hoc 阵列
开放状态:
  - paper
aliases:
  - Project Denmark
  - Meeting Transcription Using Asynchronous Distant Microphones
  - Meeting Transcriptions Using Virtual Microphone Arrays
  - ad-hoc microphone array transcription
tags:
  - 类型/对象
  - 方向/AI语音
  - 任务/会议转写
  - 主题/分布式阵列
  - 主题/异步对齐
---

# Project Denmark（多设备云端 ad-hoc 组阵会议转写）

## 0. 背景

**问题现场**：远场会议转写（"谁说了什么"）要达到可用精度通常依赖专用麦克风阵列，硬件成本和部署门槛把字幕/转写的可及性卡住了；而与会者口袋里本来就有带麦克风的手机、笔记本、平板。

**前序路线的缺口**：ad-hoc 阵列的概念 2000 年代初就有，但按 MSR 博客（2019）口径，**此前从未有产品或公开原型落地**——设备音质参差、信号不同步、设备数量与相对位置未知，多路独立信息流难以连贯合并。

**Project Denmark 的切入点**：不造硬件，让与会者现有设备在**云端虚拟组阵**：对齐 → 盲波束形成 → 多流 ASR + 说话人日志 → 转写系统合并，端到端验证可行性（Interspeech 2019 论文 + Build 2019 实时演示）。

## 1. 身份

Project Denmark 是微软 Speech and Dialog Research Group 的长期项目代号（Interspeech 2019 论文《Meeting Transcription Using Asynchronous Distant Microphones》，作者 Takuya Yoshioka、Dimitrios Dimitriadis、Andreas Stolcke、William Hinthorn、Zhuo Chen、Michael Zeng、Xuedong Huang），**用个人设备组成云端 ad-hoc 麦克风阵列做多人会议转写**的系统工作。

边界：目标是转写（WER + 说话人归属），不是增强（无 DNSMOS 类指标）；异步处理走"对齐 + 盲波束形成"信号路线，不是后来 PickNet 的通道选择或 WCA 的特征层注意力。

## 2. 核心机制

```text
多设备异步音频上传
  -> 跨设备信号对齐
  -> 盲波束形成（不知道麦克风数量与位置；
     神经 mask 优化恢复声学模型输入特征）
  -> 多路增强流 -> ASR + 说话人日志
  -> 混淆网络（词 + 说话人假设）系统合并
  -> 带说话人标注的转写
```

关键设计：盲波束形成**刻意输出多路信号**，让下游 ASR/说话人日志保留随机麦克风摆放带来的声学多样性，而不是合并成单路。

## 3. 结果口径

- 3 麦 / 7 麦系统比单设备 WER 好 **14.8% / 22.4%**（相对）。
- 系统有版本可实时运行（Build 2019 演示）。
- NIST 会议测试数据的扩展结果在扩展版《Meeting Transcriptions Using Virtual Microphone Arrays》中报告。
- 评测口径是转写 WER，与增强文献的 SI-SDR/DNSMOS 不可横比。

## 4. 使用判断

- 适合：作为 ad-hoc 阵列**系统级可行性**的源头引用；理解"对齐 + 盲波束形成 + 多流合并"这条信号层路线的起点。
- 不适合：直接当增强方法引用；其波束形成假设与后来特征层对齐（WCA）和通道选择（PickNet）的取舍不同。

## 5. 关键来源

- [Bring your phones to the conference table（MSR Blog，2019-09-13）](https://www.microsoft.com/en-us/research/blog/bring-your-phones-to-the-conference-table-creating-ad-hoc-microphone-arrays-from-personal-devices)
  - 内容定位：项目官方博客；系统流水线（对齐→盲波束形成→多流 ASR/日志→混淆网络合并）、14.8%/22.4% 数字、作者名单、"ad-hoc 阵列尚无产品或公开原型"的自述。
  - 用途：项目身份、系统架构与结果口径。
  - 核验日期：2026-10-28
- [Meeting Transcription Using Asynchronous Distant Microphones（Interspeech 2019 论文页）](https://www.microsoft.com/en-us/research/publication/meeting-transcription-using-asynchronous-distant-microphones/)
  - 内容定位：Interspeech 2019 正式论文；扩展版为 Meeting Transcriptions Using Virtual Microphone Arrays。
  - 用途：一手论文出处（未读全文，数字以博客为准）。
  - 核验日期：2026-10-28

## 6. 相关对象

- [[方向/AI语音/团队/Microsoft Speech Group（微软语音组）]]：所属团队。
- [[方向/AI语音/模型/PickNet（ad-hoc 阵列实时通道选择）]]：同一链条的下一步——从"对齐 + 波束形成"退到"不聚合、只选通道"。
- [[方向/AI语音/模型/Windowed Cross-Attention（窗口交叉注意力异步阵列增强）]]：链条 2025 节点——回到特征层注意力对齐。
- [[方向/AI语音/知识/技术路线/Distributed Multichannel SE（分布式异步多通道增强）]]：所属技术路线（异步多流合并）。
- [[方向/AI语音/知识/调研与地图/Array-Agnostic SE Industry（工业界阵列可变语音增强调研）]]：链条完整叙事与工业对比。
- [[方向/AI语音/知识/基础概念/CSS（连续语音分离）]]：多说话人重叠转写的下游难题（博客自述遗留挑战之一）。

## 7. 待验证

- Interspeech 2019 论文全文的实验细节（对齐算法、波束形成网络结构、NIST 会议集数字）未读原文。
- 与扩展版（virtual microphone arrays）的论文关系与差异范围待核。
- Project Denmark 是否有技术进入 Teams 产品（调研页 §14 已记 Group Transcribe 现状待查），公开信息止于 2019–2022。

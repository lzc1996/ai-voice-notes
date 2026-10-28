---
title: PLD（丢包检测）
类型: 概念
相关任务:
  - 语音恢复
相关主题:
  - 丢包修复
相关模型:
  - "[[方向/AI语音/模型/UniPASE]]"
  - "[[方向/AI语音/模型/DeWavLM-Omni]]"
aliases:
  - Packet Loss Detection
  - packet loss detection
  - packet-loss detection
  - PLD
  - pld
  - 丢包检测
  - 缺失帧检测
tags:
  - 类型/对象
  - 方向/AI语音
  - 任务/语音恢复
  - 主题/丢包修复
---
# PLD（丢包检测）

## 1. 身份

`PLD` 在当前 AI 语音笔记里按 **Packet Loss Detection（丢包检测）** 处理：从 degraded waveform 中检测哪些帧像是 VoIP / packet loss 场景造成的缺失或近零片段，并输出 missing-frame mask，供后续语音恢复模型重点修补。

边界：PLD 只是检测 / 标记缺失区域，不负责补全语音。补全动作属于 packet loss concealment / speech restoration；在 [[方向/AI语音/模型/UniPASE|UniPASE]] 里，PLD mask 被送入 [[方向/AI语音/模型/DeWavLM-Omni|DeWavLM-Omni]]，后续再由 Adapter、vocoder 和 PostNet 生成修复波形。

缩写冲突：`方向/推荐系统` 里也有 PLD，指 Personalized Denoising Implicit Feedback；与本页无关。

## 2. 怎么工作

- 把输入 waveform 按短帧切分，例如 UniPASE 附录算法采用 20 ms frame。
- 计算每帧近零采样点比例；如果高于阈值，就标成 packet-loss / missing frame。
- 输出二值 mask，作为模型条件之一，提示后端“这里不是普通噪声，而是缺失内容”。

## 3. 为什么重要

- **区分退化类型**：丢包不是普通加性噪声；模型需要知道哪里是断裂 / 缺失。
- **降低幻觉风险**：显式 mask 能让生成式模型只在缺失区域更积极补全，避免到处“重写”语音。
- **服务实时链路**：VoIP / 语音 Agent 场景里，packet loss concealment 需要低延迟地先定位缺口，再做补偿。

## 4. 在 UniPASE 里的位置

```text
degraded waveform
  -> PLD missing-frame mask
  -> DeWavLM-Omni representation enhancement
  -> Adapter / vocoder / PostNet
  -> restored speech
```

UniPASE 把 PLD 放在 DeWavLM-Omni 的输入侧，用来支持 packet loss concealment 这类 restoration 子任务；它不是独立模型权重，也不是最终 vocoder。

## 5. 关键来源

- [UniPASE: A Generative Model for Universal Speech Enhancement with High Fidelity and Low Hallucinations](https://arxiv.org/abs/2604.14606)
  - 内容定位：提出 UniPASE，并在系统链路中使用 packet loss detection mask 支持 universal speech enhancement。
  - 用途：确认 PLD 与 DeWavLM-Omni / UniPASE 的关系。
  - 核验日期：2026-08-04
- [UniPASE paper detail page - AlphaXiv](https://www.alphaxiv.org/abs/2604.14606)
  - 内容定位：提取论文附录中的 PLD Algorithm 1，说明按帧近零比例生成 missing packet mask。
  - 用途：记录 PLD 的工程口径。
  - 核验日期：2026-08-04

## 6. 相关对象

- [[方向/AI语音/模型/UniPASE|UniPASE]]：PLD 是其 universal speech enhancement 链路中处理丢包退化的检测模块。
- [[方向/AI语音/模型/DeWavLM-Omni|DeWavLM-Omni]]：使用 PLD mask 辅助表示增强。
- [[方向/AI语音/知识/基础概念/SR（语音恢复）|SR（语音恢复）]]：packet loss concealment 是 SR 的子任务之一。
- [[方向/AI语音/知识/基础概念/SE（语音增强）导论|SE（语音增强）导论]]：PLD 属于多退化增强中的退化定位 / 条件输入。

## 7. 待验证

- UniPASE 的 PLD 阈值在真实 VoIP 丢包、静音段、VAD 切分后的长音频上是否会误报。
- 是否需要把 packet loss concealment / PLC 单独拆成任务笔记。

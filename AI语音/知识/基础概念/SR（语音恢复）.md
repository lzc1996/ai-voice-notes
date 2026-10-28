---
title: SR（语音恢复）
类型: 概念
发表时间:
时间依据: 任务概念；覆盖降噪、去混响、带宽扩展、丢包修复等多类恢复任务，非单一发表物
相关任务:
  - 语音增强
  - 语音恢复
相关模型:
  - "[[方向/AI语音/模型/UniSE（Unified Speech Enhancement）]]"
  - "[[方向/AI语音/模型/WavLM]]"
  - "[[方向/AI语音/模型/HuBERT]]"
  - "[[方向/AI语音/模型/Miipher]]"
  - "[[方向/AI语音/模型/MaskSR]]"
  - "[[方向/AI语音/模型/MaskSR2]]"
  - "[[方向/AI语音/模型/UniPASE]]"
  - "[[方向/AI语音/模型/GAP-URGENet]]"
相关评估:
  - "[[方向/AI语音/评估/NFE（函数评估次数）]]"
  - "[[方向/AI语音/评估/CAcc]]"
  - "[[方向/AI语音/评估/STOI 与 ESTOI]]"
  - "[[方向/AI语音/评估/SI-SDR]]"
aliases:
  - 语音恢复（SR）
  - SR
  - 语音恢复
  - sr
tags:
  - 类型/对象
  - 方向/AI语音
  - 任务/语音增强
  - 任务/语音恢复
---

# SR（语音恢复）

## 1. 身份

`SR` 在当前 AI 语音笔记里按 **Speech Restoration（语音恢复）** 处理：给一段受损语音，恢复成更清晰、连续、自然、尽量保留原说话人和原内容的语音。

边界：SR 比传统“降噪”更宽，通常把 denoising、dereverberation、declipping、bandwidth extension、packet loss concealment、codec artifact removal 等都视作恢复子问题。但它一般默认目标仍是同一说话人的原始语音，不是 TTS 重新配音，也不是普通音频生成。

## 2. 覆盖哪些退化

| 子任务 | 退化来源 | 目标 |
|---|---|---|
| Denoising | 加性背景噪声、设备底噪 | 去噪但保留语音内容和音色 |
| Dereverberation | 房间冲激响应尾巴 | 减少远场混响和拖尾 |
| Declipping | 录音过载截顶 | 修复削波失真 |
| Bandwidth Extension | 电话 8 kHz、低采样率、频带缺失 | 补高频和自然度 |
| Packet Loss Concealment | VoIP 丢包、断续 | 先用 [[方向/AI语音/知识/基础概念/PLD（丢包检测）]] 等方法定位缺失帧，再补全并保持连续 |
| Codec artifact removal | Opus/AMR/MP3 等压缩伪影 | 去伪影但不改写内容 |

## 3. 和相邻任务的区别

- **语音增强（SE）**：常作为总称；SR 是其中更强调“多退化修复 / restoration”的口径。
- **[[方向/AI语音/知识/基础概念/TSE（目标说话人提取）|TSE]]**：TSE 先问“要谁的声音”，SR 先问“这一路语音坏在哪里”。
- **[[方向/AI语音/知识/基础概念/SS（语音分离）|语音分离（SS）]]**：SS 输出多路说话人；SR 通常输出一路被修复的主语音。
- **TTS / voice cloning**：TTS 可以重新生成声音；SR 要尽量保持原录音身份、内容和时序。

## 4. 常见路线

- **判别式回归 / mask**：直接从 degraded speech 回归 clean speech 或频谱 mask，低延迟、低幻觉，是实时系统常用底线。
- **Vocoder / analysis-synthesis**：先抽语音内容或声学条件，再用 [[方向/AI语音/知识/基础概念/Vocoder（声码器）|vocoder]] 重建波形，常用于带宽扩展、老录音修复和缺失补全。
- **扩散 / Flow Matching**：把恢复看作生成过程，强退化下音质上限高，但要控制 [[方向/AI语音/评估/NFE（函数评估次数）|NFE / 采样步数]] 和幻觉。
- **codec LM / token LM**：用 [[方向/AI语音/知识/基础概念/NAC（神经音频 Codec）|codec token]] 或离散语音 token 表示语音，再预测干净 token；[[方向/AI语音/模型/SELM|SELM]] 和 [[方向/AI语音/模型/UniSE（Unified Speech Enhancement）|UniSE]] 属于这条线。
- **SSL 表示回归 / 蒸馏**：用 [[方向/AI语音/模型/WavLM|WavLM]] / [[方向/AI语音/模型/HuBERT|HuBERT]] 表示约束内容和音系一致性，降低生成式幻觉。

## 5. 使用注意

- SR 的关键风险是“听起来更好但内容被改写”：必须配合 [[方向/AI语音/评估/CAcc|CAcc]]、[[方向/AI语音/评估/STOI 与 ESTOI|ESTOI]]、[[方向/AI语音/评估/SI-SDR|SI-SDR]] 和人工听测。
- 带宽扩展和丢包修复天然需要补不存在的信息，不能只看主观 MOS。
- 实时 SR 要优先检查算法延迟、chunk 边界伪影和跨块一致性。

## 6. 相关对象

- [[方向/AI语音/知识/基础概念/SE（语音增强）导论|语音增强]]：SR 是语音增强里的多退化恢复口径。
- [[方向/AI语音/模型/UniSE（Unified Speech Enhancement）|UniSE]]：把 SR / TSE / SS 统一到 decoder-only LM-based 框架。
- [[方向/AI语音/知识/基础概念/SS（语音分离）|语音分离]]：SS 处理多人拆轨，SR 处理单路受损语音修复。
- [[方向/AI语音/知识/生成式语音增强/扩散模型与语音|扩散模型与语音]]：生成式 SR 的早期音质上限路线。
- [[方向/AI语音/知识/基础概念/Flow Matching（流匹配）|Flow Matching]]：低步数生成式恢复和实时化的重要路线。
- [[方向/AI语音/知识/基础概念/PLD（丢包检测）|PLD]]：packet loss concealment 前的缺失帧检测模块。
- [[方向/AI语音/模型/Miipher|Miipher]]：面向 TTS 数据清洗的 speech restoration 模型，LibriTTS-R 使用它修复原始 LibriTTS。
- [[方向/AI语音/模型/MaskSR]]：用 neural codec acoustic tokens + masked LM 做 44.1 kHz full-band speech restoration。
- [[方向/AI语音/模型/MaskSR2]]：在 MaskSR 上加入 semantic KD，重点改善恢复语音的 intelligibility / WER。
- [[方向/AI语音/模型/UniPASE|UniPASE]]、[[方向/AI语音/模型/GAP-URGENet|GAP-URGENet]]：universal speech restoration / enhancement 的近期系统代表。

## 7. 关键来源

- [Speech Enhancement and Dereverberation with Diffusion-based Generative Models](https://arxiv.org/abs/2208.05830)
  - 内容定位：SGMSE+ 系工作，把 speech enhancement / dereverberation 放进 diffusion-based generative restoration 路线。
  - 用途：建立生成式语音恢复的代表路线。
  - 核验日期：2026-08-03
- [Real-Time Streamable Generative Speech Restoration with Flow Matching](https://arxiv.org/abs/2512.19442)
  - 内容定位：Stream.FM，用 flow matching 做实时流式 speech restoration。
  - 用途：跟踪 SR 实时化方向。
  - 核验日期：2026-08-03
- [UniSE: A Unified Framework for Decoder-Only Autoregressive LM-Based Speech Enhancement](https://arxiv.org/abs/2510.20441)
  - 内容定位：把 Speech Restoration、TSE 和 Speech Separation 放进统一 decoder-only LM-based speech enhancement 框架。
  - 用途：确认 SR 在统一语音增强框架里的任务定义。
  - 核验日期：2026-08-03

## 8. 收尾与待实验

- **术语边界**：当前页已经用任务目标和输出形态区分 SR、SE、universal SE 与挑战赛口径，暂不再拆更细 MOC。
- **待实验**：实时场景下比较判别式模型、[[方向/AI语音/模型/Stream.FM]] 与 [[方向/AI语音/模型/UniSE（Unified Speech Enhancement）]] 的延迟、内容保持和跨块一致性。

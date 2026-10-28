---
title: MaskSR
类型: 模型
发表时间: 2024-06-04
时间依据: arXiv v1 首次提交日；Interspeech 2024 论文
任务:
  - 语音恢复
  - 语音增强
  - bandwidth extension
  - declipping
  - dereverberation
相关主题:
  - full-band speech restoration
  - masked language model
  - neural codec
  - acoustic token
开放状态:
  - paper
  - demo
aliases:
  - "MaskSR: Masked Language Model for Full-band Speech Restoration"
  - Masked Language Model for Full-band Speech Restoration
  - MaskSR-M
  - full-band speech restoration MaskSR
tags:
  - 类型/对象
  - 方向/AI语音
  - 任务/语音恢复
  - 任务/语音增强
  - 主题/神经音频codec
  - 主题/masked-modeling
---

# MaskSR

## 0. 背景

**问题现场**：把受噪声、混响、削波、低带宽等多种退化影响的语音恢复成 44.1 kHz 高质量语音。

**MaskSR 的切入点**：不走传统频谱 mask 回归，而是先用预训练神经 codec 把语音变成离散声学 token，再用 masked language model 在受损语音条件下迭代补全目标 clean token（codec-token restoration）。

## 1. 身份

`MaskSR` 是 Xu Li、Qirui Wang、Xiaoyu Liu 提出的 full-band [[方向/AI语音/知识/基础概念/SR（语音恢复）]] 模型，论文题目为 *MaskSR: Masked Language Model for Full-band Speech Restoration*，发表于 Interspeech 2024。

它的目标是把受 noise、reverb、clipping、low bandwidth 等多种退化影响的语音恢复成 44.1 kHz 高质量语音。边界上，它不是传统频谱 mask 回归模型，也不是 ASR/TTS 模型；它更接近 codec-token restoration：先把语音变成离散声学 token，再用 masked language model 补全目标 clean speech token。

## 2. 核心机制

```text
corrupted speech waveform
  -> pre-trained neural codec / DAC acoustic tokens
  -> masked language model conditioned on corrupted speech
  -> iterative sampling reconstructs target speech tokens
  -> codec decoder
  -> restored 44.1 kHz waveform
```

- **离散声学 token**：使用预训练 [[方向/AI语音/知识/基础概念/NAC（神经音频 Codec）]] 抽取 acoustic tokens，把 waveform restoration 变成 token restoration。
- **masked token prediction**：训练时随机 mask 高质量目标语音 token，让模型在受损语音条件下预测 clean token。
- **iterative sampling**：推理时逐步重建目标 token，而不是一次性直接回归波形。
- **DAC 关联**：论文关键词和 demo/source 信息指向 [[方向/AI语音/模型/DAC（Descript Audio Codec）]] / neural codec 表示，重点在 44.1 kHz full-band 重建。

## 3. 任务覆盖

- **full-band speech restoration**：联合处理噪声、混响、削波、低带宽等复合退化。
- **bandwidth extension**：demo 覆盖从 1 kHz / 2 kHz / 4 kHz 到 44.1 kHz 的高频补全。
- **declipping**：修复录音过载导致的截顶失真。
- **dereverberation / denoising**：把混响和背景噪声视作同一 restoration 任务里的退化条件。

## 4. 使用判断

- 适合作为 [[方向/AI语音/知识/基础概念/SR（语音恢复）]] 里 “masked LM + codec token” 路线的早期代表。
- 和 [[方向/AI语音/模型/SELM]] / [[方向/AI语音/模型/UniSE（Unified Speech Enhancement）]] 相比，MaskSR 更聚焦 full-band restoration 本身，不把 TSE / SS 统一进同一个任务空间。
- [[方向/AI语音/模型/MaskSR2]] 是直接后续：保留 MaskSR 的 masked acoustic modeling，同时加入 semantic knowledge distillation 来改善 intelligibility / WER。
- 和 [[方向/AI语音/模型/AnyEnhance]] 相比，MaskSR 更像 acoustic-token masked generation 基线；AnyEnhance 在此基础附近继续扩展 prompt guidance、self-critic 和 singing voice。
- 工程复现前先确认官方代码、权重和数据配方；当前稳定来源是论文页、ISCA Archive 和 demo 页。

## 5. 相关对象

- [[方向/AI语音增强/README]]：MaskSR 属于生成式 / codec-token 语音恢复路线。
- [[方向/AI语音/模型/MaskSR2]]：MaskSR 的 intelligibility 改进版，在 speech encoder 上加入 semantic KD。
- [[方向/AI语音/知识/基础概念/SR（语音恢复）]]：任务归属，覆盖 denoising、dereverberation、declipping、bandwidth extension 等。
- [[方向/AI语音/知识/基础概念/NAC（神经音频 Codec）]]：MaskSR 的离散声学 token 基础。
- [[方向/AI语音/模型/DAC（Descript Audio Codec）]]：MaskSR 使用的高保真 neural codec / acoustic token 表示相关对象。
- [[方向/AI语音/知识/基础概念/RVQ（残差向量量化）]]：DAC 类 codec 的常见量化机制。
- [[方向/AI语音/模型/AnyEnhance]]：后续统一 voice enhancement / singing voice enhancement 路线对照。
- [[方向/AI语音/模型/UniSE（Unified Speech Enhancement）]]：LM-based 统一语音增强路线对照。
- [[方向/AI语音/知识/基础概念/Masked Generative Modeling（掩码生成建模）]]：MaskSR 的 masked acoustic token restoration 范式。

## 6. 关键来源

- [arXiv: MaskSR: Masked Language Model for Full-band Speech Restoration](https://arxiv.org/abs/2406.02092)
  - 内容定位：原始论文入口；确认标题、作者、v1 时间、任务覆盖、masked LM、neural codec token 和 iterative sampling。
  - 核验日期：2026-09-17
- [ISCA Archive: MaskSR](https://www.isca-archive.org/interspeech_2024/li24ea_interspeech.html)
  - 内容定位：Interspeech 2024 论文页；记录页码 2275-2279 与 DOI `10.21437/Interspeech.2024-1584`。
  - 核验日期：2026-09-17
- [MaskSR demo page](https://masksr.github.io/MaskSR/)
  - 内容定位：官方 demo 音频样例；覆盖 full-band 44.1 kHz restoration、bandwidth extension、baseline 对比等。
  - 核验日期：2026-09-17

## 7. 核验结论

### 7.1. arXiv 基准结果

以下结果整理自 [MaskSR arXiv 论文](https://arxiv.org/abs/2406.02092) Table 1–4。论文同时报告 full-band 44.1 kHz restoration 与 DNS Challenge 16 kHz 结果；不同任务的分数不可直接横向合并，也不能直接外推到中文或会议语音。

#### 7.1.1. Full-band restoration：ALL-GSR

| 系统 | 参数量 | DNSMOS SIG↑ | DNSMOS BAK↑ | DNSMOS OVL↑ | SESQA↑ | LSD↓ | SpkSim↑ |
|---|---:|---:|---:|---:|---:|---:|---:|
| MaskSR-S | 55M | 3.430 | 3.982 | 3.123 | 3.541 | 1.201 | 0.845 |
| MaskSR-M | 145M | 3.445 | 3.971 | 3.128 | 3.531 | 1.191 | 0.853 |
| UniAudio | 55M | 3.403 | 4.026 | 3.117 | 3.538 | 1.363 | 0.815 |
| Target-DAC | — | 3.455 | 3.981 | 3.143 | 3.533 | 0.827 | 0.931 |

#### 7.1.2. DNS Challenge：16 kHz

| 系统 | With Reverb：SIG / BAK / OVL | SpkSim↑ | Without Reverb：SIG / BAK / OVL | SpkSim↑ | Real Recordings：SIG / BAK / OVL |
|---|---|---:|---|---:|---|
| MaskSR-S | 3.524 / 4.016 / 3.223 | 0.816 | 3.575 / 4.082 / 3.307 | 0.926 | 3.398 / 4.011 / 3.103 |
| MaskSR-M | 3.531 / 4.065 / 3.253 | 0.827 | 3.586 / 4.116 / 3.339 | 0.929 | 3.430 / 4.025 / 3.136 |

#### 7.1.3. Runtime 与主观 MOS

| 系统 | 4 s | 8 s | 12 s | 16 s | 单位 |
|---|---:|---:|---:|---:|---|
| MaskSR-S | 2.72 | 4.10 | 4.92 | 5.22 | s |
| SoundStorm | 3.05 | 4.25 | 5.55 | 6.85 | s |
| UniAudio | 44.86 | 66.08 | 87.54 | 112.02 | s |

| 系统 | 主观 MOS |
|---|---:|
| Unprocessed | 1.96±0.08 |
| Target | 4.66±0.05 |
| NSNet2 | 2.50±0.09 |
| VoiceFixer | 3.53±0.09 |
| MaskSR-M | 4.36±0.07 |

- **公开形态**：截至 2026-09-18，官方 [`MaskSR/MaskSR`](https://github.com/MaskSR/MaskSR) 仓库是 demo 资源页：包含 README、项目目录和音频样例；仓库树未见 Python 源码、模型 checkpoint、训练配置或许可证文件。因此目前能确认的是论文、demo 和样例公开，不能确认有可直接复现的训练/推理包；DAC 的具体配置也没有在该仓库单独公开。
- **参数 / 采样 / RTF**：官方 demo 仓库没有 `MaskSR-M` 的参数表、采样脚本或 RTF benchmark；这些数字不在本页继续当作已知事实，需读论文全文或做本地复现。

## 8. 待实验

- 与 [[方向/AI语音/模型/AnyEnhance]]、[[方向/AI语音/模型/UniPASE]]、[[方向/AI语音/模型/SenSE]] 在同一中文或会议语音样本上的内容保持、音色保持和听感差异。

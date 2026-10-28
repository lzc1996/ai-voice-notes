---
title: DeWavLM-Omni
类型: 模型组件
发表时间: 2026-04-16
时间依据: UniPASE arXiv 首次提交日；DeWavLM-Omni 随 UniPASE 发布
任务:
  - 语音增强
开放状态:
  - paper
  - code
  - weights
aliases:
  - DeWavLM Omni
  - DeWavLM-Omni.pt
  - DeWavLM
  - DWO
  - denoising WavLM Omni
  - UniPASE DeWavLM-Omni
  - 去噪 WavLM
tags:
  - 类型/对象
  - 方向/AI语音
  - 任务/语音增强
  - 主题/语音表示
---

# DeWavLM-Omni

## 0. 背景

**问题现场**：生成式语音增强中，强退化语音的条件表示不可信，容易引发 linguistic hallucination，需要把降质语音映射回归到干净语音的 WavLM 表示。

**DeWavLM-Omni 的切入点**：基于 WavLM 微调做「表示域蒸馏」，结合 PLD 缺失帧 mask 标记缺失片段并排除无教师目标的帧，输出更干净、语言内容更稳定的 phonetic representation。

## 1. 身份

DeWavLM-Omni 是 [[方向/AI语音/模型/UniPASE|UniPASE]] 的核心表示增强模块：基于 [[方向/AI语音/模型/WavLM|WavLM]] 微调，通过知识蒸馏把降质语音映射到更干净、语言内容更稳定的 phonetic representation。

边界：它不是原版 WavLM、不是 vocoder，也不是完整 UniPASE。它负责表示域增强；后面的 Adapter / Vocoder / PostNet 才负责声学细节补全、波形重建和采样率适配。

## 2. 核心作用

- 输入 degraded waveform，并结合 [[方向/AI语音/知识/基础概念/PLD（丢包检测）|PLD（丢包检测）]] 得到的缺失帧 mask。
- 输出增强后的 phonetic representation，用于压低生成式语音增强里的 linguistic hallucination。
- 作为 UniPASE 的第一段核心模块，后接 Adapter、Vocoder 和 PostNet。
- 官方 checkpoint 名称是 `DeWavLM-Omni.pt`；论文表格里也缩写为 `DWO`。

## 3. 核心公式

DeWavLM-Omni 的核心是「表示域蒸馏」：把降质语音映射回归到干净语音的 WavLM 表示。以下为标准回归形式（具体损失细节以 UniPASE 论文为准）。

- 表示回归 / 蒸馏目标：

$$\mathcal{L}_{\mathrm{distill}} = \frac{1}{|\mathcal{T}|} \sum_{t \in \mathcal{T}} \left\| \hat{\mathbf{h}}_t - \mathbf{h}_t^{\mathrm{teacher}} \right\|_2^2$$

说明：$\hat{\mathbf{h}}_t = f_\theta(\tilde{\mathbf{x}}, \mathbf{m})_t$ 为 DeWavLM-Omni 对降质波形 $\tilde{\mathbf{x}}$（结合 PLD 缺失帧 mask $\mathbf{m}$）输出的第 $t$ 帧 phonetic representation；$\mathbf{h}_t^{\mathrm{teacher}}$ 为教师信号（干净语音的 WavLM 表示）；$\mathcal{T}$ 为参与蒸馏的帧集合。

- 缺失帧掩码（输入与损失两侧共用）：

$$t \in \mathcal{T} \iff m_t = 1$$

说明：PLD 输出的 mask 一方面标记输入中的缺失片段，另一方面排除损失中无有效教师目标的帧，防止模型在丢包位置学到错误表示。

## 4. 测试基准与性能

**测试基准**（来源：UniPASE arXiv 摘要）

- URGENT 2026 Challenge（客观评估）。
- 若干评测数据集，覆盖子任务与完整任务（具体名单未在摘要列出，待核）。

**性能指标**

- URGENT 2026 Challenge 客观评估第 1 名（作为提交的 backbone；arXiv 摘要）。
- 定性：各评测数据集上优于或持平现有 SOTA（arXiv 摘要）。
- MOS / CER / WER / PESQ 等具体数值：待核。

## 5. 使用注意

- `Vocoder_WavLM-L24.pt` 只是从 WavLM L24 表示重建波形、方便评估 DeWavLM-Omni 的辅助 vocoder，不是 UniPASE 主链路组件。
- 单独评估 DeWavLM-Omni 时，不应只看 MOS；要同时看内容保持、表示相似度和下游 ASR/CER。
- 和 [[方向/AI语音/模型/L3-SE|L3-SE]] 可放在一起看：二者都在用 WavLM 系表示蒸馏压住强退化下的条件不可信问题。

## 6. 关键来源

- [UniPASE: A Generative Model for Universal Speech Enhancement with High Fidelity and Low Hallucinations](https://arxiv.org/abs/2604.14606)
  - 内容定位：提出 UniPASE，并把 DeWavLM-Omni 定义为核心 representation-level enhancement module。
  - 用途：理解 DeWavLM-Omni 的定位、输入输出和在 UniPASE 中的位置。
  - 核验日期：2026-08-04
- [Xiaobin-Rong/unipase](https://github.com/Xiaobin-Rong/unipase)
  - 内容定位：官方实现与 checkpoint 入口。
  - 用途：确认 `DeWavLM-Omni.pt`、Adapter、Vocoder、PostNet 等权重文件。
  - 核验日期：2026-08-04
- [Xiaobin-Rong/unipase - Hugging Face](https://huggingface.co/Xiaobin-Rong/unipase)
  - 内容定位：官方权重页。
  - 用途：下载模型权重并核对许可。
  - 核验日期：2026-08-04
- [WavLM: Large-Scale Self-Supervised Pre-Training for Full Stack Speech Processing](https://arxiv.org/abs/2110.13900)
  - 内容定位：DeWavLM-Omni 的底座模型背景。
  - 用途：理解 WavLM 表示为什么适合语音增强、分离和鲁棒语音处理。
  - 核验日期：2026-08-04

## 7. 相关对象

- [[方向/AI语音/模型/UniPASE|UniPASE]]：DeWavLM-Omni 是其核心表示增强模块。
- [[方向/AI语音/知识/基础概念/PLD（丢包检测）|PLD]]：为 DeWavLM-Omni 提供 packet loss missing-frame mask。
- [[方向/AI语音/模型/WavLM|WavLM]]：DeWavLM-Omni 从 WavLM 微调而来。
- [[方向/AI语音/模型/GAP-URGENet|GAP-URGENet]]：使用 UniPASE 作为生成式分支。
- [[方向/AI语音/知识/基础概念/SE（语音增强）导论|SE（语音增强）导论]]：DeWavLM-Omni 属于 SSL 表示回归 / 蒸馏路线。
- [[方向/AI语音/知识/技术路线/LLM 与 Agent 对语音增强的影响|LLM 与 Agent 对语音增强的影响]]：可作为语音增强中“表征蒸馏”的具体例子。

## 8. 待验证

- 官方 checkpoint 在本地样本上的表示稳定性、CER/WER 收益和幻觉率。
- `DWO` 单模块与完整 UniPASE 主链路之间的质量差异。
- UniPASE 论文评测表的具体数值（MOS / CER / WER / PESQ）与评测集名单待核（arXiv 摘要未给出）。

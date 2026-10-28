---
title: CAcc
类型: 概念
发表时间: 2025-05-29
时间依据: URGENT 2025 arXiv 首次提交日（CAcc 官方指标口径）
aliases:
  - Character Accuracy
  - 内容准确率
  - Content Accuracy
tags:
  - 类型/对象
  - 方向/AI语音
  - 任务/语音增强
  - 指标/内容保持
---

# CAcc

## 0. 背景

**问题现场**：生成式语音增强会把语音重新生成成别的词（幻觉），而 DNSMOS/[[NISQA]]/[[UTMOS]] 等听感指标对此完全盲。

**切入点**：用 ASR 转写增强语音，与参考文本逐字比对，CAcc = 1 − [[方向/AI语音/评估/CER（Character Error Rate）|CER]]，直接度量内容保持。

## 1. 身份

`CAcc`（Character Accuracy，内容准确率）= 1 − [[方向/AI语音/评估/CER（Character Error Rate）|CER]]：用 ASR 把增强后的语音转写成文本，与参考文本逐字比对得到的正确率，衡量增强过程**有没有把说的内容弄丢或改写**。

- 以百分比计，越高越好；URGENT 2025 判别式冠军配置约 89.9%，生成式冠军仅 67.9%（中文子集低至 20.1%）。

## 2. 用途

- 生成式语音增强的**幻觉检测核心指标**：听感类指标（DNSMOS、[[NISQA]]、[[UTMOS]]）无法发现"语音被重新生成成了别的词"，CAcc 可以。
- 评估增强对下游 ASR 的真实收益（配合 [[方向/AI语音/选型/ASR 模型选型矩阵|ASR 选型]]）。

## 3. 计算口径

- 需要参考文本（或用强 ASR 转写干净参考语音获得）；转写用固定 ASR 模型（URGENT 用 Whisper 系）。
- 分数同时受增强质量和 ASR 模型本身语言能力影响——低资源语言的低分未必全是增强的锅。

常用公式：

$$
\mathrm{CAcc}=1-\mathrm{CER}=1-\frac{S+D+I}{N}
$$

- `S/D/I/N` 与 [[方向/AI语音/评估/CER（Character Error Rate）|CER]] 相同，分别是替换、删除、插入和参考字符数。
- 报百分比时再乘以 $100\%$；插入很多时 CAcc 可能低于 0。

## 4. 使用注意

- 跨语言比较要谨慎：URGENT 2025 同一生成式系统英文 CAcc 尚可、中文 20.1%、日语 36.8%，既暴露幻觉也暴露 ASR 转写器的语言偏置。
- 听感指标高 + CAcc 低 = 典型生成式幻觉签名，见 [[语音增强评估指标体系]] 的指标分裂分析。
- 词级口径见 WER，中文/日语场景用字级 CAcc/CER 更合适。

## 5. 相关对象

- [[方向/AI语音增强/README|AI 语音增强]]
- [[语音增强评估指标体系]]、[[SE SOTA（语音增强模型表现）]]
- [[SpkSim]]（音色保持，与内容保持并列）
- [[方向/AI语音/评估/CER（Character Error Rate）|CER]]

## 6. 关键资源

- [URGENT 2025 挑战论文 (Saijo et al.)](https://arxiv.org/abs/2505.23212)
  - 内容定位：CAcc 作为官方幻觉检测指标的用法与数据。核验日期：2026-07-28

## 7. 待验证

- 用哪个 ASR 做转写器对 CAcc 排名最公平（Whisper 大模型 vs 各语言专用模型）。


---
title: Miipher
类型: 模型
发表时间: 2023-03-03
时间依据: arXiv 首次提交日
任务:
  - 语音恢复
  - 语音增强
  - TTS
开放状态:
  - paper
  - demo
aliases:
  - Miipher speech restoration
  - "Miipher: A Robust Speech Restoration Model Integrating Self-Supervised Speech and Text Representations"
  - robust speech restoration model
tags:
  - 类型/对象
  - 方向/AI语音
  - 任务/语音恢复
  - 任务/语音增强
  - 任务/TTS
---

# Miipher

## 0. 背景

**问题现场**：把 degraded / in-the-wild 的低质量网页语音或公开语料恢复成接近 studio-quality 的语音，用于高质量 TTS 训练数据清洗。

**Miipher 的切入点**：用 w2v-BERT 语音表示作输入、PnG-BERT 文本表示保内容、speaker embedding 补音色，feature cleaner 预测干净 w2v-BERT 特征后经 WaveFit vocoder 重建 24 kHz 波形（LibriTTS-R 即由此链路修复得到）。

## 1. 身份

`Miipher` 是 Google / Koizumi 等人在 2023 年提出的 robust [[方向/AI语音/知识/基础概念/SR（语音恢复）|speech restoration]] 模型，用来把 degraded / in-the-wild speech 恢复成更接近 studio-quality 的语音，并服务于高质量 TTS 训练数据清洗。

边界：Miipher 不是 TTS 模型，也不是数据集；它是把低质量网页语音或公开语料修复成更适合 speech generation 训练数据的恢复模型。[[方向/AI语音/数据集/LibriTTS|LibriTTS-R]] 就是用 Miipher 修复 LibriTTS 得到的音质增强版。

## 2. 核心机制

- **输入表示**：从 degraded speech 中抽取 w2v-BERT speech representation，作为恢复模型的输入特征。
- **文本条件**：从 transcript 经 PnG-BERT 抽取 text representation，帮助保留 phoneme / linguistic content，降低内容改写风险。
- **说话人条件**：从输入语音抽取 speaker embedding，补足 SSL 表示容易丢失的说话人信息。
- **波形重建**：feature cleaner 预测 clean w2v-BERT features，再用 WaveFit neural vocoder 合成 24 kHz restored waveform。

## 3. 核心公式

**1. Feature cleaner 回归损失（核心）：**

$$\mathcal{L}_{\text{clean}} = \mathbb{E}\Big[\big\| \hat h - h_{\text{clean}} \big\|_2^2\Big], \qquad \hat h = F_\theta\big(h_{\text{w2v-BERT}}(y),\, h_{\text{text}},\, e_{\text{spk}}\big)$$

$y$ 为 degraded speech，$h_{\text{w2v-BERT}}(y)$ 为其 w2v-BERT 表示，$h_{\text{text}}$ 为 PnG-BERT 文本表示，$e_{\text{spk}}$ 为说话人 embedding；feature cleaner $F_\theta$ 以三者作条件预测干净语音的 w2v-BERT 特征。（具体度量（L1/L2）与训练细节待核，见待验证）

**2. 文本与说话人条件：**

$$h_{\text{text}} = \text{PnG-BERT}(\text{phoneme},\, \text{grapheme}), \qquad e_{\text{spk}} = \text{SpeakerExtractor}(y)$$

PnG-BERT 联合建模音素与字素，保留 phoneme / linguistic content、降低内容改写风险；说话人 embedding 补足 SSL 表示易丢失的音色信息。

**3. 波形重建：**

$$\hat x = \text{WaveFit}\big(\hat h,\, e_{\text{spk}}\big)$$

WaveFit neural vocoder 以清理后的 w2v-BERT 特征为条件合成 24 kHz restored waveform；LibriTTS-R 即由该链路修复 LibriTTS 得到。

## 4. 测试基准与性能

**测试基准：** 面向 in-the-wild / degraded speech 的语音恢复；应用场景为 Common Voice、LibriVox、LibriTTS 等网络公开语料清洗（LibriTTS-R 即 Miipher 修复 LibriTTS 得到，见「用途」）；输出 24 kHz（WaveFit vocoder）。论文报告对多种音频退化鲁棒、且可用于训练高质量 TTS（arXiv 摘要）。

**性能指标：** 待核——arXiv 摘要无数字、demo 页为纯音频样例页；论文测试集与客观指标（PESQ / STOI / WER / MOS）需从全文核对。

（来源：arXiv 2303.01664 摘要；笔记正文「用途」「后续」）

## 5. 用途

- 清洗 Common Voice、LibriVox、LibriTTS 这类非录音棚或质量不稳定的公开语音。
- 扩大高质量 speech generation / TTS 训练数据，而不是只依赖 studio-recorded corpus。
- 做 TTS 数据来源审计时，区分“原始语料”和“Miipher 修复后的语料”。

## 6. 后续

- `Miipher-2` 是 2025 年的后续版本，面向 million-hour scale data restoration。
- 与原始 Miipher 不同，Miipher-2 用 frozen Universal Speech Model（USM）和 parallel adapters，目标是多语言、无显式 transcript / speaker ID 条件、低成本大规模清洗。

## 7. 关键来源

- [Miipher paper](https://arxiv.org/abs/2303.01664)
  - 内容定位：提出 Miipher，说明 w2v-BERT speech representation、PnG-BERT text conditioning、speaker embedding、WaveFit vocoder 的组合。
  - 用途：理解模型结构、训练目标和 TTS 数据清洗应用。
  - 核验日期：2026-08-05
- [Miipher demo page](https://google.github.io/df-conformer/miipher/)
  - 内容定位：官方音频样例页，展示 restored Common Voice 与基于修复数据训练的 TTS 样例。
  - 用途：主观检查恢复效果和 TTS 数据清洗场景。
  - 核验日期：2026-08-05
- [OpenSLR - LibriTTS-R](https://www.openslr.org/141/)
  - 内容定位：官方 SLR141 数据页，说明 LibriTTS-R 样本与 LibriTTS 一致，但由 Miipher 改善音质。
  - 用途：确认 Miipher 与 LibriTTS-R 的关系。
  - 核验日期：2026-08-05
- [Miipher-2 paper](https://arxiv.org/abs/2505.04457)
  - 内容定位：Miipher 的大规模后续版本，改用 USM 与 parallel adapters 做 million-hour scale restoration。
  - 用途：跟踪 Miipher 系列的多语言和大规模数据清洗路线。
  - 核验日期：2026-08-05

## 8. 相关对象

- [[方向/AI语音/数据集/LibriTTS|LibriTTS-R]]：用 Miipher 修复得到的 LibriTTS 音质增强版本。
- [[方向/AI语音/知识/基础概念/SR（语音恢复）|SR（语音恢复）]]：Miipher 属于 speech restoration / restoration-as-data-cleaning 路线。
- [[方向/AI语音/知识/基础概念/SE（语音增强）导论|SE（语音增强）导论]]：Miipher 可放在 parametric resynthesis / vocoder-based restoration 路线下。
- [[方向/AI语音/模型/WavLM|WavLM]]：Miipher 使用的是 w2v-BERT，不是 WavLM；二者同属 SSL speech representation 生态，容易在模型综述里并列比较。

## 9. 待验证

- 是否有官方可复现实作或公开权重；目前常见的是论文、demo 和非官方实现。
- 本地 TTS 数据清洗时，Miipher / Miipher-2 与当前 UniPASE、SenSE、VoiceFixer 系模型的音质、内容保持和处理成本差异。
- Feature cleaner 回归损失的具体度量（L1/L2）与训练细节需从论文核对。
- 论文的评测集与客观指标数字（PESQ/STOI/WER/MOS）需从论文全文核对（摘要无数字、demo 页为样例页）。

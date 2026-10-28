---
title: MaskGCT
类型: 模型
发表时间: 2024-09-01
时间依据: arXiv v1 首次提交日（2024-09-01）；2025 年被 ICLR 2025 收录
任务:
  - TTS
开放状态:
  - paper
  - code
  - weights
aliases:
  - Masked Generative Codec Transformer
  - maskgct
tags:
  - 类型/对象
  - 方向/AI语音
  - 任务/TTS
---

# MaskGCT

## 0. 背景

**问题现场**：zero-shot TTS 需要在只给参考音频的条件下合成任意文本的高保真语音。

**前序路线的缺口**：传统 TTS 依赖 text-speech 对齐监督与音素级时长预测，两类外部模块带来额外约束。

**MaskGCT 的切入点**：全非自回归的两阶段 mask-and-predict（T2S + S2A），免对齐、免时长预测，推理时按指定长度并行生成；免转录克隆只取参考音频语义 token。

## 1. 身份

MaskGCT（Masked Generative Codec Transformer）是 Amphion（OpenMMLab 音频工具包）团队提出的**全非自回归 zero-shot TTS 模型**，核心主张是去掉两类传统依赖：text-speech 对齐监督与音素级时长预测。它也是「免转录 zero-shot 克隆」路线的早期代表——in-context 提示只用参考音频的语义 token，不需要参考音频的转录文本。

与 [[方向/AI语音/模型/AuK|AuK]] 对比：两者都是免转录 in-context 克隆，但 MaskGCT 走掩码 codec 预测路线（离散 token + 并行生成），AuK 走连续 latent 上的 rectified-flow 路线，且 AuK 把接口统一到了编辑/增强/分离。

## 2. 核心信息

- **两阶段 mask-and-predict**：第一阶段 text-to-semantic（T2S）用文本预测语义 token；第二阶段 semantic-to-acoustic（S2A）在语义 token 条件下预测声学 token。训练时随机掩码、学习补全，推理时按指定长度并行生成全部 token。
- **免对齐、免转录**：无需音素时长模型，无需文本-语音强制对齐；zero-shot 克隆时提示侧只取参考音频的语义 token，不依赖其转录。
- **语义 codec**：对 W2v-BERT 2.0 第 17 层 hidden features 训练 VQ-VAE 得到语义 token。
- **训练数据**：Emilia 数据集约 100K 小时 in-the-wild 多语言语音。
- **开放状态**：代码随 Amphion 仓库开源；模型权重 CC-BY-NC-4.0（**非商业**），据 ModelScope 页面。

## 3. 核心机制

```text
目标文本
  -> T2S（masked generative transformer，条件 = 文本 token + 提示语音的语义 token）
  -> 目标语义 token（并行迭代解码，指定总时长）
  -> S2A（条件 = 语义 token + 提示语音的声学 token）
  -> 目标声学 token
  -> codec decoder -> waveform
```

设 $x$ 为文本 token，$s$ 为提示语音的语义 token，$a$ 为提示语音的声学 token，$y$ 为目标语义 token，$q$ 为目标声学 token，$M$ 为随机掩码位置集合，$\theta_T$ 和 $\theta_S$ 分别为 T2S 与 S2A 参数：

$$
y=G_{\theta_T}(x,s;M),\qquad
q=G_{\theta_S}(y,a;M),\qquad
\hat{w}=D_{\mathrm{codec}}(q)
$$

训练时随机掩码语义/声学 token 序列的一部分，并最小化被掩位置的预测损失：

$$
\mathcal{L}=\mathcal{L}_{\mathrm{T2S}}(y_M\mid x,s,y_{\bar M})
+\mathcal{L}_{\mathrm{S2A}}(q_M\mid y,a,q_{\bar M})
$$

推理时从全掩码起步，多步并行细化，因此 T2S 与 S2A 都不是逐 token 串行生成。

## 4. 测试基准与性能

以下结果整理自 [MaskGCT arXiv 论文](https://arxiv.org/abs/2409.00750) Table 2–5；SIM-O、SMOS、CMOS 越高越好，WER、FSD 越低越好。`rerank` 表示论文报告的重排结果，`gt length` 表示使用真实目标长度。

#### 4.1.1. SeedTTS-Eval 主结果

| 数据集 | 系统 | SIM-O↑ | SIM-O rerank↑ | WER↓ | WER rerank↓ | FSD↓ | SMOS↑ | CMOS↑ |
|---|---|---:|---:|---:|---:|---:|---:|---:|
| LibriSpeech test-clean | Ground Truth | 0.680 | — | 1.940 | — | — | 4.05±0.12 | 0 |
| LibriSpeech test-clean | MaskGCT | 0.687 | 0.723 | 2.634 | 1.976 | 0.886 | 4.27±0.14 | 0.10±0.16 |
| LibriSpeech test-clean | MaskGCT gt length | 0.697 | — | 2.012 | — | 0.746 | 4.33±0.11 | 0.13±0.13 |
| SeedTTS test-en | Ground Truth | 0.730 | — | 2.143 | — | — | 3.92±0.15 | 0 |
| SeedTTS test-en | MaskGCT | 0.717 | 0.760 | 2.623 | 1.283 | 0.188 | 4.24±0.12 | 0.03±0.14 |
| SeedTTS test-en | MaskGCT gt length | 0.728 | — | 2.466 | — | 0.159 | 4.13±0.17 | 0.12±0.15 |
| SeedTTS test-zh | Ground Truth | 0.750 | — | 1.254 | — | — | 3.86±0.17 | 0 |
| SeedTTS test-zh | MaskGCT | 0.774 | 0.805 | 2.273 | 0.843 | 0.106 | 4.09±0.12 | 0.05±0.17 |
| SeedTTS test-zh | MaskGCT gt length | 0.777 | — | 2.183 | — | 0.101 | 4.11±0.12 | 0.08±0.18 |

#### 4.1.2. 与 AR+SoundStorm 对比

| 数据集 | 系统 | SIM-O↑ | WER↓ | FSD↓ | SMOS↑ | CMOS↑ |
|---|---|---:|---:|---:|---:|---:|
| LibriSpeech | AR+SoundStorm | 0.672 | 3.267 | 0.998 | 4.20±0.17 | -0.02±0.20 |
| LibriSpeech | MaskGCT | 0.687 | 2.634 | 0.886 | 4.27±0.14 | 0.10±0.16 |
| SeedTTS en | AR+SoundStorm | 0.683 | 2.846 | 0.323 | 4.03±0.23 | -0.05±0.22 |
| SeedTTS en | MaskGCT | 0.717 | 2.623 | 0.188 | 4.24±0.12 | 0.03±0.14 |
| SeedTTS zh | AR+SoundStorm | 0.747 | 3.865 | 0.238 | 3.78±0.23 | -0.32±0.22 |
| SeedTTS zh | MaskGCT | 0.774 | 2.273 | 0.106 | 4.09±0.12 | 0.05±0.17 |

#### 4.1.3. 音色属性与情绪模仿

| 任务 | SIM-O↑ | WER↓ | 属性 SIM↑ | CMOS↑ | SMOS↑ | 属性 SMOS↑ |
|---|---:|---:|---:|---:|---:|---:|
| Accent imitation | 0.717 | 6.382 | 0.645 | 0.23±0.17 | 4.24±0.16 | 4.38±0.25 |
| Emotion imitation | 0.600 | 12.502 | 0.822 | -0.31±0.17 | 4.07±0.16 | 3.76±0.25 |

## 5. 边界

- 权重 CC-BY-NC-4.0，商用受限。
- 并行生成需预先指定目标时长/长度，时长可控但需外部给定。
- 语义/声学 token 两段式，错误会在两级间传递；声学 codec 的具体实现细节未在本页核实。

## 6. 相关对象

- [[方向/AI语音/MOC - TTS]]：任务入口。
- [[方向/AI语音/模型/AuK]]：免转录 in-context 克隆的后续大规模实例，技术路线不同（flow + 连续 latent）。
- [[方向/AI语音/模型/XTTS-v2]]：论文对照系统之一，同属免转录克隆路线。
- [[方向/AI语音/模型/CosyVoice]]：论文对照系统之一。
- [[方向/AI语音/知识/基础概念/Zero-shot Voice Cloning（零样本声音克隆）]]：任务概念入口。
- [[方向/AI语音/知识/基础概念/Masked Generative Modeling（掩码生成建模）]]：MaskGCT 的 mask-and-predict / 并行迭代生成范式。

## 7. 关键来源

- [MaskGCT: Zero-Shot Text-to-Speech with Masked Generative Codec Transformer（arXiv:2409.00750）](https://arxiv.org/abs/2409.00750)
  - 内容定位：论文主页；定义两阶段 mask-and-predict、免对齐免时长预测的动机、Emilia 100K 小时训练规模。
  - 用途：架构与训练数据的一手出处。
  - 发表日期：2024-09-01（arXiv v1）
  - 核验日期：2026-09-15
- [Amphion MaskGCT README（open-mmlab/Amphion）](https://github.com/open-mmlab/Amphion/blob/main/models/tts/maskgct/README.md)
  - 内容定位：官方代码、checkpoint 下载与 Quick Start。
  - 用途：确认开放状态与复现入口。
  - 核验日期：2026-09-15
- [OpenReview ICLR 2025 页面](https://openreview.net/pdf?id=ExuBFYtCQU)
  - 内容定位：会议版全文，含 SeedTTS test-en/test-zh 的 SIM-O 与 WER 最终数字。
  - 用途：本页评测数字的出处。
  - 核验日期：2026-09-15

## 8. 待深挖

- 论文对「推理不需要提示音频转录」的原文表述（v1/v3 差异）。
- 声学 token 所用 codec 的具体实现与帧率。
- CC-BY-NC-4.0 是全部 checkpoint 统一口径还是仅部分。

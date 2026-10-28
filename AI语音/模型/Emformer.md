---
title: Emformer
类型: 模型
参数量: 76M（TorchAudio EMFORMER_RNNT_BASE_LIBRISPEECH）
发表时间: 2020-10-21
时间依据: arXiv 首次提交日期
任务:
  - ASR
开放状态:
  - paper
aliases:
  - Efficient Memory Transformer
  - Emformer RNN-T
  - EMFORMER_RNNT_BASE_LIBRISPEECH
tags:
  - 类型/对象
  - 方向/AI语音
  - 任务/ASR
---

# Emformer

## 0. 背景

**问题现场**：流式 ASR 需要同时满足低延迟推理和长历史上下文建模。

**前序路线的缺口**：普通 Transformer 难以直接满足流式识别的低延迟和长上下文需求。

**Emformer 的切入点**：把长历史压缩进 augmented memory bank、缓存 left context 的 self-attention key/value，并用并行 block processing 支持低延迟训练。

## 1. 身份

Emformer（Efficient Memory Transformer）是面向低延迟流式语音识别的 Transformer 声学模型。它的核心目标是在流式 ASR 中保留长历史上下文，同时降低自注意力计算和解码开销。

边界：这里先把 Emformer 当作“流式 ASR encoder / acoustic model 架构”记录，不把它扩展成完整 ASR 系统；RNN-T decoder、特征提取、分块输入和 token 后处理属于工程管线的其他组件。

## 2. 核心信息

- 架构动机：普通 Transformer 难以直接满足流式识别的低延迟和长上下文需求。
- 关键机制：把长历史上下文压缩进 augmented memory bank，并缓存 left context 的 self-attention key/value。
- 训练方式：用并行 block processing 支持低延迟模型训练。
- 工程入口：TorchAudio 提供 `EMFORMER_RNNT_BASE_LIBRISPEECH`，可通过 streaming feature extractor、decoder 和 token processor 做在线 ASR。

## 3. 核心公式

Emformer 的核心是 segment-level 自注意力 + memory bank：按块处理输入，用少量记忆向量压缩长历史。

- segment-level 自注意力（块 $i$）：

$$Q_i = S_i^c W_Q, \quad K_i = [m_i^l;\ S_i^l;\ S_i^c;\ S_i^r] W_K, \quad V_i = [m_i^l;\ S_i^l;\ S_i^c;\ S_i^r] W_V$$

$$\mathrm{Attn}_i = \mathrm{softmax}\left(\frac{Q_i K_i^\top}{\sqrt{d_k}}\right) V_i$$

说明：输入段 $S_i = [S_i^l;\ S_i^c;\ S_i^r]$ 由左上下文、当前 chunk、右 lookahead 组成；当前 chunk $S_i^c$ 作为 query，只对「memory $m_i^l$ + 左上下文 + 当前段 + 右上下文」做注意力，实现低延迟并保留长历史；左上下文的 key/value 被缓存复用。

- augmented memory bank 更新：

$$m_{i+1}^a = \mathrm{Truncate}_M\left(\left[m_i^a;\ \mathrm{Pool}(S_i^c)\right]\right)$$

说明：处理完第 $i$ 段后，把段信息压缩进 augmented memory，容量上限为 $M$（超出的最旧记忆被丢弃），长历史由此被压缩成少量向量，控制自注意力计算量。

- 流式 ASR 训练目标（RNN-T / CTC 序列损失）：

$$\mathcal{L} = -\log \sum_{\boldsymbol{\pi} \in \mathcal{B}^{-1}(\mathbf{y})} P(\boldsymbol{\pi} \mid \mathbf{H})$$

说明：$\mathbf{H}$ 为 Emformer encoder 输出，$\boldsymbol{\pi}$ 为含空白/重复的对齐路径，$\mathbf{y}$ 为参考文本，$\mathcal{B}$ 为对齐到文本的映射（CTC 为去重去空白，RNN-T 为允许一帧内输出多 token 的对齐）；Emformer 论文与 TorchAudio `EMFORMER_RNNT_BASE_LIBRISPEECH` 以 RNN-T 形态为主。

## 4. 测试基准与性能

**测试基准**

- LibriSpeech test-clean / test-other（论文）。
- 流式延迟口径：平均 960 ms 与 80 ms 两档。
- 工程入口：TorchAudio `EMFORMER_RNNT_BASE_LIBRISPEECH`（76M 参数，LibriSpeech 预训练）。

**性能指标**（来源：arXiv 摘要）

| 平均延迟 | test-clean WER（%） | test-other WER（%） |
| --- | --- | --- |
| 960 ms | 2.50 | 5.62 |
| 80 ms | 3.01 | 7.09 |

- vs AM-TRF 基线：训练提速 4.6 倍、解码 RTF 相对降低 18%、相对 WER 降低 17%（test-clean）/ 9%（test-other）。
- vs 同延迟同规模 LSTM：相对 WER 降低 9%（test-clean）/ 16%（test-other）。
- TorchAudio 预训练 bundle：第三方（ICASSP 2024）报告 test-clean WER 4.6%，待核。

## 5. 什么时候选 Emformer

- 需要低延迟流式 ASR，而不是离线批处理转写。
- 希望保留 Transformer 的上下文建模能力，但要控制 chunk 级推理成本。
- 需要一个可直接跑通的 PyTorch / TorchAudio 在线 ASR baseline。

## 6. 不适合直接承担的任务

- **完整会议系统**：仍需要外接 [[方向/AI语音/知识/基础概念/VAD（Voice Activity Detection）|VAD]]、说话人分离、标点、分段和术语修正。
- **高保真语音生成或增强**：Emformer 输出目标是识别文本，不是波形重建。
- **最新通用 ASR SOTA 判断**：它更适合作为流式架构和工程 baseline，不应直接替代当前 Qwen3-ASR、Seed-ASR、FunASR、Whisper 等横评。

## 7. 关键资源

- [Emformer paper - arXiv](https://arxiv.org/abs/2010.10759)
  - 内容定位：提出 Emformer；说明 memory bank、left-context key/value cache、parallelized block processing 和 LibriSpeech 低延迟结果。
  - 用途：确认模型身份、架构机制和论文指标。
  - 核验日期：2026-07-31
- [Online ASR with Emformer RNN-T - TorchAudio](https://docs.pytorch.org/audio/master/tutorials/online_asr_tutorial.html)
  - 内容定位：TorchAudio 在线 ASR 教程；使用 `EMFORMER_RNNT_BASE_LIBRISPEECH`，展示 streaming feature extractor、decoder 和 token processor。
  - 用途：确认可运行工程入口和推理管线边界。
  - 核验日期：2026-07-31
- [Emformer ICASSP record](https://doi.org/10.1109/ICASSP39728.2021.9414560)
  - 内容定位：ICASSP 2021 论文记录。
  - 用途：正式论文引用入口。
  - 核验日期：2026-07-31

## 8. 相关对象

- [[方向/AI语音/MOC - ASR|ASR]]：Emformer 是低延迟流式 ASR 的 encoder / acoustic model 路线。
- [[方向/AI语音/知识/技术路线/语音网络结构与模块|语音网络结构与模块]]：Emformer 属于流式 Transformer / memory-augmented encoder 模块。
- [[方向/AI语音/知识/基础概念/Streaming Conformer|Streaming Conformer]]：相邻流式 ASR encoder 路线；都围绕低延迟、有限未来上下文和缓存权衡。

## 9. 待验证

- TorchAudio 当前维护状态下，Emformer RNN-T bundle 是否仍适合作为新项目 baseline。
- Emformer 与 Conformer、chunk-wise Transformer、Zipformer 等流式 encoder 在中文、噪声、远场和实时语音 Agent 场景中的差距。
- `EMFORMER_RNNT_BASE_LIBRISPEECH` 的 license、模型大小、延迟和部署边界是否满足本地实验需求。
- TorchAudio `EMFORMER_RNNT_BASE_LIBRISPEECH` 的官方 WER / RTF 数值待核（当前仅有第三方 ICASSP 2024 报告的 test-clean 4.6%）。

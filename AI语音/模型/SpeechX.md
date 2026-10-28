---
title: SpeechX
类型: 模型
发表时间: 2023-08-14
时间依据: arXiv v1 首次提交日；IEEE/TASLP 期刊版 DOI 10.1109/TASLP.2024.3419418
任务:
  - zero-shot TTS
  - noise suppression
  - target speaker extraction
  - speech removal
  - speech editing
  - speech transformation
开放状态:
  - paper
  - demo
aliases:
  - "SpeechX: Neural Codec Language Model as a Versatile Speech Transformer"
  - Neural Codec Language Model as a Versatile Speech Transformer
  - SpeechX speech transformer
  - SpeechX neural codec language model
tags:
  - 类型/对象
  - 方向/AI语音
  - 主题/音频大模型
  - 主题/语音生成
  - 主题/神经音频codec
  - 任务/TTS
  - 任务/语音增强
---

# SpeechX

## 0. 背景

**问题现场**：TTS、降噪、目标说话人提取、语音编辑等任务通常各自训练专用模型，彼此割裂。

**SpeechX 的切入点**：neural codec language model + task-dependent prompting，用一套模型和离散 token 接口统一多种语音生成/变换任务。

## 1. 身份

SpeechX 是 Microsoft Research 提出的 neural codec language model，把 zero-shot TTS、noise suppression、target speaker extraction、speech removal、speech editing 等任务统一成基于音频和文本 prompt 的语音生成 / 变换问题。

它更适合放在 [[方向/AI语音/MOC - 音频大模型]] 的 codec token 神经语言模型路线里，而不是只当作单一 TTS、SE 或 TSE 模型：核心价值是一个模型覆盖多种 speech transformation 关系。

## 2. 核心机制

```text
task prompt / text prompt + optional input speech + optional reference speech
  -> neural audio codec tokens + text tokens
  -> task-dependent prompting + multi-task codec language model
  -> target speech codec tokens
  -> codec decoder
  -> waveform
```mermaid

- **neural codec LM**：把语音压成离散 codec token，再用语言模型方式预测目标语音 token。
- **task-dependent prompting**：用任务相关特殊 token 告诉模型当前输出目标，例如 TTS、降噪、说话人提取或语音编辑。
- **multi-task learning**：不同任务共享一套模型和 token 接口，减少每个任务单独训练专用模型的割裂。

### 2.1. 架构示意（概念级）

> [!note] 架构示意（概念级）
> 按本页已有输入—中间表示—输出链路整理，不替代论文结构图。

```
flowchart LR
  A["Audio + text/task prompt"] --> B["EnCodec tokenizer"]
  B --> C["Task-conditioned codec language model"]
  C --> D["Codec decoder"]
  D --> E["TTS / denoise / TSE / speech editing output"]
```

## 3. 任务覆盖

- **zero-shot TTS**：给文本和参考语音，生成符合参考音色 / 风格的目标语音。
- **noise suppression**：输入带噪语音，输出更干净的语音。
- **target speaker extraction**：在混合说话人场景中，根据目标说话人线索提取目标语音。
- **speech removal**：从混合音频中移除语音成分，保留背景声。
- **speech editing**：替换或改写语音内容，同时尽量保留说话人和背景声音；论文覆盖 clean/noisy 两种编辑场景。

## 4. 使用判断

- 用它理解 “codec token + prompt + multi-task” 如何把 TTS、增强、编辑、分离类任务合成一个 speech transformer 框架。
- 若目标是工程落地，先确认代码和权重是否开放；当前可靠入口主要是论文、Microsoft Research demo 和 IEEE/TASLP 论文页。
- 和 [[方向/AI语音/模型/AudioLM]] 相比，SpeechX 不只做延续式语音生成 / TTS，而是显式覆盖多种输入语音变换任务。
- 和 [[方向/AI语音/模型/GenSE]] / [[方向/AI语音/模型/DDSE]] 相比，SpeechX 的重点不是单任务增强，而是统一多任务 prompt 建模。

## 5. 相关对象

- [[方向/AI语音/MOC - 音频大模型]]：SpeechX 所在的音频大模型路线入口。
- [[方向/AI语音/模型/AudioLM]]：codec token 神经语言模型的早期代表。
- [[方向/AI语音/知识/基础概念/NAC（神经音频 Codec）]]：SpeechX 依赖的离散语音表示基础。
- [[方向/AI语音/知识/技术路线/语音生成 tokenizer codec 技术路线]]：语音生成 tokenizer / codec 路线总入口。
- [[方向/AI语音/知识/基础概念/Zero-shot Voice Cloning（零样本声音克隆）]]：zero-shot TTS / 音色迁移相关概念。
- [[方向/AI语音/知识/基础概念/TSE（目标说话人提取）]]：SpeechX 覆盖的目标说话人提取任务。
- [[方向/AI语音/知识/基础概念/SE（语音增强）导论]]：SpeechX 覆盖的语音增强任务。
- [[方向/AI语音/模型/UniAudio]] / [[方向/AI语音/模型/Ming-UniAudio]]：统一音频生成 / 编辑模型路线对照。

## 6. 关键来源

- [arXiv: SpeechX: Neural Codec Language Model as a Versatile Speech Transformer](https://arxiv.org/abs/2308.06873)
  - 内容定位：论文入口；确认标题、作者、发布时间、任务覆盖和核心方法。
  - 核验日期：2026-09-17
- [Microsoft Research: SpeechX](https://www.microsoft.com/en-us/research/project/speechx/)
  - 内容定位：项目 / demo 页；确认 audio-text prompts、special tokens、task-dependent prompting、60K hours LibriLight 训练描述和 demo 任务。
  - 核验日期：2026-09-17
- [IEEE Xplore: SpeechX](https://ieeexplore.ieee.org/document/10577150/)
  - 内容定位：IEEE/ACM TASLP 期刊版入口；DOI `10.1109/TASLP.2024.3419418`。
  - 核验日期：2026-09-17

## 7. 核验结论

### 7.1. arXiv 基准结果

以下结果整理自 [SpeechX arXiv 论文](https://arxiv.org/abs/2308.06873) Table II、III、VI、VII；评测主要是英文 / LibriLight 口径，WER 越低越好，DNSMOS、PESQ、SIM 越高越好，不能直接外推到中文或会议语音链路。

#### 7.1.1. 主任务对比

| 系统 | NS WER↓ | NS DNSMOS↑ | NS PESQ↑ | TSE WER↓ | TSE DNSMOS↑ | TSE PESQ↑ | ZS-TTS WER↓ | ZS-TTS SIM↑ |
|---|---:|---:|---:|---:|---:|---:|---:|---:|
| SpeechX（random init.） | 2.56 | 3.05 | 2.24 | 3.12 | 3.46 | 2.27 | 5.40 | 0.57 |
| SpeechX（VALL-E init.） | 2.48 | 3.05 | 2.24 | 2.53 | 3.46 | 2.28 | 4.66 | 0.58 |
| Expert baselines（组合行） | 6.39 | 3.25 | 3.52 | 5.09 | 3.39 | 2.90 | 5.90 | 0.57 |
| No processing | 3.29 | 2.42 | 1.93 | 12.55 | 3.04 | 2.27 | 1.71 | 1.00 |

#### 7.1.2. 编辑与语音移除

| 系统 | Clean edit WER↓ | Clean edit SIM↑ | Noisy edit WER↓ | Noisy edit SIM↑ | Speech removal WER↓ | Speech removal MCD↓ |
|---|---:|---:|---:|---:|---:|---:|
| SpeechX（random init.） | 8.10 | 0.75 | 15.33 | 0.64 | 3.04 | 3.04 |
| SpeechX（VALL-E init.） | 5.63 | 0.76 | 13.95 | 0.65 | — | 3.05 |
| Expert baselines（组合行） | 17.17 | 0.29 | 32.17 | 0.18 | — | — |
| No processing | 38.29 | 0.96 | 42.48 | 0.87 | 12.57 | — |

#### 7.1.3. Text prompt 消融

| Text prompt | NS WER↓ | NS DNSMOS↑ | NS PESQ↑ | TSE WER↓ | TSE DNSMOS↑ | TSE PESQ↑ |
|---|---:|---:|---:|---:|---:|---:|
| With text | 2.48 | 3.05 | 2.24 | 2.53 | 3.46 | 2.28 |
| Without text | 6.76 | 3.05 | 2.20 | 5.00 | 3.01 | 2.23 |

#### 7.1.4. Raw speech 与 EnCodec 消融

| 输入 | WER↓ | DNSMOS↑ | PESQ↑ | SIM↑ |
|---|---:|---:|---:|---:|
| Raw clean speech | 1.71 | 3.22 | 4.64 | 1.00 |
| EnCodec clean | 1.81 | 2.97 | 2.69 | 0.81 |
| Raw noisy speech | 3.29 | 2.42 | 1.93 | 0.95 |
| EnCodec noisy | 5.08 | 2.19 | 1.63 | 0.75 |

- **官方代码 / 权重**：截至 2026-09-18，Microsoft Research 项目页、论文入口未给出官方代码或模型权重下载。GitHub 上存在同名 [`Speech-AI/SpeechX`](https://github.com/Speech-AI/SpeechX) 仓库，但当前只有 `asteroid-transmask.tar.gz`，没有 README、许可证或 SpeechX checkpoint，不能视为可复现的官方实现。
- **与后续统一模型的边界**：`SpeechX` 是 60K 小时 LibriLight + audio/text prompt + 离散 codec LM + 多任务 speech transformation；[[方向/AI语音/模型/UniAudio]] 是 1B codec LM，用 source-target 序列统一 11 个音频生成任务；[[方向/AI语音/模型/Ming-UniAudio]] 是 16.8B MoE（2.8B active），用连续 `MingTok-Audio` 覆盖理解、生成和编辑。三者的任务接口与表示路线已经可以区分；后两者训练数据总规模未在本库完整记录，不做规模优劣判断。

## 8. 待深挖

- 若需要严格比较训练数据规模，再回到 `UniAudio` / `Ming-UniAudio` 原始技术报告补齐小时数；不影响当前路线归类。

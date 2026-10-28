---
title: Kimi-Audio
类型: 模型
发表时间: 2025-04-25
时间依据: arXiv 首次提交日
任务:
  - 音频理解
  - ASR
  - TTS
  - 语音对话
开放状态:
  - paper
  - code
  - weights
aliases:
  - kimi-audio
  - Kimi-Audio-7B-Instruct
  - Kimi Audio
  - Kimi-Audio Technical Report
  - MoonshotAI/Kimi-Audio
  - 月之暗面 Kimi-Audio
tags:
  - 类型/对象
  - 方向/AI语音
  - 任务/音频理解
  - 任务/ASR
  - 任务/TTS
  - 任务/语音对话
---

# Kimi-Audio

## 0. 背景

**问题现场**：音频理解、生成与对话此前分散在不同专用模型中，需要一个开源通用底座在单一框架内覆盖各类音频任务。

**Kimi-Audio 的切入点**：Whisper 系 tokenizer 产出「离散语义 token + 连续声学特征」双路输入（统一 12.5 Hz，兼得可预测性与副语言信息），text/audio 双 head 输出，chunk-wise flow-matching 流式 detokenizer 降低生成延迟；基于 Qwen2.5-7B、1300 万小时以上音频预训练。

## 1. 内容定位

Kimi-Audio 是月之暗面（Moonshot AI）2025 年 4 月开源的通用音频基础模型：单一框架内覆盖音频理解、生成与对话，目标是做「什么音频任务都能接」的开源底座。官方报告在语音识别、音频理解、audio-to-text 对话与语音对话多项任务上给出 SOTA 口径，并同时开源了公平可复现的评测工具包。

## 2. 核心信息

- **规模与底座**：7B，指令版 Kimi-Audio-7B-Instruct 基于 Qwen2.5-7B。
- **混合音频输入**：Whisper-large-v3 系 audio tokenizer 产出**离散语义 token + 连续声学特征**双路输入，统一按 12.5 Hz 处理——同时保留语义与副语言信息，是其通用性的关键设计。
- **训练**：1300 万小时以上多样音频预训练，混合单模态任务、音频-文本对齐任务与交错多模态任务。
- **任务面**：ASR、音频问答（AQA）、音频字幕（AAC）、语音情感识别（SER）、声音事件/场景分类（SEC/ASC）、TTS、语音转换（VC）、端到端语音对话。
- **开放**：代码、权重与配套评测工具包全部开源。

## 3. 核心机制

### 3.1. 输入到输出流水线

```text
音频理解 / ASR：输入音频 -> Whisper 系 audio tokenizer -> 离散语义 token a^d（12.5 Hz）+ Whisper continuous acoustic vector a^c（50 Hz 下采样到 12.5 Hz）-> token embedding 与连续特征融合 -> Audio LLM shared transformer -> text head -> 转写 / caption / QA / 分类结果。

语音生成 / 对话：系统 prompt + 历史 token + 用户音频 token -> Audio LLM shared transformer -> text head 生成文本 token，audio head 生成离散语义音频 token -> chunk-wise streaming detokenizer -> 50 Hz mel-spectrogram -> BigVGAN vocoder -> 输出语音波形。

实时部署：client audio stream -> VAD commit -> Tokenizer Service -> Scheduler 拼接新 token 与历史 -> LLM Service 生成 response tokens -> Detokenizer Service 分块回传音频 -> client 播放。
```

Kimi-Audio 的机制核心是「离散语义 token + 连续声学特征」混合输入：离散 token 让 LLM 容易做自回归建模，连续 Whisper 特征补足音色、情绪、环境声等副语言信息；输出侧则分成 text head 和 audio head，再用 flow-matching detokenizer 把 12.5 Hz 语义 token 变成可播放语音。

### 3.2. 核心公式

单段音频输入表示可记为离散与连续两路的组合：

$$
a_i=(a_i^{d},a_i^{c})
$$

预训练任务按哪些 token 接收 loss 来定义。ASR / audio-to-text 序列：

$$
S_{\mathrm{ASR}}=\{a_1,t_1,a_2,t_2,\ldots,a_N,t_N\},\quad
\mathcal{L}_{\mathrm{ASR}}=-\sum_i\log p_{\theta}(t_i\mid S_{<t_i})
$$

TTS / text-to-audio 序列：

$$
S_{\mathrm{TTS}}=\{t_1,a_1^d,t_2,a_2^d,\ldots,t_N,a_N^d\},\quad
\mathcal{L}_{\mathrm{TTS}}=-\sum_i\log p_{\theta}(a_i^d\mid S_{<a_i^d})
$$

audio-to-semantic interleaving：

$$
S_{\mathrm{A2S}}=\{a_1,a_2^d,a_3,a_4^d,\ldots,a_{N-1},a_N^d\}
$$

chunk-wise detokenizer 中，第 $i$ 个 chunk 的 mel $m_i$ 由当前语义 token、历史 chunk 和噪声反推得到：

$$
m_i\leftarrow\mathrm{FlowMatch}(a_i^d,\{c_j\}_{j<i},\epsilon)
$$

look-ahead 把下一 chunk 的前 $n$ 个语义 token 拼到当前 chunk 尾部，只保留当前 chunk 对应的 mel：

$$
\hat{c}_i=[c_i;\ a_{i+1,1:n}^{d}]
$$

### 3.3. 机制要点

- **输入不是纯 codec**：语义 token 提供可预测性，连续 acoustic vector 保留副语言和声学细节。
- **双 head 输出**：text head 负责文本结果，audio head 负责语音 token；共享底层 transformer 做跨模态融合。
- **训练靠任务序列组织**：text-only、audio-only、audio-to-text、text-to-audio、interleaving 用不同 loss token 组合桥接模态。
- **流式 detokenizer 降低延迟**：按 chunk 解码，look-ahead 用少量未来语义 token 修复 chunk 边界音质。

## 4. 发展脉络

属「一个底座吃所有音频任务」的通用 audio foundation model 线（对照 Qwen-Audio→Qwen2-Audio→[[方向/AI语音/模型/Qwen3-Omni|Qwen3-Omni]] 的理解侧）；其离散+连续双输入设计与本库 [[方向/AI语音/知识/技术路线/语音生成 tokenizer codec 技术路线|音频表示路线]] 的离散 vs 连续之争直接相关。

## 5. 边界

- 以理解与对话为主，语音生成（TTS/VC）为辅助能力，非其最强项。
- 官方 SOTA 数字基于其自建评测工具包口径，跨报告对比需谨慎（见 [[方向/AI语音/MOC - 音频大模型|MOC - 音频大模型]] 的评估碎片化问题）。
- 实时全双工不是目标场景。

## 6. 相关对象

- [[方向/AI语音/模型/Whisper|Whisper]]：audio tokenizer 的来源。
- [[方向/AI语音/模型/Qwen3-Omni|Qwen3-Omni]]：同路线的规模化全模态后继。
- [[方向/AI语音/模型/FireRedAudio]]：同属通用 audio foundation model，对照点是离散+连续双输入 vs 连续表示解耦。
- [[方向/AI语音/模型/UALM]] / [[方向/AI语音/模型/Audex]]：NVIDIA 统一音频理解、生成与推理模型线，对照 Kimi-Audio 的 7B 通用音频底座路线。
- [[方向/AI语音/评估/AudioBench（音频大模型通用基准）|AudioBench]] / [[方向/AI语音/评估/MMAU（大规模多任务音频理解与推理基准）|MMAU]]：此类模型的主要评测场。
- [[方向/AI语音/知识/基础概念/SSL 编码器|SSL 编码器]]：语义 token 蒸馏的背景。
- [[方向/AI语音/MOC - 音频大模型|MOC - 音频大模型]]：方向地图。

## 7. 来源

- [Kimi-Audio Technical Report（arXiv:2504.18425）](https://arxiv.org/abs/2504.18425)
  - 内容定位：技术报告，混合输入设计、13M 小时预训练、chunk-wise streaming detokenizer、任务覆盖与评测工具包。
  - 用途：架构与能力判断依据。
  - 核验日期：2026-09-01
- [MoonshotAI/Kimi-Audio（GitHub）](https://github.com/MoonshotAI/Kimi-Audio)
  - 内容定位：官方仓库，代码、权重与评测工具包。
  - 用途：复现与评测入口。
  - 核验日期：2026-09-01

## 8. 待验证

- 离散+连续双输入相对纯 codec token（Moshi 线）在下游任务的实证差异。
- 与 FireRedAudio、UALM、Audex 这类统一理解+生成模型在中文语音、长音频和 speech-to-speech 任务上的第三方复测差异。

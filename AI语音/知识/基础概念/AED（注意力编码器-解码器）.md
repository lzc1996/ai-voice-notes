---
title: AED（注意力编码器-解码器）
类型: 概念
aliases:
  - AED
  - Attention Encoder-Decoder
  - Attention-based Encoder-Decoder
  - attention decoder
  - 注意力编码器解码器
  - 注意力编码器-解码器
tags:
  - 方向/AI语音
  - 类型/对象
  - 任务/ASR
  - 主题/模型结构
  - 主题/端到端语音识别
---

# AED（注意力编码器-解码器）

## 1. 身份

`AED` 在 ASR 语境里通常指 **Attention Encoder-Decoder**：encoder 把声学帧编码成隐藏序列，decoder 在注意力机制帮助下自回归地产生文本 token。

边界：这里的 AED 是端到端语音识别架构，不是医学里的 defibrillator。它也不是 [[方向/AI语音/知识/基础概念/CTC（连接时序分类）|CTC]] 或 RNN-T；三者都是 speech-to-text 的建模/解码路线，但对齐假设和流式能力不同。

## 2. 核心机制

AED 的最小链路：

```text
waveform / fbank
  -> acoustic encoder
  -> attention over encoder states
  -> autoregressive text decoder
  -> token sequence / transcript
```

给定声学输入 $X$ 和文本 token 序列 $Y=(y_1,\ldots,y_U)$，AED 通常按条件概率分解：

$$
P(Y \mid X)=\prod_{u=1}^{U} P(y_u \mid y_{<u}, X)
$$

训练目标通常是 [[方向/大模型/训练/Teacher Forcing（教师强制）|teacher forcing]] 下的 token 级交叉熵：

$$
\mathcal{L}_{\mathrm{AED}}=-\sum_{u=1}^{U}\log P(y_u \mid y_{<u}, X)
$$

### 执行拓扑

- 编码器：对输入帧可并行计算。
- 解码器：按 token 自回归串行生成：
  其中 $h$ 为编码器输出，$y_u$ 为第 $u$ 个输出 token，$y_{<u}$ 为此前已生成的 token 序列，$f$ 为解码器条件生成函数。
  $$
  y_u = f(y_{<u}, h),\quad u=1,\ldots,U
  $$
- 整体：`encoder` 与 `decoder` 是串行阶段；不能把 encoder 的并行计算等同于端到端并行解码。

## 3. 和 CTC / RNN-T 的差别

- **[[方向/AI语音/知识/基础概念/CTC（连接时序分类）|CTC]]**：每帧独立预测标签/blank，再通过 collapse 规则对齐到文本；训练和解码较简单，但条件独立假设较强。
- **AED**：decoder 显式依赖历史输出 $y_{<u}$，语言建模能力更强，但自回归解码更慢，也更难天然流式。
- **RNN-T / Transducer**：把声学帧和历史 token 联合建模，常用于流式 ASR。
- **Hybrid CTC/AED**：训练时同时用 CTC 和 AED，CTC 提供单调对齐约束，AED 提供序列级条件生成能力。

## 4. 为什么在语音里重要

- **ASR decoder 入口**：很多语音系统会在 encoder 后接 CTC / AED / Transducer / LLM decoder，不同 decoder 决定输出方式和延迟约束。
- **语义 tokenizer 脚手架**：S3 / CosyVoice 式 semantic tokenizer 可用 ASR 后段和 CTC/AED decoder 提供文本监督，训练后只保留前段表示和量化器。
- **非流式更自然**：AED 的全局 attention 对离线识别友好；严格低延迟场景通常要改成 chunk/causal 形式，或改用 Transducer/CTC 路线。
- **容易混入 LM 能力**：AED decoder 会学习输出 token 的历史依赖，因此评估时要区分声学 encoder 能力和 decoder/语言模型贡献。

## 5. 常见误读

- **不是所有 encoder-decoder 都叫 AED**：关键是 decoder 对 encoder states 做 attention，并按历史 token 自回归生成。
- **不是一定优于 CTC**：AED 更灵活，但流式、稳定对齐和解码成本不一定占优。
- **不是 speech tokenizer 本身**：在 semantic tokenizer 训练里，AED decoder 可能只是监督脚手架，最终 token 由 encoder 中间层量化得到。

## 6. 相关对象

- [[方向/AI语音/MOC - ASR]]：ASR 方向入口。
- [[方向/AI语音/知识/基础概念/CTC（连接时序分类）]]：AED 的常见对照和 hybrid 搭档。
- [[方向/AI语音/知识/技术路线/语音网络结构与模块]]：AED 位于 ASR decoder 选择层。
- [[方向/AI语音/知识/技术路线/LLM-SE Stage 0（表示空间准备）]]：ASR 监督 semantic tokenizer 中提到 CTC / AED decoder。
- [[方向/AI语音/知识/基础概念/Streaming Conformer]]：流式 ASR encoder，常与 CTC / RNN-T 等 decoder 组合。
- [[方向/AI语音/模型/Whisper]]：encoder-decoder ASR 代表模型之一。
- [[方向/AI语音/模型/FunASR]]：工程化 ASR 链路，常见 CTC / AED 混合训练表述。

## 7. 关键来源

- [Listen, Attend and Spell](https://arxiv.org/abs/1508.01211)
  - 内容定位：端到端 attention-based encoder-decoder ASR 代表论文。
  - 用途：AED 的基本形式和 ASR 语境来源。
  - 核验日期：2026-09-04
- [Hybrid CTC/Attention Architecture for End-to-End Speech Recognition](https://arxiv.org/abs/1706.02737)
  - 内容定位：把 CTC 与 attention encoder-decoder 结合，用 CTC 辅助对齐和解码。
  - 用途：理解 CTC/AED hybrid 的常见 ASR recipe。
  - 核验日期：2026-09-04

## 8. 待验证

- vault 内是否需要单独拆出 `RNN-T`、`Transducer` 概念页。
- 当前 AI 语音笔记里 `AED decoder` 是否都指 ASR attention decoder，而不是普通 encoder-decoder。

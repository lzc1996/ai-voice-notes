---
title: CTC（连接时序分类）
类型: 概念
aliases:
  - CTC
  - CTC Loss
  - Connectionist Temporal Classification
  - 连接时序分类
  - 连接主义时序分类
  - CTC 损失
tags:
  - 方向/AI语音
  - 类型/对象
  - 任务/ASR
  - 主题/端到端语音识别
  - 主题/对齐
---

# CTC（连接时序分类）

## 1. 身份

`CTC`（Connectionist Temporal Classification，连接时序分类）是一种用于未切分序列标注的训练目标。在 ASR 里，它让模型只需要音频和转写文本，不需要逐帧对齐标签。

边界：CTC 更准确地说是**对齐假设 + 损失函数 / 解码方式**，不是完整 ASR 模型。它通常接在 acoustic encoder 后面；encoder 可以是 CNN、LSTM、Transformer、Conformer 或 Whisper-like encoder。

## 2. 核心机制

CTC 的最小链路：

```text
waveform / fbank
  -> acoustic encoder
  -> frame-level logits over vocab + blank
  -> CTC path marginalization
  -> collapsed token sequence / transcript
```

CTC 会在输出词表里加入一个特殊的 blank 符号。模型每一帧预测一个 token 或 blank，再用 collapse 规则把帧级路径变成文本：先合并连续重复 token，再删除 blank。

```text
路径:   _ h _ e _ l _ l _ o _
collapse -> h e l l o
```

实际例子里重复字符需要用 blank 分开，例如 `hello` 里的两个 `l` 不能直接由连续 `l l` 表示，否则会被合并。

## 3. 公式

给定声学输入 $X$、目标文本 token 序列 $Y$、帧级路径 $\pi$，CTC 对所有能 collapse 到 $Y$ 的路径求和：

$$
P(Y \mid X)=\sum_{\pi \in \mathcal{B}^{-1}(Y)}\prod_{t=1}^{T}P(\pi_t \mid X)
$$

训练损失是负对数似然：

$$
\mathcal{L}_{\mathrm{CTC}}=-\log P(Y \mid X)
$$

其中 $\mathcal{B}$ 是 collapse 映射，$T$ 是 encoder 输出帧数。工程上通常用动态规划计算这个求和，不枚举全部路径。

## 4. 和 AED / RNN-T 的差别

- **CTC**：帧级条件独立，假设输出顺序和音频时间大体单调；训练简单，适合对齐和流式友好场景。
- **AED**：decoder 自回归地产生文本 token，并通过 attention 读取 encoder states；语言建模能力更强，但解码更慢，天然流式性更弱。
- **RNN-T / Transducer**：同时建模声学时间步和历史输出 token，常用于低延迟流式 ASR。
- **Hybrid CTC/AED**：CTC 提供单调对齐约束，AED 提供条件生成能力，是很多端到端 ASR recipe 的折中。

## 5. 为什么语音里常用

- **不需要帧级标注**：只有音频和 transcript 就能训练。
- **对齐能力强**：CTC 路径天然给出帧到 token 的粗对齐，适合 forced alignment、时间戳和长音频切分辅助。
- **解码简单**：greedy / beam search 都能用，也容易接外部语言模型。
- **适合脚手架监督**：semantic tokenizer 训练里，CTC 可以和 AED 一起作为 ASR 后段监督，训练完后段可丢弃。

## 6. 常见误读

- **不是逐帧分类就完了**：关键是对所有合法对齐路径求和，而不是硬指定某一帧对应哪个字。
- **blank 不是空格**：blank 是对齐占位符，删除后不出现在最终文本里。
- **CTC 不擅长强语言建模**：它的帧级条件独立假设弱化了 token 历史依赖，通常需要 beam search 或外部 LM 补足。
- **不是所有 ASR 都适合只用 CTC**：长上下文、复杂标点、热词、代码切换和强语义纠错场景可能需要 AED、RNN-T 或 LLM decoder。

## 7. 相关对象

- [[方向/AI语音/MOC - ASR]]：ASR 方向入口。
- [[方向/AI语音/知识/基础概念/AED（注意力编码器-解码器）]]：CTC 的常见对照和 hybrid 搭档。
- [[方向/AI语音/知识/技术路线/语音网络结构与模块]]：CTC 位于 ASR decoder / training objective 选择层。
- [[方向/AI语音/知识/技术路线/LLM-SE Stage 0（表示空间准备）]]：semantic tokenizer 中提到 CTC / AED decoder 作为文本监督脚手架。
- [[方向/AI语音/知识/基础概念/Streaming Conformer]]：流式 ASR encoder 常接 CTC 或 RNN-T。
- [[方向/AI语音/模型/FunASR]]、[[方向/AI语音/模型/Emformer]]：vault 中含 CTC 或 RNN-T 训练目标的 ASR 模型页。

## 8. 关键来源

- [Connectionist Temporal Classification: Labelling Unsegmented Sequence Data with Recurrent Neural Networks](https://www.cs.toronto.edu/~graves/icml_2006.pdf)
  - 内容定位：CTC 原论文，提出面向未切分序列标注的路径求和训练目标。
  - 用途：定义、blank/collapse、动态规划目标来源。
  - 核验日期：2026-09-04
- [Distill - Sequence Modeling With CTC](https://distill.pub/2017/ctc/)
  - 内容定位：CTC 的直观解释、alignment、blank、解码方式。
  - 用途：辅助理解 CTC 和 ASR 解码直觉。
  - 核验日期：2026-09-04
- [Hybrid CTC/Attention Architecture for End-to-End Speech Recognition](https://arxiv.org/abs/1706.02737)
  - 内容定位：CTC 与 attention encoder-decoder 的混合 ASR 架构。
  - 用途：理解 CTC/AED hybrid 的角色分工。
  - 核验日期：2026-09-04

## 9. 待验证

- 是否单独拆出 `RNN-T（循环神经网络转导器）` / `Transducer` 概念页。
- 当前 ASR 选型页是否需要把 CTC、AED、RNN-T、LLM decoder 做成一张 decoder 路线对比表。

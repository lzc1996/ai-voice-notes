---
title: Conv Position Embedding（卷积位置嵌入）
类型: 概念
发表时间: 2020-06-20
时间依据: wav2vec 2.0 论文 arXiv v1 首次提交日（2020-06-20），该设计由此进入语音表征主流
相关任务:
  - TTS
相关模型:
  - "[[方向/AI语音/模型/AuK]]"
aliases:
  - 卷积位置嵌入
  - Convolutional Positional Embedding
  - ConvPositionEmbedding
tags:
  - 类型/对象
  - 方向/AI语音
  - 任务/TTS
---

# Conv Position Embedding（卷积位置嵌入）

## 1. 身份

`Conv Position Embedding`（卷积位置嵌入）是给 Transformer 输入注入位置信息的一种设计：不加正弦或可学习位置向量，而是**在 token 序列的时间维上直接跑一个一维卷积，残差加回原序列**。最早由 wav2vec 2.0 用于语音表征，后被 F5-TTS 搬进扩散式 TTS 的 DiT 输入端，[[方向/AI语音/模型/AuK|AuK]] 声学流沿用同一设计。

## 2. 核心机制

$$\tilde{\mathbf{x}}_i = \mathbf{x}_i + \mathrm{GELU}\big(\mathrm{Conv1D}(\mathbf{x})_i\big)$$

wav2vec 2.0 / F5-TTS 的实现口径：沿时间维的宽核卷积（kernel 128、分组 16）+ GELU，残差加回。效果是每帧表示混入其前后各几十帧的上下文——token 自带局部时序结构，而不只是绝对下标。

## 3. 为什么适合音频序列

- **音频帧局部平滑**：相邻 mel/latent 帧强相关，「我在一个平稳片段的中间」比「我是绝对第 317 帧」信息量更大；宽核卷积让每帧感知自身局部相位与邻域结构，对语音对齐、时长控制、边界平滑直接有用。
- **平移等变 = 相对位置**：卷积不看绝对下标，天然给出相对位置偏置；参数仅一个卷积层，还顺带做一次轻量局部特征混合。

## 4. 与 RoPE 的分工

两者叠加而非二选一：

- **Conv Position Embedding**：作用于**输入端**，回答「每个 token 周围长什么样」；
- **RoPE**：作用于**注意力内部**的 query/key，回答「token 互相看对方时怎么算距离」。

AuK 中的实例：声学流的输入映射 $\mathcal{P}_{\mathrm{ref}}$、$\mathcal{P}_{\mathrm{tgt}}$ 各为「卷积位置嵌入 + 线性投影」，注意力内用 RoPE；语义流（MLLM hidden states）只做 linear + RMSNorm——LLM 表示已充分上下文化，不需要再补局部时序，需要补的是原始声学 latent。

## 5. 血缘链

wav2vec 2.0（2020，自监督语音表征首次用其注入位置）-> F5-TTS（2024，扩散式 TTS 的 DiT 输入端）-> AuK（2026，声学流两个输入映射原样继承）。

## 6. 关键来源

- [wav2vec 2.0: A Framework for Self-Supervised Learning of Speech Representations（arXiv:2006.11477）](https://arxiv.org/abs/2006.11477)
  - 内容定位：卷积位置嵌入的出处（feature encoder 之后的 positional conv embedding，kernel 128、groups 16）。
  - 用途：概念源头与实现口径锚点。
  - 核验日期：2026-09-15
- [F5-TTS: A Fairytaler that Fakes Fluent and Faithful Speech with Flow Matching（arXiv:2410.06885）](https://arxiv.org/abs/2410.06885)
  - 内容定位：把 ConvPositionEmbedding 用于 DiT 输入端的 TTS 实例。
  - 用途：AuK 所引用「F5-TTS 设计」的直接来源。
  - 核验日期：2026-09-15
- [AuK Technical Report（arXiv:2609.08936）](https://arxiv.org/abs/2609.08936)
  - 内容定位：§3.4 Condition Mapping 与 §4.2 明确声学流沿用 F5-TTS 的 RoPE + 卷积位置嵌入设计。
  - 用途：本页 §4 实例的一手出处。
  - 核验日期：2026-09-15

## 7. 待验证

- AuK 中卷积核宽度、分组数等超参（论文未展开，需看代码确认是否与 F5-TTS 一致）。
- F5-TTS 官方实现中该模块对 mel 输入的具体接入位置（与文本 embedding 拼接前后的顺序）。

---
title: RVQ（残差向量量化）
类型: 概念
发表时间: 2021-07-07
时间依据: SoundStream arXiv v1 提交日；RVQ 作为神经音频 codec 代表性入口
相关主题:
  - 语音表示
  - 语音生成
  - 音频压缩
aliases:
  - Residual Vector Quantization
  - residual vector quantization
  - 残差向量量化
  - 残差 VQ
  - RVQ
tags:
  - 类型/对象
  - 方向/AI语音
  - 主题/语音表示
  - 主题/音频压缩
---

# RVQ（残差向量量化）

## 1. 身份

`RVQ` 是 **Residual Vector Quantization，残差向量量化**：用多级码本逐层量化同一个连续向量。第一层先近似原向量，后续每一层只量化上一层没解释掉的 residual；最终表示是多层码本向量的和。

边界：RVQ 是量化方法，不是完整 codec。神经音频 codec 还需要 encoder、decoder / [[方向/AI语音/知识/基础概念/Vocoder（声码器）|vocoder]]、重建损失、对抗损失和流式设计。

## 2. 最小公式

设 encoder 输出连续向量 $z$，第 $k$ 个码本为 $C_k$：

$$
r_0=z,
\qquad i_k=\arg\min_i \|r_{k-1}-C_k[i]\|_2^2,
\qquad q_k=C_k[i_k],
\qquad r_k=r_{k-1}-q_k
$$

最终量化向量为：

$$
\hat z=\sum_{k=1}^{K} q_k
$$

直觉：每个码本都在“补上一层留下的误差”。层数 $K$ 越多，重建细节越多，但每帧 token 数、码率和生成成本也更高。

## 3. token 和码率口径

RVQ 的一个音频帧通常不是一个 token，而是一组 codebook indices：

```text
frame_t -> [i_1, i_2, ..., i_K]
```

如果帧率为 $F$ Hz、RVQ 层数为 $K$、每层码本大小为 $N$，未做熵编码时的粗略码率是：

$$
\mathrm{bitrate} \approx F \times K \times \log_2 N
$$

例：$50$ Hz、$8$ 个 codebook、每层 $1024=2^{10}$ 个 entries，大约是 $50\times 8\times 10=4000$ bps，即 4 kbps。对 LLM 来说，更关键的是**每秒要建模多少 token**：$50$ Hz × $8$ codebooks 往往比 $50$ Hz × $1$ codebook 难很多。

## 4. 在语音模型里的作用

- **压缩音频表示**：把连续 latent 变成离散 codebook indices，方便存储、传输或给 LM 预测。
- **控制码率**：通过 RVQ 层数、码本大小、帧率共同决定 bitrate。
- **服务 codec LM**：上层模型可预测一层或多层 codec token，再由 decoder 还原 waveform。
- **分层细节**：前几层通常承载更粗的声学结构，后几层补细节；实际语义分工取决于训练目标和模型结构。

## 5. 常见坑

- **RVQ 层数不是越多越好**：重建质量提升会换来更长 token 流和更慢自回归生成。
- **token rate 要和 codebook 数一起看**：`50 Hz × 8 codebooks` 和 `50 Hz × 1 codebook` 对 LM 是完全不同的长度/复杂度。
- **不是所有 speech tokenizer 都用 RVQ**：例如单层 VQ、[[方向/AI语音/知识/基础概念/FSQ（有限标量量化）|FSQ]]、semantic token、continuous VAE latent 都是不同路线。
- **codec 上限锁下游**：RVQ 重建损失、码本塌缩或 decoder 伪影会限制 TTS、voice cloning 和语音增强上限。

## 6. 和 VQScore 的关系

RVQ 和 [[方向/AI语音/评估/VQScore（语音质量评分）]] 都用到 vector quantization，但问题不同：

- **RVQ**：把连续音频 latent 压成多层离散 token，目标是压缩和可重建。
- **VQScore**：利用量化误差 / 相似度估计语音质量，目标是评估或筛数据。

一句话：RVQ 是“把音频变成 token”的 codec 组件；VQScore 是“看一段语音像不像高质量 clean speech”的评分工具。

## 7. 关键来源

- [SoundStream: An End-to-End Neural Audio Codec](https://arxiv.org/abs/2107.03312)
  - 内容定位：端到端神经音频 codec 论文，使用 residual vector quantization 做低码率音频压缩。
  - 用途：RVQ 在神经音频 codec 中的代表入口。
  - 发表日期：2021-07-07（arXiv v1）
  - 核验日期：2026-08-11
- [High Fidelity Neural Audio Compression](https://arxiv.org/abs/2210.13438)
  - 内容定位：EnCodec 论文，记录高保真 neural audio compression 和多码本离散表示。
  - 用途：理解 RVQ / 多码本 codec 在高保真音频压缩中的工程口径。
  - 发表日期：2022-10-24（arXiv v1）
  - 核验日期：2026-08-11
- [High-Fidelity Audio Compression with Improved RVQGAN](https://arxiv.org/abs/2306.06546)
  - 内容定位：DAC 论文，记录高保真神经音频 codec 和开源实现路线。
  - 用途：对照 RVQ / codec decoder 质量对生成模型上限的影响。
  - 发表日期：2023-06-11（arXiv v1；NeurIPS 2023）
  - 核验日期：2026-08-11

## 8. 相关对象

- [[方向/AI语音/知识/基础概念/NAC（神经音频 Codec）]]：RVQ 是 neural audio codec 的常见离散量化方式。
- [[方向/AI语音/知识/基础概念/FSQ（有限标量量化）]]：FSQ 是 RVQ 的主要对照量化路线。
- [[方向/AI语音/知识/技术路线/语音生成 tokenizer codec 技术路线]]：RVQ 属于离散 codec token 路线。
- [[方向/AI语音/知识/技术路线/语音模型 tokenizer 与 LLM tokenizer 对比]]：区分 audio tokenizer / codec token 和文本 tokenizer。
- [[方向/AI语音/模型/X-Codec2]]：对照单层大码本 / FSQ 路线，和多层 RVQ 不同。
- [[方向/AI语音/模型/ZONOS2]]：使用 RVQ / DAC audio token 作为 TTS 输出表示。
- [[方向/AI语音/评估/VQScore（语音质量评分）]]：同样用到 VQ 思想，但用途是质量估计，不是 codec tokenization。

## 9. 待验证

- 当前常用 TTS / codec LM 中，RVQ 各层是否稳定呈现“粗到细”的可解释分工。
- 中文 voice cloning 中，RVQ 层数、帧率和 speaker similarity 的实际 trade-off。
- 多层 RVQ、FSQ、单层大码本和 continuous latent 在同一小样本上的重建、延迟和生成稳定性差异。

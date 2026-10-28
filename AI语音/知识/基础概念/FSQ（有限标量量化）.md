---
title: FSQ（有限标量量化）
类型: 概念
发表时间: 2023-09-27
时间依据: Finite Scalar Quantization arXiv v1 提交日
相关主题:
  - 语音表示
  - 语音生成
  - 音频压缩
aliases:
  - Finite Scalar Quantization
  - finite scalar quantization
  - Feature Scalar Quantization
  - 标量量化
  - 有限标量量化
  - FSQ
tags:
  - 类型/对象
  - 方向/AI语音
  - 主题/语音表示
  - 主题/音频压缩
---

# FSQ（有限标量量化）

## 1. 身份

`FSQ` 通常指 **Finite Scalar Quantization，有限标量量化**：把连续 latent 的少数维度分别量化到有限个固定标量 level，再把各维 level 组合成一个隐式 codebook index。

边界：FSQ 是量化器，不是完整 codec / tokenizer。它解决的是连续表示如何离散化；encoder、decoder / [[方向/AI语音/知识/基础概念/Vocoder（声码器）|vocoder]]、训练目标、帧率和下游 LM 建模方式仍由具体系统决定。

## 2. 最小公式

设 encoder 输出低维 latent $z \in \mathbb{R}^d$，第 $i$ 维有 $L_i$ 个离散 level：

$$
q_i = \mathrm{round}(\mathrm{bound}(z_i)),
\qquad |\mathcal{C}| = \prod_{i=1}^{d} L_i
$$

量化后的向量 $q=(q_1,\dots,q_d)$ 可以映射成一个离散 index $c$。直觉：FSQ 不学习一个显式向量码本，而是用每个维度的有限标量网格组成隐式码本。

## 3. 和 RVQ / VQ 的区别

- **VQ**：学习一个显式向量码本，连续向量查最近邻 codeword。
- **RVQ**：多层 VQ 逐层量化 residual，每帧通常产生多个 codebook index。
- **FSQ**：逐维标量离散化，隐式码本大小由各维 level 的乘积决定；通常更容易获得高 codebook utilization。

一句话：RVQ 更像“多层补误差”，FSQ 更像“把低维连续坐标卡到固定网格”。

## 4. 在语音模型里的作用

- **speech tokenizer**：CosyVoice 2 在 supervised semantic speech tokenizer 中引入 FSQ，提高 speech token 的 codebook utilization。
- **low-bitrate codec**：X-Codec2 的 Transformers 文档把实现口径描述为 single-stage Feature Scalar Quantization，用单层 token 适配 causal autoregressive LLM。
- **解耦 token**：BiCodec 的 global tokenizer 使用 FSQ 表示全局说话人 / 风格属性。
- **对照路径**：在 audio LLM 里，FSQ 常和 [[方向/AI语音/知识/基础概念/RVQ（残差向量量化）|RVQ]]、单层 VQ、semantic token、continuous latent 一起比较 token 率、码本利用率和重建质量。

## 5. 常见坑

- **FSQ 不等于语义 token**：是否去掉 speaker / channel / emotion 信息，主要取决于监督目标和训练数据，不是量化器自动保证。
- **单层不等于低延迟**：token 帧率、decoder RTF、chunk 边界和 vocoder 才决定真实流式体验。
- **大隐式码本仍有建模成本**：level 组合越多，离散空间越大；下游 Transformer 的压缩/预测成本仍要实测。
- **术语口径要分清**：原始方法名是 Finite Scalar Quantization；X-Codec2 Transformers 文档使用 Feature Scalar Quantization 这个实现口径，实际阅读时要回到具体代码和配置。

## 6. 关键来源

- [Finite Scalar Quantization: VQ-VAE Made Simple](https://arxiv.org/abs/2309.15505)
  - 内容定位：FSQ 原始论文，提出用有限标量量化替代 VQ-VAE 中的 learned vector quantizer。
  - 用途：确认 FSQ 的基础定义、隐式码本和 codebook utilization 口径。
  - 发表日期：2023-09-27（arXiv v1）
  - 核验日期：2026-09-07
- [CosyVoice 2: Scalable Streaming Speech Synthesis with Large Language Models](https://arxiv.org/abs/2412.10117)
  - 内容定位：CosyVoice 2 把 FSQ 插入 supervised semantic speech tokenizer，并报告 codebook utilization / ASR 相关消融。
  - 用途：确认 FSQ 在 TTS semantic tokenizer 中的应用。
  - 发表日期：2024-12-13（arXiv v1）
  - 核验日期：2026-09-07
- [X-Codec2 - Hugging Face Transformers docs](https://huggingface.co/docs/transformers/main/model_doc/xcodec2)
  - 内容定位：Transformers 文档称 X-Codec2 使用 single-stage Feature Scalar Quantization（FSQ），区别于多层 residual VQ。
  - 用途：确认 X-Codec2 / LLaSA 路线里的 FSQ 口径。
  - 核验日期：2026-09-07

## 7. 相关对象

- [[方向/AI语音/知识/基础概念/RVQ（残差向量量化）]]：FSQ 的主要对照量化路线。
- [[方向/AI语音/知识/基础概念/NAC（神经音频 Codec）]]：FSQ 可作为 neural audio codec / tokenizer 的离散量化组件。
- [[方向/AI语音/模型/X-Codec2]]：单层 FSQ / 50 tokens/s speech codec 代表。
- [[方向/AI语音/模型/CosyVoice]]：CosyVoice 2 使用 FSQ tokenizer 改善 speech token 利用率。
- [[方向/AI语音/模型/BiCodec]]：global tokenizer 使用 FSQ 表示全局属性。
- [[方向/AI语音/知识/技术路线/语音生成 tokenizer codec 技术路线]]：FSQ 属于离散 tokenizer / codec 技术路线的对照项。

## 8. 待验证

- X-Codec2 的 “Feature Scalar Quantization” 和原始 FSQ 在代码配置上的精确对应关系。
- FSQ 在中文长文本 TTS、voice cloning 和强情绪样本上的 speaker leakage / prosody leakage 边界。
- FSQ、RVQ、单层 VQ、continuous latent 在同一语音样本上的 token 率、码率、重建质量和下游 LM 训练稳定性。

---
title: FiLM（特征级线性调制）
类型: 概念
发表时间: 2017-09-22
时间依据: arXiv v1 首次提交日；AAAI 2018 论文集版本
aliases:
  - FiLM
  - Feature-wise Linear Modulation
  - Feature-wise affine transformation
  - 特征级线性调制
  - 条件线性调制
  - 特征级仿射调制
tags:
  - 类型/对象
  - 方向/AI语音
  - 主题/条件注入
  - 主题/模型结构
---

# FiLM（特征级线性调制）

## 1. 身份

`FiLM`（Feature-wise Linear Modulation）是一种轻量条件注入层：用条件向量生成每个 feature / channel 的缩放系数和偏置，再对中间特征做逐维仿射变换。原论文用于视觉推理，但在语音模型里常被拿来注入 speaker embedding、task embedding、reasoning token、退化条件或高层语义条件。

边界：FiLM 不是 attention，也不是 tokenizer。它不把条件变成长序列参与交互，而是把条件压成 $\gamma,\beta$ 后广播到特征维度；因此成本低、稳定，但表达能力弱于 cross-attention。

## 2. 核心机制

### 2.1. 输入到输出链路

```text
condition c -> FiLM generator -> gamma(c), beta(c)
hidden feature h -> backbone block / encoder / decoder
gamma(c), beta(c) + h -> feature-wise affine modulation -> conditioned hidden feature h' -> downstream module

AI speech examples:
speaker embedding -> FiLM -> speech enhancement / target speaker extraction backbone
reasoning token / semantic condition -> FiLM -> reconstruction encoder / flow decoder
degradation embedding -> FiLM -> denoising or restoration decoder
```

### 2.2. 关键公式

最小形式：

$$
\mathrm{FiLM}(h;c)=\gamma(c)\odot h+\beta(c)
$$

对时序语音特征常按 channel 广播：

$$
h'_{t,k}=\gamma_k(c)h_{t,k}+\beta_k(c),\quad t=1,\ldots,T
$$

条件生成器：

$$
[\gamma(c),\beta(c)]=g_{\phi}(c)
$$

为了避免初始训练破坏主干，常用 residual scale 写法：

$$
h'=(1+\Delta\gamma(c))\odot h+\beta(c)
$$

放在归一化后时，FiLM 和 conditional normalization / AdaLN 的关系很近：

$$
h'=\gamma(c)\odot \mathrm{Norm}(h)+\beta(c)
$$

### 执行拓扑

- 条件分支与主干特征提取可分别计算，随后在调制点汇合：
  其中 $c$ 为条件，$g_\phi$ 为条件生成器，$\gamma,\beta$ 为调制参数，$h$ 为主干特征，$h'$ 为调制后的特征。
  $$
  c \xrightarrow{g_\phi} (\gamma,\beta),\qquad
  h' = \gamma\odot h+\beta
  $$
- FiLM 本身是一个并行条件注入算子，不等于额外的串行生成阶段。
- 若多个 block 重复注入，应写成迭代堆叠：其中 $h^{(l)}$ 为第 $l$ 个 block 的输入，$F_l$ 为该 block，$L$ 为 block 总数。
  $$
  h^{(l+1)}=F_l(h^{(l)},c),\quad l=0,\ldots,L-1
  $$

### 2.3. 机制要点

- **条件是低维控制量**：适合 speaker、style、task、degradation、reasoning summary 这类全局或低帧率条件。
- **不会增加 token 长度**：相比 concat / prefix / cross-attention，FiLM 不增加 LLM 或 Transformer 的序列长度。
- **调的是通道重要性**：$\gamma$ 像门控，$\beta$ 像条件偏移；两者一起改变中间特征的计算路径。
- **不适合承载细粒度证据**：如果条件本身是长音频证据、逐帧对齐信息或多段文本，通常应先用 attention / pooling / Q-Former 压缩，再决定是否 FiLM 注入。

## 3. 使用判断

- 用于**说话人条件**：speaker enrollment / SV embedding 已经压成向量时，FiLM 是比直接拼接更干净的注入方式。
- 用于**语义回注**：如 [[方向/AI语音/模型/UniAudio 2.0|UniAudio 2.0]] 把 reasoning 信息回注到 reconstruction 特征，避免重建分支只看低层声学。
- 用于**SE / restoration 条件控制**：退化类型、SNR、RT60、任务标签等低维条件可用 FiLM 调制 decoder 或 DiT block。
- 不用于**高带宽证据传输**：长音频 hidden、逐帧 mel/STFT evidence、完整 prompt 更适合 cross-attention、adapter 或显式序列建模。

## 4. 相关对象

- [[方向/AI语音/模型/UniAudio 2.0|UniAudio 2.0]]：ReasoningCodec 中用 FiLM 把 reasoning 信息注入 reconstruction 特征。
- [[方向/AI语音/评估/ECHI（助听对话增强）|ECHI（助听对话增强）]]：官方 TF-GridNet 基线用 FiLM 注入注册式 TSE 的说话人嵌入。
- [[方向/AI语音/知识/技术路线/LLM-SE Training Recipe v2（显式解耦训练配方）]]：speaker embedding / degradation condition 的候选注入方式。
- [[方向/AI语音/选型/LLM-SE 架构选型调研（统一音频模型对比）]]：把 FiLM 作为语义回注和 speaker 条件方式对比。
- [[方向/大模型/模型结构/AdaLN-Zero]]：归一化后条件缩放/偏置路线的相邻机制。
- [[方向/大模型/模型结构/DiT（Diffusion Transformer）]]：扩散/flow 语音生成中常见的条件注入载体。

## 5. 来源

- [FiLM: Visual Reasoning with a General Conditioning Layer](https://arxiv.org/abs/1709.07871)
  - 内容定位：FiLM 原始论文，提出 feature-wise affine transformation based on conditioning information。
  - 用途：确认概念定义、公式和发表时间。
  - 发表日期：2017-09-22（arXiv v1）
  - 核验日期：2026-09-02
- [FiLM: Visual Reasoning with a General Conditioning Layer（AAAI）](https://ojs.aaai.org/index.php/AAAI/article/view/11671)
  - 内容定位：AAAI 2018 论文集版本。
  - 用途：确认会议版本与正式论文入口。
  - 核验日期：2026-09-02
- [Feature-wise transformations（Distill）](https://distill.pub/2018/feature-wise-transformations/)
  - 内容定位：Distill 对 feature-wise transformation 家族的解释，说明 FiLM 与 conditional biasing / scaling / normalization 的关系。
  - 用途：建立 FiLM、conditional normalization、AdaLN、speaker/style conditioning 的概念边界。
  - 核验日期：2026-09-02

## 6. 待验证

- 在 LLM-SE 中，speaker embedding 用 FiLM、prefix 还是 cross-attention 的消融差异。
- FiLM 注入退化条件时是否会让模型过拟合仿真噪声元数据。
- UniAudio 2.0 的 FiLM 回注细节是否值得单独拆到 ReasoningCodec 机制页。

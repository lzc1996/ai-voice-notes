---
title: Masked Generative Modeling（掩码生成建模）
类型: 方法
发表时间:
时间依据: 通用生成建模范式；文本、图像、音频和语音模型均有不同实现
相关任务:
  - 语音生成
  - 语音恢复
  - 语音增强
  - zero-shot TTS
  - audio editing
相关主题:
  - masked modeling
  - iterative refinement
  - discrete token
  - parallel generation
aliases:
  - 掩码生成建模
  - 掩码式生成建模
  - Masked Generative Model
  - masked generation
  - mask-and-predict
  - masked acoustic modeling
  - masked codec modeling
tags:
  - 类型/对象
  - 方向/AI语音
  - 主题/生成建模
  - 主题/masked-modeling
  - 主题/音频表示
---

# Masked Generative Modeling（掩码生成建模）

## 1. 身份

`Masked Generative Modeling`（掩码生成建模，MGM）是一类“先遮住一部分目标，再根据可见上下文生成被遮部分”的生成范式。它不限定输入一定是文本：被预测的对象可以是文本 token、图像 patch、语音 codec token、声学 token 或连续 latent。

在 AI 语音里，MGM 常把语音生成 / 恢复从严格的左到右自回归，改成**并行或半并行的补全与迭代细化**。代表对象包括 [[方向/AI语音/模型/MaskGCT]]、[[方向/AI语音/模型/MaskSR]]、[[方向/AI语音/模型/MaskSR2]] 和 [[方向/AI语音/模型/AnyEnhance]]。

## 2. 核心机制

```text
clean target tokens / corrupted audio + condition
  -> random mask or corruption
  -> bidirectional model predicts masked tokens
  -> confidence-based remasking / iterative refinement
  -> codec or vocoder decoder
  -> waveform / generated output
```

设目标 token 序列为 $x=(x_1,\dots,x_n)$，随机掩码位置集合为 $M$，可见位置记为 $x_{\mathrm{vis}}$，典型训练目标可写成：

$$
\mathcal{L}_{\mathrm{MGM}}
=-\mathbb{E}_{x,M}\sum_{i\in M}
\log p_\theta(x_i\mid x_{\mathrm{vis}}, c)
$$

其中 $c$ 可以是文本、参考语音、退化语音、任务 prompt、speaker condition 或其他上下文。推理时通常从全掩码或高比例掩码开始，预测一轮后保留高置信 token，再重新 mask 低置信位置，重复若干轮。

### 执行拓扑

- 单轮预测：被掩码位置可并行预测：
  其中 $M$ 为当前掩码位置集合，$x_{\mathrm{vis}}$ 为可见 token，$c$ 为条件，$f_i$ 为位置 $i$ 的预测函数。
  $$
  \hat{x}_M = \{f_i(x_{\mathrm{vis}},c)\}_{i\in M}
  $$
- 多轮细化：轮次之间串行、轮内位置并行：
  其中 $x^{(k)}$ 为第 $k$ 轮的完整 token 状态，$R$ 为一次重掩码与补全操作，$K$ 为总轮数。
  $$
  x^{(k+1)} = R\!\left(x^{(k)},c\right),\quad k=0,\ldots,K-1
  $$
- 因此，`parallel generation` 只描述轮内并行，不代表端到端一次前向。

## 3. 在语音里的两种主要形态

- **生成型 MGM**：输入文本 / 参考语音，预测完整的 semantic token 或 acoustic token 序列，适合 TTS、voice cloning、音频编辑。
- **恢复型 MGM**：输入带噪、带混响、削波或低带宽语音，预测 clean target token，适合 speech restoration、denoising、bandwidth extension 和 declipping。

两者都使用“补全缺失 token”的形式，但条件不同：生成型主要从文本和参考条件产生目标序列；恢复型必须受到退化观测约束，不能把“听起来更自然”误当成“恢复了原内容”。

## 4. 和相邻方法的区别

| 概念 | 主要机制 | 和 MGM 的边界 |
|---|---|---|
| [[方向/大模型/LLM/模型/Masked LM 掩码语言模型]] | 对文本 token 做 mask-and-predict | 是 MGM 在文本上的典型实例，MGM 范围更广 |
| 自回归生成 | 按时间 / token 顺序逐个预测下一个 token | MGM 可一次预测多个位置，再迭代修正，不要求严格左到右 |
| [[方向/AI语音/知识/基础概念/TF Mask（时频掩码）]] | 给 STFT 时频 bin 分配权重或归属 | TF mask 是信号处理 / 特征选择，不等于生成缺失内容 |
| Diffusion / Flow Matching | 连续状态上的噪声扰动与反向生成 | MGM 通常在离散 token 或被遮位置上补全；也可和连续 latent 结合 |
| Inpainting | 对空间、时间或频率上的缺失区域进行修复 | inpainting 是任务形态；MGM 是实现该任务的一类建模范式 |

## 5. 在 AI 语音里的价值与代价

**价值：**

- 并行补全比严格自回归更适合低延迟或固定长度生成。
- 可对局部 token 做编辑、替换和条件控制，天然支持 infilling / editing。
- 在语音恢复中可以只重建受损区域，保留未受损区域的 evidence。
- 离散 codec token 让语言模型能够处理 waveform 之外的声学结构。

**代价：**

- 需要设计 mask schedule、采样轮数和停止条件；速度不是“并行”三个字自动保证的。
- 从高比例 mask 开始时，模型更容易凭先验重绘说话人、音色、韵律或内容。
- codec token 的码率、语义 / 声学解耦和 decoder 质量会直接限制最终音质。
- 恢复任务必须同时看 WER / CER、SpkSim、音质和人工听感，不能只看生成 likelihood 或 MOS。

## 6. 在现有语音模型中的位置

- [[方向/AI语音/模型/MaskGCT]]：两阶段 text-to-semantic / semantic-to-acoustic 的 mask-and-predict zero-shot TTS。
- [[方向/AI语音/模型/MaskSR]]：用 masked language model 补全受损语音的 acoustic tokens，做 44.1 kHz full-band restoration。
- [[方向/AI语音/模型/MaskSR2]]：在 MaskSR 上加入 semantic knowledge distillation，进一步约束 intelligibility / WER。
- [[方向/AI语音/模型/AnyEnhance]]：把 masked acoustic generation 扩展到多种 voice / singing voice enhancement，并加入 prompt guidance 与 self-critic。

## 7. 使用判断

- 看到 `mask-and-predict`、`masked acoustic modeling`、`iterative token refinement`、`parallel generation` 时，可以先归入 MGM 路线，再看它的 token 类型、条件和任务边界。
- 比较两个 MGM 模型时，至少拆开看：mask 的对象、初始 mask 比例、迭代步数、每轮保留策略、codec / tokenizer、是否有 semantic constraint。
- 不要把“并行生成”直接等同于低延迟；真实延迟还取决于迭代轮数、token 序列长度、decoder 和硬件。
- 对 speech restoration，优先检查 no-edit 内容保持、说话人保持和局部 evidence 保留，再看主观音质。

## 8. 关键来源

- [BERT: Pre-training of Deep Bidirectional Transformers for Language Understanding](https://arxiv.org/abs/1810.04805)
  - 内容定位：文本 masked language modeling 的经典基线，说明 bidirectional context + masked token prediction 的基本范式。
  - 用途：建立 MGM 在文本 token 上的起点。
  - 核验日期：2026-09-18
- [MaskGCT: Zero-Shot Text-to-Speech with Masked Generative Codec Transformer](https://arxiv.org/abs/2409.00750)
  - 内容定位：语音生成中的两阶段 mask-and-predict codec token 路线。
  - 用途：连接 MGM 与 zero-shot TTS / 并行语音生成。
  - 核验日期：2026-09-18
- [MaskSR: Masked Language Model for Full-band Speech Restoration](https://arxiv.org/abs/2406.02092)
  - 内容定位：语音恢复中的 masked acoustic token generation 和 iterative sampling。
  - 用途：连接 MGM 与多退化 full-band speech restoration。
  - 核验日期：2026-09-18

## 9. 待实验

- 离散 acoustic token MGM 与连续 latent MGM 在音质、可编辑性和幻觉风险上的边界。
- mask schedule、confidence sampling 和 evidence preservation 对中文语音恢复的影响。
- MGM 与 diffusion / flow matching 混合时，哪些阶段适合离散补全，哪些阶段适合连续生成。

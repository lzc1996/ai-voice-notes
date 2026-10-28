---
title: SELM
类型: 模型
发表时间: 2023-12-15
时间依据: arXiv 首次提交日
任务:
  - 语音增强
开放状态:
  - paper
  - demo
aliases:
  - SELM
  - Speech Enhancement Using Discrete Tokens and Language Models
tags:
  - 类型/对象
  - 方向/AI语音
  - 任务/语音增强
  - 主题/语音表示
  - 主题/语音生成
---

# SELM

## 0. 背景

**问题现场**：传统语音增强是帧级频谱回归问题。

**SELM 的切入点**：把增强改写成"离散 token 序列建模"——SSL 编码器 + k-means 离散化带噪语音，用语言模型自回归生成干净 token，再经 detokenizer 与 vocoder 还原波形。

## 1. 身份

`SELM` 是 *Speech Enhancement Using Discrete Tokens and Language Models* 提出的语音增强框架：把连续语音先转成离散 token，再用语言模型建模上下文，最后把增强后的 token 还原成语音。

边界：SELM 不是传统频谱掩码模型，也不是纯 waveform 回归模型；它把语音增强改写成"离散 token 序列建模"问题。它也不是通用多任务统一框架，后续 [[方向/AI语音/模型/UniSE（Unified Speech Enhancement）|UniSE]] 才把恢复、目标说话人提取和语音分离进一步统一到 decoder-only LM 框架里。

## 2. 核心机制

```text
noisy waveform
  -> SSL encoder + k-means tokenizer
  -> noisy discrete tokens
  -> language model
  -> enhanced / clean discrete tokens
  -> detokenizer + HiFi-GAN
  -> enhanced waveform
```

- **Encoding**：用预训练 [[方向/AI语音/知识/基础概念/SSL 编码器|SSL 编码器]] 和 k-means tokenizer 把连续波形离散化。
- **Modeling**：用 Transformer-based language model 捕捉 token 序列中的上下文信息。
- **Decoding**：用 detokenizer 和 [[方向/AI语音/知识/基础概念/Vocoder（声码器）|HiFi-GAN 类 vocoder]] 把 token 还原成增强语音。

## 3. 核心公式

**离散化**（SSL 表示 → 离散 token）：

$$
c_t = \arg\min_{c_k \in \mathcal{C}}\ \left\| h_t - c_k \right\|_2
$$

$h_t$ 为预训练 SSL 编码器在第 $t$ 帧的输出表示，$\mathcal{C} = \{c_1, \dots, c_K\}$ 为 k-means 学到的码本；连续帧表示被量化为 token 序列 $c_{1:T}$。

**条件语言模型**（带噪 token → 干净 token）：

$$
p_\theta\!\left(c_{1:T}^{\mathrm{clean}} \mid c_{1:T}^{\mathrm{noisy}}\right) = \prod_{t=1}^{T} p_\theta\!\left(c_t^{\mathrm{clean}} \mid c_{<t}^{\mathrm{clean}},\ c_{1:T}^{\mathrm{noisy}}\right)
$$

自回归逐 token 预测干净序列，条件为带噪 token 序列与已生成前缀；训练为交叉熵最大似然——把增强从"帧级频谱回归"改写为"上下文条件生成"。

**解码**（detokenizer + vocoder 还原波形）：

$$
\hat{y} = \mathrm{Vocoder}\!\left( \mathrm{detokenize}(\hat{c}_{1:T}) \right)
$$

$\hat{c}_{1:T}$ 为 LM 生成的干净 token 序列，detokenizer 映射回连续表示，HiFi-GAN 类 vocoder 合成增强波形 $\hat{y}$；token 粒度直接决定增强上限（粗粒度保语义但丢细节）。

## 4. 结果口径

- 它是 `codec / token + LM` 做语音增强的早期明确范式之一。
- 它把语音增强从帧级频谱回归转向 token-level 生成，为后续 [[方向/AI语音/模型/UniSE（Unified Speech Enhancement）|UniSE]]、codec LM 和 discrete audio token 路线提供了前置参照。
- 论文报告其客观指标可比，同时主观感知结果更好；这也提示 token-LM 路线要同时盯住内容保持和幻觉风险。

## 5. 测试基准与性能

**测试基准**：

- 演示 / 评测音频为 DNS Challenge 风格：demo 样例文件名含 clnsp（clean speech）与 babble / traffic 噪声、snr 4–15 标签（demo 页）——即带噪–干净语音对 + 多种非平稳噪声。
- 具体训练 / 测试集划分与采样率待核（arXiv 摘要与 demo 页均未列出）。

**性能指标**：

- 论文口径：客观指标与基线可比、主观感知更优（arXiv 摘要）；具体 PESQ / ESTOI / DNSMOS / SI-SDR 数值待核。
- 评测注意：生成式 token-LM 路线需同时盯内容保持（CAcc）与幻觉风险，不能只看 MOS（见「使用判断」）。

## 6. 使用判断

- token 粒度和 tokenizer 质量会直接限制增强上限；粗粒度 token 可能保语义但丢细节。
- LM 生成式增强有幻觉风险，不能只看 MOS / NISQA / UTMOS，需要配合 [[CAcc]]、[[STOI 与 ESTOI|ESTOI]]、[[SI-SDR]] 和人工听测。
- 自回归 token 生成通常比判别式增强更慢，实时系统要单独评估延迟。

## 7. 相关对象

- [[方向/AI语音/知识/基础概念/SE（语音增强）导论|语音增强]]：SELM 属于 codec LM / 自回归 token 路线。
- [[方向/AI语音/知识/基础概念/NAC（神经音频 Codec）|神经音频 Codec]]：离散 token / decoder 是这类路线的表示基础。
- [[方向/AI语音/知识/基础概念/SSL 编码器|SSL 编码器]]：SELM 用 SSL 表示生成离散 token。
- [[方向/AI语音/知识/基础概念/Vocoder（声码器）|声码器]]：token 还原为 waveform 的输出侧模块。
- [[方向/AI语音/知识/技术路线/LLM-SE Training Recipe（借鉴 NLP LLM 的语音增强训练配方）]]：可把 SELM 视为这套路线的早期 token-LM baseline。
- [[方向/AI语音/模型/UniSE（Unified Speech Enhancement）|UniSE]]：后续更统一的 decoder-only LM-based speech enhancement 框架。

## 8. 关键来源

- [SELM: Speech Enhancement Using Discrete Tokens and Language Models](https://arxiv.org/abs/2312.09747)
  - 内容定位：原始论文，提出 encoding / modeling / decoding 三阶段，并用 SSL + k-means tokenizer、language model、detokenizer + HiFi-GAN 做语音增强。
  - 用途：确认框架机制、发布时间和任务边界。
  - 核验日期：2026-07-31
- [SELM project page](https://honee-w.github.io/SELM/)
  - 内容定位：项目页和音频 demo，展示 coarse-grained discrete tokens + language models 的语音增强流程。
  - 用途：听样例和快速理解框架图。
  - 核验日期：2026-07-31

## 9. 待验证

- SELM 和 UniSE / DAC-SE / [[方向/AI语音/模型/DDSE|DDSE]] 这类后续 codec-LM 语音增强工作的指标与主观听测差异。
- coarse-grained token 在中文、强混响、codec 伪影和低信噪比场景下的内容保持能力。
- 量化结果补全：PESQ / ESTOI / DNSMOS / SI-SDR 具体数值与评测集划分——arXiv 摘要与 demo 页均未列出，待核。

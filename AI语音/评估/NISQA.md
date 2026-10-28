---
title: NISQA
类型: 概念
发表时间: 2021-04-19
时间依据: NISQA arXiv 首次提交日
aliases:
  - Non-Intrusive Speech Quality Assessment
  - NISQA MOS
tags:
  - 类型/对象
  - 方向/AI语音
  - 任务/语音增强
  - 指标/语音质量
---

# NISQA

## 0. 背景

**问题现场**：真实录音（通话、会议、终端设备）拿不到干净参考，PESQ 类侵入式指标不可用，需要无参考的质量预测。

**切入点**：CNN + 自注意力深度模型直接从单段语音回归 MOS 与四个子维度；开源、可复现、提供官方权重。

## 1. 身份

`NISQA`（Non-Intrusive Speech Quality Assessment）是开源的**非侵入式**深度学习质量预测模型：无需干净参考，直接对单段语音预测 MOS 及四个子维度（Noisiness 噪声感、Coloration 音染、Discontinuity 断续、Loudness 响度）。

- 输出 MOS 1–5，越高越好；开源、可复现、有官方权重。

## 2. 用途

- 真实录音（无参考可得）场景的质量评估——URGENT 盲测一半真实录音就靠这类指标。
- 语音增强、TTS、编解码质量的通用代理指标；在 URGENT 榜单中与主观 MOS 排名相关性较高。

## 3. 计算口径

- CNN + 自注意力结构在大量带主观 MOS 标注的语料上训练。
- 与 DNSMOS（[[OVRL_MOS]]）相比：NISQA 输出子维度更细，且训练/预测框架、语料标签和微调路径更开放；DNSMOS 也有公开实现和 ONNX 权重，但更偏 Microsoft DNS Challenge 评测工具链。

NISQA 没有手算闭式公式，本质是非侵入式模型回归：

$$
(\widehat{MOS},\widehat{Noisiness},\widehat{Coloration},\widehat{Discontinuity},\widehat{Loudness})=f_\theta(x)
$$

批量报告通常取样本均值：

$$
\overline{MOS}=\frac{1}{M}\sum_{i=1}^{M}\widehat{MOS}_i
$$

## 4. 子维度量化与训练

NISQA 的子维度分数来自主观听测标签，不是从 SNR、LUFS、频响或丢包率等物理指标直接换算出来。训练集里的每条音频有 overall MOS 和四个维度标签，模型学习的是：给定音频特征，人类平均会在每个维度上打几分。

- 量化方式：听众对音频的 overall quality、Noisiness、Coloration、Discontinuity、Loudness 分别打分，聚合成每条样本的监督标签。
- 训练数据：官方 NISQA Corpus 包含 14,000+ 条语音，覆盖模拟失真与真实通信链路，并带主观质量和维度标签。
- 训练字段：标准多维训练 CSV 需要 `mos`、`noi`、`dis`、`col`、`loud` 五列，对应 overall 和四个子维度。
- 模型结构：Mel-spectrogram segment → CNN framewise feature → Self-Attention / LSTM 时间建模 → pooling；`NISQA_DIM` 使用共享前端和 5 个输出分支。
- 损失函数：五个输出分别做回归损失后相加反传；官方实现使用 `biasLoss`，可选一阶 bias mapping，用于缓解不同数据集主观打分尺度偏移。

训练目标可以简写为：

$$
\mathcal{L}=\mathcal{L}_{MOS}+\mathcal{L}_{Noi}+\mathcal{L}_{Dis}+\mathcal{L}_{Col}+\mathcal{L}_{Loud}
$$

所以 NISQA 确实是数据拟合，但不是简单线性拟合；它是用深度模型拟合“音频特征 → 人类主观维度分数”的映射。遇到中文方言、生成式伪影、新 codec、TTS 或极端通话链路时，可能把问题归因错。

## 5. 四个子维度

NISQA 的四个子维度用于解释 MOS 为什么低：它们不是手工信号指标，而是听感故障归因。分数仍按质量分理解，通常越高越好；例如 `Noisiness` 高不是“噪声多”，而是“噪声问题少”。

| 维度 | 具体含义 | 典型问题 | 排查方向 |
|------|----------|----------|----------|
| `Noisiness` 噪声感 | 背景噪声、嘶声、编码噪声、电路噪声等非语音成分是否烦人。 | 风扇声、底噪、白噪、音乐残留、人群残留、codec 噪声。 | 降噪强度、残留背景、噪声数据匹配、后处理。 |
| `Coloration` 音染 | 人声频谱和音色是否自然，是否被滤波、窄带化、鼻音化、变薄或变远。 | 电话音、闷、薄、金属感、鼻音、像隔着墙、[[方向/AI语音/知识/基础概念/Boxy Sound（箱音）]]、[[方向/AI语音/知识/基础概念/High-Frequency Roll-off（高频滚降）]]。 | 频响、codec、vocoder、过度增强、带宽限制。 |
| `Discontinuity` 断续 | 时间上是否连续平稳，有没有断裂、抖动、抽吸、丢帧或突变。 | 卡顿、掉字、爆音、门限开关感、VAD 抽吸、水声闪烁。 | 丢包、chunk 边界、VAD、门控、生成式不稳定。 |
| `Loudness` 响度 | 主观音量是否合适；不是越响越好，太小或太大都会扣分。 | 太轻听不清、太响刺耳、响度忽大忽小、压缩感重。 | 响度归一化、AGC、削波、动态范围压缩。 |

一句话记法：`Noisiness` 管“脏不脏”，`Coloration` 管“像不像原本人声”，`Discontinuity` 管“顺不顺”，`Loudness` 管“音量合不合适”。

## 6. 子维度解耦性

NISQA 的四个子维度更像“带诊断含义的主观质量回归头”，不是充分解耦的潜变量。它们都按“高分 = 质量好”标定，所以在很多测试集上与 overall MOS 高度正相关是预期现象，不一定说明脚本错误。

造成高相关的常见原因：

- **评分方向一致**：MOS、Noisiness、Coloration、Discontinuity、Loudness 都是质量分，天然同向。
- **真实退化共现**：codec、远场、会议链路、过度降噪常同时带来噪声、音染、断续和响度问题。
- **共享模型前端**：`NISQA_DIM` 是共享声学表示后接多个输出分支，没有显式正交约束或互信息解耦约束。
- **训练目标拟合人类评分**：如果主观数据中整体质量差时各维度也一起低，模型会学到这种相关结构。
- **测试集退化单一**：如果样本主要是“整体好 / 整体坏”，而不是纯噪声、纯音染、纯断续、纯响度，子维度会更像 MOS 的共线代理。

学界已有相近讨论，但通常不直接表述为“NISQA 未充分解耦”：

- NISQA 原论文只承诺四个维度提供 degradation cause insight，没有承诺这些维度彼此独立或正交。
- ICASSP 2023 Speech Signal Improvement Challenge 用 factor analysis 检查质量维度共享方差，结果显示 signal、coloration、loudness 有共享因子，discontinuity 有 cross-loading，noisiness 相对独立；作者也提醒该因子结构来自当前训练集，需要额外验证泛化性。
- 2025 年 Multivariate Probabilistic Assessment of Speech Quality 直接把 MOS 与四个 NISQA 维度联合建模为多变量分布，并预测维度间 covariance，说明维度相关结构本身值得建模。

本地验证不要只看 `corr(dim, MOS)`，更有用的是看去除 MOS 后还有没有诊断信息：

| 检查 | 目的 |
|------|------|
| `partial corr(dim_i, dim_j | MOS)` | 看控制 overall MOS 后，维度之间是否仍强相关。 |
| `residual_dim = dim - f(MOS)` | 看每个维度相对 MOS 的残差是否能区分故障类型。 |
| 按退化类型分组看 residual | 判断纯噪声、纯低通、纯丢包、纯增益变化是否落在对应维度上。 |

可控退化的期望现象：只加背景噪声时 `Noisiness` 相对 MOS 掉得更多；只做低通 / 带宽限制时 `Coloration` 相对更差；只做丢包 / 门控 / 卡顿时 `Discontinuity` 相对更差；只改增益 / 响度时 `Loudness` 相对更差。如果这些 controlled degradations 的残差仍分不开，可以较有力地说：在当前目标域上，NISQA 子维度诊断能力不足，主要退化成 overall MOS 的共线代理。

## 7. 使用注意

- 对训练分布外的失真（新型 codec、生成式伪影、非英语）会失准——URGENT 2025 日语案例中 NISQA 3.08 vs 主观 MOS 2.94 出现失配。
- 生成式"幻觉语音"听感自然时 NISQA 会打高分，无法检测内容错误；需配合 [[CAcc]] / CER 类内容指标。
- 四个子维度只解释听感问题，不等价于内容保持或说话人保持；仍需配合 [[CAcc]]、[[SpkSim]]、WER/CER。
- 见 [[语音增强评估指标体系]]。

## 8. 相关对象

- [[方向/AI语音增强/README|AI 语音增强]]
- [[语音增强评估指标体系]]、[[SE SOTA（语音增强模型表现）]]
- [[OVRL_MOS]]（DNSMOS/P.835 口径）、[[UTMOS]]

## 9. 关键资源

- [NISQA 官方仓库](https://github.com/gabrielmittag/NISQA)
  - 内容定位：开源实现与预训练权重。核验日期：2026-07-28
- [NISQA 论文 (Mittag et al.)](https://arxiv.org/abs/2104.09494)
  - 内容定位：模型结构与训练数据说明。核验日期：2026-07-28
- [NISQA train config](https://github.com/gabrielmittag/NISQA/blob/master/config/train_nisqa_cnn_sa_ap.yaml)
  - 内容定位：标准训练配置，说明多维训练 CSV 需包含 `mos`、`noi`、`dis`、`col`、`loud` 标签列。
  - 核验日期：2026-08-17
- [NISQA implementation](https://github.com/gabrielmittag/NISQA/blob/master/nisqa/NISQA_lib.py)
  - 内容定位：`NISQA_DIM` 多维输出模型实现，包含 5 个输出分支。
  - 核验日期：2026-08-17
- [ICASSP 2023 Speech Signal Improvement Challenge](https://arxiv.org/abs/2303.06566)
  - 内容定位：使用 factor analysis 分析 speech quality dimensions 的共享方差和因子结构。
  - 核验日期：2026-08-18
- [Multivariate Probabilistic Assessment of Speech Quality](https://arxiv.org/abs/2506.04890)
  - 内容定位：将 MOS 与 NISQA 四个维度联合建模，并显式预测维度间 covariance / correlation。
  - 核验日期：2026-08-18

## 10. 待验证

- 中文通话链路上 NISQA 与人工 P.808 听测的相关性。
- 本地测试集上 NISQA 四个子维度与 MOS 的 partial correlation、residual diagnostic power。
- 构造纯噪声、纯低通、纯丢包、纯增益变化样本，验证四个子维度是否能按预期分开。

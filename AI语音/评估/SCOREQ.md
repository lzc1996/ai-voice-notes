---
title: SCOREQ
类型: 概念
发表时间: 2024-10-09
时间依据: SCOREQ arXiv v1 提交日
aliases:
  - Speech Quality Assessment with Contrastive Regression
tags:
  - 类型/对象
  - 方向/AI语音
  - 任务/语音增强
  - 指标/语音质量
---

# SCOREQ

## 0. 背景

**问题现场**：无参考语音质量指标普遍跨域泛化差，在训练分布外与主观 MOS 的相关性显著下降。

**前序缺口**：L2 损失直接回归 MOS 丢掉了标签的连续性，学到的表示碎片化；NOMAD 等对比方法依赖离线三元组准备。

**SCOREQ 的切入点**：用 MOS 距离排序约束的三元组对比回归损失（Batch-All 在线挖掘）学习按质量有序的表示。

## 1. 身份

`SCOREQ`（Speech Quality Assessment with Contrastive Regression，Ragano/Skoglund/Hines，NeurIPS 2024）是**非侵入式**语音质量预测模型，核心贡献是把对比回归的三元组损失引入 MOS 预测，针对性解决无参考指标**跨域泛化差**的问题。

- 论文 arXiv v1 标题曾含 "Quantile Distribution Matching"，v2（NeurIPS 录用版）已去掉，且正文没有分位分布匹配方法——引用时以 v2 标题为准。
- 在 URGENT 2024 的分析中，SCOREQ 与 [[UTMOS]] 并列为主观 MOS 排名相关性最高的一档自动指标。

## 2. 用途

- 无参考（NR）MOS 预测：直接从退化语音预测质量，适合大规模自动初筛。
- 非匹配参考（NMR）模式：没有对齐参考信号时，用 embedding 距离度量质量。
- 作为损失函数复用：三元组对比回归思路可迁移到任何回归任务（论文的核心结论之一）。

## 3. 核心机制

数据流：`音频 -> wav2vec 2.0 编码器 -> 时间维平均 -> 投影头 -> 256 维 embedding -> MOS 预测`。

- 编码器：wav2vec 2.0 BASE，12 层 transformer（768 维）微调，CNN 前端冻结；输出取最后一个 transformer 层沿时间平均，记为 $g(x)$。
- 投影头 $f(\cdot)$：ReLU + 全连接，$e_i = f(g(x_i)) \in \mathbb{R}^{256}$。
- 另有 w2vlight 轻量版（4 层 transformer 从头训练），证明小模型也能受益于该损失。

核心损失是三元组对比回归：同一 batch 内，若样本 $x_i$ 的 MOS 距 $x_j$ 比距 $x_k$ 近（$|y_i - y_j| < |y_i - y_k|$），就约束 embedding 也满足同样的排序：

$$
\mathcal{L} = \sum_{i,j,k} \mathcal{M}(i,j,k)\left( \|e_i - e_j\|_2 - \|e_i - e_k\|_2 + m \right)
$$

其中 $\mathcal{M}(i,j,k)$ 是 Batch-All 掩码（on-the-fly 三元组挖掘，只保留排序有效的三元组，不同于 NOMAD 的离线准备），$m$ 是 margin，"easy triplets"（损失已为负）被剔除。两个变体：SCOREQ Const（固定 margin）与 SCOREQ Adapt（margin 按 MOS 差值自适应，归一化到 $[0,1]$）。

NR 模式两步训练：① 用上述损失训练编码器；② 冻结编码器，用 L2 训练线性 MOS 预测头。这样 embedding 空间先按质量连续有序（L2 直接回归的表示是碎片化的：论文中 NMI 0.39 vs 0.11），再由轻量头完成映射。

## 4. 测试基准与性能

- 训练只用两个域：NISQA TRAIN SIM（模拟电话退化）+ VoiceMOS Train（TTS/语音转换），共约 1 万样本。
- 零样本跨域测试 11 个集合（NISQA TEST FOR/P501/LIVETALK、P23、TCD-VOIP、NOIZEUS、TENCENT/TENCENT-Rev、VoiceMOS Test 等），分 IN/ODS/ODM 三档。
- 主要结果（Pearson 相关）：NISQA TEST FOR 0.97、P23 EXP1 0.96、NOIZEUS 0.91、VoiceMOS Test 2 0.82，多数 ODS/ODM 集上显著优于 NISQA、NR-PESQ、NORESQA-MOS、NOMAD 和 L2 基线（bootstrap 检验）。
- 注意：论文正文未与 DNSMOS、UTMOS 头对头对比；"与 UTMOS 并列第一档"的说法来自 URGENT 2024 挑战论文的分析（见 [[语音增强评估指标体系]]）。
- 评估时对预测值做一阶多项式映射校正各听测偏差，仅影响 RMSE 口径。

## 5. 边界与使用注意

- 训练域极窄（电话退化 + 合成语音），对语音增强特有失真的覆盖靠的是表示学习而非训练数据；强混响、真实通话录音上的表现需验证。
- 分数绝对值跨数据集不可比，只适合同一评测内排序（与 UTMOS 同样的限制）。
- 引用标题注意版本差异（见 [[#1. 身份|身份]] 节）。

## 6. 相关对象

- [[UTMOS]] - URGENT 2024 分析中并列主观 MOS 相关性第一档的无参考指标
- [[NISQA]] - 论文基线之一，训练集沿用其 TRAIN SIM 划分
- [[OVRL_MOS]] - 同类无参考 MOS 指标（DNSMOS 三分量）
- [[语音增强评估指标体系]]、[[URGENT（通用语音增强挑战）]]

## 7. 关键资源

- [SCOREQ: Speech Quality Assessment with Contrastive Regression (Ragano et al., NeurIPS 2024)](https://arxiv.org/abs/2410.06675)
  - 内容定位：原始论文，机制、损失定义与跨域评测均以此为准。核验日期：2026-10-22
- [SCOREQ 官方仓库 (alessandroragano/scoreq)](https://github.com/alessandroragano/scoreq)
  - 内容定位：PyTorch 实现，提供自然语音/合成语音两版指标，支持 NR 与 NMR 模式。核验日期：2026-10-22

## 8. 待验证

- SCOREQ 在强混响、真实通话录音上的分数漂移程度（与 UTMOS 同一问题）。
- 在语音增强任务（URGENT 类场景）中相对 DNSMOS/[[NISQA]] 的头对头表现。

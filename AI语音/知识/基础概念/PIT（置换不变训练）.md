---
title: PIT（置换不变训练）
类型: 方法
发表时间: 2016-07-01
时间依据: arXiv 首次提交日（v1）；ICASSP 2017 发表
相关任务:
  - 语音分离
相关主题:
  - 训练准则
  - 输出排列问题
aliases:
  - 置换不变训练
  - PIT
  - Permutation Invariant Training
  - uPIT
  - utterance-level PIT
tags:
  - 类型/对象
  - 方向/AI语音
  - 任务/语音分离
  - 主题/训练准则
---

# PIT（置换不变训练）

## 1. 身份

`PIT`（Permutation Invariant Training，置换不变训练）是 Yu、Kolbæk、Tan、Jensen（Microsoft Research + Aalborg University）2016 年提出的**多说话人分离训练准则**，解决监督式分离的长期卡点——**输出排列问题**（label permutation problem）：模型输出第 1 路、第 2 路没有天然的说话人标签，固定指定"输出 1 = 说话人 A"会让训练目标自相矛盾。

边界：PIT 不是模型架构，也不是 mask 类型或评估指标——它是**损失函数的排列对齐方式**，可以套在任意分离网络上（LSTM、Conv-TasNet、[[方向/AI语音/模型/TF-GridNet|TF-GridNet]]、[[方向/AI语音/模型/SpatialNet|SpatialNet]] 都在用）。它与 deep clustering 同属深度学习语音分离的奠基性范式，但路线不同（见第 3 节）。

## 2. 核心机制

设混合语音对应 $C$ 个目标说话人信号 $s_1,\dots,s_C$，模型输出 $C$ 路估计 $\hat{s}_1,\dots,\hat{s}_C$。训练时枚举全部 $C!$ 种输出-目标配对，取总误差最小的一种排列回传梯度：

$$\mathcal{L}_{\text{PIT}}=\min_{\pi\in S_C}\sum_{c=1}^{C}\ell\big(\hat{s}_{\pi(c)},\,s_{c}\big)$$

其中 $S_C$ 为 $C$ 元对称群（全部排列），$\ell$ 为单路损失（原版用谱幅度 MSE，现代实践多用负 [[方向/AI语音/评估/SI-SDR|SI-SDR]] / SNR）。

数据流口径：网络结构不变 → 前向得到 $C$ 路输出 → 损失层内做排列搜索 → 按最优排列算梯度。排列搜索只发生在训练损失里，不增加模型参数。

## 3. 变体：帧级 PIT 与 uPIT

| 变体 | 出处 | 排列粒度 | 代价 |
|---|---|---|---|
| 帧级 PIT（tPT） | ICASSP 2017 原版 | 每个 T-F 帧独立选最优排列 | 相邻帧可能把同一说话人切到不同输出流，推理时还需额外的说话人一致性对齐 |
| uPIT（utterance-level PIT） | IEEE/ACM TASLP 2017 | 整句共享一个排列 | 用 RNN 的时序记忆把同一说话人钉在同一输出流，成为事实标准 |

uPIT 在 WSJ0 与 Danish 二/三人混合上超过 NMF、CASA 类方法，与 deep clustering（DPCL）、Deep Attractor Network 相当，且对未见说话人、未见语言、2/3 人混合共用单模型均有泛化。

## 4. 边界与使用判断

- **适合**：说话人无关（speaker-independent）的监督式分离训练；与任意判别式骨干、任意单路损失（MSE / SI-SDR / SNR）组合。
- **复杂度**：排列枚举随说话人数阶乘增长——2 人 2 种、3 人 6 种、4 人 24 种；说话人数多时需要启发式或分阶段排列搜索。
- **不解决**：说话人数未知的问题（需 OR-PIT 等递归扩展，见 [[方向/AI语音/模型/REDnet|REDnet]] 谱系）；输出路数需预设最大人数。
- **现代地位**：uPIT 已是分离训练的默认组件，论文中"PIT + 负 SI-SDR"作为一行训练配置出现，不再单独宣称创新。

## 5. 关键来源

- [Permutation Invariant Training of Deep Models for Speaker-Independent Multi-talker Speech Separation (arXiv:1607.00325)](https://arxiv.org/abs/1607.00325)
  - 内容定位：PIT 原始论文（ICASSP 2017），提出直接优化分离回归误差、忽略源顺序的训练准则。
  - 用途：PIT 定义与发表时间依据。
  - 核验日期：2026-10-15
- [Multi-talker Speech Separation with Utterance-level Permutation Invariant Training of Deep Recurrent Neural Networks (arXiv:1703.06284)](https://arxiv.org/abs/1703.06284)
  - 内容定位：uPIT 论文（IEEE/ACM TASLP 2017），把排列对齐提升到整句粒度，消除推理期额外排列对齐。
  - 用途：理解帧级 PIT 与 uPIT 的区别和工程可用形态。
  - 核验日期：2026-10-15

## 6. 相关对象

- [[方向/AI语音/知识/基础概念/SS（语音分离）|SS（语音分离）]]：PIT 是分离任务的训练侧地基，解决其"输出排列问题"。
- [[方向/AI语音/知识/基础概念/Source Separation（源分离）|Source Separation（源分离）]]：上位概念；判别式深度学习路线里 deep clustering → PIT → 时域端到端的演进。
- [[方向/AI语音/模型/TF-GridNet|TF-GridNet]]、[[方向/AI语音/模型/SpatialNet|SpatialNet]]、[[方向/AI语音/模型/CI-Spatial|CI-Spatial]]、[[方向/AI语音/模型/FlexIO|FlexIO]]：现代骨干均用 PIT 训练。
- [[方向/AI语音/模型/MiDashengLM-Spatial|MiDashengLM-Spatial]]：PIT 在 SELD 场景的 track 级变体——multi-ACCDOA 输出按帧做排列搜索，对齐预测的源轨迹与目标。
- [[方向/AI语音/模型/REDnet|REDnet]]：递归分离范式 OR-PIT 的端到端实现，处理说话人数未知。
- [[方向/AI语音/评估/SI-SDR|SI-SDR]]：PIT 框架下最常用的单路损失/指标。

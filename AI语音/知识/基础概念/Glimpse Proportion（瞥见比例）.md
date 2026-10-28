---
title: Glimpse Proportion（瞥见比例）
类型: 概念
相关主题:
  - 可懂度评估
  - 听觉场景分析
aliases:
  - Glimpse Proportion
  - glimpse proportion
  - GP
  - 瞥见比例
  - glimpsing
  - 语音瞥见
tags:
  - 类型/对象
  - 方向/AI语音
  - 主题/可懂度
  - 主题/听觉模型
---
# Glimpse Proportion（瞥见比例）

## 1. 身份

`Glimpse Proportion`（GP，瞥见比例）是一种基于**语音瞥见（glimpsing）**听觉模型的可懂度度量：噪声中的语音理解不要求全部时频点都干净，听者靠拼接"目标占主导的时频小块"（glimpses）即可恢复内容；GP 就是**估计可听度超过阈值的 T-F 块占总块数的比例**。

理论源头是 Cooke（2006）的 glimpsing model：该模型用"局部 T-F 区域的幸存量"解释人在噪声下的语音识别，并据此预测可懂度。工程上 GP 由"听觉模型"落地为一个**可计算的输出端指标**——不需要干净参考，只需要一个 T-F 可听度估计器。

## 2. 公式与口径

[[方向/AI语音/模型/Listen-first（输出式增强）|Listen-first]] 使用的形式化（助听器输出端选择场景）：

$$\mathrm{GP} = \frac{1}{KL}\sum_{k=1}^{K}\sum_{l=1}^{L} U\big(\widehat{AUD}(k,l) - \gamma_{\mathrm{GP}}\big)$$

- $\widehat{AUD}(k,l)$：T-F 块 $(k,l)$ 的估计可听度。Listen-first 用神经 VAD 输出，按 SII 风格把 T-F SNR clip 到 [−15, 15] dB 再线性映射到 [0, 1]。
- $U(\cdot)$：单位阶跃；$\gamma_{\mathrm{GP}}$：可配置阈值（Listen-first 在验证集上按输出 SNR 调优）。
- GP ∈ [0, 1]：越大表示"目标够响的时频块"越多，可懂度预期越高。

其中"SII 风格"指 **Speech Intelligibility Index（语音可懂度指数，ANSI S3.5）**的分带可听度映射：$A=(\operatorname{clip}(\mathrm{SNR},-15,+15)+15)/30$。截断的两个端点有感知依据——**下限 −15 dB**：再低人耳已提取不出该带信息，不让"特别差的带"把总分拉负；**上限 +15 dB**：感知饱和，听清后再放大不继续提升可懂度，不让"特别好的带"补贴差的带。SII 原版按频带加权（另有频带重要度表），Listen-first 借用同一映射改按 T-F 块计算。SII 目前库内仅这一处使用谱系，暂不建独立页；出现第二个独立使用者（如助听器指标横评）再在 `评估/` 拆页。

## 3. AUD（T-F 可听度）的获取路线

$\widehat{AUD}(k,l)$ 不是只能由网络给出，常见三条路线：

1. **经典信号处理（无网络）**：VAD 门控找静默段、用 MCRA/最小统计量类方法跟踪噪声功率谱，再算局部后验 SNR $(|X|^2-\hat\Phi_{nn})/\hat\Phi_{nn}$，经 SII（ANSI S3.5）clip+线性映射成 [0,1] 可听度；单通道还常用 Ephraim–Malah decision-directed 先验 SNR 递归；多通道可用通道间相干（MSC）判断目标主导块。痛点：低 SNR 下 VAD 与噪声统计本身最不可靠。
2. **听觉模型（感知计算，无网络）**：Cooke 2006 原始口径——gammatone 滤波器组 + 压缩非线性的听觉外周模型，分别在目标与噪声上算耳蜗内可检测量，目标超阈的 T-F 单元记为 glimpse。本质仍是局部 SNR 超阈，只是 SNR 在听觉表征空间里算。
3. **神经网络**：IRM/mask 估计器的输出本身就是 [0,1] 的 T-F 目标占比，可直接作 AUD；或训练专用 VAD/SNR 网络逐块回归可听度。[[方向/AI语音/模型/Listen-first（输出式增强）|Listen-first]] 是混合做法——神经 VAD 出数，再套 SII 风格 clip+线性映射定标。

研究评测里有干净参考时可不算估计、直接用 oracle 局部 SNR。选哪条的约束和 [[方向/AI语音/知识/基础概念/MPDR（最小功率无失真响应）|MPDR]]/[[方向/AI语音/知识/基础概念/MVDR（最小方差无失真响应）|MVDR]] 是同一个权衡：噪声统计可估性 vs 估计器训练成本与泛化。

## 4. 和相邻概念的关系

- **与 [[方向/AI语音/知识/基础概念/TF Mask（时频掩码）|ideal binary mask]] 的同构**：oracle 口径下，"可听度超阈的 T-F 块"近似就是 local SNR > 阈值的块，即 IBM 为 1 的块——GP 可以读作"软版 IBM 占空比"。glimpsing 模型正是 IBM 研究的感知理论基础。
- **与 [[方向/AI语音/评估/STOI 与 ESTOI|STOI / ESTOI]] 的区别**：STOI 需要干净参考、用包络相关性；GP 不需要参考、用可听度计数，因此能用在**输出端在线评估**（没有 ground truth 的部署场景）。
- **与全局 SNR 的区别**：GP 强调"目标主导区是否存在"，对方向性处理（波束指向对不对）更敏感——全局能量指标可能被大范围的小幅改善抬高，而 GP 只在目标真正浮出噪声的块上计数。

## 5. 为什么重要

- **给"输出式系统"提供选择信号**：[[方向/AI语音/模型/Listen-first（输出式增强）|Listen-first]] 用 GP 从一族候选 [[方向/AI语音/知识/基础概念/MPDR（最小功率无失真响应）|MPDR]] 波束中选配置——低 SNR 下输入端 VAD/协方差不可靠，但输出端 GP 仍能可靠挑出指向正确的候选（指向错的候选目标被抵消，GP 自然露馅）。
- **感知对齐**：直接来自人类听觉模型，比纯信号能量口径更接近"人能不能听懂"。

## 6. 边界

- **不是标准化指标**：与 STOI/PESQ 不同，GP 的 $\widehat{AUD}$ 定义、阈值 $\gamma_{\mathrm{GP}}$、T-F 分辨率都因实现而异，跨论文数值不可直接比较。
- **依赖估计器质量**：$\widehat{AUD}$ 本身由神经 VAD 之类估计器给出，估计器的偏差会完整传导进 GP。
- **只数"够不够响"，不评"像不像"**：GP 对可懂度敏感，但不直接惩罚语音失真/伪影（那需要质量类指标配合）。
- 单声道 T-F 口径；双耳/空间保真不在其度量范围。

## 7. 关键来源

- [A glimpsing model of speech perception in noise — M. Cooke, JASA 119(3), 1562–1573 (2006)](https://pubmed.ncbi.nlm.nih.gov/16583901/)
  - 内容定位：glimpsing 模型的原始论文（DOI 10.1121/1.2166600），提出用 T-F glimpse 幸存量解释并预测噪声中语音识别。
  - 用途：GP 概念与感知理论基础的出处。
  - 核验日期：2026-10-15
- [Listen first: Output-Based Multi-Microphone Speech Enhancement（arXiv:2607.12529）](https://arxiv.org/abs/2607.12529)
  - 内容定位：把 GP 用作输出端可懂度度量驱动波束选择（库内笔记：[[方向/AI语音/模型/Listen-first（输出式增强）|Listen-first]]）；给出本页的 GP 公式、SII 风格 AUD 映射与阈值调优口径。
  - 用途：GP 工程化定义的直接依据。
  - 核验日期：2026-10-15

## 8. 相关对象

- [[方向/AI语音/模型/Listen-first（输出式增强）|Listen-first]]：GP 在库内的主要使用者（输出式波束选择）。
- [[方向/AI语音/知识/基础概念/TF Mask（时频掩码）|TF Mask]]：GP 超阈 T-F 块与 IBM 为 1 的块同构。
- [[方向/AI语音/评估/STOI 与 ESTOI|STOI / ESTOI]]：参考式可懂度指标，GP 的非参考式对照。
- [[方向/AI语音/知识/基础概念/MPDR（最小功率无失真响应）|MPDR]]：Listen-first 中 GP 选择的候选波束族。

## 9. 待验证

- glimpse-based 可懂度指标的后续谱系（如 Tang & Cooke 的 glimpse-based metrics 工作 待核 具体年份与 venue），本页只锚定 Cooke 2006 源头。
- GP 阈值 $\gamma_{\mathrm{GP}}$ 与 AUD 映射在不同文献中的口径差异，未做跨文献对照。
- Cooke 2006 中 glimpse 的精确定义（局部 SNR 阈值口径）与 Listen-first 的 SII 风格 AUD 是否严格对应，未逐式核对。

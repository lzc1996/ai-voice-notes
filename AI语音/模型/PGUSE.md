---
title: PGUSE
类型: 模型
发表时间: 2025-05-30
时间依据: arXiv 首次提交日
任务:
  - 语音增强
开放状态:
  - paper
  - demo
aliases:
  - Predictive and Generative modeling for Universal Speech Enhancement
  - A Composite Predictive-Generative Approach to Monaural Universal Speech Enhancement
  - PGUSE speech enhancement
  - predictive-generative universal speech enhancement
tags:
  - 类型/对象
  - 方向/AI语音
  - 任务/语音增强
  - 主题/生成模型
---

# PGUSE

## 0. 背景

**问题现场**：单通道通用语音增强既需要判别式/预测式增强的稳定保真，又需要扩散生成式增强在严重退化下的恢复能力。

**PGUSE 的切入点**：双分支架构——predictive branch 直接预测 clean complex spectrum、generative branch 做 score-based diffusion，经 interaction module 传递信息，最终在幅度域融合输出，并用 truncated diffusion 缩短反向扩散过程。

## 1. 身份

`PGUSE` 是一个 monaural universal speech enhancement 模型，全名可按论文表述理解为 **Predictive and Generative modeling for Universal Speech Enhancement**。它试图把判别式/预测式增强的稳定保真，和扩散生成式增强在严重退化下的恢复能力合到一个模型里。

层级定位：PGUSE 是**模型**。它有明确的双分支架构、训练目标和推理策略；“预测 + 生成融合”这个思想后来也可以作为更宽的混合式路线理解。

## 2. 核心结构

- **Predictive branch**：从 degraded signal 直接预测 clean complex spectrum，提供稳定的相位/频谱估计。
- **Generative branch**：做 score-based diffusion / denoising objective，在 magnitude STFT 域生成增强候选。
- **Interaction module**：把 predictive branch 的信息传给 generative branch，帮助 score estimation。
- **Output fusion**：在频谱幅度域融合 predictive result 和 generative result，phase 主要取 predictive branch。
- **Truncated diffusion**：用 predictive branch 的初始估计缩短反向扩散过程，减少采样步数和计算开销。

## 3. 核心公式

**1. 预测分支：complex spectrum 回归：**

$$\mathcal{L}_{\text{pred}} = \mathbb{E}\Big[\big\| \hat S_{\text{pred}}(y) - S \big\|_2^2\Big]$$

$y$ 为 degraded 信号，$S$ 为干净语音的 complex spectrum，$\hat S_{\text{pred}}$ 为 predictive branch 的直接估计；该分支提供稳定的相位与幅度先验。

**2. 生成分支：score-based diffusion / denoising objective（magnitude STFT 域）：**

$$\mathcal{L}_{\text{gen}} = \mathbb{E}_{t\sim\mathcal U(0,T),\,\epsilon\sim\mathcal N(0,I)}\Big[w(t)\,\big\| \epsilon_\theta\big(x_t,\, t,\, h_{\text{pred}}\big) - \epsilon \big\|_2^2\Big]$$

$x_t$ 为幅度谱域加噪样本，$h_{\text{pred}}$ 为 interaction module 从预测分支传入的信息（辅助 score estimation），$w(t)$ 为时间权重；生成分支负责严重退化下的恢复上限。

**3. 截断扩散推理（truncated diffusion）：**

$$x_{t_0} = \sqrt{\bar\alpha_{t_0}}\,\hat S_{\text{pred}} + \sqrt{1-\bar\alpha_{t_0}}\,\epsilon, \qquad \epsilon\sim\mathcal N(0,I)$$

用预测分支估计 $\hat S_{\text{pred}}$ 构造反向扩散起点 $x_{t_0}$（$t_0<T$，$\bar\alpha_t$ 为噪声 schedule 累积系数），跳过前半段反向过程，减少采样步数与计算开销。

**4. 输出融合：**

$$|\hat S_{\text{out}}| = \text{Fuse}\big(|\hat S_{\text{pred}}|,\, |\hat S_{\text{gen}}|\big), \qquad \angle\hat S_{\text{out}} = \angle\hat S_{\text{pred}}$$

最终幅度为预测与生成幅度的融合结果，相位主要取预测分支的相位估计，兼顾稳定性与生成上限。（具体融合方式（加权/门控）待核，见待验证）

## 4. 测试基准与性能

**测试基准：** 论文摘要仅称 "several datasets"、与 SOTA 基线对比；具体评测集与条件待核。旁证：SenSE 论文（arXiv 2509.24708）的对比表中 PGUSE 出现在 DNS Challenge no-reverb / HardSet / GSR 与 VCTK GSR 四个评测集（PGUSE 原文待核）。

**性能指标：** 待核——arXiv 摘要与 demo 页均无数字（ar5iv HTML 抓取失败、demo 页不可达）。SenSE 论文对比表转引的 PGUSE 数值（非 PGUSE 原文）：DNS no-reverb DNSMOS 3.333 / NISQA 4.661 / dWER 4.52%；HardSet DNSMOS 3.250；DNS GSR DNSMOS 3.290；VCTK GSR DNSMOS 3.057（转引自 arXiv 2509.24708 HTML）。

（来源：arXiv 2505.24576 摘要；转引 SenSE arXiv 2509.24708 HTML）

## 5. 位置判断

PGUSE 属于 [[方向/AI语音/知识/基础概念/SE（语音增强）导论|SE]] 里的**混合式/预测-生成复合路线**：它不是纯判别式模型，也不是纯扩散模型。和 [[方向/AI语音/模型/GAP-URGENet|GAP-URGENet]] 相比，PGUSE 更早地在一个模型内结合 predictive / generative 分支；GAP-URGENet 则是 URGENT 2026 参赛系统层面的生成-预测融合。

它也可以放在从 [[方向/AI语音/知识/生成式语音增强/扩散模型与语音|扩散语音增强]] 走向低幻觉、低采样成本的中间位置：用生成式提高严重退化恢复上限，用预测式守住稳定性并缩短采样。

## 6. 使用注意

- PGUSE 的“generative”不是 codec LM 或 LLM 自回归生成，而是 score-based diffusion。
- 它仍是单通道 universal SE 模型；真实产品里要单独评估多通道、流式、实时延迟和域外泛化。
- Output fusion 和 truncated diffusion 是理解 PGUSE 的两个关键点：前者负责融合质量，后者负责降低扩散采样负担。
- 和 [[方向/AI语音/模型/SenSE|SenSE]]、[[方向/AI语音/模型/UniPASE|UniPASE]]、[[方向/AI语音/模型/GAP-URGENet|GAP-URGENet]] 对比时，要分清评测集、采样率、是否参加 [[方向/AI语音/评估/URGENT（通用语音增强挑战）|URGENT]] 榜单。

## 7. 相关对象

- [[方向/AI语音增强/README|AI 语音增强]]：PGUSE 属于 universal speech enhancement 前沿模型。
- [[方向/AI语音/知识/基础概念/SE（语音增强）导论|SE（语音增强）导论]]：PGUSE 是预测式和生成式路线融合的代表。
- [[方向/AI语音/知识/调研与地图/SE SOTA（语音增强模型表现）|SE SOTA]]：可作为混合式/生成式增强路线的比较对象。
- [[方向/AI语音/知识/生成式语音增强/扩散模型与语音|扩散模型与语音]]：PGUSE 的 generative branch 属于 score-based diffusion。
- [[方向/AI语音/模型/GAP-URGENet|GAP-URGENet]]：后续更系统化的生成-预测融合路线代表。
- [[方向/AI语音/模型/SenSE|SenSE]]、[[方向/AI语音/模型/UniPASE|UniPASE]]：同属 2025–2026 前后 universal SE 生成式/低幻觉路线。
- [[方向/AI语音/实证研究/Toward Universal Speech Enhancement for Diverse Input Conditions（通用语音增强开山作）|Toward Universal SE for Diverse Input Conditions]]：ASRU 2023 提出的通道数/时长/采样率无关统一 SE 模型与基准，可作 universal SE 谱系的先行参照。

## 8. 关键来源

- [A Composite Predictive-Generative Approach to Monaural Universal Speech Enhancement](https://arxiv.org/abs/2505.24576)
  - 内容定位：PGUSE 原始论文，提出 predictive branch + generative branch、output fusion 和 truncated diffusion。
  - 用途：确认模型定义、发表时间、架构和实验结论。
  - 核验日期：2026-08-04
- [PGUSE demo / project page](https://hyyan2k.github.io/PGUSE/)
  - 内容定位：作者项目页，提供 paper、code 和 audio demos 入口。
  - 用途：后续复现实验和听感对比。
  - 核验日期：2026-08-04

## 9. 待验证

- 官方代码仓库当前是否仍可完整复现论文结果。
- PGUSE 在 URGENT 2025/2026、真实会议录音、中文和低码率通话场景中的位置。
- 与 GAP-URGENet 的”生成-预测融合”是否可以整理成一个更高层的混合式 SE 框架笔记。
- 输出融合的具体方式（加权系数/门控网络）与预测分支损失的具体度量（L1/L2/SI-SNR）需从论文核对。
- PGUSE 原文的评测集清单（是否参加 URGENT 榜单）与绝对指标（PESQ/DNSMOS/SI-SDR）需从论文全文核对（demo 页与 ar5iv 不可达）。

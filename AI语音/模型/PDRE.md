---
title: PDRE
类型: 模型
发表时间: 2025-04
时间依据: ICASSP 2025 会议发表
任务:
  - 语音增强
  - 去混响
团队:
  - "[[方向/AI语音/团队/NTT Speech Group（NTT 语音组）]]"
开放状态:
  - paper
  - demo
aliases:
  - PDRE
  - Probabilistic-Deterministic Recursive Enhancement
  - A Hybrid Probabilistic-Deterministic Model Recursively Enhancing Speech
  - 概率-判别式递归增强
tags:
  - 类型/对象
  - 方向/AI语音
  - 任务/语音增强
  - 任务/去混响
  - 主题/生成式增强
---

# PDRE

## 0. 背景

**问题现场**：生成式语音增强需要扩散级的质量，但扩散的迭代估计算力昂贵，需要以更少迭代达到同等精度。

**前序路线的缺口**：扩散方法（mSGMSE+Ensemble 类）需 30–60 步噪声采样，质量高但 RTF 高达 7.87，算力难以落地。

**PDRE 的切入点**：不做逐步去噪采样，而是用最大似然目标训练的增强网络（EN）递归细化干净语音密度估计，与确定性信号估计协同，RTF 降到 0.077。

## 1. 身份

`PDRE`（Probabilistic-Deterministic Recursive Enhancement，概率-判别式递归增强）是 NTT（Nakatani、Kamo、Delcroix、Araki，ICASSP 2025，Hyderabad，pp. 1–5）提出的生成式增强方法：用**最大似然目标训练的增强网络（EN）递归细化**干净语音的密度估计，与确定性信号估计协同，**以远少于扩散的迭代次数达到扩散级质量**。

边界：PDRE **不是扩散模型**——不做逐步去噪采样；它是"概率式密度细化 × 判别式信号估计"的递归混合，是 [[方向/AI语音/模型/mSGMSE|mSGMSE+Ensemble]] 类扩散方法的算力解。动机：扩散的迭代估计质量高但算力昂贵，需要更少的迭代实现同等精度。

## 2. 核心机制

```text
带噪/混响观测
  -> 确定性信号估计（detNN 类前端）
  -> 递归应用增强网络 EN（ML 目标训练）：
       每轮更新干净语音密度估计
  -> 与确定性估计协同 -> 最终干净估计
```

关键点：

- **递归 EN**：对干净语音的密度估计反复应用 EN（而非扩散的 30–60 步噪声采样），**单次应用即显著改进**，迭代数大幅少于扩散。
- **概率-判别式协同**：递归细化与确定性信号估计互为补充，精度高于纯递归或纯确定性。
- **算力主线**：论文定位是"保持扩散质量、砍掉扩散算力"——RTF 从扩散的 7.87 降到 0.077。

## 3. 核心公式

PDRE 不做逐步去噪采样，而是**递归细化干净语音的密度估计**；以下为任务的标准形式（EN 网络结构、递归步数与 ML 目标的具体构造见待验证）。

**递归细化**（EN 反复应用）：

$$
\hat{s}^{(r)} = \mathrm{EN}_\theta\!\left(\hat{s}^{(r-1)},\ x\right), \qquad r = 1, \dots, R
$$

$x$ 为带噪/混响观测，$\hat{s}^{(r)}$ 为第 $r$ 轮估计（$r=0$ 为确定性前端 detNN 输出或观测本身）；单次应用即显著改进，迭代数 $R$ 远小于扩散的 30–60 步采样。

**最大似然目标**（EN 的训练准则）：

$$
\theta^* = \arg\max_\theta\ \mathbb{E}_{(s, x)}\left[ \log q_\theta(s \mid x) \right]
$$

$q_\theta$ 为 EN 参数化的干净语音条件密度——与判别式回归（最小化均方误差）不同，ML 目标让网络输出密度而非点估计，支持递归更新（具体构造待核）。

**概率-判别式协同**（最终估计）：

$$
\hat{s} = \arg\max_{s}\ \left[ \log q_\theta(s \mid x) + \log p(x \mid s) \right]
$$

将递归得到的概率密度估计与观测似然合并的 MAP 形式（标准形式，具体融合方式待核）；论文口径：质量与扩散（mSGMSE+Ensemble）相当，RTF 0.077、不到其 1/100。

## 4. 结果口径（NTT 官方 demo 页：REVERB real mismatched + 仿真噪声混响）

| 方法 | SI-SDR | fwsSNR | ESTOI | PESQ | RTF |
|---|---|---|---|---|---|
| 未处理 | −3.6 | 4.6 | 0.47 | 2.32 | — |
| detNN（确定性） | 6.3 | 11.4 | 0.83 | 2.32 | 0.021 |
| mSGMSE+Ensemble（扩散） | 8.1 | 11.7 | 0.86 | 2.58 | 7.87 |
| **PDRE** | **8.4** | **12.7** | **0.87** | **2.56** | **0.077** |

- **vs detNN**：质量显著提升，RTF 仅小幅增加（0.021 → 0.077）。
- **vs mSGMSE+Ensemble（扩散）**：质量相当或略优，**RTF 不到其 1/100**（0.077 vs 7.87）。

## 5. 测试基准与性能

**测试基准**：

- **REVERB real（mismatched）+ 仿真噪声混响**（NTT demo 页口径）；单通道评测。
- 基线：detNN（确定性前端）、mSGMSE+Ensemble（扩散）。

**性能指标**：完整对比表见「结果口径」（PDRE：SI-SDR 8.4 / fwsSNR 12.7 / ESTOI 0.87 / PESQ 2.56 / RTF 0.077，vs mSGMSE+Ensemble RTF 7.87），此处不重复。

## 6. 使用判断

- 适合：需要扩散级增强质量但算力 / 时延受限的工程化场景；"生成式增强落地"的候选方案。
- 不适合：纯离线且算力充裕、追求极致质量的上限研究（与扩散的直接差距需更大规模验证）。
- 风险：demo 为单通道；多通道 / 流式版本与全文细节待核；官方代码未公开。

## 7. 关键来源

- [A Hybrid Probabilistic-Deterministic Model Recursively Enhancing Speech（IEEE ICASSP 2025）](https://ieeexplore.ieee.org/document/10887979)
  - 内容定位：原始论文（DOI 10.1109/ICASSP49660.2025.10887979）。
  - 用途：方法机制与实验设计。
  - 核验日期：2026-08-06
- [NTT 联合去噪去混响 demo（ICASSP 2025）](https://www.kecl.ntt.co.jp/icl/signal/nakatani/demos/icassp2025/demo.html)
  - 内容定位：PDRE vs detNN vs mSGMSE+Ensemble 的指标表与听感样例。
  - 用途：量化口径（SI-SDR / fwsSNR / ESTOI / PESQ / RTF）。
  - 核验日期：2026-08-06

## 8. 相关对象

- [[方向/AI语音/模型/mSGMSE|mSGMSE]]：直接对比对象 / 前身（mSGMSE+Ensemble 扩散路线）。
- [[方向/AI语音/模型/Multi-Stream Diffusion|Multi-Stream Diffusion]]：同组概率式集成前作。
- [[方向/AI语音/模型/DiffCBF|DiffCBF]]：同组迭代耦合的另一分支（扩散 × 波束形成）。
- [[方向/AI语音/模型/SGMSE+|SGMSE+]]：扩散谱系源头——PDRE 是其"算力解"。
- [[方向/AI语音/团队/NTT Speech Group（NTT 语音组）|NTT Speech Group]]：提出团队。

## 9. 待验证

- 全文细节：EN 网络结构、递归步数、ML 目标构造、训练数据。
- 多通道 / 流式版本与真实产品场景（会议、助听）验证。
- 官方代码 / 权重是否开放。
- 递归更新、ML 目标与概率-判别式融合的具体公式形式——核心公式小节按标准形式写出，IEEE 全文不可直接抓取，待核。

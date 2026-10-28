---
title: STOI 与 ESTOI
类型: 概念
发表时间: 2010
时间依据: STOI 原始论文年份；ESTOI 为 2016 扩展
aliases:
  - STOI
  - ESTOI
  - Short-Time Objective Intelligibility
  - 短时客观可懂度
tags:
  - 类型/对象
  - 方向/AI语音
  - 任务/语音增强
  - 指标/可懂度
---

# STOI 与 ESTOI

## 0. 背景

**问题现场**：质量指标（[[PESQ]] 类）回答"好不好听"，但语音通信与助听场景还需要独立回答"听不听得清"——可懂度需要自己的客观度量。

**切入点**：用短时频谱包络与干净参考的短期相关性预测人类可懂度（STOI）；ESTOI 扩展了对噪声调制频谱的建模并基本取代 STOI。

## 1. 身份

`STOI`（Short-Time Objective Intelligibility）是**侵入式**语音可懂度指标：不需要听懂内容，而是通过[[方向/AI语音/知识/基础概念/Spectral Envelope（频谱包络）|短时频谱包络]]与干净参考的相关性，预测人类听者的可懂度。`ESTOI`（Extended STOI）是其改进版，对噪声调制频谱的建模更细，与真实可懂度相关性更高，目前已基本取代 STOI。

- 范围 0–1，越高越好；0.9+ 通常表示高度可懂。

## 2. 用途

- 语音增强、去混响、听力辅助算法的可懂度评估。
- 与 [[PESQ]]（质量）互补：一个管"听得清不清"，一个管"听感好不好"。

## 3. 计算口径

- 需要干净参考；分帧计算[[方向/AI语音/知识/基础概念/Spectral Envelope（频谱包络）|短时频谱包络]]的归一化相关系数再平均。
- 对电平不敏感，对时间错位敏感；混响尾巴会显著拉低分数。

STOI 的简化计算式可以写成：

$$
d_{j,m}=\frac{(x_{j,m}-\mu_x)^\top(\hat{x}_{j,m}-\mu_{\hat{x}})}{\lVert x_{j,m}-\mu_x\rVert\lVert \hat{x}_{j,m}-\mu_{\hat{x}}\rVert}
$$

$$
\mathrm{STOI}=\frac{1}{JM}\sum_{j=1}^{J}\sum_{m=1}^{M}d_{j,m}
$$

- $x_{j,m}$ / $\hat{x}_{j,m}$ 是参考和待测语音在第 $j$ 个频带、第 $m$ 个短时片段的包络向量。
- ESTOI 是 STOI 的扩展版，会在更长的时频块上做归一化相关；工程上用官方/标准实现，不用这条 STOI 简式替代。

## 4. 使用注意

- STOI/ESTOI 预测的是**可懂度**不是**质量**：噪声去得很干净但语音失真严重的系统，ESTOI 可能仍低。
- 生成式增强的"幻觉语音"（内容被改写）在 ESTOI 上同样被惩罚——URGENT 2025 生成式冠军 ESTOI 仅 0.53–0.54。
- 混响场景建议配合 [[Reverberation Modeling（混响建模）|C50/DRR]] 等声学参数一起看。

## 5. 相关对象

- [[方向/AI语音增强/README|AI 语音增强]]
- [[语音增强评估指标体系]]
- [[SE SOTA（语音增强模型表现）]]
- [[方向/AI语音/知识/基础概念/Spectral Envelope（频谱包络）|Spectral Envelope（频谱包络）]]
- [[Reverberation Modeling（混响建模）]]：晚期混响是可懂度主要杀手。

## 6. 关键资源

- [Taal et al., STOI 原始论文 (ICASSP 2010)](https://ieeexplore.ieee.org/document/5495701)
  - 内容定位：STOI 定义与验证。核验日期：2026-07-28
- [Jensen & Taal, ESTOI (IEEE/ACM TASLP 2016)](https://ieeexplore.ieee.org/document/7539284)
  - 内容定位：ESTOI 改进版定义。核验日期：2026-07-28

## 7. 待验证

- 中文语音上 STOI/ESTOI 与人工可懂度测试的相关性是否和英文一致。

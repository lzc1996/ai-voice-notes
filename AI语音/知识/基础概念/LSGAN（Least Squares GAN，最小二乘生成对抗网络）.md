---
title: "LSGAN（Least Squares GAN，最小二乘生成对抗网络）"
类型: 概念
相关任务:
  - adversarial training
  - 语音合成
  - vocoder
aliases:
  - Least Squares GAN
  - Least Squares Generative Adversarial Network
  - LS-GAN
  - 最小二乘生成对抗网络
  - 最小二乘 GAN
  - LSGAN
tags:
  - 类型/对象
  - 方向/AI语音
  - 主题/生成对抗网络
---

# LSGAN（Least Squares GAN，最小二乘生成对抗网络）

## 1. 身份

`LSGAN` 是一种生成对抗网络训练目标：把传统 GAN 判别器的二元交叉熵替换为最小二乘损失，让判别器按“距离目标标签有多远”惩罚样本。它是损失函数变体，不是新的生成器、判别器架构，也不是一个声码器。

## 2. 核心机制

```text
真实样本 x / 生成样本 G(z)
  -> 判别器 D 输出实数分数
  -> 与真实/伪造目标标签计算平方误差
  -> 交替更新 D 与 G
```

一般形式为：

$$
\min_D \; \frac{1}{2}\mathbb{E}_{x\sim p_{\mathrm{data}}}\left[(D(x)-b)^2\right]
+ \frac{1}{2}\mathbb{E}_{z\sim p_z}\left[(D(G(z))-a)^2\right]
$$

$$
\min_G \; \frac{1}{2}\mathbb{E}_{z\sim p_z}\left[(D(G(z))-c)^2\right]
$$

常见的 `0/1` 标签设定是 $a=0$、$b=c=1$。与只关心“分对/分错”的交叉熵相比，平方误差会继续按分数距离提供梯度；原论文据此讨论减轻梯度消失和改善训练稳定性，但具体收益依赖标签、判别器和数据配方。

## 3. 在 AI 语音中的位置

在声码器、codec decoder 或音频 VAE 的对抗训练中，LSGAN 负责定义 adversarial objective；MPD、MSD 或 CQT 判别器负责从不同时间/频率视角提供判别信号。两者不是同一层概念：LSGAN 是损失目标，[[方向/AI语音/知识/基础概念/MPD（Multi-Period Discriminator，多周期判别器）|MPD]] 是判别器结构。

现有 [[方向/AI语音/模型/AuK|AuK]] 笔记明确记录了 `LS-GAN + MPD + 多尺度 CQT 判别器` 的 VAE 训练配方。

## 4. 相关对象

- [[方向/AI语音/知识/基础概念/MPD（Multi-Period Discriminator，多周期判别器）|MPD]]：判别器结构；可与 LSGAN 训练目标组合。
- [[方向/AI语音/模型/AuK|AuK]]：已有语音模型实例，VAE 训练配方明确使用 LS-GAN。
- [[方向/AI语音/知识/基础概念/Vocoder（声码器）|Vocoder]]：LSGAN 可作为声码器输出头的对抗训练目标之一。

## 5. 关键来源

- [Least Squares Generative Adversarial Networks（arXiv:1611.04076）](https://arxiv.org/abs/1611.04076)
  - 内容定位：提出 LSGAN 的最小二乘判别/生成目标，并讨论梯度消失、训练稳定性和 Pearson $χ^2$ 散度联系。
  - 用途：确认 LSGAN 的定义、目标函数和理论边界。
  - 核验日期：2026-09-22

## 6. 待验证

- [ ] 核对 AuK 官方实现中的标签设定、判别器输出范围和各 adversarial loss 权重。
- [ ] 在同一 vocoder/codec 配方下，对比 LSGAN、hinge loss 与 logistic GAN 的稳定性、听感和伪影。

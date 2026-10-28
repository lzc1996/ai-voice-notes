---
title: Tweedie（Tweedie 公式）
类型: 概念
相关主题:
  - 扩散模型
  - 生成式语音增强
aliases:
  - Tweedie 公式
  - Tweedie's Formula
  - Tweedie's formula
  - Tweedie 一步估计
  - Tweedie 去噪估计
tags:
  - 类型/对象
  - 方向/AI语音
  - 主题/扩散模型
---
# Tweedie（Tweedie 公式）

## 1. 身份

`Tweedie`（Tweedie's formula，Tweedie 公式）是统计学的经典恒等式（归功于 M. C. K. Tweedie，Robbins 1956 正式化）：当观测 $y = x + n$、$n \sim \mathcal{N}(0, \sigma^2 I)$ 时，未知信号 $x$ 的后验期望可以直接由边际密度 $p(y)$ 的 score 写出，**无需显式建模先验**：

$$
\mathbb{E}[x \mid y] = y + \sigma^2 \nabla_y \log p(y)
$$

在扩散模型里，它就是「由带噪状态一步估计干净信号」的数学依据——score 网络学的正是 $\nabla_{x_t} \log p_t(x_t)$。

## 2. 在扩散模型里

设 $x_t = \sqrt{\bar{\alpha}_t}\, x_0 + \sqrt{1-\bar{\alpha}_t}\, \varepsilon$（条件方差 $\sigma_t^2 = 1 - \bar{\alpha}_t$），代入 Tweedie 公式得到干净估计：

$$
\hat{x}_0(x_t) = \frac{x_t - \sigma_t^2\, \nabla_{x_t} \log p_t(x_t)}{\sqrt{\bar{\alpha}_t}}
= \frac{x_t - \sqrt{1-\bar{\alpha}_t}\, \varepsilon_\theta(x_t, t)}{\sqrt{\bar{\alpha}_t}}
$$

第二行用了 score 网络与噪声预测的等价关系 $\nabla_{x_t} \log p_t(x_t) \approx -\varepsilon_\theta(x_t, t) / \sqrt{1-\bar{\alpha}_t}$。

这个 $\hat{x}_0$ 估计是扩散采样与引导的共同地基：

- **[[方向/AI语音/知识/基础概念/DDIM（去噪扩散隐式模型）|DDIM]]**：用它重参数化反向步（去噪估计 + 加噪插值）。
- **[[方向/AI语音/知识/生成式语音增强/DPS（扩散后验采样）|DPS]] / ArrayDPS 家族**：把 $\hat{x}_0$ 代入测量算子 $A$ 计算似然梯度——没有 Tweedie 估计，引导项无从下手。

## 3. 待核验

- [ ] 历史归属：Tweedie 于 1940s 提出、Robbins（1956）正式化的具体出处（需查统计史原始文献）。

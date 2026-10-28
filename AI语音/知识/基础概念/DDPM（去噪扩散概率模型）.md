---
title: DDPM（去噪扩散概率模型）
类型: 概念
相关主题:
  - 扩散模型
  - 生成式语音增强
  - 语音统计建模
aliases:
  - DDPM
  - ddpm
  - Denoising Diffusion Probabilistic Models
  - denoising diffusion probabilistic models
  - 去噪扩散概率模型
  - 去噪扩散概率模型（Ho et al. 2020）
tags:
  - 类型/对象
  - 方向/AI语音
  - 主题/扩散模型
  - 主题/生成式语音增强
---
# DDPM（去噪扩散概率模型）

## 1. 身份

`DDPM`（Denoising Diffusion Probabilistic Models）是 Ho、Jain、Abbeel（NeurIPS 2020，arXiv:2006.11239）提出的扩散生成模型基础算法：**前向 $T$ 步逐渐加噪**把数据变成近似高斯分布，**反向学习逐步去噪**以生成数据。语音增强谱系（[[方向/AI语音/模型/SGMSE+|SGMSE+]]、[[方向/AI语音/模型/StoRM|StoRM]]、CDiffuSE、[[方向/AI语音/模型/ArrayDPS|ArrayDPS]] 的 EDM 先验）都建立在这套训练 / 采样框架上。

边界：DDPM 是**无条件生成**的基础算法；SE 里的条件 / 插值扩散（如 SGMSE+ 前向搅向带噪输入 $y$）是它的变体；它与 score-based SDE（Song et al. 2021）是同一族（VP-SDE 的离散化），训练目标可从 [[方向/AI语音/知识/基础概念/Score Matching（分数匹配）]] / denoising score matching 理解；[[方向/AI语音/知识/基础概念/Flow Matching（流匹配）|Flow Matching]] 是其"直线化"后继（确定性 ODE、少步采样）。

## 2. 核心公式

**前向过程**（固定方差调度 $\beta_1, \dots, \beta_T$）：

$$
q(x_t | x_{t-1}) = \mathcal{N}\!\left(x_t;\ \sqrt{1-\beta_t}\, x_{t-1},\ \beta_t I\right)
$$

**闭式边缘分布**（任意步直接得到）：

$$
q(x_t | x_0) = \mathcal{N}\!\left(x_t;\ \sqrt{\bar{\alpha}_t}\, x_0,\ (1-\bar{\alpha}_t) I\right), \qquad
\bar{\alpha}_t = \prod_{s=1}^{t} (1 - \beta_s)
$$

**训练目标**（噪声预测参数化，化简后的负 ELBO）：

$$
L_{\text{simple}} = \mathbb{E}_{t, x_0, \varepsilon}\left[\, \left\| \varepsilon - \varepsilon_\theta\!\left(\sqrt{\bar{\alpha}_t}\, x_0 + \sqrt{1-\bar{\alpha}_t}\, \varepsilon,\ t\right) \right\|^2 \,\right]
$$

$\varepsilon_\theta$ 通常为 U-Net（带时间嵌入）；等价于每步预测注入的噪声 $\varepsilon$。

**反向采样**（每步去噪 + 加新噪声）：

$$
x_{t-1} = \frac{1}{\sqrt{\alpha_t}}\left(x_t - \frac{\beta_t}{\sqrt{1-\bar{\alpha}_t}}\, \varepsilon_\theta(x_t, t)\right) + \sigma_t z, \qquad
\alpha_t = 1 - \beta_t
$$

$\sigma_t^2$ 取后验方差 $\tilde{\beta}_t$（随机采样）或 $\beta_t$；$z = 0$ 时为 [[方向/AI语音/知识/基础概念/DDIM（去噪扩散隐式模型）|DDIM]] 确定性采样（可几十步）。

## 3. 关键实现细节

- **典型配置**：$T = 1000$ 步、线性 $\beta$ 调度（$10^{-4} \to 0.02$）、U-Net + 时间嵌入。
- **与连续时间 SDE 等价**：DDPM 是 VP-SDE 的离散化；**EDM**（Karras et al. 2022）是重调超参的连续时间形式——语音侧（如 [[方向/AI语音/模型/ArrayDPS|ArrayDPS]]）多直接用 EDM 框架。
- **成本**：1000 步采样（或 [[方向/AI语音/知识/基础概念/DDIM（去噪扩散隐式模型）|DDIM]] 几十步）——语音增强里被 FM / 少步方法替代的根本原因。

## 4. 在语音增强里的角色

- **[[方向/AI语音/模型/SGMSE+|SGMSE+]] / CDiffuSE**：DDPM 框架 + 条件 / 插值前向（搅向带噪 $y$）——生成式 SE 的开创。
- **[[方向/AI语音/模型/StoRM|StoRM]]**：判别式粗估 + 截断扩散（中段注噪再生细节）。
- **[[方向/AI语音/模型/ArrayDPS|ArrayDPS]]**：EDM 单通道扩散先验 + [[方向/AI语音/知识/生成式语音增强/DPS（扩散后验采样）|DPS]] 引导。
- **让位趋势**：FlowSE / DiT-Flow（[[方向/AI语音/知识/基础概念/Flow Matching（流匹配）|FM]]）5–20 步替代 1000 步（见 [[方向/AI语音/知识/生成式语音增强/扩散模型与语音|扩散模型与语音]]）。

## 5. 相关对象

- [[方向/AI语音/知识/生成式语音增强/扩散模型与语音|扩散模型与语音]]：扩散谱系全景（DDPM → SGMSE+ → StoRM → DiTSE → FM 让位）。
- [[方向/AI语音/知识/基础概念/Score Matching（分数匹配）]]：解释 denoising score matching 与 score-based SDE 的训练目标。
- [[方向/AI语音/知识/基础概念/Flow Matching（流匹配）|Flow Matching]]：直线化后继，确定性少步。
- [[方向/AI语音/知识/基础概念/Time-Varying Variance（时变方差）|Time-Varying Variance]]：$\beta_t$ 调度是时变方差的实例（时间轴 = 扩散步）。
- [[方向/AI语音/模型/SGMSE+|SGMSE+]]、[[方向/AI语音/模型/StoRM|StoRM]]、[[方向/AI语音/模型/ArrayDPS|ArrayDPS]]、[[方向/AI语音/知识/生成式语音增强/DPS（扩散后验采样）|DPS]]：语音侧应用。
- [[方向/AI语音/知识/基础概念/ODE（常微分方程）|ODE]]：概率流 ODE 视角的桥梁。

## 6. 待验证

- 语音增强里 DDPM 型（离散、$\beta$ 调度）vs EDM 型（连续、$f/g$ 参数化）实现的实证差距。
- DDIM 少步采样在语音增强上的质量底线与伪影形态。

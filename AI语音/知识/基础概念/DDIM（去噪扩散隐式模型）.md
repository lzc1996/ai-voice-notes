---
title: DDIM（去噪扩散隐式模型）
类型: 概念
相关主题:
  - 扩散模型
  - 生成式语音增强
  - 语音统计建模
aliases:
  - DDIM
  - ddim
  - Denoising Diffusion Implicit Models
  - denoising diffusion implicit models
  - 去噪扩散隐式模型
  - 确定性扩散采样
tags:
  - 类型/对象
  - 方向/AI语音
  - 主题/扩散模型
  - 主题/生成式语音增强
---
# DDIM（去噪扩散隐式模型）

## 1. 身份

`DDIM`（Denoising Diffusion Implicit Models）是 Song、Meng、Ermon（ICLR 2021，arXiv:2010.02502）提出的[[方向/AI语音/知识/基础概念/DDPM（去噪扩散概率模型）|DDPM]] 采样加速方法：把反向过程重表述为**非马尔可夫（隐式）**家族——**保持与 DDPM 相同的边缘分布 $q(x_t|x_0)$（训练目标不变），但反向可以完全确定性**，几十步即高质量采样，并提供 $z \to x$ 的确定性映射。

边界：DDIM 不是新的训练算法——**直接复用 DDPM 预训练权重**；它是采样算法族（$\sigma_t$ 参数控制随机性）；确定性 DDIM 是概率流 ODE 的离散化特例（见 [[方向/AI语音/知识/基础概念/ODE（常微分方程）|ODE]]）。

## 2. 核心公式

同一训练目标下的通用采样公式：

$$
x_{t-1} = \sqrt{\bar{\alpha}_{t-1}}\, \hat{x}_0(x_t) + \sqrt{1 - \bar{\alpha}_{t-1} - \sigma_t^2}\, \varepsilon_\theta(x_t, t) + \sigma_t z
$$

其中 $\hat{x}_0$ 是 [[方向/AI语音/知识/基础概念/Tweedie（Tweedie 公式）|Tweedie 一步估计]]：

$$
\hat{x}_0(x_t) = \frac{x_t - \sqrt{1 - \bar{\alpha}_t}\, \varepsilon_\theta(x_t, t)}{\sqrt{\bar{\alpha}_t}}
$$

- **$\sigma_t = 0$**：DDIM——完全确定性；给定初始噪声 $x_T$ 即唯一输出（"隐式"）。
- **$\sigma_t^2 = \tilde{\beta}_t$**（DDPM 后验方差）：退化为随机 DDPM 采样。
- **$\eta \in [0,1]$** 插值两者（$\sigma_t = \eta \sqrt{\tilde{\beta}_t}$）。

## 3. 关键性质

- **复用训练**：与 DDPM 相同的边缘分布 → 训练目标完全一样，**预训练 DDPM 模型直接可用于 DDIM 采样**。
- **少步采样**：~50 步（vs 1000 步）质量基本无损；更少步数质量下降，低 SNR 段（$t$ 接近 $T$）最先受损。
- **确定性映射**：$z$ 的线性插值对应内容的平滑插值（语义插值）；DDIM inversion 支持图像 / 音频编辑。
- **ODE 视角**：确定性 DDIM 即 VP 概率流 ODE 的欧拉离散化——与 Flow Matching 的确定性 ODE 路线同源（后者更进一步，直接学直线轨迹）。

## 4. 在语音增强里的角色

- 扩散 SE（[[方向/AI语音/模型/SGMSE+|SGMSE+]] / [[方向/AI语音/模型/StoRM|StoRM]] 系）加速采样的常用选择：1000 步 → 几十步。
- 与 [[方向/AI语音/知识/生成式语音增强/DPS（扩散后验采样）|DPS]] 类引导结合：少步 + 似然引导。
- 2025+ 被 [[方向/AI语音/知识/基础概念/Flow Matching（流匹配）|FM]] 取代：FM 直接学确定性直线轨迹，天然 5–20 步。

## 5. 相关对象

- [[方向/AI语音/知识/基础概念/DDPM（去噪扩散概率模型）|DDPM]]：被加速的原始算法（训练目标相同）。
- [[方向/AI语音/知识/基础概念/Flow Matching（流匹配）|Flow Matching]]：确定性 ODE 的更进一步（直线传输、更少步）。
- [[方向/AI语音/知识/基础概念/ODE（常微分方程）|ODE]]：概率流 ODE 视角。
- [[方向/AI语音/模型/SGMSE+|SGMSE+]]、[[方向/AI语音/模型/StoRM|StoRM]]：语音侧少步采样使用场景。
- [[方向/AI语音/知识/生成式语音增强/扩散模型与语音|扩散模型与语音]]：扩散谱系全景。

## 6. 待验证

- DDIM 少步在语音增强具体模型（SGMSE+ / StoRM）上的步数-质量曲线（与 FM 的 5–20 步对比）。
- DDIM inversion 在语音编辑（内容 / 说话人插值）上的应用现状。

---
title: Score Matching（分数匹配）
类型: 概念
发表时间: 2005-04
时间依据: Hyvärinen JMLR 论文 published 4/05
相关主题:
  - 生成模型
  - 扩散模型
  - 非归一化模型
相关任务:
  - 语音增强
aliases:
  - Score Matching
  - score matching
  - 分数匹配
  - Denoising Score Matching
  - denoising score matching
  - DSM
  - Score-based Generative Modeling
  - score-based diffusion
tags:
  - 类型/对象
  - 方向/AI语音
  - 主题/生成模型
  - 主题/扩散模型
---

# Score Matching（分数匹配）

## 1. 身份

`Score Matching`（分数匹配）是一种训练概率模型的方法：不直接拟合归一化后的密度 $p_\theta(x)$，而是让模型的 **score field** 匹配数据分布的 score field。

这里的 score 通常指对样本求梯度：

$$
s_\theta(x)=\nabla_x \log p_\theta(x)
$$

直觉：模型不必知道“这个点的概率是多少”，只要知道“从这个点往哪个方向走，数据概率会变大”。这就是 score-based diffusion / SDE 生成模型的核心。

边界：Score Matching 不是“评分器”、不是 reward model，也不是 LLM-as-judge。它的 score 是概率密度的梯度场。

## 2. 和 Score Function 的关系

经典统计学里的 [[知识wiki/数学/得分函数 (Score Function)|Score Function]] 常指对参数求梯度：$\nabla_\theta \log p_\theta(x)$。生成模型里的 score matching 更常用 **Stein score / data score** 口径，对样本求梯度：$\nabla_x \log p(x)$。

这两个都叫 score，但梯度对象不同：一个问“参数怎么改”，一个问“样本往哪里移动更像数据”。

## 3. 最小公式

原始 score matching 目标是匹配模型 score 和真实数据 score：

$$
J(\theta)=\frac{1}{2}\mathbb{E}_{p_{data}(x)}\left[\left\|\nabla_x\log p_\theta(x)-\nabla_x\log p_{data}(x)\right\|^2\right]
$$

难点是 $\nabla_x\log p_{data}(x)$ 不可直接得到。Hyvärinen 的关键结果是可用分部积分把数据 score 消掉，得到只依赖模型 score 的等价目标（差一个常数）：

$$
J(\theta)=\mathbb{E}_{p_{data}(x)}\left[\frac{1}{2}\|\psi_\theta(x)\|^2+\nabla_x\cdot\psi_\theta(x)\right]+C,
\qquad \psi_\theta(x)=\nabla_x\log p_\theta(x)
$$

因此它适合训练非归一化模型 / energy-based model，因为归一化常数在 $\nabla_x\log p_\theta(x)$ 里会消失。

## 4. Denoising Score Matching

现代扩散模型更常用 `Denoising Score Matching`：先给干净样本加噪，再训练模型预测加噪分布的 score。严格等价关系见 [[方向/AI语音/知识/基础概念/Vincent Theorem（去噪分数匹配等价定理）]]：DSM 匹配条件 corruption score，但优化上等价于匹配加噪边缘分布 $q_\sigma(\tilde{x})$ 的 score。

若 $\tilde{x}=x+\sigma z$，$z\sim\mathcal{N}(0,I)$，高斯扰动核的条件 score 为：

$$
\nabla_{\tilde{x}}\log p_\sigma(\tilde{x}|x)=-\frac{\tilde{x}-x}{\sigma^2}
$$

训练目标可写成：

$$
\mathcal{L}_{DSM}=\mathbb{E}_{x,\tilde{x},\sigma}\left[\left\|s_\theta(\tilde{x},\sigma)+\frac{\tilde{x}-x}{\sigma^2}\right\|^2\right]
$$

在 SDE / 语音增强论文里常写成 $x_t=\mu(t)+\sigma(t)z$，目标是让 $s_\theta(x_t,t)$ 逼近 $-z/\sigma(t)$。

## 5. 和扩散 / Flow Matching 的区别

- **一句话区别**：score 是“概率密度往哪边更高”的梯度，flow 是“样本沿生成路径该往哪边走”的速度。前者问 $\nabla_x\log p_t(x)$，后者问 $v_t(x)$。
- **Score-based diffusion / SDE**：学的是 score field，反向 SDE 或 Langevin 动力学用这个梯度场从噪声走回数据。
- **DDPM 噪声预测**：预测噪声 $\epsilon$ 与预测 score 在高斯加噪设定下可互相换算，因此和 DSM 是近亲。
- **[[方向/AI语音/知识/基础概念/Flow Matching（流匹配）|Flow Matching]]**：学的是 velocity field（速度场），不是 score field；推理更偏 ODE 搬运，常用于少步生成。
- **判别式增强**：直接学 noisy → clean 映射，不显式学习概率梯度场。

更具体地说：

- **score field**：局部量，表示当前噪声级 $t$ 下，样本 $x_t$ 朝哪个方向移动会让 log-density 变大；常接反向 SDE / Langevin，所以采样可以是随机、多步的。
- **flow / velocity field**：路径量，表示在预设概率路径上，样本 $x_t$ 下一瞬间应该移动多少；常接 ODE，所以更容易做确定性、少步采样。
- **二者可有关联但不等价**：概率流 ODE 可由 score-based SDE 推出一个 velocity，但 Flow Matching 通常直接监督 velocity，不需要先学 score 再换算。

在语音增强里，score 路线更像“沿概率梯度逐步去噪”，代表 [[方向/AI语音/模型/SGMSE+|SGMSE+]]；flow 路线更像“沿一条从退化表示到干净表示的路径搬运”，代表 [[方向/AI语音/模型/DiT-Flow|DiT-Flow]] / FlowSE / Stream.FM。

## 6. 在语音增强里的位置

- [[方向/AI语音/模型/SGMSE+|SGMSE+]]：复数 STFT 域 score-based SDE，训练目标是 denoising score matching。
- [[方向/AI语音/模型/AMDM-SE|AMDM-SE]] / [[方向/AI语音/模型/mSGMSE|mSGMSE]]：把 score-based 扩散扩展到多通道 / 阵列语音增强。
- [[方向/AI语音/模型/StoRM|StoRM]]：把判别式粗估和 denoising score matching 结合，降低纯扩散不稳定性。
- [[方向/AI语音/模型/PGUSE|PGUSE]]：生成分支属于 score-based diffusion / denoising objective。

工程判断：score matching 路线的优势是生成式先验强、能恢复强退化细节；代价是采样慢、NFE 高、低 SNR 下可能出现 hallucination / vocalizing，因此实时系统常转向少步 Flow Matching、蒸馏或判别式 + 生成式混合。

## 7. 关键来源

- [Estimation of Non-Normalized Statistical Models by Score Matching](https://www.jmlr.org/beta/papers/v6/hyvarinen05a.html)
  - 内容定位：Hyvärinen 原始 score matching 论文，提出用 log-density 梯度匹配训练非归一化统计模型。
  - 发表时间：2005-04（JMLR published 4/05）
  - 用途：建立 score matching 的原始定义。
  - 核验日期：2026-08-28
- [A Connection Between Score Matching and Denoising Autoencoders](https://direct.mit.edu/neco/article-abstract/23/7/1661/7677/A-Connection-Between-Score-Matching-and-Denoising)
  - 内容定位：Vincent 论文，连接 denoising autoencoder 与 score matching，奠定 denoising score matching 口径。
  - 发表时间：2011-07（Neural Computation 23(7)；PubMed 期刊口径为 2011 Jul）
  - 用途：理解 DSM 为什么可用加噪-去噪目标训练 score。
  - 核验日期：2026-08-28
- [Generative Modeling by Estimating Gradients of the Data Distribution](https://arxiv.org/abs/1907.05600)
  - 内容定位：Song & Ermon 的 NCSN / annealed Langevin 生成模型论文。
  - 发表时间：2019-07-12（arXiv v1；NeurIPS 2019）
  - 用途：把 score matching 推入现代生成模型。
  - 核验日期：2026-08-28
- [Score-Based Generative Modeling through Stochastic Differential Equations](https://arxiv.org/abs/2011.13456)
  - 内容定位：SDE 统一框架，说明反向 SDE 依赖时变 score field，并统一 score-based generative modeling 与 diffusion probabilistic modeling。
  - 发表时间：2020-11-26（arXiv v1；ICLR 2021）
  - 用途：理解 score matching、DDPM、SDE/ODE 采样之间的关系。
  - 核验日期：2026-08-28

## 8. 相关对象

- [[知识wiki/数学/得分函数 (Score Function)]]：score 的数学来源，但要区分对参数求梯度与对样本求梯度。
- [[方向/AI语音/知识/基础概念/Vincent Theorem（去噪分数匹配等价定理）]]：DSM 与加噪边缘分布 score matching 的等价定理。
- [[方向/AI语音/知识/基础概念/DDPM（去噪扩散概率模型）]]：DDPM 噪声预测和 DSM 同属高斯加噪去噪家族。
- [[方向/AI语音/知识/基础概念/NCSN++（噪声条件分数网络）]]：常见 score network 骨干。
- [[方向/AI语音/知识/基础概念/Flow Matching（流匹配）]]：从学 score field 转向学 velocity field 的相邻路线。
- [[方向/AI语音/知识/生成式语音增强/扩散模型与语音]]：score matching 在语音增强谱系中的入口。
- [[方向/AI语音/评估/NFE（函数评估次数）]]：score-based 采样成本的重要指标。

## 9. 待验证

- Score matching、denoising diffusion、rectified flow / flow matching 在语音增强里的统一高斯路径视角是否需要单独拆一页。
- 多通道 score matching 是否应该和阵列几何 / 空间一致性约束绑定记录。

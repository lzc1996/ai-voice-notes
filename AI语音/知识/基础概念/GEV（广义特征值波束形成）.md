---
title: GEV（广义特征值波束形成）
类型: 概念
相关主题:
  - 阵列信号
  - 多通道增强
  - 波束形成
aliases:
  - GEV
  - gev
  - GEV beamformer
  - Generalized Eigenvalue beamformer
  - Generalized Eigenvalue Decomposition beamformer
  - 广义特征值波束形成
  - 广义特征值分解波束形成
tags:
  - 类型/对象
  - 方向/AI语音
  - 主题/阵列信号
  - 主题/多通道增强
  - 主题/波束形成
---
# GEV（广义特征值波束形成）

## 1. 身份

`GEV` beamformer（Generalized Eigenvalue Decomposition，广义特征值波束形成，Warsitz & Haeb-Umbach，IEEE TASLP 2007）以**最大化输出 SNR** 为准则的波束形成器：权重取 $\Phi_{nn}^{-1}\Phi_{ss}$ 的**主特征向量**——不需要 steering vector / RTF，直接从语音 / 噪声协方差得到。代价是输出**增益缩放有歧义**（特征向量长度任意），需额外归一化。

边界：与 [[方向/AI语音/知识/基础概念/MVDR（最小方差无失真响应）|MVDR]] 是"同一最优方向、不同缩放"的关系；它无显式无失真约束、也无 [[方向/AI语音/知识/基础概念/WNG（白噪声增益）|WNG]] 控制（低 WNG 风险）。

## 2. 核心公式

**输出 SNR 瑞利商**：

$$
\text{SNR}_{\text{out}}(\mathbf{w}) = \frac{\mathbf{w}^H \Phi_{ss}\, \mathbf{w}}{\mathbf{w}^H \Phi_{nn}\, \mathbf{w}}
$$

**最大化 → 广义特征问题**：

$$
\Phi_{ss}\, \mathbf{w} = \lambda\, \Phi_{nn}\, \mathbf{w}
\quad\Rightarrow\quad
\mathbf{w}_{\text{GEV}} = \text{eigvec}_{\max}\!\left(\Phi_{nn}^{-1}\Phi_{ss}\right)
$$

**与 MVDR 的关系**：同一瑞利商的最优方向——$\mathbf{w}_{\text{GEV}}$ 与 $\mathbf{w}_{\text{MVDR}}$ 方向一致；区别只在缩放。MVDR 用无失真约束 $\mathbf{w}^H\mathbf{d}=1$ 固定缩放；GEV 需事后归一化（按参考麦增益、或 $\|\mathbf{w}^H\mathbf{d}\|=1$、或接后置滤波）。

**mask-based GEV**：用 [[方向/AI语音/知识/基础概念/TF Mask（时频掩码）|TF Mask]] 分别估 $\Phi_{ss}$（语音掩码加权）与 $\Phi_{nn}$（噪声掩码加权），再取广义主特征向量——[[方向/AI语音/模型/ESPnet|ESPnet]] 系 mask-based beamforming 的常用选项，无几何假设。

## 3. 使用注意

- **缩放歧义**：GEV 输出幅度不确定——通常接后置 Wiener 滤波（GEV + post-filter 是经典组合）或按参考通道归一。
- **鲁棒性**：无 WNG 约束，协方差病态时输出尖锐、自噪声放大——低 SNR / 阵列失配下不如加对角加载的 MVDR 稳。
- **无需几何**：相比 MVDR（需 steering vector / RTF），GEV 纯统计、天然 array-agnostic——但代价是丢掉无失真保证。

## 4. 相关对象

- [[方向/AI语音/知识/基础概念/MVDR（最小方差无失真响应）|MVDR]]：同一最优方向、不同缩放；有显式无失真约束。
- [[方向/AI语音/知识/基础概念/SCM（空间协方差矩阵）|SCM]]：$\Phi_{ss}$ / $\Phi_{nn}$ 是输入统计。
- [[方向/AI语音/知识/基础概念/TF Mask（时频掩码）|TF Mask]]：mask-based GEV 的协方差估计路线。
- [[方向/AI语音/知识/基础概念/WNG（白噪声增益）|WNG]]：GEV 无 WNG 控制的鲁棒性风险。
- [[方向/AI语音/知识/基础概念/DP-MWF（保向多通道维纳滤波）|DP-MWF]]：MMSE 准则的保向变体（对比谱系）。

## 5. 待验证

- mask-based GEV vs mask-based MVDR 在固定会议阵列上的实证对比（ESPnet 系实现）。
- GEV + 后置滤波组合在现代挑战赛前端中的使用率与收益。

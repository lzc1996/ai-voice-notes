---
title: Array Steering Matrix（阵列导向矩阵）
类型: 概念
aliases:
  - Array Steering Matrix
  - Steering Matrix
  - Array Manifold Matrix
  - 阵列流形矩阵
tags:
  - 类型/对象
  - 方向/AI语音
  - 主题/阵列信号
---

# Array Steering Matrix（阵列导向矩阵）

## 1. 身份

阵列导向矩阵是在给定频率和一组候选声源方向后，将各方向对应的 [[方向/AI语音/知识/基础概念/steering vector（导向矢量）|steering vector]] 按列排列得到的矩阵。每列描述一个候选方向在全部麦克风上的理想复响应，因此它也可作为方向扫描或空间稀疏重建的阵列字典。

## 2. 表示

设阵列有 $M$ 个麦克风，候选方向网格为 $Theta = \{\theta_1,\ldots,\theta_K\}$，$\mathbf{a}(f,\theta_k)\in\mathbb{C}^{M}$ 是频率 $f$、方向 $\theta_k$ 对应的导向矢量，则

$$
\mathbf{A}(f,\Theta)=\begin{bmatrix}\mathbf{a}(f,\theta_1)&\cdots&\mathbf{a}(f,\theta_K)\end{bmatrix}\in\mathbb{C}^{M\times K}.
$$

行对应麦克风，列对应候选方向；方向网格或频率改变时，矩阵也随之改变。若采用窄带远场点源模型，多源观测可写为

$$
\mathbf{x}(f,t)=\mathbf{A}(f,\Theta)\mathbf{s}(f,t)+\mathbf{n}(f,t),
$$

其中 $\mathbf{s}(f,t)$ 是各候选方向上的源系数，$\mathbf{n}(f,t)$ 是噪声。此模型要求所用导向矢量与阵列几何、坐标约定及传播假设相符。

## 3. 用途与边界

- **方向扫描**：逐列将阵列观测与候选导向矢量比较，形成空间谱或方向得分；MUSIC 等方法也会在候选方向上评估导向矢量与噪声子空间的关系。
- **空间字典**：稀疏 DOA 估计可把 $\mathbf{A}(f,\Theta)$ 作为候选方向字典；角度网格决定字典覆盖范围与离散化误差。
- **不是波束权重矩阵**：$\mathbf{A}$ 描述阵列对候选来波的响应；波束权重描述如何组合麦克风通道。二者维度或方向常相反，使用时应检查约定。
- **模型边界**：自由场远场模型通常只按方向索引；近场模型需要把距离并入候选网格，混响环境则可能需要用 RTF 或实测传递函数替代理想平面波响应。

## 4. 相关对象

- [[方向/AI语音/知识/基础概念/steering vector（导向矢量）]]：矩阵的每一列是一个候选方向的导向矢量。
- [[方向/AI语音/知识/基础概念/DOA（到达方向）]]：方向估计可通过扫描候选字典或空间谱完成。
- [[方向/AI语音/知识/基础概念/Beamforming（波束形成）]]：波束形成器利用目标导向矢量或其候选集合构造空间响应。

## 5. 待验证

- 不同论文中 `steering matrix`、`array manifold matrix` 与 `steering dictionary` 的具体用法是否一致；引用时应以原文的矩阵维度和索引定义为准。
- 当前目标阵列的方向网格、麦克风坐标系、参考通道和相位符号约定。

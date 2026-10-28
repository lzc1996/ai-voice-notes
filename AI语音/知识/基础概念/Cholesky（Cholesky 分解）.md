---
title: Cholesky（Cholesky 分解）
类型: 概念
相关主题:
  - 阵列信号
  - 多通道增强
  - 数值线性代数
aliases:
  - Cholesky
  - cholesky
  - Cholesky Decomposition
  - Cholesky 分解
  - Cholesky 因子
  - 乔列斯基分解
tags:
  - 类型/对象
  - 方向/AI语音
  - 主题/阵列信号
  - 主题/多通道增强
  - 主题/数值线性代数
---
# Cholesky（Cholesky 分解）

## 1. 身份

`Cholesky` 分解是把 Hermitian **半正定**矩阵分解为下三角与其共轭转置之积的标准工具：

$$
\mathbf{A} = \mathbf{L}\mathbf{L}^H
$$

$\mathbf{L}$ 为下三角（$\mathbf{A}$ 正定时唯一，$\mathbf{L}$ 对角取正实值）。在阵列信号处理里，它服务于两件事：**协方差矩阵的正定参数化**（神经估计）与**数值稳定计算**（求逆 / 求解）。

边界：只适用于 Hermitian 半正定矩阵（[[方向/AI语音/知识/基础概念/SCM（空间协方差矩阵）|SCM]] 天然满足）；与特征分解同为"分解"但用途不同——Cholesky 更快（约 $O(M^3/3)$ 前向替换，特征分解的一半）且直接利用正定性。

## 2. 在语音增强里的角色

- **[[方向/AI语音/模型/Direction-Preserving MIMO|Direction-Preserving MIMO]]（OnlineSpatialNet）**：直接回归噪声协方差的**尺度归一化 Cholesky 因子**——参数化天然保证 Hermitian 正定；对角线用 softplus 约束为正实值、非对角为自由复值；这是"绕过 mask 凑协方差"路线的结构保证。
- **[[方向/AI语音/模型/NICE-Beam|NICE-Beam]]**：结构变体之一（Rank-1 / Cholesky / Arbitrary）——Cholesky 变体强制输出协方差正定。
- **数值稳定**：MVDR / WPE 的矩阵求逆与线性求解可用 Cholesky（正定时）替代一般 LU——更稳、更快、无需条件数处理中的对称性假设。
- **判别式 / 生成式共用**：无论协方差来自掩码加权、残差估计还是神经回归，Cholesky 是"保证正定 + 高效求解"的公共手段。

## 3. 与相关概念的关系

- **特征分解**：$A = U\Lambda U^H$——更通用（可处理半正定与负特征值诊断），代价更高；Cholesky 是"已知正定"前提下的廉价分解。
- **LDL^H 变体**：免开方分解，数值上对近奇异矩阵更稳。
- **参数化视角**：神经输出任意复数矩阵 → 经 Cholesky 结构（+ 对角正性激活）映射为合法协方差——比"输出后投影到半正定锥"更简单。

## 4. 相关对象

- [[方向/AI语音/知识/基础概念/SCM（空间协方差矩阵）|SCM]]：被参数化 / 被分解的对象。
- [[方向/AI语音/模型/Direction-Preserving MIMO|Direction-Preserving MIMO]]：Cholesky 因子回归的代表。
- [[方向/AI语音/模型/NICE-Beam|NICE-Beam]]：Cholesky 结构变体。
- [[方向/AI语音/知识/基础概念/MVDR（最小方差无失真响应）|MVDR]] / [[方向/AI语音/知识/基础概念/WPE（加权预测误差）|WPE]]：求逆 / 求解的数值用户。

## 5. 待验证

- Cholesky 参数化（DP-MIMO）vs 逆矩阵参数化（NICE-Beam）在端侧实现的数值差异。
- 近奇异协方差下 Cholesky 与对角加载的配合实践。

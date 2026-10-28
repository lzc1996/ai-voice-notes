---
title: SCM（空间协方差矩阵）
类型: 概念
相关主题:
  - 阵列信号
  - 多通道增强
  - 波束形成
aliases:
  - SCM
  - scm
  - Spatial Covariance Matrix
  - spatial covariance matrix
  - 空间协方差矩阵
  - 噪声空间协方差
  - 空间协方差
tags:
  - 类型/对象
  - 方向/AI语音
  - 主题/阵列信号
  - 主题/多通道增强
  - 主题/波束形成
---
# SCM（空间协方差矩阵）

## 1. 身份

`SCM`（Spatial Covariance Matrix，空间协方差矩阵）是频域多通道信号的二阶统计描述：每个频点 $f$ 上，$M$ 个麦克风观测向量 $\mathbf{x}(f) \in \mathbb{C}^M$ 的自相关矩阵：

$$
\Phi(f) = E\left[\, \mathbf{x}(f)\, \mathbf{x}^H(f) \,\right] \in \mathbb{C}^{M \times M}
$$

它编码了"各通道信号在频点 $f$ 上的能量与**通道间相关性**（相位 / 幅度关系）"——波束形成、掩码估计、神经协方差估计与生成式精修的公共数据底座（[[方向/AI语音/知识/基础概念/MVDR（最小方差无失真响应）|MVDR]] 的 $\Phi_{nn}$、[[方向/AI语音/模型/ArrayDPS-Refine|ArrayDPS]] 的噪声 SCM 都是它的实例）。

边界：SCM 是**统计量**（频域二阶矩），不是算法、不是波束形成器本身；它描述空间相关性，而 [[方向/AI语音/知识/基础概念/IPD（通道间相位差）|IPD]] / [[方向/AI语音/知识/基础概念/ILD（双耳声级差）|ILD]] 是它的低维投影（相位差 / 幅度差特征）。

## 2. 基本性质

- **Hermitian 且半正定**：$\Phi^H = \Phi$，$\Phi \succeq 0$——所有特征值非负。
- **逐频点定义**：每个 $f$ 一个 $M \times M$ 矩阵，频率间独立。
- **不相关源的加性**：观测 $\mathbf{x} = \mathbf{s} + \mathbf{n}$（语音与噪声不相关）时 $\Phi_{xx} = \Phi_{ss} + \Phi_{nn}$。
- **自由场点源的秩**：单一点源在自由场时 $\Phi_{ss} = \sigma_s^2\, \mathbf{d}\mathbf{d}^H$（秩 1，$\mathbf{d}$ 为 [[方向/AI语音/知识/基础概念/steering vector（导向矢量）|steering vector]]）——加性噪声 / 混响使其满秩。

## 3. 估计方法

| 方法 | 公式 / 说明 |
|---|---|
| 样本平均 | $\hat{\Phi} = \frac{1}{T}\sum_t \mathbf{x}(t)\mathbf{x}^H(t)$，朴素时间平均 |
| mask 加权 | $\hat{\Phi}_{nn} = \frac{\sum_t m_n(t)\,\mathbf{x}(t)\mathbf{x}^H(t)}{\sum_t m_n(t)}$（[[方向/AI语音/知识/基础概念/TF Mask（时频掩码）]] 选噪声帧） |
| 残差估计 | $\hat{\Phi}_{nn} = \frac{1}{T}\sum_t (\mathbf{x}_t - \hat{\mathbf{s}}_t)(\mathbf{x}_t - \hat{\mathbf{s}}_t)^H$（判别式输出定残差，ArrayDPS-Refine 路线） |
| 神经直接估计 | NICE 直接回归 $\hat{\Phi}_{nn}^{-1}$；OnlineSpatialNet 回归尺度归一化 [[方向/AI语音/知识/基础概念/Cholesky（Cholesky 分解）]] 因子（绕过 mask） |

## 4. 在算法里的角色

- **[[方向/AI语音/知识/基础概念/MVDR（最小方差无失真响应）|MVDR]]**：$\mathbf{w} = \Phi_{nn}^{-1}\mathbf{d}/(\mathbf{d}^H\Phi_{nn}^{-1}\mathbf{d})$——噪声 SCM 是滤波器核心；估计不准 → 目标抵消。
- **鲁棒性**：SCM 病态时加对角加载（$\Phi + \epsilon I$，即 [[方向/AI语音/知识/基础概念/WNG（白噪声增益）|WNG]] 约束）；条件数是数值健康度指标。
- **生成式精修**：ArrayDPS-Refine / Uni-ArrayDPS 把估计的 $\hat{\Phi}_{nn}^{-1}$ 代入 [[方向/AI语音/知识/生成式语音增强/DPS（扩散后验采样）|DPS]] 似然——比白噪声假设更贴合彩色 / 残留噪声（见 Uni-ArrayDPS 的 $\nabla \log p \approx -\frac{1}{2}\nabla (\hat{\mathbf{s}}-\mathbf{x})^H \hat{\Phi}_{nn}^{-1}(\hat{\mathbf{s}}-\mathbf{x})$）。
- **神经协方差估计谱系**：mask-based（NICE）→ 结构直接回归（OnlineSpatialNet）→ 生成式引导（SCM 定似然）——SCM 的角色从"输入统计"演变为"可学习 / 可引导量"。

## 5. 相关对象

- [[方向/AI语音/知识/基础概念/MVDR（最小方差无失真响应）|MVDR]]：噪声 SCM 是其闭式解的核心输入。
- [[方向/AI语音/知识/基础概念/Beamforming（波束形成）|Beamforming]]：GEV / LCMV / MWF 等均由 SCM 驱动。
- [[方向/AI语音/知识/基础概念/steering vector（导向矢量）|steering vector]]：秩 1 SCM 的方向因子。
- [[方向/AI语音/知识/基础概念/ATF（阵列传递函数）|ATF]]：单源时 $\Phi_{ss}=\sigma_s^2\mathbf{h}\mathbf{h}^H$，ATF 是 SCM 的一阶因子、SCM 是它的二阶封装。
- [[方向/AI语音/知识/基础概念/TF Mask（时频掩码）|TF Mask]]：mask 加权 SCM 估计路线。
- [[方向/AI语音/模型/NICE-Beam|NICE-Beam]]：神经估计逆 SCM 的代表。
- [[方向/AI语音/模型/Direction-Preserving MIMO|Direction-Preserving MIMO]]：神经估计 Cholesky 因子（保正定）。
- [[方向/AI语音/模型/ArrayDPS-Refine|ArrayDPS-Refine]] / [[方向/AI语音/模型/Uni-ArrayDPS|Uni-ArrayDPS]]：残差 SCM 定 DPS 似然项。
- [[方向/AI语音/知识/基础概念/WNG（白噪声增益）|WNG]]：对角加载与条件数相关的鲁棒性刻度。

## 6. 待验证

- 固定会议阵列上，mask 加权 vs 残差估计 vs 神经直接估计三种 SCM 口径的精度差距（余弦相似度口径，参照 DP-MIMO 的 0.93）。
- SCM 估计误差（几何失配 / 短窗）对下游 MVDR 与 DPS 精修的敏感性排序。

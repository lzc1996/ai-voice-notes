---
title: DP-MWF（保向多通道维纳滤波）
类型: 概念
相关主题:
  - 阵列信号
  - 多通道增强
  - 空间音频
aliases:
  - DP-MWF
  - dp-mwf
  - Direction-Preserving MIMO Wiener Filter
  - Direction-Preserving Wiener Filter
  - 保向 MIMO Wiener 滤波器
  - 保向多通道维纳滤波
  - 保向维纳滤波
tags:
  - 类型/对象
  - 方向/AI语音
  - 主题/阵列信号
  - 主题/多通道增强
  - 主题/空间音频
---
# DP-MWF（保向多通道维纳滤波）

## 1. 身份

`DP-MWF`（Direction-Preserving MIMO Wiener Filter，保向多输入多输出维纳滤波）是 [[方向/AI语音/模型/Direction-Preserving MIMO|Direction-Preserving MIMO]]（Deppisch 2026）的输出滤波器：**参数化 Wiener 滤波与单位阵的信号相关混合**，输出多通道增强信号，同时保留目标语音与残余噪声的**空间特征值结构**——方位线索（[[方向/AI语音/知识/基础概念/ITD（耳间时间差）|ITD]] / [[方向/AI语音/知识/基础概念/ILD（双耳声级差）|ILD]]）不塌缩。

边界：它是 **MIMO Wiener 滤波器的保向变体**——不是单通道后置滤波、不是 [[方向/AI语音/知识/基础概念/MVDR（最小方差无失真响应）|MVDR]]（约束无失真、单通道输出）；对比经典 MWF（MMSE 最优但不保空间结构），DP-MWF 的关键是"抑噪的同时保留方向"。

## 2. 核心机制

- **经典 MIMO MWF**（MMSE 意义）：$\mathbf{W} = \Phi_{ss}(\Phi_{ss} + \Phi_{nn})^{-1}$，输出 $\hat{\mathbf{s}} = \mathbf{W}\mathbf{x}$——最优抑噪但输出空间结构被压缩。
- **DP-MWF 的保向混合**：参数化 Wiener 滤波与**单位阵** $\mathbf{I}$ 的信号相关混合——单位阵分量保留观测的空间结构，Wiener 分量做抑噪，混合参数控制"保向 vs 抑噪"权衡。
- **输入协方差**：来自 OnlineSpatialNet 估计的尺度归一化 [[方向/AI语音/知识/基础概念/Cholesky（Cholesky 分解）|Cholesky]] 因子（[[方向/AI语音/知识/基础概念/SCM（空间协方差矩阵）|SCM]] 神经估计路线）。
- **效果**：目标与残余噪声的特征值结构都保留 → 输出仍是多通道，SRP 分析确认目标方向增强后仍在。

## 3. 与相关滤波器的对比

| 滤波器 | 准则 | 输出形态 | 空间保真 |
|---|---|---|---|
| MVDR | 约束无失真、最小噪声功率 | 单通道 | 无（输出即塌缩） |
| [[方向/AI语音/知识/基础概念/GEV（广义特征值波束形成）]] | 最大化输出 SNR | 单通道 | 无（需额外归一化） |
| MWF | MMSE 最优 | 多通道 | 不保方向结构 |
| **DP-MWF** | MMSE + 保向混合 | 多通道 | **保留目标 / 残余噪声方向** |

## 4. 相关对象

- [[方向/AI语音/模型/Direction-Preserving MIMO|Direction-Preserving MIMO]]：宿主方法（OnlineSpatialNet + DP-MWF）。
- [[方向/AI语音/知识/基础概念/MVDR（最小方差无失真响应）|MVDR]] / [[方向/AI语音/知识/基础概念/Beamforming（波束形成）|Beamforming]]：单通道输出的对照谱系。
- [[方向/AI语音/知识/基础概念/SCM（空间协方差矩阵）|SCM]]、[[方向/AI语音/知识/基础概念/Cholesky（Cholesky 分解）|Cholesky]]：滤波器输入的协方差表示。
- [[方向/AI语音/知识/基础概念/ITD（耳间时间差）|ITD]] / [[方向/AI语音/知识/基础概念/ILD（双耳声级差）|ILD]]：保向效果的评估维度。

## 5. 待验证

- DP-MWF 与 oracle 上限（11.01 dB）的差距来源（协方差估计误差 vs 混合参数）。
- 与双耳助听场景（[[方向/AI语音/评估/ECHI（助听对话增强）|ECHI]] 类）的适配与主观方位感评测。

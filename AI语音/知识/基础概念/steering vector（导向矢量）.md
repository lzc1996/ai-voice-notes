---
title: steering vector（导向矢量）
类型: 概念
相关主题:
  - 阵列信号
  - 多通道增强
aliases:
  - Steering Vector
  - steering vector
  - array manifold vector
  - Array Manifold Vector
  - 导向矢量
  - 阵列导向矢量
  - 方向矢量
tags:
  - 类型/对象
  - 方向/AI语音
  - 主题/阵列信号
  - 主题/多通道增强
---
# steering vector（导向矢量）

## 1. 身份

导向矢量是一个复数向量，用数学语言精确描述了“从某个特定方向传来的平面前波，到达阵列中各个传感器（麦克风/天线）时的相位延迟和幅度变化”。
`steering vector`（导向矢量，也叫 array manifold vector）是 [[方向/AI语音/知识/基础概念/Array Audio Signal（阵列音频信号）|麦克风阵列]] 对来自方向 $\theta$ 的平面波的**理想复响应向量**：每个元素描述该麦克风对单位幅值信号的幅度与相位延迟。它是阵列几何的模型化描述，是 [[方向/AI语音/知识/基础概念/Beamforming（波束形成）|beamforming]]、[[方向/AI语音/知识/基础概念/DOA（到达方向）|DOA]] 估计和空间协方差建模的共同基础构件。

均匀线阵（ULA，间距 $d$）的最小形式：

$$
\mathbf{a}(f, \theta) = \left[ 1, \; e^{-j 2\pi f d \sin\theta / c}, \; \ldots, \; e^{-j 2\pi f (M-1) d \sin\theta / c} \right]^{T}
$$

其中 $M$ 是麦克风数，$c$ 是声速。每个频点一个向量；方向变了、频率变了，steering vector 都不同。

## 2. 边界

- **steering vector ≠ 波束权重**：权重 `w` 由 steering vector 派生——DAS 是 `w = a / M`，[[方向/AI语音/知识/基础概念/MVDR（最小方差无失真响应）|MVDR]] 是 `w = R⁻¹a / (aᴴR⁻¹a)`。steering vector 描述"阵列对来波的响应"，权重是"施加到通道上的滤波系数"。
- **steering vector ≠ RTF**：steering vector 是理想平面波模型（幅度一致、纯相位延迟）；RTF 是实测 / 估计的通道间传递函数比，含幅度差异和多径，混响下更贴近真实。两者的上位概念是 [[方向/AI语音/知识/基础概念/ATF（阵列传递函数）|ATF]]（含混响与器件响应的真实传递函数），steering vector 只是它的自由场特例。
- **steering vector ≠ IPD**：[[方向/AI语音/知识/基础概念/IPD（通道间相位差）|IPD]] 是两通道的经验相位差特征；steering vector 是覆盖全部通道的模型向量，两者互为"数据特征 vs 模型先验"。

## 3. 为什么重要

- **beamforming 的构建块**：DAS 对齐、MVDR 无失真约束、GSC 阻塞矩阵都以 steering vector 为目标条件。
- **DOA 估计的核心**：MUSIC / ESPRIT 类方法靠 steering vector 张成的信号子空间扫描方向。
- **协方差建模**：目标信号的空间协方差可写为 $\mathbf{R}_s = \sigma_s^2 \mathbf{a}\mathbf{a}^H$，是 mask-based beamformer 的模型基础。
- **注入阵列先验**：已知几何时，steering vector 把物理知识显式带进神经前端；当几何未知或不可信时，DNN 改为隐式学习空间滤波（见 [[方向/AI语音/知识/调研与地图/Array Speech Enhancement Frontier（阵列语音增强前沿调研）|阵列增强前沿]]：手工空间特征正被可学习空间滤波取代）。

## 4. 使用注意

- **steering / RTF mismatch 很敏感**：阵列几何错、通道顺序反、采样不同步、说话人移动，都会让目标约束失配（[[方向/AI语音/知识/基础概念/MVDR（最小方差无失真响应）|MVDR]] 笔记的"无失真"前提即此）。
- **空间混叠**：$d > \lambda/2$ 时高频方向出现歧义，一个 steering vector 可能对应多个方向。
- **增益一致性假设**：steering vector 假定各麦克风幅度响应一致，通道增益差异需先校准。
- **远场假设**：平面波只依赖方向；近场要加入距离参数（球面波 steering vector）。
- **混响下失效**：反射声破坏纯相位延迟模型，实测 RTF 或神经 mask 估计更稳。

## 5. 关键来源

- [Microphone Array Signal Processing and Deep Learning for Speech Enhancement](https://arxiv.org/abs/2501.07215)
  - 内容定位：麦克风阵列信号处理与深度学习语音增强综述，覆盖 beamforming 与空间特征。
  - 用途：确认 steering vector 在 DOA、beamforming、多通道 SE 地图中的位置。
  - 核验日期：2026-08-04
- [Advances in Microphone Array Processing and Multichannel Speech Enhancement](https://arxiv.org/abs/2502.09037)
  - 内容定位：麦克风阵列处理与多通道语音增强综述。
  - 用途：把 steering vector 与 RTF、协方差估计、神经 beamformer 串成一条线。
  - 核验日期：2026-08-04

## 6. 相关对象

- [[方向/AI语音/知识/基础概念/Array Audio Signal（阵列音频信号）|Array Audio Signal]]：steering vector 描述阵列对来波的响应。
- [[方向/AI语音/知识/基础概念/Array Steering Matrix（阵列导向矩阵）]]：将多个候选方向的 steering vectors 按列堆叠成阵列字典。
- [[方向/AI语音/知识/基础概念/Beamforming（波束形成）|Beamforming]]：DAS / MVDR / GSC 都以 steering vector 为构建块。
- [[方向/AI语音/知识/基础概念/MVDR（最小方差无失真响应）|MVDR]]：无失真约束直接依赖目标 steering vector / RTF，mismatch 敏感。
- [[方向/AI语音/知识/基础概念/DOA（到达方向）|DOA]]：MUSIC / ESPRIT 等方向估计靠 steering vector 扫描。
- [[方向/AI语音/知识/基础概念/IPD（通道间相位差）|IPD]]：经验相位特征 vs 模型化导向矢量，神经前端中互为补充。

## 7. 待验证

- 已知几何 vs 未知几何时，显式 steering vector 约束和 DNN 隐式空间滤波的性能差距（呼应 [[方向/AI语音/知识/调研与地图/Array Speech Enhancement Frontier（阵列语音增强前沿调研）|阵列增强前沿]] 的"泛化性"主线）。
- 目标设备（耳机 / 会议宝 / 远场麦克风）近场场景下球面波 steering vector 的必要性。
- 是否需要继续拆 TDOA / ITD、RTF estimation、transfer function。

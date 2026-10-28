---
title: WNG（白噪声增益）
类型: 概念
相关主题:
  - 阵列信号
  - 多通道增强
aliases:
  - WNG
  - wng
  - White Noise Gain
  - white noise gain
  - 白噪声增益
  - 白噪声增益系数
tags:
  - 类型/对象
  - 方向/AI语音
  - 主题/阵列信号
  - 主题/多通道增强
---

# WNG（白噪声增益）

## 1. 身份

`WNG`（White Noise Gain，白噪声增益）是[[方向/AI语音/知识/基础概念/Beamforming（波束形成）|波束形成器]]对**传感器自噪声**（通道间不相关的白噪声）的抑制比，是衡量 beamformer **鲁棒性**的核心指标：WNG 越高，对麦克风增益失配、位置误差、校准误差等"白噪声型"失配越不敏感。

频域定义：

$$
\text{WNG}(f) = \frac{\left| \mathbf{w}^H(f)\, \mathbf{a}(f) \right|^2}{\mathbf{w}^H(f)\, \mathbf{w}(f)}
$$

其中 $\mathbf{w}(f)$ 是波束权重，$\mathbf{a}(f)$ 是目标方向 [[方向/AI语音/知识/基础概念/steering vector（导向矢量）|steering vector]]。对满足无失真约束 $\mathbf{w}^H \mathbf{a} = 1$ 的 beamformer（DAS、[[方向/AI语音/知识/基础概念/MVDR（最小方差无失真响应）|MVDR]]、GSC 主路径），化简为：

$$
\text{WNG}(f) = \frac{1}{\| \mathbf{w}(f) \|^2}
$$

## 2. 边界

- **WNG ≠ 指向性指数（DI）**：DI 衡量对**扩散噪声场**（环境噪声、混响尾）的抑制，WNG 衡量对**自噪声 / 失配**的抑制——两者是 beamformer 的两个正交评估轴，且经典地互相权衡。
- **WNG ≠ SNR 增益**：SNR 增益看目标 vs 环境噪声比，WNG 只看传感器噪声通道。
- **WNG ≠ MVDR**：MVDR 是约束优化准则；WNG 是评价/约束指标（MVDR 可加 WNG 约束或 diagonal loading 控制 WNG）。

## 3. 为什么重要

- **鲁棒性刻度**：低 WNG 的 beamformer 在真实阵列上会放大自噪声、被增益失配毁掉——"纸上指向性好、上机就翻车"通常就是 WNG 塌了。
- **物理边界**：小阵列、低频段电尺寸小，超指向性 beamformer 指向性越强 WNG 越低——这是阵列物理的硬权衡，不能两头都要。
- **工程手段**：diagonal loading 本质是 WNG 约束；数据驱动方向出现"频变 WNG 阈值"——2026 的 [[方向/AI语音/模型/WNG-MVDR|WNG-MVDR]] 用双分支网络联合估噪声掩码与频变 WNG 阈值，微分化鲁棒 MVDR 层做自适应鲁棒性-指向性权衡，阵列失配/自噪声下优于固定 WNG。

## 4. 使用注意

- **必须频域看**：WNG 随频率变化，低频最差；只看宽带均值会掩盖低频脆弱。
- **评估口径**：设计 / 对比 beamformer 时同时报 WNG 和 DI（或 SNR 增益），缺一个都会误判。
- **对角加载**：实际协方差病态时加小对角正则（diagonal loading）提升 WNG 与数值稳定性（见 [[方向/AI语音/知识/基础概念/MVDR（最小方差无失真响应）|MVDR]] 使用注意）。

## 5. 关键来源

- [Microphone Array Beamforming - MathWorks](https://www.mathworks.com/help/audio/ug/microphone-array-beamforming.html)
  - 内容定位：麦克风阵列 beamforming 示例，覆盖 DAS / MVDR 与鲁棒性讨论。
  - 用途：确认 WNG 作为 beamformer 鲁棒性指标的基础口径。
  - 核验日期：2026-08-04
- [数据驱动 WNG-MVDR（arXiv:2606.24137）](https://arxiv.org/abs/2606.24137)（见 [[方向/AI语音/模型/WNG-MVDR|WNG-MVDR]] 笔记）
  - 内容定位：双分支网络联合估时频噪声掩码与频变 WNG 阈值，微分化鲁棒 MVDR。
  - 用途：WNG 自适应权衡的前沿例子（vault [[方向/AI语音/知识/调研与地图/Array Speech Enhancement Frontier（阵列语音增强前沿调研）|阵列增强前沿]] 条目）。
  - 核验日期：2026-08-06

## 6. 相关对象

- [[方向/AI语音/知识/基础概念/Beamforming（波束形成）|Beamforming]]：WNG 是 beamformer 的鲁棒性评估指标。
- [[方向/AI语音/知识/基础概念/MVDR（最小方差无失真响应）|MVDR]]：无失真约束下的 WNG 即 $1/\|\mathbf{w}\|^2$；diagonal loading 是控制 WNG 的工程手段。
- [[方向/AI语音/知识/基础概念/steering vector（导向矢量）|steering vector]]：WNG 定义依赖目标方向导向矢量。
- [[方向/AI语音/知识/调研与地图/Array Speech Enhancement Frontier（阵列语音增强前沿调研）|阵列语音增强前沿调研]]：2026 数据驱动 WNG-MVDR 条目。

## 7. 待验证

- 目标硬件阵列在目标频段的 WNG 频响与失配容忍度（与 MVDR 笔记的 diagonal loading 待验证项合并）。
- 数据驱动频变 WNG 阈值 vs 固定 WNG + diagonal loading，在真实阵列失配下的差距。

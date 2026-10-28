---
title: SIR（Signal-to-Interference Ratio，信号干扰比）
类型: 概念
发表时间: 2006-07
时间依据: BSS_eval 指标族原始论文（Vincent et al., IEEE TASLP）发表时间
aliases:
  - Signal-to-Interference Ratio
  - 信号干扰比
  - SI-SIR
tags:
  - 类型/对象
  - 方向/AI语音
  - 任务/语音增强
  - 指标/信号保真
---

# SIR（Signal-to-Interference Ratio，信号干扰比）

## 0. 背景

**问题现场**：分离/增强系统需要把"其他声源的泄漏"从背景噪声和算法伪影中单独拆出来度量，才能定位干扰抑制做得好不好。

**切入点**：[[方向/AI语音/评估/BSS_eval（盲源分离评估工具箱）|BSS_eval]] 把估计信号正交分解为目标/干扰/噪声/伪影四成分，SIR 专取干扰项与目标成分的能量比。

## 1. 身份

SIR 是 [[方向/AI语音/评估/BSS_eval（盲源分离评估工具箱）|BSS_eval]] 指标族中的**干扰抑制指标**：把分离系统的估计输出 $\hat{s}$ 正交分解后，只度量"目标成分"对"其他说话人/声源泄漏成分"的能量比，单位 dB，越高越好。

边界：SIR 只管**干扰源**（interference），不管背景噪声（归 SNR）和算法伪影（归 SAR）；三个成分合在一起才是 [[SI-SDR|SDR]]。它是侵入式指标，需要样本级对齐的干净目标参考与干扰参考。

## 2. 计算口径

BSS_eval 把估计信号分解为四个成分：

$$
\hat{s}=s_{target}+e_{interf}+e_{noise}+e_{artif}
$$

其中 $s_{target}$ 是 $\hat{s}$ 在真实目标源上的投影成分，$e_{interf}$ 是来自其他声源（干扰说话人）的泄漏，$e_{noise}$ 是背景噪声残差，$e_{artif}$ 是算法自身引入的伪影（如音乐噪声）。SIR 只取干扰项：

$$
\mathrm{SIR}=10\log_{10}\frac{\lVert s_{target}\rVert^2}{\lVert e_{interf}\rVert^2}
$$

配套口径：$\mathrm{SNR}=10\log_{10}\frac{\lVert s_{target}+e_{interf}\rVert^2}{\lVert e_{noise}\rVert^2}$，$\mathrm{SAR}=10\log_{10}\frac{\lVert s_{target}+e_{interf}+e_{noise}\rVert^2}{\lVert e_{artif}\rVert^2}$。

**SI-SIR**（scale-invariant 变体）：先做尺度不变投影再算干扰比，对全局增益不敏感；[[方向/AI语音/模型/SGMSE+|SGMSE+]] 等模型报告的就是 SI-SIR。

## 3. 用途

- **语音分离**的标准指标：WSJ0-2mix 等基准上 SDR/SIR/SAR 联合报告，衡量"把干扰说话人压掉多少"。
- 数据侧：[[方向/AI语音/知识/基础概念/Mix（语音混合）|语音混合]]时用 SIR 控制目标与干扰说话人的混合能量比（区别于控制噪声的 SNR）。
- 波束成形/阵列场景常以 SIR 设定仿真条件（如 [[方向/AI语音/模型/WNG-MVDR|WNG-MVDR]] 的干扰源 SIR 0–10 dB）。

## 4. 使用注意

- **SIR 高不等于干净**：只压干扰源不管伪影，激进掩蔽可以把 SIR 刷高同时产生严重音乐噪声——必须与 SAR / SDR 联合看。
- **增强（降噪）任务里 SIR 不是主角**：单说话人降噪没有"干扰说话人"成分，应看 SNR/SDR 或感知指标；SIR 的主场是分离与会话场景。
- 与感知质量无必然联系：和 [[SI-SDR]] 一样是纯信号层度量，听感判断仍需 PESQ / MOS 类指标。
- 跨论文比较先确认口径：SIR vs SI-SIR、是否零均值化、分解窗口长度都会影响数值。

## 5. 相关对象

- [[SI-SDR]]：同一族的尺度不变总失真指标（目标 vs 全部非目标成分）。
- [[方向/AI语音/评估/语音增强评估指标体系|语音增强评估指标体系]]：指标地图与指标分裂讨论。
- [[方向/AI语音/知识/基础概念/SS（语音分离）|语音分离]]：SIR 的主要任务场景。
- [[方向/AI语音/知识/基础概念/Mix（语音混合）|语音混合]]：SIR 作为数据混合配方的控制量。

## 6. 关键来源

- [Vincent, Gribonval, Févotte, "Performance measurement in blind audio source separation", IEEE TASLP 2006](https://ieeexplore.ieee.org/document/1643671)
  - 内容定位：SDR / SIR / SAR / SNR 分解口径的原始定义（BSS_eval）。
  - 用途：SIR 定义的权威依据。
  - 核验日期：2026-09-30
- [Le Roux et al., "SDR half-baked or well done?" (ICASSP 2019)](https://arxiv.org/abs/1811.02508)
  - 内容定位：SDR/SI-SDR 口径澄清；同样适用于理解 SIR 的尺度敏感性问题。
  - 用途：SI-SIR 变体的动机。
  - 核验日期：2026-09-30

## 7. 待验证

- 多说话人场景下 SIR 与下游 ASR（cpWER）收益的相关性强弱。
- 本地分离实验统一用 SIR 还是 SI-SIR 口径，避免与论文数字混比。

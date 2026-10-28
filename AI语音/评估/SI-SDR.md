---
title: SI-SDR
类型: 概念
发表时间: 2018-11-06
时间依据: SDR/SI-SDR 口径澄清论文 arXiv 首次提交日
aliases:
  - SI-SNR
  - Scale-Invariant Signal-to-Distortion Ratio
  - 尺度不变信噪比
  - SI-SDRi
  - SI-SNRi
  - 尺度不变信噪比提升
  - Scale-Invariant SDR Improvement
tags:
  - 类型/对象
  - 方向/AI语音
  - 任务/语音增强
  - 指标/信号保真
---

# SI-SDR

## 0. 背景

**问题现场**：语音分离/增强需要与感知无关、可微、可直接优化的波形保真度度量；传统 SDR 对全局增益缩放敏感，同一结果的分数会因音量差异漂移。

**切入点**：把估计信号投影到参考方向，取目标成分与正交残差的能量比——对全局增益不敏感（scale-invariant），后成为 Conv-TasNet 时代分离系统的标准训练目标与指标。

## 1. 身份

`SI-SDR`（Scale-Invariant Signal-to-Distortion Ratio，也称 SI-SNR）是**侵入式**波形域保真度指标：把估计信号分解为"参考方向上的投影"（目标成分）和正交残差（失真成分），取二者能量比的对数。

- 单位 dB，越高越好；干净复现可到 30+ dB，语音增强常见区间 10–25 dB。
- 对全局增益（音量大小）不敏感，这是"scale-invariant"的含义。

## 2. 用途

- 语音分离（Conv-TasNet 时代的标准训练目标和指标）、语音增强、去混响的波形保真度衡量。
- 常作为训练损失（负 SI-SDR loss）直接优化。

## 3. 计算口径

- 需要样本级对齐的干净参考；计算前通常做零均值化。
- 是纯信号层面度量，**完全不含感知模型**：两个 SI-SDR 相同的信号听感可能天差地别。

设零均值后的参考为 $s$，模型输出为 $\hat{s}$：

$$
s_{target}=\frac{\langle \hat{s},s\rangle}{\lVert s\rVert^2}s
$$

$$
e_{noise}=\hat{s}-s_{target}
$$

$$
\mathrm{SI\mbox{-}SDR}=10\log_{10}\frac{\lVert s_{target}\rVert^2}{\lVert e_{noise}\rVert^2}
$$

## 4. SI-SDRi（增益口径）

$$\mathrm{SI\text{-}SDRi}=\mathrm{SI\text{-}SDR}_{\text{enhanced}}-\mathrm{SI\text{-}SDR}_{\text{input}}$$

同一测试集、同一干净参考下逐句相减再平均，单位仍是 dB。它回答的是「**相对未处理混合改善了多少**」，而不是「输出有多干净」。

- **SI-SDR** = 绝对刻度（输出 vs 干净参考）；**SI-SDRi** = 增益（输出 vs 输入）。两者恒差一个「输入混合的 SI-SDR」。
- 领域惯例分叉：分离文献（Conv-TasNet 系，如 [[方向/AI语音/模型/UniArray]]）常只报 SI-SDRi；增强文献（DNS / URGENT 系，如 [[方向/AI语音/模型/Geo-DConv]]）常只报绝对 SI-SDR。**两个传统各说各话，是这个指标最容易被误读的地方。**
- 同族还有 BSS-Eval 的 `SDRi` / `SIRi`（[[BSS_eval（盲源分离评估工具箱）]]）：思路相同但底座是 SDR，与 SI-SDRi 数值不可互换。

### 4.1. 四个坑

1. **不能跨数据集比**：增益的起跑线是输入混合的 SNR，混合越差、增益越容易做大。同一模型换一个更低 SNR 的混合，SI-SDRi 会上升而输出并没有更好。
2. **不能与绝对 SI-SDR 同列**：UniArray 报 13.46 是增益，DeFTAN-AA 的 9.4 是绝对值；换算到同一口径后 DeFTAN-AA 的增益是 17.2、反而更高——**同一批数字换口径会翻转排序**（换算示例见 [[方向/AI语音/知识/调研与地图/Array-Agnostic SE SOTA（阵列可变语音增强SOTA调研）]] §2.1.1）。
3. **增益为正不等于输出可用**：输入 −6.35 dB 时 +11.1 dB 增益只到 4.77 dB；而基线在未见阵列上可以是 −15.08 dB（增益为负且远低于输入）。只看增益会掩盖「输出已经不可用」。
4. **天花板效应**：输入 SI-SDR 越高可提升空间越小，增益天然惩罚已经很强的基线；低 SNR 条件下的大增益不代表方法更好。

### 4.2. 报告规范

三件套同时给：**未处理输入的 SI-SDR**、**增强输出的绝对 SI-SDR**、**两者之差**。只给增益时读者无法判断输出落在哪一档；只给绝对值时读者无法知道相对输入改善了多少。

## 5. 使用注意

- SI-SDR 高 ≠ 好听：过平滑的输出 SI-SDR 高但发闷；生成式重建的输出 SI-SDR 低但可能更自然。
- 生成式增强在 URGENT 2025 上 SDR 低至 −12 dB（内容被重新生成），与主观 MOS 第一并存——典型指标分裂案例，见 [[语音增强评估指标体系]]。
- 与 [[PESQ]]、[[STOI 与 ESTOI|ESTOI]] 联合报告才能避免误判。

## 6. 相关对象

- [[方向/AI语音增强/README|AI 语音增强]]
- [[语音增强评估指标体系]]
- [[SE SOTA（语音增强模型表现）]]
- [[方向/AI语音/知识/调研与地图/Array-Agnostic SE SOTA（阵列可变语音增强SOTA调研）]]：阵列无关各方案的 SI-SDR 绝对值与 SI-SDRi 增益分列对照。

## 7. 关键资源

- [Le Roux et al., SDR half-baked or well done? (ICASSP 2019)](https://arxiv.org/abs/1811.02508)
  - 内容定位：SI-SDR 的定义澄清与推荐口径。核验日期：2026-07-28

## 8. 待验证

- 语音增强场景 SI-SDR 与下游 ASR 收益的相关性强弱（分离场景较强，增强场景存疑）。
- 本库其余模型页（[[方向/AI语音/模型/AmbiDrop]]、[[方向/AI语音/模型/TF-GridNet]]、[[方向/AI语音/模型/CrossNet]]、[[方向/AI语音/模型/CI-Spatial]] 等）中 SI-SDR 与 SI-SDRi 是否都标了口径——2026-10-28 只核过调研页与 UniArray / DeFTAN-AA / AmbiDrop 三页。

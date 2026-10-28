---
title: TAC（变换-平均-拼接）
类型: 概念
相关主题:
  - 阵列信号
  - 多通道增强
aliases:
  - TAC
  - Transform-Average-Concatenate
  - transform-average-concatenate
  - 变换-平均-拼接
tags:
  - 类型/对象
  - 方向/AI语音
  - 主题/阵列信号
  - 主题/阵列无关
---
# TAC（变换-平均-拼接）

## 0. 背景

**1) 问题现场**：2019 年前后的神经波束形成（neural beamformer）有两条主流 pipeline——

- **逐通道预分离 + 传统波束形成**（掩码估计 + [[方向/AI语音/知识/基础概念/MVDR（最小方差无失真响应）|MVDR]]/多通道维纳滤波）：波束形成是优化问题，天然对麦克风数量与排列不变，是各种配置的通用解法；但预分离独立训练、滤波器估计是与预分离结果脱钩的确定操作——预分离失败时整个系统输出不可靠。
- **端到端直接估计波束滤波器**（时域或频域）：全可训练，去掉了优化式滤波估计；但标准网络层只能产生固定维度输出，因此必须已知麦数，且输出各段到通道的分配隐含固定了通道索引——麦克风换个排列顺序，输出就完全变样。

**2) [[方向/AI语音/模型/FaSNet（滤波求和网络）|FaSNet]] 的折衷与遗留缺口**：FaSNet 用两阶段设计（参考麦预分离 + 逐对跨通道特征估计其余通道滤波器）兼顾了两条 pipeline，对麦数/排列不变且端到端可训练；但第一阶段的表现直接拖累第二阶段，且**逐对（pair-wise）特征使滤波估计时无法利用全部麦克风做全局决策**——在各麦声学特性差异很大的 ad-hoc 阵列上尤其不稳。

**3) TAC 的切入点**：把通道当作**集合**处理——共享变换（参数共享 → 通道数任意）、平均池化（置换不变）、拼接回各通道（恢复逐通道输出、支撑全局决策），三个简单操作补上 FaSNet 缺的"全局视野"，同时保留两条旧 pipeline 各自的优势。

## 1. 身份

`TAC`（Transform-Average-Concatenate，变换-平均-拼接）是 Luo、Chen、Mesgarani、Yoshioka（Columbia + Microsoft，ICASSP 2020，arXiv:1910.14104）提出的**跨通道处理范式**：让网络对麦克风**数量与排列顺序都不变**（permutation & number invariant），同时能利用全部通道信息做全局决策。它是 ad-hoc 阵列 / array-agnostic 深度学习的基础构件，原始载体是时域神经波束形成器 [[方向/AI语音/模型/FaSNet（滤波求和网络）|FaSNet]]；代码开源（github.com/yluo42/TAC）。

## 2. 核心公式

对每个通道 $i$、时刻 $j$ 的特征 $\mathbf{z}_{i,j}$，TAC 模块三步（$P,R,S$ 均为共享的 FC+PReLU 子模块）：

$$\mathbf{f}_{i,j}=P(\mathbf{z}_{i,j}) \qquad \text{（逐通道共享变换）}$$

$$\hat{\mathbf{f}}_{j}=R\Big(\frac{1}{N}\sum_{i=1}^{N}\mathbf{f}_{i,j}\Big) \qquad\text{（跨通道平均 = 全局池化）}$$

$$\hat{\mathbf{g}}_{i,j}=S\big([\mathbf{f}_{i,j};\hat{\mathbf{f}}_{j}]\big),\qquad \hat{\mathbf{z}}_{i,j}=\mathbf{z}_{i,j}+\hat{\mathbf{g}}_{i,j} \qquad\text{（拼接回各通道 + 残差）}$$

不变性的来源：平均池化对集合无序 → 换通道顺序输出不变；逐通道共享参数 → 通道数任意。拼接步让输出维度匹配输入，残差连接使 TAC 可插入任意深层架构而不增加优化难度。

理论亲缘：TAC 即 Deep Sets（Zaheer et al., NeurIPS 2017）意义的**集合函数**——共享变换 + 置换不变池化是该族函数的通用构造。

## 3. 性质与表现

原始论文（FaSNet + DPRNN 块，LibriSpeech 2-mix 噪声混响，SI-SNRi）的关键结论：

- **ad-hoc 阵列（2/4/6 麦）**：单阶段 FaSNet+TAC 平均 9.8 / 11.2 / 11.7 dB，对照无 TAC 两阶段 FaSNet 5.9 / 6.9 / 7.3 dB；**只有带 TAC 的配置保证"麦越多越好"**（无 TAC 的 TasNet 系加麦不涨）。
- **固定几何 6 麦圆阵**：加 TAC 后 10.0 → 11.3 dB——TAC 对固定阵列也涨点，作者的解释是 **TAC 无需显式几何特征也能学到几何相关信息**。
- 高重叠率区间增益最大；小窗（4 ms）下 TAC 弥补了 FaSNet 原文"小窗掉点"的问题——论文据此论证原问题不是频率分辨率不足，而是滤波估计缺全局处理。

## 4. 局限与后续改进

- **全局平均压缩通道特有信息**：平均池化把各通道细节压成一个全局向量——这正是 [[方向/AI语音/模型/REDnet|REDnet]] 的 RE（逐麦递归累积、线性复杂度、保留通道增量）对 TAC 式聚合的主要批评与替代方案；REnet 在 TAC 数据集同算力下一致优于 TAC（SI-SDRi 19.3/22.3/23.4 vs 17.8/20.2/20.9，含未见几何 18.5 vs 17.1）。
- 平均是固定的等权聚合，不看内容；后续有把平均换成注意力/通道注意力的变体（如 [[方向/AI语音/模型/UniArray|UniArray]] 对照中的 VarArray+CA）。
- TAC 只保证对**通道**不变，不处理说话人数可变；也不含几何/坐标信息（那走 [[方向/AI语音/模型/Geo-DConv|Geo-DConv]] 式显式条件化路线）。

## 5. 在库内的使用谱系

- [[方向/AI语音/模型/VarArray|VarArray]]：TAC 穿插在 Conformer block 间的变体（A、B 各半维拼接），几何无关 CSS 的核心层。
- [[方向/AI语音/模型/REDnet|REDnet]]：RE 的对照与批评对象；REnet 实验直接比 TAC。
- [[方向/AI语音/模型/SFB-NSE|SFB-NSE]]：基线系 "DPRNN+TAC"。
- [[方向/AI语音/模型/UniArray|UniArray]]：其空间字典嵌入被定位为 TAC/注意力交替的替代。

## 6. 关键来源

- [End-to-end microphone permutation and number invariant multi-channel speech separation（arXiv:1910.14104）](https://arxiv.org/abs/1910.14104)
  - 内容定位：TAC 原始论文（v3 2020-03-27，ICASSP 2020，CC BY-NC-SA；全文 HTML 已核），TAC 三步公式、FaSNet 载体、ad-hoc/固定几何全部结果。
  - 用途：本页公式与实验口径的来源；引言（§1）为「背景」节素材（2026-10-21 复核）。
  - 核验日期：2026-10-21
- [yluo42/TAC（GitHub）](https://github.com/yluo42/TAC)
  - 内容定位：论文官方代码与数据生成配置。
  - 用途：复现入口。
  - 核验日期：2026-10-15
- [Deep Sets（Zaheer et al., NeurIPS 2017）](https://arxiv.org/abs/1703.06114)
  - 内容定位：置换不变集合函数的一般理论，TAC 论文自承的理论亲缘。
  - 用途：TAC 不变性构造的理论定位。
  - 核验日期：2026-10-15

## 7. 相关对象

- [[方向/AI语音/知识/基础概念/Array Audio Signal（阵列音频信号）|Array Audio Signal]]：TAC 的输入基础（多通道特征序列）。
- [[方向/AI语音/知识/基础概念/PIT（置换不变训练）|PIT/uPIT]]：另一维度的置换问题——TAC 解决**通道**置换不变，PIT 解决**输出说话人**置换歧义；两者在同一系统里正交共存。
- [[方向/AI语音/知识/技术路线/Array-Agnostic SE（阵列无关语音增强）|Array-Agnostic SE]]：TAC 所属技术路线的基础构件。
- [[方向/AI语音/模型/VarArray|VarArray]]、[[方向/AI语音/模型/REDnet|REDnet]]、[[方向/AI语音/模型/UniArray|UniArray]]：使用/对照/替代 TAC 的模型。

## 8. 待验证

- ~~FaSNet 本身无库内独立笔记~~（已解决 2026-10-21）：已拆出 [[方向/AI语音/模型/FaSNet（滤波求和网络）|FaSNet]] 独立页——引用面已达 10 页，远超"第二处独立使用"的拆页阈值。
- TAC 在非分离任务（增强、TSE）上的迁移表现，库内尚无证据。

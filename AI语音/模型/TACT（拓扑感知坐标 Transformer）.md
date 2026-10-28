---
title: TACT（拓扑感知坐标 Transformer）
类型: 模型组件
发表时间: 2026-07
时间依据: 随 Geo-DConv 论文（arXiv:2607.18658）首次提出
相关任务:
  - 语音增强
  - 多通道增强
aliases:
  - TACT
  - Topology-Aware Coordinate Transformer
  - 拓扑感知坐标 Transformer
tags:
  - 类型/对象
  - 方向/AI语音
  - 任务/多通道增强
  - 主题/阵列信号
---

# TACT（拓扑感知坐标 Transformer）

## 0. 背景

**问题现场**：多通道语音增强希望模型随阵列几何变化生成合适的卷积核，而非绑定固定阵列拓扑。

**TACT 的切入点**：把麦克风坐标当 token 序列过 Transformer Encoder，输出系数矩阵让基卷积核线性组合成随几何变化的动态核，并以逐点傅里叶 PE + 置换等变 MHSA 保证对麦克风编号顺序严格不敏感。

## 1. 身份

`TACT`（Topology-Aware Coordinate Transformer）是 [[方向/AI语音/模型/Geo-DConv|Geo-DConv]]（上海交大，Interspeech 2026）内部的**坐标→动态卷积权重生成器**：把一组麦克风坐标当作 token 序列过 Transformer Encoder，输出变换系数矩阵 $M$，供基卷积核线性组合成随阵列几何变化的动态卷积核。

边界：TACT 不是独立模型，脱离 Geo-DConv 没有任务定义；它的输入是坐标、输出是权重系数，不接触声学特征本身。

## 2. 核心机制

数据流：坐标矩阵 $G\in\mathbb{R}^{C\times 3}$ →（外部先做傅里叶位置编码）$G_{pe}\in\mathbb{R}^{C\times d_{pe}}$ → 线性投影到 $d_{hidden}$ → $C$ 个 token 进 Transformer Encoder（[[方向/大模型/模型结构/MHA（Multi-Head Attention）|MHSA]] 在麦克风维做全局注意力，建模阵列拓扑）→ 输出线性层投影到基核维数 $b$，得 $M\in\mathbb{R}^{C\times b}$。

**置换等变性**是 TACT 的设计核心：傅里叶 PE 逐点（point-wise）、MHSA 本身置换等变，因此坐标排列 $PG$ 必产生 $PM$，最终保证 $PX\circledast P\mathcal{W}_{dyn}=X\circledast\mathcal{W}_{dyn}$——模型对麦克风编号顺序严格不敏感（论文显式声明并给出推导）。

## 3. 核心公式

$$G^{(0)}=G_{pe}W_{in},\quad W_{in}\in\mathbb{R}^{d_{pe}\times d_{hidden}}$$

$$Q=G^{(l)}W_Q,\quad K=G^{(l)}W_K,\quad V=G^{(l)}W_V,\qquad Z^{(l+1)}=\mathrm{LayerNorm}\big(Z^{(l)}+\mathrm{MHSA}(Q,K,V)\big)$$

$$M=Z^{(L_{layers})}W_{out},\quad W_{out}\in\mathbb{R}^{d_{hidden}\times b}$$

其中 $G^{(l)}$ 为第 $l$ 层坐标 token 表示，$b$ 为 Geo-DConv 基卷积核个数。论文实验设置：$d_{hidden}=64$、4 头、2 层、$b=8$。

## 4. 边界

- 依赖**已知且准确**的麦克风坐标；坐标缺失时 TACT 无输入，整个 Geo-DConv 路线不可用。
- 只对**排列**等变，对阵列的旋转/平移不变性来自使用相对坐标这一输入约定，不是 TACT 结构本身保证。
- 训练最多见 4 麦、泛化到 5/6 麦的实验结论属于 Geo-DConv 系统级结果，TACT 单独的泛化上界未单独消融。

## 5. 关键来源

- [Towards Array-Invariant Speech Enhancement via Geometry-Aware Dynamic Convolution（arXiv:2607.18658）](https://arxiv.org/abs/2607.18658)
  - 内容定位：Geo-DConv 原始论文，§2.3 定义 TACT 结构、公式与置换等变性质。
  - 用途：本组件唯一的定义来源。
  - 核验日期：2026-10-15

## 6. 相关对象

- [[方向/AI语音/模型/Geo-DConv|Geo-DConv]]：TACT 的宿主框架；$M$ 的消费方（基核线性组合生成 $\mathcal{W}_{dyn}$）。
- [[知识wiki/NeRF（神经辐射场）|NeRF]]：TACT 输入侧傅里叶位置编码的来源范式（经 NAF 间接引用）。

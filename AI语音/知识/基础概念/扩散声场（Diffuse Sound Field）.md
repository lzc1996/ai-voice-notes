---
title: 扩散声场（Diffuse Sound Field）
类型: 概念
相关主题:
  - 空间音频
  - 阵列信号
aliases:
  - Diffuse Sound Field
  - diffuse sound field
  - 扩散声场
  - 混响场
  - 非相关平面波叠加
tags:
  - 类型/对象
  - 方向/AI语音
  - 主题/空间音频
  - 主题/阵列信号
---
# 扩散声场（Diffuse Sound Field）

## 1. 身份

`扩散声场`（Diffuse Sound Field，即充分混响场）是一种**统计化的理想声场模型**：声能从所有方向均匀到达场点，且不同方向的来波在统计上互不相关。在阵列信号处理中，它的标准数学实现是——把连续分布的复杂声场**近似为 $Q$ 个互不相关的平面波**（Uncorrelated Plane Waves）的叠加，包含"平面波表达"与"互不相关"两个要点。

物理对应：房间中声波经墙面大量随机反射后形成的晚期混响（见 [[方向/AI语音/知识/基础概念/Reverberation Modeling（混响建模）|Reverberation Modeling]]——晚期混响统计上接近扩散声场）。

## 2. 核心公式

### 2.1. 平面波展开与离散化

单个方向 $\Omega_q$、振幅 $s_q(k)$ 的平面波在 $\mathbf{r}$ 处的声压：

$$p(\mathbf{r},k)=s_q(k)\,e^{-j\mathbf{k}_q\cdot\mathbf{r}}$$

任意无源区域内的连续声场可严格写成全方向平面波的连续积分（平面波展开定理）：

$$p(\mathbf{r},k)=\int_{S^2}s(\Omega,k)\,e^{-j\mathbf{k}(\Omega)\cdot\mathbf{r}}\,d\Omega$$

其中 $s(\Omega,k)$ 是连续复振幅密度。计算上用球面采样网格（Lebedev、equiangular、均分多面体等）取 $Q$ 个均匀方向，把积分离散为求和：

$$p(\mathbf{r},k)\approx\sum_{q=1}^{Q}s_q(k)\,e^{-j\mathbf{k}_q\cdot\mathbf{r}}$$

### 2.2. 互不相关假设：协方差对角化

声源向量 $\boldsymbol{s}(k)=[s_1,\dots,s_Q]^T$ 的协方差 $\mathbf{R}_s=\mathbb{E}[\boldsymbol{s}\boldsymbol{s}^H]$。"互不相关"即

$$\mathbb{E}[s_q\,s_m^*]=0\quad(q\neq m)\;\Rightarrow\;\mathbf{R}_s=\mathrm{diag}(\sigma_1^2,\dots,\sigma_Q^2)$$

再加上**各向同性**（各方向能量相等）即得扩散场的标准形式：

$$\mathbf{R}_s(k)=\sigma_s^2\,\mathbf{I}_Q$$

### 2.3. 空间采样条件

拟合最高 $N$ 阶 [[方向/AI语音/知识/基础概念/Ambisonics（球谐声场）|Ambisonics]] 声场要求

$$Q\ge(N+1)^2$$

$Q$ 足够大（数百量级）且方向均匀时，$\frac{4\pi}{Q}\sum_q$ 高精度逼近 $\int_{S^2}d\Omega$。

## 3. 为什么在推导中如此关键

- **无穷维 → 有限维矩阵运算**：麦克风观测直接写成 $\mathbf{x}(k)=\mathbf{V}(k)\boldsymbol{s}(k)+\mathbf{n}(k)$，$\mathbf{V}\in\mathbb{C}^{M\times Q}$ 为阵列流形矩阵。
- **闭式解的前提**：求二阶矩时 $\boldsymbol{y}^H\mathbb{E}[\boldsymbol{s}\boldsymbol{s}^H]\boldsymbol{y}=\sigma_s^2\|\boldsymbol{y}\|_2^2$，交叉项全部消失；没有不相关假设，目标函数留下无法解析处理的交叉相关项，[[方向/AI语音/知识/基础概念/ASM（Ambisonics 信号匹配编码）|ASM]] 这类 [[算法wiki/Tikhonov Regularization（Tikhonov 正则化）|Tikhonov]] 闭式解就导不出来。完整展开见 ASM 页 §2.1。
- **建模晚期混响/噪声场**：扩散场假设是多通道维纳滤波、MVDR 系波束形成中噪声协方差建模的标准默认。

## 4. 边界与适用性

- **适用**：充分混响房间的晚期混响场；高密度随机散射环境；作为"最坏情况/平均情况"的设计先验。
- **不适用**：[[方向/AI语音/知识/基础概念/近场与远场（近场球面波模型）|近场]]（球面波曲率与 $1/r$ 幅度不均使平面波流形失效）与早期反射主导的场景（强方向性、强相关性）；半消声室；稀疏离散声源场景——此时 $\mathbf{R}_s$ 明显非对角，扩散假设会系统性低估方向性信息。
- 真实混响场只是**近似**扩散：低频模态稀疏、房间不对称都会破坏各向同性。

## 5. 关键来源

- 用户提供综合说明（2026-10-15）：平面波展开、$Q$ 点离散化、互不相关协方差、$Q\ge(N+1)^2$ 采样条件的整理——本页主体框架，教科书级声学内容，未逐条对照一手教材。
- [Ambisonics encoding for arbitrary microphone arrays（Gayer et al., ICASSPW 2024, arXiv:2402.17362）](https://arxiv.org/abs/2402.17362)
  - 内容定位：扩散场假设（$\mathbf{R}_s=\sigma_s^2\mathbf{I}$）在 ASM 编码误差推导中的库内使用处。
  - 用途：§3 闭式解依赖的直接依据。
  - 核验日期：2026-10-15

## 6. 相关对象

- [[方向/AI语音/知识/基础概念/ASM（Ambisonics 信号匹配编码）|ASM]]：扩散场假设的直接使用者（编码误差闭式的推导前提）。
- [[方向/AI语音/知识/基础概念/Reverberation Modeling（混响建模）|Reverberation Modeling]]：扩散声场的物理来源（晚期混响）。
- [[方向/AI语音/知识/基础概念/Ambisonics（球谐声场）|Ambisonics]]：扩散场的球谐系数在各通道等能量分布，是 Ambisonics 分析的标准测试场。
- [[方向/AI语音/知识/基础概念/Array Steering Matrix（阵列导向矩阵）|Array Steering Matrix]]：离散化后 $\mathbf{V}$ 的载体。
- [[方向/AI语音/知识/基础概念/MVDR（最小方差无失真响应）|MVDR]]：噪声/混响协方差常以扩散场建模。

## 7. 待验证

- "平面波展开定理"的严格成立条件（无源区域、凸性要求）与 Herglotz 波函数表述未核对一手文献。
- Lebedev / equiangular 等网格在不同 $N$ 下的实际逼近误差界未查。

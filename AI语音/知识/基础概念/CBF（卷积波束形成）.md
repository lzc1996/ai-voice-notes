---
title: CBF（卷积波束形成）
类型: 概念
相关主题:
  - 阵列信号
  - 多通道增强
  - 去混响
aliases:
  - CBF
  - cbf
  - Convolutional Beamformer
  - convolutional beamformer
  - 卷积波束形成
  - 统一卷积波束形成
  - WPD
  - Weighted Power minimization Distortionless response
tags:
  - 类型/对象
  - 方向/AI语音
  - 主题/阵列信号
  - 主题/多通道增强
  - 主题/去混响
  - 主题/波束形成
---
# CBF（卷积波束形成）

## 1. 身份

`CBF`（Convolutional Beamformer，卷积波束形成）是 NTT（Nakatani、Kinoshita、Ikeshita、Sawada、Araki，WASPAA 2019；统一版 IEEE SPL 26(6):903–907, 2019）提出的**无训练统一空间滤波框架**：把多通道线性预测（MCLP）去混响与波束形成合并进**单个跨时延多通道滤波器**，同时完成去噪、去混响、多源分离——取代"WPE → MVDR"的串行级联。

边界：统计方法（无需训练数据，从观测估计）；[[方向/AI语音/知识/基础概念/WPE（加权预测误差）|WPE]] 可看作 CBF 框架的"每通道去混响子结构"（MCLP 项）；[[方向/AI语音/知识/基础概念/MVDR（最小方差无失真响应）|MVDR]] 是它的单时延（$L=1$）特例。

## 2. 核心公式

### 2.1. 机制总览

CBF 把“延迟预测（去混响）”和“空间滤波（降噪 / 分离）”放进同一个可学习滤波器中；数据流可以先粗略看成：

设 $\mathbf{X}$ 为多通道时频观测，$\mathbf{R}$ 为延迟预测后的残差，$\hat{\mathbf{S}}$ 为输出语音，$\mathbf{G}$ 为延迟预测参数，$\mathbf{W}$ 为空间滤波参数。

$$
\mathbf{X}
\xrightarrow[\mathbf{G}]{\text{延迟预测 / 晚期混响抵消}}
\mathbf{R}
\xrightarrow[\mathbf{W}]{\text{空间滤波 / 波束形成}}
\hat{\mathbf{S}}
$$

两个箭头表示便于理解的数据流顺序；“联合”指 $\mathbf{G}$ 和 $\mathbf{W}$ 在同一个 CBF 目标下共同求解，而不是先固定 WPE、再把结果交给 MVDR。

### 2.2. 模块组合

先把 CBF 拆成两个容易理解的操作：**延迟预测 / 晚期混响抵消**，以及**空间滤波 / 波束形成**。前者用历史帧估计并减去可预测的晚期混响，后者再沿麦克风维度加权，保留目标方向、抑制噪声或其他声源。令 $\mathbf{x}_{t,f}$ 为时间帧 $t$、频率 bin $f$ 的多通道观测，$\mathbf{G}_{\tau,f}$ 为延迟 $\tau$ 的预测参数，$\mathbf{W}_f$ 为空间滤波参数，$D$ 为预测起始延迟，$L$ 为最大延迟：

$$
\mathbf{r}_{t,f}
=\mathbf{x}_{t,f}-\sum_{\tau=D}^{L}\mathbf{G}_{\tau,f}^{H}\mathbf{x}_{t-\tau,f},
\qquad
\hat{\mathbf{s}}_{t,f}=\mathbf{W}_{f}^{H}\mathbf{r}_{t,f}
$$

其中 $\mathbf{r}_{t,f}$ 是去除可预测晚期混响后的残差，$\hat{\mathbf{s}}_{t,f}$ 是空间滤波后的输出。这个分解用于理解数据流；实际 CBF 的 $\mathbf{G}$ 和 $\mathbf{W}$ 是联合优化的。

### 2.3. 卷积滤波展开：把两个模块合成一个滤波器

前面的“延迟预测 + 空间滤波”可以合成为一个跨时间 tap 的卷积滤波器。若用 $\mathbf{w}_l(f)$ 表示第 $l$ 个时延 tap 的综合权重，则直观上有：零时延 tap 主要对应空间滤波，延迟 tap 同时包含延迟预测和空间滤波的作用：

$$
\mathbf{w}_0(f)=\mathbf{W}_f,\qquad
\mathbf{w}_{\tau}(f)=-\mathbf{G}_{\tau,f}\mathbf{W}_f\quad(\tau\ge D)
$$

因此，下面的卷积求和式是在实现层面展开同一个 CBF 算子；上面的模块式适合解释机制，下面的 tap 形式适合说明实际滤波结构。

**输出**（对多通道、多时延观测向量加权）：

其中 $f$ 为频率 bin，$t$ 为时间帧，$l$ 为时延索引，$L$ 为滤波器时延阶数，$\mathbf{x}(f,t)$ 为多通道观测向量，$\mathbf{w}_l(f)$ 为第 $l$ 个时延 tap 的复权重，$y(f,t)$ 为输出，$\mathbf{w}(f)$ 与 $\tilde{\mathbf{x}}(f,t)$ 分别为所有 tap 权重和观测的堆叠向量。

$$
y(f,t) = \sum_{l=0}^{L-1} \mathbf{w}_l^H(f)\, \mathbf{x}(f, t-l) = \mathbf{w}^H(f)\, \tilde{\mathbf{x}}(f,t)
$$

$\tilde{\mathbf{x}}$ 为多通道 × 多时延堆叠向量（同 WPE 的延迟观测结构）——"卷积"指滤波器在**时间延迟维**上滑动，而非常规单 tap 空间滤波。

**统一形式**（DiffCBF 论文式 (1) 引用的标准写法——波束形成项 + 延迟预测项一体式）：

其中 $f$ 为频率 bin，$t$ 为时间帧，$\tau$ 为延迟预测索引，$D$ 为预测起始延迟，$L$ 为最大预测阶数，$\mathbf{y}_{t,f}$ 为多通道观测，$\mathbf{W}_f$ 为波束形成参数，$\mathbf{G}_{\tau,f}$ 为延迟预测参数，$\hat{\mathbf{x}}^{\mathrm{CBF}}_{t,f}$ 为 CBF 输出。

$$
\hat{\mathbf{x}}^{\text{CBF}}_{t,f} = \mathbf{W}_f^H\!\left( \mathbf{y}_{t,f} - \sum_{\tau=D}^{L} \mathbf{G}_{\tau,f}^H\, \mathbf{y}_{t-\tau,f} \right)
$$

- $\mathbf{W}_f$：波束形成部分（降噪 / 分离）。
- $\mathbf{G}_{\tau,f}$：延迟预测部分（MCLP 去混响，同 WPE 的晚期混响预测）。
- 两部分**联合优化**——这是与"WPE 去混响 + MVDR 降噪"串行级联的本质区别。

**ML 解（WPD）**：weighted power minimization distortionless response——在无失真约束下最小化**时变加权**输出功率：

其中 $\mathbf{w}$ 为待求滤波器参数，$\lambda(f,t)$ 为时频点 $(f,t)$ 的源功率估计，$y(f,t)$ 为滤波输出。

$$
\arg\min_{\mathbf{w}} \sum_t \frac{|y(f,t)|^2}{\lambda(f,t)} \quad \text{s.t. 无失真约束}
$$

权重 $1/\lambda$（$\lambda$ = 时变源功率）与 WPE 的方差归一化同一机制；多源时每源一个输出滤波器（分离）。

**DNN 支持版**（ICASSP 2020）：CNN-uPIT 掩码 + noisyCGMM 空间聚类 + WPD——三组件缺一不可。

### 执行拓扑

- 结构：单个跨时延多通道滤波器，去混响与波束形成联合建模。
- 串行对照：`WPE → MVDR` 是级联；CBF 直接写成联合算子：
  其中 $x$ 为多通道观测，$y$ 为输出，$\mathbf{W}$ 为波束形成参数，$\mathbf{G}$ 为延迟预测参数，$F_{\mathrm{CBF}}$ 为联合滤波算子。
  $$
  y = F_{\mathrm{CBF}}(x;\mathbf{W},\mathbf{G})
  $$
- 优化：联合优化，不是先固定 WPE 输出再优化 MVDR。

## 3. 与 WPE / MVDR 的关系

| 方法 | 结构 | 与本概念关系 |
|---|---|---|
| WPE | 每通道 MCLP 去混响（延迟预测） | CBF 的 $\mathbf{G}$ 项是其统一化 |
| MVDR | 单 tap 空间滤波（$L=1$） | CBF 的时间扩展特例 |
| CBF | 多时延 × 多通道统一滤波 | 去混响 + 降噪 + 分离联合优化 |
| WPE → MVDR 级联 | 串行两段 | CBF 的联合优化声称优于串行子优 |

## 4. 在增强 / 阵列里的角色

- **[[方向/AI语音/模型/DiffCBF|DiffCBF]]**（EUSIPCO 2025）：CBF 作为信号处理部件与 ms-SGMSE 扩散迭代耦合（扩散功率谱作 CBF 的 inverse Gamma 先验）；CBF 部件单独看弱于纯扩散基线，增益来自耦合。
- **会议 / 助听前端**：无训练、多任务统一、可实时（如 128 ms 窗 / 64 ms 移配置）——ECHI 类硬约束场景的强候选。
- **DNN-CBF**：现代用法以 mask / 聚类支撑 WPD 估计。

## 5. 相关对象

- [[方向/AI语音/模型/DiffCBF|DiffCBF]]：CBF 的扩散耦合应用。
- [[方向/AI语音/知识/基础概念/MCLP（多通道线性预测）|MCLP]]：$\mathbf{G}$ 项（延迟预测）的机制底座。
- [[方向/AI语音/知识/基础概念/WPE（加权预测误差）|WPE]]：MCLP 去混响同族（延迟预测项同构）。
- [[方向/AI语音/知识/基础概念/MVDR（最小方差无失真响应）|MVDR]]：单 tap 特例 / 级联对照。
- [[方向/AI语音/知识/基础概念/Beamforming（波束形成）|Beamforming]]：空间滤波谱系。
- [[方向/AI语音/知识/基础概念/SCM（空间协方差矩阵）|SCM]]：滤波器估计的统计基础（噪声协方差 / 时变功率）。

## 6. 待验证

- CBF vs "WPE + MVDR"级联在固定会议阵列上的量化差距（联合优化收益）。
- DNN-CBF（ICASSP 2020）在 ECHI 类多流输出任务上的现代用法与表现。

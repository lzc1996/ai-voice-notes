---
title: WG-Auto-HOA
类型: 模型
发表时间: 2026-07
时间依据: arXiv 首次提交日（v1 2026-07-05）；IWAENC 2026 已接收（arXiv Comments 栏）
任务:
  - 目标说话人提取
  - 多通道增强
方法范式:
  - 判别式
  - 掩码驱动 MVDR（弱引导 + 帧间自回归）
开放状态:
  - paper
aliases:
  - WG-Auto-HOA
  - "Weakly Guided and Autoregressive Beamformer Parameterization for Generalizable Moving Speaker Extraction in Higher-Order Ambisonics"
  - Weakly Guided and Autoregressive Beamformer Parameterization
  - 弱引导自回归波束形成器参数化
tags:
  - 类型/对象
  - 方向/AI语音
  - 任务/目标说话人提取
  - 任务/多通道增强
  - 主题/阵列无关
  - 主题/动态声源
---

# WG-Auto-HOA

## 0. 背景

**问题现场**：在 HOA 录音上提取会移动的目标说话人，且只有录制起始时的目标方向可用，要求逐帧因果的流式处理。

**前序路线的缺口**：端到端神经空间滤波与依赖连续方位跟踪的"强引导"方法，要么可解释性/统计保证不足，要么要求持续准确的方位信息。

**WG-Auto-HOA 的切入点**：把神经时频处理与线性空间处理解耦——DNN 仅以标量声场功率估计软掩码，条件特征只用固定波束形成器（FB）与自回归（AR）反馈两条弱线索，空间滤波交给闭式 MVDR。

## 1. 身份

`WG-Auto-HOA`（Weakly Guided and Autoregressive Beamformer Parameterization for Generalizable Moving Speaker Extraction in Higher-Order Ambisonics）是汉堡大学 Signal Processing (SP) Group（Jakob Kienegger、Tal Peer、Sina Khanagha、Timo Gerkmann，DFG Grant 508337379）提出的**移动目标说话人提取（[[方向/AI语音/知识/基础概念/TSE（目标说话人提取）|TSE]]）**方法（IWAENC 2026 已接收，arXiv:2607.04471v1 [eess.AS]，2026-07-05）。

与端到端神经空间滤波和依赖连续方位跟踪的“强引导”不同，它把**神经时频处理与线性空间处理解耦**：DNN 只以标量声场功率估计软掩码，条件特征仅有**固定波束形成器（FB）**与**自回归（AR）反馈**（AR 框架承自作者前作的非线性空间滤波引导）两条弱线索，空间滤波交给闭式线性运算（机制见「核心机制」）。

边界：题名中的 “autoregressive” 指因果逐帧递推、把上一帧增强输出回灌作当前帧 DNN 输入，**不是生成式自回归建模**；观测在 [[方向/AI语音/知识/基础概念/Higher-Order Ambisonics（高阶 Ambisonics）|HOA]] 域而非麦克风阵列域（$M=(N+1)^2$ 个 Ambisonics 系数，需 $P\ge M$ 才可编码），自称的 array-agnostic 实为 ambisonics-order-agnostic；弱引导只假设录制起始时的目标方向已知，该方向的来源与失配影响均未处理（见「待验证」）；严格任务是在 HOA 录音上提取移动目标说话人（TSE），实验为合成数据 + 6 条约 30 s 真实录音。与 [[方向/AI语音/模型/ARiSE|ARiSE]]、[[方向/AI语音/模型/AmbiDrop|AmbiDrop]] 的区别见「相关对象」。

## 2. 核心机制

```text
HOA 观测 X_tk ∈ C^M（M=(N+1)^2 个 Ambisonics 系数，由 P≥M 麦克风 SH 最小二乘解出）
  -> 输入特征三件套：声场功率 |X_tk|^2 + 固定波束形成器 FB（朝初始方向 d0）+ 上一帧增强输出 Ŝ_{t-1,k}（AR 反馈）
  -> DNN 掩码估计（CRUSE / SpatialNet，逐帧因果）-> 语音掩码 M̂(S)_tk 与噪声掩码 M̂(V)_tk（IRM 监督，分开估计）
  -> 递归协方差估计（式 5、6 的自适应指数衰减）-> Φ̂(S)_tk、Φ̂(V)_tk
  -> PEV 导向矢量 d̂_tk（5 次幂迭代 + 预白化）+ [[算法wiki/Tikhonov Regularization（Tikhonov 正则化）|Tikhonov 正则]]（对角加载）
  -> MVDR 权重 w_tk（式 4）-> 输出 Ŝ_tk = w_tk^H X_tk
  -> Ŝ_{t-1,k} 回灌到下一帧 DNN 输入（AR 环路闭合）
```

### 2.1. 弱引导的两个条件特征：FB 与 AR

- **固定波束形成器（FB）**：用式 (7) 的初始化方案参数化一个**朝目标初始方向**的固定波束形成器，其输出作为 DNN 条件输入。给网络的意图是"learn the target's temporal-spectral characteristic at recording start"——一个时间对齐的目标线索，但只在目标还在波束宽度内时有效。
- **自回归（AR）**：把上一帧的处理结果 $\hat{S}_{t-1,k}$ 作为当前帧 DNN 的额外输入。论文对两者差异的表述是这个设计的核心权衡：FB 提供**时间对齐的线索**（利于短录音），AR 提供**连续的目标说话人信息**（利于快速移动与长录音），代价是恒定一帧延迟。两者可单独使用也可联合（Fig. 1）。
- 二者的计算开销：同时使用 FB 与 AR 特征仅增加约 500 参数、<10 MMACs/s（"a negligible increase"）。

### 2.2. 掩码驱动的递归协方差估计

- 递归形式为式 (5)，衰减系数 $\alpha^{(\chi)}_{tk}$ 由式 (6) 给出——**不是**常规的掩码指数移动平均。论文点明这一改动的机制："Expanding the recursion in (5), (6) shows how the denominator in (6) cancels the exponential decay for frames marked without signal activity ($\hat{M}_{tk}=0$). As a result, the effective sample size depends on the mask values $\hat{M}_{tk}$, which **avoids covariance shrinkage in periods of signal inactivity**." 即无语音活动时协方差不被稀释，从而在录制起始的静音段维持目标方向。
- 初始化用式 (7)：目标初始方向构造 rank-1 语音协方差，噪声用扩散（SH-white）模型，$\sigma_0^2$ 匹配期望输入功率。

### 2.3. 弱引导神经掩码估计

- 输入去掉所有空间结构（只用 $|\mathbf{X}_{tk}|^2$），故"unaffected by closely spaced speakers, since it cannot exploit source location"。但功率谱本身不足以区分目标与干扰，因此必须补上初始方向派生的 FB / AR 特征——这就是 "weakly guided" 的由来。
- 训练目标是式 (8) 的 IRM 加阈值 $E_M^{(\chi)}$。论文对该目标的理论定位：当 $|\chi_{tk}|^2 > E_M^{(\chi)}$ 时，$M^{(\chi)}_{tk}$ 在 $S_{tk}\perp V_{tk}$（目标与噪声不相关）条件下最小化 rank-1 协方差更新误差 $\|M^{(\chi)}_{tk}\mathbf{X}_{tk}\mathbf{X}_{tk}^H - \boldsymbol{\chi}_{tk}\boldsymbol{\chi}_{tk}^H\|_F$ 的 Frobenius 范数；而该正交条件在紧邻与交叉说话人场景**并不普遍成立**，所以它只是"a bounded training target, which solely depends on signal power"。
- 由于 $M^{(S)}_{tk}+M^{(V)}_{tk}=1$ 只在 $E_M^{(S)}=E_M^{(V)}=0$ 这种受限情形成立，**语音与噪声掩码分开估计**（而非互补）。
- 骨干两个：CRUSE 改造成逐帧因果（padded CNN + 单向 GRU，2.3 GMACs/s、6.9 M 参数，低复杂度基线）与 SpatialNet（状态空间建模，18.7 GMACs/s、1.7 M 参数，SOTA 架构）。

### 2.4. MVDR 求解与数值稳定性

- 噪声协方差求逆用 [[方向/AI语音/知识/基础概念/Cholesky（Cholesky 分解）|Cholesky 分解]]，并做 [[算法wiki/Tikhonov Regularization（Tikhonov 正则化）|Tikhonov 正则]]（波束形成文献里的对角加载），对应 Ambisonics 域的扩散噪声先验。
- 论文特别指出一个病态场景：方向交叉的说话人会让"inverted noise covariance matrix approaches a projector orthogonal to the target steering vector"，于是式 (4) 的分子分母**同时趋零**——数学上求值恰为 unit gain，实现上必须用**阈值化直通（thresholded pass-through）**人为强制该行为，以保数值稳定。
- 导向矢量由语音协方差的 PEV 得到，用 5 次幂迭代 + 预白化降低软掩码协方差估计的噪声污染；论文提到用递归特征矢量跟踪可进一步省算力，但"lies outside the scope of this work"。

### 2.5. 训练策略

$\ell_1$ 损失、初始学习率 $10^{-3}$ 加指数衰减、50 epochs；所有不可学超参（波束形成、协方差估计、IRM 定义）在验证集上穷举搜索。AR 的固有不可并行性用 **recurrent deep stacking（RDS）**作伪 AR 训练策略规避（该训练策略来自 [[方向/AI语音/模型/ARiSE|ARiSE]] 一系）。

## 3. 核心公式

**1. 球谐展开与 Ambisonics 系数（式 1）：**

$$X_{tk}(r_p,\theta_p,\phi_p) \approx \sum_{n=0}^{N}\sum_{m=-n}^{n} b_n(kr_p)\, X_{tnkm}\, Y_n^m(\theta_p,\phi_p)$$

$k$ 为频点（波数，$kr_p$ 决定刚性球散射的径向响应 $b_n$）、$t$ 为帧索引；$p$ 为麦克风位置。截断阶数 $N$ 下共 $M=(N+1)^2$ 个系数，向量化记为 $\mathbf{X}_{tk}=[X_{t0k0},X_{t1k-1},\dots,X_{tNkN}]^T$；$P\ge M$ 个麦克风时可最小二乘解出。这套系数就是与阵列无关的 Ambisonics 表示。

**2. Ambisonics 信号模型（式 3）：**

$$\mathbf{X}_{tk} = \mathbf{S}_{tk} + \mathbf{V}_{tk} \in \mathbb{C}^{M}, \qquad \mathbf{S}_{tk} = \mathbf{d}_t\, S_{tk}$$

$\mathbf{S}_{tk}$ 为目标语音的无回声 Ambisonics 系数矢量、$S_{tk}$ 为其标量波形；$\mathbf{V}_{tk}$ 吸收干扰语音、环境/测量噪声以及目标语音的混响部分。导向矢量 $\mathbf{d}_t=\mathbf{d}(\theta_t,\phi_t)$ 编码目标 DoA 的直达路径传播，远场假设下即 SH 基矢量 $\mathbf{Y}(\theta_t,\phi_t)$，**实值且与频率无关**。

**3. MVDR 波束形成器（式 4）：**

$$\mathbf{w}_{tk} = \frac{\big(\boldsymbol{\Phi}^{(\mathrm{V})}_{tk}\big)^{-1}\mathbf{d}_t}{\mathbf{d}_t^{T}\big(\boldsymbol{\Phi}^{(\mathrm{V})}_{tk}\big)^{-1}\mathbf{d}_t}, \qquad \hat{S}_{tk} = \mathbf{w}_{tk}^{H}\mathbf{X}_{tk}$$

$\boldsymbol{\Phi}^{(\mathrm{V})}_{tk}$ 为噪声协方差矩阵（其估计是全篇核心）；分子分母同乘的形式即单位增益无失真的保持，$\mathbf{d}$ 实值故用转置 $^T$ 而非共轭转置。导向矢量 $\hat{\mathbf{d}}_{tk}$ 由语音协方差矩阵的 PEV 得到，因 PEV 相位不变，须在全向通道 $d_{0,0}$ 对齐并缩放使 $4\|\hat{\mathbf{d}}_{tk}\|^2 = M$。

**4. 递归协方差估计（式 5）：**

$$\hat{\boldsymbol{\Phi}}^{(\chi)}_{tk} = \alpha^{(\chi)}_{tk}\,\mathbf{X}_{tk}\mathbf{X}_{tk}^{H} + \big(1-\alpha^{(\chi)}_{tk}\big)\,\hat{\boldsymbol{\Phi}}^{(\chi)}_{t-1,k}, \qquad \chi \in \{S,V\}$$

$\mathbf{X}_{tk}\mathbf{X}_{tk}^{H}$ 为当前帧瞬时 rank-1 外积，$\alpha^{(\chi)}_{tk}$ 为自适应遗忘因子，二者加权得到当前协方差估计。

**5. 复合衰减参数（式 6，本文相对常规掩码 EMA 的改动）：**

$$\alpha^{(\chi)}_{tk} = \frac{\beta^{(\chi)}\hat{M}^{(\chi)}_{tk}}{\beta^{(\chi)}\hat{M}^{(\chi)}_{tk} + 1 - \beta^{(\chi)}}$$

$\hat{M}^{(\chi)}_{tk}$ 为估计的软信号指示掩码（语音/噪声），$\beta^{(\chi)}$ 为时间平滑参数。分母中的 $1-\beta^{(\chi)}$ 抵消了指数衰减：当 $\hat{M}_{tk}=0$（无信号活动）时 $\alpha_{tk}=0$，协方差**原地冻结**而不被稀释。

**6. 协方差初始化（式 7）：**

$$\hat{\boldsymbol{\Phi}}^{(S)}_{0k} = \sigma_0^2\,\mathbf{d}_0\mathbf{d}_0^{T}, \qquad \hat{\boldsymbol{\Phi}}^{(V)}_{0k} = \frac{\sigma_0^2}{4}\,\mathbf{I}$$

$\mathbf{d}_0$ 由目标**初始**方向构造（rank-1 语音模型），噪声为扩散（SH-white）先验，$\sigma_0^2$ 调整到匹配期望输入功率。同一初始化方案也被用来参数化 FB 条件特征。

**7. IRM 训练目标（式 8）：**

$$M^{(\chi)}_{tk} = \frac{|\chi_{tk}|^2}{|S_{tk}|^2 + |X_{tk} - S_{tk}|^2}, \quad \text{if } |\chi_{tk}|^2 > E_M^{(\chi)}; \qquad \text{else } 0$$

$\chi_{tk}\in\{S_{tk},V_{tk}\}$；分母即 $|S_{tk}|^2+|V_{tk}|^2$（因 $X_{tk}-S_{tk}=V_{tk}$）。阈值 $E_M^{(\chi)}$ 用于避免静音段污染协方差。

## 4. 结果口径

**实验设置。** 合成数据：Libri2Mix 配对语音 + social force 运动模型生成的说话人轨迹，自实现镜像法（远场理想平面波模型）生成三阶 Ambisonics；刚性球阵列按 MH Acoustics Eigenmike64 尺寸，应用其 [[算法wiki/Tikhonov Regularization（Tikhonov 正则化）|Tikhonov 正则化]]模式强度响应（最大增益 15 dB）；STFT 用 32 ms Hann 窗、16 ms 跳距；加 −30 dB SNR 传感器噪声（该噪声在低频被模式强度补偿放大）。真实数据：Eigenmike64 置于 RT60 ≈ 500 ms 的会议室，两条男声（非母语英语）同时朗读 Rainbow Passage，一人坐定、另一人起立绕过其走到桌对侧再坐下——**每条录音含一次方向性交叉**；段落切成 3 段在两说话人间置换，共 6 条约 30 s 录音。指标：合成集用 PESQ / ESTOI（有参考），真实集与合成集都用 QuartzNet15x5Base-En 转写的 WER（该 ASR 仅在干净与电话对话英语上训练，故对失真敏感，WER 兼作处理退化与任务级性能的联合度量）。

**Table 1（掩码估计方法对照，数值为 CRUSE / SpatialNet 两骨干的 sample mean；95% 置信区间：PESQ ±.01、ESTOI ±.3%、WER ±1%）**

| 掩码估计方法 | 骨干 | MACs [G/s] | PESQ | ESTOI [%] | WER [%] |
| --- | --- | --- | --- | --- | --- |
| Unprocessed | — | — | 1.13±.01 | 43.4±.3 | 112.3±2.4 |
| IRM (oracle) | — | — | 1.93±.01 | 77.8±.3 | 10.7±0.5 |
| FB | CRUSE / SpatialNet | 2.3 / 18.7 | 1.38 / 1.71 | 59.2 / 71.1 | 45.4 / 17.5 |
| AR | CRUSE / SpatialNet | 2.3 / 18.7 | 1.60 / 1.70 | 68.3 / 71.2 | 24.0 / 18.0 |
| FB + AR | CRUSE / SpatialNet | 2.3 / 18.7 | 1.65 / 1.77 | 69.2 / 73.3 | 22.5 / 15.5 |

- **CRUSE**：FB 作输入特征时全指标一致垫底（PESQ 1.38），原因是算力有限、无法充分利用 FB 提供的目标特征；AR 反馈则大幅提升（1.60 / 68.3 / 24.0），组合最优（1.65 / 69.2 / 22.5）。
- **SpatialNet**：FB 与 AR 在整个测试集上**表现相近**（1.71/71.1/17.5 vs 1.70/71.2/18.0）；组合最优（1.77 / 73.3 / 15.5）。
- **机制解释**（正文）：FB 依赖网络在录制起始隐式提取说话人嵌入，既受 DNN 表征能力限制，也受目标停留在初始方向附近**时长**的限制（Fig. 3a：FB 对起始移动高度敏感，AR 在不同运动动态下保持一致）；长录音测试用 EARS 语料的 322 条自由说合成双人混合、按 2.5 s 区间算 SNR，Fig. 3b 显示录音后半段 FB 引导的 SpatialNet 性能下滑而 AR 保持稳定的噪声抑制。论文结论：FB 与 AR 是"时间线索对齐（利于短录音）"与"跨移动/跨时长泛化"之间的权衡，组合兼得。
- **真实录音跨阶数**（Fig. 4，SpatialNet）：所有方法均按 $N=3$ 优化；$N=1$ 的低空间分辨率在多人会议场景不够用；弱引导方法在所有更高阶上表现稳健（ambisonics-order-agnostic）；$N=3\to4$ 因模式强度反演病态导致带宽受限，增益可忽略而算力显著上升。论文自承真实集样本量有限（"Even with the limited sample size"），并称试听测试显示 AR 帮助 SpatialNet 在录音后半段维持说话人可分性。

## 5. 测试基准与性能

**测试基准：** 合成数据为 Libri2Mix + social force 轨迹 + 自实现镜像法的三阶 Ambisonics，刚性球按 Eigenmike64 尺寸与 [[算法wiki/Tikhonov Regularization（Tikhonov 正则化）|Tikhonov 正则化]]模式强度响应，32 ms/16 ms STFT，−30 dB 传感器噪声；真实数据为 Eigenmike64 在 RT60 ≈ 500 ms 会议室的 6 条约 30 s 双人朗读录音（每条含一次方向性交叉）。掩码估计骨干为因果化 CRUSE 与 SpatialNet；对照条件为仅 FB、仅 AR、FB+AR，上界为 oracle IRM，下界为未处理信号。合成集用 PESQ / ESTOI，两集均用 QuartzNet15x5Base-En 转写 WER；跨泛化维度为 Ambisonics 阶数 $N=1$–$4$、说话人运动动态与录音时长（含 EARS 自由说 322 条一分钟区间测试）。

**性能指标：** 全部数值见「结果口径」表格与正文，此处不重复。

（来源：笔记正文「结果口径」，核验日期 2026-10-09）

## 6. 使用判断

- **适合**：球形阵列 / HOA 录音（能拿到 $P\ge M$ 的球阵信号）、目标会移动且**只有起始方向**可用的场景；要求逐帧因果的流式实时增强；需要在不同 Ambisonics 阶数或不同球阵尺寸间复用同一套前端；需要可解释、有统计保证的线性空间滤波器（相对端到端非线性空间滤波）；以及希望把方位跟踪的问题整体绕开的部署。掩码骨干可替换（论文验证了 CRUSE 与 SpatialNet 两端）。
- **不适合**：非球阵且不便做 Ambisonics 编码的任意阵列（$P < M$ 时不可编码）；能把目标 DOA 轨迹准确给出的强引导场景（弱引导是主动放弃信息）；不做逐帧因果的离线批量处理（AR 环路与因果设计无收益）；只追求听感 MOS 的生成式增强目标（本篇无生成模块，指标是 PESQ/ESTOI/WER）。
- **风险**：FB 线索对**录制起始阶段**的目标移动高度敏感，起始运动快时收益明显缩水；交叉/紧邻说话人会让 MVDR 的噪声协方差趋于退化投影器，靠阈值化直通硬撑（工程补丁而非理论解）；**初始方向本身失配的情形全篇未评估**；训练依赖 RDS 伪 AR 策略，实现细节影响可复现性；RDS 带来的 AR 误差跨帧累积在超长录音下的行为未单独分析；真实录音仅 6 条约 30 s，统计效力有限；未见开源代码或权重。

## 7. 关键来源

- [Weakly Guided and Autoregressive Beamformer Parameterization for Generalizable Moving Speaker Extraction in Higher-Order Ambisonics（arXiv:2607.04471）](https://arxiv.org/abs/2607.04471)
  - 内容定位：原始论文，IWAENC 2026 已接收（arXiv Comments 栏）。作者为 Jakob Kienegger、Tal Peer、Sina Khanagha、Timo Gerkmann（汉堡大学 Signal Processing (SP) Group）。
  - 用途：题名/作者/提交日核验、AR 术语判定依据、式 (1)(3)(4)(5)(6)(7)(8)、Table 1 全部数值、跨阶数与真实录音结论。
  - 核验日期：2026-10-09

## 8. 相关对象

- [[方向/AI语音/团队/UHH Gerkmann Group（汉堡大学 Gerkmann 组）|UHH Gerkmann Group]]：本文所属团队（SP Group, University of Hamburg）；该组除生成式增强（SGMSE 线）外还有这条空间滤波 / 移动说话人线。
- [[方向/AI语音/模型/ARiSE|ARiSE]]：同一 AR 范式的直接对照——ARiSE 把上一帧估计与 BF 混合作为**非线性/端到端**增强器的额外输入，本文把 AR 反馈搬到**掩码估计 + 线性 MVDR**上并补上弱引导；本文的 RDS 伪 AR 训练策略即出自该一系。
- [[方向/AI语音/模型/AmbiDrop|AmbiDrop]]：同为 Ambisonics 域的阵列无关路线，但走端到端神经增强 + 通道 dropout（系数直接进 DNN），本文只把声场功率进 DNN、空间处理留给闭式 MVDR——是 array-agnostic 的两个分支。
- [[方向/AI语音/模型/HyBeam|HyBeam]]：同为阵列无关 / 面向硬件形态变化的多通道增强，但走"低频原始信号 + 高频波束输出"的混合特征路线，且不依赖 Ambisonics 编码。
- [[方向/AI语音/知识/基础概念/MVDR（最小方差无失真响应）|MVDR]]、[[方向/AI语音/知识/基础概念/SCM（空间协方差矩阵）|SCM]]：本文波束形成与递归协方差估计的两块基石。
- [[方向/AI语音/知识/基础概念/DOA（到达方向）|DOA]]、[[方向/AI语音/知识/基础概念/steering vector（导向矢量）|steering vector]]、[[方向/AI语音/知识/基础概念/Direct Path（直达声）|Direct Path]]：弱引导设定里"初始方向"的角色，以及 $\mathbf{d}_t$ 编码的直达路径传播。
- [[方向/AI语音/模型/Adaptive Rotary Steering（自适应旋转转向）|Adaptive Rotary Steering]]：同组姊妹工作（Kienegger & Gerkmann，ICASSP 2026）——同样用帧级 AR 反馈 + 仅初始方向引导，但那篇走"Ambisonics 域声场旋转转向自动化"的路线面向 TSE，本文把 AR 反馈接在**掩码估计 + 线性 MVDR** 上；两篇的 "autoregressive" 同指逐帧递推、均非生成式建模。
- [[方向/AI语音/知识/技术路线/Array-Agnostic SE（阵列无关语音增强）|Array-Agnostic SE]]、[[方向/AI语音/知识/技术路线/Hybrid Array SE（传统神经混合阵列增强）|Hybrid Array SE]]：本文属"经典统计波束形成 + 神经掩码"的混合路线，并自称 array-agnostic（实际为 order-agnostic）。
- [[方向/AI语音/知识/技术路线/Spatial-Guided SE（空间引导与多模态增强）|Spatial-Guided SE]]：初始方向作为引导信号的使用方式（本文是其"最弱"的一档：只有起始方向，无连续方位、无视频/注册等模态）。
- [[方向/AI语音/知识/调研与地图/Array Speech Enhancement Frontier（阵列语音增强前沿调研）|阵列语音增强前沿调研]]：本对象所属的阵列增强前沿条目上下文。
- [[方向/AI语音/评估/PESQ|PESQ]]、[[方向/AI语音/评估/STOI 与 ESTOI|STOI 与 ESTOI]]、[[方向/AI语音/评估/WER（词错误率）|WER]]：本文三个评估指标。

## 9. 待验证

- **Table 1 的行标签归属**：原文表格的勾选符号在纯文本抽取中丢失，表中 FB / AR / FB+AR 三行按正文叙述顺序（"FB 一致垫底 → AR 显著提升 → 组合最优"）对应，数值经与正文描述交叉核对一致；仍需对照 HTML/PDF 版原表确认。
- **式 (8) 的排版恢复**：纯文本抽取中该式有字符缺口，本页渲染依据其后紧随的 prose 描述（$|S|^2+|X-S|^2$ 分母、$\chi\in\{S,V\}$、阈值 $E_M$）恢复，需对照原版核对。
- **初始 DoA 失配的量化影响**：全文无初始方向误差实验；边界只体现在 FB 的波束宽度与起始移动敏感性（Fig. 3a）。初始方向从何获得（DOA 估计器、外部标注还是人工指定）论文亦未交代。
- **论文未自取方法缩写**：本页工作名 `WG-Auto-HOA` 取自本项目文件名，非论文自称；若后续出现社区通用名（相对唯一标识符）应改名。
- **项目页未独立核验**：论文脚注给出的 https://sp-uhh.github.io/weakly-guided-beamforming/ 声称含录音视频与试听测试，本次未访问核验。
- **开源状态**：全文未提及代码/权重发布，视作未开源，待查。
- **venue 核对**：IWAENC 2026 接收信息来自 arXiv Comments 栏，待正式论文集核对。
- **FB / AR 联合使用的具体组合方式**（拼接、加权还是分别送入特定层）在纯文本中未给出细节；仅知增量约 500 参数、<10 MMACs/s。
- **前景对照缺失**：与显式跟踪路线（文献 [11] Interspeech 2025、[22] arXiv:2603.23723 的作者前作）没有在同一数据集上的数值对照；这两篇前作在 vault 中也尚无独立页面。
- **统计效力**：真实录音仅 6 条约 30 s（论文自承样本量有限），真实场景收益的显著性待更大规模录制验证。

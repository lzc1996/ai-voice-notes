---
title: SFB-NSE（空间滤波器组神经增强）
类型: 模型
发表时间: 2025-04
时间依据: arXiv 首次提交日（2025-04-02）
任务:
  - 语音增强
  - 多通道增强
方法范式:
  - 判别式
开放状态:
  - paper
aliases:
  - SFB-NSE
  - TSCBM+FB
  - Spatial-Filter-Bank-Based Neural Method for Multichannel Speech Enhancement
  - 空间滤波器组
tags:
  - 类型/对象
  - 方向/AI语音
  - 任务/语音增强
  - 任务/多通道增强
  - 主题/阵列无关
  - 主题/阵列信号
  - 主题/高效化
---

# SFB-NSE（空间滤波器组神经增强）

## 0. 背景

**问题现场**：多通道语音增强需要在不同阵列几何下工作，且算力敏感。

**前序路线的缺口**：TAC / IPD 类逐通道特征与阵列几何绑定，跨几何泛化差且逐通道分支算力高。

**SFB-NSE 的切入点**：先用固定的、数据无关的空间滤波器组把观测投成近似几何无关的特征，再由 TSCBM 后端联合处理全部滤波器通道。

## 1. 身份

`SFB-NSE`（**Spatial-Filter-Bank-Based Neural Method for Multichannel Speech Enhancement**）是 Tianqin Zheng、Jilu Jin、Hanchen Pei、Gongping Huang、Jingdong Chen、Jacob Benesty 提出的**几何无关多通道语音增强**方法（arXiv:2504.01392v1，2025-04-02；正文为 IEEE SPL 模板，未见收录）。论文自称 **TSCBM+FB**（two-stage conformer-based model + filter bank），无公认简称，本条目按 vault 命名惯例记作 SFB-NSE。

它与 TAC / IPD 类**几何绑定的逐通道特征**路线相反：先用**空间滤波器组（SFB）**把阵列观测投成近似几何无关的特征，再由 CMGAN 系两阶段 Conformer 后端 **TSCBM** 联合处理全部滤波器通道（机制见「核心机制」）。

边界：与 [[方向/AI语音/模型/MSEN（特征束多阶编码器）|MSEN]] 是**不同工作**——作者无重叠、机制不同（本文为单一 2 阶 supercardioid 波束 ×9 方位、不分阶、限定 UCA；MSEN 为 0/1/2 阶 eigenbeam 分路 + late fusion），与 AmbiDrop / Geo-DConv 的逐项对比见「相关对象」。滤波器组是**固定、数据无关**的，由含贝塞尔函数的最小二乘闭式解算出，不是可学习模块，可训练的只有后端 TSCBM。严格任务是**增强**，不是分离 / 目标说话人提取；实验全为仿真数据，无真实录音评估。

## 2. 核心机制

```text
UCA 观测 y(k,ω)（M 个全向麦，半径 r，几何只出现在导向矢量里）
  -> 固定空间滤波器组：I=9 个 2 阶 supercardioid 滤波器，指向 θ_s = i/I·2π
       （闭式最小二乘解，含贝塞尔函数正则项，数据无关、不参与训练）
  -> 9 路输出各做幂压缩：Z'_i = |Z_i|^c e^{ȷ∠Z_i}，c=0.3
  -> 实虚部拼接成 Z' ∈ R^{B×2I×T×F}（多通道联合，不分通道处理）
  -> TSCBM（CMGAN 简化版）：Encoder（conv + dilated DenseNet + 频域下采样）
       -> 2 × TSCB（每个含 2 个 conformer block：FFNN×2 + 4 头 MHSA + conv module，带 skip）
       -> Decoder（dilated DenseNet + sub-pixel conv + pixel shuffle，C=64→128）
  -> 输出目标谱实虚部（C=2），以「实部 + 虚部 + 幅度」MSE 监督
  -> 增强语音（固定阵列训练，未见阵列推理）
```

### 2.1. 几何不变性从哪来（全文的支点）

- 镜像声源模型下，第 m 麦的期望语音 $X_{m,\mathrm d}=\sum_l Q_l(\omega)\zeta_m(\omega,\theta_l)S(k,\omega)$：**几何只经由 $\mathbf{d}(\omega,\theta_l)$ 进入观测**，$Q_l$（第 l 条路径冲激响应谱）与 $S$（源信号）与几何无关。
- 空间滤波后 $X_{\mathrm{fd}}=\sum_l Q_l S\,\mathcal{B}[\mathbf{h}(\omega),\theta_l]$：几何残留只剩**波束图** $\mathcal{B}$。
- 推论（论文核心论证）：只要把 $\mathcal{B}$ 设计成**与几何无关**，提取出的特征就与阵列几何无关——这是「固定滤波器组」替代「多阵列训练」的理论依据。
- 图 2 给出经验佐证：同一 2 阶 supercardioid 设计在不同 UCA 几何下波束图高度一致（条件 θ_s=0°、f=4 kHz）。

### 2.2. 滤波器组设计与「为什么要一组滤波器」

- 理想方向图取圆谐波形式 $\sum_{n=-N}^{N} b_{N,n}e^{\jmath n(\theta-\theta_{\mathrm s})}$，$N$ 为阶数、$\mathbf{b}_N$ 控制方向图形状；滤波器由含贝塞尔函数对角阵的**最小二乘闭式解**给出（沿用 Huang–Benesty–Chen 的 UCA 频率不变波束图设计）。
- 单个滤波器只增强一个方向，而实际说话人方位未知 → 用 $I=9$ 个滤波器组成滤波器组，第 $i$ 个指向 $\theta_{\mathrm s}=\frac{i}{I}2\pi$，输出记 $Z_i$。
- 配置：$N=2$ 的 supercardioid，$\mathbf{b}_N=[0.1035\;0.242\;0.309\;0.242\;0.1035]^{T}$（5 个系数，和为 1）。
- 输出做幂压缩 $Z_i'=|Z_i|^{c}e^{\jmath\angle Z_i}$（$c=0.3$，沿用 CMGAN 口径，平衡弱声与强声），实虚部拼接得到 $2I$ 通道输入。

### 2.3. TSCBM 后端（CMGAN 简化版）

- 输入 $Z'\in\mathcal{R}^{B\times 2I\times T\times F}$ → Encoder（conv (1,1) + Instance Norm + PReLU → dilated DenseNet（dilation 1、2）→ conv (1,3) stride (1,2) 下采样频率）→ 通道数 C=64。
- 2 个 TSCB，每个 TSCB 含 2 个 conformer block（各含两个 FFNN、4 头 MHSA、conv module），带 skip connection，同时建模时间与频率依赖。
- Decoder：dilated DenseNet 镜像 → sub-pixel convolution（C 翻倍到 128、像素洗牌上采样频率）→ 末层 conv (1,2) + Instance Norm + PReLU，输出 C=2（实部/虚部）。
- 损失：估计谱的**实部、虚部、幅度**三者的 MSE（论文未给完整表达式）；AdamW，lr $5\times10^{-4}$；STFT 25 ms Hamming / 400 点 FFT、hop 6.25 ms（75% 重叠）。
- **关键工程点**：全部滤波器通道**联合处理**（joint channel processing），不做逐通道分支——这正是相对 TAC / 逐通道 IPD 方案省算力的来源；作者强调该方法不限于 TSCBM，可接多数多通道增强模型。

### 2.4. 训练 / 推理口径

- 训练：VoiceBank+DEMAND 仿真的多通道数据，镜像法生成 RIR；房间 3×3×2.5 m ~ 7×9×3 m，T60 随机 0.2–0.35 s；SNR −5~10 dB；目标语音与干扰最小方位差 5°；训练语音切 2 s 段，测试用整句。
- 训练阵列：**5 麦、半径 0.5 cm 的 UCA，只有这一种**。测试：4 种未见 UCA（7/9 麦 × 1/1.5 cm 半径）；泛化扫描共 9 组（M=5/7/9 × r=0.5/1/1.5 cm，其中与训练一致的 5 麦 0.5 cm 作为参考点）。
- 基线：DPRNN+TAC（[[方向/AI语音/模型/FaSNet（滤波求和网络）|FaSNet]]+TAC 改造：去掉波束形成模块以适配无参考中心麦的增强任务）、TSCBM+select（测试阵列多于 5 麦时挑与训练阵列方位最接近的 5 个）、DPRNN+FB（DPRNN+TAC 去掉 TAC、换成本文滤波器组，用于证明 FB 可以替掉 TAC 的算力）。

## 3. 核心公式

**1. 阵列信号模型（相位延迟与导向矢量）：**

$$\zeta_m(\omega,\theta) = e^{\jmath \bar{\omega}\cos(\theta-\psi_m)}, \qquad \bar{\omega} = \frac{\omega r}{c}, \qquad \mathbf{d}(\omega,\theta) = \big[\zeta_1(\omega,\theta)\;\cdots\;\zeta_M(\omega,\theta)\big]^{T}$$

$M$ 个[[方向/AI语音/知识/基础概念/Omni Mic（全向麦克风）|全向麦]]均匀分布在半径 $r$ 的圆上；$\psi_m$ 是第 $m$ 个麦的角位置（即阵列几何），$\theta$ 为来波方位，$\bar{\omega}=\omega r/c$ 为归一化频率，$c$ 为声速。

**2. 观测与期望分量（几何入口）：**

$$\mathbf{y}(k,\omega) = \mathbf{x}_{\mathrm{d}}(k,\omega) + \mathbf{v}(k,\omega), \qquad \mathbf{x}_{\mathrm{d}}(k,\omega) = \sum_{l=1}^{L} Q_l(\omega)\,S(k,\omega)\,\mathbf{d}(\omega,\theta_l)$$

$Q_l(\omega)$ 为第 $l$ 个镜像源冲激响应的频谱，$L$ 为镜像源总数，$S$ 为源信号，$\mathbf{v}$ 为背景噪声向量——几何只藏在 $\mathbf{d}(\omega,\theta_l)$ 里。

**3. 空间滤波与几何无关性（核心论证）：**

$$Z(k,\omega) = \mathbf{h}^{H}(\omega)\mathbf{y}(k,\omega), \qquad X_{\mathrm{fd}}(k,\omega) = \sum_{l=1}^{L} Q_l(\omega)\,S(k,\omega)\,\mathcal{B}\big[\mathbf{h}(\omega),\theta_l\big]$$

$\mathbf{h}(\omega)$ 为空间滤波器，$X_{\mathrm{fd}}$ 为滤波后期望信号，$V_{\mathrm{rn}}$ 为残余噪声；$\mathcal{B}[\mathbf{h}(\omega),\theta_l]$ 为 $\theta_l$ 方向的**波束图**。因 $Q_l$、$S$ 均与几何无关，特征是否几何无关完全取决于 $\mathcal{B}$。

**4. 理想波束图（圆谐波形式）：**

$$\mathcal{B}(\mathbf{b}_N,\theta) = \sum_{n=-N}^{N} b_{N,n}\,e^{\jmath n(\theta-\theta_{\mathrm{s}})} = \mathbf{b}_N^{T}\mathbf{p}(\theta), \qquad \mathbf{p}(\theta) = \big[e^{-\jmath N\theta}\;\cdots\;1\;\cdots\;e^{\jmath N\theta}\big]^{T}$$

$\mathbf{b}_N$ 为决定方向图形状的系数，$N$ 为阶数（本文 $N=2$），$\theta_{\mathrm{s}}$ 为主瓣指向（滤波器组取 $\theta_{\mathrm{s}}=\frac{i}{I}2\pi$）。

**5. 最小二乘滤波器设计（固定、闭式、无学习参数）：**

$$\mathbf{h}(\omega) = \frac{1}{M}\,\boldsymbol{\Psi}^{H}\mathbf{J}^{*}(\bar{\omega})\,\boldsymbol{\Upsilon}^{*}(\theta_{\mathrm{s}})\,\mathbf{b}_N$$

$$\boldsymbol{\Psi} = \big[\boldsymbol{\psi}_{-N}^{*}\;\cdots\;\boldsymbol{\psi}_{0}^{*}\;\cdots\;\boldsymbol{\psi}_{N}^{*}\big]^{T}, \qquad \boldsymbol{\psi}_n = \big[e^{-\jmath n\psi_1}\;e^{-\jmath n\psi_2}\;\cdots\;e^{-\jmath n\psi_M}\big]^{T}$$

$$\mathbf{J}(\bar{\omega}) = \mathrm{diag}\left[\frac{1}{\jmath^{-N}J_{-N}(\bar{\omega})}\;\cdots\;\frac{1}{J_{0}(\bar{\omega})}\;\cdots\;\frac{1}{\jmath^{N}J_{N}(\bar{\omega})}\right], \qquad \boldsymbol{\Upsilon}(\theta_{\mathrm{s}}) = \mathrm{diag}\big[e^{\jmath N\theta_{\mathrm{s}}}\;\cdots\;1\;\cdots\;e^{-\jmath N\theta_{\mathrm{s}}}\big]$$

$J_n(\cdot)$ 为第一类 $n$ 阶贝塞尔函数；$\boldsymbol{\Psi}$ 只依赖麦克风角位置（几何），$\mathbf{J}$ 只依赖归一化频率 $\bar{\omega}=\omega r/c$（含半径），$\boldsymbol{\Upsilon}$ 只依赖主瓣指向——三者相乘即「用贝塞尔函数补偿 UCA 各阶模态」的闭式设计（方法出自 Huang–Benesty–Chen 的 UCA 频率不变波束图工作）。

**6. 特征压缩：**

$$Z_i' = |Z_i|^{c}\,e^{\jmath \angle Z_i}, \qquad c = 0.3$$

第 $i$ 个滤波器的输出 $Z_i$ 按幂律压缩幅度、保留相位；实虚部拼接成网络输入 $Z'\in\mathcal{R}^{B\times 2I\times T\times F}$（$I=9$）。

## 4. 结果口径

实验设置：VoiceBank+DEMAND 仿真多通道数据（镜像法 RIR），训练/测试噪声类型不重叠；房间 3×3×2.5 m ~ 7×9×3 m；T60 0.2–0.35 s；SNR −5~10 dB；训练 UCA 为 5 麦、半径 0.5 cm，测试为 7/9 麦、1/1.5 cm 半径的未见 UCA；指标 PESQ / CSIG / CBAK / COVL / STOI + FLOPS。以下为原文 Table I（数值原样，同一测试集）：

| 模型           | FLOPS  | PESQ     | CSIG     | CBAK     | COVL     | STOI     |
| ------------ | ------ | -------- | -------- | -------- | -------- | -------- |
| Noisy        | —      | 1.23     | 2.72     | 1.86     | 1.99     | 0.789    |
| DPRNN+TAC    | 31.3G  | 2.25     | 4.09     | 3.06     | 3.23     | 0.914    |
| TSCBM+select | 28.3G  | 2.50     | 4.02     | 3.21     | 3.32     | 0.934    |
| DPRNN+FB     | 2.77G  | 2.25     | 4.15     | 2.98     | 3.26     | 0.911    |
| **TSCBM+FB** | 28.3G  | **2.76** | **4.36** | **3.30** | **3.64** | **0.947** |

- TSCBM+FB 在全部五项感知/可懂度指标上最优；DPRNN+FB 与 DPRNN+TAC 性能相当，而算力约为其**十分之一**（2.77G vs 31.3G，原文表述）——即本文的滤波器组可以替掉 TAC 类逐通道模块；TSCBM+select 也已超过 DPRNN+TAC（说明「挑麦」本身有效）。
- 图 3 的泛化结论（9 组 UCA 配置，**原文只给趋势、未给数字**）：DPRNN+TAC 对麦克风数变化稳定、但**随半径变化退化**（TAC 只处理通道数变化，不处理半径变化）；TSCBM+FB 对**半径与麦克风数两者都稳定**。

## 5. 测试基准与性能

测试基准为 VoiceBank + DEMAND 的仿真多通道集（镜像法 RIR，训练/测试噪声不重叠），训练阵列固定为 5 麦 / 0.5 cm 半径 UCA，评测覆盖与训练不同的 7、9 麦与 1、1.5 cm 半径等未见 UCA；指标为 PESQ、CSIG、CBAK、COVL、STOI 以及模型 FLOPS，基线为 DPRNN+TAC、TSCBM+select、DPRNN+FB（全部数字见「结果口径」表，此处不重复）。性能要点：所提 TSCBM+FB 在主表全指标领先，并通过 9 组（麦克风数 × 半径）配置扫描展示了对几何参数的稳定泛化，而 TAC 类基线随半径退化。

（来源：笔记正文「结果口径」；核验日期 2026-10-09）

## 6. 使用判断

- 适合：**设备几何多变但都是圆形/紧凑平面阵列**的场景，且希望只用一种阵列的训练数据（省去多阵列数据采集）；给现有多通道增强网络加一个**数据无关、无训练参数**的几何无关前端；算力敏感（无逐通道分支，DPRNN+FB 口径下约省 10 倍）。
- 不适合：分布式 / 异步 / 非平面阵列；需要波束随环境自适应更新（滤波器是闭式固定解，不含环境自适应）；对真实录音验证有硬要求（本文全部为仿真评测）。
- 风险：训练与测试几何差异范围温和（同为 UCA，只有 M 与 r 变化，半径 0.5→1/1.5 cm）；基线只有 DPRNN+TAC 系，未与 TPARN / [[方向/AI语音/模型/VarArray|VarArray]] / AGADIR 等 array-agnostic 主流方法对比；论文声称可扩展到任意平面阵列但无实验；未开源；venue 未确认（仅 arXiv v1）。

## 7. 关键来源

- [Spatial-Filter-Bank-Based Neural Method for Multichannel Speech Enhancement（arXiv:2504.01392）](https://arxiv.org/abs/2504.01392)
  - 内容定位：原始论文（v1，2025-04-02，eess.AS；正文页眉为 IEEE SPL 模板，abs 页未给 venue/comments）。
  - 用途：对象身份、作者、机制、公式与 Table I 全部数字。
  - 核验日期：2026-10-09
- [论文 HTML 版（arXiv HTML）](https://arxiv.org/html/2504.01392v1)
  - 内容定位：同论文排版版；本次用于校订纯文本抽取中失真的公式与表格对齐（公式 (1)–(18) 与 Table I 复核）。
  - 用途：公式与实验数字的二次核验。
  - 核验日期：2026-10-09

## 8. 相关对象

- [[方向/AI语音/模型/MSEN（特征束多阶编码器）|MSEN（特征束多阶编码器）]]：同路线不同工作——都是空间滤波器组 + 圆谐波/贝塞尔设计的几何不变波束图；MSEN 分 0/1/2 阶并行编码 + late fusion、面向任意紧凑平面阵列（作者无重叠、更晚），本文是单阶 9 方向滤波器组 + CMGAN 系 TSCBM、限定 UCA 的更早工作。
- [[方向/AI语音/知识/基础概念/Beamforming（波束形成）|Beamforming]]：滤波器组即一组固定波束形成器，波束图的几何不变量是全文论证支点。
- [[方向/AI语音/知识/基础概念/steering vector（导向矢量）|steering vector]]：几何进入观测的唯一通道，也是被滤波器组「消掉」的对象。
- [[方向/AI语音/知识/基础概念/Array Aperture（阵列孔径）|Array Aperture]]：UCA 半径（孔径）与通道数是本文泛化的两个维度，实验正扫这两个轴。
- [[方向/AI语音/知识/基础概念/IPD（通道间相位差）|IPD]]：论文引言批评的几何绑定/逐通道特征代表（TAC、IPD 类方案），本文的对立面。
- [[方向/AI语音/知识/技术路线/Array-Agnostic SE（阵列无关语音增强）|Array-Agnostic SE]]：本文属「规范空间表示」路线中的固定滤波器组分支。
- [[方向/AI语音/模型/Geo-DConv|Geo-DConv]]：相对路线——显式几何条件化 vs 本文的输入表示去几何化。
- [[方向/AI语音/模型/AmbiDrop|AmbiDrop]]：同为规范空间路线，但走 Ambisonics 编码 + dropout，不是可指定方向图的波束组。
- [[方向/AI语音/知识/技术路线/Efficient Multichannel SE（多通道语音增强高效化）|Efficient Multichannel SE]]：几何无关 + 联合通道处理的省算力证据（DPRNN+FB vs DPRNN+TAC）。
- [[方向/AI语音/知识/调研与地图/Array Speech Enhancement Frontier（阵列语音增强前沿调研）|阵列语音增强前沿调研]]：谱系位置（阵列泛化 / 任意几何）。
- [[方向/AI语音/数据集/VoiceBank-DEMAND|VoiceBank-DEMAND]]：仿真数据来源（VoiceBank 干净语音 + DEMAND 噪声）。
- [[方向/AI语音/评估/PESQ|PESQ]]、[[方向/AI语音/评估/STOI 与 ESTOI|STOI]]：主评测指标。

## 9. 待验证

- **venue / 发表状态**：abs 页无 comments 与 journal-ref；仅正文页眉显示 IEEE SPL 模板（VOL. XX, NO. XX, JAN 2025），arXiv 只挂 v1（2025-04-02），是否已被期刊或会议接收未确认。
- **与 MSEN 一线的关系**：arXiv 2504.01392 是否被 ICASSP 2026 的 MSEN 或其同组工作（检索到一篇 "On The Design of Efficient Neural Methods for Geometry-Agnostic Multichannel Speech Enhancement"，作者与 MSEN 重叠，vault 调研页记为「高效 SFB 设计」）引用/延伸——网络检索提示存在引用关系，但 IEEE 页面与 Semantic Scholar 本次均无法直连核验（IEEE 拒绝访问、S2 返回 429）；vault 中该 ICASSP 条目的描述（最优通道数理论、LSTM 替换自注意力、算力 −25%）与本文内容不符，应为不同论文。
- **图 3 数值缺失**：9 组 UCA 配置的 PESQ/CSIG/CBAK/COVL 只有趋势描述（TAC 随半径退化、本文稳定），原文未给数字。
- **半径量级**：训练半径 0.5 cm、测试 1/1.5 cm 偏小（纯文本与 arXiv HTML 三处一致，非抽取错误），建议以 PDF 图复核是否为原文意图。
- **滤波器组重设计成本**：$\mathbf{h}(\omega)$ 的 $\boldsymbol{\Psi}$、$\mathbf{J}$ 分别依赖麦克风角位置与半径，换阵列推理时应按新几何闭式重算（属公式直接推论，论文未明说）；重算开销与是否缓存未讨论。
- **超参缺口**：TSCB 层数/隐藏维度、训练 epoch、batch size、参数量均未给出。
- **真实数据与更强基线**：全部为仿真评测（无真实录音）；对比方法仅 DPRNN+TAC / DPRNN+FB，未与 TPARN、VarArray、AGADIR 等 array-agnostic 主基线比较。
- **非 UCA 扩展**：结论声称方法适用于任意形状平面阵列（引 Huang–Chen–Benesty 2018），无实验支撑。
- **开源情况**：未见代码 / 权重 / 音频样例。
- **作者单位**：正文与 arXiv HTML 均未携带 affiliation 信息（SPL 模板作者块未随 arXiv 版本发布），故本页未写机构。

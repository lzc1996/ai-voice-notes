---
title: ADEPS
类型: 模型
发表时间: 2026-08
时间依据: arXiv 首次提交日（v1 2026-08-25）
任务:
  - Ambisonics 编码
  - 空间音频
方法范式:
  - 生成式
参数量: 30.8M（NCSN++M 骨干）
开放状态:
  - paper
  - code
aliases:
  - ADEPS
  - Ambisonics Diffusion Encoding via Posterior Sampling
  - "Array-Agnostic Ambisonics Encoding via Diffusion Posterior Sampling"
tags:
  - 类型/对象
  - 方向/AI语音
  - 任务/空间音频
  - 主题/阵列无关
  - 主题/空间音频
  - 主题/扩散模型
---

# ADEPS

## 0. 背景

**1) 问题现场**：Ambisonics 作为空间音频表示理论上与录制设备无关，但实际系数必须从物理麦克风阵列"编码"出来，而编码步被阵列物理属性绑死——声场采样、麦克风布位、声衍射带来严重的阵列相关伪影。经典线性编码（正则化伪逆解逆问题）有两个结构性失效：低频高阶径向函数 $b_n(k,r)\to 0$ 导致矩阵病态、放大传感器噪声；高频超过空间 Nyquist 后混叠。参数化方法（HOA/DirAC 类）靠 DOA 估计动态重合成，混响下 DOA 误差、密集声源与复杂反射建模不住。数据驱动方法准，但**绑定固定阵列几何**，换麦克风数要整个重训。

**2) 前序路线的缺口**：位置条件化方案（Heikkinen 等）仍限固定通道数、忽略阵列频响特性；后续用采集信号与 ATF 交叉注意力的编码-解码架构**无通道柔性**，换麦数需完整重训。即"零样本换阵列"在编码步没有解决。

**3) ADEPS 的切入点**：把**物理采集模型显式嵌进扩散采样过程**（Diffusion Posterior Sampling）——生成先验只用**理想、无损坏的 Np 阶 Ambisonics 表示**做无监督训练（与任何阵列几何、混叠、噪声剖面完全隔离），推断时用依赖 ATF 的线性退化算子做测量一致性引导，从而对任意阵列拓扑零样本编码。

## 1. 身份

`ADEPS`（Ambisonics Diffusion Encoding via Posterior Sampling）是 Amit Milstein、Nir Shlezinger、Boaz Rafaely 提出的**阵列无关 Ambisonics 编码生成框架**（arXiv:2608.24558，v1 2026-08-25 / v3 2026-09-08，eess.AS + eess.SP，暂无 venue；README 口径单位为 Ben-Gurion University of the Negev ECE 学院，代码仓库 [Amitmils/ADEUPS](https://github.com/Amitmils/ADEUPS)，声明整理中、尚未放码）。Rafaely 组即库内 [[方向/AI语音/模型/AmbiDrop|AmbiDrop]]、[[方向/AI语音/模型/HyBeam|HyBeam]] 的同一阵容，ADEPS 是该组"规范空间投影"路线在**编码步本身**上的生成式升级。

边界：**不是语音增强模型**——输入任意阵列信号、输出 $N_{enc}$ 阶 Ambisonics 系数（文中 $N_p = 5$，即 36 通道），是增强/渲染的**上游前端组件**；也不做虚拟麦克风补全（那是 [[方向/AI语音/模型/Spatial-Magnifier|Spatial-Magnifier]] 的问题）。与 [[方向/AI语音/模型/AmbiDrop|AmbiDrop]] 的分工：AmbiDrop 用 [[方向/AI语音/知识/基础概念/ASM（Ambisonics 信号匹配编码）|ASM]] 线性编码进 Ambisonics 域后靠 dropout 容错做 SE，ADEPS 则把编码误差本身作为逆问题用扩散先验修掉——是 AmbiDrop 前端的潜在替换件（尚未有人验证）。框架明确"restricted to spatially resolvable orders"（先验阶数内），全阶真实声场下高频空间混叠抑制会退化。

## 2. 核心机制

```text
任意几何 Q 麦信号 p_q(k)（Q 满足 (N_enc+1)² ≤ Q）
  -> 逐频点 Tikhonov 正则化伪逆线性编码 Ẽ(k) -> Ẽp
  -> 幅度压缩 STFT 域 H(z) = β|z|^α·e^{i∠z}（α=0.67, β=3）-> 观测 y
  -> DPS 反向采样（M=150 步，warm-init：x_τmax ~ N(y, σ_max²I)，σ_max 80→20）
       先验得分：Tweedie ∇log pτ(xτ) ≈ (D_θ(xτ,σ) − xτ)/σ²
       似然得分：−η(τ)∇‖y − A(D_θ(xτ,σ))‖²，A(x0) = H(Ẽ V H⁻¹(x0))
       （D_θ：NCSN++M 改 (Np+1)² 通道 + adaLN 时间条件，30.8M，EDM 训练）
  -> 输出 N_enc 阶 Ambisonics 系数 -> 解压/渲染（双耳用 KU100 HRTF）
```

### 2.1. 生成先验

- 只在**理想 Np 阶 Ambisonics 系数**上做无监督训练（EDM 框架，Karras 式预条件化 + 加权 ℓ2），训练时完全不接触任何阵列几何、空间混叠与麦克风噪声——先验因此天然 array-agnostic。
- 先验阶数 $N_p > N_{enc}$：先验容量高于目标编码阶，压缩后的 STFT 域建模。$N_p$ 是权衡：越接近真实 $N_{eff}$ 性能越好，但显存与算力上涨。

### 2.2. 测量一致性引导（DPS）

- 退化算子 $A(\cdot)$ 精确复刻"线性编码链"：解压 → 经模态导向矩阵 $V$ 的物理采样 → Tikhonov 伪逆再编码 → 幅度压缩。它依赖 ATF/导向矩阵知识，是物理模型侧的"已知条件"。
- 每步反向采样同时拉两个力：先验（"像理想 Ambisonics"）+ 似然（"线性编码回看要和观测 $y$ 一致"），步长按梯度范数归一化稳定。

### 2.3. 主干与数据

- 训练 RIR 用 HARP 生成：房间 $[6,10]\times[6,10]\times[2,3]$ m、T60 ∈ [0.1, 0.4] s、阵列中心随机撒在 1×1 m²、1–2 声源、距离 0.8–1.5 m；语音 VCTK（训练）/ WSJ0（评估）。
- 测试 13 个阵列：Project Aria 实阵列 + 每个 $Q\in\{4,5,6\}$ 各 4 组随机不规则阵列（成对间距 0.02–0.18 m）；50 dB SNR 高斯噪声；共 13k 测试信号。

## 3. 核心公式

**1. 信号模型**（频点 $k$）：

$$p_q(k) = \sum_n \sum_m b_n(k, r_q)\, Y_n^m(\theta_q, \phi_q)\, a_{nm}(k) + \nu_q(k); \qquad p(k) = V(k)\, a_{N_{eff}}(k) + \nu(k)$$

$b_n$ 为阶数相关径向函数，$Y_n^m$ 为实值球谐函数，$V = Y_{N_{eff}} B$ 为模态导向矩阵（SH 矩阵 × 径向函数对角阵），$\nu$ 为 i.i.d. 测量噪声。

**2. 线性编码（观测构造）**：

$$\tilde{E}(k) = V^H\big(VV^H + \gamma^2 I_Q\big)^{-1}; \qquad y = H(\tilde{E}\, p), \qquad H(z) = \beta|z|^{\alpha} e^{i\angle z}$$

$\gamma$ 为 Tikhonov 正则系数；$\tilde{E}p$ 即"线性编码信号"，是 ADEPS 要修正的对象。

**3. 退化算子与 DPS 似然得分**：

$$A(x_0) = H\big(\tilde{E}\, V\, H^{-1}(x_0)\big); \qquad \nabla_{x_\tau} \log p_\tau(y|x_\tau) \approx -\eta(\tau)\, \nabla_{x_\tau} \big\| y - A(D_\theta(x_\tau, \sigma(\tau))) \big\|_2^2$$

$D_\theta$ 为去噪器（Tweedie 点估计 $\hat{x}_0$）；步长归一化 $\eta(\tau) = \eta' / [\sigma(\tau)\,\|\nabla_{x_\tau}\|y - A(\hat{x}_0)\|_2^2\|_2]$。

**4. 后验得分与更新**（Alg. 1，VE 参数化 $f=0,\ g=\sqrt{2\tau}$）：

$$\nabla \log p_\tau(x_\tau|y) = \underbrace{\frac{D_\theta(x_\tau,\sigma) - x_\tau}{\sigma^2}}_{\text{先验（Tweedie）}} + \underbrace{\nabla_{x_\tau} \log p_\tau(y|x_\tau)}_{\text{测量一致性}}; \qquad x_{\tau_{i+1}} \leftarrow x_{\tau_i} - \sigma_i(\sigma_{i+1}-\sigma_i)\,[s_i + s_{LH}]$$

**5. EDM 训练损失**：

$$L(\theta) = \mathbb{E}_{x_0,\varepsilon,\tilde{\sigma}}\big[\lambda(\tilde{\sigma})\, \| D_\theta(x_0 + \tilde{\sigma}\varepsilon, \sigma_\tau) - x_0 \|_2^2\big]$$

## 4. 结果口径

**设置**：指标 = SI-SDR↑、对数幅度谱误差↓、幅度平方相干性↑、双耳渲染（KU100 HRTF）ERB 带的 ILD/IC 绝对误差↓；系数评估至 $N_{enc}=1$（原文口径，含义见待验证）。四列数字依次为 4 麦 / 5 麦 / 6 麦随机阵列 / Project Aria 实阵列。Param. 基线用 **oracle DOA + 设备 ATF**，是参数化方法的上限口径。

### 4.1. Table I：阶数匹配（$N_{eff} = N_p = 5$，理想化设定）

| 方法 | SI-SDR↑ | 谱误差↓ | 相干性↑ | ILD 误差↓ | IC 误差↓ |
| --- | --- | --- | --- | --- | --- |
| Linear | 6.80 / 7.95 / 9.26 / 3.63 | 8.39 / 7.78 / 7.21 / 14.71 | 0.81 / 0.82 / 0.83 / 0.76 | 3.61 / 3.04 / 2.77 / 2.44 | 0.12 / 0.11 / 0.10 / 0.11 |
| Param.（oracle） | 3.80 / 3.92 / 3.91 / 2.86 | 5.85 / 5.79 / 5.77 / 6.04 | 0.72 / 0.72 / 0.72 / 0.71 | 0.98 / 0.91 / 0.92 / 0.93 | 0.09 / 0.08 / 0.08 / 0.09 |
| **ADEPS** | **11.66 / 14.18 / 16.20 / 10.00** | **5.15 / 4.72 / 4.35 / 6.67** | 0.80 / 0.85 / 0.88 / 0.73 | 1.02 / 0.68 / 0.53 / 0.77 | **0.07 / 0.04 / 0.03 / 0.06** |

- SI-SDR 比线性编码高 **4–7 dB**，且 5/6 麦时 ILD/IC 误差为全场最低（空间保真最佳）；Aria 实阵列上优势同样保持（10.00 vs 3.63）。
- 参数化方法即便喂 oracle DOA 与真 ATF，SI-SDR 仍全场最差——混响下参数化合成的失败是结构性的。

### 4.2. Table II：全阶现实声场（$N_{eff}=15$，$N_p=5$）

| 方法 | SI-SDR↑ | 谱误差↓ | 相干性↑ | ILD 误差↓ | IC 误差↓ |
| --- | --- | --- | --- | --- | --- |
| Linear | 6.71 / 7.82 / 9.09 / 3.31 | 9.56 / 9.32 / 8.37 / 10.84 | 0.82 / 0.82 / 0.83 / 0.76 | 3.65 / 3.11 / 2.84 / 2.39 | 0.12 / 0.11 / 0.10 / 0.12 |
| Param.（oracle） | 3.73 / 3.76 / 3.78 / 2.26 | 6.29 / 6.61 / 6.73 / 7.36 | 0.71 / 0.70 / 0.71 / 0.66 | 0.95 / 2.54 / 0.88 / 0.91 | 0.08 / 0.08 / 0.08 / 0.08 |
| **ADEPS** | **9.85 / 10.57 / 12.67 / 4.94** | **5.72 / 5.58 / 5.03 / 7.43** | 0.74 / 0.76 / 0.80 / 0.64 | 1.21 / 1.05 / 0.86 / 1.30 | 0.08 / 0.07 / 0.06 / 0.10 |

- 真实声场含高阶分量而先验只到 5 阶：高频混叠抑制退化，**相干性反低于线性编码**（0.74–0.80 vs 0.82–0.83）；但 SI-SDR 与谱误差仍全面领先。

### 4.3. Table III：对阵列特定编码器（4 麦阵列、全阶）

| 方法 | SI-SDR↑ | 谱误差↓ | 相干性↑ | ILD 误差↓ | IC 误差↓ |
| --- | --- | --- | --- | --- | --- |
| Linear | 6.63 | 11.02 | 0.80 | 3.24 | 0.13 |
| U-Net 编码器（10.2M，阵列特定） | 6.16 | **5.83** | **0.83** | **2.33** | **0.11** |
| Diff-Enc（通道拼接条件化，30.8M，阵列特定） | **9.52** | 6.01 | 0.78 | **0.88** | **0.06** |
| **ADEPS（零样本）** | 9.23 | **5.88** | 0.71 | 1.13 | 0.07 |

- 阵列特定扩散编码器（Diff-Enc）以同参数量微弱领先 SI-SDR/ILD/IC，但它**只在训练过的阵列上成立**——原文明言两个阵列特定基线"在未见 4 麦几何上完全失效"；ADEPS 不训练任何阵列仍拿到同档性能。
- U-Net（10.2M）SI-SDR 反而低于线性编码（6.16 vs 6.63）：小模型拟合编码映射并不便宜。

## 5. 测试基准与性能

**测试基准**：仿真为主 + 一个实阵列（Project Aria）。HARP 生成 RIR（T60 0.1–0.4 s），VCTK 训练 / WSJ0 评估，13 个测试阵列（4/5/6 麦随机不规则 + Aria），50 dB SNR；基线三档：线性编码（信号无关逆问题）、参数化合成（oracle DOA + 设备 ATF 上限）、阵列特定神经编码器（U-Net 10.2M、通道拼接扩散 30.8M）。指标：SI-SDR、对数幅度谱误差、幅度平方相干性、双耳 ERB 带 ILD/IC 误差。

**性能指标**：完整数字见「结果口径」。一句话总结——阶数匹配设定下全面领先（SI-SDR 高线性编码 4–7 dB、ILD/IC 最低）；全阶声场下 SI-SDR/谱误差仍领先但空间相干性让给线性编码；对阵列特定编码器以**零样本**拿到同档水平，而后者换几何即崩。

（来源：笔记正文「结果口径」，核验日期 2026-10-27）

## 6. 使用判断

- **适合**：任意/不可控阵列 → Ambisonics 的**零样本编码前端**（消费级设备、穿戴阵列、临时布放）；作为 [[方向/AI语音/模型/AmbiDrop|AmbiDrop]] 类规范空间 SE 的**编码步升级候选**（用生成式编码替换 ASM，降低 dropout 层的容错负担——未验证）；双耳渲染前的高保真空间采集。
- **不适合**：实时/端侧链路——150 步反向采样 × 30.8M 骨干，每步一次网络评估，延迟与算力都不是实时口径（论文未给 RTF）；需要 $N_{enc}>5$ 的高阶编码（先验未覆盖）；高频空间相干性敏感的场景（全阶声场下此项输给线性编码）。
- **风险**：
  - **先验阶数天花板**："restricted to spatially resolvable orders" 是作者自认的结构性限制；高阶扩展（欠定系数上采样）列为 future work。
  - **算力口径**：M=150 步的推理成本无实测（无 RTF/延迟/显存数字），无法判断离线可用性之外的落地空间。
  - **评估阶数口径**：系数"evaluated up to $N_{enc}=1$"原文含义待核——若指标只算 1 阶以下，SI-SDR 的绝对值不能直接与全阶编码工作对比。
  - **代码未放**：仓库声明 WIP，无权重、无 license，可复现性未知。
  - **对比口径**：Table I/II 的 Param. 基线用 oracle DOA + 设备 ATF（偏强的上限口径），但没有与非 oracle 的实用参数化方法比。

## 7. 关键来源

- [Array-Agnostic Ambisonics Encoding via Diffusion Posterior Sampling（arXiv:2608.24558）](https://arxiv.org/abs/2608.24558)
  - 内容定位：arXiv 摘要页，v1 2026-08-25、v2 2026-08-27、v3 2026-09-08，eess.AS / eess.SP，作者 Amit Milstein、Nir Shlezinger、Boaz Rafaely；无 venue comment。
  - 用途：对象身份、作者与时间口径核验。
  - 核验日期：2026-10-27
- [ADEPS 全文（arXiv:2608.24558v3 HTML）](https://arxiv.org/html/2608.24558)
  - 内容定位：全文，含信号模型 (1)–(3)、线性编码 (5)、DPS 得分与退化算子 (6)–(10)、EDM 训练 (11)–(12)、Table I/II/III 全部数值与实验设置。
  - 用途：核心机制、边界与全部结果数字的来源。
  - 核验日期：2026-10-27
- [Amitmils/ADEUPS（GitHub）](https://github.com/Amitmils/ADEUPS)
  - 内容定位：官方仓库（README 引用本 arXiv 号）。**声明 "Codebase Under Active Preparation"，暂无代码、无权重、无 license**；README 署名单位为 BGU ECE 学院。
  - 用途：开放状态与单位口径核验。
  - 核验日期：2026-10-27

## 8. 相关对象

- [[方向/AI语音/模型/AmbiDrop|AmbiDrop]]：同组（Rafaely 组）下游 array-agnostic SE；其 ASM 编码 + dropout 容错与 ADEPS 的"生成式修编码误差"是同一问题（编码伪影）的两种解法，ADEPS 可视为前端替换候选。
- [[方向/AI语音/知识/基础概念/ASM（Ambisonics 信号匹配编码）|ASM]]：ADEPS 观测链里的线性编码同族概念；AmbiDrop 实际采用的编码方式。
- [[方向/AI语音/知识/基础概念/Ambisonics（球谐声场）|Ambisonics]]：ADEPS 的目标表示域（$N_p=5$ 阶，36 系数，压缩 STFT 域建模）。
- [[方向/AI语音/模型/MSEN（特征束多阶编码器）|MSEN]]、[[方向/AI语音/模型/WG-Auto-HOA|WG-Auto-HOA]]：同属"规范空间投影"路线的对照系——MSEN 走 eigenbeam 空间滤波器组、WG-Auto-HOA 在 HOA 域解耦线性/神经处理，均为判别式。
- [[方向/AI语音/模型/Spatial-Magnifier|Spatial-Magnifier]]：少麦"空间上采样"，与 ADEPS 的"任意阵列零样本编码"相邻但不同问题（它需要固定已知几何）。
- [[方向/AI语音/模型/ArrayDPS|ArrayDPS]]、[[方向/AI语音/模型/VM-ArrayDPS|VM-ArrayDPS]]、[[方向/AI语音/模型/USD-DPS|USD-DPS]]：同用 [[方向/AI语音/知识/生成式语音增强/DPS（扩散后验采样）|DPS（扩散后验采样）]] 做测量一致性引导的增强侧模型，ADEPS 把同一机制搬到编码侧。
- [[方向/AI语音/知识/技术路线/Array-Agnostic SE（阵列无关语音增强）|Array-Agnostic SE]]：ADEPS 归入"规范空间投影"路线，是其中唯一的生成式编码代表。
- [[方向/AI语音/知识/技术路线/Generative Multichannel SE（生成式多通道语音增强）|Generative Multichannel SE]]：生成式 + 阵列的相邻路线；ADEPS 证明 DPS 可承载"物理采集模型进采样环"的范式。
- [[方向/AI语音/知识/基础概念/DDPM（去噪扩散概率模型）|DDPM]]、[[方向/AI语音/知识/基础概念/DDIM（去噪扩散隐式模型）|DDIM]]：扩散先验的基础机制页（ADEPS 用 EDM 框架 + 概率流 ODE，属同族）。
- [[方向/AI语音/模型/HyBeam|HyBeam]]：同组另一条 array-agnostic 分支（低频 raw mic + 高频波束），与 Ambisonics 域编码互补而非竞争。
- [[方向/AI语音/知识/基础概念/ILD（双耳声级差）|ILD]]：双耳渲染评估口径之一（IC 同列）。
- [[方向/AI语音/数据集/VCTK|VCTK]]、[[方向/AI语音/数据集/WSJ0（华尔街日报语料库）|WSJ0]]：训练 / 评估语音来源。
- [[方向/AI语音/知识/调研与地图/Array Speech Enhancement Frontier（阵列语音增强前沿调研）|阵列语音增强前沿调研]]：本对象对应"六、阵列泛化 / 任意几何 / 少麦"条目。

## 9. 待验证

- **venue**：arXiv 无 comment，v3（2026-09-08）后无新版本；四页双栏排版像会议投稿，无确证。
- **评估阶数口径**：原文称 "Ambisonics coefficients are evaluated up to $N_{enc}=1$"——若指标只在 1 阶以下系数上算，Table I–III 数值不能与全阶编码工作直接横比；需对照 PDF 确认。
- **训练/评估场景数**：抽取文本显示 "2020k training and 11k evaluation scenes"，疑为 20k / 11k 的抽取粘连，待核 PDF。
- **Shlezinger 单位**：README 把三位作者统一署在 BGU ECE 学院名下，但 Nir Shlezinger 常规署名为巴伊兰大学，以论文 PDF 页脚为准。
- **推理成本实测**：M=150 步 × 30.8M 的 RTF/延迟/显存全文未给；"离线可用、实时不行"目前是推断不是证据。
- **Tikhonov 正则系数 $\gamma$ 与 DPS 步长 $\eta'$ 的取值**：正文未在抽取文本中出现具体数值。
- **替换 ASM 前端的实证**：ADEPS 编码 + AmbiDrop dropout SE 的组合效果无人验证；同组论文间互不引用实验。
- **Table III 中"阵列特定基线在未见几何完全失效"**：为原文转述，未见其跨几何扫描数据；若引用需回到 PDF 核对原句。
- **代码与复现**：仓库 WIP，无 license、无权重；放出后需核训练脚本是否含 HARP RIR 生成链与 13 阵列测试配置。

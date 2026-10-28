---
title: USD-DPS
类型: 模型
发表时间: 2025-08
时间依据: arXiv 首次提交日（2025-08-04，v1）；DOI 指向 IEEE WASPAA 2025
任务:
  - 去混响
  - 多通道增强
方法范式:
  - 生成式-扩散
  - 无监督
开放状态:
  - paper
  - code
  - demo
aliases:
  - USD-DPS
  - usd-dps
  - Unsupervised Speech Dereverberation via Diffusion Posterior Sampling
  - Unsupervised Multi-channel Speech Dereverberation via Diffusion
  - 无监督多通道盲去混响
  - 无监督扩散后验采样去混响
tags:
  - 类型/对象
  - 方向/AI语音
  - 任务/去混响
  - 任务/多通道增强
  - 主题/扩散模型
  - 主题/无监督学习
  - 主题/去混响
---

# USD-DPS

## 0. 背景

**问题现场**：多通道单说话人盲去混响——阵列几何、RIR、房间声学全未知，且没有配对干净数据可供训练。

**前序路线的缺口**：MC-BUDDy 全通道建 RIR 模型算力随通道数线性膨胀且 8 麦 SI-SDR 为负；MC-FCP 完全不用 RIR 先验则 SI-SDR −13.8 ~ −11.7 dB，不可行。

**USD-DPS 的切入点**：无条件干净语音扩散先验 + 逐采样步重估 RIR（参考通道子带 RIR 模型、其余通道 FCP 解析解）构造多通道混合一致性似然，用 DPS 式后验采样恢复参考麦干净语音，全程无需配对数据。

## 1. 身份

`USD-DPS`（Unsupervised Speech Dereverberation via Diffusion Posterior Sampling）是 UIUC（Yulun Wu、Zhongweiyang Xu、Jianchong Chen、Romit Roy Choudhury）× 南方科技大学（Zhong-Qiu Wang）在 WASPAA 2025 提出的**多通道单说话人盲去混响**方法（arXiv:2508.02071，2025-08-04）。

它不训练"混响进 → 干净出"的判别式去混响网络，而是用**无条件干净语音扩散先验** + **逐扩散采样步重估各通道 RIR**（参考通道建参数化 RIR 模型、其余通道用 FCP 解析解补）构造**多通道混合一致性（mixture consistency）**似然，以 [[方向/AI语音/知识/生成式语音增强/DPS（扩散后验采样）|DPS]] 式后验采样恢复参考麦的干净无回声语音，全程无需配对干净数据（机制见「核心机制」）。

边界：它是**盲**且**单说话人**的（阵列几何、RIR、房间声学全部未知），推理路径上没有任务专用网络，也不是单通道方法；与同系列 [[方向/AI语音/模型/USDnet++|USDnet++]] 不是同一方法（它走神经前向滤波、不含生成先验），与 [[方向/AI语音/模型/ArrayDPS|ArrayDPS]]、BUDDy / MC-BUDDy 的逐项区别见「相关对象」；命名上论文自身、代码仓库与 Demo 域名一律用 USD-DPS，不是 UMC-DiffDereverb。严格任务是**盲去混响**，不是分离、不是通用增强，目标是参考麦的直达声；实验仅仿真数据。

## 2. 核心机制

```text
多通道混响混合 y = {y_c}（C 个麦，参考麦为 1）
  -> WPE 暖启动：x_init = WPE(y)
  -> 从 x_N ~ N(x_init, σ_N²I) 出发，跑 200 步反向概率流 ODE（沿用 BUDDy 的 scheduler + 一阶采样器）
  -> 每个采样步 n 内四件事：
       (a) 冻结的干净语音扩散先验打 score s_θ → Tweedie 一步去噪得 x̂₁⁰，rescale 到经验标准差 0.05
       (b) 参考通道 RIR：子带 RIR 模型参数 ψ（幅度=粗采样指数衰减插值，相位自由）用 Adam 迭代 N_its 步，
           再投影（最小相位 + δ⊕ 把首样本置 1，钉住直达声）
       (c) 非参考通道 RIR：FCP 加权最小二乘解析解，不建 RIR 模型
       (d) 似然引导：压缩 STFT 域上算 mixture-consistency 残差 → 梯度 g_n
  -> x₁^{n-1} = x₁^n − σ_n(σ_{n-1}−σ_n)(s_n + g_n)
  -> 输出参考通道干净无回声语音 x₁⁰
```

### 2.1. DPS 后验采样与压缩域似然

后验 score 拆成先验 score + 似然 score（Eq. 3）；先验 score 由冻结的扩散模型给，似然 score 用 Tweedie 一步去噪估计 $\hat{x}_1^0$ 近似（Eq. 4）。似然建在**压缩 STFT 域**上：$S_{\mathrm{comp}}(\mathbf{y})=|\mathrm{STFT}(\mathbf{y})|^{2/3}\exp\{j\angle \mathrm{STFT}(\mathbf{y})\}$——幅度压到 2/3 次幂，避免高能量 bin 主导。这一项在论文中被点明"也可视为迈向 mixture consistency 约束的一步"：**RIR 滤波后的输出应当接近混响混合**。

### 2.2. 参考通道 RIR：子带 RIR 模型 + Adam

沿用 BUDDy 的信号混响模型 $\mathcal{A}_{\psi}$（STFT → 逐子带 1D 卷积 → iSTFT）。RIR 的 STFT $H$ 被结构化参数化：幅度响应由**粗采样的指数衰减模型插值**得到（每子带一个权重 $w_b$ 与衰减率 $\alpha_b$），**相位 $\Phi$ 直接自由优化**；参数 $\psi=\{\Phi,(w_b,\alpha_b)_{b=1}^{B}\}$ 每个采样步用 Adam 迭代最小化压缩域残差 + 正则 $R(\psi)$。每次参数更新后做投影：最小相位化，并用 $\delta\oplus(\cdot)$ 把 RIR 首样本置 1——保证直达声落在第 0 个样本。MC-BUDDy 里只有参考通道做 $\delta\oplus$；USD-DPS 沿用该设置（不同通道直达声有延时，非参考通道不能再钉首样本）。

### 2.3. 非参考通道 RIR：FCP 解析解

只用参考通道的 RIR 模型，其余 $C-1$ 个通道的 RIR 用 **FCP** 解：把滤波器估计写成**加权最小二乘**，权重 $\hat{\lambda}^c_{m,k}$ 取各通道平均能量再加一个 floor（$\epsilon\cdot\max$），抑制高能量 T-F bin 过拟合。因为是解析解，不需要迭代优化。论文强调 FCP 的估计过程**可微**，从而给似然 score 更直接的梯度。

### 2.4. 为什么这样分工（论文的消融逻辑）

- **全通道都上 RIR 模型（MC-BUDDy）**：更准但算力随 $C$ 线性膨胀，且各通道独立建模 → 8 麦 SI-SDR 掉到负值，作者解释为"同一房间不同通道的 RIR 本应有相似性质"。
- **全通道都用 FCP（MC-FCP）**：SI-SDR −13.8 ~ −11.7 dB，"does not work"——完全不用 RIR 先验不可行。
- **只有参考通道上 RIR 模型 + FCP 补其余（USD-DPS）**：在精度与效率之间取平衡，全部指标优于 MC-BUDDy，且 8 麦推理 114.38 s vs 387.75 s。

### 2.5. 扩散先验与训练配置

波形域 **1D U-Net**（audio-diffusion-pytorch v0.1.3），训练数据是 LibriTTS train-clean-{100,360}（约 460 小时、>1000 说话人）——**只用干净语音，只有混响混合做推理输入**。作者对比了 BUDDy 原用的修改版 [[方向/AI语音/知识/基础概念/NCSN++（噪声条件分数网络）|NCSN++]]：1D U-Net 在所有指标更好且采样更快，故 MC-BUDDy / USD-DPS 都用 1D U-Net。训练配方沿用 BUDDy。

## 3. 核心公式

**1. 概率流 ODE 与后验 score 分解（Eq. 1–3）：**

$$\mathrm{d}x_1^{\tau}=-\sigma(\tau)\nabla_{x_1^{\tau}}\log p(x_1^{\tau})\,\mathrm{d}\tau,\qquad \mathrm{d}x_1^{\tau}=-\sigma(\tau)\nabla_{x_1^{\tau}}\log p(x_1^{\tau}\,|\,y)\,\mathrm{d}\tau$$

$$\nabla_{x_1^{\tau}}\log p(x_1^{\tau}\,|\,y)=\nabla_{x_1^{\tau}}\log p(x_1^{\tau})+\nabla_{x_1^{\tau}}\log p(y\,|\,x_1^{\tau})$$

前两式分别是无条件与后验的 EDM 概率流 [[方向/AI语音/知识/基础概念/ODE（常微分方程）|ODE]]；第三式把后验 score 拆成先验 score（冻结扩散模型给）与似然 score（待近似）——即 [[方向/AI语音/知识/生成式语音增强/DPS（扩散后验采样）|DPS]] 的标准分解。$x_1^{\tau}$ 是扩散时刻 $\tau$ 的状态，$\sigma(\tau)$ 为噪声调度。

**2. Tweedie 一步去噪与压缩域似然（Eq. 4）：**

$$\nabla_{x_1^{\tau}}\log p(y\,|\,x_1^{\tau})\simeq\nabla_{x_1^{\tau}}\log p(y\,|\,\hat{x}_1^{0},h),\qquad \hat{x}_1^{0}=x_1^{\tau}-\sigma^{2}(\tau)\,s_{\theta}(x_1^{\tau},\tau)$$

$$p(y\,|\,\hat{x}_1^{0},h)=\prod_{c=1}^{C}\mathcal{N}\!\left(S_{\mathrm{comp}}(y);\;S_{\mathrm{comp}}(\hat{x}_1^{0}*h_c),\;\eta^{2}I\right),\qquad S_{\mathrm{comp}}(\mathbf{y})=|\mathrm{STFT}(\mathbf{y})|^{2/3}\exp\{j\angle\mathrm{STFT}(\mathbf{y})\}$$

$\hat{x}_1^{0}$ 是 [[方向/AI语音/知识/基础概念/Tweedie（Tweedie 公式）|Tweedie 公式]]给出的干净语音一步估计；$h_c$ 是第 $c$ 通道相对 RIR；$\eta$ 是压缩 STFT 域的测量噪声水平。

**3. 子带 RIR 卷积与结构化 RIR 先验（Eq. 5–6）：**

$$Y_{m,k}=H_{m,k}*X_{m,k}=\sum_{n=0}^{N_h-1}H_{n,k}X_{m-n,k}$$

$$A'_{n,b}=w_be^{-\alpha_bn},\qquad A=\exp\!\big(\mathrm{lerp}(\log A')\big),\qquad \psi=\{\Phi,\,(w_b,\alpha_b)_{b=1}^{B}\}$$

$H=\mathrm{STFT}(h)\in\mathbb{C}^{N_h\times K}$，$N_h$ 是 RIR 帧数、$K$ 是频点数；每个频带独立做 1D 卷积。$w_b$、$\alpha_b$ 是子带 $b\in[1,B]$ 的权重与衰减率，$A$ 由粗采样的指数衰减 $A'$ 在对数域线性插值（lerp）得到；相位 $\Phi$ 自由优化。

**4. RIR 参数估计目标与投影（Eq. 7–8）：**

$$\hat{\psi}=\arg\min_{\psi}\;\big\|S_{\mathrm{comp}}(y)-S_{\mathrm{comp}}(\mathcal{A}_{\psi}(\hat{x}_1^{0}))\big\|_2^{2}+R(\psi)$$

$$H\leftarrow\mathrm{STFT}\big(\delta\oplus P_{\min}(\mathrm{iSTFT}(H))\big)$$

$\mathcal{A}_{\psi}$ 是"STFT → 逐子带卷积 → iSTFT"的顺序算子，$R(\psi)$ 为参数正则项（细节见 BUDDy），用 Adam 优化 $N_{\text{its}}$ 次。投影式中 $P_{\min}$ 保证最小相位，$\delta\oplus(\cdot)$ 把 RIR 首样本置 1，使[[方向/AI语音/知识/基础概念/Direct Path（直达声）|直达声]]落在第 0 样本。

**5. FCP 非参考通道 RIR 的解析解（Eq. 11–12）：**

$$\hat{H}^{c}=\mathrm{FCP}(Y^{c},\hat{X})=\arg\min_{H^{c}}\sum_{m,k}\frac{1}{\hat{\lambda}^{c}_{m,k}}\left|Y^{c}_{m,k}-\sum_{n=0}^{N_h'-1}H^{c}_{n,k}\hat{X}_{m-n,k}\right|^{2}$$

$$\hat{\lambda}^{c}_{m,k}=\frac{1}{C}\sum_{c=1}^{C}|Y^{c}_{m,k}|^{2}+\epsilon\cdot\max_{m,k}\frac{1}{C}\sum_{c=1}^{C}|Y^{c}_{m,k}|^{2}$$

给定 STFT 域源估计 $\hat{X}$ 与各通道观测 $\{Y^c\}$，FCP 解加权最小二乘得第 $c$ 通道 RIR；权重 $\hat{\lambda}^c_{m,k}$ 用各通道平均能量加一个 $\epsilon$ 倍的全局最大值作为 floor，防止过拟合高能量 bin。$N_h'$ 为 FCP 滤波器帧数（取 60）。

**6. USD-DPS 的多通道似然引导（Eq. 13，本文核心）：**

$$\nabla_{x_1^{\tau}}\log p(y\,|\,x_1^{\tau})\simeq\zeta(\tau)\nabla_{x_1^{\tau}}\Bigg(\big\|S_{\mathrm{comp}}(y_1)-S_{\mathrm{comp}}(A_{\hat{\psi}_1}(\hat{x}_1^{0}))\big\|_2^{2}+\lambda'\sum_{c=2}^{C}\big\|S_{\mathrm{comp}}(y_c)-S_{\mathrm{comp}}(A_{\hat{H}^{c}}(\hat{x}_1^{0}))\big\|_2^{2}\Bigg)$$

第一项是**参考通道**的混合一致性（RIR 来自 RIR 模型 $\hat{\psi}_1$），第二项是**非参考通道**的一致性（RIR 来自 FCP 的 $\hat{H}^c$），$\lambda'$ 调节非参考通道引导强度（取 0.6）。对照 MC-BUDDy 的写法只是把求和放到 $c=1..C$（Eq. 10），但每个 $\hat{\psi}_c$ 都要独立 Adam 优化。

**7. 采样更新与引导步长（Algorithm 1 line 23，Eq. 14）：**

$$x_1^{n-1}=x_1^{n}-\sigma_n\,(\sigma_{n-1}-\sigma_n)\,\big(s_n+g_n\big),\qquad g_n=\zeta(\sigma_n)\,\nabla_{x_1^{n}}\big(\mathcal{L}_{\text{ref}}+\mathcal{L}_{\text{non-ref}}\big)$$

$$\zeta(\tau)=\frac{\zeta\sqrt{L}}{\tau\,\|G\|_2}$$

$s_n$ 是扩散先验 score，$g_n$ 是似然引导项，两者相加后按 EDM 一阶采样器步进（沿用 BUDDy 的 scheduler）。$\|G\|_2$ 是似然梯度范数（Eq. 14），$L$ 为信号长度，$\zeta$ 取 0.8 作全局缩放——把引导强度按梯度尺度归一，避免步长随残差量级漂移。

## 4. 结果口径

**数据与设置**：WSJ0CAM-DEREVERB（8 麦圆阵，直径 20 cm；说话人距离 0.75–2.5 m；T60 0.2–1.3 s；加 REVERB 数据集的扩散空调噪声，SNR 5–25 dB；16 kHz）。测试集 3,262 条（约 6.4 h）。评价参考信号为**参考麦（第 1 麦）的直达声**。2 麦用 mic 1+5，4 麦用 1+3+5+7，8 麦用全部。指标：SI-SDR、窄带 PESQ、eSTOI。

### 4.1. 主结果（Table 1，WSJ0CAM-DEREVERB 测试集）

| 方法 | Unsup. | 多通道 | 2 麦 SI-SDR/PESQ/eSTOI | 4 麦 SI-SDR/PESQ/eSTOI | 8 麦 SI-SDR/PESQ/eSTOI |
|---|---|---|---|---|---|
| Mixture | – | – | −3.6 / 1.64 / 0.494 | −3.6 / 1.64 / 0.494 | −3.6 / 1.64 / 0.494 |
| WPE | ✓ | ✗ | −3.1 / 1.67 / 0.512 | −3.1 / 1.67 / 0.512 | −3.1 / 1.67 / 0.512 |
| WPE | ✓ | ✓ | −1.0 / 1.90 / 0.630 | −1.0 / 1.98 / 0.665 | −0.1 / 1.97 / 0.656 |
| USDnet | ✓ | ✓ | 2.1 / 2.37 / 0.745 | 2.3 / 2.53 / 0.751 | 2.7 / 2.45 / 0.761 |
| BUDDy (NCSN++) | ✓ | ✗ | 1.0 / 2.31 / 0.778 | 1.0 / 2.31 / 0.778 | 1.0 / 2.31 / 0.778 |
| BUDDy (1D U-Net) | ✓ | ✗ | 2.1 / 2.49 / 0.802 | 2.1 / 2.49 / 0.802 | 2.1 / 2.49 / 0.802 |
| MC-FCP（消融） | ✓ | ✓ | −13.8 / 1.63 / 0.479 | −13.8 / 1.64 / 0.487 | −11.7 / 1.70 / 0.516 |
| MC-BUDDy（对照） | ✓ | ✓ | −3.3 / 2.67 / 0.834 | −5.5 / 2.74 / 0.884 | −6.6 / 2.68 / 0.838 |
| **USD-DPS** | ✓ | ✓ | **3.6 / 2.79 / 0.871** | **3.8 / 2.90 / 0.884** | **3.5 / 2.94 / 0.879** |
| DNN-WPE（监督） | ✗ | ✓ | 1.6 / 2.00 / 0.697 | 2.9 / 2.08 / 0.731 | 2.9 / 2.09 / 0.728 |
| NB-LSTM（监督） | ✗ | ✓ | 4.0 / 2.20 / 0.722 | 6.3 / 2.45 / 0.789 | 7.8 / 2.69 / 0.827 |
| NBC（监督） | ✗ | ✓ | 7.6 / 2.63 / 0.824 | 11.1 / 3.08 / 0.898 | 13.0 / 3.31 / 0.926 |

读法（论文原话口径）：

- **无监督内部**：USD-DPS 与 MC-BUDDy 明显优于 USDnet，说明扩散语音先验的收益；MC-BUDDy 虽靠多通道测量在 PESQ / eSTOI 上有增益，但 SI-SDR 为负；USD-DPS 相对 MC-BUDDy **全指标更好且更快**。
- **MC-FCP 不可行**（SI-SDR −13.8 ~ −11.7 dB），与 USDnet 用复谱映射时的观察一致。
- **vs 监督**：USD-DPS 全指标胜 DNN-WPE；对 NB-LSTM 是 PESQ / eSTOI 明显更好、SI-SDR 更差（论文归因于无监督输出与真值存在错位，SI-SDR 对样本级对齐敏感）；对更强的 NBC **仅在 2 麦场景的 PESQ（2.79 vs 2.63）与 eSTOI（0.871 vs 0.824）更好**，其余全部更差——论文归因于 NBC 能学到训练集的噪声分布，而 USD-DPS 只假设白噪声。
- 附带一点：NBC / NB-LSTM 每个设置都要重训，USD-DPS 对任意设置 training-free。

### 4.2. 推理成本（Table 2，8 麦，每条混合平均 7.0 s）

| 方法 | 架构 | 处理时间 (s) | PESQ |
|---|---|---|---|
| BUDDy | NCSN++ | 119.67 | 2.31 |
| BUDDy | 1D U-Net | 64.78 | 2.49 |
| MC-BUDDy | 1D U-Net | 387.75 | 2.68 |
| USD-DPS | 1D U-Net | 114.38 | 2.94 |

USD-DPS 相对 MC-BUDDy 快约 3.4 倍且 PESQ 更高；相对同架构单通道 BUDDy 慢约 1.8 倍（换多通道一致性）。

## 5. 测试基准与性能

**测试基准**：WSJ0CAM-DEREVERB（WSJ0CAM 干净语料 + 仿真房间；8 麦 20 cm 直径圆阵、距离 0.75–2.5 m、T60 0.2–1.3 s、空调扩散噪声 SNR 5–25 dB、16 kHz），测试集 3,262 条。参考信号取参考麦直达声；指标为 SI-SDR / 窄带 PESQ / eSTOI；2 / 4 / 8 麦三种阵列子集分别评估。基线分三档：无监督（WPE、USDnet、BUDDy 两版）、本文消融（MC-FCP、MC-BUDDy）、监督（DNN-WPE、NB-LSTM、NBC）。扩散先验在 LibriTTS train-clean-{100,360} 上训练，推理 200 步采样、1D U-Net。

**性能指针**：完整数字见「结果口径」（Table 1 全表 + Table 2 成本表），此处不重复。定位一句话：**在无监督多通道盲去混响里拿 SOTA，性价比上优于 MC-BUDDy（准且快 3.4×），但打不过强监督 NBC（只在 2 麦的 PESQ / eSTOI 上赢）**。全篇只有绝对处理时间，没有 RTF、没有参数量、没有实现细节级别的算力口径。

## 6. 使用判断

- **适合**：只有混响录音、没有干净配对数据可训练的场景；阵列几何 / 通道数会变、不想为每种设置重训；可以接受每条 7 s 音频约 114 s 处理（离线或近线）的多通道去混响。
- **不适合**：实时 / 端侧（论文的成本口径是 8 麦每条 7.0 s 混合需 114.38 s，论文本身未报 RTF）；噪声显著的非平稳噪声场景（只假设白噪声，降噪明显弱于监督方案）；多说话人 / 需要分离的输入（单说话人假设）。
- **风险**：先验是干净语音扩散模型，生成式采样天然有幻觉风险，论文未做内容保真度 / WER 类验证；SI-SDR 为负或偏低是这套无监督路线的常态（输出与真值错位），拿 SI-SDR 做选型会误判；RIR 模型的 $N_{\text{its}}$、子带数 $B$、正则 $R(\psi)$ 细节都外链到 BUDDy，复现时要回到 BUDDy 的代码与超参。

## 7. 关键来源

- [Unsupervised Multi-channel Speech Dereverberation via Diffusion（arXiv:2508.02071）](https://arxiv.org/abs/2508.02071)
  - 内容定位：原始论文，WASPAA 2025（DOI 10.1109/WASPAA66052.2025.11231009）；题名、作者、提交日、摘要均以 arXiv abs 页为准。
  - 用途：USD-DPS 全部机制、公式 (1)–(14)、Algorithm 1、Table 1 / Table 2 数据。
  - 核验日期：2026-10-09
- [论文 HTML 版（arXiv 官方）](https://arxiv.org/html/2508.02071v1)
  - 内容定位：同论文的可读 HTML 版本（LaTeX 原生渲染）。
  - 用途：Table 1 / Table 2 的精确单元格数值（PDF 纯文本抽取会把表格列打散，此页为准）。
  - 核验日期：2026-10-09
- [官方代码（GitHub: USDDPS/USDDPS_code）](https://github.com/USDDPS/USDDPS_code)
  - 内容定位：作者给出的复现入口（论文 §4.1 正文引用此地址）。
  - 用途：复现与接入自有阵列数据。
  - 核验日期：2026-10-09
- [Demo 页（usddps.github.io）](https://usddps.github.io/USDDPS_demo/)
  - 内容定位：作者提供的音频试听页（论文摘要引用）。
  - 用途：听感评估与失败案例分析。
  - 核验日期：2026-10-09

## 8. 相关对象

- [[方向/AI语音/知识/生成式语音增强/DPS（扩散后验采样）|DPS]]：USD-DPS 的基础采样框架（先验 score + 似然 score）；本文把它推广到"逐采样步重估全部通道 RIR"的盲多通道设定。
- [[方向/AI语音/模型/ArrayDPS|ArrayDPS]]：同组姊妹工作——同一套 DPS + 逐步估算子思路，但做盲**分离**（多说话人、相对 RIR + 虚拟源），USD-DPS 做盲**去混响**（单说话人、绝对 RIR + 混合一致性）。
- [[方向/AI语音/模型/Uni-ArrayDPS|Uni-ArrayDPS]] / [[方向/AI语音/模型/ArrayDPS-Refine|ArrayDPS-Refine]]：ArrayDPS 家族后续，属同一"扩散先验 + 阵列逆问题"谱系。
- [[方向/AI语音/模型/USDnet++|USDnet++]]：同属无监督去混响，但路线是神经前向滤波、不含生成先验；本文的 USDnet 基线即该系列，论文也指出 MC-FCP 的失败与 USDnet 复谱映射的观察一致。
- [[方向/AI语音/模型/mSGMSE|mSGMSE]] / [[方向/AI语音/模型/SGMSE+|SGMSE+]]：同为"扩散先验做语音逆问题"的路线，均是单通道增强侧的对照。
- [[方向/AI语音/知识/生成式语音增强/扩散模型与语音|扩散模型与语音]] / [[方向/AI语音/知识/生成式语音增强/SE Generative Prior（语音增强生成先验）|SE Generative Prior]]：本方法的先验来源与范式归属。
- [[方向/AI语音/知识/技术路线/Generative Multichannel SE（生成式多通道语音增强）|Generative Multichannel SE]] / [[方向/AI语音/知识/技术路线/Efficient Multichannel SE（多通道语音增强高效化）|Efficient Multichannel SE]]：本文在"生成式多通道化"与"多通道高效化"两条线上的具体落点（MC-BUDDy → USD-DPS 的算力-精度取舍）。
- [[方向/AI语音/团队/UIUC SiNRG（UIUC 信号推断研究组）|UIUC SiNRG]]、[[方向/AI语音/团队/Z.-Q. Wang Group（Zhong-Qiu Wang 组）|Z.-Q. Wang Group]]：提出团队。
- [[方向/AI语音/团队/UHH Gerkmann Group（汉堡大学 Gerkmann 组）|UHH Gerkmann Group]]：BUDDy 的作者组，本文的直接前作与主要对照。
- [[方向/AI语音/知识/基础概念/MCLP（多通道线性预测）|MCLP]]：WPE 的所属框架，本文用它做暖启动与基线（本 vault 内尚无 WPE 独立页）。
- [[方向/AI语音/数据集/LibriTTS|LibriTTS]]：扩散先验的训练语料（train-clean-{100,360}）。
- [[方向/AI语音/评估/SI-SDR|SI-SDR]]、[[方向/AI语音/评估/PESQ|PESQ]]、[[方向/AI语音/评估/STOI 与 ESTOI|STOI 与 ESTOI]]：本文三项指标。
- [[方向/AI语音/知识/调研与地图/Array Speech Enhancement Frontier（阵列语音增强前沿调研）|阵列语音增强前沿调研]]：无监督扩散去混响条目。

## 9. 待验证

- RIR 模型的 Adam 迭代次数 $N_{\text{its}}$、子带数 $B$、正则项 $R(\psi)$ 的具体形式——论文只说"$N_{\text{its}}$ iterations"并外链到 BUDDy，本页未记数值。
- 参数规模、RTF、显存与训练成本（论文只给绝对处理时间，无 RTF / 参数量）。
- 输出与真值的对齐 / 内容保真：SI-SDR 系统性偏低被归因于"错位"，但论文没有 WER / ASR 类下游验证，也没有幻觉率评估。
- 真实录音（非仿真 WSJ0CAM）上的表现；论文全程仿真，未含真实阵列数据。
- 非白噪声（babble、点噪声源、非平稳噪声）下的退化程度——论文自认这是弱项并留作未来工作。
- 更换扩散先验（更大模型 / 其他语料）与更换采样步数（现为 200 步）对质量-成本曲线的影响。
- WSJ0CAM-DEREVERB 的独立页缺失，T60 / 阵列参数只能从本文转述。

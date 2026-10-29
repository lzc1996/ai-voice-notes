---
title: Uni-ArrayDPS
类型: 方法
发表时间: 2026-03
时间依据: arXiv 首次提交日
任务:
  - 语音增强
  - 多通道增强
  - 语音分离
团队:
  - "[[方向/AI语音/团队/UIUC SiNRG（UIUC 信号推断研究组）]]"
  - "[[方向/AI语音/团队/Meta Audio AI（Meta 音频 AI 团队）]]"
开放状态:
  - paper
  - demo
aliases:
  - Uni ArrayDPS
  - Unified Diffusion Refinement for Multi-Channel Speech Enhancement and Separation
  - 统一扩散精修
tags:
  - 类型/对象
  - 方向/AI语音
  - 任务/语音增强
  - 任务/多通道增强
  - 任务/语音分离
  - 主题/阵列信号
  - 主题/扩散模型
---

# Uni-ArrayDPS

## 0. 背景

- **"判别式前端 + 生成式精修"两段范式的完成形态**：前端从阵列线选型（TF-GridNet / McNet / SpatialNet），精修从生成线选型（扩散先验），两槽位可分别演化（见 [[方向/AI语音/知识/调研与地图/Array Speech Enhancement Team Map（阵列增强团队地图）|阵列增强团队地图]] 的推论）。
- **对判别式模型普适提升**：论文报告在增强与分离两类任务上稳定改善多种判别式模型——PESQ / DNSMOS / UTMOS（感知）、STOI / eSTOI（可懂度）、WER（ASR），并在真实数据集上验证。
- **接棒 ArrayDPS 家族的通用化**：[[方向/AI语音/模型/ArrayDPS|ArrayDPS]]（无监督盲分离，2025）→ ArrayDPS-Refine（增强精修，2026）→ Uni-ArrayDPS（增强 + 分离统一，2026）。

## 1. 身份

`Uni-ArrayDPS`（*Unified Diffusion Refinement for Multi-Channel Speech Enhancement and Separation*）是 [[方向/AI语音/模型/ArrayDPS-Refine|ArrayDPS-Refine]] 的扩展：用干净语音扩散先验 + diffusion posterior sampling（DPS）精修**任意强判别式多通道模型**的输出，并把精修从语音增强统一扩展到**语音分离**。作者是 [[方向/AI语音/团队/UIUC SiNRG（UIUC 信号推断研究组）|UIUC SiNRG]]（Xu、Choudhury）与 Meta Reality Labs Research（Pandey、Azcarreta、Ni、Parekh、Buye Xu）合作。

边界：与 ArrayDPS-Refine 一样是**后处理 refiner**，不是第一段增强 / 分离网络；空间信息由判别式前端先利用，扩散只负责修复回归目标带来的非线性失真和残留噪声。区别在任务覆盖：ArrayDPS-Refine 只做 enhancement，Uni-ArrayDPS 统一 enhancement + separation。

## 2. 核心机制

```text
noisy multi-channel input
  -> 任意强判别式多通道 SE / SS 模型
  -> enhanced / separated estimate
  -> 用估计 + noisy mixture 估噪声空间协方差（SCM）
  -> 干净语音扩散先验 + [[方向/AI语音/知识/生成式语音增强/DPS（扩散后验采样）|DPS]]（SCM 定似然项）
  -> refined 输出
```

关键点：

- **training-free / array-agnostic**：只要一个预训练 clean-speech diffusion prior，不针对 backbone、阵列几何或任务训练。
- **噪声 [[方向/AI语音/知识/基础概念/SCM（空间协方差矩阵）|SCM]] 显式建模**：用判别式输出和带噪混合估噪声 SCM，再代入 DPS 似然——比前身 ArrayDPS（假设白噪声）更贴近彩色 / 带噪环境。
  - 术语注（2026-10-27）："彩色"（colored）= 非白噪声，光学类比——白噪声功率谱平坦（像白光各频率等量），有色噪声能量集中在特定频段（风扇、babble 等真实环境噪声几乎全是有色的）。多通道下"双重有色"：频谱有色（功率随频点变）+ 空间有色（能量随通道/方向分布不均、通道间相关性随频点变）；白噪声假设对应 $\sigma^2 I$。操作含义：白噪声下 DPS 似然直接最小化残差能量 $\sum|\hat{N}|^2$，强噪声频段会主导梯度、把先验拉偏；SCM 加权 $\hat{\mathbf{N}}^H\hat{\Phi}_{nn}^{-1}\hat{\mathbf{N}}$（马氏距离）= 先按噪声统计白化残差再算能量，逐频点按实际噪声水平加权——$\hat{\Phi}_{nn}^{-1}$ 就是"去偏"的逆权重。
- **SCM 估计链路（§III-A）**：判别式输出（参考通道、无混响）→ **FCP**（Forward Convolutive Prediction，加权最小二乘、解析可微，滤波器帧数 $N_H=13$、$\gamma=10^{-3}$）估各源 [[方向/AI语音/知识/基础概念/ATF（阵列传递函数）|ATF]] → 卷积回得多通道混响语音估计 → $\tilde{\mathbf{N}} = \mathbf{Y} - \sum_k \tilde{\mathbf{X}}^k_{reverb}$ → 指数滑动平均 $\hat{\Phi}_{NN}(\ell,f) = \eta\,\hat{\Phi}_{NN}(\ell{-}1,f) + (1{-}\eta)\,\tilde{\mathbf{N}}\tilde{\mathbf{N}}^H$（$\eta=0.95$）。
  - 零均值复高斯假设展开（§II，Eq. 2–3，2026-10-27）：$N(\ell,f)\sim\mathcal{CN}(0,\Phi_{\text{NN}}(\ell,f))$ 三成分——①**复高斯/圆对称**：$\mathbb{E}[NN^T]=0$，二阶统计 $\Phi$ 完全刻画分布 → SCM 估计（二阶滑动平均）即分布估计，且似然有解析形式（马氏二次型），DPS 框架可行性全押在这；②**零均值**：排除确定性偏置分量（恒定谐波/底噪固定项）——非零均值无法归入协方差、会被错误吸收进 $\hat H$/$\hat X_0$；混响不在 $N$ 里（$H^k *_\ell X^k$ 已含），$N$ 是"混响源混合之后剩下"的残差；③**跨 bin 独立**：逐 $(\ell,f)$ 各自一个 M×M Hermitian $\Phi$。真实性辩护：真实噪声非高斯（babble 有高阶结构）、非平稳、非独立，但用实测残差估的 $\hat\Phi$ 仍吸收真实二阶统计（频谱+空间颜色），似然项退化为"按实际噪声水平白化加权的最小二乘"引导项——不需精确后验，只需方向大致正确（与 T′=1000 失效须从 T′≈300 起步同一逻辑：整套是近似推断，高斯是每步可算的最小代价）。Eq. 39/41 注入项 $Z\sim\mathcal{CN}(0,2I)$ 方差 ×2：DDPM 实跑在压缩 STFT 的实虚分量上，复高斯按实虚各拆一份。与 ArrayDPS 关系：家族不变（复高斯），$\sigma^2I$ → 完整 Hermitian $\Phi(\ell,f)$ 只放开协方差自由度。
- **采样后要过对齐**：DPS 似然引导不保证输出与参考通道对齐（UNSSOR/ArrayDPS 已知问题），用单帧 FCP（$N_H=1$）把生成输出对齐回参考通道，再与判别式输出插值。
- **判别 + 生成输出插值**：论文报告插值判别式与生成式输出还能进一步改善。
- **任务统一**：增强与分离共用同一套精修框架。

## 3. 核心公式

**统一任务观测模型**：

$$
\text{SE: } \mathbf{x} = \mathbf{s} + \mathbf{n}, \qquad\qquad
\text{SS: } \mathbf{x} = \sum_{k=1}^{K} \mathbf{s}_k + \mathbf{n}
$$

增强（SE）目标为单个 $\mathbf{s}$，分离（SS）目标为 $K$ 个源 $\mathbf{s}_k$；$\mathbf{n}$ 为噪声，两者共用同一套精修框架。

**噪声 SCM 估计**（判别式输出定残差）：

$$
\hat{\Phi}_{nn} = \frac{1}{T}\sum_{t=1}^{T} \left( \mathbf{x}_t - \hat{\mathbf{s}}^{disc}_t \right) \left( \mathbf{x}_t - \hat{\mathbf{s}}^{disc}_t \right)^H
$$

$\hat{\mathbf{s}}^{disc}$ 为任意强判别式多通道 SE / SS 模型的输出；$\hat{\Phi}_{nn}$ 显式建模彩色 / 带噪环境的空间噪声统计（比前身 [[方向/AI语音/模型/ArrayDPS|ArrayDPS]] 的白噪声假设更一般）。

**DPS 似然梯度（SCM 定似然项）**：

$$
\nabla_{x_\tau} \log p(\mathbf{x} | \hat{\mathbf{s}}_\tau) \approx -\frac{1}{2}\, \nabla_{x_\tau} \left( \hat{\mathbf{s}}_\tau - \mathbf{x} \right)^H \hat{\Phi}_{nn}^{-1} \left( \hat{\mathbf{s}}_\tau - \mathbf{x} \right)
$$

$\hat{\mathbf{s}}_\tau = D_\theta(x_\tau, \sigma_\tau)$ 为干净语音扩散先验的 [[方向/AI语音/知识/基础概念/Tweedie（Tweedie 公式）|Tweedie 去噪估计]]；引导项对增强与分离采用同一形式，仅目标 $\mathbf{s}$ 的定义不同。

**推导骨架：DPS 模板（§II-B Eq. 15–17）→ 本文 Eq. 30–32 的逐项映射**（2026-10-27 核对原文）：

| DPS 原式（Chung et al. 2023） | 本文对应 | 改动 |
|---|---|---|
| Eq. 15 后验得分贝叶斯分解 = 先验得分 + 似然得分 | Eq. 30 | 结构不变，扩展到 K 个源 $\bar{X}^{1:K}$ |
| Eq. 16 似然得分 $\nabla\log p(y\vert x_t) \simeq \nabla\log p(y\vert\hat{x}_0(x_t,t))$（点估计替换，Eq. 18 Tweedie） | Eq. 31–36 | 除 $\hat{X}_0^k$ 外**同时估未知退化算子**：$\hat{H}^k=\mathrm{FCP}(\hat{X}_0^k, Y)$ |
| Eq. 17 白高斯似然 $\propto -\nabla\Vert y - A(\hat{x}_0)\Vert^2 / 2\sigma_y^2$ | Eq. 32 | $\sigma_y^2 I \to \hat{\Phi}_{\mathrm{NN}}(\ell,f)$，残差变马氏形式 $\hat{N}^H\hat{\Phi}^{-1}\hat{N}$ |

DPS 的两个"不现实假设"（$A(\cdot)$ 已知、噪声白高斯）分别被 FCP 与 SCM 解决；Eq. 16 的点估计替换有偏且 $t$ 越大越不可信——采样起点 $T'$ 不能取 1000 的直接原因。

**$1/\sigma_y^2 \to \hat{\Phi}^{-1}$ 的语义升级**（2026-10-27 展开）：

- 推导：$\log p(y|x) = -\|y-A(x)\|^2/2\sigma_y^2 - M\log(\pi\sigma_y^2)$，常数项对 $x_t$ 求梯度为零 → Eq. 17 只是高斯密度求导，非新增假设；除以 $\sigma_y^2$ 的作用是把残差变成**以噪声功率为单位**的无量纲量，否则无法与先验得分相加（Eq. 15 是同量纲相加）。
- 拔河：更新 = 先验拉向干净流形（权重恒 1）+ 似然拉向解释观测（权重 $1/\sigma_y^2$）；再乘时间调度 $\sqrt{1-\bar\alpha_t}$（$\epsilon$ 形式）→ **有效步长 = 统计权重 × 时间因子**，两者随 $t$ 反向变化，这是最优 $T'$ 存在的机理。
- 白化几何：$\hat\Phi=\sum_i\lambda_i u_i u_i^H$ → $\hat N^H\hat\Phi^{-1}\hat N=\sum_i|u_i^H\hat N|^2/\lambda_i$，即残差按噪声特征方向逐个归一化——噪声强方向打折（残差多为噪声）、噪声弱方向放大（出现残差即失真），与 MVDR/子空间白化同构；标量 $\sigma^2$ 只能全局缩放，做不到方向性。
- $\xi$ 的来历：论文里根本没有显式 $\sigma_y^2$，被 $\hat\Phi^{-1}$ 顶替，而 $\hat\Phi$ 尺度随输入增益漂 + Eq. 16 有偏 → 理论权重不可信，Alg. 1 line 17 用 $\xi$ 作经验步长补（扫 0.4–1.2，$>1$ 说明理论权重偏保守）。实测：$\xi\uparrow$ → eSTOI/WER 变好（信观测、少幻觉），PESQ/DNSMOS/UTMOS 变差（噪声回来）；强前端（SpatialNet/USES2）恶化最明显。
- 复现坑：$\hat\Phi$ 的绝对尺度直接进梯度，输入电平须固定，或做 trace 归一化 $\hat\Phi\leftarrow\hat\Phi/\mathrm{tr}(\hat\Phi)\cdot M$，否则 $\xi$ 最优值跨数据集漂移。

**判别 + 生成输出插值**：

$$
\hat{\mathbf{s}} = \alpha\, \hat{\mathbf{s}}^{disc} + (1-\alpha)\, \hat{\mathbf{s}}^{gen}
$$

$\hat{\mathbf{s}}^{gen}$ 为 DPS 精修输出；论文报告判别式与生成式输出插值可进一步改善指标（插值系数 / 融合方式的具体形式待核，见待验证）。

## 4. 测试基准与性能

### 4.1. 测试基准

- **simulated ad-hoc 阵列集**：8 麦在房间内随机布放（阵列位置随机，各麦在半径 0.1 m 球内随机采样），T60 0.13–0.55 s；8–16 个干扰说话人模拟 babble、1–50 个噪声源模拟扩散噪声场；评测时取**前 4 麦与前 8 麦两档**。
- **[[方向/AI语音/数据集/RealMAN|RealMAN]]**：**仅作测试集**，任何模型（判别前端 + 扩散先验）都未在 RealMAN train 上训练——这是真实域零样本迁移测试。配置按官方仓库口径：SNR −15 ~ 5 dB、static 说话人、4 s 片段，取**前 4 麦 / 前 8 麦**两档；只测增强（分离仅在仿真集测）；CER 用 Whisper base 转写（中文，增强输出 vs ground-truth clean）。
  - **"SNR −15~5 dB" 的含义**：RealMAN 的语音（`ma_speech`）与噪声（`ma_noise`）是**同场景分开实录**的 32 通道信号，SE 测试输入 = 两者混合；噪声是真实录制（保留真实空间相干性），不是白噪声/仿真扩散场。官方口径是测试集按**实录电平**自然混合、逐条 SNR 分布均值 test ≈ −0.8 dB（附录 B.5），训练集随机混合 U[−10,15] dB，官方 SE 基线仓库训练混噪 `snr: [0,15]`、测试用预混 `ma_noisy_speech`——Uni-ArrayDPS 写的 −15~5 与三者均不完全一致，最可能是引用测试集逐条 SNR 分布范围，或自行按该区间混合；平均 ≈ −0.8 dB 属很难的条件（Noisy 行 PESQ 1.58/1.11、CER 56.6% 即由此来）。
- **判别式前端的训练集（非 RealMAN）**：论文自建仿真 ad-hoc 阵列集——DNS-Challenge 语音/噪声、鞋盒房间 3×3×2–10×10×5 m、T60 0.13–0.55 s、**8 麦在半径 0.1 m 球内逐样本随机布放**、8–16 干扰说话人 + 1–50 噪声源、image-source 法（6 阶，Pyroomacoustics）、80k 条 10 s 训练样本；SNR −10~5 dB、SIR 5~10 dB；损失 PCM（分离加 PIT）。变通道模型（TADRN/FaSNet-TAC/USES2）每 batch 随机采 2–8 麦；SpatialNet-Large 固定通道，4 麦/8 麦 × 增强/分离共训 4 个模型。
- **被精修的判别式前端**：array-agnostic 的 **[[方向/AI语音/模型/FaSNet（滤波求和网络）|FaSNet]]-TAC**、**TADRN**、**USES2**，加上固定阵列的 **[[方向/AI语音/模型/SpatialNet|SpatialNet]]**（对照）。
- **先验与采样配置**：DDPM（$T=1000$，线性 $\beta$ 1e-4 → 0.02），2-D U-Net 与 Diffiner 同结构；**工作域为压缩 STFT**（$|X|^{0.5}e^{j\angle X}$，FFT 512 / hop 128 / √Hann 窗，输入 2×256×512）；先验训练数据为 **DNS-Challenge 约 220 h 干净语音**，4 s / 16 kHz，Adam lr 1e-4、batch 64、$2.5\times10^6$ 步（8×H100）、EMA 0.9999；采样从 $T'=300\text{–}400$ 起步最优，缺省 $\xi=0.4$、$\alpha=0.5$。
- **阵列维度是运行时参数**：先验是**单通道**扩散模型，通道数 $C$ 只出现在噪声 SCM 与 FCP 回投影里，不进入任何权重 → **同一 checkpoint 直接跑 4 麦与 8 麦**，这正是它"阵列可变"的实现方式。

### 4.2. 性能指标（RealMAN，Table II 全表核对）

4 麦与 8 麦共用同一个扩散先验，只换判别式前端与通道数。消融行每组统一为：α=0（纯生成）/ ξ=0.4·α=0.5（默认）/ ξ=0.2·α=0.5 / ξ=0.6·α=0.5；下表列基线 + 默认精修 + 该组最优消融：

| 系统                          | 通道    | STOI      | eSTOI     | PESQ(NB/WB)     | SI-SDR  | CER(%)   | DNSMOS   | UTMOSv2  |
| --------------------------- | ----- | --------- | --------- | --------------- | ------- | -------- | -------- | -------- |
| Noisy                       | 4 / 8 | 0.712     | 0.533     | 1.58 / 1.11     | −6.1    | 56.6     | 1.72     | 2.09     |
| TADRN（A1）                   | 4     | 0.772     | 0.650     | 2.25 / 1.57     | −0.8    | 60.2     | 2.48     | 1.82     |
| Refined TADRN（A3，默认）        | 4     | 0.781     | 0.664     | 2.35 / 1.67     | −0.7    | 57.0     | 2.55     | 2.09     |
| TADRN（A1）                   | 8     | 0.791     | 0.673     | 2.32 / 1.63     | −0.6    | 57.0     | 2.46     | 1.84     |
| **Refined TADRN（A3，默认）**    | 8     | **0.835** | **0.747** | **2.55 / 1.87** | **0.9** | **41.0** | **2.62** | **2.45** |
| FaSNet-TAC（B1）              | 4     | 0.776     | 0.652     | 2.26 / 1.48     | −0.5    | 62.4     | 2.40     | 1.50     |
| Refined FaSNet-TAC（B3，默认）   | 4     | 0.788     | 0.668     | 2.37 / 1.58     | −0.3    | 59.4     | 2.50     | 1.82     |
| FaSNet-TAC（B1）              | 8     | 0.798     | 0.680     | 2.36 / 1.56     | 0.6     | 57.5     | 2.42     | 1.63     |
| Refined FaSNet-TAC（B3，默认）   | 8     | 0.809     | 0.696     | 2.48 / 1.67     | 0.8     | 53.5     | 2.53     | 1.94     |
| USES2（C1）                   | 4     | 0.863     | 0.778     | 2.80 / 2.09     | 1.09    | 40.2     | 2.69     | 2.71     |
| Refined USES2（C3，默认）        | 4     | 0.864     | 0.778     | 2.81 / 2.14     | 1.3     | 39.3     | 2.73     | 2.76     |
| USES2（C1）                   | 8     | 0.876     | 0.798     | 2.87 / 2.19     | 2.2     | 35.6     | 2.71     | 2.78     |
| **Refined USES2（C5，ξ=0.6）** | 8     | **0.878** | **0.800** | 2.89 / 2.23     | 2.4     | **33.7** | 2.73     | 2.79     |
| SpatialNet（D1）              | 4     | 0.853     | 0.770     | 2.62 / 1.74     | 2.2     | 40.1     | 2.64     | 2.48     |
| Refined SpatialNet（D3，默认）   | 4     | 0.854     | 0.770     | 2.66 / 1.86     | 2.4     | 40.5     | 2.72     | 2.56     |
| SpatialNet（D1）              | 8     | 0.831     | 0.743     | 2.47 / 1.71     | 0.8     | 41.5     | 2.51     | 2.36     |
| Refined SpatialNet（D3，默认）   | 8     | 0.835     | 0.747     | 2.55 / 1.87     | 1.0     | 41.1     | 2.62     | 2.45     |

五条读法：

- **麦数越多，生成式精修收益越大**：TADRN 8 麦 CER 57.0 → 41.0（−16 个点）、WB-PESQ +0.24、UTMOS +0.61；4 麦只从 60.2 → 57.0。原因是 SCM 估得越准，DPS 似然项越可信，先验才敢往干净流形推。
- **前端排名仿真→真实翻转**：仿真集上 TADRN 大幅领先 FaSNet-TAC，RealMAN 上 FaSNet-TAC 反超（论文明确点名这一现象）——判别式前端的真实域泛化差异大，精修收益随之变化（TADRN 8 麦 −16% CER vs FaSNet-TAC 仅 −4%）。
- **USES2 泛化最强**：原始输出 CER 40.2/35.6 已反超 SpatialNet；ξ=0.6 精修到 33.7（全表 8 麦最低 CER）。强前端上精修收益变小（+0.016 eSTOI / +0.05 UTMOS 量级），**前端越弱、精修补得越多**。
- **SpatialNet 的收益集中在感知**：WB-PESQ +0.12、UTMOS +0.08~0.09，可懂度几乎不动（CER 40.1→40.5 反而微升）——固定阵列模型输出"内容正确"，缺的是自然度。
- **纯生成（α=0）与插值（α=0.5）各有所长**：α=0 时 DNSMOS/UTMOS 更高（TADRN 4 麦 UTMOS 1.82→2.28）但 CER 几乎不降（60.2→59.4）；α=0.5 时 CER/eSTOI 明显更好。判别式锚点对内容保持必要；ξ 加大（0.6）普遍进一步降 CER 但压 DNSMOS/UTMOS。

**与仿真集（Table III）对照**：仿真集上 SpatialNet 是绝对冠军（8 麦分离 WER 19.8，精修后 17.4），USES2 次之，FaSNet-TAC 最弱（WER 69.1，精修后 53.9、+15 个点，**FaSNet-TAC 精修收益最大**）。

模拟集上论文给的相对增益：eSTOI +0.04、WB-PESQ +0.2、WER 相对降 10%、UTMOS +0.5（以 FaSNet-TAC 为前端）。

**与 CaSNet / DiT-Flow 的数字不可横比**：这里是 SNR −15~5 dB、4/8 麦、16 kHz、精修范式；[[方向/AI语音/评估/RealMAN 测试结果清单|RealMAN 清单]] A 组是 −5~15 dB、6 麦、判别式；B 组是 8 kHz 单通道生成式。三组口径不同。

## 5. 使用判断

- 适合：已有强判别式多通道增强 / 分离模型，输出有音乐噪声、非线性失真、听感不自然。
- 适合：固定或未知阵列、单任务或多任务都可试（声明 array-agnostic、task-general）。
- 不适合：硬实时通话、低算力端侧；DPS 采样计算成本高，定位离线后处理。
- 风险：扩散精修提升自然度，但需检查内容保持、说话人一致性和弱语音段幻觉。

## 6. 关键来源

- [Unified Diffusion Refinement for Multi-Channel Speech Enhancement and Separation](https://arxiv.org/abs/2603.24810)
  - 内容定位：Uni-ArrayDPS 原始论文，把 ArrayDPS-Refine 扩展为 enhancement + separation 统一 diffusion refinement。
  - 用途：方法定义、作者（UIUC × Meta RL）与评测结果；Table I/II 于 2026-10-27 按 arXiv v1 全文逐格复核（含 RealMAN 4/8 麦）。
  - 核验日期：2026-10-27
- [Uni-ArrayDPS audio demos](https://xzwy.github.io/Uni-ArrayDPS/)
  - 内容定位：官方音频样例页（对应仓库 `XZWY/Uni-ArrayDPS`，仅 demo 页无代码，2026-10-27 核）。
  - 用途：比较 enhancement 与 separation 两类任务的精修效果。
  - 核验日期：2026-08-05

## 7. 相关对象

- [[方向/AI语音/模型/ArrayDPS-Refine|ArrayDPS-Refine]]：前身，只做多通道增强精修；Uni-ArrayDPS 是其任务统一扩展。
- [[方向/AI语音/模型/AMDM-SE|AMDM-SE]]：直接吃多通道输入的扩散增强模型（生成式为主），与本方法"判别前端 + 扩散后处理"互补。
- [[方向/AI语音/模型/McNet|McNet]] / SpatialNet：可作为被精修的判别式前端。
- [[方向/AI语音/模型/PGUSE|PGUSE]]：单通道预测-生成双分支，对照"判别式 + 生成式"的另一条组织方式。
- [[方向/AI语音/知识/基础概念/ATF（阵列传递函数）|ATF]]：DPS 里被 FCP 在线估计的前向算子；$N_H=13$ 近似完整 ATF、$N_H=1$ 退化为 RTF 型对齐。
- [[工程/Uni-ArrayDPS 复现方案|Uni-ArrayDPS 复现方案]]：只写 training-free 精修器、先验与前端换外部资产的切法，含 9 项数值自检与 7 条待核。
- [[方向/AI语音/知识/调研与地图/Array Speech Enhancement Frontier（阵列语音增强前沿调研）|阵列语音增强前沿调研]]：两段式范式在多通道生成式增强中的地位。
- [[方向/AI语音/知识/调研与地图/Array-Agnostic SE SOTA（阵列可变语音增强SOTA调研）|Array-Agnostic SE SOTA]]：离线生成式精修候选；与判别式前端和无监督 BSS 分协议比较。

## 8. 待验证

- ~~是否有官方代码~~（2026-10-27 已核：**无代码**——`XZWY/Uni-ArrayDPS` 仓库只是 demo 页；前身 ArrayDPS/ArrayDPS（ICML 2025）有码，可作复现底座）。
- 在固定会议阵列、中文会议、低 SNR 样本上，对 PESQ/STOI/SI-SDR、DNSMOS、SpkSim、WER 的真实影响。
- DPS 采样步数、延迟与显存是否允许作为离线后处理（与 ArrayDPS-Refine 共用评估口径）。
- ~~插值系数 $\alpha$~~（论文已给：$\hat{\mathbf{X}} = \alpha\tilde{\mathbf{X}} + (1{-}\alpha)\mathbf{X}_{align}$，默认 $\alpha=0.5$；$\alpha=0$（纯生成）DNSMOS/UTMOS 常更高但内容保持弱；SpatialNet 前端需 $\alpha>0.3$ 才改善）。
- 未见阵列泛化只验到"4 麦 / 8 麦同房间随机布放"这一档：**未见拓扑**（线阵 vs 环阵）、**通道缺失**（部分麦失效）、**麦数极端少（2–3 麦）**均无实验。
- RealMAN 上只用了 static 子集与前 4/8 麦，移动声源、其余 24 路麦未测；与 RealMAN 官方 Variable-Array 档（2–8 麦随机子阵训练、5 麦未见阵测试）不是同一设置。
- 采样成本：$T'$ 300–400 步 + 每步一次先验前向，论文未报 RTF 与显存，离线后处理定位需实测。

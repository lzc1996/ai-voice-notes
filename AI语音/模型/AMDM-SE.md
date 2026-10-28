---
title: AMDM-SE
类型: 模型
发表时间: 2026-01-19
时间依据: arXiv 首次提交日
任务:
  - 语音增强
  - 多通道增强
团队:
  - "[[方向/AI语音/团队/BGU Speech Enhancement Group（本古里安大学语音增强组）]]"
开放状态:
  - paper
  - demo
aliases:
  - AMDM-SE
  - Attention-based Multichannel Diffusion Model for Speech Enhancement
  - Attention-based Multichannel Diffusion Model
  - AMDM SE
  - Cross-Channel TF-Attention diffusion SE
tags:
  - 类型/对象
  - 方向/AI语音
  - 任务/语音增强
  - 任务/多通道增强
  - 主题/阵列信号
  - 主题/扩散模型
---

# AMDM-SE

## 0. 背景

**问题现场**：多麦设备普及，多通道语音增强需求增长，但多通道扩散式增强尚处萌芽期。

**前序路线的缺口**：此前扩散增强（如单通道 SGMSE+）只能看参考通道，多通道工作又很少用 attention 做空间建模。

**AMDM-SE 的切入点**：把多通道输入送入 complex STFT 域 score-based diffusion 模型，并用 Cross-Channel TF-Attention 显式利用跨通道空间信息。

## 1. 身份

`AMDM-SE`（Attention-based Multichannel Diffusion Model for Speech Enhancement）是 Renana Opochinsky 与 Sharon Gannot 提出的多通道扩散式语音增强模型。它把 [[方向/AI语音/知识/基础概念/Array Audio Signal（阵列音频信号）|麦克风阵列]] 输入送入 complex STFT 域的 score-based diffusion 模型，并用 **Cross-Channel TF-Attention** 显式利用跨通道空间信息。动机：多麦设备普及，但"多通道扩散增强仍处于萌芽期"，且此前工作很少用 attention 做空间建模。

边界：AMDM-SE 是多通道 noise reduction / speech enhancement 模型，不是 [[方向/AI语音/知识/基础概念/Beamforming（波束形成）|beamforming]] 公式，也不是 [[方向/AI语音/评估/CHiME（语音分离与识别挑战赛）|CHiME]] 这种识别 benchmark。它在 CHiME-3 上评测增强质量，但 CHiME 本身主线仍是 ASR。

## 2. 核心机制

```text
multichannel waveform
  -> complex STFT per channel（动态范围压缩 α=0.5, β=3）
  -> reference channel + remaining channels
  -> Cross-Channel TF-Attention（扩散网络前 + bottleneck 内两处）
  -> score network：[[方向/AI语音/知识/基础概念/NCSN++（噪声条件分数网络）|NCSN++]] 扩展处理多通道实/虚部 STFT
  -> 反向采样（PC sampler，T=30 步）
  -> enhanced single-channel STFT
  -> iSTFT waveform
```

### 2.1. 扩散建模（score-based，[[方向/AI语音/模型/SGMSE+|SGMSE+]] 同款配置）

输入特征做动态范围压缩：

$$
x_m(\ell,k) \leftarrow \beta\,|x_m(\ell,k)|^{\alpha}\, e^{i\angle(x_m(\ell,k))}, \qquad \alpha=0.5,\ \beta=3
$$

**前向过程**是干净谱与含噪谱之间的均值插值（而非纯加噪）：

$$
\mu_t = e^{-\gamma t}\, s_0 + (1 - e^{-\gamma t})\, x,
\qquad
\sigma_t^2 = \sigma_{\min}^2\, \frac{\left(\frac{\sigma_{\max}}{\sigma_{\min}}\right)^{2t} - e^{-2\gamma t}}{2\log\frac{\sigma_{\max}}{\sigma_{\min}}}
$$

$$
s_t = \mu_t + \sigma_t\, z
$$

**训练目标**（score matching）：

$$
L = \mathbb{E}\left[\, \lambda(t)\, \left\| \text{score}_\theta + \frac{s_t - \mu_t}{\sigma_t^2} \right\|^2 \,\right]
$$

**超参**：$\gamma=1.5$、$\sigma_{\min}=0.05$、$\sigma_{\max}=0.5$、$T=30$、$t_\varepsilon=0.03$——与 [[方向/AI语音/模型/SGMSE+|SGMSE+]] 完全一致。

**反向采样**：Song et al. 2020 的 predictor-corrector（PC）sampler，漂移 $f(s_t, x_{ref}) = \gamma(x_{ref} - s_t)$，扩散系数 $g(t) = \sigma_{\min}(\sigma_{\max}/\sigma_{\min})^t \sqrt{2\log(\sigma_{\max}/\sigma_{\min})}$。

关键区别：**score 以全部 $M$ 个通道（$x_{ref}$ 与其余通道）为条件**，单通道 [[方向/AI语音/模型/SGMSE+|SGMSE+]] 只能看 reference channel。

### 2.2. Cross-Channel TF-Attention

模块来源：Zhang et al. 2023 的时频 attention（原本用于单通道增强），放置**两处**——扩散网络之前 + 网络内部 bottleneck 层。

机制（输入 $M$ 通道，输出 $2M-1$ 通道）：

```text
reference channel: 频域平均池化 ─┐
其余 M−1 通道:     时域平均池化 ─┴→ 1×1 Conv → ReLU → 1×1 Conv → Sigmoid
  -> M−1 个 attention mask，逐元素乘到参考通道谱
  -> 得到 M−1 个"被另一通道条件化"的掩码表示
  -> 与原始 M 通道拼接 -> 2M−1 通道输出
```

直觉：每个 mask 表示"另一个通道的空间/能量信息如何调节参考通道的时频表示"——空间线索（如说话人相对各麦的距离/相位差导致的能量分布差异）被编码为对参考通道的选择性放大 / 抑制。

## 3. 核心公式

扩散公式在「扩散建模」一节已展开，此处补上 Cross-Channel TF-Attention 的公式化描述，并收拢扩散闭环（符号同上文；幅度压缩公式见上节）。

**前向 SDE 与扰动核**（干净谱 ↔ 参考通道含噪谱的均值插值）：

$$
ds_t = \gamma\,(x_{ref} - s_t)\,dt + g(t)\,dw, \qquad g(t) = \sigma_{\min}\left(\frac{\sigma_{\max}}{\sigma_{\min}}\right)^{t}\sqrt{2\log\frac{\sigma_{\max}}{\sigma_{\min}}}
$$

扰动核 $p_{0t}(s_t|s_0, x_{ref}) = \mathcal{N}_C(s_t;\ \mu_t,\ \sigma_t^2 I)$，$\mu_t = e^{-\gamma t}s_0 + (1-e^{-\gamma t})\,x_{ref}$；score 以全部 $M$ 个通道（$x_{ref}$ 与其余通道）为条件——单通道 [[方向/AI语音/模型/SGMSE+|SGMSE+]] 只能看参考通道，这是关键区别。

**训练目标**（score matching，同 SGMSE+ 配置）：

$$
\mathcal{L}_{DSM} = \mathbb{E}\left[ \lambda(t)\, \left\| \mathrm{score}_\theta + \frac{s_t - \mu_t}{\sigma_t^2} \right\|^2 \right]
$$

$\lambda(t)$ 为时间权重；超参 $\gamma=1.5$、$\sigma_{\min}=0.05$、$\sigma_{\max}=0.5$、$T=30$、$t_\varepsilon=0.03$ 与 SGMSE+ 完全一致。

**Cross-Channel TF-Attention 掩码**（对参考通道的条件化调制）：

$$
\mathbf{M}_m = \sigma\!\left( \mathrm{Conv}^{(2)}_{1\times1}\!\left( \mathrm{ReLU}\!\left( \mathrm{Conv}^{(1)}_{1\times1}\!\left( \left[\, \mathrm{FreqPool}(\mathbf{R}),\ \mathrm{TimePool}(\mathbf{X}_m) \,\right] \right) \right) \right) \right)
$$

$\mathbf{R}$ 为参考通道谱（频域平均池化），$\mathbf{X}_m$ 为第 $m$ 个非参考通道谱（时域平均池化），两路拼接经双层 1×1 Conv（ReLU → Sigmoid）得 $M-1$ 个 attention mask；mask 逐元素乘参考通道谱，与原 $M$ 通道拼接成 $2M-1$ 通道输入 score network——空间线索（能量随距离/相位差的空间分布）被编码为选择性放大 / 抑制。

## 4. 训练细节

- **优化**：AdamW，batch 24，validation PESQ 早停；其余沿用 SGMSE。
- **仿真数据**：LibriSpeech train-clean-360 + train-clean-100 训练、test-clean 评测（无说话人重叠，4–9 s）；**4 麦线性阵列，间距 8/6/8 cm**；镜像法 RIR，**RT60=0.2 s**，房间长宽 [4.5, 6.5] m、高 [2.5, 3] m；WHAM! babble 噪声，**SNR 均匀取自 [5, 15] dB**；8000 / 2000 / 2000 段（各 10 s）。
- **目标**：干净**无混响**信号对齐到参考通道 #0——即联合去噪 + 去混响。
- **CHiME-3**：6 通道 tablet 阵列、16 kHz；用 close-talk #0 作为 ground truth（不同于先前工作用混响第 5 通道）；train / dev / test = 7138 / 1640 / 1320 句（均长约 3 s）。

## 5. 结果口径

### 5.1. 仿真数据（PESQ ↑ / SI-SDR ↑ / eSTOI ↑）

| 方法 | PESQ | SI-SDR | eSTOI |
|---|---|---|---|
| 未处理 | 1.81 | 2.92 | 0.59 |
| SGMSE（单通道） | 2.63 | 5.37 | 0.70 |
| MC-SGMSE（多通道无 attention，本文） | 2.93 | 6.99 | 0.73 |
| **AMDM-SE（本文）** | **3.11** | **7.06** | **0.75** |

### 5.2. CHiME-3（PESQ ↑ / eSTOI ↑ / DNSMOS P.835 ↑）

| 方法 | PESQ | eSTOI | ovrl | sig | bak |
|---|---|---|---|---|---|
| 未处理 | 1.271 | 0.683 | 1.863 | 2.697 | 1.865 |
| CA Dense U-Net（原文报告值） | 2.436 | — | — | — | — |
| SGMSE | 1.96 | 0.84 | 3.128 | 3.429 | 4.072 |
| **AMDM-SE** | **2.58** | **0.91** | **3.158** | **3.492** | 3.964 |

要点：

- **attention 增益可归因**：AMDM-SE 在两组实验全部指标上超过无 attention 的 MC-SGMSE，证明"多通道 attention 显著改善降噪"。
- **对谐波结构更好**：定性谱图显示 AMDM-SE 比 SGMSE 更完整重建语音谐波结构。
- **抑噪-保真权衡**：CHiME-3 的 bak（背景）分略低于 SGMSE（3.964 vs 4.072），而 sig / ovrl 更高——抑噪激进与信号保真的取舍。
- **无法直接对比其他多通道扩散工作**（[[方向/AI语音/模型/mSGMSE|mSGMSE]]、[[方向/AI语音/模型/Multi-Stream Diffusion|multi-stream diffusion]]、[[方向/AI语音/模型/DiffCBF|DiffCBF]]）：均未开源代码 / 权重。
- **CHiME-3 不报 SI-SNR**：noisy 录音与 close-talk 目标之间存在时间错位，该指标不可靠。

## 6. 测试基准与性能

**测试基准**（条件细节见「训练细节」）：

- **仿真数据**：LibriSpeech train-clean-360/100 训练、test-clean 评测（4–9 s）；4 麦线性阵列（间距 8/6/8 cm）；镜像法 RIR，RT60 0.2 s；WHAM! babble 噪声，SNR 均匀 5–15 dB；目标为对齐参考通道 #0 的干净无混响信号。
- **CHiME-3**：6 通道 tablet 阵列、16 kHz，close-talk #0 为 ground truth；train/dev/test = 7138/1640/1320 句。
- 基线：SGMSE（单通道）、MC-SGMSE（多通道无 attention，本文消融）。

**性能指标**：完整表格见「结果口径」（仿真：PESQ 3.11 / SI-SDR 7.06 / eSTOI 0.75；CHiME-3：PESQ 2.58 / eSTOI 0.91 / OVRL 3.158），此处不重复。

## 7. 使用判断

- 适合：固定或已知几何的多麦阵列、多通道噪声抑制研究、扩散模型如何利用空间线索的对照实验。
- 不适合：硬实时语音 Agent、低算力端侧、未知/异步 ad-hoc array、只需要 WER 最优的传统 ASR 前端。
- 主要风险：扩散采样成本高（T=30 步 PC 采样，无蒸馏）；CHiME-3 是读句 noisy ASR 场景，不等于真实中文会议；多通道扩散仍是早期路线。

## 8. 关键来源

- [AMDM-SE: Attention-based Multichannel Diffusion Model for Speech Enhancement](https://arxiv.org/abs/2601.13140)
  - 内容定位：AMDM-SE 原始论文，提出 Cross-Channel TF-Attention + multichannel diffusion speech enhancement。
  - 用途：建立模型定义、发表时间、作者和实验口径。
  - 核验日期：2026-08-06
- [论文 HTML 版（ar5iv）](https://ar5iv.labs.arxiv.org/html/2601.13140)
  - 内容定位：同论文可读 HTML 版本。
  - 用途：扩散公式、attention 模块与实验表格细节。
  - 核验日期：2026-08-06
- [AMDM-SE project page](https://AMDMSE.github.io)
  - 内容定位：论文提到的音频样例项目页。
  - 用途：后续主观听感对比和样例复核入口。
  - 核验日期：2026-08-05

## 9. 相关对象

- [[方向/AI语音/模型/SGMSE+|SGMSE+]]：本模型的单通道扩散基线，扩散配置（γ/T/σ 与损失）完全沿用。
- [[方向/AI语音/知识/调研与地图/Array Speech Enhancement Frontier（阵列语音增强前沿调研）|阵列语音增强前沿调研]]：AMDM-SE 属于 2026 多通道生成式增强路线。
- [[方向/AI语音/团队/BGU Speech Enhancement Group（本古里安大学语音增强组）|BGU Speech Enhancement Group]]：vault 当前把 AMDM-SE 暂挂到该团队线索下；具体作者归属仍需核验。
- [[方向/AI语音/知识/基础概念/Array Audio Signal（阵列音频信号）|Array Audio Signal]]：AMDM-SE 依赖多通道阵列输入。
- [[方向/AI语音/知识/基础概念/IPD（通道间相位差）|IPD]]、[[方向/AI语音/知识/基础概念/MVDR（最小方差无失真响应）|MVDR]]：传统 / 判别式多通道空间线索与基线参照。
- [[方向/AI语音/模型/ArrayDPS-Refine|ArrayDPS-Refine]]：同属多通道生成式增强，但走"判别式前端 + 扩散精修"的后处理路线。
- [[方向/AI语音/模型/McNet|McNet]]：判别式多 cue 多通道增强路线。
- [[方向/AI语音/评估/CHiME（语音分离与识别挑战赛）|CHiME]]：AMDM-SE 使用 CHiME-3 评测多通道增强质量。

## 10. 待验证

- 官方代码 / 权重是否开放，以及项目页音频样例是否稳定可访问。
- 与 [[方向/AI语音/模型/mSGMSE|mSGMSE]]、[[方向/AI语音/模型/Multi-Stream Diffusion|multi-stream diffusion]]、[[方向/AI语音/模型/DiffCBF|DiffCBF]] 的直接对比（等它们开源）。
- 论文指出 RTF（相对传递函数）特征是多通道扩散的 promising 方向——跟进后续工作。
- 在真实中文会议阵列、CHiME-8 NOTSOFAR-1 或本地设备阵列上的表现。
- 与 [[方向/AI语音/模型/ArrayDPS-Refine|ArrayDPS]]、McNet、Mel-McNet、SpatialNet、MVDR + neural post-filter 的延迟 / 质量 / WER 取舍。

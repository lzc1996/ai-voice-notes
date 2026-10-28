---
title: SGMSE+
类型: 模型
发表时间: 2022-08
时间依据: arXiv 首次提交日
任务:
  - 语音增强
  - 去混响
团队:
  - "[[方向/AI语音/团队/UHH Gerkmann Group（汉堡大学 Gerkmann 组）]]"
开放状态:
  - paper
  - code
aliases:
  - SGMSE+
  - SGMSE Plus
  - Speech Enhancement and Dereverberation with Diffusion-based Generative Models
  - Speech Enhancement and Dereverberation with Diffusion-Based Generative Models
  - SGMSE-Plus
tags:
  - 类型/对象
  - 方向/AI语音
  - 任务/语音增强
  - 任务/去混响
  - 主题/扩散模型
---

# SGMSE+

## 0. 背景

**问题现场**：单通道语音增强要同时完成去噪与去混响，且追求生成式恢复质量。

**前序路线的缺口**：判别式方法的 SE 质量此前优于生成式路线。

**SGMSE+ 的切入点**：复数谱域 score-based 扩散，漂移项把过程锚定在带噪输入上，反向只需生成"干净与带噪之差"；首次证明扩散 SE 质量可超判别式方法。

## 1. 身份

`SGMSE+`（Speech Enhancement and Dereverberation with Diffusion-Based Generative Models）是汉堡大学 Gerkmann 组（Lemercier、Richter、Welker、Gerkmann，IEEE/ACM TASLP 2023，arXiv:2208.05830）提出的单通道生成式增强模型：**复数谱域 score-based 扩散，联合去噪 + 去混响**。它是"扩散做语音增强"的开创性工作——首次证明 score-based 扩散的 SE 质量可超判别式方法。

边界：单通道；纯扩散生成（从"带噪语音 + 噪声"反向采样），不像 [[方向/AI语音/模型/StoRM|StoRM]] 有判别式粗估主干；按 [[方向/AI语音/知识/生成式语音增强/SE Generative Prior（语音增强生成先验）|SE 生成先验]] 分类属于 B 类（受损语音锚定先验）——漂移项把过程均值拉向带噪输入 $y$。

## 2. 核心机制

```text
noisy/reverberant waveform
  -> complex STFT（幅度压缩 α=0.5, β=0.15）
  -> 前向 SDE：从干净谱漂移/扩散向带噪谱（μ 指数插值）
  -> score network：NCSN++（复数谱实/虚双通道输入）
  -> 反向：x_T ~ N(x_T; y, σ(T)²I) 起步，PC sampler 30 步
  -> enhanced STFT -> iSTFT
```

### 2.1. 扩散过程（SDE 公式）

**前向 SDE**：$dx_t = f(x_t, y)\,dt + g(t)\,dw$，漂移把干净语音拉向带噪/混响输入：

$$
f(x_t, y) = \gamma\,(y - x_t), \qquad
g(t) = \sigma_{\min}\left(\frac{\sigma_{\max}}{\sigma_{\min}}\right)^{t}\sqrt{2\log\frac{\sigma_{\max}}{\sigma_{\min}}}
$$

（$\sigma_{\min}=0.05$、$\sigma_{\max}=0.5$、$\gamma=1.5$，网格搜索选定）

**扰动核（闭式）**：$p_{0t}(x_t|x_0, y) = \mathcal{N}_C\!\left(x_t;\ \mu(x_0,y,t),\ \sigma(t)^2 I\right)$，其中

$$
\mu(x_0, y, t) = e^{-\gamma t} x_0 + (1 - e^{-\gamma t})\, y
$$

即干净谱与带噪谱之间的**指数插值**；方差

$$
\sigma(t)^2 = \sigma_{\min}^2\,\frac{\left(\frac{\sigma_{\max}}{\sigma_{\min}}\right)^{2t} - e^{-2\gamma t}}{\gamma + \log\frac{\sigma_{\max}}{\sigma_{\min}}}
$$

**训练目标**（[[方向/AI语音/知识/基础概念/Score Matching（分数匹配）|denoising score matching]]）：

$$
\arg\min_\theta \mathbb{E}\left[\, \left\| s_\theta(x_t, y, t) + \frac{z}{\sigma(t)} \right\|_2^2 \,\right], \qquad x_t = \mu + \sigma(t)\,z,\ z\sim\mathcal{N}_C(0,I)
$$

**反向**：plug-in reverse SDE，**不从纯高斯噪声起步**，而是 $x_T \sim \mathcal{N}_C(x_T;\ y,\ \sigma(T)^2 I)$——"带噪语音与高斯噪声的混合"。

### 2.2. 关键设计

- **信号依赖漂移**：不是把干净语音搅成高斯噪声，而是搅向带噪输入 $y$——反向时只需生成"干净与带噪之间的差异"，显著降低采样难度。
- **网络是主要限制**：论文明确"改进的架构而非形式化框架，是相对 SGMSE 的最大性能来源"。

## 3. 核心公式

（前向 SDE 与扰动核的展开式见上文「扩散过程（SDE 公式）」；此处按「压缩 → 前向 → 训练 → 反向」收拢闭环，并补充幅度压缩与反向起点两项，符号同上文。）

**复数谱幅度压缩**（输入侧预处理）：

$$
\tilde{c} = \beta\,|c|^{\alpha}\, e^{i\angle c}, \qquad \alpha = 0.5,\ \beta = 0.15
$$

$c$ 为 STFT 系数，$\tilde{c}$ 为压缩后的复数谱；幅度压缩压低大系数动态范围，缓解谐波细节与小能量成分之间的量级失衡。

**前向 SDE**（信号依赖漂移 + VE 型扩散系数）：

$$
dx_t = \gamma\,(y - x_t)\,dt + g(t)\,dw, \qquad g(t) = \sigma_{\min}\left(\frac{\sigma_{\max}}{\sigma_{\min}}\right)^{t}\sqrt{2\log\frac{\sigma_{\max}}{\sigma_{\min}}}
$$

$y$ 为带噪/混响谱（漂移锚点），$\gamma=1.5$ 控制拉向 $y$ 的强度，$\sigma_{\min}=0.05$、$\sigma_{\max}=0.5$（网格搜索选定）。

**扰动核（闭式）**：

$$
p_{0t}(x_t|x_0, y) = \mathcal{N}_C\!\left(x_t;\ e^{-\gamma t}x_0 + (1-e^{-\gamma t})\,y,\ \sigma(t)^2 I\right)
$$

均值在干净谱 $x_0$ 与带噪谱 $y$ 之间指数插值；方差 $\sigma(t)^2 = \sigma_{\min}^2\,\dfrac{(\sigma_{\max}/\sigma_{\min})^{2t} - e^{-2\gamma t}}{\gamma + \log(\sigma_{\max}/\sigma_{\min})}$ 随 $t$ 单调增大——反向只需生成"干净与带噪之差"。

**训练目标**（[[方向/AI语音/知识/基础概念/Score Matching（分数匹配）|denoising score matching]]）：

$$
\mathcal{L}_{DSM} = \mathbb{E}_{t, x_0, y, z}\left[\, \left\| s_\theta(x_t, y, t) + \frac{z}{\sigma(t)} \right\|_2^2 \,\right], \qquad x_t = e^{-\gamma t}x_0 + (1-e^{-\gamma t})\,y + \sigma(t)\,z
$$

$s_\theta$ 为 score network（NCSN++ 复数谱实/虚双通道版），$z \sim \mathcal{N}_C(0, I)$；最优时 $s_\theta = \nabla_{x_t}\log p_{0t}(x_t|x_0, y)$。

**反向采样起点**（不从纯高斯噪声起步）：

$$
x_T \sim \mathcal{N}_C(x_T;\ y,\ \sigma(T)^2 I)
$$

"带噪谱与高斯噪声的混合"作起点，配 plug-in reverse SDE 的 PC sampler（30–60 步）反向到 $t \approx 0$。

## 4. 网络与训练

- **Score network**：[[方向/AI语音/知识/基础概念/NCSN++（噪声条件分数网络）|NCSN++]] 适配复数谱（实 / 虚部分别作为输入通道）——BigGAN residual blocks（3×3 Conv、group norm、Swish、FIR 上/下采样）、16×16 分辨率与 bottleneck 全局 attention、每残差块注入 Fourier 时间嵌入、输入 / 输出路径渐进式增长、同分辨率共享下采样权重。
- **表示**：STFT 窗 510、hop 128（~75% 重叠）、F=256、Hann 窗；幅度压缩 $\tilde{c} = \beta|c|^\alpha e^{i\angle c}$，α=0.5、β=0.15。
- **数据**：WSJ0-CHiME3（SNR 0–20 dB）；VB-DMD（train SNR 0/5/10/15，test 2.5/7.5/12.5/17.5）；自建 WSJ0-REVERB（pyroomacoustics RIR，T60 0.4–1.0 s，DRR ≈ −9 dB）。
- **优化**：4× Quadro RTX 6000，160 epochs（约 1 天），Adam lr 1e-4，有效 batch 32，EMA 0.999，按 validation PESQ 选模。

## 5. 结果口径

### 5.1. VB-DMD（Table III，PESQ ↑ / ESTOI ↑ / SI-SDR ↑ / DNSMOS ↑）

| 方法 | PESQ | PESQ_nb | ESTOI | SI-SDR | DNSMOS |
|---|---|---|---|---|---|
| Mixture | 1.97 | 2.88 | 0.79 | 8.4 | 3.09 |
| SGMSE（前作） | 2.28 | 3.22 | 0.80 | 16.2 | 3.46 |
| **SGMSE+** | **2.93** | **3.66** | **0.87** | 17.3 | **3.56** |
| CDiffuSE | 2.52 | 3.31 | 0.79 | 12.4 | 3.09 |
| Conv-TasNet | 2.63 | 3.42 | 0.85 | **19.1** | 3.37 |
| MetricGAN+ | **3.13** | 3.63 | 0.83 | 8.5 | 3.37 |

SGMSE+ 超所有生成式基线；判别式 MetricGAN+ 仍领 PESQ、Conv-TasNet 领 SI-SDR。

### 5.2. WSJ0-CHiME3（Table II）

- **matched**：POLQA 3.73 / PESQ 2.96 / ESTOI 0.92 / SI-SDR 18.3 / SI-SIR 31.1 / SI-SAR 18.6 / DNSMOS 3.99——生成式第一，POLQA/SI-SIR/DNSMOS 也超判别式（Conv-TasNet 领 SI-SDR 19.9）。
- **mismatched**（VB-DMD 训练直接测）：**全指标第一**（如 PESQ 2.48 vs Conv-TasNet 2.40）——泛化性优于判别式。

### 5.3. WSJ0-REVERB 去混响（Table IV）

| 方法 | POLQA | PESQ | ESTOI | SI-SDR | SI-SIR |
|---|---|---|---|---|---|
| Mixture | 1.76 | 1.36 | 0.46 | −7.3 | −7.5 |
| SGMSE（前作） | 1.79 | 1.35 | 0.57 | −7.4 | −1.1 |
| **SGMSE+** | **3.24** | **2.66** | **0.84** | 1.6 | 9.4 |
| Conv-TasNet | 2.41 | 1.84 | 0.73 | 1.6 | **12.1** |

去混响上显著优于判别式基线，且此处未出现 vocalizing 伪影。

### 5.4. 采样成本（VB-DMD）

| 采样器 | NFE | RTF（RTX 2080 Ti） | PESQ | SI-SDR |
|---|---|---|---|---|
| PC + 1 corrector | 60 | 1.77 | 2.93 | 17.35 |
| PC + 0 corrector | 30 | 0.89 | 2.80 | 15.38 |
| 概率流 ODE（DP 4/5，tol 1e-1） | 14 | 0.46 | 2.78 | 12.83 |

一个 correction step 翻倍 NFE；2 个 corrector 无进一步 PESQ 收益。

**已知失败模式**：极低输入 SNR 下偶发 "vocalizing" 伪影（噪声段生成类语音），论文建议以语音活动 / 音素信息条件化作为后续方向。

## 6. 测试基准与性能

**测试基准**（数据条件详见「网络与训练」）：

- **VB-DMD**：VoiceBank-DEMAND 子集；训练 SNR 0/5/10/15 dB，测试 2.5/7.5/12.5/17.5 dB。
- **WSJ0-CHiME3**：WSJ0 语音 × CHiME3 噪声，SNR 0–20 dB；matched / mismatched（VB-DMD 训练直接测）双口径。
- **WSJ0-REVERB**（自建）：pyroomacoustics RIR，T60 0.4–1.0 s，DRR ≈ −9 dB。
- 基线：SGMSE（前作）、CDiffuSE、Conv-TasNet、MetricGAN+。

**性能指标**：全部数值见「结果口径」（PESQ / ESTOI / SI-SDR / POLQA / DNSMOS / RTF 表齐全），此处不重复。

## 7. 使用判断

- 适合：单通道离线、强降质（混响 + 噪声）恢复；生成式 SE 的标准基线（DiT-Flow 等 FM 论文必打它）；评估"网络 vs 形式化"差异的对照。
- 不适合：实时 / 端侧（RTF > 0.5 且需 30–60 NFE）；多通道（需 [[方向/AI语音/模型/AMDM-SE|AMDM-SE]] 类扩展）；无随机源偏好场景（确定性输出）。
- 风险：采样慢、vocalizing 伪影、判别式（MetricGAN+ / Conv-TasNet）在单指标上仍可反超。

## 8. 关键来源

- [SGMSE+: Speech Enhancement and Dereverberation with Diffusion-based Generative Models（arXiv:2208.05830）](https://arxiv.org/abs/2208.05830)
  - 内容定位：原始论文，TASLP 2023。
  - 用途：SDE 公式、网络、训练与全部实验数据。
  - 核验日期：2026-08-06
- [论文 HTML 版（ar5iv）](https://ar5iv.labs.arxiv.org/html/2208.05830)
  - 内容定位：同论文可读 HTML 版本。
  - 用途：公式与表格细节快速查阅。
  - 核验日期：2026-08-06
- [官方实现 sp-uhh/sgmse（GitHub，MIT）](https://github.com/sp-uhh/sgmse)
  - 内容定位：SGMSE / SGMSE+ 官方 PyTorch 实现 + 预训练权重（VB-DMD / WSJ0-CHiME3 / WSJ0-REVERB / EARS）。
  - 用途：复现、采样器设置（--N 50 --snr 0.33 用于 WSJ0-REVERB）与微调入口。
  - 核验日期：2026-08-06

## 9. 相关对象

- [[方向/AI语音/模型/AMDM-SE|AMDM-SE]]：直接建立在本模型配置之上（γ/T/σ 完全沿用）的多通道扩散扩展。
- [[方向/AI语音/知识/基础概念/Score Matching（分数匹配）]]：解释本模型训练目标中的 denoising score matching。
- [[方向/AI语音/模型/StoRM|StoRM]]：同组后继，判别式粗估 + 扩散再生的混合形态。
- [[方向/AI语音/模型/DiT-Flow|DiT-Flow]]：FM 系论文的头号对比基线。
- [[方向/AI语音/知识/生成式语音增强/扩散模型与语音|扩散模型与语音]]：扩散谱系全景（SGMSE+ → StoRM → DiTSE → FM 让位）。
- [[方向/AI语音/知识/生成式语音增强/SE Generative Prior（语音增强生成先验）|SE Generative Prior]]：B 类（受损语音锚定）先验代表。
- [[方向/AI语音/团队/UHH Gerkmann Group（汉堡大学 Gerkmann 组）|UHH Gerkmann Group]]：提出团队。
- [[方向/AI语音/数据集/VoiceBank-DEMAND|VoiceBank-DEMAND]]：标准评测数据集之一。

## 10. 待验证

- vocalizing 伪影的触发条件与缓解（语音活动条件化）在后续工作（含 StoRM 系）中的落实情况。
- 在 URGENT 类多失真基准上与 FM 系（FlowSE / DiT-Flow）的直接对比。
- 多通道扩展（[[方向/AI语音/模型/AMDM-SE|AMDM-SE]]、[[方向/AI语音/模型/mSGMSE|mSGMSE]]）相对单通道本体的实际增益与延迟代价。

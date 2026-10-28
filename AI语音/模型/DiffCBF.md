---
title: DiffCBF
类型: 模型
发表时间: 2025-09
时间依据: EUSIPCO 2025 会议发表
任务:
  - 语音增强
  - 语音分离
  - 去混响
  - 多通道增强
团队:
  - "[[方向/AI语音/团队/NTT Speech Group（NTT 语音组）]]"
开放状态:
  - paper
aliases:
  - DiffCBF
  - A Diffusion Model with Convolutional Beamformer for Joint Speech Separation, Denoising, and Dereverberation
  - Diffusion CBF
tags:
  - 类型/对象
  - 方向/AI语音
  - 任务/语音增强
  - 任务/语音分离
  - 任务/多通道增强
  - 任务/去混响
  - 主题/扩散模型
  - 主题/阵列信号
---

# DiffCBF

## 0. 背景

**问题现场**：多通道多源场景（噪声 + 混响 + 多说话人）下需要同时完成分离、去噪与去混响。

**前序路线的缺口**：纯扩散分离 DiffSep 性能有限（源分离 SI-SDR-Imp 仅 6.5 dB）；无训练的 CBF 单独使用也弱于 DiffSep（5.9 dB），两者各有短板。

**DiffCBF 的切入点**：把 ms-SGMSE 扩散与无训练信号处理的 Convolutional Beamformer 迭代交替耦合——CBF 输出作扩散的额外条件流，扩散估计的功率谱又作为 CBF 的 inverse Gamma 贝叶斯先验。

## 1. 身份

`DiffCBF`（A Diffusion Model with Convolutional Beamformer for Joint Speech Separation, Denoising, and Dereverberation）是早稻田大学 + NTT（Kimura、Ueda、Nakatani、Kamo、Delcroix、Araki、Makino，EUSIPCO 2025，Palermo，pp. 945–949）提出的**多通道联合分离 + 去噪 + 去混响**方法：把概率生成（[[方向/AI语音/模型/mSGMSE|ms-SGMSE]] 扩散）与无训练信号处理（Convolutional Beamformer，CBF）**迭代交替耦合**。

边界：它是"生成式 × 经典信号处理"的混合路线——不是纯扩散（对比对象是纯扩散分离 DiffSep），也不是纯波束形成；需要给定源数，不能全盲。输出是各源的干净估计，服务多源场景（会议、多说话人）的下游。

## 2. 核心机制

```text
multichannel mixture（噪声 + 混响 + 多源）
  -> 第 1 轮：CBF（MCLP 去混响 + 波束形成分离/去噪，无需训练）
       -> 每源初始干净估计
  -> ms-SGMSE：以 CBF 输出作为扩散过程的额外流（extra stream），
       对原始信号做条件扩散 -> 改进的每源估计
  -> 下一轮：CBF 接收 ms-SGMSE 估计的功率谱作为先验
       （inverse Gamma prior）-> 再迭代
  -> 收敛后输出各源干净语音
```

关键点：

- **[[方向/AI语音/知识/基础概念/CBF（卷积波束形成）|CBF]]（Convolutional Beamformer）**：纯信号处理部件——多通道线性预测（MCLP）做去混响，波束形成做分离 / 降噪，**无需训练数据**。
- **ms-SGMSE**：概率生成部件，弥合 CBF 估计与真实干净谱之间的差距。
- **迭代交替**：CBF 提供信号处理先验 → 扩散精修 → 扩散估计的功率谱作为 CBF 的贝叶斯先验（inverse Gamma）→ 逐步收敛。两套方法互相补强，而非级联一次。
- **通用性**：只要给定源数，可处理任意数量的说话人源。

## 3. 核心公式

扩散部件（ms-SGMSE）的公式同 [[方向/AI语音/模型/mSGMSE|mSGMSE]]（SGMSE+ 框架、CBF 输出作为额外条件流），此处给出 CBF 与迭代耦合两端的标准形式。

**CBF 联合去混响 + 分离 / 降噪**（论文式 (1)，MCLP 与波束形成一体式）：

$$
\hat{\mathbf{x}}^{\mathrm{CBF}}_{t,f} = \mathbf{W}_f^{H}\left( \mathbf{y}_{t,f} - \sum_{\tau=D}^{L} \mathbf{G}_{\tau,f}^{H}\, \mathbf{y}_{t-\tau,f} \right)
$$

$\mathbf{y}_{t,f}\in\mathbb{C}^{M}$ 为帧 $t$、频点 $f$ 的多通道观测，$\hat{\mathbf{x}}^{\mathrm{CBF}}_{t,f}$ 含 $N$ 路语音与 $M-N$ 路噪声估计（论文 $M=3$）；括号内为 MCLP 去混响——用过去帧多通道观测经预测矩阵 $\mathbf{G}_{\tau,f}$（预测阶 $D\le\tau\le L$，论文 $D=1$、$L=10$）减去晚期混响成分；$\mathbf{W}_f$ 为波束形成矩阵，完成分离 / 降噪。参数由最大似然估计，无需训练数据（与 WPE 同属多通道线性预测家族）。

**inverse Gamma 先验**（论文式 (4)，扩散估计 → CBF 的贝叶斯先验）：

$$
p(\lambda_{n,t,f};\theta_\lambda) = \mathrm{IG}\left(\lambda_{n,t,f};\ \alpha,\ \beta\right),\qquad \beta=\sigma^2_{n,t,f}
$$

$\lambda_{n,t,f}$ 为第 $n$ 源在 TF 点的复高斯方差，$\alpha$ 为形状参数（论文 $\alpha=1$），尺度参数 $\beta$ 取上一轮 ms-SGMSE 估计的干净功率谱 $\sigma^2_{n,t,f}$——CBF 在贝叶斯意义下把生成模型输出当作数据先验，迭代中逐步收敛。

**迭代交替耦合**（整体闭环）：

$$
\hat{s}_n^{(r)} = \mathrm{ms\text{-}SGMSE}\!\left(x,\ \mathrm{CBF}\!\left(x;\ p(\cdot \mid \hat{s}_n^{(r-1)})\right)\right)
$$

第 $r$ 轮：CBF 以第 $r-1$ 轮扩散估计的功率谱为 inverse Gamma 先验做去混响 + 波束形成，ms-SGMSE 以 CBF 输出为额外条件流精修各源估计；论文迭代 2 轮收敛，且普遍略优于 1 轮（源分离 +0.5 dB）。

## 4. 实验设置

- **数据**：WSJ0 语音 × CHiME3 噪声（10 类）各经 image method 生成的 RIR 卷积混合；房间 5×5×2 m，说话人–阵列距离 0.5–1.5 m；clean target 用同一 RIR 截断到直达声后 2 ms。
- **阵列**：M=3 麦克风，从 8 麦等距线性阵列（间距 2 cm）随机选取（MAG 训练）。
- **条件**：混响语音–噪声比 10–14 dB；T60 0.2–1.0 s；采样率 8 kHz。
- **任务**：源分离（N=2；训练 3569 / 验证 2500 / 测试 166 句）；单说话人增强（N=1，训练–测试源数失配；测试 333 句）。
- **实现**：迭代 2 轮；扩散采样 30 步 predictor-corrector，γ=1.5、c=1.07×10⁻¹、a=10.0；CBF 预测阶 D=1、L=10、α=1，分析窗 128 ms / 帧移 64 ms；score model 用 Adam（lr 1e-4）+ EMA 两阶段训练（先用无先验 CBF 输出，再用有 / 无先验两版输出重训）。
- **评估**：SI-SDR-Imp、PESQ、ESTOI、DNSMOS OVRL；ensemble 8 次采样取均值（DiffSep 需按干净参考对齐源序）。参数量 ms-SGMSE 65.8 MB / DiffSep 65.7 MB，RTF（ensemble）4.50 / 4.07。

## 5. 结果口径

源分离任务（N=2，噪声 + 混响；raw 输入 SI-SDR −8.1 dB、PESQ 1.39、ESTOI 0.32、OVRL 2.0）：

| 方法 | SI-SDR-Imp | PESQ | ESTOI | OVRL |
| --- | --- | --- | --- | --- |
| DiffSep（基线） | 6.5 dB | 2.06 | 0.42 | 3.0 |
| CBF（DiffCBF 内，迭代 1/2） | 5.9 / 5.7 dB | 1.71 / 1.74 | 0.53 / 0.54 | 2.4 / 2.4 |
| **DiffCBF（迭代 1/2）** | **14.6 / 15.1 dB** | **2.97 / 3.04** | **0.81 / 0.83** | **4.0 / 4.0** |

单说话人增强任务（N=1，源数失配；raw 输入 −3.7 dB / 1.65 / 0.46 / 2.2）：

| 方法 | SI-SDR-Imp | PESQ | ESTOI | OVRL |
| --- | --- | --- | --- | --- |
| DiffSep（取两路输出中 SI-SDR 较高者） | 6.6 dB | 2.80 | 0.60 | 3.7 |
| CBF（迭代 1/2） | 3.7 / 3.9 dB | 2.04 / 2.10 | 0.65 / 0.68 | 2.7 / 2.7 |
| **DiffCBF（迭代 1/2）** | **12.6 / 12.7 dB** | **3.47 / 3.51** | **0.88 / 0.89** | **4.1 / 4.1** |

要点：

- 大幅优于纯扩散分离基线 **DiffSep**（源分离 SI-SDR-Imp 15.1 vs 6.5 dB）；而 CBF 部件单独看反而弱于 DiffSep，增益来自扩散 × CBF 的耦合而非任一部件单独表现。
- 迭代 2 轮普遍略好于 1 轮（源分离 +0.5 dB；单说话人 +0.1 dB）。
- 源数失配（训练 N=2、测试 N=1）下依然有效。
- 评估指标为 SI-SDR-Imp / PESQ / ESTOI / DNSMOS OVRL（无 WER）；DiffCBF 输出三通道、DiffSep 单通道，只取公共通道比较。

## 6. 测试基准与性能

**测试基准**（条件细节见「实验设置」）：

- **数据**：WSJ0 语音 × CHiME3 噪声（10 类）× image method RIR；房间 5×5×2 m，说话人–阵列 0.5–1.5 m。
- **阵列 / 条件**：M=3 麦（8 麦线性阵列子集，间距 2 cm）；RSNR 10–14 dB；T60 0.2–1.0 s；8 kHz。
- **任务**：源分离（N=2；3569/2500/166 句）+ 单说话人增强（N=1，源数失配；333 句）。
- **基线 / 配置**：DiffSep（纯扩散分离）；迭代 2 轮；ensemble 8 次采样；RTF 4.50（DiffCBF）/ 4.07（DiffSep）。

**性能指标**：完整表格见「结果口径」（源分离 SI-SDR-Imp 15.1 dB vs DiffSep 6.5、PESQ 3.04；单说话人 SI-SDR-Imp 12.7、PESQ 3.51），此处不重复。

## 7. 使用判断

- 适合：多源多通道、需同时分离 + 去混响 + 去噪、源数已知的场景；研究"无训练信号处理 × 生成式"迭代耦合的路线。
- 不适合：源数未知 / 变动的场景（必须给定源数）；实时或低算力（扩散采样 + 多轮迭代）。
- 风险：迭代只报告到 2 轮，更多轮次的收益 / 收敛性未讨论；官方代码 / 权重未公开（论文基于 sp-uhh/sgmse 与 fakufaku/diffusion-separation 的公开代码修改，见关键来源）。

## 8. 关键来源

- [DiffCBF 论文 PDF（EUSIPCO 2025 官方论文集）](https://eusipco2025.org/wp-content/uploads/pdfs/0000945.pdf)
  - 内容定位：原始论文全文，含机制与实验。
  - 用途：数值细节与迭代实现口径。
  - 核验日期：2026-08-06
- [Waseda 研究库条目](https://waseda.elsevierpure.com/en/publications/diffcbf-a-diffusion-model-with-convolutional-beamformer-for-joint/)
  - 内容定位：作者、会议、页码等元数据。
  - 用途：元数据确认。
  - 核验日期：2026-08-06
- [DiffCBF 声音示例（NTT 官方 demo 页）](https://www.kecl.ntt.co.jp/icl/signal/nakatani/demos/eusipco2025/demo.html)
  - 内容定位：两个数据样本的听感对比（Observation / Clean / DiffSep / CBF / DiffCBF）+ 质量分数。
  - 用途：听觉验证。
  - 核验日期：2026-08-07
- [SGMSE 公开代码（sp-uhh/sgmse）](https://github.com/sp-uhh/sgmse)：DiffCBF 的 ms-SGMSE 部分基于此修改实现。
- [DiffSep 公开代码（fakufaku/diffusion-separation）](https://github.com/fakufaku/diffusion-separation)：基线 DiffSep 的官方实现。

## 9. 相关对象

- [[方向/AI语音/模型/mSGMSE|mSGMSE]]：扩散部件（ms-SGMSE）的直接来源，同为 NTT 生成式多通道线。
- [[方向/AI语音/模型/SGMSE+|SGMSE+]]：扩散谱系源头。
- [[方向/AI语音/知识/基础概念/WPE（加权预测误差）|WPE]]：CBF 的 MCLP 去混响与 WPE 同属多通道线性预测家族。
- [[方向/AI语音/模型/AMDM-SE|AMDM-SE]]：另一条多通道扩散路线（BGU）。
- DiffSep：纯扩散分离基线（对比对象，尚无独立笔记）。
- [[方向/AI语音/团队/NTT Speech Group（NTT 语音组）|NTT Speech Group]]：提出团队（与早稻田 Makino 组合作）。

## 10. 待验证

- 官方代码 / 权重：未公开（截至 2026-08-07，仅有论文 PDF 与 demo 页）。
- 与其他路线的直接对比：论文基线只有 DiffSep（作者称当时没有能处理该任务的多通道扩散 SE 方法）；与 [[方向/AI语音/模型/PDRE|PDRE]]（同组低 RTF 线）、mSGMSE+Ensemble、TF-GridNet 等确定性多通道方法无同条件对比口径。
- 更多迭代轮次（>2）与 N≥3 源数的泛化表现未报告。

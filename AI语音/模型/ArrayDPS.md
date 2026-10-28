---
title: ArrayDPS
类型: 方法
发表时间: 2025-05
时间依据: arXiv 首次提交日
任务:
  - 语音分离
相关方向:
  - 多通道增强
方法范式:
  - 扩散后验采样
  - 无监督盲逆问题
团队:
  - "[[方向/AI语音/团队/UIUC SiNRG（UIUC 信号推断研究组）]]"
  - "[[方向/AI语音/团队/Z.-Q. Wang Group（Zhong-Qiu Wang 组）]]"
开放状态:
  - paper
aliases:
  - ArrayDPS
  - "ArrayDPS: Unsupervised Blind Speech Separation with a Diffusion Prior"
  - Unsupervised Blind Speech Separation with a Diffusion Prior
  - 无监督盲分离扩散先验
tags:
  - 类型/对象
  - 方向/AI语音
  - 任务/语音分离
  - 主题/阵列信号
  - 主题/扩散模型
  - 主题/无监督学习
---

# ArrayDPS

## 0. 背景

**问题现场**：从麦克风阵列混合中恢复多个说话人，且阵列几何、RIR、声源全部未知，也没有配对训练数据。

**前序路线的缺口**：论文对监督式分离的三点批判——仿真训练数据难泛化到真实声学；解不唯一时判别式模型输出均值导致模糊；通常假设已知、固定的阵列几何。

**ArrayDPS 的切入点**：只用预训练单通道干净语音扩散先验 + DPS 式似然引导做无监督盲分离，每个采样步用 FCP 逐步估计未知的混合算子，IVA 初始化保证稳定性。

## 1. 身份

`ArrayDPS`（Unsupervised Blind Speech Separation with a Diffusion Prior）是 UIUC SiNRG（Zhongweiyang Xu、Xilin Jiang、Romit Roy Choudhury）× Z.-Q. Wang（SUSTech，Xulin Fan 合作），ICML 2025（arXiv:2505.05657）提出的**无监督盲语音分离**方法：从麦克风阵列混合中恢复多个说话人，且**阵列几何、RIR、声源全部未知**——只用一个预训练的**单通道干净语音扩散先验** + [[方向/AI语音/知识/生成式语音增强/DPS（扩散后验采样）|DPS]] 式似然引导。

边界：严格任务是**无监督盲语音分离**，不是狭义语音增强。它是"盲"的——失真算子同时依赖未知阵列几何与未知 RIR（区别于已知几何的 mask-based / beamforming 分离）；无监督（不需要配对训练数据，先验只需干净语音）；不是判别式分离器（TF-GridNet 类），也不是纯信号处理（IVA / clustering 类）——它是"扩散先验 + 逐采样步估计混合算子"的混合路线，[[方向/AI语音/模型/ArrayDPS-Refine|ArrayDPS 家族]] 的源头。它出现在 [[方向/AI语音增强/README|AI 语音增强]] 和阵列增强调研中，是因为同一套扩散逆问题 / refinement 思路后来迁移到多通道增强。

## 2. 对监督式分离的三点批判（论文动机）

1. **仿真-真实失配**：仿真训练数据难泛化到真实声学。
2. **确定性单解**：解不唯一时，判别式模型输出均值 → 模糊（"blurred"）。
3. **固定几何假设**：监督模型通常假设已知、固定阵列几何。

## 3. 核心机制

```text
多通道混合 x = A(s) + ε（A 未知：混响滤波-求和混合算子）
  -> IVA 初始化源与相对 RIR（关键：消融后 SDR 15.8 → 8.5 dB）
  -> 每步扩散采样：
       1. 单通道扩散 U-Net 去噪（EDM 框架，σ(τ)=τ 线性噪声调度）
       2. FCP 估计相对 RIR（Forward Convolutive Prediction，ML 等价）
       3. 似然梯度：对 U-Net + STFT + FCP 整体反向传播
       4. 先验 score + 似然 score 相加
  -> 采样 5 个样本（取均值 ArrayDPS-A 或最大似然样本 ArrayDPS-A-ML）
```

关键点：

- **测量模型**：$x = A(s) + \varepsilon$，逐麦白高斯噪声；$A$ 未知 → 标准 DPS 的似然不可计算。
- **逐采样步 ML 估计 $A$**：用当前去噪源估计 $\hat{s}$ 解 $\hat{A} = \arg\max_A p(x|\hat{s}, A)$；相对 RIR 用 **FCP** 估计（论文证明与 ML 估计等价，附录 B.2）——STFT 域加权最小二乘，权重 $\hat{\lambda}$（每 T-F bin 平均混合能量 + floor）避免高能量 bin 过拟合。
- **多帧相对 RIR**：每对虚拟源-麦克风的相对 RIR 建模为 $F$ 过去 + $P$ 未来帧的多帧滤波器，放宽"滤波器短于 FFT 尺寸"的窄带假设。
- **array-agnostic 的虚拟源模型**：每个说话人是虚拟信号 $s_k$，经估计的相对 RIR $g^k_{0 \to c}$ 映射到每个真实麦克风——不指定任何物理麦克风为参考锚点。
- **IVA 初始化**：源与相对 RIR 都用 Independent Vector Analysis 初始化，稳定性关键（消融：SMS-WSJ SDR 15.8 → 8.5 dB）。
- **先验**：预训练**单通道、单说话人**扩散去噪 U-Net（LibriTTS 干净子集，EDM/Karras 2022，线性调度）；另有一版用混响语音训练。**不需要多通道训练数据**。

## 4. 核心公式

**测量模型**：

$$
\mathbf{x} = A(\mathbf{s}) + \boldsymbol{\varepsilon}, \qquad \boldsymbol{\varepsilon} \sim \mathcal{N}(0, \sigma_\varepsilon^2 I)
$$

$\mathbf{s} = [s_1, \dots, s_K]$ 为 $K$ 个说话人信号，$A$ 为未知的混响滤波-求和混合算子（依赖未知阵列几何与 RIR），$\boldsymbol{\varepsilon}$ 为逐麦白高斯噪声；$A$ 未知 → 标准 DPS 的似然不可直接计算。

**虚拟源 + 多帧相对 RIR（STFT 域测量展开）**：

$$
x_{c,t,f} = \sum_{k=1}^{K} \sum_{\delta=-P}^{F} g^{k}_{0 \to c}(\delta, f)\, s_{k,\, t-\delta,\, f} + \varepsilon_{c,t,f}
$$

每个说话人是虚拟信号 $s_k$，经估计的相对 RIR $g^k_{0 \to c}$（$F$ 过去 + $P$ 未来帧的多帧滤波器，放宽"滤波器短于 FFT 尺寸"的窄带假设）映射到每个真实麦克风 $c$，不指定物理参考锚点。

**逐采样步 ML 估计混合算子（FCP）**：

$$
\hat{g}_\tau = \arg\min_{g} \sum_{t,f} \hat{\lambda}_{t,f} \left| x_{t,f} - \sum_{k=1}^{K} \hat{s}_{k,t,f}\, g_{k,f} \right|^2
$$

用当前去噪源估计 $\hat{\mathbf{s}}_\tau$ 解 $\hat{A}_\tau = \arg\max_A p(\mathbf{x} | \hat{\mathbf{s}}_\tau, A)$；STFT 域加权最小二乘，权重 $\hat{\lambda}_{t,f}$ 为每 T-F bin 平均混合能量 + floor，避免高能量 bin 过拟合（论文证明 FCP 与 ML 估计等价）。

**DPS 引导更新**（先验 score + 似然 score）：

$$
\nabla_{x_\tau} \log p(x_\tau | \mathbf{x}) \approx s_\theta(x_\tau, \tau) \;-\; \frac{1}{2\sigma_\varepsilon^2}\, \nabla_{x_\tau} \left\| \mathbf{x} - A_\tau(\hat{\mathbf{s}}_\tau) \right\|_2^2
$$

$\hat{\mathbf{s}}_\tau = D_\theta(x_\tau, \sigma_\tau)$ 为 EDM 框架（$\sigma(\tau)=\tau$ 线性调度）的 [[方向/AI语音/知识/基础概念/Tweedie（Tweedie 公式）|Tweedie 去噪估计]]；似然梯度对 U-Net + STFT + FCP 整体反向传播，逐采样步更新 $A_\tau$。

**样本聚合**：

$$
\hat{\mathbf{s}} = \frac{1}{M}\sum_{i=1}^{M} \mathbf{s}^{(i)} \;\; \text{（ArrayDPS-A）}
\qquad \text{或} \qquad
\hat{\mathbf{s}} = \mathbf{s}^{\left(\arg\max_i\, p(\mathbf{x}|\mathbf{s}^{(i)})\right)} \;\; \text{（ArrayDPS-A-ML）}
$$

采样 $M = 5$ 个样本，取均值或最大似然样本作为最终分离结果。

## 5. 结果口径

### 5.1. 通道 SMS-WSJ（Table 1，固定阵列）

| 方法 | SDR | SI-SDR | PESQ | eSTOI |
|---|---|---|---|---|
| IVA（Gaussian） | 13.4 | 12.2 | 2.82 | 0.834 |
| UNSSOR（无监督 SOTA） | 15.4 | 14.4 | 3.20 | 0.875 |
| ArrayDPS-A（5 样本均值） | 15.8 | 15.0 | 3.38 | 0.865 |
| **ArrayDPS-A-ML（最大似然样本）** | **16.9** | **16.2** | 3.49 | 0.884 |
| TF-GridNet-SMS（监督） | 16.8 | 16.3 | **3.91** | **0.924** |

### 5.2. Ad-hoc 4 通道 Spatialized WSJ0-2Mix（Table 2，随机几何）

- ArrayDPS-A-ML：SDR 16.6 / SI-SDR 15.8——超 UNSSOR（15.2 / 14.2）；5 样本均值 SDR 16.1 甚至超过监督式 TF-GridNet-Spatial 的 15.8（PESQ / eSTOI 仍是 TF-GridNet 赢）。
- 附录含 3 说话人（WSJ0-3Mix）与真实房间录音。

要点：**无监督逼近甚至部分超过监督式 TF-GridNet 系**（尤其 SI-SDR），但 PESQ / eSTOI 仍有差距；论文未报告运行时间 / 算力，采样 5 样本 × 多步扩散的成本未量化。

## 6. 测试基准与性能

### 6.1. 测试基准

- **3 通道 SMS-WSJ（Table 1）**：固定阵列；基线含 IVA（Gaussian）、UNSSOR（无监督 SOTA）、TF-GridNet-SMS（监督）。
- **Ad-hoc 4 通道 Spatialized WSJ0-2Mix（Table 2）**：随机阵列几何；基线含 UNSSOR、TF-GridNet-Spatial（监督）。
- **附加评估**：附录含 3 说话人 WSJ0-3Mix 与真实房间录音。
- **训练条件**：无监督——不需要多通道配对训练数据；扩散先验为预训练单通道单说话人去噪 U-Net（LibriTTS 干净子集，EDM/Karras 2022，线性调度），另有混响语音训练版本。

### 6.2. 性能指标

明细表格见上方「结果口径」（不重复堆砌），要点：

- **Table 1（3ch SMS-WSJ）**：ArrayDPS-A-ML SDR 16.9 / SI-SDR 16.2 / PESQ 3.49 / eSTOI 0.884，全面超 UNSSOR（15.4 / 14.4 / 3.20 / 0.875）与 IVA；SI-SDR 追平监督式 TF-GridNet-SMS（16.3），PESQ / eSTOI 仍有差距（3.91 / 0.924）。
- **Table 2（4ch ad-hoc）**：ArrayDPS-A-ML SDR 16.6 / SI-SDR 15.8；5 样本均值 SDR 16.1 超监督式 TF-GridNet-Spatial 的 15.8。
- **消融**：移除 IVA 初始化后 SDR 15.8 → 8.5 dB（SMS-WSJ）。
- **运行时间 / RTF**：未报告（论文），成本未量化。

## 7. 使用判断

- 适合：阵列几何未知 / 变化、无配对训练数据的真实场景分离；作为"判别式前端 + 生成精修"研究路线的方法源头。
- 不适合：实时 / 低算力（多步扩散 + 逐步 FCP 与反向传播）；需要强感知指标的场合（PESQ/eSTOI 不如监督式）。
- 风险：采样成本高；IVA 初始化质量直接影响稳定性；5 样本采样有方差（论文用均值/ML 选择缓解）。

## 8. 关键来源

- [ArrayDPS: Unsupervised Blind Speech Separation with a Diffusion Prior（arXiv:2505.05657）](https://arxiv.org/abs/2505.05657)
  - 内容定位：原始论文，ICML 2025。
  - 用途：FCP 公式、虚拟源模型、实验与消融。
  - 核验日期：2026-08-07
- [论文 HTML 版（ar5iv）](https://ar5iv.labs.arxiv.org/html/2505.05657)
  - 内容定位：同论文可读 HTML 版本。
  - 用途：公式与附录细节（IVA 消融、3 说话人实验）。
  - 核验日期：2026-08-07

## 9. 相关对象

- [[方向/AI语音/知识/生成式语音增强/DPS（扩散后验采样）|DPS]]：本方法的似然引导机制；ArrayDPS 是"DPS + 逐步估计观测算子"的推广。
- [[方向/AI语音/模型/ArrayDPS-Refine|ArrayDPS-Refine]]：家族后继——由盲分离转向判别式输出精修（training-free）。
- [[方向/AI语音/模型/Uni-ArrayDPS|Uni-ArrayDPS]]：家族通用化——增强 + 分离统一，噪声 SCM 显式建模。
- [[方向/AI语音/模型/MeCo|MeCo]]：两段式另一分支——训练式一步校正（对比本方法的 training-free 迭代）。
- [[方向/AI语音/团队/UIUC SiNRG（UIUC 信号推断研究组）|UIUC SiNRG]]、[[方向/AI语音/团队/Z.-Q. Wang Group（Zhong-Qiu Wang 组）|Z.-Q. Wang Group]]：提出团队。
- [[方向/AI语音/知识/调研与地图/Array Speech Enhancement Frontier（阵列语音增强前沿调研）|阵列语音增强前沿调研]]：无监督扩散（ArrayDPS 线）条目。

## 10. 待验证

- 官方代码 / 权重；运行时间与算力量化。
- 真实会议阵列（CHiME 类）与中文场景下的分离质量与稳定性。
- 与监督式 TF-GridNet 系在感知指标（PESQ/eSTOI）差距的收敛速度（家族后续是否缩小）。

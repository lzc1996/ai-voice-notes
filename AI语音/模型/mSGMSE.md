---
title: mSGMSE
类型: 模型
发表时间: 2024-04
时间依据: ICASSP 2024 Workshop（HSCMA 2024）发表
任务:
  - 语音增强
  - 去混响
  - 多通道增强
团队:
  - "[[方向/AI语音/团队/NTT Speech Group（NTT 语音组）]]"
开放状态:
  - paper
aliases:
  - mSGMSE
  - multi-stream SGMSE
  - MIMO SGMSE
  - Diffusion Model-Based MIMO Speech Denoising and Dereverberation
  - MS-SGMSE
tags:
  - 类型/对象
  - 方向/AI语音
  - 任务/语音增强
  - 任务/多通道增强
  - 任务/去混响
  - 主题/扩散模型
  - 主题/阵列信号
---

# mSGMSE

## 0. 背景

**问题现场**：多通道语音增强在去噪去混响的同时必须保留通道间空间线索（ITD/ILD），以服务定位、双耳渲染与 ASR 下游。

**前序路线的缺口**：逐通道独立应用 SGMSE 会破坏通道间协调性、丢失空间线索。

**mSGMSE 的切入点**：把 SGMSE 扩展到 MIMO——用条件扩散模型对干净多通道信号的联合条件分布建模，反向过程一次生成全部通道，天然保证通道间相关性。

## 1. 身份

`mSGMSE`（multi-stream SGMSE，MIMO 扩散增强）是早稻田大学 + NTT（Kimura、Nakatani、Kamo、Delcroix、Araki、Ueda、Makino，ICASSPW 2024 / HSCMA 2024，pp. 455–459）把 [[方向/AI语音/模型/SGMSE+|SGMSE]] 扩展到 **[[方向/AI语音/知识/基础概念/MIMO（多输入多输出）|MIMO]]（多输入多输出）** 的生成式增强模型：用条件扩散模型联合生成多麦克风的干净语音信号，**保留通道间空间线索（[[方向/AI语音/知识/基础概念/ITD（耳间时间差）|ITD]] / [[方向/AI语音/知识/基础概念/ILD（双耳声级差）|ILD]]）**——不仅服务听感，也服务定位与 ASR 下游。

边界：它是生成式 MIMO 增强（联合生成所有通道），不同于判别式 MIMO（如 McNet 类逐通道/多 cue 掩码）——逐通道独立应用 SGMSE 会破坏通道间协调性、丢失空间线索。它不依赖固定阵列几何（论文提出适配未知几何的技术），不是 beamforming 公式。

## 2. 核心机制

```text
distant-mic noisy/reverberant multichannel
  -> 可选：WPE 预去混响（对 mSGMSE 增益大于逐通道 SGMSE）
  -> 条件扩散：对"给定多通道观测下的干净多通道信号"的条件分布建模
  -> 反向扩散生成多麦干净信号（空间线索保留）
  -> 下游：双耳渲染 / 定位 / ASR
```

要点：

- **MIMO 条件扩散**：干净多通道信号的条件分布 $p(s_{1:M} | x_{1:M})$ 由 score-based 扩散建模，反向过程直接生成全部通道——通道间相关性由联合分布天然保证。
- **vs 逐通道 SGMSE**：逐通道独立生成每个通道，输出间缺乏协调（ITD/ILD 被破坏）；mSGMSE 联合生成保持空间线索，且质量、空间线索、计算时间全面更优。
- **几何适应性（MAG 训练）**：score model 用 **Multiple Array-Geometry（MAG）训练**，训练集覆盖 2–14 cm 多种麦间距的模拟几何；架构上是 MNCSN++（NCSN++ 改造的多通道版），U-Net 主体参数在各通道流间共享，因此**算力与麦数基本无关**（论文称处理全阵约等于 SGMSE 处理单麦）。REVERB challenge real 数据（含训练未见几何）上 ASR 仍显著提升。注意：**实验中的麦数是 2**，所以“几何可变”已验证、“麦数可变”只是结构上允许，未被实验证实（见待验证）。
- **WPE 协同**：[[方向/AI语音/知识/基础概念/WPE（加权预测误差）|WPE]] 预去混响对 mSGMSE 的增益大于对逐通道 SGMSE 的。

## 3. 核心公式

mSGMSE 与 [[方向/AI语音/模型/SGMSE+|SGMSE+]] 共用同一 SDE 框架，差别是把单通道谱推广为**通道堆叠向量**（$M$ 个通道的复数谱向量 $s, x \in \mathbb{C}^{M F}$ 联合建模）；具体拼接与条件化方式按标准形式写出（具体形式待核，见待验证）。

**建模目标**（MIMO 条件分布）：

$$
p(s_{1:M} \mid x_{1:M})
$$

$s_{1:M}$、$x_{1:M}$ 分别为各通道干净谱与观测谱（复数 STFT 域）；score-based 扩散直接建模该联合条件分布，反向一次生成全部通道——通道间相关性由联合分布天然保证，空间线索（ITD/ILD）不被破坏。

**前向 SDE**（沿用 SGMSE+ 的信号依赖漂移，对象推广为通道向量）：

$$
ds_t = \gamma\,(x_{1:M} - s_t)\,dt + g(t)\,dw, \qquad g(t) = \sigma_{\min}\left(\frac{\sigma_{\max}}{\sigma_{\min}}\right)^{t}\sqrt{2\log\frac{\sigma_{\max}}{\sigma_{\min}}}
$$

扰动核 $p_{0t}(s_t|s_0, x_{1:M}) = \mathcal{N}_C(s_t;\ e^{-\gamma t}s_0 + (1-e^{-\gamma t})\,x_{1:M},\ \sigma^2(t)I)$；超参 $\gamma=1.5$、$\sigma_{\min}=0.05$、$\sigma_{\max}=0.5$ 同 SGMSE+。

**训练目标**（score matching，score 以全部通道为条件）：

$$
\mathcal{L}_{DSM} = \mathbb{E}\left[\, \left\| s_\theta(s_t, x_{1:M}, t) + \frac{z}{\sigma(t)} \right\|_2^2 \,\right], \qquad s_t = \mu(s_0, x_{1:M}, t) + \sigma(t)\,z
$$

$z \sim \mathcal{N}_C(0, I)$；逐通道独立应用 SGMSE 相当于忽略跨通道条件、输出间缺乏协调，此处联合条件保证通道间协调。

**反向生成**（plug-in reverse SDE + PC 采样）：

$$
ds_t = \left[\, \gamma\,(x_{1:M} - s_t) - g(t)^2\,\nabla_{s_t}\log p_t(s_t|x_{1:M}) \,\right] dt + g(t)\,d\bar{w}
$$

score 由 $s_\theta$ 近似，起点 $s_T \sim \mathcal{N}_C(s_T;\ x_{1:M},\ \sigma(T)^2 I)$；输出即多通道干净谱，供双耳渲染 / 定位 / ASR 下游使用。

## 4. 结果口径

- **vs 逐通道 SGMSE**：信号质量、空间线索（ITD/ILD 保持）、计算时间三项全面优于。
- **ASR 收益**：REVERB challenge **real** 数据上 ASR 显著改善——该数据与训练集存在大失配（含未见过的阵列几何），说明跨几何泛化。
- **后续变体数据**（NTT demo 页）：mSGMSE+Ensemble（与确定性 NN 增强集成推理）SI-SDR 8.1 / PESQ 2.58 / ESTOI 0.86，但 **RTF 7.87**（极慢）；后续 PDRE（概率-判别式递归增强，ICASSP 2025）同等质量下 RTF 不到其 1/100。
- 注：论文摘要未给出完整数值表，具体指标见全文（见待验证）。

## 5. 测试基准与性能

**测试基准**：

- **REVERB Challenge**：simulated + real；real 数据与训练集大失配（含训练未见的阵列几何），评测增强质量与 ASR 下游；demo 页确认 real 为 2 通道录音（NTT demo 页）。
- 仿真条件：远场多通道带噪混响，可选 WPE 预去混响前端（对 mSGMSE 增益大于逐通道 SGMSE）。
- 基线：逐通道 SGMSE、mSGMSE+Ensemble、detNN（见 PDRE 对比）。

**性能指标**：

- vs 逐通道 SGMSE：质量、空间线索（ITD/ILD 保持）、计算时间全面更优（论文口径，具体数值待核）。
- REVERB real：ASR 显著改善，具体 WER 待核。
- mSGMSE+Ensemble（NTT demo 页）：SI-SDR 8.1 / PESQ 2.58 / ESTOI 0.86，RTF 7.87（数字已在「结果口径」，此处仅汇总）。

## 6. 使用判断

- 适合：需要保留空间线索的多通道恢复（双耳渲染、声源定位、ASR 前端）；未知 / 多变阵列几何的研究场景。
- 不适合：实时 / 端侧（扩散采样成本高，Ensemble 版 RTF 近 8）；只需单通道听感的场景（判别式 MIMO 更划算）。
- 风险：官方代码 / 权重未公开——与 [[方向/AI语音/模型/AMDM-SE|AMDM-SE]] 等其他多通道扩散路线的直接对比至今做不了。

## 7. 关键来源

- [Diffusion Model-Based MIMO Speech Denoising and Dereverberation（IEEE ICASSPW 2024）](https://ieeexplore.ieee.org/abstract/document/10626291)
  - 内容定位：mSGMSE 原始论文（HSCMA 2024，DOI 10.1109/ICASSPW62465.2024.10626291）。
  - 用途：方法定义、实验口径与结论。
  - 核验日期：2026-08-06
- [NTT 联合去噪去混响声音 demo（IWAENC 2024）](https://www.kecl.ntt.co.jp/icl/signal/nakatani/demos/iwaenc2024/demoE.html)
  - 内容定位：NTT 官方多通道扩散 demo 页。
  - 用途：主观听感对比入口。
  - 核验日期：2026-08-06
- [NTT 扩散增强 demo 与 PDRE 对比页（ICASSP 2025）](https://www.kecl.ntt.co.jp/icl/signal/nakatani/demos/icassp2025/demo.html)
  - 内容定位：mSGMSE+Ensemble vs PDRE 的指标与 RTF 对比。
  - 用途：mSGMSE 系与低 RTF 后续方案的量化口径。
  - 核验日期：2026-08-06

## 8. 相关对象

- [[方向/AI语音/模型/SGMSE+|SGMSE+]]：单通道前身与逐通道基线。
- [[方向/AI语音/模型/AMDM-SE|AMDM-SE]]：另一条多通道扩散路线（BGU，跨通道 TF-attention）——均未开源，无法直接对比。
- [[方向/AI语音/知识/基础概念/WPE（加权预测误差）|WPE]]：预去混响前端，与 mSGMSE 协同增益更大。
- [[方向/AI语音/团队/NTT Speech Group（NTT 语音组）|NTT Speech Group]]：提出团队（与早稻田 Makino 组合作）。
- [[方向/AI语音/知识/调研与地图/Array Speech Enhancement Team Map（阵列增强团队地图）|阵列增强团队地图]]：NTT 生成式布局条目（mSGMSE / multi-stream diffusion / DiffCBF）。
- [[方向/AI语音/模型/DiffCBF|DiffCBF]]：同系后续（EUSIPCO 2025，扩散 × 卷积波束形成迭代耦合，联合分离+去噪+去混响）。
- [[方向/AI语音/模型/Multi-Stream Diffusion|Multi-Stream Diffusion]]：同系同名异文（IWAENC 2024，概率式集成 CSM+WPE 的多流条件扩散）。
- [[方向/AI语音/模型/PDRE|PDRE]]：同系后续（ICASSP 2025，概率-判别式递归增强，扩散级质量、RTF < 1/100）。

## 9. 待验证

- 论文全文的具体数值（质量 / 空间线索指标、算力、REVERB WER）——IEEE 全文不可直接抓取，需人工补。
- 官方代码 / 权重是否开放。
- 与 AMDM-SE、ArrayDPS-Refine 等生成式多通道路线的直接对比（等开源）。
- MIMO 扩散公式的具体形式（通道堆叠与条件化方式）——核心公式小节按 SGMSE+ 标准形式推广写出，IEEE 全文不可直接抓取，待人工核验。
- MAG 训练覆盖的麦间距为 2–14 cm，但**训练/测试的麦数是否变化**未见明确说明；若要做阵列可变横评，需确认它能否在 3/4/8 麦上直接推理，别把"几何无关"当成"麦数无关"。

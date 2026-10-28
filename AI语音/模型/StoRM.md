---
title: StoRM
类型: 模型
发表时间: 2023
时间依据: arXiv 首次提交 2022-12，IEEE/ACM TASLP 接受 2023
任务:
  - 语音增强
  - 去混响
相关主题:
  - 扩散模型
  - 生成式语音增强
相关模型:
  - "[[方向/AI语音/模型/PGUSE]]"
  - "[[方向/AI语音/模型/GAP-URGENet]]"
  - "[[方向/AI语音/模型/DiT-Flow]]"
开放状态: []
aliases: []
tags:
  - 类型/对象
  - 方向/AI语音
---
# StoRM

## 0. 背景

- **解决纯扩散的伪影问题**：纯扩散在恶劣条件下（低 SNR）会产生"vocalizing / breathing artifacts"（音素混淆类伪影）；预测式引导能消掉这类伪影，同时保留扩散的高质量生成。
- **计算量降一个量级**：扩散模型可以只用更少的采样步数，论文报告在不牺牲质量的前提下把计算负担降低约一个数量级。
- **确立混合范式**：判别式保真 + 生成式保质——该思路后续延续到 PGUSE（output fusion + truncated diffusion）和 [[方向/AI语音/模型/GAP-URGENet|GAP-URGENet]] 融合架构，也是 ArrayDPS（多通道盲逆）的单通道前驱之一。
- **标准基线**：作为扩散谱系代表，SGMSE/StoRM 仍是 FM 系论文（如 [[方向/AI语音/模型/DiT-Flow|DiT-Flow]]）的头号对比基线。

## 1. 身份

`StoRM`（*Stochastic Regeneration Model*，随机再生模型）是汉堡大学 Gerkmann 组（Lemercier、Richter、Welker、Gerkmann）提出的扩散语音增强 / 去混响模型：**判别式预测器先粗估，扩散模型以粗估为引导再生成最终干净语音**。它是"生成 + 预测混合"路线的早期形态，SGMSE+ 之后、FM 让位之前的关键一站。

边界：StoRM 不是纯扩散（不像 SGMSE+ 从噪声一路反向采样），也不是纯判别式回归；它把扩散模型降级为"残差 / 细节再生器"，粗估主干保内容、扩散补细节。按 [[方向/AI语音/知识/生成式语音增强/SE Generative Prior（语音增强生成先验）|SE 生成先验]] 分类属于 B 类（受损语音锚定先验）：判别式粗估后从中段注入足量噪声再反向生成，人为补熵恢复生成能力。

## 2. 核心链路

```text
noisy waveform
  -> 判别式预测器（粗估干净语音 / 去混响语音）
  -> 粗估结果作为引导 + 中段注噪（截断扩散）
  -> 扩散模型逐步再生细节
  -> 最终干净语音
```

## 3. 核心公式

SDE 框架与 [[方向/AI语音/模型/SGMSE+|SGMSE+]] 一致（同一 OU 型前向、同一扰动核），差异在**反向起点**与 **score 条件**（按论文 arXiv:2212.11851 的公式写出；注意：反向仍跑完整区间 $[0,T]$、并非中段截断起步——与笔记「截断扩散」表述的口径差异见待验证）。

**前向 SDE**（漂移拉向带噪输入 $y$）：

$$
dx_\tau = \gamma\,(y - x_\tau)\,d\tau + g(\tau)\,dw, \qquad g(\tau) = \sigma_{\min}\left(\frac{\sigma_{\max}}{\sigma_{\min}}\right)^{\tau}\sqrt{2\log\frac{\sigma_{\max}}{\sigma_{\min}}}
$$

扰动核 $p_{0\tau}(x_\tau|x_0, y) = \mathcal{N}_C(x_\tau;\ e^{-\gamma\tau}x_0 + (1-e^{-\gamma\tau})\,y,\ \sigma^2(\tau)I)$，方差为闭式（同 SGMSE+ 形式）。

**反向起点：粗估替代观测**（StoRM 的标志性改动）：

$$
x_T \sim \mathcal{N}_C(x_T;\ D_\theta(y),\ \sigma^2(T)\, I)
$$

判别式预测器输出 $D_\theta(y)$（粗估干净谱）替换带噪输入 $y$ 作为反向起点——先验从"带噪锚定"改为"粗估干净锚定"，预测器保住内容、扩散只再生细节，从而消除低 SNR 下的 vocalizing 伪影。

**score 条件拼接**（论文消融 "Both" 最优）：

$$
s_\phi\!\left(x_\tau,\ y,\ D_\theta(y),\ \tau\right)
$$

score 网络的输入通道拼接为 $[y,\ D_\theta(y),\ x_\tau]$（辅以 $\sigma(\tau)$ 时间条件）；消融显示只用 $y$ 条件反而有害，两个条件都用最佳。

**反向 SDE**（plug-in reverse + PC 采样）：

$$
dx_\tau = \left[ -\gamma\,(y - x_\tau) + g(\tau)^2\, s_\phi(x_\tau, y, D_\theta(y), \tau) \right] d\tau + g(\tau)\, d\bar{w}
$$

从 $\tau=T$ 积分回 0：Euler–Maruyama predictor + 一步 annealed Langevin corrector（步长 $r=0.5$），默认 $N=50$ 步（VB-DEMAND 为 30）——计算量比纯扩散降约一个量级。

**联合训练目标**（DSM + 预测器监督）：

$$
\mathcal{J}(\theta, \phi) = \mathbb{E}_{\tau, x_0, y, z}\left[\left\| s_\phi(x_\tau, y, \tau) + \frac{z}{\sigma(\tau)} \right\|_2^2 \right] + \alpha\, \mathbb{E}_{x_0, y}\left[\left\| x_0 - D_\theta(y) \right\|_2^2 \right], \qquad \alpha = 1
$$

第一项为 denoising score matching，第二项约束预测器输出贴近干净谱 $x_0$；预测器先以 MSE 预训练再联合训练，消融显示去掉监督项（$\alpha=0$）性能崩塌（PESQ 1.11）——粗估质量直接决定生成上限。

## 4. 测试基准与性能

**测试基准**（评测面见「关键来源」）：

- **VoiceBank-DEMAND**：去噪评测（该数据集上采样 N=30 步）。
- **WSJ0 去混响**：WSJ0 × RIR 去混响评测。
- **TIMIT ASR**：下游识别评测。
- 默认采样：PC 采样 N=50 步（Euler–Maruyama predictor + 一步 annealed Langevin corrector，r=0.5），计算负担比纯扩散降约一个量级。

**性能指标**：

- 论文口径：减少采样步数不损质量，消除低 SNR 下的 vocalizing/breathing 伪影（arXiv 摘要）。
- 具体 PESQ / SI-SDR / WER 数值待核。

## 5. 现状

纯 SDE 扩散在语音增强上已鲜有新工作，StoRM 的价值以两种形态存续：混合架构思想（→ GAP-URGENet、PGUSE），以及 FM 论文的标准基线。同组后续工作把 StoRM 扩展到风噪抑制（Wind Noise Reduction with a Diffusion-based Stochastic Regeneration Model，arXiv:2306.12867）。

## 6. 关键来源

- [StoRM: A Diffusion-based Stochastic Regeneration Model for Speech Enhancement and Dereverberation](https://arxiv.org/abs/2212.11851)
  - 内容定位：原始论文。判别式预测引导 + 截断扩散再生；VoiceBank-DEMAND、WSJ0 去混响、TIMIT ASR 评测；消融覆盖采样效率与预测器失配。
  - 用途：确认机制、作者、时间和评测结果。
  - 核验日期：2026-08-03
- [sp-uhh/storm GitHub 仓库](https://github.com/sp-uhh/storm)
  - 内容定位：官方代码（含风噪扩展），与 sgmse 同组的开源生态。
  - 用途：复现 / 改写的代码入口。
  - 核验日期：2026-08-06
- [UHH Signal Processing Group StoRM 项目页](https://www.inf.uni-hamburg.de/en/inst/ab/sp/publications/storm)
  - 内容定位：项目页与音频 demo。
  - 用途：快速听样例对比增强 / 去混响效果。
  - 核验日期：2026-08-06

## 7. 相关对象

- [[方向/AI语音/模型/SGMSE+|SGMSE / SGMSE+]]：同组前作，score-based 扩散 SE 开创者，StoRM 建立在其上（谱系见 [[方向/AI语音/知识/生成式语音增强/扩散模型与语音|扩散模型与语音]]）。
- [[方向/AI语音/知识/生成式语音增强/SE Generative Prior（语音增强生成先验）|SE Generative Prior]]：B 类（受损语音锚定）先验的代表，"截断扩散中段注噪"出自此模型。
- [[方向/AI语音/模型/PGUSE|PGUSE]]：同类"预测分支 + 扩散生成分支"混合架构的后续。
- [[方向/AI语音/模型/GAP-URGENet|GAP-URGENet]]：预测 + 生成融合思想的存续形态。
- [[方向/AI语音/模型/DiT-Flow|DiT-Flow]]：FM 系后继，对比基线的对象。
- [[方向/AI语音/知识/生成式语音增强/扩散模型与语音|扩散模型与语音]]：扩散谱系全景（SGMSE+ → StoRM → DiTSE → FM 让位）。

## 8. 待验证

- StoRM 与 PGUSE 的截断扩散实现差异（注噪起点、融合方式）对质量 / 步数的影响。
- 在 URGENT 类多失真基准上，StoRM 与 FM 系（FlowSE / DiT-Flow）的直接对比数据（[[方向/AI语音/知识/生成式语音增强/SE Generative Prior（语音增强生成先验）|SE Generative Prior]] 待验证项之一）。
- 风噪扩展版本（ITG 2023）的适用场景与局限。
- 「中段注噪（截断扩散）」表述与论文口径差异：按论文（arXiv:2212.11851），反向从 $\tau=T$ 全区间起步、以预测器输出 $D_\theta(y)$ 为锚（$x_T \sim \mathcal{N}_C(x_T;\, D_\theta(y),\, \sigma^2(T)I)$），并非中段截断起步——[[方向/AI语音/知识/生成式语音增强/SE Generative Prior（语音增强生成先验）|SE Generative Prior]] 笔记中的截断表述待复核。
- 量化结果补全：VB-DEMAND PESQ/SI-SDR、WSJ0 去混响与 TIMIT WER 具体数字——arXiv 摘要无数字，TASLP 全文需人工抓取，待核。

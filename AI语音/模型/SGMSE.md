---
title: SGMSE
类型: 模型
发表时间: "2022"
时间依据: Interspeech 2022 论文；arXiv 2022-03-31 首次公开
任务:
  - 单通道语音增强
  - 生成式降噪
  - 复数谱域建模
相关主题:
  - score matching
  - SDE
  - complex STFT
  - predictor-corrector sampling
相关评估:
  - VoiceBank-DEMAND
  - WSJ0-CHiME3
  - PESQ
  - ESTOI
  - SI-SDR
  - DNSMOS
开放状态:
  - paper
  - code
  - pretrained-weights
aliases:
  - Speech Enhancement with Score-Based Generative Models in the Complex STFT Domain
  - Score-Based Generative Model for Speech Enhancement
  - SGMSE original
tags:
  - 类型/对象
  - 方向/AI语音
  - 任务/语音增强
  - 任务/降噪
  - 主题/扩散模型
  - 主题/分数匹配
---

# SGMSE

## 0. 背景

**问题现场**：语音增强需要恢复受损语音条件下的干净语音分布。

**前序路线的缺口**：只估计幅度 mask 的方法会被动继承输入相位。

**SGMSE 的切入点**：在复数 STFT 域做条件 score-based SDE——带噪语音作为漂移锚点，反向采样在带噪输入附近逐步生成更干净的语音。

## 1. 身份

`SGMSE`（Score-based Generative Model for Speech Enhancement）是汉堡大学 Gerkmann 组提出的复数 STFT 域生成式语音增强模型。它把语音增强写成条件 score-based SDE 问题：模型学习受损语音条件下的干净语音分布，再通过反向随机微分方程采样恢复语音。

它是 SGMSE+、StoRM 以及后续多通道 score-based 增强路线的上游工作之一。边界上，原始 SGMSE 是单通道生成式 SE，不是实时轻量降噪模型，也不是完整 GSR / full-band restoration 系统。

## 2. 核心链路

```text
noisy speech waveform y
  -> complex STFT
  -> signal-conditioned SDE perturbs clean speech toward y
  -> score network estimates ∇ log p(x_t | y)
  -> reverse SDE with predictor-corrector sampling
  -> enhanced complex STFT
  -> iSTFT
  -> enhanced waveform
```

关键点是：前向过程不是把干净语音简单推到与输入无关的纯高斯噪声，而是利用受损语音作为条件和漂移锚点。反向采样因此是在“带噪输入附近”逐步生成更干净的语音。

## 3. 方法机制

- **复数 STFT 域**：同时建模实部与虚部，避免只估计幅度 mask 后被动继承输入相位。
- **条件 score network**：输入带噪/混响语音的复数谱、扰动状态和时间条件，估计当前状态的 score。
- **Denoising score matching**：在不同 SDE 时间状态下构造扰动样本，训练网络逼近条件分布的对数梯度。
- **Predictor-corrector sampling**：用 predictor 进行反向 SDE 更新，再用 corrector 细化样本；质量更高但推理需要多步采样。
- **随机生成**：同一输入可以得到不同采样轨迹，因此需要通过随机种子、采样步数和是否 ensemble 固定复现实验口径。

## 4. 与 SGMSE+ 的关系

| 维度 | SGMSE | SGMSE+ |
|---|---|---|
| 论文定位 | 首个复数 STFT 域 score-based SE 代表 | 扩散式增强与去混响扩展 |
| 主要任务 | 单通道语音增强 | 单通道降噪 + 去混响 |
| 方法骨架 | 条件 SDE + score network + PC sampling | 延续该框架并改进网络与任务配方 |
| 研究作用 | 证明 score-based 生成式 SE 可行 | 提升质量并成为后续工作常用基线 |

当前库中的 `SGMSE+` 页面负责后续的去混响、网络改进和完整实验表；本页只记录原始 SGMSE 的方法定位和谱系作用。

## 5. 训练与评测

- **常见表示**：复数 STFT，实部/虚部作为 score network 的输入通道。
- **常见数据**：VoiceBank-DEMAND、WSJ0-CHiME3 等单通道语音增强基准；官方仓库还提供 WSJ0-REVERB、EARS 等变体入口。
- **常见指标**：PESQ、ESTOI、SI-SDR、DNSMOS；生成式结果还应补充 WER/CER、说话人相似度和推理成本。
- **推理成本**：通常需要几十个反向步骤；具体 NFE、corrector 数量、采样器和 RTF 取决于 checkpoint 与命令行配置。

SGMSE 的主要价值是生成式恢复质量和分布建模，不是每一步计算速度。与 [[方向/AI语音/模型/NSNet2]] 或 [[方向/AI语音/模型/FRCRN]] 相比，它更接近离线高质量增强基线。

## 6. 使用判断

- **适合**：单通道离线降噪、复杂噪声条件、生成式 SE 研究、score/SDE 与 flow matching 的方法对照。
- **不适合优先选择**：端侧实时通话、严格低延迟 Agent、单步确定性推理。
- **主要优势**：在复杂退化下可生成更自然的语音，并为后续扩散/生成式增强建立了统一数学框架。
- **主要代价**：采样慢、随机性高、强退化下可能出现生成式伪影；不能把 MOS 提升直接等同于内容完全保持。
- **与 GSR 的关系**：SGMSE 是生成式 SE 的重要前身，但原始任务范围窄于覆盖削波、带宽扩展、codec 伪影等多退化的完整 GSR。

## 7. 版本与实现边界

- **原始论文**：*Speech Enhancement with Score-Based Generative Models in the Complex STFT Domain*，Interspeech 2022。
- **SGMSE+**：同一代码生态中的后续论文，增加去混响并改进网络和采样设置。
- **官方代码**：`sp-uhh/sgmse` 提供 PyTorch 实现、训练/评测脚本和预训练 checkpoint。
- **官方实现支持**：VoiceBank-DEMAND、WSJ0-CHiME3、WSJ0-REVERB、EARS 等数据/模型配置。
- 不能把 `SGMSE`、`SGMSE+`、`mSGMSE` 或第三方 fork 的指标、采样器和模型规模直接混用。

## 8. 相关对象

- [[方向/AI语音/模型/SGMSE+]]：直接后续，扩展到去混响并成为常用扩散 SE 基线。
- [[方向/AI语音/模型/StoRM]]：判别式粗估 + 扩散再生的混合后继。
- [[方向/AI语音/模型/mSGMSE]]：把 SGMSE 线路扩展到多通道联合生成。
- [[方向/AI语音/模型/AMDM-SE]]：多通道扩散增强，沿用 SGMSE+ 的条件 SDE 配方。
- [[方向/AI语音/知识/基础概念/Score Matching（分数匹配）]]：训练目标与 score-based 生成建模入口。
- [[方向/AI语音/知识/基础概念/SE（语音增强）导论]]：SGMSE 的任务归属。
- [[方向/AI语音/知识/基础概念/GSR（General Speech Restoration，通用语音恢复）]]：更宽的多退化恢复口径。
- [[方向/AI语音/模型/DiT-Flow]]：Flow Matching 路线对照，通常以 SGMSE/SGMSE+ 作为扩散基线。

## 9. 关键来源

- [Speech Enhancement with Score-Based Generative Models in the Complex STFT Domain](https://arxiv.org/abs/2203.17004)
  - 内容定位：原始 SGMSE 论文，介绍复数 STFT、条件 SDE、score matching 和 predictor-corrector sampling。
  - 用途：确认模型身份、数学框架和原始任务边界。
  - 核验日期：2026-09-20
- [Speech Enhancement and Dereverberation with Diffusion-based Generative Models](https://arxiv.org/abs/2208.05830)
  - 内容定位：SGMSE+ 后续论文，延续并扩展 SGMSE 到去混响和更强网络。
  - 用途：记录 SGMSE → SGMSE+ 的谱系关系。
  - 核验日期：2026-09-20
- [Official sp-uhh/sgmse repository](https://github.com/sp-uhh/sgmse)
  - 内容定位：官方 PyTorch 实现、预训练 checkpoint、训练和评测脚本。
  - 用途：复现、采样器配置和版本核验。
  - 核验日期：2026-09-20
- [University of Hamburg project page](https://www.inf.uni-hamburg.de/en/inst/ab/sp/publications/sgmse)
  - 内容定位：音频样例、论文材料、方法比较和代码入口。
  - 用途：主观样例与项目谱系核验。
  - 核验日期：2026-09-20

## 10. 待验证

- [ ] 固定本地 SGMSE checkpoint、采样器、NFE、corrector 数量和随机种子。
- [ ] 在同一 VoiceBank-DEMAND / DNS / GSR 管线下比较 SGMSE、SGMSE+、StoRM、FRCRN 和 NSNet2 的质量、内容保持与 RTF。

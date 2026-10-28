---
title: SE SOTA（语音增强模型表现）
发表时间:
时间依据: 榜单/横评综合笔记；非单一发表物
相关任务:
  - 语音增强
相关模型:
  - "[[方向/AI语音/模型/GAP-URGENet]]"
  - "[[方向/AI语音/模型/TF-GridNet]]"
  - "[[方向/AI语音/模型/DeWavLM-Omni]]"
  - "[[方向/AI语音/模型/RE-USE]]"
  - "[[方向/AI语音/模型/PGUSE]]"
  - "[[方向/AI语音/模型/UniPASE]]"
相关评估:
  - "[[方向/AI语音/评估/DNS Challenge（深度噪声抑制挑战）]]"
aliases:
  - 语音增强模型表现（SE SOTA）
  - SE SOTA
  - 语音增强模型表现
  - se sota
  - SE
tags:
  - 类型/对象
  - 方向/AI语音
  - 任务/语音增强
---

# SE SOTA（语音增强模型表现）

当前语音增强的"SOTA"取决于在哪套基准、哪类指标上衡量。**核心格局：生成式模型刷满非侵入式指标（DNSMOS/NISQA/UTMOS/主观 MOS）但内容保持指标崩塌；判别式模型守住 PESQ/ESTOI；混合式（判别+生成串联）在综合排名中夺冠。**

## 1. [[方向/AI语音/评估/URGENT（通用语音增强挑战）|URGENT Challenge]]（当前事实上的主榜单）

[[方向/AI语音/评估/URGENT（通用语音增强挑战）|URGENT]] 已取代 [[方向/AI语音/评估/DNS Challenge（深度噪声抑制挑战）|DNS Challenge]] 成为最全面的公共评测：多语言、多失真（噪声+混响+codec+带宽限制），盲测含一半真实录音。

### 1.1. URGENT 2025（32 份提交，盲测 900 样本 / 6 语言）

| 系统 | 类型 | 表现 |
|------|------|------|
| **T1（冠军）** | 纯判别式 | 综合排名分 2.97，跨语言最稳定 |
| **T13** | 纯生成式 | DNSMOS / NISQA / UTMOS / **MOS 3.69 全部第一**；但 PESQ 1.34、ESTOI 0.54、SDR −12.28、SpkSim 0.47——典型"好听但幻觉" |
| USEMamba | Mamba 系 | Track 1 盲测第二（仅用部分数据训练） |
| FUSE | 混合式 | 第三；前三名中 MOS 类指标最高 |
| DeepFilterGAN | 实时判别式 | 40 ms 算法延迟、3.45M 参数的实时全频带参赛系统 |

### 1.2. URGENT 2026（ICASSP 2026）

| 系统                              | 类型                            | DNSMOS | NISQA    | UTMOS | PESQ  | ESTOI    | SpkSim   | 参数量    |        |
| ------------------------------- | ----------------------------- | ------ | -------- | ----- | ----- | -------- | -------- | ------ | ------ |
| **[[方向/AI语音/模型/GAP-URGENet]]**（客观评测第一，队名 WR） | 混合式    | 3.31     | 3.96  | 3.22  | **2.89** | **0.90** | 0.82   | 567.8M |
| UniPASE（GAP-URGENet 的生成式分支单独评测） | 纯生成式                          | 3.26   | **4.18** | 2.97  | 落后混合式 | —        | 0.81     | 545.7M |        |

要点：第一名是南京大学声学所团队（Xiaobin Rong 等）的**生成-预测融合系统**——GAP-URGENet 论文描述整体框架（生成式分支 + [[方向/AI语音/模型/TF-GridNet|TF-GridNet]] 预测分支 + PostNet 融合兼带宽扩展），UniPASE 是同一团队的姊妹论文，详述其中生成式分支（[[方向/AI语音/模型/DeWavLM-Omni|DeWavLM-Omni]] + Adapter + Vocoder）的低幻觉设计。纯生成式单体在 NISQA 上最高，但 PESQ/ESTOI 追不上融合后的完整系统。

## 2. [[VoiceBank-DEMAND]]（经典基准，PESQ 演进）

| 模型 | 年份/类型 | PESQ |
|------|-----------|------|
| 未增强基线 | — | ~1.97 |
| Wiener 滤波 | 经典 | 2.22 |
| Conv-TasNet | 判别式 | 2.53 |
| Demucs | 判别式 | 2.93–3.07 |
| TaylorSENet | 2023 判别式 | 3.23 |
| MP-SENet / CMGAN / DPT-FSNet | 2023–24 判别式 SOTA | 3.33–3.50 |
| EffiFusion-GAN | 2025，1.08M 参数 | 3.45 |

近年头部模型在此基准上还可达 CSIG >4.7、COVL ~4.1、STOI ~0.96。泛化基准 VB-DemandEx（域外 DNS 2020 / EARS-WHAM_v2）上 **MambAttention** 领先：域内 PESQ 3.03、域外 DNS 2.92、EARS 2.09——域外泛化成为新的区分点。

## 3. 生成式与预测-生成混合家族

| 模型 | 指标亮点 | 延迟/成本 |
|------|----------|-----------|
| **DiTSE** | DAPS 集 QMOS **4.34**，与录音室干净音频不可区分 | 8×A100 训练；32 步采样，离线向 |
| **FlowSE** | 与扩散式质量相当 | 10–20 步 ODE，延迟降一个量级；开源 |
| **[[方向/AI语音/模型/PGUSE]]** | 预测分支 + 扩散生成分支，output fusion + truncated diffusion | 比纯扩散更低采样负担；离线/研究向 |
| **DiT-Flow** | 多失真条件下超 SGMSE/[[方向/AI语音/模型/StoRM]]，RTF 好 ~2× | 潜空间 FM |
| **Stream.FM** | 统一增强/去混响/带宽扩展 | **32 ms 算法延迟**，消费级 GPU 流式 |
| **VoiceRestore** | 自监督统一修复，提升下游 Whisper V3 ASR | FM Transformer |

## 4. 关键结论

1. **指标分裂是当前最大特征：** 纯生成式在 URGENT 2025 上 MOS 3.69 夺冠、PESQ 仅 1.34。听感与内容保持不再同向，单一指标排名没有说服力。
2. **混合式是 2026 综合最优解：** URGENT 2026 冠军 [[方向/AI语音/模型/GAP-URGENet|GAP-URGENet]] 是判别+生成串联（生成式分支 [[方向/AI语音/模型/UniPASE|UniPASE]] + [[方向/AI语音/模型/TF-GridNet|TF-GridNet]]），兼顾 PESQ 2.89/ESTOI 0.90 与 DNSMOS 3.31。
3. **幻觉问题开始被量化：** 生成式系统在内容准确率（CAcc）、词错误率、说话人相似度上的崩塌已有专门的多语言 P.808 主观研究记录（日语 MOS 2.94 vs DNSMOS 2.88 的失配案例）。
4. **数据质量 > 数据规模：** URGENT 2025 Track 2（60k 小时）未超过精心筛选的 Track 1（2.5k 小时）。
5. **实时与离线分叉明显：** 离线看 DiTSE/QMOS 4.34；实时看 DeepFilterGAN（40 ms、3.45M）和 Stream.FM（32 ms）两个极端。
6. **训练目标新发现：** [[方向/AI语音/模型/RE-USE]] 表明，以"时间平移的消声干净语音"为目标（而非含早期反射目标）配合 GAN residual correction，是 2026 年报告的更优配置（DNSMOS 3.26 / NISQA 4.12 / CAcc 89.88）。

## 5. 关键来源

- [URGENT Speech Enhancement Challenge 主题页](https://www.emergentmind.com/topics/urgent-speech-enhancement-challenge)
  - URGENT 2024/2025/2026 排名与趋势汇总。核验日期：2026-07-28
- [UniPASE: A Generative Model for Universal Speech Enhancement with High Fidelity and Low Hallucinations](https://arxiv.org/abs/2604.14606)
  - URGENT 2026 冠军系统的生成式分支（南大声学所），低幻觉设计详解。核验日期：2026-07-28
- [GAP-URGENet: A Generative-Predictive Fusion Framework for Universal Speech Enhancement](https://arxiv.org/abs/2604.01832)（[代码](https://github.com/Xiaobin-Rong/gap-urgenet)）
  - URGENT 2026 客观第一的整体混合框架，UniPASE 的姊妹论文。核验日期：2026-07-28
- [A Composite Predictive-Generative Approach to Monaural Universal Speech Enhancement](https://arxiv.org/abs/2505.24576)
  - PGUSE 原始论文，预测-生成双分支和 truncated diffusion 的代表。核验日期：2026-08-04
- [URGENT 2026 官方结果](https://urgent-challenge.com/competitions/15#results)
  - 挑战赛官方排名。核验日期：2026-07-28
- [多语言 P.808 主观评测研究（Sach et al.）](https://arxiv.org/abs/2507.11306)
  - 生成式增强幻觉与跨语言失配的量化证据。核验日期：2026-07-28
- [VoiceBank+DEMAND Benchmark 主题页](https://www.emergentmind.com/topics/voicebank-demand-dataset-6a395fe3-bd1f-41ee-919b-0986fce1d1f3)
  - 经典基准 PESQ 演进表。核验日期：2026-07-28
- [VB-DemandEx 泛化基准](https://www.emergentmind.com/topics/voicebank-demand-extended-vb-demandex)
  - 域外泛化对比，MambAttention 领先。核验日期：2026-07-28
- [A Comparative Evaluation of Deep Learning Models for Speech Enhancement](https://arxiv.org/abs/2506.15000)
  - Wave-U-Net / CMGAN / U-Net 横向评测（CMGAN PESQ 4.04 @ SpEAR）。核验日期：2026-07-28
- [Rethinking Training Targets, Architectures and Data Quality for Universal Speech Enhancement](https://arxiv.org/abs/2603.02641)
  - 内容定位：[[方向/AI语音/模型/RE-USE]] 原始论文，系统重审 USE 的训练目标、两阶段架构和训练数据质量。
  - 用途：支撑“time-shifted anechoic clean target + GAN residual correction + 数据质量优先”的训练目标结论。
  - 发表日期：2026-03-03（arXiv v1；当前 v2 为 2026-04-30）
  - 核验日期：2026-08-25

## 6. 关联

- 方向：[[方向/AI语音增强/README|AI 语音增强]]
- [[方向/AI语音/评估/URGENT（通用语音增强挑战）|URGENT]]：universal speech enhancement 挑战赛和评测基准入口。
- 相邻笔记：[[语音增强评估指标体系]]（指标地图与分裂分析）、[[DiT 与语音增强（DiT-based Speech Enhancement）]]（表中 DiT 家族细节）、[[方向/AI语音/模型/RE-USE]]、[[方向/AI语音/模型/PGUSE|PGUSE]]、[[UniSE（Unified Speech Enhancement）]]、[[Reverberation Modeling（混响建模）]]、[[OVRL_MOS]]（生成式评估指标）
- [[方向/AI语音/评估/RealMAN 测试结果清单|RealMAN 测试结果清单]]：真实阵列数据集上的分支清单（多通道 PESQ 组、单通道 DNSMOS 组、几何泛化组互不可比）。
- 待深挖：[[方向/AI语音/模型/GAP-URGENet|GAP-URGENet]] 与 UniPASE+[[方向/AI语音/模型/TF-GridNet|TF-GridNet]] 两个 URGENT 2026 第一名的架构拆解；生成式幻觉率的统一度量（CAcc/CER/SpkSim 哪个最敏感）；[[方向/AI语音/评估/DNS Challenge（深度噪声抑制挑战）|DNS Challenge]] 是否已被 URGENT 完全取代。

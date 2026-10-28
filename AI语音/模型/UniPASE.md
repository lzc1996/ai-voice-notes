---
title: UniPASE
类型: 模型
参数量: 545.7M
发表时间: 2026-04-16
时间依据: arXiv 首次提交日
任务:
  - 语音增强
开放状态:
  - paper
  - code
  - weights
  - demo
aliases:
  - Universal Speech Enhancement with High Fidelity and Low Hallucinations
  - Perceptual Audio Tokenizer for Speech Enhancement
tags:
  - 类型/对象
  - 方向/AI语音
  - 任务/语音增强
---

# UniPASE

## 0. 背景

**问题现场**：universal speech enhancement 要用一个模型覆盖降噪、去混响、带宽扩展、丢包修复等 7 种失真与多采样率，同时兼顾高保真与低幻觉。

**前序路线的缺口**：前代 PASE 是低幻觉生成式增强但未做 universal 扩展；更早的判别式三阶段路线按失真类型分治，泛化受限；纯生成式单体在 URGENT 综合榜上指标崩塌。

**UniPASE 的切入点**：用 perceptual audio tokenizer（DeWavLM-Omni + Adapter 表示回归/去噪表征蒸馏）把任何失真先映射回"干净表示域"，再经 Vocos vocoder 与 PostNet（带宽扩展细化）生成波形。

## 1. 身份

UniPASE 是一个 generative universal speech enhancement **模型**，全名是 *UniPASE: A Generative Model for Universal Speech Enhancement with High Fidelity and Low Hallucinations*。它用 perceptual audio tokenizer 学习语义和声学兼具的表示，再通过直接回归、adapter、vocoder 和 PostNet 完成多种语音增强任务。

层级定位（按 vault 的模型/框架/系统约定）：UniPASE 是有具体权重的**模型**（官方发布 5 个 checkpoint，545.7M 参数）；它同时是 [[方向/AI语音/模型/GAP-URGENet|GAP-URGENet]] 系统里的生成式分支——GAP-URGENet = UniPASE + [[方向/AI语音/模型/TF-GridNet|TF-GridNet]] + PostNet 融合。

## 2. 用途

- 作为低幻觉、高保真 universal speech enhancement 路线的前沿样例。
- 处理 denoising、dereverberation、bandwidth extension、packet loss concealment 等多类退化。
- 和 [[方向/AI语音/模型/SenSE|SenSE]]、[[方向/AI语音/模型/UniSE（Unified Speech Enhancement）|UniSE]] 对比：UniPASE 更强调 perceptual tokenizer / WavLM 表示回归，SenSE 强调 semantic-guided flow matching，UniSE 强调 decoder-only LM 统一恢复。
- 作为 URGENT / DNSMOS / ASR 收益评测中的候选增强模型。

## 3. 核心信息

- 论文声称 UniPASE 在 URGENT Challenge 2026 的五个 objective tracks 中排名第一。
- 官方实现已被 IEEE TASLP 接收。
- 官方仓库提供五个 checkpoint：[[方向/AI语音/模型/DeWavLM-Omni|DeWavLM-Omni.pt]]、`Adapter.pt`、`Vocoder_DWO-L1.pt`、`Vocoder_WavLM-L24.pt`、`PosterNet.pt`。
- `Vocoder_WavLM-L24.pt` 仅用于从 WavLM L24 表示重建波形，方便评估 [[方向/AI语音/模型/DeWavLM-Omni|DeWavLM-Omni]]，不属于 UniPASE 主模型组件。
- 代码仓库 LICENSE 是 MIT；Hugging Face 模型卡标注 license 为 Apache-2.0，使用前需要分别核对代码和权重许可。

## 4. 核心公式

**1. 表示回归 / 去噪表征蒸馏（核心训练目标）：**

$$\mathcal{L}_{\text{distill}} = \mathbb{E}\Big[\big\| \text{Adapter}\big(\text{DeWavLM-Omni}(y,\, m_{\text{PLD}})\big) - h_{\text{target}} \big\|_2^2\Big]$$

$y$ 为退化语音，$m_{\text{PLD}}$ 为丢包检测 mask（packet loss 缺失帧标记），DeWavLM-Omni 提取并增强表示，Adapter 做声学表征增强，$h_{\text{target}}$ 为干净语音的目标表示；失真种类再多都先映射回"干净表示域"再生成，是 universal 扩展的前提。（目标表示定义与度量形式待核，见待验证）

**2. Adapter 的对抗训练（MSRD）：**

$$\min_{\theta}\max_{D}\ \mathbb{E}\big[\log D(h_{\text{target}})\big] + \mathbb{E}\big[\log\big(1 - D(\hat h)\big)\big]$$

判别器 $D$ 区分真实目标表示与增强后表示 $\hat h$，对抗压力进一步提升表示质量。（MSRD 的具体对抗设计待核，见待验证）

**3. 波形重建链路：**

$$\hat x = \text{Vocos}\big(\hat h,\, \hat e_{\text{spk}}\big), \qquad \hat x_{\text{final}} = \text{PostNet}\big(\hat x\big)$$

Vocos vocoder 把表示解码为波形，PostNet（CWS-TF-GridNet 带宽扩展）做终值细化，覆盖多采样率与 7 种失真。

## 5. 测试基准与性能

**测试基准：** 多采样率（16 kHz / 48 kHz / 原采样率重采样）；大规模监督多失真训练集；URGENT 2026 Challenge 多个评测集（覆盖子任务与全任务，共 7 种失真：降噪、去混响、带宽扩展、丢包等，见「核心公式」「发展脉络」）。

**性能指标：** URGENT 2026 Challenge 客观评测第一名（arXiv 摘要："achieved 1st place in the objective evaluation"；笔记：五个 objective tracks 均第一）。参数量 545.7M，官方 5 个 checkpoint（笔记正文）。具体分数（PESQ/DNSMOS/ESTOI/WER/CER）与 RTF 待核。

（来源：arXiv 2604.14606 摘要；笔记正文「身份」「核心信息」）

## 6. 发展脉络

UniPASE 是南京大学声学所 / NJU-Horizon 实验室（Xiaobin Rong、Jing Lu 等）四年 URGENT 参赛路线的第三代产物，脉络清晰地反映了整个领域"判别式 → 生成式 → 融合式"的演进：

| 代际 | 工作 | 时间/发表 | 路线 | 成绩 |
|------|------|-----------|------|------|
| 第一代 | **TS-URGENet** | Interspeech 2025 | 纯判别式三阶段 [[方向/AI语音/模型/TF-GridNet]]：填充（丢包修复）→ 分离（降噪/去混响/去削波）→ 恢复（带宽扩展/codec 修复） | URGENT 2025 Track 1 **第二**（输给纯判别式冠军 T1） |
| 第二代 | **PASE** | AAAI 2026 | 首次转向生成式：去噪表征蒸馏把 WavLM 变成"去噪专家"，用其音系先验压幻觉；双流 vocoder 分离语言内容（高层音素表征）与说话人特征（低层声学表征） | 感知质量超判别式 SOTA，幻觉率显著低于此前生成式 |
| 第三代 | **UniPASE** | TASLP 2026 | PASE 的 universal 扩展：[[方向/AI语音/模型/DeWavLM-Omni]]（加 [[方向/AI语音/知识/基础概念/PLD（丢包检测）]] / PLD）+ Adapter（声学表征增强 + MSRD 对抗）+ Vocos vocoder + PostNet（CWS-[[方向/AI语音/模型/TF-GridNet]] 带宽扩展），覆盖 7 种失真、多采样率 | URGENT 2026 客观评测第一（作为 GAP-URGENet 的生成式分支） |
| 系统化 | **GAP-URGENet** | ICASSP 2026 | UniPASE + [[方向/AI语音/模型/TF-GridNet]] + PostNet 的生成-预测融合系统 | URGENT 2026 Track 1 第一 |

### 6.1. 脉络里的三个关键判断

1. **从"分阶段修"到"表示域重建"：** TS-URGENet 按失真类型分治（每种失真归一个阶段），PASE 起改为在 WavLM 自监督表示域里统一重建——失真种类再多，都先映射回"干净音素表征"再生成。这是 universal 扩展能成立的前提。
2. **幻觉问题是被正面攻坚出来的，不是绕开的：** PASE 首次把生成式幻觉明确分为语言幻觉（内容错）和声学幻觉（音色错），并分别用"音系先验蒸馏"和"双流 vocoder"对应解决——UniPASE 的低幻觉标签直接继承自这里。
3. **生成式单体赢不了综合榜，融合才行：** URGENT 2025 纯判别式夺冠、生成式冠军指标崩塌的教训（见 [[方向/AI语音/知识/调研与地图/SE SOTA（语音增强模型表现）|指标分裂]]）直接促成了 GAP-URGENet 的融合设计——同一团队用 TS-URGENet 时代积累的 [[方向/AI语音/模型/TF-GridNet|TF-GridNet]] 做预测分支，用 PASE 系做生成分支。

### 6.2. 团队与生态

- 核心作者：Xiaobin Rong（一作贯穿全部四篇）、Jing Lu（通讯，南大教授）。
- PASE 有 Cisco Collaboration AI 参与（代码托管在 cisco-open）；后续工作回到 NJU-Horizon。
- 全部开源：PASE（[cisco-open/pase](https://github.com/cisco-open/pase)）、UniPASE（[Xiaobin-Rong/unipase](https://github.com/Xiaobin-Rong/unipase)）、GAP-URGENet（[Xiaobin-Rong/gap-urgenet](https://github.com/Xiaobin-Rong/gap-urgenet)）。

## 7. 关键资源

- [PASE: Leveraging the Phonological Prior of WavLM for Low-Hallucination Generative Speech Enhancement](https://arxiv.org/abs/2511.13300)（AAAI 2026，[代码](https://github.com/cisco-open/pase)）
  - 内容定位：UniPASE 的直接前身，WavLM 音系先验 + 双流 vocoder 的低幻觉生成式增强。
  - 用途：理解 UniPASE 低幻觉设计的来源。
  - 核验日期：2026-07-28
- [TS-URGENet: A Three-stage Universal Robust and Generalizable Speech Enhancement Network](https://arxiv.org/abs/2505.18533)（Interspeech 2025）
  - 内容定位：同团队第一代 URGENT 参赛系统，三阶段判别式 [[方向/AI语音/模型/TF-GridNet|TF-GridNet]]，URGENT 2025 Track 1 第二。
  - 用途：理解团队从判别式到生成式的转向背景。
  - 核验日期：2026-07-28
- [UniPASE paper](https://arxiv.org/abs/2604.14606)
  - 内容定位：论文提出 perceptual audio tokenizer + generative universal speech enhancement，并报告 URGENT Challenge 2026 objective tracks 结果。
  - 用途：理解模型定位、架构和评测结论。
  - 核验日期：2026-07-28
- [Xiaobin-Rong/unipase](https://github.com/Xiaobin-Rong/unipase)
  - 内容定位：官方实现，包含 checkpoint 列表、推理命令、长音频推理、训练步骤和 citation。
  - 用途：本地复现实验和工程入口。
  - 核验日期：2026-07-28
- [Xiaobin-Rong/unipase - Hugging Face](https://huggingface.co/Xiaobin-Rong/unipase)
  - 内容定位：官方模型权重页，提供 checkpoint 文件和模型卡。
  - 用途：权重下载和许可核对。
  - 核验日期：2026-07-28

## 8. 相关对象

- [[方向/AI语音增强/README|AI 语音增强]]：UniPASE 属于 universal speech enhancement 前沿方法。
- [[方向/AI语音/模型/DeWavLM-Omni|DeWavLM-Omni]]：UniPASE 的核心表示增强模块。
- [[方向/AI语音/知识/基础概念/PLD（丢包检测）|PLD]]：为 packet loss concealment 提供缺失帧检测 mask。
- [[方向/AI语音/模型/WavLM|WavLM]]：UniPASE 以 WavLM 表示为重要中间层，并 finetune WavLM 作为 USE expert。
- [[方向/AI语音/模型/SenSE|SenSE]]：同属 2026 前后生成式 universal speech enhancement 路线。
- [[方向/AI语音/模型/UniSE（Unified Speech Enhancement）|UniSE]]：同属统一语音恢复方向，但建模范式不同。
- [[方向/AI语音/评估/OVRL_MOS|OVRL_MOS]]：听感质量评估入口，但 UniPASE 也要结合语义保真和下游 ASR 指标。
- [[方向/AI语音/评估/CER（Character Error Rate）|CER]]：如果用于 ASR 前端增强，需要看增强后 CER/WER 是否下降。

## 9. 待验证

- 官方 checkpoint 在本地 GPU 上的 RTF、显存占用和长音频稳定性。
- MIT 代码许可证与 HF 权重 Apache-2.0 标注是否覆盖目标用途。
- 中文、方言、TTS 合成语音和真实通话链路上的 OVRL_MOS、DNSMOS、CER/WER 是否一致。
- 与 SenSE、UniSE、DeepFilterNet、RNNoise 在同一小样本集上的质量和延迟差异。
- 表示蒸馏的目标表示定义与度量形式、MSRD 对抗的具体设计（损失项、判别器输入）需从论文核对。
- URGENT 2026 各 track 具体分数与 RTF / 显存占用需从论文全文核对（摘要仅定性第一名，无数字）。

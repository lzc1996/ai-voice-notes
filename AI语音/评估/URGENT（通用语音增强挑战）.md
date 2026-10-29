---
title: URGENT（通用语音增强挑战）
类型: 评测基准
发表时间: 2024-06-07
时间依据: URGENT Challenge arXiv 首次提交日
相关任务:
  - 语音增强
相关模型:
  - "[[方向/AI语音/模型/GAP-URGENet]]"
  - "[[方向/AI语音/模型/UniPASE]]"
  - "[[方向/AI语音/模型/UniSE（Unified Speech Enhancement）]]"
  - "[[方向/AI语音/模型/DiT-Flow]]"
相关评估:
  - "[[方向/AI语音/评估/OVRL_MOS]]"
  - "[[方向/AI语音/评估/NISQA]]"
  - "[[方向/AI语音/评估/UTMOS]]"
  - "[[方向/AI语音/评估/PESQ]]"
  - "[[方向/AI语音/评估/STOI 与 ESTOI]]"
  - "[[方向/AI语音/评估/SI-SDR]]"
  - "[[方向/AI语音/评估/CAcc]]"
  - "[[方向/AI语音/评估/SpkSim]]"
  - "[[方向/AI语音/评估/语音增强评估指标体系]]"
  - "[[方向/AI语音/评估/CHiME and URGENT Chinese Industry Labs（国内工业界参赛记录）]]"
  - "[[方向/AI语音/评估/DNS Challenge（深度噪声抑制挑战）]]"
aliases:
  - 通用语音增强挑战（URGENT）
  - URGENT
  - 通用语音增强挑战
  - urgent
tags:
  - 类型/对象
  - 方向/AI语音
  - 任务/语音增强
---

# URGENT（通用语音增强挑战）

## 0. 背景

- **覆盖更真实的失真空间**：噪声、混响、削波、带宽限制、codec 伪影、丢包等不再分散成多个小任务。
- **推动 universal SE**：目标从“某个数据集上 PESQ 高”变成“一个系统跨语言、跨退化、跨真实录音仍稳定”。
- **暴露指标分裂**：生成式系统可在 MOS/DNSMOS/NISQA 上很好听，但在 PESQ/ESTOI/CAcc/SpkSim 上暴露内容或身份幻觉。
- **成为近年主榜单**：当前 [[方向/AI语音/知识/调研与地图/SE SOTA（语音增强模型表现）|SE SOTA]] 讨论里，URGENT 比 VoiceBank-DEMAND 更能代表真实泛化能力。

## 1. 身份

`URGENT` 是面向 **universal speech enhancement** 的公开挑战赛/评测基准系列，目标是把语音增强从单一降噪或单一数据集，推向更真实的多语言、多失真、多场景评测。

边界：URGENT 不是模型。它是数据、规则、提交系统、主观/客观指标和榜单组成的 benchmark；[[方向/AI语音/模型/GAP-URGENet|GAP-URGENet]]、[[方向/AI语音/模型/UniPASE|UniPASE]]、DeepFilterGAN 等才是参赛系统或模型。

## 2. 届次脉络

| 届次 | 会议/位置 | 重点 |
|---|---|---|
| URGENT 2024 | NeurIPS 2024 Competition Track / Interspeech 2024 论文 | 建立 universality、robustness、generalizability 的 challenge 定义 |
| URGENT 2025 | Interspeech 2025 Challenge | 生成式增强和判别式增强的指标分裂变成核心现象 |
| URGENT 2026 | ICASSP 2026 SP Grand Challenge | Track 1 为 Universal Speech Enhancement；Track 2 把 MOS 预测也单独做成任务 |

## 3. 评估口径

- **听感质量**：主观 MOS、P.808、DNSMOS / [[方向/AI语音/评估/OVRL_MOS|OVRL_MOS]]、[[方向/AI语音/评估/NISQA|NISQA]]、[[方向/AI语音/评估/UTMOS|UTMOS]]。
- **保真和可懂度**：[[方向/AI语音/评估/PESQ|PESQ]]、[[方向/AI语音/评估/STOI 与 ESTOI|ESTOI]]、[[方向/AI语音/评估/SI-SDR|SI-SDR]]。
- **内容/身份保持**：[[方向/AI语音/评估/CAcc|CAcc]]、WER/CER、[[方向/AI语音/评估/SpkSim|SpkSim]]。
- **工程维度**：参数量、RTF、算法延迟、是否使用官方训练数据、是否适合真实录音和多语言场景。

## 4. 使用注意

- 不要只引用单一榜单分数：URGENT 的核心价值正是揭示“听感好”和“内容对”可以分裂。
- 比较系统时要确认届次、track、主观轮/客观轮、是否 real-time、是否使用额外数据。
- `universal SE` 在 URGENT 里指统一失真空间，不等于 [[方向/AI语音/模型/UniSE（Unified Speech Enhancement）|UniSE]] 那种统一 SR / TSE / SS 的任务空间。
- 旧的 VoiceBank-DEMAND 分数仍可做历史参照，但不能替代 URGENT 这种多失真、多语言、真实录音评测。

## 5. 相关对象

- [[方向/AI语音/知识/基础概念/SE（语音增强）导论|SE（语音增强）导论]]：解释 universal SE 和普通 SE / SR / TSE / SS 的边界。
- [[方向/AI语音/知识/基础概念/Full-Band（全频带）|Full-Band（全频带）]]：带宽限制失真与 8–48 kHz 跨带宽评测轴的口径背景。
- [[方向/AI语音/知识/调研与地图/SE SOTA（语音增强模型表现）|SE SOTA]]：记录 URGENT 各届榜单、指标分裂和代表系统。
- [[方向/AI语音/评估/语音增强评估指标体系|语音增强评估指标体系]]：解释 URGENT 使用的听感、保真、内容和身份指标。
- [[方向/AI语音/模型/GAP-URGENet|GAP-URGENet]]：URGENT 2026 生成-预测融合路线代表。
- [[方向/AI语音/模型/UniPASE|UniPASE]]：URGENT 2026 低幻觉生成式 universal SE 路线代表。
- [[方向/AI语音/模型/DiT-Flow|DiT-Flow]]：虽然不直接等同 URGENT 赛道，但其多失真适配机制可对照 URGENT 失真谱。
- [[方向/AI语音/评估/CHiME and URGENT Chinese Industry Labs（国内工业界参赛记录）|国内工业界 CHiME / URGENT 参赛记录]]：阿里、腾讯、字节、华为 2012 的公开参赛证据梳理。
- [[方向/AI语音/数据集/VoiceBank-DEMAND|VoiceBank-DEMAND]]：经典语音增强基准，常作为 URGENT 之前的历史参照。

## 6. 关键来源

- [URGENT Challenge: Universality, Robustness, and Generalizability For Speech Enhancement](https://arxiv.org/abs/2406.04660)
  - 内容定位：URGENT Challenge 原始论文入口，提出面向 universal SE 的新挑战。
  - 用途：确认名称、目标和发表时间。
  - 核验日期：2026-08-03
- [URGENT Challenge 2024 official site](https://urgent-challenge.github.io/urgent2024/)
  - 内容定位：URGENT 2024 官方页面，说明其 NeurIPS 2024 Competition Track 定位。
  - 用途：确认第一届挑战赛定位和官方入口。
  - 核验日期：2026-08-03
- [Interspeech 2025 URGENT Speech Enhancement Challenge](https://arxiv.org/abs/2505.23212)
  - 内容定位：URGENT 2025 挑战论文，记录提交、评测和指标分裂现象。
  - 用途：理解 2025 届榜单和生成式幻觉案例。
  - 核验日期：2026-08-03
- [Lessons Learned from the URGENT 2024 Speech Enhancement Challenge](https://arxiv.org/abs/2506.01611)
  - 内容定位：URGENT 2024 经验总结，分析数据、指标和主观评测相关性。
  - 用途：理解指标体系和评测设计。
  - 核验日期：2026-08-03
- [URGENT Challenge 2026 official site](https://urgent-challenge.github.io/urgent2026/)
  - 内容定位：ICASSP 2026 URGENT Challenge 官方入口，Track 1 为 Universal Speech Enhancement。
  - 用途：跟踪 2026 届规则、track 和官方资料。
  - 核验日期：2026-08-03

## 7. 待验证

- URGENT 2026 最终 paper / results 与实时 leaderboard 是否完全一致。
- Track 2 MOS prediction 是否应单独拆成“语音质量预测”对象页。
- [[方向/AI语音/评估/DNS Challenge（深度噪声抑制挑战）|DNS Challenge]] 与 URGENT 在长期评测中的分工：DNS 更偏通信降噪，URGENT 更偏 universal SE。


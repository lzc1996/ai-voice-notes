---
title: CHiME and URGENT Chinese Industry Labs（国内工业界参赛记录）
类型: 调研
整理时间: 2026-08-05
aliases:
  - 国内工业界 CHiME URGENT 参赛记录
  - 阿里 腾讯 字节 华为 CHiME URGENT 参赛记录
  - Chinese Industry Labs in CHiME and URGENT
  - Alibaba Tencent ByteDance Huawei CHiME URGENT
tags:
  - 类型/调研
  - 方向/AI语音
  - 基准/CHiME
  - 基准/URGENT
  - 任务/语音增强
  - 任务/远场语音
---

# CHiME and URGENT Chinese Industry Labs（国内工业界参赛记录）

## 1. 范围

本页只整理公开资料里能追到的国内工业界实验室在 [[方向/AI语音/评估/CHiME（语音分离与识别挑战赛）|CHiME]] / [[方向/AI语音/评估/URGENT（通用语音增强挑战）|URGENT]] 的参赛记录，重点看阿里、腾讯、字节、华为 2012 / 华为音频相关团队。

计入口径：

- **强证据**：挑战赛官网、ISCA / ICASSP / arXiv 论文明确列出公司或公司实验室 affiliation，并说明提交、排名或 challenge task。
- **弱证据**：仅有论文引用、作者后续供职、资助致谢、产品发布或相邻赛事，不计为直接参赛记录，只放入“待验证”。
- **任务口径分开看**：CHiME 多数是 distant / noisy ASR、diarization 或智能眼镜转写；URGENT 是 universal speech enhancement，不等价于阵列增强榜。

## 2. 快速结论

1. **腾讯公开竞赛记录最密**：CHiME-5 / CHiME-8 与 URGENT 2025 都能追到明确参赛系统；其中 Tencent AI Lab 系统在 URGENT 2025 Track 1 第一。
2. **字节在 URGENT 上是强信号**：ByteDance 系统记录了 URGENT 2024 第一、URGENT 2025 Track 2 第四；CHiME 侧有 NWPU-ByteAudio 参加 CHiME-7 UDASE。
3. **阿里是后来进入的强记录**：Hummingbird Audio Lab 参与 CHiME-8 MMCSG；Intelligent Connectivity / Tongyi AI Lab 系统在 URGENT 2026 Track 1 第三。
4. **华为 2012 暂无强公开参赛记录**：目前只看到华为 CBG 参与国内 CCF AATC Speech Restoration 这类相邻赛事；未见 Huawei 2012 Labs 直接以团队身份出现在 CHiME / URGENT 提交记录中。

## 3. 公司维度记录

| 公司 / 实验室 | CHiME 记录 | URGENT 记录 | 判断 |
|---|---|---|---|
| 阿里 / Hummingbird Audio Lab / Tongyi AI Lab | CHiME-8 MMCSG：SEUEE，Southeast University + Hummingbird Audio Lab, Alibaba Group；智能眼镜场景，causal multi-channel DSE，提交系统相对 baseline 降低 wearer / partner WER。 | URGENT 2026 Track 1：Intelligent Connectivity + Tongyi AI Lab，hybrid discriminative-generative universal SE，第三名。 | 从 smart-glasses / 多通道转写切入 CHiME，从 universal SE 切入 URGENT；可作为阿里音频处理线索。 |
| 腾讯 / Tencent Ethereal Audio Lab / Tencent AI Lab | CHiME-5：NWPU + Tencent speaker-dependent separation 后续系统；CHiME-8 NOTSOFAR-1 与 MMCSG：NPU-TEA，NWPU + Tencent Ethereal Audio Lab。 | URGENT 2025 Track 1：Tencent AI Lab + CAS / CQUPT / NJU 系统第一。 | 国内工业实验室里公开挑战赛证据最完整；CHiME 偏转写系统，URGENT 偏判别式 universal SE。 |
| 字节 / ByteAudio / RTC Lab, ByteDance | CHiME-7 Task 2 UDASE：NWPU-ByteAudio，NWPU + RTC Lab, ByteDance / ByteDance。 | URGENT 2024 第一；URGENT 2025 Track 2 第四，multistage universal SE。 | URGENT 信号强，强调多阶段恢复：declipping、PLC、separation、spectral inpainting。 |
| 华为 2012 / Huawei Audio | 未见 Huawei 2012 Labs 直接 CHiME 参赛记录。 | 未见 Huawei 2012 Labs 直接 URGENT 参赛记录；Huawei CBG 参与 CCF AATC 2025 Speech Restoration，是相邻但非 URGENT。 | 不应把华为产品堆料或相邻国内赛事误算成 CHiME / URGENT 公开参赛成绩。 |

## 4. 逐条记录

### 4.1. 阿里

#### 4.1.1. CHiME-8 MMCSG：SEUEE / Hummingbird Audio Lab

- 任务：CHiME-8 Task 3 MMCSG，Multi-modal Conversations in Smart Glasses。
- 团队：Southeast University + Hummingbird Audio Lab, Alibaba Group。
- 系统：causal multi-channel directional speech extraction（DSE），把 wearer / conversational partner 分离后分别送入 ASR。
- 结果口径：论文摘要报告 SEUEE 与扩展 DSE 系统在 MMCSG evaluation set 上，相比 baseline 对 wearer speech 和 partner speech 有绝对 WER 降低。
- 判断：这是阿里在 CHiME 侧的明确公开参赛记录；更接近智能眼镜 / 可穿戴会议转写，不是传统会议室阵列增强榜。

#### 4.1.2. URGENT 2026 Track 1：Alibaba hybrid discriminative-generative system

- 团队：Intelligent Connectivity, Alibaba Group；Tongyi AI Lab, Alibaba Group。
- 系统：TF-GridNet discriminative branch + AR / codec-token generative branch + fusion network。
- 结果：论文与 GitHub 均写明在 ICASSP 2026 URGENT Challenge Track 1 获得第三名。
- 判断：阿里在 URGENT 里走的是“判别式守客观指标 + 生成式补细节”的混合路线，和 [[方向/AI语音/模型/GAP-URGENet|GAP-URGENet]] 的大方向类似。

### 4.2. 腾讯

#### 4.2.1. CHiME-5：NWPU / Tencent speaker-dependent separation

- 任务：CHiME-5 dinner-party distant ASR。
- 公开记录：NWPU / Tencent 相关系统做 speaker-dependent speech separation，用 target speaker information 提升 CHiME-5 语音识别；ISCA 摘要记录其在 development set 上相对 80.28% baseline 有 10% 绝对 WER 改进，改进后端声学模型后降到 60.15%，并超过其 submitted CHiME-5 challenge system。
- 判断：这是腾讯较早的 CHiME 参赛线索，但更偏 CHiME-5 ASR 前端 / 说话人相关分离，不是纯音质增强评估。

#### 4.2.2. CHiME-8 NOTSOFAR-1：NPU-TEA

- 任务：CHiME-8 Task 2 NOTSOFAR-1，远场会议转写。
- 团队：ASLP@NPU + Tencent Ethereal Audio Lab。
- 系统：[[方向/AI语音/知识/基础概念/CSS（连续语音分离）|CSS]] + ASR + speaker diarization；CSS 融入 WavLM，ASR 用 AdaLoRA 微调 Whisper large-v2，SD 用 ResNet293 / Ecapa1024。
- 结果口径：公开 poster / paper 报告 dev2 set 上 single-channel 和 multi-channel tcpWER 均较 baseline 大幅下降。
- 判断：这是腾讯在阵列/会议转写口径下最值得跟的 CHiME 记录。

#### 4.2.3. CHiME-8 MMCSG：NPU-TEA

- 任务：CHiME-8 Task 3 MMCSG，智能眼镜多模态会话。
- 团队：ASLP@NPU + Tencent Ethereal Audio Lab。
- 系统：基于 CHiME-8 NOTSOFAR baseline 风格，做 AGC、CSS、ASR、SD；同时报告 streaming 和 non-streaming 配置。
- 判断：同一 NPU-TEA 线覆盖 NOTSOFAR-1 和 MMCSG，说明腾讯 TEA 更像“会议/穿戴转写系统工程”团队。

#### 4.2.4. URGENT 2025 Track 1：Tencent AI Lab

- 团队：Tencent AI Lab + 重庆邮电大学 + 中科院声学所 + 南京大学。
- 系统：dual-path T-F discriminative SE，fast band split / merge、Fourier Analysis Network channel mixing、progressive block expansion training。
- 结果：论文写明 submitted system ranked first on Track 1；Top-3 表中 rank 1 system 在 WB-PESQ、ESTOI、SDR、SpkSim、CAcc 上优势明显。
- 判断：这是腾讯在 universal SE 公开榜上的最强硬证据。

### 4.3. 字节

#### 4.3.1. CHiME-7 Task 2 UDASE：NWPU-ByteAudio

- 任务：CHiME-7 Task 2 UDASE，unsupervised domain adaptation for speech enhancement。
- 团队：Northwestern Polytechnical University + RTC Lab, ByteDance / ByteDance。
- 公开记录：CHiME 2023 programme 将 `The NWPU-ByteAudio System for CHiME-7 Task 2 UDASE Challenge` 列入 top systems presentations；后续 evaluation paper 也把 Northwestern Polytechnical University and ByteDance 的 N&B submission 列为参赛方法之一。
- 判断：这是字节 CHiME 侧的明确参赛记录，但任务是单通道 domain adaptation speech enhancement，不是多麦会议阵列。

#### 4.3.2. URGENT 2024 / 2025：ByteDance multistage universal SE

- 团队：ByteDance, China。
- 系统：audio declipping、packet loss compensation、audio separation、spectral inpainting 四阶段 universal speech enhancement。
- 结果：ISCA 页面写明系统在 URGENT 2024 challenge 以 MOS 3.52 排名第一，并在 URGENT 2025 第二 track 排名第四。
- 判断：字节在 URGENT 上更像“主观质量 / 多失真恢复”路线，和腾讯 2025 Track 1 的强判别式路线形成对照。

### 4.4. 华为 2012 / 华为音频

当前未把华为列为 CHiME / URGENT 公开参赛强记录，原因是：

- 未检索到 Huawei 2012 Labs 作为队伍或 affiliation 的 CHiME / URGENT submitted system。
- 华为 CBG 音频部门参与 CCF AATC 2025 Speech Restoration Challenge，是相邻国内赛事，不是 CHiME / URGENT。
- 搜到的 Huawei 相关条目多为其他语音任务、产品线或相邻赛事，不能直接证明华为 2012 在 CHiME / URGENT 参赛。

后续若要补证，优先查：ICASSP / Interspeech workshop proceedings、华为 2012 音频算法组主页、Huawei CBG Audio paper list、CHiME / URGENT leaderboard 原始 team metadata。

## 5. 横向判断

| 维度 | 阿里 | 腾讯 | 字节 | 华为 |
|---|---|---|---|---|
| CHiME 强度 | 中：CHiME-8 MMCSG | 强：CHiME-5、CHiME-8 NOTSOFAR/MMCSG | 中：CHiME-7 UDASE | 弱：未见直接记录 |
| URGENT 强度 | 强：2026 Track 1 第三 | 强：2025 Track 1 第一 | 强：2024 第一、2025 Track 2 第四 | 弱：未见直接记录 |
| 技术画像 | 混合式 SE + 智能眼镜 DSE | 判别式 SE + 会议转写系统 | 多阶段恢复 + UDASE | 产品音频强，公开挑战赛弱 |
| 是否值得建团队页 | 暂缓；已有 Qwen / DashScope 相关页 | 可建 Tencent Audio / TEA 页 | 可建 ByteAudio / RTC Audio 页 | 暂缓；证据不足 |

## 6. 对后续跟踪的意义

- 如果目标是**公开 challenge 背书**：优先跟腾讯、字节、阿里；华为暂按产品线和相邻赛事观察。
- 如果目标是**阵列/会议转写前端**：优先看腾讯 NPU-TEA、阿里 SEUEE；字节 UDASE 是单通道增强适配，不是会议阵列主线。
- 如果目标是**universal speech enhancement**：腾讯 2025、字节 2024/2025、阿里 2026 是三条可直接对比路线：判别式、分阶段恢复、判别+生成融合。

## 7. 关键来源

- [The SEUEE System for the CHiME-8 MMCSG Challenge](https://www.isca-archive.org/chime_2024/pang24_chime.html)
  - 内容定位：SEUEE 系统、Hummingbird Audio Lab / Alibaba affiliation、CHiME-8 MMCSG WER 口径。
  - 用途：确认阿里 CHiME-8 参赛记录。
  - 核验日期：2026-08-05
- [A Hybrid Discriminative and Generative System for Universal Speech Enhancement](https://arxiv.org/abs/2601.19113)
  - 内容定位：Alibaba Intelligent Connectivity / Tongyi AI Lab，URGENT 2026 Track 1 第三。
  - 用途：确认阿里 URGENT 2026 参赛记录。
  - 核验日期：2026-08-05
- [Alibaba unified-audio GitHub](https://github.com/alibaba/unified-audio)
  - 内容定位：QuarkAudio / hybrid system 新闻条目，确认 URGENT 2026 Track 1 第三和代码生态入口。
  - 用途：追踪阿里后续开源与模型族。
  - 核验日期：2026-08-05
- [Improved Speaker-Dependent Separation for CHiME-5 Challenge](https://www.isca-archive.org/interspeech_2019/wu19d_interspeech.html)
  - 内容定位：NWPU / Tencent AI Lab 的 CHiME-5 speaker-dependent separation 后续系统，记录 development set WER 改进。
  - 用途：确认腾讯 CHiME-5 参赛线索。
  - 核验日期：2026-08-05
- [The NPU-TEA System for the CHiME-8 NOTSOFAR-1 Challenge](https://www.isca-archive.org/chime_2024/huang24b_chime.html)
  - 内容定位：Tencent Ethereal Audio Lab + NPU，NOTSOFAR-1 系统。
  - 用途：确认腾讯 CHiME-8 NOTSOFAR 参赛记录。
  - 核验日期：2026-08-05
- [The NPU-TEA System Report for the CHiME-8 MMCSG Challenge](https://www.isca-archive.org/chime_2024/huang24_chime.html)
  - 内容定位：Tencent Ethereal Audio Lab + NPU，MMCSG 系统。
  - 用途：确认腾讯 CHiME-8 MMCSG 参赛记录。
  - 核验日期：2026-08-05
- [Scaling beyond Denoising: Submitted System and Findings in URGENT Challenge 2025](https://www.isca-archive.org/interspeech_2025/sun25d_interspeech.html)
  - 内容定位：Tencent AI Lab 参与，URGENT 2025 Track 1 第一，系统结构和 Top-3 指标表。
  - 用途：确认腾讯 URGENT 2025 参赛记录。
  - 核验日期：2026-08-05
- [CHiME 2023 Programme](https://www.chimechallenge.org/workshops/chime2023/programme)
  - 内容定位：NWPU-ByteAudio / ByteDance 被列为 CHiME-7 Task 2 UDASE top systems presentation。
  - 用途：确认字节 CHiME-7 UDASE 参赛记录。
  - 核验日期：2026-08-05
- [Objective and subjective evaluation of speech enhancement methods in the UDASE task of the 7th CHiME challenge](https://www.sciencedirect.com/science/article/am/pii/S0885230824000688)
  - 内容定位：列出 Northwestern Polytechnical University and ByteDance 的 N&B submission。
  - 用途：补证字节 CHiME-7 UDASE 是实际提交，不只是报告题目。
  - 核验日期：2026-08-05
- [Multistage Universal Speech Enhancement System for URGENT Challenge](https://www.isca-archive.org/interspeech_2025/le25b_interspeech.html)
  - 内容定位：ByteDance system，URGENT 2024 第一、URGENT 2025 Track 2 第四。
  - 用途：确认字节 URGENT 参赛记录。
  - 核验日期：2026-08-05
- [The CCF AATC 2025: Speech Restoration Challenge](https://www.researchgate.net/publication/395541671_The_CCF_AATC_2025_Speech_Restoration_Challenge)
  - 内容定位：Huawei CBG Audio Department 参与国内 speech restoration challenge。
  - 用途：说明华为有相邻赛事记录，但不计入 CHiME / URGENT。
  - 核验日期：2026-08-05

## 8. 待验证

- 腾讯 CHiME-5 NWPU / Tencent speaker-dependent separation 的原始论文页和最终 leaderboard 是否需要单独归档。
- CHiME-8 MMCSG 官方 awards / task results 中 SEUEE 与 NPU-TEA 的奖项、rank 与最终 WER 是否需要表格化。
- URGENT 2026 official results 中阿里第三名是否和最终 ICASSP paper 完全一致。
- 是否为 Tencent Ethereal Audio Lab、ByteAudio、Alibaba Hummingbird Audio Lab 建独立团队页。
- 是否继续查华为 2012 / Huawei Audio 在非 CHiME/URGENT 的国内音频挑战赛记录，另开“国内音频挑战赛”页。

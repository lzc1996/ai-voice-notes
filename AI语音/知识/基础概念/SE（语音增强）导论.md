---
title: SE（语音增强）导论
类型: 概念
发表时间:
时间依据: 方向导论；非单一发表物
相关任务:
  - 语音增强
相关模型:
  - "[[方向/AI语音/模型/UniPASE]]"
  - "[[方向/AI语音/模型/SenSE]]"
  - "[[方向/AI语音/模型/TF-GridNet]]"
  - "[[方向/AI语音/模型/DiT-Flow]]"
  - "[[方向/AI语音/模型/PGUSE]]"
  - "[[方向/AI语音/模型/GAP-URGENet]]"
  - "[[方向/AI语音/模型/WavLM]]"
  - "[[方向/AI语音/模型/HuBERT]]"
相关评估:
  - "[[方向/AI语音/评估/DNS Challenge（深度噪声抑制挑战）]]"
  - "[[方向/AI语音/评估/CHiME（语音分离与识别挑战赛）]]"
  - "[[方向/AI语音/评估/NOTSOFAR-1（远场会议转写挑战）]]"
aliases:
  - 语音增强（SE）导论
  - SE
  - 语音增强
  - 语音增强导论
  - se
tags:
  - 类型/对象
  - 方向/AI语音
  - 任务/语音增强
---

# SE（语音增强）导论

语音增强（SE）要解决的问题：真实录到的语音从来不是"干净"的，SE 从受污染的录音中恢复出清晰、可懂、不失真、像本人、内容没错的语音，服务人耳聆听和下游机器系统（ASR、会议、助听）。本笔记是 [[方向/AI语音增强/README|AI 语音增强]] 方向的总入口。

这里的 `SE` 在本组 AI 语音笔记里统一指 **Speech Enhancement**，不是 software engineering、search engine 或其他缩写。

## 1. 信号模型

```
x(t) = s(t) * h(t) + n(t)
       ─────   ─────   ────
       干净语音  房间冲激  加性噪声
                响应(RIR)
```

- `s(t) * h(t)` 卷积项产生**混响**（详见 [[Reverberation Modeling（混响建模）]]）
- `n(t)` 是**加性噪声**（环境声、设备底噪、风噪）
- 实际链路还叠加**削波**（过载截顶）、**带宽限制**（电话 8 kHz）、**codec 伪影**（Opus/AMR 压缩）、**丢包**（VoIP 抖动）

## 2. 任务子类

| 子任务 | 去除的退化 | 场景 |
|--------|-----------|------|
| Denoising（降噪） | 加性噪声 | 通话、会议、助听 |
| Dereverberation（去混响） | RIR 卷积尾 | 远场拾音、大房间 |
| Declipping（去削波） | 幅度截顶失真 | 录音电平过载 |
| Bandwidth Extension（带宽扩展） | 频带缺失（8k→48k Hz） | 电话音质提升 |
| Packet Loss Concealment（丢包隐藏） | 帧丢失 | VoIP |
| Codec 去伪影 | 压缩噪声 | 低码率链路 |

近邻但不等同的任务：[[方向/AI语音/知识/基础概念/SR（语音恢复）|语音恢复]]（单人多退化修复）、[[方向/AI语音/知识/基础概念/SS（语音分离）|语音分离]]（多人分开）、[[方向/AI语音/知识/基础概念/TSE（目标说话人提取）|目标说话人提取]]（给定参考捞一个人）——[[UniSE（Unified Speech Enhancement）|UniSE]] 把这三者统一（unified = 统一**任务空间**）；**universal SE**（URGENT 定义）则是用上表所有失真通吃单一增强任务（universal = 统一**失真空间**），代表是 [[方向/AI语音/模型/UniPASE|UniPASE]] 和 [[方向/AI语音/模型/SenSE|SenSE]]。

维护口径：对象笔记的 `任务` / `tags` 应按严格任务写。SS / TSE 模型可以被 SE 方向跟踪为相邻技术或方法来源，但不要因为它们使用降噪、去混响、beamforming、生成式精修或 SE 指标，就直接贴 `任务/语音增强` 标签。

## 3. 方法演进（四代）

### 3.1. 经典信号处理（1970s–2000s）

- 谱减法、维纳滤波、MMSE-STSA：估计噪声谱从带噪谱中"减掉"
- 多通道：[[方向/AI语音/知识/基础概念/Array Audio Signal（阵列音频信号）|阵列音频信号]]、[[方向/AI语音/知识/基础概念/DOA（到达方向）|DOA]]、[[方向/AI语音/知识/基础概念/Beamforming（波束形成）|波束形成]]（[[方向/AI语音/知识/基础概念/MVDR（最小方差无失真响应）|MVDR]]/GSC）、WPE 去混响
- 特点：无需训练、可解释；对非平稳噪声和强混响力不从心，易产生"音乐噪声"伪影

### 3.2. 判别式深度学习（2015–2023）

- 两条建模范式：**掩码**（估计时频掩码）与**映射**（直接回归干净谱/波形）
- 代表：CRN → DCCRN → Conv-TasNet（时域）→ [[方向/AI语音/模型/TF-GridNet|TF-GridNet]]（频域 SOTA 常客）
- 轻量实时系：RNNoise、DeepFilterNet（工程落地主力）
- 特点：内容保持极好（PESQ/ESTOI 高）、延迟可控；强退化下"干净但发闷"，主观听感有天花板

### 3.3. 生成式（2022–至今）

- **扩散系**：SGMSE+ 开创 → StoRM（生成+预测混合早期形态）
- **DiT/FM 系**：DiTSE（录音室级 QMOS 4.34）、FlowSE、[[方向/AI语音/模型/DiT-Flow|DiT-Flow]]、Stream.FM（32 ms 实时）——见 [[DiT 与语音增强（DiT-based Speech Enhancement）]]
- **codec LM 系**：[[方向/AI语音/模型/SELM|SELM]]、[[方向/AI语音/模型/GenSE|GenSE]]、[[UniSE（Unified Speech Enhancement）|UniSE]]、[[方向/AI语音/模型/DDSE|DDSE]]——离散 token + 自回归 LM；关键风险是“离散 token 是否真的可纠错”，见 [[方向/AI语音/思考/Error-Correcting Speech Token（可纠错语音 Token）]]
- **表示回归系**：[[方向/AI语音/模型/UniPASE|UniPASE]]（PASE→UniPASE，WavLM 音系先验压幻觉）、[[方向/AI语音/模型/SenSE|SenSE]]（语义 token + flow matching）
- 特点：强退化下音质碾压判别式，但有**幻觉风险**（生成不存在的内容）

### 3.4. 混合式（2025–至今，当前 SOTA 形态）

- 早期代表 [[方向/AI语音/模型/PGUSE|PGUSE]]：同一模型内并行 predictive branch 和 score-based diffusion generative branch，用 output fusion 与 truncated diffusion 融合保真和生成能力。
- 生成式补听感 + 判别式守内容，代表 [[方向/AI语音/模型/GAP-URGENet|GAP-URGENet]]（URGENT 2026 冠军：UniPASE 生成分支 + [[方向/AI语音/模型/TF-GridNet|TF-GridNet]] 预测分支 + PostNet 融合）
- 出现原因：**指标分裂**——URGENT 2025 纯生成式 MOS 第一但 PESQ 1.34、内容被改写；纯判别式内容稳但听感平庸（见 [[SE SOTA（语音增强模型表现）]]）

## 4. 关键工程维度

- **实时性**：RTF（实时率）与算法延迟（帧长 + lookahead）。通话要求 <50 ms 总延迟——DeepFilterGAN 40 ms、Stream.FM 32 ms；离线修复可放宽（DiTSE 8×A100 训练、32 步采样）
- **参数量/算力**：端侧 1–5M（RNNoise 仅几十 K），云端可到 500M+（GAP-URGENet 567M）
- **网络模块**：常见组合包括 STFT/mel 前端、mask/deep filtering、[[方向/AI语音/模型/TF-GridNet|TF-GridNet]]、DiT/FM、SSL 条件编码器、codec/vocoder 和 VAD/chunking，详见 [[方向/AI语音/知识/技术路线/语音网络结构与模块|语音网络结构与模块]]。
- **幻觉控制**的三种抓手：WavLM 音系先验蒸馏（UniPASE）、显式语义 token（SenSE）、判别式分支兜底（混合式）

## 5. 评估

四类指标（详见 [[语音增强评估指标体系]]）：

- **侵入式**：[[PESQ]]、[[STOI 与 ESTOI|ESTOI]]、[[SI-SDR]]——需干净参考
- **非侵入式**：DNSMOS（[[OVRL_MOS]]）、[[NISQA]]、[[UTMOS]]——无参考，真实录音可用
- **内容/身份保持**：[[CAcc]]、[[SpkSim]]——生成式幻觉探针，现必报
- **主观听测**：P.808 / P.835——金标准

基准演进：[[方向/AI语音/数据集/VoiceBank-DEMAND|VoiceBank-DEMAND]]（经典但饱和）→ [[方向/AI语音/评估/DNS Challenge（深度噪声抑制挑战）|DNS Challenge]] → [[方向/AI语音/评估/URGENT（通用语音增强挑战）|URGENT]]（universal 七失真、多语言、一半真实录音，当前主战场）。

多通道 / 远场 ASR 口径另见 [[方向/AI语音/评估/CHiME（语音分离与识别挑战赛）|CHiME]]：它主线是识别 / diarization，阵列增强只是前端手段；[[方向/AI语音/评估/NOTSOFAR-1（远场会议转写挑战）|CHiME-8 NOTSOFAR-1]] 可用于看阵列前端对真实会议转写的下游收益，但不是阵列增强 benchmark。

## 6. 当前格局一句话

判别式守住实时和内容底线，生成式定义音质上限，混合式拿走综合冠军；领域共识正从"把噪声去干净"转向"**全失真覆盖 + 低幻觉 + 可验证的内容保持**"——universal SE 因此成为新主战场。

## 7. Flow Matching 之外的方案

| 方案 | 核心思路 | 适合场景 | 主要代价 |
|---|---|---|---|
| 判别式增强 / 回归 | 直接学 `noisy -> clean` | 实时、通话、低幻觉优先 | 强退化下易过平滑，听感上限有限 |
| 谱掩码 / Deep Filtering | 在 STFT 上预测 mask 或复数滤波器 | 工程成熟、低延迟、端侧 | 对混响、缺失、codec 伪影恢复有限 |
| 扩散 / Score-based / SDE | 从噪声逐步去噪到干净语音 | 离线高质量修复 | 步数多、延迟高、可能幻觉 |
| [[方向/AI语音/知识/基础概念/Flow Matching（流匹配）]] / ODE | 学速度场，少步 ODE 采样 | 低步数生成式增强、实时化尝试 | 仍要多步采样，solver / chunk 边界要测 |
| Vocoder / Analysis-Synthesis | 先分析内容或声学特征，再重建波形 | 带宽扩展、老录音修复、缺失补全 | vocoder 锁定音质上限，可能改音色 |
| codec LM / 自回归 token | 预测干净 codec token，再 decoder 还原 | LLM/多任务 prompt 化；代表：[[方向/AI语音/模型/SELM]]、[[方向/AI语音/模型/GenSE]]、[[UniSE（Unified Speech Enhancement）]]、[[方向/AI语音/模型/DDSE]] | 自回归慢，tokenizer 上限明显 |
| SSL 表示回归 / 蒸馏 | 恢复或蒸馏 [[方向/AI语音/模型/WavLM]] / [[方向/AI语音/模型/HuBERT]] 类表示 | 内容保持和低幻觉优先 | 表示层选择会影响音色和细节 |
| 传统 DSP / 统计方法 | Wiener、谱减、AEC、[[方向/AI语音/知识/基础概念/Beamforming（波束形成）]]、Kalman | 可解释、低算力、硬实时 | 复杂非平稳噪声上限低 |

选型规则：实时语音 Agent 优先判别式 / deep filtering / AEC；离线高质量修复可看扩散、Flow Matching 和 vocoder 修复；要接 LLM 生态看 codec LM；不允许“脑补”内容时优先判别式、表示回归或混合式。

## 8. 相关对象

- 方向：[[方向/AI语音增强/README|AI 语音增强]]
- [[方向/AI语音/知识/基础概念/Array Audio Signal（阵列音频信号）|阵列音频信号]]：多通道增强、beamforming 和音频大模型后端的方案分工。
- [[方向/AI语音/知识/基础概念/Beamforming（波束形成）|Beamforming]]：阵列前端把目标方向增强成单通道或多方向流。
- [[方向/AI语音/知识/基础概念/MVDR（最小方差无失真响应）|MVDR]]：多通道 SE 中常见的约束 beamforming 算法。
- [[方向/AI语音/知识/基础概念/DOA（到达方向）|DOA]]：阵列前端估计声源方向，辅助 beamforming、TSE 和会议转写。
- [[方向/AI语音/评估/URGENT（通用语音增强挑战）|URGENT]]：universal speech enhancement 的主流挑战赛/评测基准。
- [[方向/AI语音/知识/基础概念/SR（语音恢复）|语音恢复]]：单人多退化修复，是 SE 里的 restoration 口径。
- [[方向/AI语音/知识/基础概念/SS（语音分离）|语音分离]]：多人混合语音拆成各说话人轨道，是 SE 的相邻任务。
- [[方向/AI语音/知识/基础概念/TSE（目标说话人提取）|目标说话人提取]]：相邻任务，给定目标说话人线索后提取一路目标语音。
- [[方向/AI语音/知识/技术路线/语音网络结构与模块|语音网络结构与模块]]：说明语音模型里常见骨干、条件模块、输出头和实时切块机制。
- [[方向/AI语音/知识/基础概念/音频数据预处理|音频数据预处理]]：语音增强训练前需要构造 noisy-clean paired data、RIR、噪声、codec 和 SNR 控制。
- [[方向/AI语音/思考/Error-Correcting Speech Token（可纠错语音 Token）]]：生成式 / codec LM 增强里的表示设计判据，区分 robust semantic tokens 与 clean acoustic tokens。
- 深化阅读路径：[[Reverberation Modeling（混响建模）]] → [[语音增强评估指标体系]] → [[SE SOTA（语音增强模型表现）]] → [[DiT 与语音增强（DiT-based Speech Enhancement）]] → 各模型笔记（[[方向/AI语音/模型/PGUSE|PGUSE]]、[[方向/AI语音/模型/UniPASE|UniPASE]]、[[方向/AI语音/模型/GAP-URGENet|GAP-URGENet]]、[[方向/AI语音/模型/SenSE|SenSE]]、[[方向/AI语音/模型/DiT-Flow|DiT-Flow]]、[[UniSE（Unified Speech Enhancement）|UniSE]]、[[方向/AI语音/模型/DDSE|DDSE]]）
- [[方向/AI语音/知识/技术路线/音频方案迁移到一维信号|音频方案迁移到一维信号]]：说明语音增强方法迁移到其他一维信号时要替换表示、条件和评估指标。

## 9. 待验证

- 本导论与方向 README 的分工：README 管研究边界与待办，本笔记管概念地图——后续维护时避免重复。

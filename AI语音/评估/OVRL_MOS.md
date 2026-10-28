---
title: OVRL_MOS
类型: 概念
发表时间: 2021-10-05
时间依据: DNSMOS P.835 arXiv 首次提交日
aliases:
  - OVRL MOS
  - Overall MOS
  - DNSMOS OVRL
  - P.835 OVRL
  - DNSMOS P.835
  - P808_MOS
  - pDNSMOS
  - overall mean opinion score
tags:
  - 类型/对象
  - 方向/AI语音
  - 任务/语音增强
  - 指标/语音质量
---

# OVRL_MOS

## 0. 背景

**问题现场**：实时通话与降噪评估需要无参考的整体听感自动评分，且要区分"语音失真"与"背景噪声"两类问题来源。

**切入点**：Microsoft DNS Challenge 团队按 ITU-T P.835 听测协议训练无参考神经网络，分别预测 SIG/BAK/OVRL 三个分数，OVRL 即总体质量。

## 1. 身份

`OVRL_MOS` 通常指 DNSMOS / ITU-T P.835 风格评估里的 overall mean opinion score：对整段语音总体质量的 MOS 预测值。

在 P.835 三维度里，常见输出是：

- `SIG_MOS`：speech signal quality，语音本身是否失真。
- `BAK_MOS`：background quality，背景噪声是否烦人。
- `OVRL_MOS`：overall quality，总体听感质量。

## 2. 用途

- 语音增强/降噪模型评估：看增强后整体听感是否变好。
- [[方向/AI语音/评估/DNS Challenge（深度噪声抑制挑战）|DNS Challenge]]、实时通话、语音 Agent 前端评估：作为主观听感的自动化代理指标。
- 和 PESQ、STOI、SI-SDR、ASR WER/CER 一起看，避免单指标误判。

## 3. 计算口径

- `OVRL_MOS` 通常不是人工现场打分，而是 Microsoft DNS Challenge 团队提出的 DNSMOS P.835 神经网络预测模型，对单段语音直接预测出的 MOS-like 分数。
- 分数一般按 MOS 习惯解释为 1 到 5，越高越好；具体范围和标定以评估工具为准。
- P.835 风格区分 `SIG/BAK/OVRL`，所以 OVRL 高不代表语音不失真，也不代表背景完全干净。
- 如果评估目标是 ASR 收益，OVRL_MOS 只能说明听感趋势，仍要看 WER/CER、实体词错误、数字错误和端到端任务收益。

DNSMOS P.835 的工程公式是微软训练的无参考神经网络模型预测：

$$
(\widehat{SIG},\widehat{BAK},\widehat{OVRL})=f_\theta(x)
$$

$$
\mathrm{OVRL\_MOS}=\widehat{OVRL}
$$

批量报告通常取均值：

$$
\overline{\mathrm{OVRL}}=\frac{1}{M}\sum_{i=1}^{M}\widehat{OVRL}_i
$$

## 4. 版本口径差异

`OVRL_MOS` 本身不是一个模型版本，而是 DNSMOS / P.835 工具链里的总体质量输出字段。实际比较时要先确认用的是哪套 DNSMOS 口径：

| 口径 | 常见输出 | 主要差异 | 适用场景 |
|------|----------|----------|----------|
| DNSMOS / P.808 | `P808_MOS` | 只预测整体听感质量，不拆语音失真和背景噪声。 | 只需要一个 overall MOS 代理分。 |
| DNSMOS P.835 regular | `SIG`、`BAK`、`OVRL` | 按 P.835 拆成语音质量、背景质量、总体质量；`OVRL` 才是这里的 `OVRL_MOS`。 | 语音增强、降噪和通话质量评估主用。 |
| P.835 raw | `SIG_raw`、`BAK_raw`、`OVRL_raw` | ONNX 模型原始输出，未做 polynomial calibration。 | 复现实验或调试；不建议直接和论文表格混比。 |
| P.835 calibrated | `SIG`、`BAK`、`OVRL` | raw 输出后经过多项式校准；当前工程脚本通常同时写出 raw 和校准值。 | 正常报告优先使用。 |
| pDNSMOS / personalized | `SIG`、`BAK`、`OVRL` | personalized 口径，更关注目标说话人增强，会惩罚干扰说话人残留。 | 目标说话人增强、个性化降噪。 |

关键区别：`P808_MOS` 和 P.835 的 `OVRL` 都像“整体 MOS”，但训练标注协议不同，不能当作同一个指标横向比较。模型文件、脚本版本、是否 personalized、是否使用 calibrated 输出都会影响绝对分数。

## 5. DNSMOS 子维度解析

DNSMOS P.835 有类似 NISQA 的“维度解析”，但粒度更粗：它只拆 `SIG`、`BAK`、`OVRL` 三个维度。三者同样不是手工信号公式，而是用 P.835 主观听测标签训练出的无参考回归模型。

| 维度 | 具体含义 | 典型低分原因 | 和 NISQA 的近似关系 |
|------|----------|--------------|----------------------|
| `SIG` / `SIG_MOS` | speech signal quality，只看语音本身是否自然、清晰、失真少。 | 过度降噪、金属声、水声、削波、vocoder 伪影、带宽受限、语音被抹平。 | 接近 NISQA 的 `Coloration` + `Discontinuity`，但没有拆开。 |
| `BAK` / `BAK_MOS` | background noise quality，只看背景噪声是否干净、不烦人。 | 残留噪声、音乐残留、他人声泄漏、风噪、混响尾、底噪。 | 接近 NISQA 的 `Noisiness`，但也会受背景突变影响。 |
| `OVRL` / `OVRL_MOS` | overall quality，对语音失真、背景噪声和整体听感的综合评分。 | `SIG` 或 `BAK` 任一维度差、整体不自然、听感疲劳。 | 接近 NISQA overall MOS，不等价于四个子维度平均。 |

训练口径可以简写为：

$$
(\widehat{SIG},\widehat{BAK},\widehat{OVRL})=f_\theta(x)
$$

其中监督标签来自 P.835 风格听测：听众分别评价语音信号质量、背景噪声质量和总体质量。P.808 DNSMOS 则只预测整体 MOS，不提供 `SIG/BAK/OVRL` 解析。

使用上，DNSMOS 的解析适合回答“问题主要在语音失真还是背景噪声”；NISQA 的四维解析更适合进一步定位“噪声、音染、断续、响度”这类故障类型。两者都不能检测内容是否被改写，也不能保证说话人身份保持。

## 6. 使用注意

- 语音增强可能提高 `BAK_MOS`，但同时引入语音失真、降低 `SIG_MOS`。
- 重噪、混响、音乐背景、非英语/方言和合成语音场景可能和 DNSMOS 训练分布不一致。
- 不要只报告 `OVRL_MOS`；至少同时报告 `SIG_MOS`、`BAK_MOS` 和任务指标。
- 批量评测前先固定采样率、响度、裁剪方式、静音处理和测试集构成。
- 跨论文或跨 leaderboard 比较时，必须标明 DNSMOS 版本：P.808 / P.835、regular / personalized、raw / calibrated、模型文件和代码 commit。
- 旧版与新版 DNSMOS 模型的绝对分数可能差异很大；除非复现同一工具链，否则只适合看同一实验内的相对排序。

## 7. 相关对象

- [[方向/AI语音增强/README|AI 语音增强]]：OVRL_MOS 是语音增强质量评估里的总体听感指标。
- [[方向/AI语音/知识/基础概念/Audio Leakage（漏音）|漏音]]：漏音、回声和残留背景声会影响总体听感质量。
- [[方向/AI语音/评估/CER（Character Error Rate）|CER]]：ASR 收益要和听感指标分开看。
- [[方向/AI语音/评估/DNS Challenge（深度噪声抑制挑战）|DNS Challenge]]：常用 DNSMOS / P.835 风格指标评估噪声抑制模型。
- [[方向/AI语音/评估/CSIG CBAK COVL（复合客观质量指标）|CSIG / CBAK / COVL]]：语义同构的有参考三件套（CSIG↔SIG、CBAK↔BAK、COVL↔OVRL）；一个是 8 kHz 线性回归、一个是 16/48 kHz 神经网络，数值不可互推。

## 8. 关键资源

- [DNSMOS P.835 paper](https://arxiv.org/abs/2110.01763)
  - 内容定位：论文提出 non-intrusive P.835 指标，用深度模型预测 speech quality、background noise quality 和 overall quality。
  - 用途：解释 `SIG_MOS`、`BAK_MOS`、`OVRL_MOS` 的来源。
  - 核验日期：2026-08-17
- [DNSMOS implementation](https://github.com/microsoft/DNS-Challenge/tree/master/DNSMOS)
  - 内容定位：Microsoft DNS Challenge 仓库中的 DNSMOS 工具实现。
  - 用途：工程计算 DNSMOS / OVRL_MOS 的入口。
  - 核验日期：2026-07-28
- [dnsmos_local.py](https://github.com/microsoft/DNS-Challenge/blob/master/DNSMOS/dnsmos_local.py)
  - 内容定位：本地 DNSMOS 推理脚本，包含 P.808、P.835、raw / calibrated、personalized 参数等工程口径。
  - 用途：核对具体评测脚本输出字段和版本差异。
  - 核验日期：2026-08-14
- [DNSMOS model version discussion](https://github.com/microsoft/DNS-Challenge/issues/123)
  - 内容定位：社区关于 DNSMOS P.835 新旧模型分数差异的讨论。
  - 用途：提醒跨版本绝对分数不能直接混比。
  - 核验日期：2026-08-14

## 9. 待验证

- 当前项目使用的是 DNSMOS P.835、DNSMOS P.808，还是其他工具输出的 `OVRL_MOS` 字段。
- 当前项目是否统一采用 calibrated `OVRL`，以及是否需要保留 `OVRL_raw` 作为调试字段。
- 是否需要建立统一语音增强评测脚本：SIG/BAK/OVRL、PESQ、STOI、SI-SDR、ASR WER/CER。
- 中文、方言、TTS 合成语音和通话链路的 OVRL_MOS 是否与人工听感一致。

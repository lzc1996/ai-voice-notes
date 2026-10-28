---
title: REVERB Challenge（混响语音挑战）
类型: 评测基准
发表时间: 2014
时间依据: 挑战赛举办年份（Kinoshita et al. 2016 总结论文确认 2014 年举办）
任务:
  - 语音增强
  - 去混响
  - ASR
aliases:
  - REVERB
  - REVERB Challenge
  - REVERB 2014
  - REverberant Voice Enhancement and Recognition Benchmark
  - 混响语音挑战
  - 混响语音增强与识别基准
tags:
  - 类型/对象
  - 方向/AI语音
  - 任务/语音增强
  - 任务/去混响
  - 任务/ASR
  - 主题/混响
  - 主题/远场语音
---

# REVERB Challenge（混响语音挑战）

## 0. 背景

- 首个针对**混响**的统一评测框架，使去混响与混响鲁棒 ASR 算法第一次可以同口径横比。
- 确立了"WPE 去混响 + beamforming + 强声学模型"的经典远端识别前端范式，深刻影响后续 CHiME-3/4/5 等系统。
- 仿真 + 真实配对设计是研究仿真-真实失配的早期范本。
- 至今仍是多通道去混响 / 分离论文的经典对比锚点（近年 SpatialNet 等论文仍在 REVERB 上报数）。

## 1. 身份

`REVERB Challenge`（REverberant Voice Enhancement and Recognition Benchmark）是 2014 年举办的社区级评测挑战（IEEE AASP TC 挑战系列），面向**混响语音**的语音增强（SE）与语音识别（ASR）。动机是当时去混响与混响鲁棒 ASR 各论文数据与口径不一、无法横比，挑战赛提供统一评测框架（任务 + 数据库）。场景设定：混响房间中单个空间静止说话人的语音，用 1 通道 / 2 通道 / 8 通道圆形麦克风阵列（8 麦阵直径 20 cm、全向麦、16 kHz）采集。

边界：专注**混响鲁棒性**，噪声只是中等程度的平稳环境噪声（SNR 20 dB），不是噪声鲁棒挑战；单说话人、无重叠；与 CHiME 系列（噪声 / 多说话人 / 多设备）互补。

## 2. 任务口径

- **ASR 任务**：识别混响测试语音，指标 WER；不提供说话人身份、房间参数、距离、位置等先验；允许任意输入特征、声学模型、训练准则、解码策略与前端处理；允许对单个测试条件做 full-batch 处理与多遍无监督自适应。官方基线：HTK 三音子 GMM-HMM（clean / multi-condition 训练）+ CMLLR 自适应 + bigram 语言模型。
- **SE 任务**：客观指标 FWSegSNR、CD、LLR、SRMR（非侵入式去混响度量）、可选 PESQ；听感测试采用 MUSHRA 框架，分**感知混响量**（perceived amount of reverberation）与**总体质量**（overall quality）两个维度。
- 两个任务均按 1-ch / 2-ch / 8-ch 分别参评，可只参加部分通道数。

## 3. 数据口径

- **阵列**：8 麦圆阵，直径 20 cm，[[方向/AI语音/知识/基础概念/Omni Mic（全向麦克风）|全向麦克风]]；训练 / Dev / Eval 全部提供 1-ch、2-ch、8-ch 版本，采样率 16 kHz。
- **SimData（仿真）**：WSJCAM0 干净语音卷积**实测 RIR**，再叠加实测平稳环境噪声（SNR 20 dB，主要来自空调、低频能量较大）；3 个房间（T60 约 0.3 / 0.6 / 0.7 s）× 2 距离（near ≈50 cm / far ≈200 cm）= 6 个混响条件。
- **RealData（真实）**：来自 MC-WSJ-AV 语料，说话人在真实混响房间（T60 约 0.7 s）朗读，含轻微头部运动；near ≈100 cm / far ≈250 cm 两个条件；文本提示与部分 SimData 相同，可与 SimData 共用声学 / 语言模型。
- **训练集**：clean WSJCAM0 训练集 + multi-condition 训练集（干净语音卷积 24 条实测 RIR + 20 dB 噪声，T60 约 0.2–0.8 s）；训练、Dev、Eval 使用不同房间。
- 设计要点：SimData-room3-far 的声学条件刻意贴近 RealData，用于观察仿真-真实差距；总结论文指出二者 WER 宏观相关，但在头部系统上差距仍明显，说明仿真技术本身仍是研究方向。

## 4. 结果口径

- 基线 GMM-HMM（multi-condition 训练 + CMLLR）在 RealData 上 WER **49.2 %**；最佳系统（8 麦）降到 **9.0 %**。
- 共 27 篇投稿，含 25 个 SE 系统与 49 个 ASR 系统。
- 头部 ASR 系统共性：**多通道前端（WPE 逆滤波去混响 + MVDR / delay-sum 波束形成）+ DNN 声学模型 + 特征 / 模型空间自适应（CMLLR / MLLR / VTLN）+ 系统融合（ROVER）**。以 Delcroix 等为例：8-ch 去混响 >30 % 相对 WER 下降，MVDR 再贡献约 30 %，DNN 声学模型 + 自适应再降 60 %+15 %。
- 结论：8 麦系统已接近 clean / headset 上界（参考识别 WER：SimData 3.5 %、RealData 6.9 %）；1 通道系统差距仍大。
- SE 侧结论：当时算法已能有效降低感知混响量并提升总体音质（含真实重混响环境）；但客观指标只能粗略对应感知混响量，**无法很好代表总体音质**。

## 5. 典型系统链路

```text
1/2/8-ch 混响语音
  -> 多通道去混响（WPE 逆滤波）
  -> 波束形成（MVDR / delay-sum）
  -> 单通道后处理（统计 RIR 谱减 / NMFD / DAE 特征增强）
  -> ASR（DNN-HMM + 自适应 + ROVER）或 SE 指标 / 听感评测
```

## 6. 关键来源

- [REVERB Challenge 官网](https://reverb2014.dereverberation.com/)
  - 内容定位：官方入口，挑战赛任务、数据下载与结果发布页。
  - 用途：核对任务与数据定义、下载数据、查看各系统分项结果。
  - 核验日期：2026-08-10（**抓取失败**：网络错误；官网当前可访问性与数据下载入口见待验证）
- [A summary of the REVERB challenge: state-of-the-art and remaining challenges in reverberant speech processing research（Kinoshita et al., EURASIP JASP 2016）](https://link.springer.com/article/10.1186/s13634-016-0306-6)
  - 内容定位：官方总结论文，涵盖挑战赛动机、数据集（SimData / RealData / 训练集）、SE 与 ASR 任务定义、评测指标与参赛系统结果分析。
  - 用途：核验对象身份、数据口径、任务口径与结果数字（49.2 % 基线 / 9.0 % 最佳）。
  - 核验日期：2026-08-10

## 7. 相关对象

- [[方向/AI语音/知识/基础概念/WPE（加权预测误差）|WPE]]：REVERB 头部系统的核心去混响算法（STFT 域逆滤波）。
- [[方向/AI语音/知识/基础概念/MVDR（最小方差无失真响应）|MVDR]]、[[方向/AI语音/知识/基础概念/Beamforming（波束形成）|Beamforming]]：REVERB 头部系统的标准多通道前端。
- [[方向/AI语音/知识/基础概念/Reverberation Modeling（混响建模）|Reverberation Modeling]]：挑战赛的建模对象（RIR 卷积 + 加性噪声）。
- [[方向/AI语音/评估/CHiME（语音分离与识别挑战赛）|CHiME]]：后续社区挑战系列；REVERB 确立的去混响 + 波束形成前端被 CHiME 系统沿用。
- [[方向/AI语音/团队/NTT Speech Group（NTT 语音组）|NTT Speech Group]]：挑战赛组织者所在团队（Kinoshita、Delcroix、Nakatani 等）。
- [[方向/AI语音/评估/WER（词错误率）|WER]] / [[方向/AI语音/评估/PESQ|PESQ]]：ASR 任务主指标 / SE 任务可选客观指标。
- [[方向/AI语音/评估/语音增强评估指标体系]]：REVERB 的"客观指标 + MUSHRA 听感"双轨评测是指标有效性讨论的经典案例。
- [[方向/AI语音/知识/调研与地图/Array Speech Enhancement Frontier（阵列语音增强前沿调研）|阵列语音增强前沿调研]]：REVERB 在"经典评测集（方法对比锚点）"中的位置。
- [[方向/AI语音/模型/Multi-Stream Diffusion|Multi-Stream Diffusion]]：其 NTT demo 使用 REVERB 2 通道样例。

## 8. 待验证

- 官网 https://reverb2014.dereverberation.com/ 2026-08-10 抓取失败（网络错误）：数据当前下载方式、许可条款、是否仍需注册。
- 官网发布的各参赛系统分项指标明细（本页结果口径只引用总结论文）。
- 挑战赛精确时间线（征稿、评测截止、REVERB 2014 workshop 日期）。
- 组织者完整名单与主办方构成（公开信息指向 NTT 主导的 Kinoshita / Delcroix / Nakatani 等，IEEE AASP TC 挑战系列）。

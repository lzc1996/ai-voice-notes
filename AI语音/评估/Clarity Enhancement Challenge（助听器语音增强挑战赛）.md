---
title: "Clarity Enhancement Challenge（助听器语音增强挑战赛）"
类型: 评测基准
发表时间: 2021
时间依据: CEC1 结果在 Clarity-2021 workshop 公布
aliases:
  - Clarity Challenge
  - Clarity Enhancement Challenge
  - CEC1
  - CEC2
  - CEC3
  - Clarity-CEC2-2022
  - Clarity ICASSP-2023 Enhancement Challenge
  - Clarity Prediction Challenge
  - CPC1
  - CPC2
  - CPC3
  - Clarity Project
  - 助听器语音增强挑战赛
tags:
  - 类型/对象
  - 方向/AI语音
  - 任务/语音增强
  - 主题/助听
  - 主题/可穿戴设备
---

# Clarity Enhancement Challenge（助听器语音增强挑战赛）

## 0. 背景

**问题现场**：助听器用户在嘈杂环境（客厅、餐厅）中听不清语音，是全球逾 3.6 亿 disables hearing impairment 人群的核心痛点；但语音增强研究界长期以 PESQ/STOI/DNSMOS 等通信或通用口径评算法，没有任何公开基准回答"这个算法对听障用户到底有没有用"。CHiME 系列评的是下游 ASR/Diarization，DNS Challenge 评的是通信降噪，均不触达听障感知。

**前序路线缺口**：离线"信号处理式"助听算法（方向性麦、降噪曲线）几十年渐进改良，缺乏机器学习方法的系统化输入；且没有把**客观可懂度指标**（HASPI/MBSTOI）与**听障被试真人听测**放进同一公开榜。

**切入点**：英国四所大学（Sheffield、Nottingham、Salford、Cardiff）组成 Clarity Project（UKRI/EPSRC 资助），联合 Hearing Industry Research Consortium（助听产业联盟）与 Amazon 办系列挑战赛，让助听器算法第一次在"仿真场景 + 客观可懂度 + 真人听测"三重口径下公开排名。

## 1. 身份

`Clarity Enhancement Challenge`（CEC）是 Clarity Project 组织的**助听器噪声语音增强**系列挑战赛（CEC1 2021 → CEC2 2022 → CEC3/ICASSP-2023 SPGC），姊妹系列是评**可懂度预测模型**的 `Clarity Prediction Challenge`（CPC1/CPC2/CPC3）。它是唯一由**产业联盟出资排名**的助听增强榜，也是最早把"双耳穿戴 6 麦 + 听障感知评测"搬进机器学习挑战赛的系列。

边界：它不是阵列会议增强榜（场景是单说话人 + 干扰，不是多人会议），也不是通用 SE 榜（指标是助听感知口径 HASPI/HASQI/MBSTOI，从不使用 PESQ/DNSMOS/WER）。

## 2. 系列速览

| 届次 | 年份 | 场景 | 客观指标 | 榜首 |
|---|---|---|---|---|
| CEC1 | 2021（Clarity-2021 workshop） | 模拟客厅，目标说话人 + 单一平稳干扰（语音或家电） | MBSTOI | Sheffield E009，0.693（基线 0.282） |
| CEC2 | 2022（Clarity-CEC2-2022 workshop） | 模拟客厅多干扰源（语音/音乐/家电），SNR −12~+4 dB，加入头转信息 | HASPI | E009 WAVLAB（CMU）0.966 / 真人可懂 91.5 |
| CEC3（ICASSP 2023 SPGC） | 2023 | 逐届最复杂 + 真实录音 eval 集 | Ave=(HASPI+HASQI)/2 | E028_data 0.693（基线 0.197）；实测集最佳仅 0.208 |
| CPC1/2/3 | 2022/2023/2025 | 评可懂度预测模型（输入助听输出 + 听力图 → 预测正确词率） | RMSE | CPC3 结果 2025-08 于 Clarity-2025 workshop 公布 |

## 3. 各届设定与结果

### 3.1. CEC1（2021）

- **数据**：40 名英国英语说话人 × 250 句的新语料（Graetzer et al., Data in Brief 2022）+ 真实家居噪声样本 + 带基础信号处理的基线助听器模型；场景为模拟家居环境，干扰是平稳噪声（竞争语音或家电）。
- **评测**：13 个系统；客观 MBSTOI + 27 名听障被试真人听测（noise / speech 干扰分列）。
- **结果**：最佳 Sheffield E009 MBSTOI 0.693（基线 0.282）。因主办方关联 Sheffield 队不获奖，MBSTOI 奖牌：Brno 1st、Music Tribe 2nd、ELO-SPHERES 3rd；听测奖牌 Oldenburg 1st；Amazon 学生奖给了 Brno 的 Zmolikova 等。参赛队含 Tencent/Shenzhen、Googlears 等。
- **结论**（Graetzer et al., Computer Speech & Language 102, 102021, 2026）：DNN + 自适应波束形成组合收益最大；但直接对 MBSTOI 优化的算法不总能转化为真实听测收益——感知评测不可替代。

### 3.2. CEC2（2022）

- **升级**：多干扰源（语音/音乐/家电）、SNR −12~+4 dB、**头部朝向旋转**信息引入（系统可选用说话人注册与头转信息，结果表单列标注）。
- **设备口径**：双耳 6 麦——每侧 BTE 助听器 3 麦（前/中/后），最多 6 输入通道；**5 ms 因果约束**（低前瞻流式）。
- **评测**：18 个系统；客观 HASPI（Kates & Arehart 2021, Speech Comm）+ 听障被试真人可懂度。全体系统平均 HASPI 0.55（SNR −8~0 dB 段平均 0.61），最佳系统全 SNR 段 >0.9。
- **榜单**：1) E009 WAVLAB（Cornell et al., CMU）HASPI 0.966 / 真人 91.5——多通道目标说话人提取 + refinement；2) E031 DRC-NET（刘晋江 & 张学良，内蒙古大学）0.801 / 78.1；3) E008_hr（Orka Inc）0.784。真人听测第 3 名是南京大学 × 地平线 E037（0.775 / 69.4）。基线 0.258 / 26.5。
- **信号**：DRC-NET 与 WAVLAB 的双榜前二意味着"高 HASPI"与"高真人可懂"在这一届高度一致——与 CEC1 的指标↔听测裂缝形成对照。

### 3.3. CEC3 / ICASSP 2023 SPGC（2023）

- **设定**：作为 ICASSP Signal Processing Grand Challenge 举办；指标改为 Ave=(HASPI+HASQI)/2，Eval 1（仿真集）排名；Eval 2 用**真实录音**；ID 后缀 `_data` 表示用了额外训练数据、`_hr` 表示用了头转信息。
- **结果**：仿真最佳 E028_data Ave 0.693（HASPI 0.816 / HASQI 0.570），基线 0.197；**真实录音集全线大跌**——各系统 Eval 2 Ave 最高仅 0.208（E030），最佳系统 E028 从 0.693 掉到 0.022。仿真↔真实的裂缝再次被定量证实，比 CHiME 系列的同类观察更刺眼。
- **典型系统**：南京大学 × 同济 Lei et al. 低延迟混合多通道系统（online WPE 去混响 + EaBNet 短窗空间滤波 + 低 SIR 后处理，Eval 1 HASPI 0.729）。

## 4. 系列现状（截至 2026-10）

- **增强线（CEC）停在三届**，未宣布 CEC4；Clarity-2025 workshop（第 6 届，Delft，Interspeech 2025 satellite，2025-08-22）明确讨论了挑战赛可持续性，"嘈杂对话"方向已由 [[方向/AI语音/评估/ECHI（助听对话增强）|CHiME-9 ECHI]] 接棒。
- **预测线（CPC）仍在继续**：CPC1（Interspeech 2022 special session）→ CPC2（2023 satellite workshop）→ CPC3（2025-03-17 启动，07-31 截稿，结果 2025-08 公布）。CPC3 任务：输入助听输出音频 + 听力图等听者特征，预测听障被试逐句正确词率，按 RMSE 排名；分 intrusive（需干净参考）与 non-intrusive 两类，基线为 HASPI；EvalAI 榜单。
- **同门旁支**：Cadenza（歌词/演唱场景，同一团队的项目）独立于 CEC 线。

## 5. 组织与产业

- **主办方**：Clarity Project = Sheffield、Nottingham、Salford、Cardiff 四校 + Hearing Industry Research Consortium（助听产业联盟，出奖方）+ Amazon（支持与学生奖）；EPSRC（UKRI）资助；RNID 支持。
- **参赛构成**（CEC2）：CMU（WAVLAB）、内蒙古大学、Orka、南京大学 × 地平线机器人、台湾大学、中研院、Oldenburg、Tokyo Metropolitan 等学界 + 助听/芯片工业队——是助听厂、消费音频厂与学界同榜的少数场合。

## 6. 使用注意

- 指标口径完全是**助听感知系**（MBSTOI/HASPI/HASQI/真人可懂度），与通信 SE（PESQ/STOI）、通用 SE（DNSMOS）和 ASR 系（WER）三套体系都无交点——跨榜比较无意义。
- "客观指标高分 ≠ 真人受益"是系列反复证明的主命题（CEC1 结论 → CEC3 实测集崩塌），引用该榜数字时必须区分仿真集与真实录音集。
- 5 ms 因果约束 + 双耳 6 麦 + 头转信息，是它区别于离线 SE 榜的架构分水岭；满足该约束的流式架构（如低延迟 EaBNet 类）才能上榜。

## 7. 关键来源

- [CEC2 Results（官方）](http://claritychallenge.org/docs/cec2/cec2_results)
  - 内容定位：CEC2 全榜（HASPI + 真人可懂度）、获奖名单与系统报告链接。
  - 用途：CEC2 数字与获奖队口径来源。
  - 核验日期：2026-10-28
- [CEC1 Results（官方）](https://claritychallenge.github.io/docs/cec1/cec1_results)
  - 内容定位：CEC1 全榜（MBSTOI + 真人听测）与奖牌归属（含 Sheffield 不参赛规则）。
  - 用途：CEC1 数字口径。
  - 核验日期：2026-10-28
- [ICASSP 2023 结果（官方）](http://claritychallenge.org/docs/icassp2023/icassp2023_results)
  - 内容定位：CEC3/SPGC 的 Eval 1/Eval 2 双榜（HASPI/HASQI/Ave）。
  - 用途：仿真↔真实裂缝的定量来源。
  - 核验日期：2026-10-28
- [Graetzer et al., "The first Clarity Enhancement Challenge", Computer Speech & Language 102 (2026) 102021](https://orca.cardiff.ac.uk/id/eprint/188328/)
  - 内容定位：CEC1 官方总结论文（设计、数据、13 系统结果、结论）。
  - 用途：CEC1 权威叙述与"MBSTOI 优化不等于真实收益"结论出处。
  - 核验日期：2026-10-28
- [CPC3 Intro（官方）](http://www.claritychallenge.org/docs/cpc3/cpc3_intro)
  - 内容定位：CPC3 任务定义（RMSE、intrusive/non-intrusive、HASPI 基线、EvalAI 榜）与时间线。
  - 用途：预测线现状口径。
  - 核验日期：2026-10-28
- [Clarity-2025 Workshop（官方）](http://claritychallenge.org/clarity2025-workshop)
  - 内容定位：第 6 届 Clarity workshop 议程（含 CPC3 结果、未来挑战讨论、ECHI 衔接）。
  - 用途：系列现状与走向判断依据。
  - 核验日期：2026-10-28
- [Clarity Project 官网](http://www.claritychallenge.org/)
  - 内容定位：系列总入口（文档、开源代码、Colab 教程）。
  - 用途：届次导航。
  - 核验日期：2026-10-28

## 8. 相关对象

- [[方向/AI语音/评估/ECHI（助听对话增强）|ECHI（CHiME-9）]]：接棒"嘈杂对话助听增强"方向的后续挑战赛（智能眼镜 + 助听器、20 ms 流式、MUSHRA 定榜）。
- [[方向/AI语音/评估/DNS Challenge（深度噪声抑制挑战）|DNS Challenge]]：同期单通道通用降噪榜，指标与场景完全不同口径。
- [[方向/AI语音/评估/CHiME（语音分离与识别挑战赛）|CHiME]]：评下游识别的远场基准；Clarity 评听障感知——两大体系无指标交点。
- [[方向/AI语音/评估/语音增强评估指标体系|语音增强评估指标体系]]：HASPI/HASQI/MBSTOI 属感知可懂度分支，未纳入通用口径的详情见该页。
- [[方向/AI语音/知识/基础概念/Beamforming（波束形成）|Beamforming]]：CEC1 结论中与 DNN 组合收益最大的经典前端；CEC3 典型系统用 EaBNet 类神经空间滤波。
- [[方向/AI语音/知识/基础概念/TSE（目标说话人提取）|TSE]]：CEC2 冠军 WAVLAB 系统的核心模块。
- [[方向/AI语音/知识/调研与地图/Array-Agnostic SE Industry（工业界阵列可变语音增强调研）|工业界阵列可变语音增强调研]]：§11.2 的 Clarity 榜条目与本页互链。

## 9. 待验证

- CEC2 "5 ms 因果约束"的规则原文出处（当前口径来自库内调研页，未回对官方 rules 页）。
- CEC3 E028（_data 变体）团队的完整归属与系统描述论文信息。
- CPC3 最终榜单前名与获胜系统细节（结果 2025-08 已公布，未逐条核）。
- CEC 线是否真的无 CEC4（仅有 2025 workshop 的"未来挑战可持续性"讨论，未见官方声明）。

---
title: RealMAN
类型: 数据集
发表时间: 2024-06
时间依据: arXiv 首次提交（2406.19959，2024-06）；NeurIPS 2024 收录
任务:
  - 语音增强
  - 多通道增强
aliases:
  - RealMAN
  - RealMAN 数据集
  - 真实麦克风阵列数据集
tags:
  - 类型/对象
  - 方向/AI语音
  - 任务/语音增强
  - 任务/多通道增强
  - 主题/阵列信号
  - 资源/数据集
---

# RealMAN

## 0. 背景

**出现前的问题**：多通道语音增强与声源定位的训练、评测长期依赖"RIR 仿真（图像法）+ 多通道弥散噪声仿真"，根源是缺少大规模实录数据（原文摘要原话）。这个替代方案有两层失配：RIR 仿真那层是标称几何与真实声学的偏差（含麦克风位置标定误差，对学 RIR 的模型尤其致命）；噪声场那层是真实噪声的空间相关性高度时变、并不服从弥散场假设。原文基线里最刺眼的一条证据：SpatialNet 用"仿真语音 + 真实噪声"训练**反而最差**（SI-SDR −9.7）——sim-to-real 缺口不是均匀的，混一点真实数据未必更好。此前真实语料的空档是：单通道真实噪声（DNS 系）没有阵列维；真实阵列语料（AMI 等会议语料）面向转写，没有逐源标注、做不了增强的有参考评测。

**RealMAN 填的坑**：原文自述两个价值——在真实场景下做 SE / 定位 benchmark，以及提供真实训练数据。三个关键设计决定都由"填坑"推导而来：①语音与噪声**分开实录**（同一批场景），混合比与 SNR 因此可控、可复现，且噪声统计是真实的；②clean 目标取**直达路径语音**（源信号过滤波器估计出的直达分量），让 PESQ / SI-SDR 这类有参考指标可用——代价是参考本身有偏，原文明说只作参考、推荐看 DNSMOS；③鱼眼相机自动检测扬声器做方位标注，移动声源（35.4 h）因此可标。单一 32 通道物理阵列是妥协：真实多阵列同步录制成本过高，改用"单阵列 + 随机子阵列采样"支撑变阵列研究，后来发展出 Fixed-Array / Variable-Array 两档设置。

**出现后的谱系**（2024-06 发布，NeurIPS 2024）：到 2026 年它成了两条研究线的默认真实评测场——**阵列无关 / 几何泛化**（[[方向/AI语音/模型/Geo-DConv|Geo-DConv]] 的 array-invariant 验证、[[方向/AI语音/模型/Uni-ArrayDPS|Uni-ArrayDPS]] 的生成式精修 4/8 麦）和**生成式增强的真实域测试**（[[方向/AI语音/模型/CaSNet|CaSNet]] 多通道压缩传输、[[方向/AI语音/模型/DiT-Flow|DiT-Flow]] 单通道零样本、[[方向/AI语音/模型/CleanMel|CleanMel]] 的 ASR 口径）。但没有随之形成官方 leaderboard 或统一协议：混噪 SNR 在原文、仓库配置、下游论文三处各说各话（见 §4），各家结果被聚合站切成互不可比的榜单，各口径数字见 [[方向/AI语音/评估/RealMAN 测试结果清单|RealMAN 测试结果清单]]。

## 1. 身份

`RealMAN`（Real-recorded and annotated Microphone Array speech&Noise）是西湖大学音频信息与信号处理实验室（AudioLab）与希尔贝壳（AISHELL）联合开源的**真实录制 32 通道麦克风阵列语音与噪声数据集**，NeurIPS 2024，arXiv:2406.19959，代码与说明见 GitHub `Audio-WestlakeU/RealMAN`，许可 CC-BY-4.0。规模 **83.7 小时语音**（静 speaker 48.3h + 动 speaker 35.4h，约 35h 为普通话）+ **144.5 小时背景噪声**，覆盖 32 个录制场景（室内 / 室外 / 半室外 / 交通）。

边界：不是仿真混合物数据集——语音与噪声均为实录，目标是缓解 RIR 仿真与真实场景的声学失配；也不是 Geo-DConv 的附属产物——[[方向/AI语音/模型/Geo-DConv|Geo-DConv]]（上交大，Interspeech 2026）只是**使用者**（论文参考文献 [14] 即 RealMAN 原文），真实录制关系为"独立数据集 + 下游论文引用"，调研页"随 Geo-DConv 论文公开"的口径有误（2026-10-23 已核）。它仍是单一阵列（32 通道）录制，但支持取子阵列训练变阵列模型，因此可做多样拓扑评估。

## 2. 数据构成

| 维度 | 内容 |
|------|------|
| 通道数 | 32 通道高保真麦克风阵列（单一物理阵列，可取子阵列） |
| 规模 | 语音 83.7 h（静态源 48.3 h + 移动源 35.4 h）；噪声 144.5 h |
| 场景 | 32 个场景（室内 / 室外 / 半室外 / 交通），噪声另录 31 个场景 |
| 录制方式 | 实录：扬声器播放语音源，鱼眼相机自动标注声源方位 |
| 标注 | 直达路径语音（估计直达滤波器滤出的目标）、转写、声源方位 / 仰角 / 距离 |
| 数据构成 | train / val / val_raw / test / test_raw 与 dataset_info（场景 T60 等） |
| 许可 / 获取 | CC-BY-4.0；AISHELL 页面或原始数据页下载，GitHub 提供说明与基线代码 |
| 阵列坐标 | 是否需要额外几何文件待核（Geo-DConv 类复现依赖坐标，见待验证） |

## 3. 用途

- **array-agnostic / array-invariant 评估**：Geo-DConv 在 RealMAN 上把两个固定阵列模型（论文全表确认 SpatialNet / [[方向/AI语音/模型/TF-GridNet|TF-GridNet]]）改造为 array-invariant 系统，在多样阵列拓扑下取得一致性能提升。
- **真实数据路径**：调研页将 RealMAN 归入缓解仿真-真实失配三条路径中的"真实数据"路径（与弱监督、无监督并列）。
- **置换等变验证**：调研页记录 Geo-DConv 在 RealMAN 上验证了对麦克风排列置换等变，这是 array-invariant 的关键性质。

## 4. 使用注意

- **体量门槛**：train 约 531 GB、val 约 25.6 GB、test 约 38 GB（24-bit 版本），全量落地前需先算存储与下载时间。
- **混噪口径有版本漂移，引用前必须核时代**（2026-10-27 核）：语音（`ma_speech`）与噪声（`ma_noise`）同场景分开实录，SE 输入 = 两者混合，测试集按**实录电平**自然混合（不重调增益），逐条 SNR 分布均值 val ≈ 0.0 / test ≈ −0.8 dB（论文附录 B.5）；训练集随机混合 U[−10, 15] dB。仓库 2024.09 更新把基线训练 SNR 从 [0, 15] 调到 [−10, 15]，但当前 main 分支 `baselines/SE/configs/*.yaml` 仍写 `snr: [0, 15]`——三处口径互相不一致。下游论文又各用各的：Uni-ArrayDPS 写 "−15~5 dB"（三处均不吻合，最可能引测试集逐条 SNR 分布范围），复现任何论文前先确认其混噪区间与 val/test 是否用预混 `ma_noisy_speech`。
- **几何元数据是复现前提**：Geo-DConv 以麦克风坐标为条件，GitHub 说明只列出音频、直达路径语音与定位 CSV，32 通道的坐标文件 / 通道编号映射是否单列待核（见待验证）。
- **与会议语料定位不同**：相比 [[方向/AI语音/数据集/AMI Meeting Corpus（会议语料库）|AMI]] 这类面向转写的真实会议阵列语料，RealMAN 面向**增强**评估，指标口径（PESQ / SI-SDR 等）与 WER 系不可直接横比。

## 5. 关键来源

- [RealMAN 论文（arXiv:2406.19959，NeurIPS 2024）](https://arxiv.org/abs/2406.19959)
  - 内容定位：数据集原文，给出录制设备、场景、标注与基线实验结果。
  - 用途：数据构成、规模、许可口径的一手来源；2026-10-27 复核摘要动机表述（仿真失配、两价值、直达路径目标）。
  - 核验日期：2026-10-23
- [GitHub: Audio-WestlakeU/RealMAN](https://github.com/Audio-WestlakeU/RealMAN)
  - 内容定位：数据集说明 + 基线代码（SE / 定位），含各分卷大小与目录结构、变量命名规则。
  - 用途：获取方式、基线复现、子阵列训练做法。
  - 核验日期：2026-10-23
- [希尔贝壳 RealMAN 开源公告](https://www.aishelltech.com/newsinfo/7700033.html)
  - 内容定位：中文发布说明（32 通道、83h 语音 + 144h 噪声、四类场景）。
  - 核验日期：2026-10-23
- [Towards Array-Invariant Speech Enhancement via Geometry-Aware Dynamic Convolution（arXiv:2607.18658）](https://arxiv.org/abs/2607.18658)
  - 内容定位：Geo-DConv 论文，RealMAN 的下游使用者（参考文献 [14]）。
  - 用途：确认"非随该论文发布"的发布关系。
  - 核验日期：2026-10-23

## 6. 相关对象

- [[方向/AI语音/模型/TF-GridNet|TF-GridNet]]：调研页记录 Geo-DConv 改造的固定阵列骨干之一，在 RealMAN 上完成 array-invariant 验证。
- [[方向/AI语音/模型/AmbiDrop|AmbiDrop]]、[[方向/AI语音/模型/MSEN（特征束多阶编码器）|MSEN]]：同节 array-agnostic 路线（Ambisonics 域编码 / eigenbeam 规范空间）；调研页"待深挖"提议用 RealMAN 做各路线横评。
- [[方向/AI语音/知识/基础概念/IPD（通道间相位差）|IPD]]：IPD 特征绑定固定几何，是 array-agnostic 研究的动机背景。
- [[方向/AI语音/知识/基础概念/Array Audio Signal（阵列音频信号）|Array Audio Signal]]、[[方向/AI语音/知识/基础概念/Array vs Multi-Channel（阵列与多通道）|Array vs Multi-Channel]]：阵列信号与多通道概念基础。
- [[方向/AI语音/数据集/AMI Meeting Corpus（会议语料库）|AMI Meeting Corpus]]：真实录制阵列语料的对照对象（面向转写而非增强）。
- [[方向/AI语音/知识/调研与地图/Array Speech Enhancement Frontier（阵列语音增强前沿调研）|阵列语音增强前沿调研]]：本页条目的上位调研页（"三、真实数据"与"五、阵列无关"两节）。
- [[方向/AI语音/评估/RealMAN 测试结果清单|RealMAN 测试结果清单]]：本数据集上各口径（多通道 PESQ / 单通道 DNSMOS / 原文基线 / 几何泛化 / ASR）的结果汇总与不可横比说明。

## 7. 待验证

- 阵列几何 / 麦克风坐标是否随数据提供：GitHub 说明与目录结构只列音频、直达路径语音、`*_source_location.csv` 与 dataset_info，坐标文件与 32 通道编号映射需在 dataset_info 或基线代码中确认（Geo-DConv 类复现硬依赖）。
- 子阵列采样脚本：基线是否直接给出"取子阵列训练变阵列模型"的切分与 seen / unseen 拓扑划分。
- ~~32 通道 / 83.7h / 四场景~~、~~发布关系~~、~~机构归属~~：均已于 2026-10-23 核实（见身份与关键来源）。
- Geo-DConv 改造的两个固定阵列模型名（SpatialNet / [[方向/AI语音/模型/TF-GridNet|TF-GridNet]]）及各拓扑指标表已由论文全文确认，指标口径见 [[方向/AI语音/模型/Geo-DConv|Geo-DConv]]。
- 是否值得引入本地 array-agnostic 路线横评（对应调研页"待深挖"第 6 条）。

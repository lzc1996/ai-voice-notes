---
title: DRES
类型: 数据集
发表时间: 2026-03
时间依据: arXiv 首次提交日 2026-03-10（v1），2026-07-09 更新 v2
任务:
  - 语音增强
  - 语音识别
aliases:
  - DRES
  - DRES（荷兰语半自发语音数据集）
  - 荷兰语半自发语音数据集
  - A Semi-spontaneous Dutch Speech Dataset for Speech Enhancement and Speech Recognition
tags:
  - 类型/对象
  - 方向/AI语音
  - 任务/语音增强
  - 任务/ASR
  - 主题/真实数据
  - 资源/数据集
---

# DRES

## 1. 身份

`DRES` 是代尔夫特理工大学（TU Delft）Multimedia Computing Group 公开的**荷兰语真实诱发（半自发）语音数据集**，全称 Dutch Realistic Elicited (semi-spontaneous) Speech：**1.5 小时原始音频、80 名说话人**，在四个公共室内空间用**四通道线性麦克风阵列**真实录制。它被明确设计为 **test set**，用于评估 SotA ASR 与语音增强（SE）模型在真实噪声条件下的表现（arXiv:2603.09725；v1 2026-03-10，v2 2026-07-09；Submitted to Interspeech 2026）。

边界：不是仿真加噪混合物——全部为现场真实录制；不是会议 / 多人对话语料——录音内容是"一名说话人在公共室内空间面向阵列讲述"，背景中的其他说话人属于**干扰噪声**而非被转写对象；**也不是多通道阵列增强 benchmark**——录制虽为四通道，本轮评测只用通道 2、结论全部是单通道口径（原文对此有明说，见第 5 节）。

## 2. 数据构成

| 维度 | 内容 |
|------|------|
| 通道数 | 4 通道线性麦克风阵列（摘要 + 正文） |
| 规模 | 1.5 小时原始音频；去静音后保留 1.4 小时语音（摘要给 1.5 h，正文两者都给了）；词表 2,842 词（正文） |
| 语言 | 荷兰语（摘要 + 正文） |
| 场景 | 四栋公共建筑的室内大厅：Ahoy（展会场地，多场对话同时进行）、Pulse（大学午餐区，babble 噪声）、IDE（开放自习区）、Arch（开放创意空间）；Pulse / IDE / Arch 的录制安排在午间（正文）。摘要仅表述为 "noisy, public indoor environments" |
| 录制方式 | 真实录制，现场采集，未做任何仿真加噪（摘要 + 正文） |
| 说话人 | 80 人（65 母语荷兰语 / 12 非母语 / 3 未披露）；按地点 Ahoy 20、Pulse 21、IDE 20、Arch 19；现场招募、无报酬，仅提供小食（正文） |
| 噪声类型 | 背景说话人（background talkers / babble）与场地环境噪声，未注入人工噪声（摘要 + 正文） |
| 阵列几何 | 线性阵列，4 支 AKG C147 PP 领夹麦，**麦克风间距 5 cm**，接 RME Fireface UFX III 声卡，录制采样率 48 kHz；通道 2 位于阵列中心（正文） |
| 标注 | 正字法转写，遵循 Jasmin-CGN 协议；人工时间戳切分为 0.4–24.8 s 片段（原始录音时长 5.7–93.3 s）；由 3 名荷兰语母语志愿者校对；另收集元数据问卷（性别 / 年龄 / 母语性，逐地点分布见原文 Table I）（正文） |
| 划分 | 未给出 train / dev / test 划分；论文把它定位为 test set（摘要 + 正文） |

上表之外、正文另给的口径：说话人到阵列的距离**未控制也未登记**，主观估计多数为 1.0–1.5 m；诱发方式为三种任务（自由讲述 / 图卡描述 / 题卡讲述，图卡与题卡各 26 张）；录音方案经 pilot 调整（时长上限由 20 s 改为建议最多 45 s）；数据采集经 TU Delft HREC 伦理审批。

原文未涉及（不得外推）：录音条数与语音段总数；SNR、混响时间 RT60 等声学参数；干净参考语音；说话人位置或 DOA 标注；发布数据格式、许可协议与下载地址。

## 3. 用途

- **真实噪声下的 ASR 评测**：论文用它评估 8 个开箱即用 SotA ASR 模型（Google Chirp 3、Google Telephony、Microsoft Azure、MMS、Whisper-large-V3、Whisper-large-V3-turbo、NeMo-nl、CGN 预训练 Conformer），基线 WER 从 11.2%（Chirp 3）到 62.5%（Turbo），其中 5 个低于 22%。
- **单通道 SE 的质量 + 下游 ASR 影响评测**：5 个 SE 算法（谱减法 SS、谱噪声门 SNG、MetricGAN-OKD，以及 SGMSE+ 的 WSJ0-CHiME3 与 VoiceBank-DEMAND 两个 checkpoint）先在 DNSMOS P.835 上评语音质量，再送入 8 个 ASR 评 WER。
- **荷兰语真实噪声数据的补位**：原文指出真实噪声语音数据稀缺、荷兰语尤甚（CGN、Jasmin-CGN、Common Voice 12 的荷兰语部分基本为安静环境录音），DRES 用于回答"SotA ASR 在真实嘈杂荷兰语上到底行不行"这一空白问题。
- **多通道 SE 的预留资源**：四通道录制被明确写成 "facilitating future research in multichannel SE"，作者把多通道 SE 列为后续工作。

## 4. 划分口径

- **单一 test set，无 train / dev 划分**：DRES 从设计上就是评测集（"designed as a test set"），原文未给训练 / 验证划分，也未讨论用它训练 SE 或 ASR 模型。
- **两条实验轨用不同版本的数据**：SE 实验用**未切分的原始录音**，ASR 实验用**切分后的片段**——正文明确区分，复现时不能混用。
- **评测侧统一预处理**：基线信号取**通道 2**，重采样到 16 kHz，幅度归一化到 0.707 以防削波；5 个 SE 算法都作用在这套归一化 + 重采样后的语音上。
- **统计口径**：WER 忽略转写中的非语言符号；显著性用 speaker-based bootstrap（10,000 次重采样、95% CI、双侧 p 值）；语音质量用**无参考**的 DNSMOS P.835（1–5 分）。
- **按地点分层报告**：结果同时给出四栋建筑的均值与逐地点拆分（原文 Table II / Table III），即录制地点本身是分析变量。

## 5. 使用注意

- **四通道数据 / 单通道评测的错配（本页重点；原文对此是明说的，不是本页推断）**：引言写明 "DRES is recorded using a four-channel linear microphone array, facilitating future research in multichannel SE. To keep the scope of the present study focused, we consider only single-channel conditions."；II-E 再次写明 "although DRES is a multichannel dataset, in this work we focus on a single-channel analysis"，并交代只用通道 2（阵列中心）。因此：**DRES 目前公开的评测结论全部是单通道口径**，不能拿它当多通道 / 阵列增强（波束形成、空间线索利用、阵列无关性）的 benchmark 或对标基线；把它当多通道数据集引用时，必须补一句"阵列信息在原论文中未被使用"。反过来，四通道录制确实是通往多通道 SE 的真实数据基础设施——但复用前需确认发布版本是否保留全部 4 通道。
- **阵列孔径小、几何非标准**：4 支领夹麦、间距仅 5 cm，是一副很小的线性阵，不是会议室 / 环形阵列那类大孔径几何；说话人到阵列的距离未控制、未登记（多数 1.0–1.5 m）。做空间类方法时，这个几何下的实际空间可分离性需要自行评估。
- **"增强提升 ASR"在本数据上不成立**：论文的核心负面结论是——五个 SE 算法**没有一个**在 DRES 上显著提升任何 ASR 模型的 WER，多数反而显著变差（SNG 最差，在 Conformer 上把 WER 从 21.6% 推到 94.7%）；只有两个 SGMSE+ 版本对**每一条**语音都提升了 DNSMOS。作者归因于语言差异与真实噪声场景，与 StoRM 等在仿真英文混合上的正面结论相反。引用 DRES 时不要默认"SE 前置必然有利于 ASR"。
- **质量分与识别性能不对齐**：Ahoy 的 DNSMOS 显著最低（Kruskal-Wallis，p < .001），但八个 ASR 在四栋建筑间并无显著性能差异；SGMSE+ 中质量更高的 checkpoint（VoiceBank-DEMAND）反而 WER 更差。做指标选型时不要把 DNSMOS 当作 ASR 性能的代理指标。
- **无干净参考**：原文未提及干净参考信号，语音质量用无参考的 DNSMOS P.835 评估；想用它算 PESQ / SI-SDR 这类需要参考的指标会缺参考。
- **发布状态**：原文只承诺 "will be released for use by the academic community upon acceptance of this manuscript"，正文未给下载 URL、发布格式与许可；引用前需确认是否已实际公开（见第 8 节）。
- **与会议阵列语料的定位差异**：相比 [[方向/AI语音/数据集/AliMeeting|AliMeeting]]、[[方向/AI语音/数据集/AISHELL-4|AISHELL-4]] 这类面向长时会议转写的真实阵列语料，DRES 是单人面向阵列讲述 + 公共空间干扰，任务与指标口径不可直接横比。

## 6. 关键来源

- [A Semi-spontaneous Dutch Speech Dataset for Speech Enhancement and Speech Recognition（arXiv:2603.09725）](https://arxiv.org/abs/2603.09725)
  - 内容定位：DRES 数据集的原始论文（TU Delft Multimedia Computing Group；eess.AS；v1 2026-03-10、v2 2026-07-09；Submitted to Interspeech 2026）。第 II 节描述语料设计与录制，第 III 节描述 5 个单通道 SE 算法与 8 个 ASR 模型，第 IV 节给出 DNSMOS 与 WER 结果（Table II 按模型、Table III 按地点）。
  - 用途：核验数据集身份（1.5 h / 80 说话人 / 荷兰语 / 四通道线性阵列真实录制 / test set 定位）、逐字段的录制与标注口径，以及"多通道录制、单通道评测"这一错配的原文出处。
  - 核验日期：2026-10-09
  - 说明：本页字段以论文全文（本地纯文本抽取）为准；`arxiv.org` 的 abs 页在本机网络下无法抓取，题名 / 作者 / 机构取自全文首页，提交日期区间与 "Submitted to Interspeech 2026" 另经第三方索引（SciRate / CatalyzeX）交叉确认。原文未给出数据下载地址，故本页不列下载链接。

## 7. 相关对象

- [[方向/AI语音/模型/SGMSE+|SGMSE+]]：论文评测的现代单通道 SE 之一（两个 checkpoint：WSJ0-CHiME3 与 VoiceBank-DEMAND），也是唯一在每一条语音上都提升 DNSMOS 的算法。
- [[方向/AI语音/模型/StoRM|StoRM]]：论文引用的相反结论来源（扩散式 SE 在英文仿真混合上提升了 E2E ASR），DRES 的负面结果正与之对照。
- [[方向/AI语音/数据集/VoiceBank-DEMAND|VoiceBank-DEMAND]]：SGMSE+ 的 SGV checkpoint 训练语料，即"仿真混合"一侧的代表，论文用它当真实数据的对照组。
- [[方向/AI语音/数据集/RealMAN|RealMAN]]：同属真实录制多通道数据集，但 RealMAN 面向多通道 array-invariant 增强评测，DRES 是"多通道录制 + 单通道评测"，两者对阵列信息的利用口径不同。
- [[方向/AI语音/知识/基础概念/Array vs Multi-Channel（阵列与多通道）|Array vs Multi-Channel]]：正好对应本数据集"有阵列、未用阵列"的概念区分。
- [[方向/AI语音/知识/技术路线/Real-Data Array SE（真实数据驱动阵列增强）|Real-Data Array SE]]：DRES 属该路线下的真实数据（但本轮只做了单通道评测）。
- [[方向/AI语音/知识/调研与地图/Array Speech Enhancement Frontier（阵列语音增强前沿调研）|Array Speech Enhancement Frontier]]：本页条目的上位调研页（"真实数据"一节）。
- [[方向/AI语音/评估/WER（词错误率）|WER]]、[[方向/AI语音/评估/语音增强评估指标体系|语音增强评估指标体系]]：本数据集的两条主评测口径（WER 与 DNSMOS P.835 等无参考质量分）。

## 8. 待验证

- v1 的确切提交日与 arXiv comments 字段：2026-03-10 来自第三方索引，abs 页在本机不可达，未直接核到。
- 发布状态：论文承诺录用后向学术界开放，但实际下载地址、发布格式（是否保留 4 通道）、许可协议均未在原文出现。
- 录音条数与语音段总数：原文只给时长范围（原始 5.7–93.3 s、切分后 0.4–24.8 s），未给条数。
- 原文 Table I 的逐地点性别 / 年龄分布：纯文本抽取中该表错行，未逐项核对。
- 多通道复用的可行性：四通道版本是否随发布提供、是否附带阵列坐标 / 间距等几何元数据、通道间是否为原始同步录制。
- 是否值得把它作为本地方案中"真实荷兰语噪声"评测集，或在多通道 SE 复现中当补充测试集。

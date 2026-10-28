---
title: Array-Agnostic SE Industry（工业界阵列可变语音增强调研）
类型: 调研
核验日期: 2026-10-28
证据状态: 公开论文 / 专利 / 官方博客；未独立复现
相关任务:
  - 语音增强
  - 连续语音分离
  - 个性化语音增强
aliases:
  - 工业界阵列可变语音增强
  - 工业界阵列无关语音增强
  - Array-Agnostic Speech Enhancement Industry
tags:
  - 方向/AI语音
  - 任务/语音增强
  - 任务/多通道增强
  - 主题/分布式阵列
---

# Array-Agnostic SE Industry（工业界阵列可变语音增强调研）

回答一个问题：**工业界在真实部署约束下如何处理"阵列可变 / 阵列无关"**。本页与既有两页分工——硬件、芯片与产品形态见 [[方向/AI语音/知识/调研与地图/Array Speech Enhancement Industry（阵列语音增强工业界方案）|阵列语音增强工业界方案]]，学术方案横排与数字见 [[方向/AI语音/知识/调研与地图/Array-Agnostic SE SOTA（阵列可变语音增强SOTA调研）|阵列可变语音增强SOTA调研]]；分布式/异步的技术路线框架见 [[方向/AI语音/知识/技术路线/Distributed Multichannel SE（分布式异步多通道增强）|分布式异步多通道增强]]。

## 1. 一句话结论

工业界**有阵列可变**，而且微软有一条从 2019 到 2025 连续演进、含专利与产品化尝试的完整链条；但工业界的"可变"几乎清一色走**通道选择 / 置换不变聚合 / 压缩传输**三招，**没有人用学术界流行的坐标条件化**（Geo-DConv 一派）——因为工业场景里设备位置本来就未知。

## 2. 四类工业动机

| 动机 | 场景 | 代表 |
| --- | --- | --- |
| 设备异构复用 | 一个模型跑遍手机 / 笔记本 / 音箱 / 会议棒，新设备免适配 | 微软 geometry-agnostic PSE、Amazon 多几何声学建模 |
| 自带设备 ad-hoc 阵列 | 与会者用手机 / 笔记本临时组阵，替代专用会议硬件 | 微软 Project Denmark、Group Transcribe |
| 带宽 / 功耗受限分布式阵列 | 设备只传压缩特征、不传原始波形回融合中心 | USTC [[方向/AI语音/模型/CaSNet]] |
| 助听器可增删节点 | 双耳 + Roger 远程麦，节点数与位置随佩戴而变 | Phonak / GN / Oticon（封闭） |

## 3. 微软：唯一完整的公开链条

1. **[[方向/AI语音/模型/Project Denmark（多设备云端 ad-hoc 组阵会议转写）|Project Denmark]]**（Interspeech 2019）：手机 / 平板 / 笔记本云端虚拟组阵做会议转写——对齐 + 盲波束形成 + 多流 ASR/说话人日志系统合并；3 麦 / 7 麦比单设备 WER 好 14.8% / 22.4%。自述当时"ad-hoc 阵列尚无产品或公开原型"。
2. **[[方向/AI语音/模型/PickNet（ad-hoc 阵列实时通道选择）|PickNet]]**（ICASSP 2022，arXiv:2201.09586）+ **Group Transcribe**（Garage 实验应用）：放弃同步波束形成，改为**实时通道选择**——每帧用几百毫秒谱块挑离当前说话人最近的设备拼接输出，延迟仅 64 ms；跨通道卷积层对麦数与排列不变；真机多人对话评测 WER 12.6/13.7，低于块级在线波束形成的 13.6/14.4。
3. **[[方向/AI语音/模型/Geometry-Agnostic PSE（几何无关多通道个性化语音增强）|Array geometry agnostic 多通道 PSE]]**（ICASSP 2022，arXiv:2110.10330；美国专利 12,230,259）：说话人 embedding + IPD 空间特征喂进一个几何无关模型，**训练一次跨设备部署**，未见几何仍优于按几何定制的模型。这是 Teams Voice Isolation（单通道个性化增强，2024 GA）背后的多通道演进线。
4. **VarArray**（ICASSP 2022，[[方向/AI语音/模型/VarArray]]）：同一思路搬进连续语音分离（CSS），置换无关特征 + [[方向/AI语音/知识/基础概念/TAC（变换-平均-拼接）|TAC]] + Conformer。
5. **[[方向/AI语音/模型/Windowed Cross-Attention（窗口交叉注意力异步阵列增强）|Windowed cross-attention 异步分布式增强]]**（arXiv:2507.16104，2025，爱丁堡 × MSR）：明确承认 **TAC 在时钟异步下不够用**（设备间延迟可超 100 ms、有时钟漂移），用窗口化交叉注意力动态对齐全通道，模块对排列与麦数不变，在 iFaSNet 与 CRUSE 两种骨干上验证。落地问题写得很直白：理想系统应当让用户**不用手动静音**同屋其它设备。

链条读法：从"同步假设下的盲波束形成"（2019）退到"干脆不同步、只选通道"（2021–22），再回到"用注意力在特征层对齐"（2025）——**异步是工业界相对学术 RealMAN 类评测多出来的一整条约束**。

## 4. 亚马逊：多几何训练 + 与 ASR 联合

- **Multi-Geometry Spatial Acoustic Modeling**（ICASSP 2019，Kumatani 等）：多通道声学建模替代"逐环境适配波束形成器"，靠**多样化训练数据覆盖不同麦克风配置**，让"新设备 / 低出货量设备直接复用高出货量设备的交互数据"——设备异构复用被写成了官方博客的产品逻辑；2 麦系统比旧法 7 麦 WER 低 9.5%。
- **MCTT**（Interspeech 2021）：Transformer-Transducer 内置多通道编码器，通道间用 Average / Concatenation combiner，**模型规模与通道数无关**，流式低延迟，7 麦在库数据上比分段式神经波束形成 WER 相对降约 6%。
- Echo 硬件侧（7 麦环阵 + AZ1/AZ2 边缘 NPU）走固定阵列，见工业界方案页。

## 5. 国内：学术国家队带着工业约束做

- **USTC NERC-SLIP**：[[方向/AI语音/模型/CaSNet]]（ICASSP 2026）针对**带宽与能耗**——各设备本地提特征 + SVD 低秩压缩再传融合中心，跨窗口查询对齐后解码，压缩传输几乎不掉点。这是公开文献里少见的"通信约束优先"的 DMA-SE。
- **腾讯 Ethereal Audio Lab**：multi-look 神经增强 + 唤醒联合优化（Interspeech 2020，固定阵列多方向并行增强）与 TEA-PSE（DNS 挑战赛单通道个性化冠军线）；**公开面上没有阵列可变**。
- 讯飞 / 思必驰 / 声智等会议硬件仍以**加大阵列规模**（24/64 麦）换覆盖，不解决"几何可变"，见工业界方案页 §4–5。

## 6. 助听器行业：最老牌的可变阵列产品

- 双耳 ear-to-ear 链路 + **Roger 远程麦克风**本质上是可增删节点的 ad-hoc 阵列（厂商口径 +10–15 dB SNR），比学术 ad-hoc 阵列早落地十几年；Phonak StereoZoom 2.0、GN ReSound 双耳波束形成是成熟商用形态。
- 但**深度学习 + 可变几何**的公开研究极少：厂商公开的是 DNN 降噪（Oticon、Phonak DEEPSONIC、Starkey NPU），阵列几何与通信协议全部封闭；BLE Audio 的 Isochronous Channels 为 TWS / 助听多设备组阵提供了标准化传输层，尚无公开的"LE Audio ad-hoc 阵列 + 神经增强"论文。
- 与可穿戴/眼镜线的衔接：[[方向/AI语音/模型/AmbiDrop]]（Ambisonics 规范表示 + dropout）用 Project Aria 数据评测；Meta [[方向/AI语音/模型/Cloud-Boosted MC-SE（云端增强低算力多通道增强）|Cloud-Boosted MC-SE]] 走云-边协同，属于"算力可变"而非"阵列可变"。

## 7. 苹果 / 谷歌 / Meta：公开面上的空白

| 公司 | 公开情况 | 判断 |
| --- | --- | --- |
| Apple | 单通道 SE 研究（coarse-to-fine、GAN 动态感知损失）+ 多通道多任务专利（结合视频模态），无阵列可变算法论文；AirPods / HomePod 全部固定阵 | 端到端封闭，专利说明有内部能力，公开面空白 |
| Google | Meet / Pixel 走单通道（Clear Calling）；未检索到阵列可变 SE 公开工作 | 空白 |
| Meta | Aria Gen 2 用鼻托接触麦区分佩戴者（硬件手段回避几何问题）；Virtual-Flow 生成虚拟麦属"补空间观测" | 未做阵列无关本体 |

## 8. 工业界与学术界的五个差异

| 差异 | 学术界（RealMAN / AMI 系） | 工业界 |
| --- | --- | --- |
| 同步假设 | 阵列同步采样 | 设备各自时钟 + 网络延迟 >100 ms，异步是硬约束 |
| 位置信息 | 已标定（或已知子阵） | 设备位置、朝向、甚至麦数都未知 |
| 实时性 | 离线，报 RTF 的少 | 流式（PickNet 64 ms、MCTT 受限前瞻） |
| 评测口径 | SI-SDR / PESQ / DNSMOS | 以 WER / 转写与产品指标为主（Denmark、PickNet、MCTT 全是 WER） |
| 部署单元 | 单一模型 + 数据集 | 一个模型跨设备族（"train once, deploy anywhere"） |

## 9. 技术形态归纳

| 形态 | 代表 | 对可变性的处理 |
| --- | --- | --- |
| 通道选择 | 微软 PickNet、Best-mic 传统 | 不对齐不聚合，逐帧挑最近设备（放弃空间增益换鲁棒） |
| 压缩传输 | USTC CaSNet | 通道数可变 + 带宽受限，SVD 特征回传 |
| 置换不变聚合 | TAC（VarArray）、Average/Concat combiner（MCTT）、windowed cross-attention（MSR 2025） | 聚合层吸收麦数与排列差异 |
| 多几何数据覆盖 | Amazon 2019、VarArray 双几何消融 | 靠训练分布，不靠结构 |
| 规范空间表示 | AmbiDrop（学术，但 Meta 数据评测） | 编码到与阵列无关的表示 |

注意：**坐标条件化（Geo-DConv 一派）在工业界公开工作里缺席**——工业设备没有标定坐标可喂。这与学术 SOTA 页 §2.4 的观察互为镜像：学术界最优的真实数据方案（Geo-DConv）恰恰依赖工业场景给不了的信息。

## 10. 对本库复现线的启示

1. Geo-DConv 的几何泛化横评若要向工业靠拢，应补**异步与无坐标**两档退化实验：把坐标条件换成 dropout（向 AmbiDrop 靠）或去掉（向 VarArray 靠），看掉多少——这是论文没有报的敏感性。
2. 评测指标应补一路 **WER**（whisper/paraformer 级 ASR），工业口径全部落在这上面；DNSMOS 在工业公开材料中几乎不出现。
3. 通信约束（CaSNet 式"传特征不传波形"）与几何泛化是**正交的两轴**，叠加实验目前是空白，与 [[方向/AI语音/模型/Uni-ArrayDPS]] 的"先验与观测分离"思路可以拼。

## 11. 行业 leaderboard：以挑战赛形式存在，不是持续榜单

先回答"有没有"：**没有持续更新的、阵列 SE 专属的行业 leaderboard**。行业侧的排名全部以"挑战赛"形式出现——按届冻结数据、开赛排名、颁奖即关闭；聚合站（SOTA2/WizWand）只有 CHiME-4 ASR、DNS 单通道这类衍生榜。按与"阵列增强"的相关度排序：

### 11.1. CHiME 系列（最贴近阵列 SE，工业参与度最高）

| 届/任务 | 阵列设定 | 指标 | 结果锚点 |
|---|---|---|---|
| CHiME-7/8 **DASR**（2023–24） | **ad-hoc 多设备异步阵列**：一个房间 3–6 个独立设备自由摆放——全挑战赛里最接近"阵列可变"的设定 | macro DA-WER | CHiME-7 榜：USTC-NERCSLIP 16.8%（1）、STCON 18.3（2）、NTT 20.5（3），基线 34.3 |
| CHiME-9 **ECHI**（2025–26） | 4 通道助听器，真实食堂对话 | 低延迟双耳增强 | 结果 2026-05 于 HSCMA&CHiME 2026（巴塞罗那）公布 |
| CHiME-9 **MCoRec** | 单房间多组对话，360° 视频 + 麦阵 | 联合识别-聚类错误率 | 讯飞联合团队第一（相对基线 −57%），连续第六届 CHiME 夺冠 |
| CHiME-10（2026-07 公布）三任务 | **ECHI-2**：智能眼镜多通道 + 视频 + 运动传感，双耳渲染；**SG-TSE**：眼镜目标说话人提取（HATS 重放提供配对数据）；**URGENT**（收编） | WER + 提取质量 + 泛化 | 组织方含 NPU、NJU、NTT、CUHK-SZ、Meta Reality Labs |

注意口径：CHiME 全系用 **WER 评阵列前端**，不比 PESQ/DNSMOS——阵列增强的最终裁判在行业里就是下游识别率。

### 11.2. Clarity Enhancement Challenge（助听器产业联盟出奖，最"行业"的阵列 SE 榜）

> 系列全貌（CEC1/2/3 + CPC 预测线 + 现状）已单开：[[方向/AI语音/评估/Clarity Enhancement Challenge（助听器语音增强挑战赛）|Clarity Enhancement Challenge（助听器语音增强挑战赛）]]。

- 设定：双耳 6 麦（每侧 3 麦 BTE）、SNR −12~+4 dB、**5 ms 因果约束**；指标 HASPI/HASQI + 听障被试真听测。
- CEC2（2022）榜：**E009（WAVLAB）HASPI 0.966 / 真人可懂 91.5**（1）、DRC-NET 0.801（2），基线 0.258；CEC3（ICASSP 2023）改 Ave=(HASPI+HASQI)/2，仿真最佳 0.693 vs 基线 0.197，实测集全线大跌（最佳 0.208）——再次证明仿真↔真实的裂缝。
- 出奖方 Hearing Industry Research Consortium + Amazon 参办；参赛含地平线、Orka 等工业队。这是唯一由**产业联盟出资排名**的阵列增强榜。

### 11.3. 其它一届制或旁支

| 挑战赛 | 阵列设定 | 榜首 | 现状 |
|---|---|---|---|
| **L3DAS22**（快手×罗马一大） | Ambisonics 3D 麦阵（仿真办公） | ESP-SE 0.984（基线 0.833），2 百度、3 腾讯；指标 0.5·STOI+0.5·(1−WER) | 一届即止 |
| **M2MeT / AliMeeting**（阿里巴巴） | 8 麦圆阵会议转录 | 昆山杜克 DER 2.98%；喜马拉雅×USTC 4.05 | 转录榜非 SE 榜，但多通道前端是主要得分杠杆 |
| **URGENT**（Interspeech 2025→2026） | 主线**单通道**通用 SE；在线榜（CodaBench） | T1 判别式子带 RNN（102M 参数）；纯生成式在未见语言崩 | 2026 届扩到 7 类失真 × 5 语言 × 8–48 kHz；被 CHiME-10 收编 |
| **DNS Challenge**（微软） | **无阵列维**（单通道） | 聚合站有衍生榜（WB-PESQ 3.45 DBHN-Net） | 2021 后停办多年，任务被 URGENT 吸收 |

### 11.4. 三条结构性结论

1. **榜单形态**：阵列 SE 的行业排名全是"挑战赛"而非"持续榜"。要跟进就得盯三处：chimechallenge.org（届次公告）、claritychallenge.org、urgent-challenge.com 的在线榜。
2. **指标口径**：行业榜单用 **WER / DA-WER / DER / HASPI**，从不使用 DNSMOS/PESQ——与学术清单里"DNSMOS 是阵营级空白"互为印证：两边的评价体系根本没有交点。
3. **最大空白**：**"阵列可变 / 阵列无关"至今没有专门挑战赛**。最接近的是 CHiME-7/8 DASR 的设备自由摆放（但每队设备数与拓扑在开赛后固定）。用 RealMAN 的 Variable-Array 档办一届是现成候选——目前无人做。

## 12. 关键来源

- [Bring your phones to the conference table（Project Denmark，MSR Blog 2019）](https://www.microsoft.com/en-us/research/blog/bring-your-phones-to-the-conference-table-creating-ad-hoc-microphone-arrays-from-personal-devices)——ad-hoc 阵列转写系统与 14.8%/22.4% 数字。核验 2026-10-28。
- [PickNet（arXiv:2201.09586）](https://arxiv.org/abs/2201.09586)——实时通道选择、64 ms、真机 WER 表。核验 2026-10-28。
- [One model to enhance them all（arXiv:2110.10330）](https://arxiv.org/abs/2110.10330)——geometry-agnostic 多通道 PSE 原文；[美国专利 12,230,259](https://lexdana.ai/patent/12230259)（2021 申请、2025 授权）。核验 2026-10-28。
- [Distributed Asynchronous Device SE via Windowed Cross-Attention（arXiv:2507.16104）](https://arxiv.org/abs/2507.16104)——异步约束与 TAC 不足的官方表述。核验 2026-10-28。
- [Amazon 多几何声学建模（VentureBeat 报道 ICASSP 2019 两文）](https://venturebeat.com/2019/04/01/alexa-researchers-develop-2-mic-speech-recognition-system-that-beats-a-7-mic-array)、[MCTT（Interspeech 2021）](https://lacuna.tiptreesystems.com/work/multi-channel-transformer-transducer-for-speech-recognition/wrk_a7a7555317e93c7e249bc449c0624ee2)。核验 2026-10-28。
- [CaSNet（arXiv:2601.17711）](https://arxiv.org/abs/2601.17711)——带宽约束 DMA-SE，全文数字见其模型页。
- 助听器行业信息（Phonak Sphere / Oticon Intent / Roger 增益口径）来自厂商与评测站二手资料，标尺仅作量级参考。
- [CHiME Challenges 官网](https://www.chimechallenge.org/)：届次公告与历届结果页（CHiME-7 DASR 结果表 2026-10-28 核）。
- [Clarity Challenge 官网](http://claritychallenge.org/)：CEC1/2/3 与 CPC 结果及系统描述论文链接。
- [URGENT Challenge 在线榜](https://urgent-challenge.com/)：CodaBench 持续榜 + 各届技术报告（arXiv 2505.23212 为 2025 届总报告）。核验 2026-10-28。

## 13. 相关对象

- [[方向/AI语音/团队/Microsoft Speech Group（微软语音组）]]：本页链条的团队页（含 windowed cross-attention 条目）。
- [[方向/AI语音/知识/调研与地图/Array Speech Enhancement Industry（阵列语音增强工业界方案）]]：硬件 / 芯片 / 会议设备侧的姊妹页。
- [[方向/AI语音/模型/SAMbA]]、[[方向/AI语音/知识/技术路线/Distributed Multichannel SE（分布式异步多通道增强）]]：异步多流合并的技术细节与路线框架。
- [[方向/AI语音/知识/调研与地图/Array-Agnostic SE SOTA（阵列可变语音增强SOTA调研）]]：学术侧同一问题的方案横排。
- [[方向/AI语音/知识/调研与地图/Personalized SE（个性化语音分离产品线调研）|Personalized SE（个性化语音分离产品线调研）]]：同批公司的另一条产品线（声纹条件化），两线在智能眼镜处交汇（CHiME-10 ECHI-2）。

## 14. 待验证

- Group Transcribe 的产品现状（Garage 实验应用是否已下线）与 Teams 是否吸收了多设备阵列能力——公开信息止于 2021–22。
- windowed cross-attention 的具体数字已在模型页补齐（WASPAA 2025 论文报的是 DNSMOS P.835 + XLS-R-MOS + CD，不是 WER/SI-SDR：CRUSE+WCA+CM OVRL 2.41 / XLSR 2.35，iFaSNet+WCA+CM OVRL 2.35，均优于对应 TAC 配置），详见 [[方向/AI语音/模型/Windowed Cross-Attention（窗口交叉注意力异步阵列增强）]]；本页原预期的 WER/SI-SDR 表与本文口径不符，作罢。
- Amazon Multi-Geometry 2019 两文的正式引用信息（会议页码 / 作者全名单）未核对原文 PDF。
- 助听器双耳链路时延与通信机制（ ear-to-ear 的采样同步方案）为厂商口径，无公开文献级细节。
- CHiME-9 ECHI 具体榜单数字与系统描述论文（2026-05 公布后未逐项核对）；CHiME-10 三任务的数据规模与基线（2026-07 公告后未核）。

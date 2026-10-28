---
title: Array Speech Enhancement Survey Report（阵列语音增强技术调研报告）
类型: 综述
调研时间: 2026-08-24
相关任务:
  - 语音增强
  - 多通道增强
相关模型:
  - "[[方向/AI语音/模型/TF-GridNet]]"
  - "[[方向/AI语音/模型/McNet]]"
  - "[[方向/AI语音/模型/ArrayDPS-Refine]]"
  - "[[方向/AI语音/模型/AMDM-SE]]"
  - "[[方向/AI语音/模型/WNG-MVDR]]"
  - "[[方向/AI语音/模型/GAP-URGENet]]"
  - "[[方向/AI语音/模型/UniPASE]]"
相关团队:
  - "[[方向/AI语音/团队/Z.-Q. Wang Group（Zhong-Qiu Wang 组）]]"
  - "[[方向/AI语音/团队/UIUC SiNRG（UIUC 信号推断研究组）]]"
  - "[[方向/AI语音/团队/NTT Speech Group（NTT 语音组）]]"
相关评估:
  - "[[方向/AI语音/评估/URGENT（通用语音增强挑战）]]"
  - "[[方向/AI语音/评估/CHiME（语音分离与识别挑战赛）]]"
  - "[[方向/AI语音/评估/DNS Challenge（深度噪声抑制挑战）]]"
aliases:
  - 阵列语音增强技术调研报告
  - Array Speech Enhancement Survey Report
  - 阵列增强技术调研报告
tags:
  - 类型/知识
  - 方向/AI语音
  - 任务/语音增强
  - 任务/多通道增强
---

# Array Speech Enhancement Survey Report（阵列语音增强技术调研报告）

本报告是对麦克风阵列语音增强技术的系统性调研，覆盖七条技术路线——经典阵列处理、传统-神经混合、端到端判别式、生成式多通道、LM 化增强五条范式主线，加阵列泛化与数据两条扩展/横切路线——的技术原理、代表方案、横向对比与趋势研判。内容以本库 2024–2026 年持续跟踪的调研笔记为底（[[方向/AI语音/知识/调研与地图/Array Speech Enhancement Frontier（阵列语音增强前沿调研）|阵列语音增强前沿调研]]、[[方向/AI语音/知识/调研与地图/Array Speech Enhancement Industry（阵列语音增强工业界方案）|工业界方案]]、[[方向/AI语音/知识/调研与地图/Array Speech Enhancement Team Map（阵列增强团队地图）|团队地图]]、[[方向/AI语音/知识/调研与地图/SE SOTA（语音增强模型表现）|SE SOTA]]），数据与结论均已按笔记核验日期核过来源。

> [!abstract] 摘要
> - 阵列语音增强的核心增益来自**空间维度**：多通道观测提供 DOA / IPD / ILD / SCM 等单通道没有的空间线索，使"滤波"从时频域扩展到空间域。
> - 技术演进经历**经典阵列处理 → 神经波束形成（混合）→ 全神经端到端 → 生成式多通道 → 判别-生成混合**五个阶段；当前综合最优形态是混合式，URGENT 2026 冠军 GAP-URGENet（生成分支 + TF-GridNet 预测分支 + PostNet 融合）是直接证据。
> - 当前格局的最大特征是**指标分裂**：纯生成式听感碾压（URGENT 2025 MOS 3.69 第一）但内容保持崩塌（PESQ 1.34）；纯判别式守住内容与实时底线但听感有天花板。任何单一指标排名都没有说服力。
> - 工业界阵列硬件已商品化，差异化全部转移到端侧深度学习与"拾音 + 转写 + AI 摘要"打包；学界重心转向生成式建模、空间泛化、真实数据与系统接口（AEC / 全双工 / 低延迟）。
> - "固定阵列 + 多通道生成式端到端 + 语音质量终点"目前无标杆工作，是未来两年风险与机会并存的空位。

## 1. 技术概述

### 1.1. 问题定义与信号模型

语音增强（SE）要从受污染的录音中恢复清晰、可懂、不失真、内容正确的目标语音。单通道信号模型为 $x(t) = s(t) * h(t) + n(t)$，其中 $h(t)$ 是房间冲激响应（RIR，产生混响，建模方法见 [[方向/AI语音/知识/基础概念/Reverberation Modeling（混响建模）|混响建模]]），$n(t)$ 是加性噪声；实际链路还叠加削波、带宽限制、codec 伪影、丢包等退化（详见 [[方向/AI语音/知识/基础概念/SE（语音增强）导论|SE 导论]]）。

阵列场景下，$M$ 个麦克风给出 $M$ 路观测：

$$
x_m(t) = s(t) * h_m(t) + n_m(t), \quad m = 1, \dots, M
$$

同一个声源到达各麦克风的**路径不同**（不同的传播时延、衰减与房间响应 $h_m(t)$），这个差异就是阵列增强可利用的全部额外信息。注意"多通道 ≠ 阵列"：只有当通道间存在可建模的几何/传播关系（几何已知或可学习）时，多通道才构成阵列，见 [[方向/AI语音/知识/基础概念/Array vs Multi-Channel（阵列与多通道）|Array vs Multi-Channel]]。

阵列几何同时决定能力上限：**阵元间距**决定空间奈奎斯特频率——间距超过半波长即出现空间混叠（栅瓣），可用上限频率随之降低；[[方向/AI语音/知识/基础概念/Array Aperture（阵列孔径）]]决定低频指向性上限——孔径越小，低频越难形成有效波束。几何形态主流有线阵、圆阵、平面阵与分布式阵列。还需区分**近场/远场**：远场可用平面波 + 方向假设，近场必须考虑球面传播与距离。工业界的"多麦军备竞赛"（4 → 24/64 单元，见第四章）本质上就是在放宽这些物理约束。

### 1.2. 阵列提供的空间线索

| 空间线索                                            | 物理含义        | 在增强中的用途                                  |
| ----------------------------------------------- | ----------- | ---------------------------------------- |
| [[方向/AI语音/知识/基础概念/DOA（到达方向）]]                   | 声源到达方向      | 定向波束、目标说话人选择、TSE 空间条件                    |
| [[方向/AI语音/知识/基础概念/IPD（通道间相位差）]]                 | 通道间相位差      | 判别式网络的经典空间输入特征                           |
| [[方向/AI语音/知识/基础概念/ILD（双耳声级差）]] / ITD            | 通道间能量 / 时延差 | 双耳保真、空间感维持                               |
| [[方向/AI语音/知识/基础概念/SCM（空间协方差矩阵）]]                | 各通道信号的二阶统计  | MVDR / Wiener 等空间滤波器的核心输入；也可写进生成式模型的似然约束 |
| RIR / [[方向/AI语音/知识/基础概念/steering vector（导向矢量）]] | 源到各麦克风的传递函数 | 精确空间滤波、仿真数据构造                            |

趋势：手工 IPD / ILD 特征正被可学习空间滤波取代（跨通道 conv、帧级 DOA 编码、GNN 通道建模），固定阵列下跨通道 attention/conv 可充分学习几何不变的空间线索。

### 1.3. 任务边界

阵列增强周边有四个严格不同的任务口径，调研对比时必须先拆开：

- **SE（语音增强）**：单人受退化语音 → 干净语音；universal SE（[[方向/AI语音/评估/URGENT（通用语音增强挑战）|URGENT]] 定义）统一噪声/混响/削波/带宽/codec/丢包/风噪七类失真。
- **[[方向/AI语音/知识/基础概念/SS（语音分离）|SS（语音分离）]]**：多人混合 → 各路语音；[[方向/AI语音/模型/ArrayDPS|ArrayDPS]]、[[方向/AI语音/模型/MeCo|MeCo]] 严格属此列，但其扩散逆问题建模与一步生成式校正机制对 SE 有迁移价值。
- **[[方向/AI语音/知识/基础概念/TSE（目标说话人提取）|TSE（目标说话人提取）]]**：给定声纹/方向线索捞一个人；DOA-guided extraction、PATSE 属此列。
- **AEC / 全双工**：有播放参考时的回声消除，与增强的责任边界必须先定清，见 [[方向/AI语音/知识/基础概念/Full-Duplex（全双工）|Full-Duplex]]。

### 1.4. 典型系统链路

```text
multichannel waveform
  -> channel sync / gain / bad-channel check
  -> AEC（有播放参考时）
  -> VAD / DOA / speaker activity
  -> beamforming（空间滤波）
  -> WPE 去混响 / neural SE / post-filter
  -> enhanced mono / multi-beam streams
  -> ASR / audio LLM / 人耳
```

链路中每个环节都可能成为瓶颈：强混响会削弱方向性（空间谱变宽多峰，需配合 WPE）；移动声源要求波束跟踪；有扬声器回放的会议/语音 Agent 场景不能把回声泄漏交给后端兜底。

### 1.5. 方法演进脉络

| 代际 | 时期 | 代表方法 | 特征 |
|---|---|---|---|
| ① 经典阵列处理 | 1970s–2000s | DAS、MVDR、GSC、GEV、WPE、维纳后滤波 | 无需训练、可解释、低延迟；非平稳噪声与强混响上限低 |
| ② 判别式深度学习 | 2015–2023 | mask / mapping 两类范式；TF-GridNet、DCCRN、DeepFilterNet | 内容保持极好、延迟可控；强退化下"干净但发闷" |
| ③ 生成式 | 2022–至今 | 扩散（SGMSE+→StoRM）、DiT/FM（FlowSE）、codec LM（SELM/UniSE）、表示回归（UniPASE/SenSE） | 强退化下音质碾压判别式，但有幻觉风险 |
| ④ 混合式 | 2025–至今 | PGUSE、GAP-URGENet；神经协方差 + 经典空间滤波（WNG-MVDR） | 生成补听感 + 判别守内容，当前综合 SOTA 形态 |

阵列维度的演进与上述并行：经典 beamforming → mask-based 神经波束形成（DNN 估 SCM 再 MVDR）→ 全神经端到端多通道（TF-GridNet、McNet）→ 生成式多通道化（AMDM-SE、mSGMSE）→ 判别-生成混合（判别前端 + 生成精修两段式，如 ArrayDPS-Refine）。

## 2. 现有技术路线

### 2.1. 路线一：经典阵列信号处理

以 [[方向/AI语音/知识/基础概念/Beamforming（波束形成）|波束形成]] 为核心：Delay-and-Sum（按目标方向补偿时延后相加）、Filter-and-Sum、[[方向/AI语音/知识/基础概念/MVDR（最小方差无失真响应）|MVDR]]（目标方向无失真约束下最小化输出噪声功率）、GSC（阻塞矩阵 + 自适应噪声抵消）、[[方向/AI语音/知识/基础概念/GEV（广义特征值波束形成）|GEV]]；去混响侧有 [[方向/AI语音/知识/基础概念/WPE（加权预测误差）|WPE]]、[[方向/AI语音/知识/基础概念/MCLP（多通道线性预测）|MCLP]]。

- **优势**：无训练依赖、完全可解释、算法延迟极低、内容零改写风险；对阵列几何、通道同步、增益校准等先验要求硬。
- **短板**：非平稳噪声和强混响下性能骤降；残余"音乐噪声"；无法恢复被掩蔽的语音成分。
- **现状**：没有消失，而是作为**物理底座**被神经方法包裹（见 2.2），同时是任何新路线必须击败的可解释 baseline（WNG、SCM 估计、观测一致性约束）。

### 2.2. 路线二：传统-神经混合（神经波束形成）

当前**挑战赛与工业主流**：DNN 估计时频掩码或空间协方差 → 交给经典空间滤波器输出，兼得神经网络的非平稳噪声处理能力与经典滤波的可解释性、低失真。2026 年趋势是**可学习协方差与可学习约束**向经典框架渗透。

- [[方向/AI语音/模型/CUSIDE-array|CUSIDE-array]]（ISCSLP 2024）：流式掩码 MVDR 前端，挑战赛/工业主流代表。
- [[方向/AI语音/模型/WNG-MVDR|数据驱动 WNG-MVDR]]（2026-06）：双分支网络联合估噪声掩码与频变白噪声增益阈值，可微鲁棒 MVDR 层自适应"鲁棒性-指向性"权衡，阵列失配下优于固定 WNG。
- [[方向/AI语音/模型/Direction-Preserving MIMO|Direction-Preserving MIMO]]（2026-04）：OnlineSpatialNet 估噪声协方差 Cholesky 因子 + 保向 MIMO Wiener 滤波，输出**多通道**增强结果并保留目标/残余噪声方向线索；参数量与算力约为 mask-based NICE 的 1/3，逼近 oracle。
- [[方向/AI语音/模型/Linearly Constrained Deep Beamformer|Linearly Constrained Deep Beamformer]]（2026-05）：把无失真 + 干扰置零约束经增广拉格朗日损失直接嵌进 DNN 波束权重估计。
- [[方向/AI语音/模型/DiffCBF|DiffCBF]]（EUSIPCO 2025）：卷积波束形成（MCLP 去混响 + beamforming 分离）与扩散模型双向耦合的物理-生成混合。

### 2.3. 路线三：全神经端到端判别式

绕过显式空间滤波公式，网络直接从多通道 STFT/波形学增强映射。[[方向/AI语音/模型/TF-GridNet|TF-GridNet]]、[[方向/AI语音/模型/SpatialNet|SpatialNet]] 双路径架构是强基线；复数谱映射已成标配。

- [[方向/AI语音/模型/McNet|McNet]] / [[方向/AI语音/模型/Mel-McNet|Mel-McNet]]（西湖大学 Audio-WestlakeU）：级联 full-band spatial → narrow-band spatial → sub-band spectral → full-band spectral 四类模块；Mel-McNet 把多通道 STFT 压到 Mel 域，算力降 60%，输出 enhanced LogMel 直供 ASR/vocoder。
- [[方向/AI语音/模型/ARiSE|ARiSE]]（Interspeech 2025）：自回归逐帧利用已增强历史帧的空间-时序信息，在线多通道增强。
- [[方向/AI语音/模型/DeFTAN2|DeFTAN2]]：split dense blocks + subgroup cross-attention 的高效多通道增强。
- 与 ASR 联合：从"增强→识别"串行转向面向识别的目标函数（框架性综述见 Haeb-Umbach 等 arXiv:2501.07215）。

- **优势**：固定阵列下性能上限高、延迟可控、内容保持好；工程成熟。
- **短板**：强退化下听感天花板明显；IPD 类特征绑定固定几何，跨阵列泛化弱（由路线 2.6 解决）。

### 2.4. 路线四：生成式多通道（重点跟踪）

单通道扩散增强 2022 年后成熟，2025–2026 向多通道扩展，分三类形态：

| 子路线 | 代表 | 做法 | 定位 |
|---|---|---|---|
| 两段式 refiner | [[ArrayDPS-Refine]]、[[Uni-ArrayDPS]] | 判别式多通道前端先增强，扩散模型用 noisy mixture + 前端输出估噪声 SCM 写进 DPS 似然，精修残留噪声与非线性失真 | 狭义多通道 SE 主线；对阵列几何与前端松耦合 |
| 直接多通道扩散 | [[AMDM-SE]]、[[mSGMSE]] | 扩散框架内显式建模跨通道关系（AMDM-SE 用 cross-channel TF-attention 让非参考通道调制参考通道）；CHiME-3 上超单通道扩散基线与强判别式 DNN | 直接生成式探索，上限未明 |
| SS refiner / corrector 相邻线 | [[MeCo]]、[[ArrayDPS]] | 严格任务是分离：ArrayDPS 是扩散先验解阵列盲逆问题的源头，MeCo 用 1 NFE MeanFlow 一步校正判别式分离输出 | 借鉴逆问题建模与"一步生成式校正"范式 |

配套进展：[[方向/AI语音/知识/基础概念/Flow Matching（流匹配）|Flow Matching]] 成为扩散的高效替代——[[方向/AI语音/模型/FlowSE|FlowSE]]（10–20 步 ODE 达扩散相当质量）、[[方向/AI语音/模型/Stream.FM|Stream.FM]]（32 ms 流式）、AAAI 2026 把 FM/score/Schrödinger bridge 统一为高斯概率路径框架。详见 [[方向/AI语音/知识/生成式语音增强/DiT 与语音增强（DiT-based Speech Enhancement）|DiT 与语音增强]]、[[方向/AI语音/知识/生成式语音增强/扩散模型与语音|扩散模型与语音]]。

核心矛盾是**幻觉**：低 SNR 下生成模型会"编造"语音内容，对 ASR 与助听有害；URGENT 2025 预测式仍占优（见 3.2）。

### 2.5. 路线五：增强的语言模型化（表示级融合）

把增强从信号处理改写为 token/latent 映射，目标是前端与语音大模型共享表示空间、"增强—理解一体化"。按融合深度分三级：

| 融合层级 | 做法 | 代表 | 判断 |
|---|---|---|---|
| 波形级（级联） | 增强输出干净波形 + metadata，后端独立 | [[方向/AI语音/知识/基础概念/Array Audio Signal（阵列音频信号）]] 方案 A/B | 当前工程主流；前后端表示不通、误差不可回传 |
| 特征级 | 增强直接输出后端可消费的特征或联合训练 | [[Mel-McNet]] 输出 enhanced LogMel；三星 Whisper-Fest | 已验证有效，但表示按后端任务定制 |
| 表示级 | 增强即"噪声 token → 干净 token"映射 | [[SELM]]、[[GenSE]]、[[UniSE（Unified Speech Enhancement）]]、[[SenSE]]、[[UniPASE]]、[[L3-SE]] | 研究热点；codec 锁上限与幻觉是核心矛盾 |

阵列特有开放问题：IPD/ILD/DOA/SCM 在 token 化或 LogMel 压缩后基本丢失，空间规范表示（Ambisonics、eigenbeam、显式坐标）能否成为 SpeechLM 可消费的 token/latent，公开实证基本空白。深层分析见 [[方向/AI语音/知识/技术路线/LLM 与 Agent 对语音增强的影响|LLM 与 Agent 对语音增强的影响]]。

### 2.6. 路线六：阵列泛化与形态扩展

IPD 特征绑定固定几何，泛化问题需按几何信息可用性拆成三类；此外还有观测形态从固定阵列扩展到动态设备集合的分布式路线：

- **未知/弱几何（array-agnostic）**：[[方向/AI语音/模型/AmbiDrop|AmbiDrop]]（Ambisonics 域编码 + 通道 dropout，ICASSP 2026）、[[方向/AI语音/模型/MSEN（特征束多阶编码器）|MSEN]]（空间滤波器组投影到圆谐波规范空间）、[[方向/AI语音/模型/HyBeam|HyBeam]]（低频原始信号 + 高频波束输出的穿戴混合方案）。
- **已知坐标条件化（array-invariant）**：[[方向/AI语音/模型/Geo-DConv|Geo-DConv]]（上海交大，坐标 Transformer 生成动态卷积权重，对麦克风排列置换等变，真实 32 通道 RealMAN 上验证）。
- **固定已知几何少麦**：[[方向/AI语音/模型/Spatial-Magnifier|Spatial-Magnifier]]（Meta，从少麦估计虚拟麦克风信号/特征，逼近全阵列 oracle），直指消费级少麦设备。
- **分布式/异步/柔性阵列**：[[方向/AI语音/模型/SAMbA|SAMbA]]（奠基）、[[方向/AI语音/模型/CaSNet|CaSNet]]（SVD 压缩传输）、[[方向/AI语音/模型/FlexIO|FlexIO]]（单模型兼容 1–5 麦 × 1–3 说话人），面向"手机+耳机+笔记本"多设备协同。

### 2.7. 路线七：数据路线（横切所有方法）

仿真配对数据与真实录音的失配是所有路线的共同瓶颈，三条缓解路径：

- **弱监督**：[[方向/AI语音/模型/Mixture to Beamformed Mixture（波束形成混合弱监督）|Mixture to Beamformed Mixture]]（Z.-Q. Wang 等 2025）用 beamformed mixture 作真实录音的弱标签训练 DNN。
- **无监督**：[[方向/AI语音/模型/USDnet++|USDnet++]] 无监督去混响；ArrayDPS 用扩散先验做无监督盲分离。
- **真实数据与数据筛选**：[[方向/AI语音/数据集/RealMAN|RealMAN]] 83.7h 真实 32 通道；URGENT 2026 的关键胜负手是数据筛选（基线把 2500h 用 MOS 精选到 700h，[[方向/AI语音/论文/Less is More（语音增强数据筛选）|Less is More]]），URGENT 2025 也显示 60k 小时 Track 2 未超精选 2.5k 小时 Track 1——**数据质量 > 数据规模**。

## 3. 方案对比分析

### 3.1. 技术路线横向对比

| 路线 | 代表方案 | 核心优势 | 核心短板 | 适用场景 | 成熟度 |
|---|---|---|---|---|---|
| 经典阵列处理 | DAS、MVDR、GSC、WPE | 零训练、可解释、极低延迟、内容零改写 | 非平稳噪声/强混响上限低，音乐噪声 | 硬实时前端、baseline、物理约束 | 完全成熟 |
| 传统-神经混合 | [[CUSIDE-array]]、[[WNG-MVDR]]、[[Direction-Preserving MIMO]] | 可解释 + 非平稳噪声处理能力，低失真、低延迟 | 残余噪声靠后滤波，音质非顶尖 | 挑战赛前端、工业实时链路、空间保真输出 | 工业主流 |
| 端到端判别式 | [[TF-GridNet]]、[[McNet]]、[[ARiSE]] | 固定阵列上限高，内容保持好，流式可行 | 强退化听感发闷，几何绑定 | 固定阵列在线增强、ASR 前端 | 成熟 |
| 生成式多通道 | [[ArrayDPS-Refine]]、[[AMDM-SE]]、[[MeCo]] | 强退化下音质碾压，可修非线性失真 | 幻觉风险、采样成本高、流式难 | 离线高质量、两段式精修 | 快速演进 |
| LM 化增强 | [[UniSE（Unified Speech Enhancement）]]、[[SenSE]]、[[UniPASE]] | 与语音大模型表示互通，多任务统一 | codec/tokenizer 锁音质上限，自回归慢 | 增强-理解一体化预研 | 研究探索 |
| 阵列泛化 | [[AmbiDrop]]、[[Geo-DConv]]、[[Spatial-Magnifier]] | 跨几何/少麦/穿戴可用 | 口径分裂，实证仍少 | 穿戴、消费终端、多设备 | 早期 |

### 3.2. 性能证据：指标分裂是最大特征

**URGENT（当前事实主榜单，质量终点）**：

- URGENT 2025：纯判别式 T1 综合第一；纯生成式 T13 的 DNSMOS/NISQA/UTMOS/主观 MOS 3.69 **全部第一**，但 PESQ 1.34、ESTOI 0.54、SDR −12.28、SpkSim 0.47——"好听但幻觉"的极端样本。
- URGENT 2026：冠军 [[方向/AI语音/模型/GAP-URGENet|GAP-URGENet]]（南京大学声学所）是**生成-预测融合系统**（[[方向/AI语音/模型/UniPASE|UniPASE]] 生成分支 + TF-GridNet 预测分支 + PostNet 融合），PESQ 2.89 / ESTOI 0.90 / DNSMOS 3.31 兼得；纯生成式单体 NISQA 最高（4.18）但侵入式指标追不上融合系统。

**经典基准（方法对比锚点）**：[[方向/AI语音/数据集/VoiceBank-DEMAND|VoiceBank-DEMAND]] 上 PESQ 从未增强 ~1.97 → Wiener 2.22 → Conv-TasNet 2.53 → 2023–24 判别式 SOTA 3.33–3.50；域外泛化（VB-DemandEx）成为新区分点。离线质量上限由 DiTSE 定义（DAPS 集 QMOS 4.34，与录音室干净音频不可区分，但 8×A100 训练、32 步采样）。

**CHiME（WER 终点，读榜需换口径）**：CHiME-7/8 DASR 优胜套路固定（EEND-VC + TS-VAD 日志 → [[方向/AI语音/知识/基础概念/GSS（引导源分离）|GSS]] 多通道增强 → 多 ASR 组合 + LM 重打分），阵列增强在这里只是降 WER 的前端手段，**不能把 ASR 榜收益误当 SE 质量证据**。

**基准演进脉络**：VoiceBank-DEMAND 已饱和 → [[方向/AI语音/评估/DNS Challenge（深度噪声抑制挑战）|DNS Challenge]] 2023 年第五届后停办 → URGENT 成为质量终点主战场；CHiME-10（2026-07 公布）把 URGENT 与 ECHI-2、SG-TSE 并列为三大任务——质量、识别、低延迟助听三类终点正在同一赛事框架内合流，读榜先拆终点因此更加重要。

### 3.3. 工程维度对比

| 系统 | 定位 | 延迟 / 成本 |
|---|---|---|
| RNNoise / GTCRN | 轻量实时单通道 | 几十 K / 48.2K 参数 |
| DeepFilterNet3 / DeepFilterGAN | 实时全频带判别式 | 48 kHz 全带实时；40 ms 延迟、3.45M 参数 |
| [[Mel-McNet]] | 在线多通道 | 较 McNet 算力 −60%（Mel 域压缩） |
| [[Direction-Preserving MIMO]] | 混合式 MIMO 输出 | 参数量/算力约 mask-based NICE 的 1/3 |
| [[Stream.FM]] | 流式生成式 | 32 ms 算法延迟，消费级 GPU |
| DiTSE | 离线质量上限 | 8×A100 训练，32 步采样 |
| [[GAP-URGENet]] | 离线综合冠军 | 567.8M 参数 |

实时与离线已明显分叉：通话要求 <50 ms 总延迟，生成式要进实时链路必须走"少步采样（FM）+ 一步校正（MeCo 式）+ 判别兜底"路线；ECHI 助听挑战的 20 ms 硬约束是当前生成式无法直接满足的边界。

### 3.4. 评估口径：五个维度缺一不可

阵列增强不能只看单通道听感，生成式路线尤其要同时卡住内容、空间和系统成本：

| 评估面 | 要回答的问题 | 推荐指标 / 检查 |
|---|---|---|
| 语音质量 | 是否更干净、更自然 | PESQ、DNSMOS、UTMOS、NISQA；主观 MUSHRA / P.808 / P.835（金标准） |
| 内容保真 | 是否改词、漏词、脑补 | WER / CER、CAcc、数字/专名分桶 |
| 空间保真 | 是否保住相位、方向、双耳线索 | ITD/ILD 误差、IACC、DOA 偏差、spatial MOS |
| 系统成本 | 能否进实时链路 | RTF、算法延迟、lookahead、NFE、显存/GMAC |
| 真实鲁棒 | 是否过拟合仿真/固定阵列 | seen/unseen geometry、坏麦、SRO/STO、风噪、AEC 残留 |

详见 [[方向/AI语音/评估/语音增强评估指标体系|语音增强评估指标体系]]；读任何榜单前先拆终点：URGENT 偏质量、CHiME 偏 WER/diarization、[[方向/AI语音/评估/NOTSOFAR-1（远场会议转写挑战）|NOTSOFAR-1]] 是远场会议转写 benchmark。

## 4. 工业界落地格局

详见 [[方向/AI语音/知识/调研与地图/Array Speech Enhancement Industry（阵列语音增强工业界方案）|工业界方案]]，要点：

- **共同范式**：传统 AEC/波束成形管线被"阵列前端 + 深度学习降噪/去混响"混合架构包裹和参数化；**个性化语音分离取代传统降噪成为旗舰特性**（Microsoft Teams Voice Isolation：声纹注册 + 只保留本人声音）；整条管线收敛到单芯片/单设备。
- **芯片/DSP**：XMOS（XVF 系列边缘 AI 芯片，2026 展示 GenSoC 生成式音频 DSP）、高通 S3/S5 Gen 3（片上 AI 增强多麦回声消除）、Knowles、Synaptics、CEVA、Infineon。
- **消费终端**：Apple 最激进（AirPods Pro 获 FDA OTC 助听器授权，Voice Isolation）；Google Clear Calling；华为 FreeBuds Pro 5 MIMO AI 感知降噪；三麦 AI 通话降噪已下沉到 269 元档。
- **会议设备**：Shure MXA920/925 天花阵列标杆；华为 IdeaHub 24 麦阵列、15 米拾音；讯飞会议宝与转写/翻译深度绑定；思必驰 MCS06 64 单元阵列切入专业扩声。
- **新兴方向**：OTC 助听器/TWS 融合（CES 2026 集中爆发）、车载从舱内四/六音区扩展到舱外拾音、"拾音 + 实时转写 + AI 摘要"打包（Plaud、讯飞 viaim）。

工业界对学界的启示：麦克风数量军备竞赛（4 → 24/64 单元）说明**阵列侧算力与传感不是瓶颈，差异化全部在算法与数据**；端侧 NPU 普及为路线 2.3/2.6 的落地提供硬件底座。

## 5. 关键挑战与开放问题

1. **阵列泛化边界**：未知几何（AmbiDrop）、已知坐标条件化（Geo-DConv）、固定几何少麦上采样（Spatial-Magnifier）是三类不同问题，不能混为一个 array-agnostic 口径；跨设备迁移仍是榜单收益落不到设备的主要原因。
2. **真实场景泛化（sim-to-real）**：仿真 RIR + 加性噪声的训练分布盖不住真实风噪、触碰噪、SRO/STO、坏麦；弱监督（beamformed mixture）、无监督（USDnet++）、真实数据（RealMAN）三条路径都未闭环。
3. **生成式幻觉与内容保持**：低 SNR 下生成模型编造内容；幻觉控制现有三抓手——WavLM 音系先验蒸馏（UniPASE）、显式语义 token（SenSE）、判别分支兜底（混合式），但没有统一度量（CAcc/CER/SpkSim 哪个最敏感未定）。
4. **实时与成本**：生成式质量 + 预测式速度的融合尚不成熟；延迟硬约束场景（助听 20 ms、通话 50 ms）仍是判别式/混合式独占。
5. **AEC / 全双工链路**：有播放参考、barge-in 或模型自听时，AEC 与增强、VAD、beamforming 的责任边界和延迟预算要一起设计，不能把回声泄漏交给后端大模型兜底。
6. **空间信息如何进大模型表示**：IPD/ILD/SCM 在 token 化后基本丢失；"空间规范表示 → SpeechLM token/latent"公开实证空白，是阵列增强与语音大模型融合的交叉口。

## 6. 调研结论

1. **混合式是当前综合最优范式，且有两层含义**：传统-神经混合（2.2）统治实时与工业链路；判别-生成混合（2.4 两段式、GAP-URGENet）统治质量榜。纯经典、纯端到端、纯生成各有不可替代的边界场景，但都不再是综合最优。
2. **神经波束形成仍是阵列增强的工业底座**：可解释、低失真、低延迟、空间保真；2026 年的可学习协方差/WNG 约束方向说明这条线仍在进化，且是生成式路线必须击败或继承的物理约束。
3. **指标分裂是选型第一约束**：听感指标与内容保持不再同向。面向人耳（助听、会议外放）可向生成式倾斜；面向机器（ASR、转写）与法律/医疗等不容改写的场景，判别式或判别兜底混合是唯一安全选择。
4. **生成式多通道化是学界未来两年的主战场**：两段式 refiner（ArrayDPS-Refine/Uni-ArrayDPS）工程上更稳，直接多通道扩散（AMDM-SE/mSGMSE）上限未明，Flow Matching 与一步校正（MeCo 式 1 NFE）正在解决采样成本。
5. **"固定阵列 + 多通道生成式端到端 + 质量终点"是空位**：现有工作要么面向 ASR（CHiME 口径），要么是单通道 LM 化（UniSE/SenSE/L3-SE），固定几何下让模型吃全原始多通道信号、以 URGENT 式质量指标为终点的标杆工作尚不存在——风险与机会并存。
6. **数据质量 > 数据规模**：URGENT 连续两年验证（60k 小时不敌精选 2.5k 小时；[[方向/AI语音/论文/Less is More（语音增强数据筛选）|Less is More]] 700h）；阵列侧的真实数据（RealMAN 级）与弱监督闭环是比新架构更稀缺的资产。
7. **实时与离线已分叉为两个市场**：离线看 DiTSE/GAP-URGENet 级质量；实时看 DeepFilterNet3/DeepFilterGAN（≤40 ms）与流式方案（CUSIDE-array、ARiSE、Stream.FM）；两条线的技术栈正在分化，选型时先定延迟预算再定路线。
8. **增强与语音大模型的表示级融合是长期方向**：当前工程主流仍是波形级级联；特征级（Mel-McNet → ASR）已验证；表示级（token 共享）受 codec 上限与幻觉制约，阵列空间信息进 token 是公开空白。
9. **读榜先拆终点**：URGENT = 质量，CHiME/NOTSOFAR = WER/diarization，ECHI = 低延迟助听；把 ASR 榜收益当 SE 质量证据是最常见的调研误判。

## 7. 选型建议（按场景）

| 场景 | 推荐路线 | 理由 / 风险 |
|---|---|---|
| 实时通话 / 语音 Agent 前端 | 混合式：[[CUSIDE-array]] / [[WNG-MVDR]] + 轻量判别后滤波（DeepFilterNet3 级）；有播放参考先 AEC | 延迟 <50 ms 硬约束；生成式暂不兜底回声 |
| 会议转写前端（ASR 终点） | GSS / 神经 MVDR + [[TF-GridNet]] 类判别式，特征级输出（[[Mel-McNet]] LogMel） | WER 终点优先内容保持；生成式听感收益不转化为 WER |
| 离线高质量修复 / 质量终点 | 判别-生成混合：判别前端 + 生成精修（[[ArrayDPS-Refine]] 两段式），或 GAP-URGENet 式融合 | 质量上限最高；需配 CAcc/CER 幻觉监控 |
| 固定阵列预研（大模型方向） | 按 [[Array SE Roadmap（阵列语音增强技术路线优先级）]]：P0 生成式多通道、P1 阵列泛化、P2 真实数据闭环 | 空位赛道；先建 URGENT 口径评估与真实数据闭环 |
| 穿戴 / 未知几何设备 | array-agnostic：[[AmbiDrop]] / [[HyBeam]] / [[Geo-DConv]] 按几何信息可用性选型 | 口径先拆清；实证仍少，需自测 |
| 端侧低算力 | Mel 域压缩（[[Mel-McNet]] 思路）、超低算力复数掩码、RNNoise/GTCRN 级小模型 | 单通道已成熟，多通道端侧以因果神经波束成形为主 |

**开源与可复现性**（选型时的落地起点，也是本库团队可信度判据之一）：DeepFilterNet、RNNoise、GTCRN（单通道实时）、McNet/Mel-McNet（在线多通道）、FlowSE、MeCo（生成式）、GAP-URGENet（URGENT 2026 冠军系统）均有公开代码；经典路线可用 pyroomacoustics 的 beamforming 实现快速搭可解释 baseline。

## 8. 参考与延伸阅读

**本库深入阅读路径**：[[方向/AI语音/知识/基础概念/SE（语音增强）导论|SE 导论]]（概念地图）→ [[方向/AI语音/知识/调研与地图/Array Speech Enhancement Frontier（阵列语音增强前沿调研）|前沿调研]]（2024–2026 学界全景与逐方案考证）→ [[方向/AI语音/知识/调研与地图/Array Speech Enhancement Team Map（阵列增强团队地图）|团队地图]]（可信度索引）→ [[方向/AI语音/知识/调研与地图/SE SOTA（语音增强模型表现）|SE SOTA]]（榜单细节）→ [[方向/AI语音/知识/技术路线/Array SE Roadmap（阵列语音增强技术路线优先级）|Array SE Roadmap]]（P0–P6 预研优先级）→ [[方向/AI语音/知识/调研与地图/Array Speech Enhancement Industry（阵列语音增强工业界方案）|工业界方案]]。

**关键外部来源**（核验日期见各笔记）：

- 麦克风阵列处理综述：[Advances in Microphone Array Processing and Multichannel Speech Enhancement](https://arxiv.org/abs/2502.09037)
- 混合式：[WNG-MVDR](https://arxiv.org/abs/2606.24137)、[Direction-Preserving MIMO](https://arxiv.org/abs/2604.11179)、[CUSIDE-array](https://arxiv.org/abs/2407.09807)
- 端到端判别式：[McNet](https://arxiv.org/abs/2211.08872)、[Mel-McNet](https://arxiv.org/abs/2505.19576)
- 生成式多通道：[ArrayDPS-Refine](https://arxiv.org/abs/2603.24385)、[Uni-ArrayDPS](https://arxiv.org/abs/2603.24810)、[AMDM-SE](https://arxiv.org/abs/2601.13140)、[FlowSE](https://arxiv.org/abs/2505.19476)
- 质量终点综合冠军：[GAP-URGENet](https://arxiv.org/abs/2604.01832)（[代码](https://github.com/Xiaobin-Rong/gap-urgenet)）、[UniPASE](https://arxiv.org/abs/2604.14606)
- 弱监督与泛化：[Mixture to Beamformed Mixture](https://arxiv.org/abs/2507.15229)、[Geo-DConv](https://arxiv.org/abs/2607.18658)、[HyBeam](https://arxiv.org/abs/2510.22637)

## 9. 待深挖

- 本报告与 [[方向/AI语音/知识/调研与地图/Array Speech Enhancement Frontier（阵列语音增强前沿调研）|前沿调研]] 的分工：本报告是定稿式综合（季度级刷新），前沿调研是滚动更新的工作页；维护时以工作页为准向前同步。
- 阵列泛化文献横评已整理为 [[方向/AI语音/知识/调研与地图/Array-Agnostic SE SOTA（阵列可变语音增强SOTA调研）|Array-Agnostic SE SOTA]]（2026-10-27）：按 SE、SS/CSS、TSE、Ambisonics 编码与无监督 BSS 分协议给候选和证据边界；它是作者报告结果的文献横评，**不是同条件复现横评**。MSEN 尚缺全文定量证据，少麦补全另见 Spatial-Magnifier；统一实测后再回灌本报告 3.1 节。
- 生成式幻觉统一度量（CAcc/CER/SpkSim 敏感性对比）有结论后更新 5.3 与 7。

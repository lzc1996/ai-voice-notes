---
title: Array Speech Enhancement Frontier（阵列语音增强前沿调研）
类型: 综述
调研时间: 2026-08-04
相关任务:
  - 语音增强
  - 多通道增强
相关模型:
  - "[[方向/AI语音/模型/TF-GridNet]]"
  - "[[方向/AI语音/模型/McNet]]"
  - "[[方向/AI语音/模型/Mel-McNet]]"
  - "[[方向/AI语音/模型/AMDM-SE]]"
  - "[[方向/AI语音/模型/SGMSE+]]"
  - "[[方向/AI语音/模型/ArrayDPS-Refine]]"
  - "[[方向/AI语音/模型/Uni-ArrayDPS]]"
  - "[[方向/AI语音/模型/SenSE]]"
  - "[[方向/AI语音/模型/UniSE（Unified Speech Enhancement）]]"
  - "[[方向/AI语音/模型/USDnet++]]"
  - "[[方向/AI语音/模型/HyBeam]]"
  - "[[方向/AI语音/模型/PGUSE]]"
相关团队:
  - "[[方向/AI语音/团队/UIUC SiNRG（UIUC 信号推断研究组）]]"
  - "[[方向/AI语音/团队/Z.-Q. Wang Group（Zhong-Qiu Wang 组）]]"
相关评估:
  - "[[方向/AI语音/评估/DNS Challenge（深度噪声抑制挑战）]]"
  - "[[方向/AI语音/评估/CHiME（语音分离与识别挑战赛）]]"
  - "[[方向/AI语音/评估/NOTSOFAR-1（远场会议转写挑战）]]"
aliases:
  - 阵列语音增强前沿调研（Array Speech Enhancement Frontier）
  - Array Speech Enhancement Frontier
  - 阵列语音增强前沿调研
  - array speech enhancement frontier
tags:
  - 类型/知识
  - 方向/AI语音
  - 任务/语音增强
  - 任务/多通道增强
---

# Array Speech Enhancement Frontier（阵列语音增强前沿调研）

2026-08 对麦克风阵列语音增强学界最新方案（2024–2026）的调研汇总，两次补查（2026-08-04、2026-08-06）已并入对应主题节；2026-08-06 重组：工业界方案拆至 [[方向/AI语音/知识/调研与地图/Array Speech Enhancement Industry（阵列语音增强工业界方案）|阵列语音增强工业界方案]]，"多通道 ≠ 阵列"术语辨析拆至 [[方向/AI语音/知识/基础概念/Array vs Multi-Channel（阵列与多通道）|Array vs Multi-Channel]]；2026-08-20：增强与语音大模型的表示级融合由散落条目整合为独立一节（第八节）。

相关笔记：[[方向/AI语音/知识/调研与地图/Array Speech Enhancement Team Map（阵列增强团队地图）|阵列增强团队地图]]（可信度较高的团队索引）、[[方向/AI语音/知识/技术路线/Array SE Roadmap（阵列语音增强技术路线优先级）|阵列语音增强技术路线优先级]]（P0-P6 路线入口）、[[方向/AI语音/知识/基础概念/Array Audio Signal（阵列音频信号）|阵列音频信号]]（阵列前端与音频大模型后端分工）、[[方向/AI语音/评估/URGENT（通用语音增强挑战）|URGENT]]、[[方向/AI语音/评估/DNS Challenge（深度噪声抑制挑战）|DNS Challenge]]、[[方向/AI语音/知识/生成式语音增强/DiT 与语音增强（DiT-based Speech Enhancement）|DiT 与语音增强]]、[[方向/AI语音/知识/生成式语音增强/扩散模型与语音|扩散模型与语音]]。

## 1. 总体判断

- 学界重心从"新架构竞赛"转向**生成式建模、空间泛化**（array-agnostic、显式几何、少麦上采样）、真实数据和**系统接口**（AEC / full-duplex / 低延迟）；效率仍是重要工程约束，但当前内部预研不按短期落地排序。
- 工业界阵列硬件已商品化，差异化全部转移到**端侧深度学习**——DNN 降噪/去混响、个性化语音分离——并与转写、摘要、助听等上层 AI 应用打包（详见[[方向/AI语音/知识/调研与地图/Array Speech Enhancement Industry（阵列语音增强工业界方案）|工业界方案]]）。
- 未来两年最值得跟踪：狭义多通道生成式增强（判别前端 + 生成精修两段式，以及 AMDM-SE / mSGMSE 这类直接多通道扩散）、SS / TSE 相邻任务里的生成式校正器迁移、增强与语音大模型的表示级融合（见"八、增强与语音大模型的表示级融合"）。
- 路线拆分与优先级已经单列在 [[方向/AI语音/知识/技术路线/Array SE Roadmap（阵列语音增强技术路线优先级）|阵列语音增强技术路线优先级]]；当前按大模型预研价值排序：P0 生成式多通道，P1 阵列泛化 / 任意几何 / 少麦，P2 真实数据 / 弱监督 / 无监督，P3 空间引导 / 多模态，P4 分布式 / 异步 / 柔性阵列，P5 传统-神经混合，P6 端侧 / 流式 / 高效化。
- 2026 上半年挑战赛风向：从"单模型刷指标"转向"系统工程（数据筛选、级联、LLM 后处理）+ 严格延迟/穿戴约束 + 主观评测"。

### 1.1. 方案定位速查

本页是阵列增强前沿调研，但并非每个条目都严格做 SE。维护时先按“严格任务”归类，再说明为什么在本页跟踪。

| 方案 / 家族                                                                                                                  | 严格任务口径                                   | 输入输出 / 实际动作                                    | 为什么在本页                      |
| ------------------------------------------------------------------------------------------------------------------------ | ---------------------------------------- | ---------------------------------------------- | --------------------------- |
| CUSIDE-array / MVDR / GSS / [[方向/AI语音/模型/WNG-MVDR]]                                                                      | 多通道 SE / 空间滤波                            | 估计 mask、协方差或 WNG 约束，再做 beamforming             | 低延迟阵列增强底座                   |
| [[方向/AI语音/模型/Direction-Preserving MIMO]]                                                                                 | 多通道 SE                                   | 输出多通道增强结果，保留目标和残余噪声方向线索                        | 空间保真路线代表                    |
| [[方向/AI语音/模型/McNet]] / [[方向/AI语音/模型/Mel-McNet]] / [[方向/AI语音/模型/ARiSE]]                                                   | 多通道 SE                                   | 端到端或在线判别式增强；Mel-McNet 输出 LogMel，ARiSE 用历史增强帧   | 固定阵列直接候选                    |
| [[方向/AI语音/模型/TF-GridNet]] / [[方向/AI语音/模型/SpatialNet]] / [[方向/AI语音/模型/CrossNet]] / DeFTAN2                      | SS 起家，也常作 SE backbone                    | 强判别式前端或预测分支，不是单一任务定义                           | 多数 refiner 的前端依赖            |
| [[方向/AI语音/模型/Mixture to Beamformed Mixture（波束形成混合弱监督）]]                                                                  | 弱监督数据构造                                  | 用 beamformed mixture 作为真实录音弱标签训练 DNN           | 解决仿真到真实失配                   |
| [[方向/AI语音/模型/USDnet++]]                                                                                                  | 去混响 / 无监督 SE 相邻                          | 无监督方式处理混响退化                                    | 真实数据和无监督路线参考                |
| [[方向/AI语音/模型/ArrayDPS]]                                                                                                  | 无监督盲 SS                                  | 未知阵列几何、未知 RIR、未知声源下恢复多个说话人                     | 不是 SE；作为扩散逆问题源头             |
| [[方向/AI语音/模型/ArrayDPS-Refine]]                                                                                           | 多通道 SE refiner                           | 接在判别式增强模型之后，修残留噪声和非线性失真                        | 狭义 SE 两段式主线                 |
| [[方向/AI语音/模型/Uni-ArrayDPS]]                                                                                              | 多通道 SE + SS refiner                      | 把 refinement 统一到 enhancement 和 separation      | 跨任务精修接口参考                   |
| [[方向/AI语音/模型/MeCo]]                                                                                                      | 多通道 SS corrector                         | 接在判别式分离器之后，1 NFE MeanFlow 校正分离结果               | 不是 SE；只借鉴一步 corrector 范式    |
| [[方向/AI语音/模型/AMDM-SE]] / [[方向/AI语音/模型/mSGMSE]]                                                                           | 多通道 SE                                   | 直接多通道扩散增强，显式建模跨通道关系                            | 直接生成式多通道增强探索                |
| [[方向/AI语音/模型/FlowSE]] / [[方向/AI语音/模型/DiT-Flow]] / Stream.FM                                                              | 单通道 SE                                   | 用 Flow Matching / DiT 做少步或流式生成式增强              | 多通道 LM / flow 方案的方法来源       |
| [[方向/AI语音/模型/SELM]] / [[方向/AI语音/模型/GenSE]] / [[方向/AI语音/模型/UniSE（Unified Speech Enhancement）]]                            | token / codec LM 式 SE，UniSE 覆盖 SR/TSE/SS | 把受损语音映射到干净 speech token 或统一任务输出                | 增强与 SpeechLM 表示融合来源         |
| [[方向/AI语音/模型/UniPASE]] / [[方向/AI语音/模型/SenSE]] / [[方向/AI语音/模型/L3-SE]]                                                     | universal SE                             | 用 WavLM、语义 token、LM 或 flow 降低幻觉                | 低幻觉生成式增强参考                  |
| [[方向/AI语音/模型/PGUSE]] / [[方向/AI语音/模型/GAP-URGENet]]                                                                        | universal SE 模型 / 系统                     | 预测分支 + 生成分支融合，面向 URGENT 多失真                    | 融合范式和指标分裂证据                 |
| [[AmbiDrop]] / Geo-DConv / MSEN / [[方向/AI语音/模型/HyBeam]]                                                        | 阵列泛化 / array-invariant / wearable SE     | 处理未知几何、显式坐标条件化、穿戴阵列或规范空间表示                     | 不属固定阵列主线，但决定泛化边界            |
| [[方向/AI语音/模型/Spatial-Magnifier]]                                                                                         | 固定已知几何的少麦 SE / 虚拟麦克风                     | 从少量真实麦估计虚拟麦克风信号或特征，增强固定几何下的空间采样                | 不是 array-agnostic；作为少麦产品化对照 |
| SAMbA / CaSNet / FlexIO                                                                                                  | 分布式 / 柔性阵列                               | 处理多设备异步、带宽压缩、输入输出数变化                           | 产品形态扩展路线                    |
| DOA-guided extraction / PATSE / SG-TSE                                                                                   | TSE / diarization-adjacent extraction    | 用方向或多模态线索抽取目标说话人                               | 和增强共享阵列前端，但任务不是纯 SE         |
| [[方向/AI语音/知识/基础概念/Audio Leakage（漏音）]] / AEC / [[方向/AI语音/知识/基础概念/Full-Duplex（全双工）]]                                       | 全双工通信前端 / 系统约束                           | 有播放参考时先做回声消除，配合 VAD、barge-in、beamforming 与后滤波  | 语音 Agent、会议设备和助听链路的硬边界      |
| [[方向/AI语音/评估/CHiME（语音分离与识别挑战赛）]] / [[方向/AI语音/评估/NOTSOFAR-1（远场会议转写挑战）]] / MCoRec / ECHI / [[方向/AI语音/评估/URGENT（通用语音增强挑战）]] | Benchmark / challenge                    | CHiME 系常以 WER、diarization 或助听终点计分；URGENT 偏语音质量 | 读榜时先拆终点，避免把 ASR 前端收益当 SE 质量 |

### 1.2. 评估矩阵

阵列增强不能只看单通道听感；生成式路线尤其要同时卡住内容、空间和系统成本。

| 评估面 | 要回答的问题 | 推荐指标 / 检查 | 防止的误判 |
| --- | --- | --- | --- |
| 语音质量 | 是否更干净、更自然 | PESQ、DNSMOS、UTMOS、NISQA、MUSHRA | 只刷客观分但听感差 |
| 内容保真 | 是否改词、漏词或脑补弱语音 | [[方向/AI语音/评估/WER（词错误率）]]、[[方向/AI语音/评估/CER（Character Error Rate）]]、[[方向/AI语音/评估/CAcc]]、数字 / 专名分桶 | 生成式幻觉被听感掩盖 |
| 空间保真 | 是否保住多通道相位、方向和双耳线索 | ITD / ILD 误差、IACC、DOA 偏差、binaural / spatial MOS | 每路单听好但空间关系坏掉 |
| 系统成本 | 能否进入实时链路 | RTF、算法延迟、lookahead、[[方向/AI语音/评估/NFE（函数评估次数）]]、显存 / GMAC | 离线好听但无法通话或端侧运行 |
| 真实鲁棒 | 是否过拟合仿真或固定阵列 | seen / unseen geometry、坏麦、SRO / STO、风噪 / 触碰噪、AEC 残留 | 仿真榜单收益迁不到设备 |

### 1.3. 多通道方案如何引入阵列信息

| 方案                                           | 引入阵列信息的目的                                                               | 引入方式                                                                                                                          | 具体引用                                                                                                                                                                                                                                                    |
| -------------------------------------------- | ----------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| [[McNet]]                                    | 用空间信息 + 频谱信息区分语音和噪声。                                                    | 级联 full-band spatial、narrow-band spatial、sub-band spectral、full-band spectral 四类模块；空间模块使用多通道相位/通道关系（笔记公式写成 IPD 的 cos/sin 形式）。 | 原论文摘要明确说 spectral and spatial information are vital，并提出四模块级联分别利用 full-band spatial / narrow-band spatial / sub-band spectral / full-band spectral information：[arXiv:2211.08872](https://arxiv.org/abs/2211.08872)。                                     |
| [[Mel-McNet]]                                | 降低在线多通道增强算力，同时保持增强和 ASR 表现。                                             | STFT-to-Mel 模块把多通道 STFT 特征压缩为 Mel-frequency 表示，再用改造版 McNet 直接输出 enhanced LogMel。                                              | 原论文摘要说明它处理 spectral and spatial information，STFT-to-Mel compresses multi-channel STFT features，并可直连 vocoder / ASR：[arXiv:2505.19576](https://arxiv.org/abs/2505.19576)。                                                                                 |
| [[DeFTAN2]]                                  | 在多通道增强里降低 Transformer 计算和内存，并保留局部/跨子组关系。                                | 复数 STFT 通道堆叠；split dense blocks 提取 spatial features；subgroup cross-attention 建模局部强调特征与原始特征的关系。                                | 原论文摘要提到 efficient multichannel SE、subgroup processing、split dense blocks extracting spatial features、cross-attention between subgroups：[arXiv:2308.15777](https://arxiv.org/abs/2308.15777)。                                                            |
| [[SpatialNet]]                               | 充分从多通道复谱中学习空间信息，摆脱对 IPD / ILD 手工特征与显式波束形成的依赖。                          | 输入只逐 T-F bin 拼接各通道 STFT 实/虚部（$2M$ 维），**不显式计算 IPD / ILD**；narrow-band block 的 MHSA 沿时间轴承担"基于空间向量的说话人聚类"，cross-band block 的 full-band linear 学直达声 RTF 的全频相关性，两者交错 $L$ 层，空间信息由网络从复谱自学。 | 原论文题名即 extensively learning spatial information for multichannel joint separation / denoising / dereverberation；消融显示去掉 MHSA 后 SMS-WSJ-Plus SI-SDR 13.8→9.5 dB，空间聚类是主要贡献者：[arXiv:2307.16516](https://arxiv.org/abs/2307.16516)。                  |
| [[NICE-Beam]]                                | 解决穿戴/移动阵列中麦克风姿态变化导致的时变空间协方差估计问题。                                        | 神经网络模块跨时间跟踪场景信息，学习估计 time-varying spatial covariance matrices，并接入 beamforming pipeline。                                       | 原论文摘要直接把问题定义为 time-varying spatial covariance matrix estimation for wearable devices，并说明 NICE-Beam 学习估计该协方差：[arXiv:2112.04613](https://arxiv.org/abs/2112.04613)。                                                                                       |
| [[WNG-MVDR]]                                 | 在阵列失配/白噪声放大风险下，自适应权衡 MVDR 的指向性与鲁棒性。                                     | 双头网络估计噪声时频掩码与逐频点 WNG 阈值；噪声掩码估空间协方差，WNG 阈值进入可微鲁棒 MVDR 层。                                                                       | 原论文摘要与方法题名聚焦 covariance estimation + white noise gain for robust MVDR beamforming：[arXiv:2606.24137](https://arxiv.org/abs/2606.24137)。                                                                                                                 |
| [[Direction-Preserving MIMO]]                | 避免 MISO 单通道输出压塌空间方向信息，保留目标与残余噪声方向线索。                                    | OnlineSpatialNet 从多通道 STFT 估计尺度归一化噪声协方差 Cholesky 因子，再用 direction-preserving MIMO Wiener filter 输出多通道增强结果。                     | 原论文题名和摘要强调 direction-preserving MIMO SE + neural covariance estimator；方法页写明 OnlineSpatialNet / DP-MWF：[arXiv:2604.11179](https://arxiv.org/abs/2604.11179)。                                                                                             |
| [[Mixture to Beamformed Mixture（波束形成混合弱监督）]] | 用真实录音弱监督减少仿真训练和真实多通道混合之间的失配。                                            | 先用 beamforming 把真实多通道录音转成更高 SNR 的 beamformed mixture，再把它作为 sample-level weak supervision 训练 DNN。                              | 原论文摘要说明 beamforming improves target-speaker SNR，beamformed mixture is used as weak supervision，训练 real-recorded mixture / beamformed mixture 对：[arXiv:2507.15229](https://arxiv.org/abs/2507.15229)。                                                    |
| [[mSGMSE]]                                   | 保留多麦输出间的 ITD / ILD 等空间线索，避免逐通道独立生成破坏通道一致性。                              | 把单通道 SGMSE 推广为 MIMO 条件扩散，联合生成所有麦克风的干净信号；可配合 WPE 预去混响。                                                                         | 原论文为 IEEE ICASSPW/HSCMA 2024《Diffusion Model-Based MIMO Speech Denoising and Dereverberation》；摘要页可见题名与 DOI：[IEEE](https://ieeexplore.ieee.org/abstract/document/10626291)。                                                                              |
| [[Multi-Stream Diffusion]]                   | 未提及（论文目标是概率式集成 model-based 与 data-driven SE 部件，不是专门论证“为什么引入阵列信息”）。      | 间接引入：WPE、CSM、扩散增强等部件输出作为多路条件流；若上游部件是多通道 WPE/CSM，则阵列信息已被压缩到这些估计流中。                                                             | 原论文题名为 probabilistic integration of model-based and data-driven SE；本笔记中 REVERB 2 通道样例来自 NTT demo：[IEEE](https://ieeexplore.ieee.org/abstract/document/10694664)、[NTT demo](https://www.kecl.ntt.co.jp/icl/signal/nakatani/demos/iwaenc2024/demoE.html)。 |
| [[DiffCBF]]                                  | 用经典多通道信号处理补足纯扩散对混响/多源/噪声联合问题的约束。                                        | CBF 端用 MCLP 去混响 + beamforming 分离/降噪；扩散端用 CBF 输出作为额外条件流，并把扩散估计功率谱回馈给下一轮 CBF。                                                   | 原论文式 (1) 给出 convolutional beamformer，式 (4) 给出 inverse Gamma 先验；全文 PDF：[EUSIPCO 2025](https://eusipco2025.org/wp-content/uploads/pdfs/0000945.pdf)。                                                                                                      |
| [[AMDM-SE]]                                  | 在扩散语音增强中显式利用跨通道空间信息，改善 noise reduction。                                 | Cross-Channel TF-Attention：非参考通道调制参考通道时频表示，score network 以全部通道为条件。                                                            | 原论文摘要明确说 leverage spatial inter-channel information through a novel cross-channel time-frequency attention block：[arXiv:2601.13140](https://arxiv.org/abs/2601.13140)。                                                                                  |
| [[ArrayDPS]]                                 | 在阵列几何、RIR、声源均未知时做无监督盲分离。                                                | 采样过程中反复估计未知混响滤波-求和混合算子；用 FCP/相对 RIR 把虚拟源映射到真实麦克风，再做 DPS 似然引导。                                                                 | 原论文题名和摘要给出 unsupervised blind speech separation with a diffusion prior；具体 FCP/relative RIR 机制见论文方法：[arXiv:2505.05657](https://arxiv.org/abs/2505.05657)。                                                                                                |
| [[ArrayDPS-Refine]] / [[Uni-ArrayDPS]]       | 精修判别式多通道增强/分离模型的残留噪声与非线性失真，同时保持对阵列几何和前端 backbone 的松耦合。                  | 空间信息先由判别式多通道前端利用；refiner 用 noisy mixture 与判别式输出估噪声 SCM，再把 SCM 写进 DPS 似然。                                                      | 原论文分别为 generative refinement of discriminative multi-channel SE 与 unified refinement for multi-channel SE and separation：[ArrayDPS-Refine](https://arxiv.org/abs/2603.24385)、[Uni-ArrayDPS](https://arxiv.org/abs/2603.24810)。                          |
| [[MeCo]]                                     | 严格任务是多通道语音分离；论文不把阵列增强或阵列信息本身作为独立目标。 | 多通道信息作为条件输入进入 corrector：条件包含原始多通道混合 $y$ 与判别式分离器估计 $\hat{s}$；未显式建模几何、DOA、IPD 或 SCM。                                            | 原论文摘要和题名聚焦 one-step MeanFlow-based corrector for multi-channel speech separation；本页只借鉴其 1 NFE 生成式校正范式：[arXiv:2606.09677](https://arxiv.org/abs/2606.09677)。                                                                                                                  |
| [[HyBeam]]                                   | 跨穿戴阵列几何泛化，并兼顾低频/高频不同空间线索可靠性。                                            | 低频使用 raw microphone signals，高频使用 beamformer outputs，形成 hybrid microphone-beamforming array-agnostic 增强。                       | 原论文题名和摘要即为 Hybrid Microphone-Beamforming Array-Agnostic SE for Wearables；笔记实验中 bandwise analysis 支持低频 mic / 高频 beamformer 分工：[arXiv:2510.22637](https://arxiv.org/abs/2510.22637)。                                                                      |
| [[USDnet++]]                                 | 未提及（截至本笔记核验时只见作者主页题名，未见 USDnet++ 论文全文）。                                 | 未提及；只能从前作 USDnet 推断其可能沿用多麦 forward filtering / 信号处理去混响先验，但不写成 USDnet++ 已证实机制。                                                 | 作者主页列题名；前作 USDnet 摘要只支持“无监督 neural forward filtering”背景，不替代 USDnet++ 论文：[Z.-Q. Wang homepage](https://zqwang7.github.io/)、[USDnet](https://arxiv.org/abs/2402.00820)。                                                                                   |
| [[方向/AI语音/模型/VM-UNSSOR]]                    | 无监督（无干净标签）训练下强化 mixture-consistency 约束；麦克风少时该约束变弱、分离崩掉。                     | 对观测混合跑 IVA / 空间聚类得解混矩阵，回投到**每一个**物理麦得 $Q=C\times P_r$ 条高 SNR 虚拟麦；虚拟麦与物理麦拼接进 DNN 输入并全部计入 FCP + mixture-consistency 损失（$\alpha=1.0$ / $\beta=0.02$），determined 阵列变"伪 over-determined"。 | 原论文摘要明确写 augmenting observed training mixtures with higher-SNR virtual-microphone signals obtained by linear spatial demixers (IVA / spatial clustering)：[arXiv:2510.08914](https://arxiv.org/abs/2510.08914)。                                                            |
| [[方向/AI语音/模型/C2D Projection（近讲麦到远场投影）]]    | 用真实录音造监督目标，绕开仿真-真实失配。                                        | 从说话人嘴边**近讲麦**出发估跨域算子；代价函数与 SDW-MWF 同构但观测域 / 目标域跨域，rank-1 化简后与 PMWF 的唯一差别是分子里的目标 SCM 换成**跨域互协方差** $\Phi_n^{cd}$——在远场域重构目标源像，不是朝目标方向做空间滤波。        | 原论文题名与摘要聚焦 close-to-distant microphone projection 生成训练目标：[arXiv:2606.13109](https://arxiv.org/abs/2606.13109)。                                                                                                                                   |

## 2. 神经波束形成 / 经典-神经混合

DNN 估时频掩码 → 空间协方差矩阵 → [[方向/AI语音/知识/基础概念/MVDR（最小方差无失真响应）|MVDR]] / GSC 滤波，仍是挑战赛与工业主流；2026 年的趋势是**可学习协方差与可学习约束**向经典框架渗透。

- **[[方向/AI语音/模型/CUSIDE-array|CUSIDE-array]]**（ISCSLP 2024）：流式掩码 MVDR 前端，挑战赛/工业主流代表（[arXiv:2407.09807](https://arxiv.org/abs/2407.09807)）。
- **[[方向/AI语音/模型/Direction-Preserving MIMO|Direction-Preserving MIMO]]**（2026-04）：OnlineSpatialNet 估尺度归一化噪声协方差 Cholesky 因子 + 保向 MIMO Wiener 滤波，全盲且保留目标/残余噪声空间线索（利于双耳渲染、DOA）；参数与算力约 mask-based NICE 的 1/3，逼近 oracle（[arXiv:2604.11179](https://arxiv.org/abs/2604.11179)）。
- **[[方向/AI语音/模型/WNG-MVDR|数据驱动 WNG-MVDR]]**（2026-06）：双分支网络联合估时频噪声掩码与频变[[方向/AI语音/知识/基础概念/WNG（白噪声增益）|白噪声增益（WNG）]]阈值，微分化鲁棒 MVDR 层自适应鲁棒性-指向性权衡，阵列失配/自噪声下优于固定 WNG（[arXiv:2606.24137](https://arxiv.org/abs/2606.24137)）。
- **Linearly Constrained Deep Beamformer**（2026-05）：增广拉格朗日损失把无失真响应 + 干扰置零约束直接嵌进 DNN 波束权重估计，2/3 说话人场景 SI-SDR/旁瓣/背景衰减均优于经典 LCMV（[arXiv:2605.21141](https://arxiv.org/abs/2605.21141)）。
- **Listen-first 输出式增强**（2026-07，助听）：用输出可懂度（glimpse proportion）从候选 MPDR 波束中选配置，−10~−5 dB 低 SNR 与 RTF 失配下一致优于输入式 MVDR 基线，且不依赖个体化 RTF 字典（[arXiv:2607.12529](https://arxiv.org/abs/2607.12529)）。
- **AEC / full-duplex 边界**：有播放参考的会议、助听和语音 Agent 链路不能只靠 SE 后处理兜底；[[方向/AI语音/知识/基础概念/Audio Leakage（漏音）|Audio Leakage]]、AEC、VAD、barge-in 与 beamforming 的顺序和延迟预算需要一起评估，见 [[方向/AI语音/知识/基础概念/Full-Duplex（全双工）|Full-Duplex]]。

## 3. 全神经端到端与高效化

[[方向/AI语音/模型/TF-GridNet|TF-GridNet]]、[[方向/AI语音/模型/SpatialNet|SpatialNet]] 双路径架构为强基线；2025 年起走向高效化与 ASR 联合。

- **超低算力复数掩码**（Meta，ICASSP 2025）：端侧高效化。
- **Align-and-Filter Network**（ICASSP 2025）：利用空间可分离性降算力。
- **[[方向/AI语音/模型/McNet|McNet 系列]] / [[方向/AI语音/模型/Mel-McNet|Mel-McNet]]**（西湖大学 Audio-WestlakeU，Interspeech 2025）：在线多通道增强框架；Mel-McNet 把多通道 STFT 压到 Mel 域，算力降 60% 且增强与下游 ASR 表现接近原 McNet；它输出 enhanced LogMel 供 ASR 消费，不是 ASR 模型（[GitHub](https://github.com/audio-westlakeu/mel-mcnet)）。
- **[[方向/AI语音/模型/ARiSE|ARiSE]]**（Auto-Regressive Multi-Channel SE，Interspeech 2025）：自回归逐帧利用已增强历史帧的空间-时序信息（[ISCA](https://www.isca-archive.org/interspeech_2025/shen25_interspeech.pdf)）。
- **Loose Coupling of Spectral and Spatial Models**（Paderborn + NTT，ICASSP 2026）：动态会议/说话人移动下频谱与空间模型松耦合（[arXiv:2601.16077](https://arxiv.org/abs/2601.16077)）。
- 复数谱映射已成标配（综述：[arXiv:2505.08694](https://arxiv.org/abs/2505.08694)）；手工 [[方向/AI语音/知识/基础概念/IPD（通道间相位差）|IPD]] / [[方向/AI语音/知识/基础概念/ILD（双耳声级差）|ILD]] 特征逐步被可学习空间滤波（跨通道 conv、帧级 DOA 编码、GNN 通道建模）取代。
- **与 ASR 联合**：从"增强→识别"串行转向面向识别的目标函数，输出 Mel 特征直接接入 Whisper 类编码器；三星 Whisper-Fest（2026）探索无平行数据下增强与 Whisper 级 S2T 联合训练；框架性综述见 Haeb-Umbach 等（[arXiv:2501.07215](https://arxiv.org/abs/2501.07215)）。
- **[[方向/AI语音/实证研究/Joint Beamforming and SA-ASR（联合波束形成与说话人属性 ASR）|联合波束形成与 SA-ASR]]**（EUSIPCO 2025）：真实 AMI 上用预训练神经波束形成器（DAS）接说话人属性 ASR，把 ASR loss 反传到前端可再降 9% WER，**但 SI-SDRi 变差**——"读榜先拆终点"的具体反例（[arXiv:2410.21849](https://arxiv.org/abs/2410.21849)）。
- **轻量化**：单通道已很成熟——GTCRN 仅 48.2K 参数（[GitHub](https://github.com/Xiaobin-Rong/gtcrn)）、DeepFilterNet3 48kHz 全带实时、FastEnhancer 单 CPU 线程最快推理；多通道流式以因果神经波束成形（Spatial-DCCRN、align-and-filter）为主。
- **[[方向/AI语音/模型/LABNet|LABNet]]**（USTC NERC-SLIP，2025-07）：三阶段 + 跨通道注意力的 **52k 参数** ad-hoc 多通道实时增强网络，单次训练即对麦克风数量与几何保持不变（[arXiv:2507.16190](https://arxiv.org/abs/2507.16190)）。

## 4. 弱监督 / 无监督 / 真实数据

经典波束形成 + 神经后滤波的混合路线之外，缓解仿真-真实失配的三条路径：弱监督标签、无监督方法、真实数据挑战赛。

- **[[方向/AI语音/模型/Mixture to Beamformed Mixture（波束形成混合弱监督）|Mixture to Beamformed Mixture]]**（Zhong-Qiu Wang 等 2025）：用波束形成输出作弱监督标签训练 DNN（[arXiv:2507.15229](https://arxiv.org/abs/2507.15229)）。
- **[[方向/AI语音/模型/USDnet++|USDnet++]]**：无监督去混响。
- **无监督扩散**（ArrayDPS 线）：扩散先验做无监督盲分离，见下节。
- 真实 32 通道数据集 [[方向/AI语音/数据集/RealMAN|RealMAN]]（83.7h 室内/室外/半室外/交通；西湖大学 AudioLab + 希尔贝壳，NeurIPS 2024，独立开源，非 Geo-DConv 发布物）——Geo-DConv 在其上验证，见"五、阵列泛化 / 任意几何 / 少麦"。
- **[[方向/AI语音/模型/C2D Projection（近讲麦到远场投影）|C2D Projection]]**（NTT，ICASSP 2026）：从说话人嘴边的**近讲麦**出发估跨域算子，在远场域**重构目标源像**当干净参考。与 [[方向/AI语音/模型/Mixture to Beamformed Mixture（波束形成混合弱监督）|M2BM]] 的本质差别：M2BM 在同一个远场观测内做空间滤波，"干净"只来自空间置零；C2D 引入了观测之外的干净传感器，跨域投影后分子里的目标 SCM 被换成跨域互协方差 $\Phi_n^{cd}$（[arXiv:2606.13109](https://arxiv.org/abs/2606.13109)）。
- **[[方向/AI语音/模型/VM-UNSSOR|VM-UNSSOR]]**（SUSTech，ICASSP 2026）：用 IVA / 空间聚类把观测混合线性投影成高 SNR **虚拟麦克风**（$Q=C\times P_r$ 条），把 UNSSOR 的 mixture-consistency 监督从物理通道扩到虚拟通道；2 麦 determined 下从训不起来（−2.7 dB）到 10.7 dB SI-SDR。两条硬约束：虚拟麦必须回投到**全部**物理麦（只回参考麦 15.5 vs 全麦 17.1 dB），且只算损失、不让 DNN 直接拟合虚拟麦（[arXiv:2510.08914](https://arxiv.org/abs/2510.08914)）。
- **[[方向/AI语音/模型/USD-DPS|USD-DPS]]**（UIUC × SUSTech，WASPAA 2025）：扩散先验 + 逐采样步估计各通道 RIR 的**无监督多通道盲去混响**，用混音一致性构造似然；无监督方法中最优，但仍弱于强监督基线（[arXiv:2508.02071](https://arxiv.org/abs/2508.02071)）。
- **[[方向/AI语音/实证研究/Accurate Room-Acoustic Simulation（高保真 RIR 仿真对多通道增强的影响）|高保真 RIR 仿真]]**（Treble Technologies，Interspeech 2026）：模型与训练策略完全不动，只把训练 RIR 从几何声学换成**波动物理仿真**，实测 WER 就显著下降（vs 不知情 ISM 总体 −30.0%、OV40 档 −38.3%）。关键可复用的是**"把参数对准"与"把物理做对"可分离且叠加**——ISM-M 已复刻房间包围盒、收发位置与 T20，仍落后混合方案（[arXiv:2606.31552](https://arxiv.org/abs/2606.31552)）。
- **[[方向/AI语音/数据集/DRES（荷兰语半自发语音数据集）|DRES]]**（TU Delft，投稿 Interspeech 2026）：80 说话人、1.5h 荷兰语四通道线阵**真实录制**测试集。注意口径错配——原论文明确只用通道 2 做单通道评测，其公开结论不能当多通道 benchmark 或对标基线。

## 5. 生成式多通道化（重点跟踪）

单通道扩散增强（[[方向/AI语音/模型/SGMSE+|SGMSE+]]、[[方向/AI语音/模型/StoRM|StoRM]]、CDiffuSE）2022 年后成熟，2025–2026 开始向多通道扩展；当前分成三类：**狭义多通道 SE refiner**（ArrayDPS-Refine）、**SS refiner / corrector 相邻线**（ArrayDPS、MeCo）、**直接多通道扩散 SE**（AMDM-SE / mSGMSE）。工程上两段式更稳，但直接生成式多通道增强仍在探索，不能简单说已被取代。

- **[[方向/AI语音/模型/ArrayDPS|ArrayDPS]]**（ICML 2025）：严格是无监督盲语音分离，不是 SE；价值在于把 clean speech diffusion prior 和 DPS 用到未知阵列 / 未知 RIR 的逆问题。
- **[[方向/AI语音/模型/ArrayDPS-Refine|ArrayDPS-Refine]] / [[方向/AI语音/模型/Uni-ArrayDPS|Uni-ArrayDPS]]**（[[方向/AI语音/团队/UIUC SiNRG（UIUC 信号推断研究组）|UIUC SiNRG]] × [[方向/AI语音/团队/Z.-Q. Wang Group（Zhong-Qiu Wang 组）|Z.-Q. Wang]]）：ArrayDPS-Refine 是狭义多通道 SE refiner，Uni-ArrayDPS 把 refinement 扩到 enhancement + separation；空间信息由判别式/波束成形前端利用，扩散模型负责修复语音失真与残留噪声（[arXiv:2603.24385](https://arxiv.org/abs/2603.24385)、[arXiv:2603.24810](https://arxiv.org/abs/2603.24810)）。
- **[[方向/AI语音/模型/MeCo|MeCo]]**（Interspeech 2026，KAIST，开源）：严格是多通道语音分离 corrector，不是狭义 SE；它在判别式分离器输出上学条件 Mean Flow 速度场，单次前向（1 [[方向/AI语音/评估/NFE（函数评估次数）|NFE]]）校正到干净语音流形，本页只借鉴一步生成式校正范式（[GitHub](https://github.com/rlaehghks5/MECO)）。
- **[[方向/AI语音/模型/AMDM-SE|AMDM-SE]]**（2026，BGU）：直接多通道扩散路线，在扩散框架内引入跨通道时频注意力；不是"判别前端 + 生成精修"两段式。[[方向/AI语音/评估/CHiME（语音分离与识别挑战赛）|CHiME-3]] 上超过单通道扩散基线与强判别式 DNN（[arXiv:2601.13140](https://arxiv.org/abs/2601.13140)）。
- **[[方向/AI语音/模型/VM-ArrayDPS|VM-ArrayDPS]]**（2026-10，SUSTech）：[[方向/AI语音/模型/ArrayDPS|ArrayDPS]] 的**扩展版**（非独立工作）——唯一机制改动在观测端，把 IVA 输出从 warm initialization 提升为**全程参与后验采样的虚拟麦观测**，少麦低 SNR 下盲分离稳定提升；$Q=0$ 时退化为原 ArrayDPS 似然（[arXiv:2610.09334](https://arxiv.org/abs/2610.09334)）。
- **Flow Matching 成为扩散的高效替代**：[[方向/AI语音/模型/FlowSE|FlowSE]]（Interspeech 2025）证明更少采样步可达扩散相当质量；趋势关键词：少步采样、确定性轨迹、便于蒸馏（[arXiv:2505.19476](https://arxiv.org/abs/2505.19476)）。详见 [[方向/AI语音/知识/生成式语音增强/DiT 与语音增强（DiT-based Speech Enhancement）|DiT 与语音增强]]。
- **Stream.FM**（2025-12）：实时流式 flow matching 复原（[arXiv:2512.19442](https://arxiv.org/abs/2512.19442)）。
- **理论整合**：AAAI 2026 oral 把 flow matching、score-based diffusion、Schrödinger bridge 统一为高斯概率路径框架（[GitHub](https://github.com/Dahan-Wang/Rethinking-Flow-and-Diffusion-Bridge-Models-for-Speech-Enhancement)）。
- **增强的"语言模型化"**：[[方向/AI语音/模型/SELM|SELM]]（ICASSP 2024）、[[方向/AI语音/模型/GenSE|GenSE]]（2025）把 WavLM 表示量化成 token，用 SpeechLM 做"噪声 token → 干净 token"映射，目标是前端与后端语音大模型共享表示空间，走向"增强—理解一体化"。与 [[方向/AI语音/模型/SenSE|SenSE]]、[[方向/AI语音/模型/UniSE（Unified Speech Enhancement）|UniSE]] 同属此线；融合分级与阵列特有开放问题见"八、增强与语音大模型的表示级融合"。
- **幻觉风险**：扩散/生成模型在低 SNR 下会"编造"语音内容，对 ASR 与助听有害；URGENT 2025 显示预测式仍占优，可控性与保真度是生成式的核心矛盾。

## 6. 阵列泛化 / 任意几何 / 少麦

[[方向/AI语音/知识/基础概念/IPD（通道间相位差）|IPD]] 特征绑定固定几何，空间泛化需要先按几何信息可用性拆开：未知 / 弱几何走 Ambisonics 或 dropout 式 array-agnostic；几何已知但设备多变走显式坐标条件化；固定已知几何但麦克风少走[[方向/AI语音/知识/基础概念/Neural-VME（神经虚拟麦克风估计）|虚拟麦克风 / 空间上采样]]。2026-07 起，显式几何条件化与 Ambisonics 域编码并行为两大主线。

- **AmbiDrop**（ICASSP 2026）：编码到 Ambisonics 域 + 通道 dropout，实现 array-agnostic（[arXiv:2509.14855](https://arxiv.org/abs/2509.14855)，扩展版 [arXiv:2607.00548](https://arxiv.org/abs/2607.00548)）；[[方向/AI语音/模型/VarArray|VarArray]] 思路的延续。
- **[[方向/AI语音/模型/ADEPS|ADEPS]]**（BGU Rafaely 组，2026-08）：**编码步本身**的生成式升级——把物理采集模型嵌进扩散后验采样（DPS），先验只在理想 Ambisonics 上训练，对任意阵列零样本编码；阶数匹配设定下 SI-SDR 比线性编码高 4–7 dB，但 150 步推理非实时、先验限 5 阶（[arXiv:2608.24558](https://arxiv.org/abs/2608.24558)）。可作为 AmbiDrop 的 ASM 前端替换候选（未验证）。
- **[[方向/AI语音/模型/Geo-DConv|Geo-DConv]]**（上海交大，2026-07）：傅里叶位置编码 + 拓扑感知坐标 Transformer（TACT）把麦克风坐标转成动态卷积权重，将 [[方向/AI语音/模型/SpatialNet|SpatialNet]] / [[方向/AI语音/模型/TF-GridNet|TF-GridNet]] 等固定阵列模型改造为 array-invariant；真实 32 通道数据集 **[[方向/AI语音/数据集/RealMAN|RealMAN]]**（83.7h）验证，对麦克风排列置换等变（[arXiv:2607.18658](https://arxiv.org/abs/2607.18658)）。
- **MSEN 特征束多阶编码器**（ICASSP 2026）：任意紧凑平面阵列经空间滤波器组投影到圆谐波（eigenbeam）规范空间，并行编码 0/1/2 阶分量；随机平面阵列上 PESQ/CSIG/CBAK/COVL/STOI 全面超基线且算力更低（[IEEE](https://ieeexplore.ieee.org/abstract/document/11464064)）。
- **高效 SFB 设计**（ICASSP 2026）：给出空间滤波器组（SFB）覆盖完整波束图的最优通道数理论；LSTM 替换自注意力质量持平 Conformer 基线、算力 −25%（[IEEE](https://ieeexplore.ieee.org/document/11461458)）。
- **[[方向/AI语音/模型/HyBeam|HyBeam]]**（Ben-Gurion + Meta Reality Labs）：低频原始信号 + 高频波束输出的混合方案，面向眼镜/耳机（[arXiv:2510.22637](https://arxiv.org/abs/2510.22637)）。
- **[[方向/AI语音/模型/Spatial-Magnifier|Spatial-Magnifier]]**（Meta，Interspeech 2026）：固定已知几何下的少麦"空间上采样"，从少量麦克风估计虚拟麦克风信号 / 特征，恢复接近全阵列 oracle 性能；不是 array-agnostic，但直指消费级少麦设备（[arXiv:2605.04749](https://arxiv.org/abs/2605.04749)）。
- **[[方向/AI语音/模型/Virtual-Flow|Virtual-Flow]]**（Meta，NeurIPS 2026）：同组 VME 线的无监督续作——flow matching 条件生成虚拟麦信号，**不需要虚拟位置真值**（伪 VM 目标 = 实录时延叠加），加 reflow 蒸馏后下游波束形成/SE 超 SOTA neural-VME 且算力更低；只有摘要，机制细节待全文（[NeurIPS 页](https://neurips.cc/virtual/2026/loc/paris/poster/151716)）。
- **[[方向/AI语音/模型/UniArray|UniArray]]**（湖南大学 / 江南大学 / NTU，2025-03）：虚拟麦克风估计把通道数**补齐归一**，再用频率分箱级空间字典嵌入替代 [[方向/AI语音/知识/基础概念/TAC（变换-平均-拼接）|TAC]] / 注意力交替。属第四类——"通道数归一 + 数据驱动固定维度空间表示"，不是物理域变换，也不是显式坐标（[arXiv:2503.05110](https://arxiv.org/abs/2503.05110)）。
- **[[方向/AI语音/模型/SFB-NSE|SFB-NSE]]**：**固定（数据无关）**空间滤波器组——单一 2 阶 supercardioid 波束 × 9 个指向方位——把阵列几何消掉，单阵列训练即可泛化到未见 UCA；与 [[方向/AI语音/模型/MSEN（特征束多阶编码器）|MSEN]] 是**不同工作**（作者无重叠、机制与阵列口径均不同）（[arXiv:2504.01392](https://arxiv.org/abs/2504.01392)）。
- **[[方向/AI语音/模型/REDnet|REDnet]]**（SUSTech，2026-08）：递归编码逐麦、递归解码逐人，**说话人数与麦克风数同时可变**，并在解码过程中数出人数；不做通道补齐，直接逐麦累积（[arXiv:2608.24659](https://arxiv.org/abs/2608.24659)）。
- **[[方向/AI语音/模型/WG-Auto-HOA|WG-Auto-HOA]]**（UHH，IWAENC 2026）：高阶 Ambisonics 域，把神经时频处理与线性空间处理解耦，只用目标**初始方向**即可在移动场景下跟踪并提取，弱引导要求几何无关（[arXiv:2607.04471](https://arxiv.org/abs/2607.04471)）。
- **[[方向/AI语音/模型/Adaptive Rotary Steering（自适应旋转转向）|Adaptive Rotary Steering]]**（UHH，ICASSP 2026）：把声场旋转转向自动化并联合帧级自回归反馈，应对交叉 / 近距移动说话人（[arXiv:2601.12345](https://arxiv.org/abs/2601.12345)）。
  - 口径提醒：上述两篇 UHH 工作题名里的 "autoregressive" 是**因果逐帧递推 + 上一帧增强输出回灌**，与 [[方向/AI语音/模型/ARiSE|ARiSE]] 同义，**不是**生成式自回归语音建模；判定依据见各自对象页「身份」节。

## 7. 分布式 / 异步 / 柔性阵列

多设备协同拾音（"手机+耳机+笔记本"）面对采样率偏移（SRO）、时间偏移（STO）与动态位置；TAC 模块无法处理异步。

- **SAMbA**（2023）：分布式 ad-hoc 阵列奠基工作（[arXiv:2307.16582](https://arxiv.org/abs/2307.16582)）。
- **窗式交叉注意力**（2025）：多设备 SRO/STO 动态对齐（[arXiv:2507.16104](https://arxiv.org/abs/2507.16104)）。
- **CaSNet**（ICASSP 2026）："压缩-发送"——各设备 SVD 压缩特征矩阵后传输、融合中心跨窗口查询对齐，以可忽略性能损失省带宽/能耗（[arXiv:2601.17711](https://arxiv.org/abs/2601.17711)）。
- **FlexIO**（ICASSP 2026）：单模型兼容 1–5 麦输入 × 1–3 说话人输出（说话人提示向量条件），CHiME-4 验证（[IEEE](https://ieeexplore.ieee.org/document/11462393)）。

## 8. 空间引导 / 多模态

- **End-to-End DOA-Guided Extraction**（2025）：[[方向/AI语音/知识/基础概念/DOA（到达方向）|DOA]] 引导端到端目标说话人提取（[arXiv:2507.20926](https://arxiv.org/abs/2507.20926)）。
- **PATSE**（2026）：面向长时多方对话，DOA 引导空间编码器直接输出按说话人的流，免显式 diarization（[arXiv:2606.29497](https://arxiv.org/abs/2606.29497)）。
- **Spatial-VisualVoice + MAVE**（2025）：可穿戴阵列 + 视觉，保留空间线索面向 AR/VR。
- **[[方向/AI语音/模型/CI-Spatial|CI-Spatial]]**（Radboud / Leiden UMC，2025-01，期刊版 Scientific Reports）：人工耳蜗麦克风阵列的真实场景双说话人分离。核心结论是**隐式线索越弱、显式 IPD 的增益越大**——单侧双通道 +51.8% SI-SDR，双耳仅 +18.2%，单通道 +3.0%。同模型干场景 SI-SDR 12.96 → 真实场景 2.66（[arXiv:2501.14610](https://arxiv.org/abs/2501.14610)）。
- **[[方向/AI语音/实证研究/Mask-based SE for Spatial Audio（掩蔽增强三域对比）|掩蔽增强三域对比]]**（BGU / TU Berlin，2026-09）：用**实值 oracle IRM**（各表示的理论上界，非训练出来的 DNN）横向比较掩蔽作用于麦克风通道 / 波束形成输出 / Ambisonics 三个域。三条可复用结论：①三域都保住了目标线索（ΔITD 全 0），**差异只出现在残余干扰上**；②"哪个域空间最差"随指标翻转（ITD 维度麦克风域最差，ILD 维度波束域最差）；③**期望信号怎么定义，影响大于掩蔽放哪个域**——用直达声当目标时波束域 ΔC50 高达 9.00 dB，改混响目标后降到 0.58 dB（[arXiv:2609.18532](https://arxiv.org/abs/2609.18532)）。
- **MISP 2025 Challenge** 延续多通道远场音视频基准；ICASSP 2026 设 SLP-P47 多模态多通道增强专场。

## 9. 增强与语音大模型的表示级融合

总体判断中"未来两年最值得跟踪"的第三条；2026-08-20 由散落条目（方案速查、"四、生成式多通道化"的"语言模型化"条目、"二、全神经端到端"的 ASR 联合条目）整合为独立一节。核心问题：**阵列增强的输出以什么表示形态交给语音大模型，两者能否共享表示空间**。按融合深度分三级：

| 融合层级 | 做法 | 代表 | 判断 |
| --- | --- | --- | --- |
| 波形级（级联） | 增强输出干净波形 / mono stream + metadata，后端 ASR / audio LLM 独立 | [[方向/AI语音/知识/基础概念/Array Audio Signal（阵列音频信号）]] 方案 A/B；ESPnet-SE++ 前后端集成 | 当前工程主流；前端可独立验证，但前后端表示不通、误差不可回传 |
| 特征级 | 增强直接输出后端可消费的特征，或与后端联合训练 | [[Mel-McNet]] 输出 enhanced LogMel 直供 ASR / vocoder；三星 Whisper-Fest 无平行数据 SE + Whisper 级 S2T 联合训练（见"二、全神经端到端与高效化"） | 已验证有效，但表示按后端任务定制，不通用 |
| 表示级 | 增强与 SpeechLM 共享 token / latent 空间，增强即"噪声 token → 干净 token"映射 | [[SELM]]、[[GenSE]]（WavLM 表示量化）、[[UniSE（Unified Speech Enhancement）]]（codec token + decoder-only LM）、[[SenSE]]（LM 语义 token 指导 flow）、[[UniPASE]] / [[L3-SE]]（SSL 蒸馏压幻觉） | 研究热点；目标是"增强—理解一体化"，codec 锁上限与幻觉是核心矛盾 |

阵列特有的开放问题：

- **空间信息如何进表示**：[[方向/AI语音/知识/基础概念/IPD（通道间相位差）|IPD]] / [[方向/AI语音/知识/基础概念/ILD（双耳声级差）|ILD]] / [[方向/AI语音/知识/基础概念/DOA（到达方向）|DOA]] / [[方向/AI语音/知识/基础概念/SCM（空间协方差矩阵）|SCM]] 等阵列线索在 token 化或 LogMel 压缩后基本丢失；空间规范 / 条件表示（Ambisonics 域 AmbiDrop、eigenbeam MSEN、显式坐标 Geo-DConv）能否成为 SpeechLM 可消费的空间 token / latent，是本主题与"五、阵列泛化 / 任意几何 / 少麦"的交叉口，目前公开实证基本空白。
- **多通道直进大模型**：Directional-SpeechLLaMA（beamformed streams + 方向提示做 directional ASR）说明 raw / beamformed multichannel + LLM 仍处研究探索；主流仍是前端压成 mono + metadata（DOA、speaker turn、confidence）。
- **保真约束**：codec token 化锁死音质上限（相位与细节丢失），低 SNR 下生成式幻觉改词；表示级融合越深，内容保持（CAcc / CER）越要成为硬约束——URGENT 2025 预测式仍占优是直接证据。
- **大模型同时是裁判**：URGENT 2026 Track 2（MOS 预测）与 audio LLM 质量评价说明大模型既是融合对象又是评估器，训练-评估闭环需防"自己生成数据、自己打分"。

深层分析：[[方向/AI语音/知识/技术路线/LLM 与 Agent 对语音增强的影响]]（架构 / 语义 / Agent / 评估四层，含"为何不直接用 LLM 架构 + 语音头"）、[[方向/AI语音/知识/技术路线/LLM Backbone（使用 LLM 作为骨干训练其他任务）]]（encoder + connector + LLM 范式与最小实验矩阵）；前后端工程分工：[[方向/AI语音/知识/基础概念/Array Audio Signal（阵列音频信号）]]。

## 10. 挑战赛与 Benchmark

- **[[方向/AI语音/评估/CHiME（语音分离与识别挑战赛）|CHiME]]**：整体更偏远场 / 多通道 ASR 和 diarization，不是纯阵列增强评测；阵列增强在这里主要是降低 WER 的前端手段。
- **CHiME-7/8 DASR**：远场多设备、任意阵列（array-agnostic）日志+识别。优胜方案套路固定：EEND-VC + TS-VAD 日志 → 改进版 [[方向/AI语音/知识/基础概念/GSS（引导源分离）|GSS]] 多通道增强 → 多 ASR 组合 + LM 重打分（NTT 系统 tcpWER 22.0%）。总结报告：[MERL TR2026-008](https://www.merl.com/publications/docs/TR2026-008.pdf)。
- **[[方向/AI语音/评估/NOTSOFAR-1（远场会议转写挑战）|CHiME-8 NOTSOFAR-1]]**（Interspeech 2024）：已知几何会议室场景，约 280 场真实会议 + 1000h 仿真；它是远场会议转写 benchmark，可间接观察阵列前端收益，但不是阵列音频增强榜（[arXiv:2401.08887](https://arxiv.org/abs/2401.08887)）。
- **CHiME-9**（2025.7–2026.2）：转向 [[方向/AI语音/评估/MCoRec（多模态上下文识别）|MCoRec]]（360° 音视频多会话分离转录）与 [[方向/AI语音/评估/ECHI（助听对话增强）|ECHI]]（助听场景对话增强），反映多模态与助听新热点（[官网](https://www.chimechallenge.org/challenges/chime9/index)）。2026 上半年公布结果：
  - **[[方向/AI语音/评估/MCoRec（多模态上下文识别）|MCoRec]]**：冠军 USTC-NERCSLIP + 讯飞（讯飞连续第六届 CHiME 夺冠）——360° 逐人视觉流 + ASD/AVTSE/AVSR + Whisper 与 LLM + ROVER 融合（[arXiv:2603.01415](https://arxiv.org/abs/2603.01415)）；BUT 用 Parakeet-v2 + AV-HuBERT + Qwen3.5 话题聚类。
  - **ECHI**（助听/智能眼镜，严格 20ms 延迟）：代表方案为低延迟多级 MIMO 系统（数据清洗 + 在线波束形成 + 多波束分离器）与三段式（自干扰抑制→TSE→后处理）。
- **CHiME-10**（2026-07 公布，[官网](https://www.chimechallenge.org/challenges/chime10/index)）：设 ECHI-2、URGENT、SG-TSE 三个任务——ECHI-2（智能眼镜对话增强，多模态，通道数未公布）、URGENT（统一 USE+TSE+AEC，**通道配置未公布**，沿用 2025 单通道版还是升级多通道待核）、SG-TSE（智能眼镜多通道目标说话人提取，明确 multichannel）。
- **URGENT 2024→2026**：单模型处理噪声/混响/削波/带宽/编解码/丢包/风噪 7 类失真。2025 优胜系统多为预测式多阶段架构（如 TS-URGENet 三阶段），生成式整体稍逊；2026 头部系统几乎清一色**生成+判别混合**（双分支/多级流水线），**数据筛选成胜负手**（基线即把 2500h 用 MOS 精选到 700h，[[方向/AI语音/实证研究/Less is More（语音增强数据筛选）|Less is More]]），Track 2 语音质量预测头部走 Uni-VERSA-Ext 式训练（[arXiv:2601.13531](https://arxiv.org/abs/2601.13531)）。多通道泛化仍是 URGENT 的薄弱环节。详见 [[方向/AI语音/评估/URGENT（通用语音增强挑战）|URGENT]]。
- **DNS Challenge**：2023 年第五届后停办，实时低延迟定位部分由 URGENT 与助听器挑战（Clarity/ECHI）承接。
- **经典评测集（方法对比锚点）**：新挑战赛看真实场景风向，但论文间可比性仍靠经典集，新论文普遍仍在报：
  - [[方向/AI语音/数据集/AMI Meeting Corpus（会议语料库）|AMI]]：约 100h 英文会议，IHM / SDM / MDM 三种麦克风口径，会议 ASR、diarization、GSS / CSS 前端增强的经典基准（注意跨论文比较时核对 partition 与口径）。
  - **LibriCSS**：7 麦圆阵重录 LibriSpeech，连续语音分离（CSS）经典基准。
  - **AISHELL-4**：8 麦圆阵约 120h 中文会议。
  - **AliMeeting / M2MeT**：8 麦约 119h 中文会议，ICASSP 2022 M2MeT 挑战赛。
  - **REVERB Challenge**（2014）：8 麦圆阵混响语音经典基准（仿真 + 真实数据）。
  - [[方向/AI语音/数据集/WSJ0（华尔街日报语料库）|WSJ0]]：1991–1993 年 NIST/LDC 朗读语料，wsj0-2mix / WHAM / SMS-WSJ 等仿真混合基准的共同语音底料，跨论文比较先核衍生集口径。
  - **SMS-WSJ**：仿真空间化 WSJ 双人混合（RIR + 多麦），Paderborn 系多通道论文常用。

## 11. 开放问题

1. **阵列泛化边界**：见"五、阵列泛化 / 任意几何 / 少麦"——未知几何、已知坐标条件化、少麦空间上采样三类问题不能混为一个 array-agnostic 口径。
2. **分布式/异步阵列**：SRO/STO 与动态位置，见"六、分布式 / 异步 / 柔性阵列"。
3. **真实场景泛化**：弱监督、无监督、真实数据挑战赛三条缓解路径，见"三、弱监督 / 无监督 / 真实数据"。
4. **实时低延迟**：Mel 域压缩、超低算力复数掩码、chunk 级流式 beamforming 是工程化主流；"生成式质量 + 预测式速度"融合（如 MERL 的 predictive-generative drift decomposition）尚不成熟。
5. **AEC / 全双工链路**：有播放参考、barge-in 或模型自听时，AEC 与增强、VAD、beamforming 的责任边界要先定清楚，不能把回声泄漏交给后端大模型兜底。

## 12. 待深挖

候选主题页（按当前预研优先级）：

1. **P0 生成式多通道上限**：直接多通道扩散 / MIMO 生成、判别前端 → 生成精修、DiffCBF 式物理耦合、one-step flow corrector、codec / latent 多通道生成。覆盖 [[方向/AI语音/模型/ArrayDPS-Refine|ArrayDPS-Refine]]、[[方向/AI语音/模型/Uni-ArrayDPS|Uni-ArrayDPS]]、[[方向/AI语音/模型/AMDM-SE]]、[[方向/AI语音/模型/mSGMSE]]、[[方向/AI语音/模型/DiffCBF]]、[[方向/AI语音/模型/MeCo|MeCo]]。
2. **P1 阵列泛化 / 少麦表示横评**：AmbiDrop（未知 / 弱几何）/ Geo-DConv（显式坐标）/ MSEN（eigenbeam 规范空间）/ [[方向/AI语音/模型/HyBeam|HyBeam]]（混合）/ [[方向/AI语音/模型/Spatial-Magnifier|Spatial-Magnifier]]（固定几何少麦上采样）；重点看 seen / unseen geometry、传感器缺失和生成式模型能否消费这些空间表示。
3. **P2 真实数据与弱监督闭环**：URGENT 2026 [[方向/AI语音/实证研究/Less is More（语音增强数据筛选）|Less is More]] 数据筛选、[[方向/AI语音/模型/Mixture to Beamformed Mixture（波束形成混合弱监督）|beamformed mixture 弱监督]]、[[方向/AI语音/模型/USDnet++|USDnet++]] 无监督、RealMAN 真实数据；目标是验证幻觉、空间失真和 sim-to-real 偏移。
4. **P3 空间 / 语义条件化增强**：DOA / TSE / speaker attribution / AVSR 作为生成式增强条件和输出定义，不再只作为下游任务。
5. **P4 分布式观测建模**：SRO / STO、动态设备、压缩传输、flexible I/O；重点看动态设备集合如何转成大模型可消费的音频观测。
6. **P5 物理 baseline 与失败模式**：WNG-MVDR、DP-MWF、WPE / CBF、SCM 估计、AEC / 回声泄漏；记录生成式路线必须击败或继承的观测一致性约束。
7. **P6 高效化成本账**：Mel 域压缩、流式 beamforming、NFE、蒸馏、量化、端侧映射；只记录成本和未来压缩路径，不作为当前预研排序依据。

跟踪项：

- CHiME-10（2026-07 公布：ECHI-2、URGENT、SG-TSE 三任务）后续赛制与数据——重点核 URGENT 是否多通道（数据页未上线）。
- 流式生成式增强的延迟-质量权衡：Stream.FM、[[方向/AI语音/模型/MeCo|MeCo]] 1 NFE（SS corrector 口径）vs ECHI 20ms 硬约束。
- 已拆 [[方向/AI语音/评估/NOTSOFAR-1（远场会议转写挑战）|NOTSOFAR-1]]；CHiME-8 DASR、CHiME-9 ECHI 是否继续拆子页待观察复现实验需求。
- 对象页已建：AmbiDrop、ADEPS、Geo-DConv、Spatial-Magnifier、Virtual-Flow、UniArray、SFB-NSE、REDnet、WG-Auto-HOA、Adaptive Rotary Steering、VM-ArrayDPS、VM-UNSSOR、USD-DPS、C2D Projection、LABNet、CI-Spatial、DRES（数据集）、Mask-based SE for Spatial Audio（论文页）、Accurate Room-Acoustic Simulation（论文页）、Joint Beamforming and SA-ASR（论文页）。下一步把本页细节继续下沉，并补一张阵列泛化 / 少麦路线横评表。
- 2026-10-09 补建说明：本批对象页来自 `D:\paper\audio\阵列语音增强_2024-10至2026-10` 的 PDF 归档（80 篇，其中 15 篇 P0–P2 高优先批已建页，其余 P3–P6 及已有页对象留下轮）。

## 13. P3–P6 对象页补建完成

2026-10-15 已从同一 PDF 归档补建 40 个独立对象页，覆盖 P3 空间/语义条件化、P4 分布式观测、P5 物理混合基线与 P6 低延迟/低算力路线。页面已分流到 [[方向/AI语音/知识/技术路线/Spatial-Guided SE（空间引导与多模态增强）]]、[[方向/AI语音/知识/技术路线/Distributed Multichannel SE（分布式异步多通道增强）]]、[[方向/AI语音/知识/技术路线/Hybrid Array SE（传统神经混合阵列增强）]]、[[方向/AI语音/知识/技术路线/Efficient Multichannel SE（多通道语音增强高效化）]]。

- P3：[[方向/AI语音/模型/MCBSE（多通道说话人提取与双耳语音合成）]]、[[方向/AI语音/模型/NDSE（双麦定向语音增强）]]、[[方向/AI语音/模型/SSM-NBF（说话人选择神经波束形成）]]、[[方向/AI语音/模型/Spatial-VisualVoice（空间视觉语音增强）]]、[[方向/AI语音/模型/VI-NBFNet（视觉引导神经波束形成）]]、[[方向/AI语音/模型/HRTF-TSE（HRTF 引导双耳目标说话人提取）]]、[[方向/AI语音/模型/BiTSE（AR 眼镜双耳目标说话人提取）]]、[[方向/AI语音/模型/ABSE-NET（开放式助听器主动双耳增强）]]。
- P4：[[方向/AI语音/模型/dMWF（分布式多通道维纳滤波）]]、[[方向/AI语音/模型/CabinSep]]、[[方向/AI语音/模型/Robot-Mic-SE（可重构阵列语音增强平台）]]、[[方向/AI语音/模型/CrossArray-PF（跨阵列非目标估计后滤波）]]、[[方向/AI语音/模型/RT-Tango]]、[[方向/AI语音/模型/TI-dMWF（拓扑无关分布式多通道维纳滤波）]]、[[方向/AI语音/模型/Q-TANGO（量化分布式双耳语音增强）]]、[[方向/AI语音/模型/Online Per-Channel Mask Beamforming（分通道掩码在线波束形成）]]。
- P5：[[方向/AI语音/模型/RT-NBF（运行时自适应神经波束形成）]]、[[方向/AI语音/模型/ExNet-BF+PF（可解释神经波束形成与后滤波）]]、[[方向/AI语音/模型/OCM-SABF（遮挡自适应波束形成）]]、[[方向/AI语音/模型/NeuralPMWF（小网络控制多通道维纳滤波）]]、[[方向/AI语音/模型/DPLPF-MNB（双路径线性预测与多范数波束形成）]]、[[方向/AI语音/模型/Online-NF-DDB（无失真差分波束在线神经融合）]]、[[方向/AI语音/模型/CycBF-DNN（循环平稳波束形成与神经去噪）]]、[[方向/AI语音/模型/NDBF（双麦可转向高阶神经差分波束形成）]]、[[方向/AI语音/实证研究/Phoneme-MCSE（多通道增强音素级评估）]]。
- P6：[[方向/AI语音/模型/LMFCA-Net]]、[[方向/AI语音/模型/MW-SLC（掩码加权空间似然编码）]]、[[方向/AI语音/模型/WTFormer]]、[[方向/AI语音/模型/GAF-Net（全局自适应傅里叶双耳增强）]]、[[方向/AI语音/模型/TF-CorrNet]]、[[方向/AI语音/模型/LSZone]]、[[方向/AI语音/模型/Moving-Sep（移动说话人频谱空间并行分离）]]、[[方向/AI语音/模型/Spectral-Spatial TSE（频谱与空间线索联合说话人提取）]]、[[方向/AI语音/模型/RT-Tango]]、[[方向/AI语音/模型/Q-TANGO（量化分布式双耳语音增强）]]、[[方向/AI语音/模型/Transformer-NBF（低功耗可穿戴实时神经波束形成）]]、[[方向/AI语音/实证研究/FT-JNF Knowledge Distillation（多麦增强知识蒸馏比较）]]、[[方向/AI语音/模型/Binaural-CRNN（复数卷积循环双耳增强）]]。

说明：`2503.09412_RTM-Separation` 属于 P1 阵列泛化，本轮不计入；`Spatial-VisualVoice` 已补建独立对象页。

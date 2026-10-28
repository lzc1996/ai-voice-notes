---
title: Array Speech Enhancement Team Map（阵列增强团队地图）
类型: 索引
整理时间: 2026-08-04
相关任务:
  - 语音增强
  - 多通道增强
相关模型:
  - "[[方向/AI语音/模型/TF-GridNet]]"
  - "[[方向/AI语音/模型/USDnet++]]"
  - "[[方向/AI语音/模型/McNet]]"
  - "[[方向/AI语音/模型/AMDM-SE]]"
  - "[[方向/AI语音/模型/HyBeam]]"
  - "[[方向/AI语音/模型/ArrayDPS-Refine]]"
  - "[[方向/AI语音/模型/UniPASE]]"
  - "[[方向/AI语音/模型/GAP-URGENet]]"
  - "[[方向/AI语音/模型/L3-SE]]"
  - "[[方向/AI语音/模型/SenSE]]"
  - "[[方向/AI语音/模型/UniSE（Unified Speech Enhancement）]]"
  - "[[方向/AI语音/模型/PGUSE]]"
相关团队:
  - "[[方向/AI语音/团队/Z.-Q. Wang Group（Zhong-Qiu Wang 组）]]"
  - "[[方向/AI语音/团队/UPB Haeb-Umbach Group（帕德博恩大学 Haeb-Umbach 组）]]"
  - "[[方向/AI语音/团队/BIU Gannot Group（巴伊兰大学 Gannot 组）]]"
  - "[[方向/AI语音/团队/Audio-WestlakeU（西湖大学音频实验室）]]"
  - "[[方向/AI语音/团队/BGU Speech Enhancement Group（本古里安大学语音增强组）]]"
  - "[[方向/AI语音/团队/UHH Gerkmann Group（汉堡大学 Gerkmann 组）]]"
  - "[[方向/AI语音/团队/UIUC SiNRG（UIUC 信号推断研究组）]]"
  - "[[方向/AI语音/团队/NJU Acoustics（南京大学声学所）]]"
  - "[[方向/AI语音/团队/NWPU ASLP Lab（西工大 ASLP 实验室）]]"
  - "[[方向/AI语音/团队/USTC-NERCSLIP（中科大 NERCSLIP 实验室）]]"
  - "[[方向/AI语音/团队/BUT Speech Group（布尔诺理工语音组）]]"
  - "[[方向/AI语音/团队/NTT Speech Group（NTT 语音组）]]"
  - "[[方向/AI语音/团队/MERL Speech Group（MERL 语音组）]]"
  - "[[方向/AI语音/团队/Meta Audio AI（Meta 音频 AI 团队）]]"
  - "[[方向/AI语音/团队/Microsoft Speech Group（微软语音组）]]"
相关评估:
  - "[[方向/AI语音/评估/CHiME and URGENT Chinese Industry Labs（国内工业界参赛记录）]]"
aliases:
  - 阵列增强团队地图（Array Speech Enhancement Team Map）
  - Array Speech Enhancement Team Map
  - 阵列增强团队地图
  - array speech enhancement team map
tags:
  - 类型/知识
  - 方向/AI语音
  - 任务/语音增强
  - 任务/多通道增强
---

# Array Speech Enhancement Team Map（阵列增强团队地图）

阵列/多通道语音增强领域可信度较高的研究团队地图，各团队均有对象级笔记（`方向/AI语音/团队/`），本页为索引。来源：[[方向/AI语音/知识/调研与地图/Array Speech Enhancement Frontier（阵列语音增强前沿调研）|阵列语音增强前沿调研]]（2026-08），可信度判断依据见文末。相关：[[方向/AI语音/知识/基础概念/Array Audio Signal（阵列音频信号）|阵列音频信号]]、[[方向/AI语音/评估/URGENT（通用语音增强挑战）|URGENT]]。

## 1. 可信度判断依据

排序与收录依据，按权重排列：

1. **挑战赛名次**：CHiME / URGENT / DNS 历史成绩，最硬的公开验证。
2. **开源可复现**：连代码带配置放出来（Z.-Q. Wang、Audio-WestlakeU、MeCo 等）。
3. **方法成为公共基线**：[[方向/AI语音/模型/TF-GridNet|TF-GridNet]]、GSS、WPE、[[方向/AI语音/知识/基础概念/TAC（变换-平均-拼接）|TAC]]——别人论文里默认拿来对比，说明被信任。
4. **研究与产品同源**：NTT、Microsoft、讯飞——论文方法能在自家产品里找到影子。

## 2. 学界核心团队

> 定位标注（2026-08 核实）：**【增强为主线】**= 增强/分离是主要研究方向；**【ASR 为主、增强为辅】**= 主体是 ASR/日志，但有实质增强能力；**【ASR 团队】**= 增强基本只是外部工具的使用者。

### 2.1. 多通道增强/分离（增强为主线）

- [[方向/AI语音/团队/Z.-Q. Wang Group（Zhong-Qiu Wang 组）|Zhong-Qiu Wang 组（南方科技大学）]]【增强为主线】：[[方向/AI语音/模型/TF-GridNet|TF-GridNet]] 作者，多通道分离/增强近五年基线地位最高的团队之一；弱监督（[[方向/AI语音/模型/Mixture to Beamformed Mixture（波束形成混合弱监督）|Mixture to Beamformed Mixture]]）、[[方向/AI语音/模型/USDnet++|USDnet++]] 无监督去混响。
- [[方向/AI语音/团队/UPB Haeb-Umbach Group（帕德博恩大学 Haeb-Umbach 组）|Haeb-Umbach 组（帕德博恩大学）]]【增强为主线，兼做 ASR】：CHiME 元老，[[方向/AI语音/知识/基础概念/GSS（引导源分离）|GSS]] 提出者；ICASSP 2026 Loose Coupling（与 NTT 合作）；远场 ASR 框架性综述。
- [[方向/AI语音/团队/BIU Gannot Group（巴伊兰大学 Gannot 组）|Sharon Gannot 组（巴伊兰大学）]]【增强为主线】：阵列信号处理 + 深度学习结合的理论派权威。
- [[方向/AI语音/团队/Audio-WestlakeU（西湖大学音频实验室）|Audio-WestlakeU（西湖大学）]]【增强为主线】：国内在线多通道增强最集中的团队，[[方向/AI语音/模型/McNet|McNet / Mel-McNet]] 系列，可复现性强。
- [[方向/AI语音/团队/BGU Speech Enhancement Group（本古里安大学语音增强组）|本古里安大学语音增强组]]【增强为主线】：[[方向/AI语音/模型/AMDM-SE|AMDM-SE]]（跨通道注意力多通道扩散）、[[方向/AI语音/模型/HyBeam|HyBeam]]（与 Meta Reality Labs 合作）。
- [[方向/AI语音/团队/UHH Gerkmann Group（汉堡大学 Gerkmann 组）|Gerkmann 组（汉堡大学）]]【增强为主线】：生成式增强源头之一（SGMSE+），偏单通道但方法论影响大。
- [[方向/AI语音/团队/UIUC SiNRG（UIUC 信号推断研究组）|UIUC SiNRG（Choudhury 组）]]【增强为主线，生成式 × 阵列交叉样板】：[[方向/AI语音/模型/ArrayDPS|ArrayDPS]]（ICML 2025）→ [[方向/AI语音/模型/ArrayDPS-Refine|ArrayDPS-Refine]]（ICASSP 2026）——扩散先验解多通道盲逆问题、training-free 生成精修，与 Z.-Q. Wang 固定合作班底。

### 2.2. LM/生成式增强团队（单通道为主，技术源）

- [[方向/AI语音/团队/NJU Acoustics（南京大学声学所）|南京大学声学所（Jing Lu 组）]]【单通道通用增强为主线】：URGENT 2024–2026 连续头部（TS-URGENet → [[方向/AI语音/模型/UniPASE|UniPASE]] → [[方向/AI语音/模型/GAP-URGENet|GAP-URGENet]] 冠军），[[方向/AI语音/模型/L3-SE|L3-SE]]（与小米 MiLM Plus 合作降幻觉）；不做阵列，但"判别→生成→融合"范式可直接迁移。
- [[方向/AI语音/团队/NWPU ASLP Lab（西工大 ASLP 实验室）|西工大 ASLP Lab]]【语音大模型实验室，单通道增强为辅】：[[方向/AI语音/模型/SenSE|SenSE]]（语义 token 指导 flow matching）；无多通道工作，价值在"语义-声学联合"范式。
- LM 增强谱系补充：[[方向/AI语音/模型/UniSE（Unified Speech Enhancement）|UniSE]] 一作 Haoyin Yan 来自 USTC-NERCSLIP（见下"ASR 为主"组），[[方向/AI语音/模型/PGUSE|PGUSE]] 是 NERC-SLIP × 西湖大学的合作——LM 增强与阵列团队的人员交叉比表面看起来深。

### 2.3. ASR 为主但有增强工作的团队

- [[方向/AI语音/团队/USTC-NERCSLIP（中科大 NERCSLIP 实验室）|USTC-NERCSLIP（中科大，联合讯飞）]]【ASR 为主、增强为辅但自研全栈】：CHiME 六连冠；增强以自研挑战赛前端 + 前端-ASR 联合训练形式存在——CHiME-5/6 自研 SD-SS/MGSS、CHiME-7/8 自研 SE+CSS 联合微调、CHiME-9 四套全自研 AVTSE 系统；DNN 增强奠基论文（TASLP 2015）共同作者单位。实验室内部还有 Jie Zhang / Haoyin Yan 的 **LM 增强线**（[[方向/AI语音/模型/PGUSE|PGUSE]]、[[方向/AI语音/模型/UniSE（Unified Speech Enhancement）|UniSE]]）。
- [[方向/AI语音/团队/BUT Speech Group（布尔诺理工语音组）|BUT 语音组（布尔诺理工）]]【ASR/日志团队】：主体是 ASR 与说话人日志；曾有一条 TSE 研究线（SpeakerBeam 谱系，2017–2022，高被引），近年已收缩。CHiME 前端长期依赖外部 [[方向/AI语音/知识/基础概念/GSS（引导源分离）|GSS]] 工具，CHiME-9 干脆把提取隐式并入 AV-ASR——**跟踪其增强工作价值不大，看日志/AV-ASR 即可**。

### 2.4. 工业界实验室（按学界方式产出）

- [[方向/AI语音/团队/NTT Speech Group（NTT 语音组）|NTT 语音组]]【增强与系统并重】：增强研究是实打实的主线之一——WPE 去混响、SpeakerBeam（与 BUT 合作）、多通道前端均出自该组；CHiME 多次冠军（CHiME-8 DASR tcpWER 22.0%）；系统工程标杆。
- [[方向/AI语音/团队/MERL Speech Group（MERL 语音组）|MERL 语音组]]【增强为主线】：深度学习语音分离发源地（deep clustering、PIT）；现转向判别+生成融合。
- [[方向/AI语音/团队/Meta Audio AI（Meta 音频 AI 团队）|Meta 音频 AI（Pandey 组 + Reality Labs）]]【增强为主线】：TAC/ad-hoc 阵列基线、超低算力复数掩码、Spatial-Magnifier、[[方向/AI语音/模型/HyBeam|HyBeam]]；对准穿戴产品。（ArrayDPS 系列与 Meta 无关，是 UIUC SiNRG × Z.-Q. Wang 的工作，见下。）
- [[方向/AI语音/团队/Microsoft Speech Group（微软语音组）|Microsoft 语音组]]【增强为主线】：分布式异步阵列 windowed cross-attention；Teams Voice Isolation；DNS Challenge 组织方。

### 2.5. 国内竞赛验证过的团队

国内竞赛强队（USTC-NERCSLIP）已并入上文"ASR 为主但有增强工作的团队"。

## 3. 工业界（产品可信度）

产品型公司维持索引级收录，不建对象笔记（研究产出不以团队为单位）：

- **国内工业界公开挑战赛记录**：阿里、腾讯、字节、华为 2012 在 CHiME / URGENT 的可核验参赛记录单独整理在 [[方向/AI语音/评估/CHiME and URGENT Chinese Industry Labs（国内工业界参赛记录）|国内工业界参赛记录]]。

- **Shure**：专业会议阵列公认标杆，MXA 系列十年产品线（MXA920 → 2026 AI-enabled MXA925）。
- **科大讯飞**：学术竞赛背书最硬的中国公司（CHiME 六冠，与 USTC 联合），产品线（会议宝、同传麦克风）与研究同源。
- **XMOS**：远场拾音芯片事实标准之一，固件开放；2026 年展示 GenSoC 生成式音频 DSP。
- **Apple / Google**：基本不发论文，但端侧 ML 增强产品化水平（Voice Isolation、Clear Calling）是行业参照系。
- **华为**：会议设备（IdeaHub 24 麦阵列）与 TWS（FreeBuds Pro 5 MIMO AI 感知降噪）双线堆料，论文声量小但落地激进。

## 4. 交叉图谱：单通道/通用增强团队 × 阵列团队（2026-08 补查）

两条线并非隔绝，交叉比表面深，分四种形态：

- **人员/合作交叉**：[[方向/AI语音/团队/UIUC SiNRG（UIUC 信号推断研究组）|UIUC SiNRG]] × [[方向/AI语音/团队/Z.-Q. Wang Group（Zhong-Qiu Wang 组）|Z.-Q. Wang]]（ArrayDPS 系列、WASPAA 2025 扩散去混响固定合作班底）；[[方向/AI语音/团队/USTC-NERCSLIP（中科大 NERCSLIP 实验室）|USTC-NERCSLIP]] × [[方向/AI语音/团队/Audio-WestlakeU（西湖大学音频实验室）|西湖大学]]（[[方向/AI语音/模型/PGUSE|PGUSE]]：Jie Zhang、Haoyin Yan + Xiaofei Li）；[[方向/AI语音/团队/NJU Acoustics（南京大学声学所）|南大声学所]] × 小米 MiLM Plus（[[方向/AI语音/模型/L3-SE|L3-SE]]）。
- **阵列团队自建生成式线**：[[方向/AI语音/团队/NTT Speech Group（NTT 语音组）|NTT]]（[[方向/AI语音/模型/mSGMSE|mSGMSE]] MIMO 扩散 ICASSPW 2024、[[方向/AI语音/模型/Multi-Stream Diffusion|multi-stream diffusion]] IWAENC 2024、[[方向/AI语音/模型/DiffCBF|DiffCBF]] EUSIPCO 2025——阵列团队中生成式布局最系统）；[[方向/AI语音/团队/Audio-WestlakeU（西湖大学音频实验室）|西湖大学]]（RVAE-EM、VINP、[[方向/AI语音/模型/CleanMel|CleanMel]]）；Z.-Q. Wang（经 UIUC 合作进入扩散先验路线）。
- **方法借用/谱系交叉**：[[方向/AI语音/模型/AMDM-SE|AMDM-SE]]（BGU）建立在 SGMSE（[[方向/AI语音/团队/UHH Gerkmann Group（汉堡大学 Gerkmann 组）|Gerkmann 组]]）之上，跨通道 TF-attention 借自 UNSW/NUS（Haizhou Li 组）；GAP-URGENet 预测分支用 [[方向/AI语音/模型/TF-GridNet|TF-GridNet]]；ArrayDPS 的单通道前驱是 StoRM（Gerkmann 组）与 Diffiner（Sony）。
- **工业产品交叉**：AMDM-SE 的判别式基线 CA Dense U-Net 来自 Amazon；[[方向/AI语音/模型/MeCo|MeCo]]（KAIST，Jung-Woo Choi 组）构建在 FlowSE/MeanFlowSE 开源生态上。

对本方向目标场景的推论：**"多通道判别前端 + 生成精修"的两个槽位可以分别从两条线选型**——前端从阵列线（[[方向/AI语音/模型/TF-GridNet|TF-GridNet]]/[[方向/AI语音/模型/McNet|McNet]]/[[方向/AI语音/模型/SpatialNet|SpatialNet]]），精修从 LM/生成线（扩散先验、语义 token、幻觉控制），两边的成熟件已有合作先例（ArrayDPS、PGUSE）。

## 5. 如果只跟踪三个

出论文必看：[[方向/AI语音/团队/Z.-Q. Wang Group（Zhong-Qiu Wang 组）|Z.-Q. Wang 组]]、[[方向/AI语音/团队/UPB Haeb-Umbach Group（帕德博恩大学 Haeb-Umbach 组）|Paderborn]] + [[方向/AI语音/团队/NTT Speech Group（NTT 语音组）|NTT]] 这条线、[[方向/AI语音/团队/Meta Audio AI（Meta 音频 AI 团队）|Meta Pandey 组]]。

## 6. 待深挖

- "LM 化增强"谱系补全：[[方向/AI语音/模型/SELM|SELM]]、[[方向/AI语音/模型/GenSE|GenSE]]、LLaSE-G1、[[方向/AI语音/模型/AnyEnhance]] 等工作的团队归属与相互关系（2026-08 未逐一核实）。

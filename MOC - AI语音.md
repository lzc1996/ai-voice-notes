---
title: MOC - AI语音
date: 2026-10-29
tags:
  - MOC
  - 类型/索引
  - 类型/方向
  - 方向/AI语音
aliases:
  - AI 语音地图
  - AI Speech MOC
  - 语音方向地图
---

# MOC - AI语音

← [[MOC - 研究前沿]]

> [!info] 地图说明
> 本页是「方向/AI语音」的方向级导航，按 **子方向 → 知识层 → 对象库** 三层组织，不重复列 479 篇明细。
> 篇数按目录内 `.md` 计（2026-10-29 核查）：模型 194、知识 169、评估 43、数据集 22、团队 15、工具 14、实证研究 8、选型 6、思考 2、信息源 2，合计 479。
> 目录职责分工见 [[方向/AI语音/README|AI语音目录组织规则]]；语音增强方向的边界、目标场景与方案速查见 [[方向/AI语音增强/README|AI 语音增强]]。

## 子方向入口

- **语音增强** — [[方向/AI语音增强/README|AI 语音增强]]：当前主线，2026-10 起转向阵列无关 + LLM 化；阵列增强的 SOTA、工业界与路线优先级见下方「语音增强主线」。
- **ASR** — [[方向/AI语音/MOC - ASR|MOC - ASR]]：转写、时间戳、热词、会议链路；对标 WER/CER，不以质量指标为终点。
- **TTS** — [[方向/AI语音/MOC - TTS|MOC - TTS]]：可控 TTS、声音克隆与评估框架。
- **音频大模型** — [[方向/AI语音/MOC - 音频大模型|MOC - 音频大模型]]：音频 LLM、Omni 架构与通用音频理解基准。
- **评估** — [[方向/AI语音/评估/README|AI语音评估]]：指标体系、benchmark 与挑战赛的分层索引。

## 语音增强主线（当前活跃）

**路线判断**

- [[方向/AI语音/知识/技术路线/Array SE Roadmap（阵列语音增强技术路线优先级）|Array SE Roadmap]]：阵列增强路线的优先级排序。
- [[方向/AI语音/知识/技术路线/Array-Agnostic SE（阵列无关语音增强）|Array-Agnostic SE]]：跨通道数/几何泛化的路线本体。
- [[方向/AI语音/知识/技术路线/阵列可变方案技术路线概览图|阵列可变方案技术路线概览图]] 与 [[方向/AI语音/知识/技术路线/阵列可变技术路线热度趋势图|热度趋势图]]：路线图与热度走势。

**固定阵列：判别式与混合**

- [[方向/AI语音/知识/技术路线/Hybrid Array SE（传统神经混合阵列增强）|Hybrid Array SE]]：传统 DSP + 神经模块的混合范式。
- [[方向/AI语音/知识/技术路线/Efficient Multichannel SE（多通道语音增强高效化）|Efficient Multichannel SE]]：低延迟、低算力约束下的多通道路线。
- [[方向/AI语音/知识/技术路线/Real-Data Array SE（真实数据驱动阵列增强）|Real-Data Array SE]]：真实录音替代仿真 RIR 的数据策略。
- [[方向/AI语音/知识/技术路线/Spatial-Guided SE（空间引导与多模态增强）|Spatial-Guided SE]]：空间线索与多模态引导。

**阵列无关**

- [[方向/AI语音/知识/调研与地图/Array-Agnostic SE SOTA（阵列可变语音增强SOTA调研）|Array-Agnostic SE SOTA]]：论文侧 SOTA 盘点。
- [[方向/AI语音/知识/调研与地图/Array-Agnostic SE Industry（工业界阵列可变语音增强调研）|Array-Agnostic SE Industry]]：工业界方案盘点。

**生成式**

- [[方向/AI语音/知识/技术路线/Generative Multichannel SE（生成式多通道语音增强）|Generative Multichannel SE]]：生成式多通道主线。
- [[方向/AI语音/知识/生成式语音增强/SE Generative Prior（语音增强生成先验）|SE Generative Prior]]：生成先验的分类与用法。
- [[方向/AI语音/知识/生成式语音增强/DPS（扩散后验采样）|DPS（扩散后验采样）]] 与 [[方向/AI语音/知识/生成式语音增强/DiT 与语音增强（DiT-based Speech Enhancement）|DiT 与语音增强]]：扩散/流匹配的逆问题与骨干。

**LLM 化训练配方**

- [[方向/AI语音/知识/技术路线/LLM-SE Training Recipe v2（显式解耦训练配方）|LLM-SE Training Recipe v2]]：显式解耦的四阶段配方总纲。
- 分阶段：[[方向/AI语音/知识/技术路线/LLM-SE Stage 0（表示空间准备）|Stage 0 表示空间]]、[[方向/AI语音/知识/技术路线/LLM-SE Stage 1（Clean Speech Token LM 预训练）|Stage 1 LM 预训练]]、[[方向/AI语音/知识/技术路线/LLM-SE Stage 2（多退化条件重建）|Stage 2 多退化重建]]、[[方向/AI语音/知识/技术路线/LLM-SE Stage 3（声学保真）|Stage 3 声学保真]]、[[方向/AI语音/知识/技术路线/LLM-SE Stage 4（感知与偏好对齐）|Stage 4 感知对齐]]。
- [[方向/AI语音/知识/技术路线/LLM 与 Agent 对语音增强的影响|LLM 与 Agent 对语音增强的影响]]：范式层面的判断。
- [[方向/AI语音/知识/技术路线/LLM Backbone（使用 LLM 作为骨干训练其他任务）|LLM Backbone]]：骨干复用与 tokenizer 适配。

**分布式与异步**

- [[方向/AI语音/知识/技术路线/Distributed Multichannel SE（分布式异步多通道增强）|Distributed Multichannel SE]]：多设备异步组阵的边界条件。

## 知识层

- **基础概念**（108 篇）— 入口 [[方向/AI语音/知识/基础概念/SE（语音增强）导论|SE（语音增强）导论]]；相邻任务 [[方向/AI语音/知识/基础概念/SS（语音分离）|SS（语音分离）]]、[[方向/AI语音/知识/基础概念/TSE（目标说话人提取）|TSE（目标说话人提取）]]；前端与信号处理 [[方向/AI语音/知识/基础概念/CBF（卷积波束形成）|CBF]]、[[方向/AI语音/知识/基础概念/MVDR（最小方差无失真响应）|MVDR]]、[[方向/AI语音/知识/基础概念/DMA（差分麦克风阵列）|DMA]]、[[方向/AI语音/知识/基础概念/AEC（声学回声消除）|AEC]]、[[方向/AI语音/知识/基础概念/AGC（自动增益控制）|AGC]]。
- **技术路线**（24 篇）— 见上方「语音增强主线」；跨任务通用件 [[方向/AI语音/知识/技术路线/语音网络结构与模块|语音网络结构与模块]]、[[方向/AI语音/知识/技术路线/语音生成 tokenizer codec 技术路线|语音生成 tokenizer codec 技术路线]]。
- **调研与地图** — 全景：[[方向/AI语音/知识/调研与地图/Array Speech Enhancement Frontier（阵列语音增强前沿调研）|阵列语音增强前沿调研]]、[[方向/AI语音/知识/调研与地图/Array Speech Enhancement Survey Report（阵列语音增强技术调研报告）|阵列语音增强技术调研报告]]；盘点：[[方向/AI语音/知识/调研与地图/Array SE SOTA（阵列语音增强SOTA调研）|Array SE SOTA]]、[[方向/AI语音/知识/调研与地图/Array Speech Enhancement Industry（阵列语音增强工业界方案）|Array Speech Enhancement Industry]]、[[方向/AI语音/知识/调研与地图/Personalized SE（个性化语音分离产品线调研）|Personalized SE]]、[[方向/AI语音/知识/调研与地图/SE SOTA（语音增强模型表现）|SE SOTA]]；组织：[[方向/AI语音/知识/调研与地图/Array Speech Enhancement Team Map（阵列增强团队地图）|阵列增强团队地图]]。
- **生成式语音增强**（4 篇）— 专题整理层，见上方「生成式」。

## 对象库

- **模型**（194 篇）— 阵列增强主线：[[方向/AI语音/模型/ArrayDPS-Refine]]、[[方向/AI语音/模型/ArrayDPS]]、[[方向/AI语音/模型/Uni-ArrayDPS]]、[[方向/AI语音/模型/AMDM-SE]]、[[方向/AI语音/模型/ARiSE]]、[[方向/AI语音/模型/DeFTAN-AA]]、[[方向/AI语音/模型/GAP-URGENet]]、[[方向/AI语音/模型/AuK]]、[[方向/AI语音/模型/Geo-DConv]]、[[方向/AI语音/模型/FlexIO]]；LLM 化：[[方向/AI语音/模型/UniSE（Unified Speech Enhancement）|UniSE]]、[[方向/AI语音/模型/MaskSR]]、[[方向/AI语音/模型/L3-SE|L3-SE]]。
- **数据集**（22 篇）— 阵列/会议：[[方向/AI语音/数据集/RealMAN]]、[[方向/AI语音/数据集/AMI Meeting Corpus（会议语料库）|AMI Meeting Corpus]]、[[方向/AI语音/数据集/AISHELL-4]]、[[方向/AI语音/数据集/LibriCSS]]、[[方向/AI语音/数据集/SMS-WSJ]]；单通道基线：[[方向/AI语音/数据集/VoiceBank-DEMAND]]。
- **评估**（43 篇）— 索引 [[方向/AI语音/评估/README|AI语音评估]]；SE 常用 [[方向/AI语音/评估/PESQ]]、[[方向/AI语音/评估/SI-SDR]]、[[方向/AI语音/评估/OVRL_MOS]]、[[方向/AI语音/评估/RTF（实时率）]]；挑战赛 [[方向/AI语音/评估/URGENT（通用语音增强挑战）|URGENT]]、[[方向/AI语音/评估/CHiME（语音分离与识别挑战赛）|CHiME]]、[[方向/AI语音/评估/ECHI（助听对话增强）|ECHI]]、[[方向/AI语音/评估/Clarity Enhancement Challenge（助听器语音增强挑战赛）|Clarity]]。
- **团队**（15 篇）— [[方向/AI语音/团队/Z.-Q. Wang Group（Zhong-Qiu Wang 组）|Z.-Q. Wang 组]]、[[方向/AI语音/团队/UIUC SiNRG（UIUC 信号推断研究组）|UIUC SiNRG]]、[[方向/AI语音/团队/BGU Speech Enhancement Group（本古里安大学语音增强组）|BGU]]、[[方向/AI语音/团队/NJU Acoustics（南京大学声学所）|NJU Acoustics]]、[[方向/AI语音/团队/Audio-WestlakeU（西湖大学音频实验室）|Audio-WestlakeU]]。
- **工具**（14 篇）— [[方向/AI语音/工具/Audio Speech Analysis Toolchain（音频语音分析工具链）|音频语音分析工具链]]。
- **信息源**（2 篇）— [[方向/AI语音/信息源/语音会议与期刊|语音会议与期刊]]、[[方向/AI语音/信息源/Interspeech|Interspeech]]。
- **选型**（6 篇）— [[方向/AI语音/选型/LLM-SE 架构选型调研（统一音频模型对比）|LLM-SE 架构选型调研]]、[[方向/AI语音/选型/ASR 模型选型矩阵|ASR 模型选型矩阵]]、[[方向/AI语音/选型/Qwen 语音模型技术路线图|Qwen 语音模型技术路线图]]。
- **实证研究**（8 篇，2026-10-29 由 `论文/` 改名）— 非模型论文证据页（假设验证/机制分析/对比评测），入口 [[方向/AI语音/实证研究/Toward Universal Speech Enhancement for Diverse Input Conditions（通用语音增强开山作）|通用语音增强开山作]]、[[方向/AI语音/实证研究/Less is More（语音增强数据筛选）|Less is More（数据筛选）]]。
- **思考**（2 篇）— [[方向/AI语音/思考/UniSE-vs]]、[[方向/AI语音/思考/Error-Correcting Speech Token（可纠错语音 Token）|Error-Correcting Speech Token]]。

## 相关工程

- [[工程/阵列可变语音增强业务对齐清单]]：阵列可变方案落地的业务口径与验收条件（进行中）。
- [[阵列无关语音增强-组会/阵列无关语音增强-组会.pptx|阵列无关语音增强组会]]：2026-10-26 汇报稿。

## 待深挖

- 模型页 194 篇缺一份「模型族谱」：按 判别式 / 生成式 / 混合 / 阵列无关 四类挂到路线页，现在只能靠文件名检索。
- 评估侧缺一张「指标 × 场景」对照表：PESQ/SI-SDR 与 DNSMOS/OVRL_MOS 在阵列场景的可比性边界尚未成页。
- 「固定阵列 + LLM 端到端 + 质量终点」仍是空位，是否要为它单开一条技术路线页待定。

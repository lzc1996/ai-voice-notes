---
title: MOC - 音频大模型
aliases:
  - 音频大模型地图
  - Audio LLM
  - LALM
  - Large Audio Language Model
  - Audio Foundation Model
  - 音频大语言模型
tags:
  - MOC
  - 类型/索引
  - 类型/方向
  - 方向/AI语音
---

# MOC - 音频大模型

## 研究边界

音频大模型（LALM，Large Audio Language Model）指以 LLM 为推理主干、把音频作为一等输入的模型家族：音频理解（转写、声学事件、情感）、音频生成（TTS、音乐音效）、语音对话（全双工实时交互）和全模态 Omni 模型。覆盖音频表示（tokenizer/codec/SSL）、架构形态（encoder+LLM、LLM+generator、统一 encoder+LLM+decoder）、后训练（SFT/RL/GRPO）与信任安全。

不把经典信号处理（波束形成、降噪）和 [[方向/AI语音/MOC - ASR|ASR]] / [[方向/AI语音/MOC - TTS|TTS]] 的任务细节作为主线；它们作为组件、评测基线或路线对照保留。

## 核心问题

- 三条技术路线怎么选：**ASR cascade**（转写→文本 LLM→TTS）、**codec token 神经语言模型**（[[方向/AI语音/模型/AudioLM|AudioLM]]/[[方向/AI语音/模型/Moshi|Moshi]] 线）、**端到端语音原生**（[[Qwen2.5-Omni|Qwen2.5-Omni]] / Gemini Live / OpenAI Realtime 线）。
- Omni 模型与专用 ASR/TTS 的拆分边界（见 [[方向/AI语音/选型/Omni vs ASR TTS 专用模型选型|Omni vs ASR TTS 专用模型选型]]）。
- 音频表示的选择：离散 codec token（压缩丢失声学细节、安全面更小）vs 连续 latent（保细节、对抗面更大）。
- 空间音频理解：如何在保留单声道语义能力的同时注入空间线索？双耳、FOA 与任意阵列表示分别适合什么场景，如何验证模型真正利用空间信息而非语言先验？
- 实时全双工：首包延迟、打断、流式解码如何达到可用（[[方向/AI语音/模型/Moshi|Moshi]] 160–200ms → [[方向/AI语音/模型/Qwen3-Omni|Qwen3-Omni]] 234ms 首包；工程拆解见 [[工程/语音 Agent 实时链路|语音 Agent 实时链路]]）。
- 推理能力：Audio-CoT、潜在空间推理、RL/GRPO 后训练（[[方向/AI语音/模型/Step-Audio R1|Step-Audio R1]] 线）是否成为下一阶段主线（见 [[方向/AI语音/知识/技术路线/Audio Reasoning（音频推理）|Audio Reasoning（音频推理）]]）。
- 评估碎片化：WER/延迟/MOS 各厂商自测，缺统一基准；[[方向/AI语音/评估/SUPERB（语音处理通用性能基准）|SUPERB]]/[[方向/AI语音/评估/HEAR（音频表示整体评估）|HEAR]]/[[方向/AI语音/评估/AudioBench（音频大模型通用基准）|AudioBench]]/[[方向/AI语音/评估/MMAU（大规模多任务音频理解与推理基准）|MMAU]]/[[方向/AI语音/评估/MMAR（音频深度推理基准）|MMAR]]/[[方向/AI语音/评估/SAKURA（语音多跳推理基准）|SAKURA]] 尚未收敛。
- 信任与安全：跨模态越狱、音频后门、生物特征隐私；攻击研究远超前于防御（见 [[方向/AI语音/知识/调研与地图/LALM Trust and Safety（音频大模型信任与安全）|LALM Trust and Safety]]）。

## 对象地图

### Omni 与语音交互

- [[方向/AI语音/模型/StepAudio 2.5|StepAudio 2.5]]：统一音频-语言模型，ASR/TTS/实时交互一体，MTP-5 加速解码。
- [[方向/AI语音/模型/Moshi|Moshi]]：codec token 路线标杆，单模型全双工（理论 160ms / 实测约 200ms）。
- [[Qwen2.5-Omni|Qwen2.5-Omni]] / [[方向/AI语音/模型/Qwen3-Omni|Qwen3-Omni]] / [[方向/AI语音/模型/Qwen3.5-Omni|Qwen3.5-Omni]]：Qwen Omni 端到端语音原生路线（Thinker-Talker；Qwen3.5-Omni 走 API 化长上下文与 ARIA 流式语音升级）。
- [[方向/AI语音/模型/LongCat-Next]]：DiNA 原生离散多模态模型，覆盖视觉、音频和语音交互，用于对照 Qwen / MiniCPM Omni 线。
- [[方向/AI语音/模型/Ming-Flash-Omni]]：Inclusion AI 100B/6B active 开源 Omni-MLLM，覆盖 video/audio/image 理解与 image/audio 生成。
- [[方向/AI语音/模型/Mini-Omni|Mini-Omni]] / [[方向/AI语音/模型/LLaMA-Omni|LLaMA-Omni]]：2024 开源社区追赶 GPT-4o 的小型可复现实现。
- [[方向/AI语音/模型/GLM-4-Voice|GLM-4-Voice]] / [[方向/AI语音/模型/Kimi-Audio|Kimi-Audio]] / [[方向/AI语音/模型/MiniCPM-o|MiniCPM-o]] / [[方向/AI语音/模型/Voxtral|Voxtral]] / [[方向/AI语音/模型/VocalNet|VocalNet]]：开源线补全（端到端对话、通用音频底座、端侧全双工、生产转写、MTP 加速）。
- [[方向/AI语音/模型/OpenAI Realtime|OpenAI Realtime]] / [[方向/AI语音/模型/Gemini Live|Gemini Live]]：商业实时语音 API 双标杆。
- [[方向/AI语音/模型/Step-Audio R1|Step-Audio R1]]：RLVR 解锁音频推理的标志性模型。

### 统一理解、生成与编辑

- [[方向/AI语音/模型/SpeechX|SpeechX]]：Microsoft neural codec language model，把 zero-shot TTS、noise suppression、TSE、speech removal、speech editing 放到 task-dependent prompting 的统一语音生成框架。
- [[方向/AI语音/模型/CosyEdit|CosyEdit]]：基于 CosyVoice 300M 通过 task-specific post-training 解锁的端到端语音编辑模型，支持多段插入、删除和替换。
- [[方向/AI语音/模型/UALM]] / [[方向/AI语音/模型/Audex]]：NVIDIA 统一音频理解、生成与推理模型线，重点看 audio 扩展后文本能力是否回退。
- [[方向/AI语音/模型/UniAudio]] / [[方向/AI语音/模型/UniAudio 2.0]]：从 ICML 2024 统一音频生成，到 ReasoningCodec + 统一自回归 text-audio 架构的理解/生成一体化。
- [[方向/AI语音/模型/DualSpeechLM]]：USTokenizer + dual-token modeling，用语义 USToken 输入和 acoustic token 输出统一语音理解/生成。
- [[方向/AI语音/模型/Ming-UniAudio]]：MingTok-Audio 连续统一语音表示 + per-token diffusion head，统一 speech understanding / generation / free-form editing。
- [[方向/AI语音/模型/AuK]]：腾讯混元开源统一语音生成与编辑基座（1.5B MMDiT+DiT、Qwen2.5-Omni 语义条件 + AuK-VAE、MIT 权重），一套指令接口覆盖生成/编辑/增强/分离，附 4 步蒸馏版 AuK-Flash。
- [[方向/AI语音/知识/基础概念/Decoupled DMD（解耦分布匹配蒸馏）]]：AuK-Flash 使用的少步生成蒸馏方法；区分原始 CA/DM 解耦机制与 AuK 的任务路由配方。
- [[方向/AI语音/模型/Stable Audio 3|Stable Audio 3]]：通用音频/音乐生成线。
- [[方向/AI语音/模型/MMAudio|MMAudio]]：video-to-audio / text-to-audio，给 silent video 生成同步音效。
- [[方向/AI语音/模型/StoRM|StoRM]]：扩散式语音生成，对照 codec LM 路线的生成建模。

### 空间音频理解

- [[方向/AI语音/模型/Spatial-Omni|Spatial-Omni]]：保留基座原音频编码器，以并行 SO-Encoder 把 FOA 注入为独立空间模态；配套 SO-Dataset、SO-QA 与 16 任务 SO-Bench。
- [[方向/AI语音/模型/PhaseCoder|PhaseCoder]]：输入原始多通道音频与麦克风坐标，以 geometry-agnostic spatial tokens 支持空间推理和定向转写。
- [[方向/AI语音/模型/MiDashengLM-Spatial|MiDashengLM-Spatial]]：双耳语义—空间双分支 LALM，以 HSSC 融合通用音频理解与空间感知。

### 专用语音模型

- [[方向/AI语音/模型/GPT-4o Transcribe|GPT-4o Transcribe]]：OpenAI 云端 speech-to-text 模型线。
- [[方向/AI语音/模型/Seed-ASR|Seed-ASR]]：ByteDance LLM-based ASR 前沿路线。
- [[方向/AI语音/模型/Qwen3-ASR|Qwen3-ASR]] / [[方向/AI语音/模型/Qwen3-TTS|Qwen3-TTS]]：从 Omni 拆分出的专用语音模型线。
- [[方向/AI语音/模型/Whisper|Whisper]]：ASR 通用基线。

### 音频表示与 tokenizer

- [[方向/AI语音/模型/Qwen-Audio-VAE|Qwen-Audio-VAE]]：通用音频生成底层表示。
- [[方向/AI语音/模型/HuBERT|HuBERT]] / [[方向/AI语音/模型/WavLM|WavLM]]：SSL 音频编码器，Omni 编码侧的常用底座。
- [[方向/AI语音/知识/技术路线/语音生成 tokenizer codec 技术路线|语音生成 tokenizer codec 技术路线]]：音频表示路线总入口。
- [[方向/AI语音/知识/技术路线/语音模型 tokenizer 与 LLM tokenizer 对比|语音模型 tokenizer 与 LLM tokenizer 对比]]：text/audio token 边界。
- [[方向/AI语音/模型/BiCodec|BiCodec]] / [[方向/AI语音/模型/X-Codec|X-Codec]] / [[方向/AI语音/模型/X-Codec2|X-Codec2]] / [[方向/AI语音/模型/UniAudio-Token]] / [[方向/AI语音/模型/S3 Tokenizer|S3 Tokenizer]]：离散音频 token 具体实现。
- [[方向/AI语音/知识/基础概念/FSQ（有限标量量化）]] / [[方向/AI语音/知识/基础概念/RVQ（残差向量量化）]]：codec / tokenizer 的量化机制对照。

### 技术路线、评测与工程

- [[方向/AI语音/工具/Audio Speech Analysis Toolchain（音频语音分析工具链）|音频语音分析工具链]]：Praat、Audacity、librosa、torchaudio、WhisperX、pyannote.audio 等分析 / 对齐 / 评估入口。
- [[方向/AI语音/选型/Omni vs ASR TTS 专用模型选型|Omni vs ASR TTS 专用模型选型]]：架构选型判断。
- [[方向/AI语音/选型/Qwen 语音模型技术路线图|Qwen 语音模型技术路线图]]：Qwen 系 Omni→专用路线。
- [[方向/AI语音/知识/技术路线/Audio Reasoning（音频推理）|Audio Reasoning（音频推理）]]：Audio-CoT / 潜在推理 / RL 后训练路线与对下游的借鉴。
- [[工程/语音 Agent 实时链路|语音 Agent 实时链路]]：全双工、打断与首包延迟预算的工程地图。
- [[方向/AI语音/知识/调研与地图/LALM Trust and Safety（音频大模型信任与安全）|LALM Trust and Safety]]：威胁面分类、六支柱与防御现状。
- 评测基准组：[[方向/AI语音/评估/SUPERB（语音处理通用性能基准）|SUPERB]]、[[方向/AI语音/评估/HEAR（音频表示整体评估）|HEAR]]（表示时代）；[[方向/AI语音/评估/AudioBench（音频大模型通用基准）|AudioBench]]、[[方向/AI语音/评估/MMAU（大规模多任务音频理解与推理基准）|MMAU]]、[[方向/AI语音/评估/MMAR（音频深度推理基准）|MMAR]]、[[方向/AI语音/评估/SAKURA（语音多跳推理基准）|SAKURA]]、[[方向/AI语音/评估/MMAU-Pro（音频通用智能基准）|MMAU-Pro]]、[[方向/AI语音/评估/Dynamic-SUPERB（动态语音指令基准）|Dynamic-SUPERB]]、[[方向/AI语音/评估/SpeechR（语音推理基准）|SpeechR]]、[[方向/AI语音/评估/MMSU（口语理解推理基准）|MMSU]]（LALM 时代）；选用对照见 [[方向/AI语音/评估/音频大模型评测基准对比|音频大模型评测基准对比]]。
- [[方向/AI语音/MOC - ASR|ASR]] / [[方向/AI语音/MOC - TTS|TTS]]：任务子方向入口。

## 上下游

- 上游：[[方向/MOC - 大模型|大模型]] LLM 底座、SSL 编码器、audio tokenizer/codec、大规模语音数据（[[方向/AI语音/数据集/VoxBox|VoxBox]]、[[方向/AI语音/数据集/Emilia|Emilia]]）。
- 下游：语音 Agent、会议转写、视频理解、音乐音效生成、无障碍与客服。
- 相邻：[[方向/AI语音/MOC - ASR|ASR]]、[[方向/AI语音/MOC - TTS|TTS]]、[[方向/AI语音增强/README|AI 语音增强]]、[[方向/MOC - 大模型|大模型]] VLM、音视频联合生成。

## 关键来源

- [A Survey of Large Audio Language Models: Generalization, Trustworthiness, and Outlook](https://arxiv.org/abs/2605.20266)
  - 内容定位：2026 年最全面的 LALM 综述，覆盖架构、表示范式、对齐算法与信任安全分类。
  - 用途：建立领域总览与安全议题框架。
  - 核验日期：2026-08-06
- [A Survey of Audio Reasoning in Multimodal Foundation Models](https://www.semanticscholar.org/paper/A-Survey-of-Audio-Reasoning-in-Multimodal-Models-Guo-Cui/1a146621a95735f3964d86553c8b1fb156777586)
  - 内容定位：音频推理综述，覆盖 Audio-CoT、Step-Audio-R1、MMAU/MMAR/SAKURA 等。
  - 用途：推理能力维度的前沿追踪。
  - 核验日期：2026-08-06
- [Audio-Visual Intelligence in Large Foundation Models: A Comprehensive Survey](https://arxiv.org/abs/2605.04045)
  - 内容定位：NUS/牛津/微软等 9 机构音视频智能综述，2016–2026 演化树与三条技术线。
  - 用途：全模态与音视频联合生成的方向参照。
  - 核验日期：2026-08-06
- [LLM Audio Capabilities — SF Lexicon](https://sonicfield.org/wiki/llm-audio-capabilities)
  - 内容定位：三大架构阵营（ASR cascade / codec token / 端到端语音原生）与厂商能力盘点。
  - 用途：路线对比与产品侧选型。
  - 核验日期：2026-08-06
- [Speech-to-Speech Models](https://itzsid.github.io/speech-to-speech-review/)
  - 内容定位：SpeechGPT 到 Qwen3-Omni 的 13 个端到端语音对话模型时序综述。
  - 用途：模型谱系与延迟演进对照。
  - 核验日期：2026-08-06

## 待深挖

- 更多模型笔记候选：Freeze-Omni、SLAM-Omni、LLaMA-Omni2、Audio Flamingo 3、GLM 新版语音线、Voxtral 后续版本。
- 未收录基准补充：AIR-Bench、VocalBench、VoxParadox、SpeechParaling-Bench 等，并入 [[方向/AI语音/评估/音频大模型评测基准对比|基准对比表]]。
- RLVR 用于 ASR 上下文偏置/热词与长音频一致性的实证跟踪（见 [[方向/AI语音/知识/技术路线/Audio Reasoning（音频推理）|Audio Reasoning]] 待验证）。
- 端到端延迟本地复测方法落地（见 [[工程/语音 Agent 实时链路|语音 Agent 实时链路]] 待验证）。
- 音频水印部署与声音克隆合规政策跟踪（见 [[方向/AI语音/知识/调研与地图/LALM Trust and Safety（音频大模型信任与安全）|LALM Trust and Safety]] 待验证；衔接 [[方向/AI语音/MOC - TTS|TTS MOC]]）。

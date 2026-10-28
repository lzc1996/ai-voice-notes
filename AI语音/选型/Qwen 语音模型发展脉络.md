---
title: Qwen 语音模型发展脉络
类型: 概念
发表时间:
时间依据: 发展脉络综合笔记；各节点见正文时间线
aliases:
  - Qwen Audio timeline
  - Qwen speech model lineage
tags:
  - 类型/对象
  - 领域/AI语音
  - 主题/Qwen
---

# Qwen 语音模型发展脉络

## 1. 内容定位

这条线不是“先 ASR、后 TTS”的单点演进，而是 Qwen 把音频能力从“通用音频理解”推进到“端到端全模态交互”，再拆出专用 ASR/TTS 和云端生产模型的过程。

## 2. 一句话主线

Qwen 语音能力的演进路径是：**Qwen-Audio 做音频理解底座 → Qwen2-Audio 做语音交互入口 → Qwen2.5/3-Omni 统一理解与语音生成 → Qwen3-ASR/Qwen3-TTS 把识别和合成拆成专用开源模型 → Qwen-Audio-3.0-TTS/[[方向/AI语音/模型/Qwen3.5-Omni|Qwen3.5-Omni]] 走向云端生产与更大语言覆盖**。

## 3. 时间线

### 3.1. 2023-11：Qwen-Audio，音频进入 Qwen 家族

- 发布物：`Qwen-Audio`、`Qwen-Audio-Chat`。
- 技术定位：以 Qwen-7B 初始化 LLM，以 Whisper-large-v2 初始化音频编码器，面向语音、自然声、音乐、歌曲等通用音频理解。
- 关键能力：ASR、语音翻译、音频问答、音频描述、情绪识别、场景分类、词级时间戳等。
- 脉络意义：这是 Qwen 语音线的“感知底座”，重点在音频理解和文本输出，还不是自然语音输出系统。

### 3.2. 2024-07/08：Qwen2-Audio，进入语音聊天与音频分析

- 发布物：`Qwen2-Audio-7B`、`Qwen2-Audio-7B-Instruct`。
- 技术定位：Qwen-Audio 的下一代大规模 audio-language model。
- 交互形态：分成 voice chat 与 audio analysis 两种模式；voice chat 允许用户直接用语音给模型下指令，不需要外接 ASR 模块。
- 脉络意义：Qwen 从“音频任务模型”走向“语音交互模型”，但输出仍以文本为主。

### 3.3. 2025-03：Qwen2.5-Omni，统一多模态输入与自然语音输出

- 发布物：`Qwen2.5-Omni`。
- 技术定位：端到端全模态模型，能感知文本、图像、音频、视频，并流式生成文本和自然语音。
- 架构变化：引入 Thinker-Talker；Thinker 负责理解与文本生成，Talker 基于 Thinker 的表示流式生成语音 token。
- 脉络意义：这是 Qwen 语音线从“听懂音频”进入“能说话”的分水岭，后续 TTS 线可以看作对 Talker/语音生成能力的专用化。

### 3.4. 2025-09：Qwen3-Omni，成为 ASR/TTS 的全模态基础层

- 发布物：`Qwen3-Omni`。
- 技术定位：Thinker-Talker MoE 架构，统一文本、图像、音频、视频的理解与自然实时语音生成。
- 关键能力：在 36 个音频和音视频基准上覆盖 ASR、音频理解、语音对话等能力。
- 脉络意义：Qwen3-ASR 技术报告明确把 Qwen3-Omni 称为其 foundation model；Qwen3-Omni 是专用 ASR 模型继承音频理解能力的直接来源。

### 3.5. 2026-01-22：Qwen3-TTS，Qwen 第一条专用开源 TTS 线

- 发布物：`Qwen3-TTS-12Hz-1.7B/0.6B`、`Base`、`CustomVoice`、`VoiceDesign`、`Qwen3-TTS-Tokenizer-12Hz`。
- 技术定位：Qwen 系列首个专用文本转语音模型族，面向多语言、可控、鲁棒、流式 TTS。
- 关键能力：3 秒声音克隆、自然语言声音设计、instruction control、10 语言、低延迟流式首包。
- 脉络意义：Qwen 从 Omni 里的“会说话”拆出可独立部署、可微调、可克隆、可设计音色的 TTS 产品线。

### 3.6. 2026-01-29：Qwen3-ASR，Qwen 第一条专用开源 ASR 线

- 发布物：`Qwen3-ASR-1.7B`、`Qwen3-ASR-0.6B`、`Qwen3-ForcedAligner-0.6B`。
- 技术定位：基于 Qwen3-Omni 音频理解能力和大规模语音数据训练的 all-in-one ASR 模型族。
- 关键能力：语言识别、30 种语言、22 种中文方言、流式/离线统一推理、长音频、复杂声学环境、强制对齐。
- 脉络意义：Qwen 把 Omni 的泛音频理解拆成专用识别链路，并补上时间戳/对齐工具，适合工程系统替代 Whisper/FunASR 的部分场景。

### 3.7. 2026-04：Qwen3.5-Omni，云端全模态能力继续扩展

- 发布物：[[方向/AI语音/模型/Qwen3.5-Omni|Qwen3.5-Omni]]。
- 技术定位：Qwen-Omni 家族后续升级，扩大参数规模、上下文长度、音视频数据规模，并引入 ARIA 改善流式语音稳定性和韵律。
- 脉络意义：它不是 Qwen3-ASR/TTS 的简单替代，而是“全模态助手”方向的升级；在云端 ASR 场景中适合用 prompt context 处理领域术语，但混合/噪声/时间戳/说话人分离仍更适合专用 ASR 或 Fun-ASR。

### 3.8. 2026-07：Qwen-Audio-VAE 与 Qwen-Audio-3.0-TTS，走向生产级语音生成

- `Qwen-Audio-VAE`：低码率、快速编码的连续音频自编码器，面向通用音频生成底座，支持 speech/music/sound 的紧凑 latent 表示。
- `Qwen-Audio-3.0-TTS`：云端生产 TTS 系统，分 Flash 与 Plus；覆盖 16 种语言、20 个中文方言区域，支持自然语言指令、细粒度内联标签、噪声参考音频鲁棒克隆和长文本合成。
- 脉络意义：Qwen3-TTS 是开源专用 TTS；Qwen-Audio-3.0-TTS 是更偏云端生产的后续系统，重点从“可用的开源 TTS”推进到“多语言、低延迟、可控、鲁棒”的在线服务。

## 4. 分支理解

### 4.1. ASR 分支

- `Qwen-Audio`：先证明 Qwen 可以做 ASR、语音翻译、时间戳和通用音频理解。
- `Qwen2-Audio`：把音频理解包装成 voice chat / audio analysis 两种交互模式。
- `Qwen2.5-Omni` / `Qwen3-Omni`：把音频理解并入全模态模型，成为后续 ASR 的 foundation model。
- `Qwen3-ASR`：把识别能力专用化，面向本地部署、流式/离线统一推理、长音频和强制对齐。
- `QwenCloud ASR` / [[方向/AI语音/模型/Qwen3.5-Omni|Qwen3.5-Omni]]：云端路线分化为专用 ASR、Fun-ASR、Omni prompt-based transcription 三种技术栈。

### 4.2. TTS 分支

- `Qwen2.5-Omni`：Talker 让 Qwen 具备自然语音输出能力。
- `Qwen3-TTS`：把语音生成拆成独立 TTS 模型族，解决克隆、音色设计、可控和流式低延迟。
- `Qwen-Audio-3.0-TTS`：向云端生产推进，重点补多语言覆盖、方言、内联情绪/非语言标签、噪声参考克隆和长文本稳定性。
- `Qwen-Audio-VAE`：更底层的音频生成表示方向，可能支撑后续从 speech TTS 扩展到 general audio generation。

## 5. 工程判断

- 本地语音 Agent：优先组合 `Qwen3-ASR` + `Qwen3-TTS`，简单、可控、可离线。
- 需要视觉/音频/文本一体理解：优先 `Qwen3-Omni` 或 [[方向/AI语音/模型/Qwen3.5-Omni|Qwen3.5-Omni]]，不要强行拆 ASR/TTS。
- 生产 TTS：云端优先看 `Qwen-Audio-3.0-TTS-Flash/Plus`；本地和可微调优先看 `Qwen3-TTS`。
- 复杂会议转写：单独的 Qwen3-ASR 不等于完整会议系统；说话人分离、VAD、热词和后处理仍需要外部链路。

## 6. 相关对象

- [[方向/AI语音/选型/Qwen 语音模型技术路线图|Qwen 语音模型技术路线图]]：技术分工、选型边界和后续深挖入口。
- [[方向/AI语音/模型/Qwen-Audio-VAE|Qwen-Audio-VAE]]：Qwen 语音/音频生成的底层表示路线。
- [[方向/AI语音/模型/Qwen3-ASR|Qwen3-ASR]]：专用 ASR 分支。
- [[方向/AI语音/模型/Qwen3-TTS|Qwen3-TTS]]：专用 TTS 分支。
- [[方向/AI语音/模型/Qwen3.5-Omni|Qwen3.5-Omni]]：Omni 全模态云端升级分支。
- [[方向/大模型/LLM/模型/Qwen3|Qwen3]]：Qwen 模型家族入口。
- [[知识wiki/商业/DashScope 阿里云MaaS平台|DashScope 阿里云 MaaS 平台]]：QwenCloud / DashScope API 的平台上下文。

## 7. 来源

- [Qwen-Audio README](https://github.com/qwenlm/qwen-audio)
  - 内容定位：Qwen-Audio 官方仓库，记录 Qwen-Audio / Qwen-Audio-Chat、2023-11 发布节点、Qwen-7B + Whisper-large-v2 初始化和多任务音频理解评测。
  - 用途：追溯 Qwen 语音线的音频理解起点。
  - 核验日期：2026-07-24
- [Qwen2-Audio README](https://github.com/qwenlm/qwen2-audio)
  - 内容定位：Qwen2-Audio 官方仓库，记录 voice chat / audio analysis 两种交互模式、2024-07/08 发布节点和对 Qwen-Audio 的升级。
  - 用途：定位从音频理解到语音交互的过渡。
  - 核验日期：2026-07-24
- [Qwen2.5-Omni Technical Report](https://arxiv.org/abs/2503.20215)
  - 内容定位：Qwen2.5-Omni 技术报告，记录端到端全模态、Thinker-Talker、TMRoPE 和流式自然语音输出。
  - 用途：解释 TTS 能力从 Omni Talker 拆出的背景。
  - 核验日期：2026-07-24
- [Qwen3-Omni Technical Report](https://arxiv.org/abs/2509.17765)
  - 内容定位：Qwen3-Omni 技术报告，记录 Thinker-Talker MoE、音频/音视频基准和实时语音输出。
  - 用途：解释 Qwen3-ASR 的 foundation model 来源。
  - 核验日期：2026-07-24
- [Qwen3-TTS Technical Report](https://arxiv.org/abs/2601.15621)
  - 内容定位：Qwen3-TTS 技术报告，记录首个 Qwen 专用 TTS 模型族、5M 小时数据、10 语言、12Hz tokenizer 和 3 秒克隆/声音设计。
  - 用途：定位 TTS 专用化节点。
  - 核验日期：2026-07-24
- [Qwen3-ASR Technical Report](https://arxiv.org/abs/2601.21337)
  - 内容定位：Qwen3-ASR 技术报告，记录 0.6B/1.7B ASR、ForcedAligner、52 语言/方言、Qwen3-Omni foundation model 和 Apache-2.0 发布。
  - 用途：定位 ASR 专用化节点。
  - 核验日期：2026-07-24
- [Qwen3.5-Omni Technical Report](https://arxiv.org/abs/2604.15804)
  - 内容定位：Qwen3.5-Omni 技术报告，记录 Omni 家族升级、长上下文、音视频数据、ARIA 和更大语言覆盖。
  - 用途：定位专用 ASR/TTS 之外的全模态分支延续。
  - 核验日期：2026-07-24
- [Qwen-Audio-VAE Technical Report](https://arxiv.org/abs/2607.11738)
  - 内容定位：Qwen-Audio-VAE 技术报告，记录低码率连续音频 autoencoder、5M 小时多域音频和 12.5Hz latent 表示。
  - 用途：追踪后续通用音频生成底层表示方向。
  - 核验日期：2026-07-24
- [Qwen-Audio-3.0-TTS Release Blog](https://funaudiollm.github.io/qwen-audio-3.0-tts/)
  - 内容定位：Qwen-Audio-3.0-TTS 官方发布页，记录生产级 TTS、16 语言、20 中文方言区域、86 内联标签、3 分钟长文本和噪声参考鲁棒克隆。
  - 用途：定位 Qwen3-TTS 后的生产级云端 TTS 方向。
  - 核验日期：2026-07-24
- [Qwen-Audio-3.0-TTS - Alibaba Cloud Community](https://www.alibabacloud.com/blog/qwen-audio-3-0-tts-more-multilingual-easier-to-direct_603379)
  - 内容定位：Alibaba Cloud 官方说明，记录 2026-07-21 发布、Flash/Plus 两档、16 语言和生产控制能力。
  - 用途：确认云端产品化版本和可用性。
  - 核验日期：2026-07-24


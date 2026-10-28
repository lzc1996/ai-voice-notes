---
title: MOC - TTS
aliases:
  - Text-to-Speech
  - Speech Synthesis
  - 语音合成
  - 文本转语音
tags:
  - MOC
  - 类型/索引
  - 类型/方向
  - 方向/AI语音
  - 任务/TTS
---

# MOC - TTS

## 研究边界

TTS（Text-to-Speech，文本转语音/语音合成）关注把文本、音色条件、风格指令或参考音频转换成可听语音。这个方向覆盖文本规范化、语音生成建模、speaker/voice control、vocoder/codec/tokenizer、流式低延迟、长文本稳定性和安全授权。

不把 [[方向/AI语音/MOC - ASR|ASR]]、语音增强、通用音效/音乐生成作为主线；这些只作为输入输出链路、底层音频表示或评估关系保留。

## 核心问题

- 文本到语音的建模链路应当拆成文本前端、声学/生成模型、audio tokenizer 或 vocoder，还是端到端统一生成。
- 低延迟流式 TTS、长文本自然度、音色一致性和多语言稳定性之间如何取舍。
- 声音克隆、VoiceDesign、情绪/风格控制是否能被可靠评估并进入产品。
- TTS 在语音 Agent 中应作为独立工程组件，还是并入 Omni 模型直接输出语音。
- 参考音频授权、水印、名人声音限制和滥用检测如何进入工程链路。

## 种子对象

- [[方向/AI语音/模型/Qwen3-TTS|Qwen3-TTS]]：当前已有的专用 TTS 模型线索引，覆盖开源模型、云端 TTS/API、声音克隆和 VoiceDesign。
- [[方向/AI语音/模型/F5-TTS|F5-TTS]]：flow matching + DiT 的非自回归 TTS 基线；filler token 隐式对齐、24 kHz/100 维 mel 配方和推理期 [[方向/AI语音/知识/基础概念/Sway Sampling（摇摆采样）|Sway Sampling]] 被大量下游工作沿用。
- [[方向/AI语音/知识/基础概念/Zero-shot Voice Cloning（零样本声音克隆）|Zero-shot Voice Cloning]]：声音克隆任务概念页，区分参考音频克隆、VoiceDesign、voice conversion 和微调。
- [[方向/AI语音/模型/X-VC|X-VC]]：zero-shot streaming voice conversion，在 codec latent space 中做实时目标音色迁移。
- [[方向/AI语音/模型/CosyVoice|CosyVoice]]：FunAudioLLM / QwenAudio 多语言 TTS 家族，覆盖 v1 supervised semantic tokens、v2 streaming、v3 in-the-wild 多语言方言生成。
- [[方向/AI语音/模型/Spark-TTS|Spark-TTS]]：LLM-based TTS，使用 [[方向/AI语音/模型/BiCodec|BiCodec]] 单流解耦语音 token，适合作为可控 TTS 和 voice cloning 对比对象。
- [[方向/AI语音/模型/ZONOS2|ZONOS2]]：Zyphra 的 8B sparse MoE TTS / voice cloning 模型，适合跟 Qwen3-TTS、Spark-TTS、CosyVoice 做开权重声音克隆对比。
- [[方向/AI语音/数据集/VoxBox|VoxBox]]：Spark-TTS 引入的大规模中英可控 TTS 数据集，约 100k 小时并带属性 metadata。
- [[方向/AI语音/数据集/Emilia|Emilia]]：Amphion 发布的大规模多语言 in-the-wild speech generation 数据集，适合作为 TTS 训练语料和数据清洗管线参考。
- [[方向/AI语音/数据集/LibriTTS|LibriTTS]]：OpenSLR 托管的经典英文多说话人 TTS 语料，约 585 小时、24 kHz，另有音质增强版 LibriTTS-R。
- [[方向/AI语音/模型/StepAudio 2.5|StepAudio 2.5]]：统一音频-语言模型，覆盖 ASR、TTS 和实时语音交互，适合比较统一模型里的 TTS 能力和专用 TTS 的边界。
- [[方向/AI语音/模型/MaskGCT|MaskGCT]]：全非自回归 mask-and-predict codec TTS，免对齐、免时长预测的免转录克隆路线早期代表；权重 CC-BY-NC。
- [[方向/AI语音/模型/XTTS-v2|XTTS-v2]]：Coqui 的 16 语言 zero-shot 克隆基线（Tortoise 系），免转录路线最早被广泛部署的开源模型；权重 CPML 非商用，公司已于 2024-01 关停。
- [[方向/AI语音/模型/Confucius4-TTS|Confucius4-TTS]]：网易有道的 14 语言免转录跨语言克隆模型（speaker encoder + flow matching），Apache 2.0 可商用。
- [[方向/AI语音/评估/可控 TTS 与声音克隆评估框架|可控 TTS 与声音克隆评估框架]]：产品化评估入口，用于看声音克隆、VoiceDesign、情绪/风格控制是否稳定。
- [[方向/AI语音/知识/基础概念/Vocoder（声码器）|声码器]]：TTS 输出侧模块，把 mel、latent 或 codec token 还原成可听波形。
- [[方向/AI语音/知识/基础概念/MPD（Multi-Period Discriminator，多周期判别器）|MPD]]：HiFi-GAN 中约束 waveform 周期性与谐波结构的多周期判别器集合。
- [[方向/AI语音/知识/基础概念/LSGAN（Least Squares GAN，最小二乘生成对抗网络）|LSGAN]]：以最小二乘目标替代交叉熵的对抗训练损失；AuK-VAE 将其与 MPD/CQT 判别器组合。
- [[方向/AI语音/模型/BigVGAN|BigVGAN]]：NVIDIA 通用 GAN vocoder，常作为 `mel -> waveform` 输出头。
- [[方向/AI语音/模型/S3 Tokenizer|S3 Tokenizer]]：CosyVoice 使用的 supervised semantic speech tokenizer。
- [[方向/AI语音/知识/技术路线/语音生成 tokenizer codec 技术路线|语音生成 tokenizer codec 技术路线]]：底层音频表示路线，解释低帧率 tokenizer、codec token 和连续 latent 的取舍。
- [[方向/AI语音/知识/技术路线/语音模型 tokenizer 与 LLM tokenizer 对比|语音模型 tokenizer 与 LLM tokenizer 对比]]：区分输入 text tokenizer 和输出 audio tokenizer/latent。
- [[方向/AI语音/模型/Qwen-Audio-VAE|Qwen-Audio-VAE]]：更偏通用音频生成底层表示，和专用 TTS tokenizer 形成对照。
- [[方向/AI语音/模型/MiniMax-Speech|MiniMax-Speech]]：MiniMax 的 AR Transformer 零样本克隆 TTS，可学习 speaker encoder 免转录，提出 [[方向/AI语音/知识/基础概念/Flow-VAE（流增强变分自编码器）|Flow-VAE]] 连续 latent 路线。
- [[方向/AI语音/知识/基础概念/Flow-VAE（流增强变分自编码器）|Flow-VAE]]：MiniMax-Speech 式 waveform→continuous latent 表示，用可逆 flow 在变换后验上施加 KL，再交给 latent flow matching 生成。
- [[方向/AI语音/选型/Omni vs ASR TTS 专用模型选型|Omni vs ASR TTS 专用模型选型]]：语音 Agent 里是否拆 ASR/LLM/TTS 三层的架构判断。
- [[方向/AI语音/数据集/OpenSLR|OpenSLR]]：公开语音与语言资源索引，可作为 TTS/ASR 数据入口。
- [[方向/AI语音/工具/Audio Speech Analysis Toolchain（音频语音分析工具链）|音频语音分析工具链]]：Praat、MFA、ELAN、librosa 和 torchaudio 等音色 / 对齐 / 标注 / 特征检查入口。

## 上下游

- 上游：文本规范化、韵律/标点处理、speaker embedding、参考音频、音频 tokenizer/codec、[[方向/AI语音/数据集/OpenSLR|OpenSLR]]。
- 下游：语音 Agent、播报、客服、长文本朗读、声音克隆、可控角色音色、无障碍读屏。
- 相邻方向：[[方向/AI语音/MOC - ASR|ASR]]、语音增强、说话人识别、[[方向/AI语音/知识/基础概念/SS（语音分离）|语音分离]]、通用音频生成（[[方向/AI语音/模型/Stable Audio 3|Stable Audio 3]]）、声音编辑。

## 关键资源

- [Qwen3-TTS README](https://github.com/QwenLM/Qwen3-TTS)
  - 内容定位：官方开源仓库，记录模型家族、推理、微调、评测和 Citation。
  - 用途：本地部署、开源模型选择和能力边界。
  - 核验日期：2026-07-28
- [Qwen3-TTS Technical Report](https://arxiv.org/abs/2601.15621)
  - 内容定位：技术报告，记录多语言 TTS、声音克隆、12Hz tokenizer、低延迟流式架构和训练规模。
  - 用途：判断模型能力、架构和评测结论。
  - 核验日期：2026-07-28
- [Text-to-speech models - QwenCloud](https://docs.qwencloud.com/developer-guides/speech/tts-models)
  - 内容定位：QwenCloud TTS 模型选择页，比较 Qwen-Audio-TTS、CosyVoice、Qwen3-TTS、声音克隆、声音设计和 instruction control。
  - 用途：云端 API 选型和模型 ID 查询。
  - 核验日期：2026-07-28
- [OpenSLR Resources](https://www.openslr.org/resources.php)
  - 内容定位：官方资源索引，按 SLR 编号列出语音、文本、音频、软件和辅助资源。
  - 用途：检索可复用公开语音资源。
  - 核验日期：2026-07-28

## 待深挖

- 是否需要单独建立 TTS 数据集清单：[[方向/AI语音/数据集/VoxBox|VoxBox]]、[[方向/AI语音/数据集/Emilia|Emilia]]、[[方向/AI语音/数据集/LibriTTS|LibriTTS]]、LJSpeech、[[方向/AI语音/数据集/VCTK|VCTK]]、AISHELL-3、WenetSpeech4TTS。
- 是否需要拆出传统 TTS 架构笔记：Tacotron、[[方向/AI语音/模型/FastSpeech|FastSpeech]]、VITS、Diffusion/Flow TTS、Neural Codec LM。
- 产品评估是否优先围绕“声音克隆 + 低延迟 Agent + 长文本朗读”三类场景展开。
- TTS 安全策略是否需要单独沉淀：授权、名人声音、音频水印、检测器和审计日志。

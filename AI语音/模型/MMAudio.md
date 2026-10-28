---
title: MMAudio
类型: 模型
参数量: 157M
发表时间: 2024-12-19
时间依据: arXiv 首次提交日；CVPR 2025 收录
任务:
  - 音频生成
  - 音视频生成
  - Video-to-Audio
  - Text-to-Audio
相关主题:
  - Flow Matching
  - 多模态联合训练
  - 音画同步
开放状态:
  - paper
  - code
  - weights
  - demo
许可证:
  - code: MIT
  - checkpoints: CC-BY-NC 4.0
aliases:
  - "MMAudio: Taming Multimodal Joint Training for High-Quality Video-to-Audio Synthesis"
  - Taming Multimodal Joint Training for High-Quality Video-to-Audio Synthesis
  - MM Audio
tags:
  - 类型/对象
  - 方向/AI语音
  - 任务/音频生成
  - 任务/音视频生成
  - 主题/生成模型
---

# MMAudio

## 0. 背景

- **V2A 公共模型强基线**：论文称在公开 video-to-audio 模型中，在音频质量、语义对齐和音画同步上达到新 SOTA。
- **联合训练不伤 T2A**：论文特别强调 text-to-audio 也有竞争力，说明视频/文本联合训练不是纯折中。
- **视频生成后处理价值高**：Sora、Veo、MovieGen、Hunyuan Video 等无声或弱声视频可以用 MMAudio 补音效，是视频生成 pipeline 的后处理模块。
- **和 raw waveform 路线互补**：[[方向/AI语音/模型/WavFlow|WavFlow]] 直接在波形空间做 T2A/V2A；MMAudio 更像 latent / flow matching + 同步模块的 V2A 实用基线。

## 1. 身份

`MMAudio` 是 UIUC + Sony AI / Sony Group 的 **video-to-audio / text-to-audio 生成模型**，论文题为 *MMAudio: Taming Multimodal Joint Training for High-Quality Video-to-Audio Synthesis*，CVPR 2025。它给定视频和/或文本条件，生成与画面同步的音效、环境声或事件音频。

边界：MMAudio 不是语音 TTS、ASR 或语音增强模型；它更接近“给 silent video 补 Foley / soundscape”的通用音频生成模型。官方 README 也明确提示它可能生成不可懂的人声样声音，背景音乐质量也不是主目标。

## 2. 核心机制

- **多模态联合训练**：同时使用 audio-visual 与 text-audio 数据，避免只依赖有限的视频-音频数据；目标是让视频条件学同步、文本条件补语义覆盖。
- **Flow Matching**：训练生成 audio latent / waveform 解码路径时使用 flow matching objective；论文报告 157M 参数、生成 8 秒音频约 1.23 秒。
- **条件同步模块**：把 video condition 与 audio latent 做 frame-level 对齐，用来改善音画同步。
- **多入口推理**：支持 video + prompt、video-only、text-to-audio；官方 Gradio 还支持实验性 image-to-audio（把图像复制成视频处理），但这不是训练目标。
- **工程默认**：官方 demo 默认 `large_44k_v2`，训练 / 默认输出时长 8 秒；偏离训练时长太多可能降质。

## 3. 数据与开源

- **训练数据**：官方列出 AudioSet、Freesound、VGGSound、AudioCaps、WavCaps 等数据源；数据各自有许可证，官方不保证预训练模型适合商业使用。
- **代码**：GitHub `hkchengrex/MMAudio`，MIT license。
- **权重**：官方 Hugging Face 权重；checkpoint license 为 CC-BY-NC 4.0。
- **评测工具**：同作者生态的 `av-benchmark` 用于 V2A / T2A 指标评测，见 [[方向/AI语音/评估/FD_PaSST（PaSST 特征 Fréchet 距离）|FD_PaSST]]。

## 4. 已知限制

- 会生成不可懂的人声样声音，不适合作为 speech / dialogue generator。
- 可能生成背景音乐，但官方认为没有显式高质量音乐训练时效果有限。
- 对不熟悉概念泛化差，例如能生成 gunfire，但不一定能生成更细的 “RPG firing”。
- 评测和商用要注意 checkpoint 非商用许可、训练数据许可证和视频素材版权。
- 官方 GitHub 声明与 `mmaudio.net` 域名背后的主体无关联。

## 5. 关键来源

- [MMAudio: Taming Multimodal Joint Training for High-Quality Video-to-Audio Synthesis](https://arxiv.org/abs/2412.15322)
  - 内容定位：原始论文，提出 multimodal joint training、conditional synchronization module、flow matching V2A/T2A 框架。
  - 用途：主定义、参数量、推理速度和评测结论。
  - 核验日期：2026-08-11
- [hkchengrex/MMAudio GitHub](https://github.com/hkchengrex/MMAudio)
  - 内容定位：官方代码、demo、模型下载说明、许可证、训练数据列表和已知限制。
  - 用途：复现、部署和边界条件。
  - 核验日期：2026-08-11
- [MMAudio 项目页](https://hkchengrex.com/MMAudio/)
  - 内容定位：CVPR 2025 项目页、作者机构、demo 与结果入口。
  - 用途：快速确认项目身份和示例。
  - 核验日期：2026-08-11

## 6. 相关对象

- [[方向/AI语音/模型/WavFlow|WavFlow]]：同属 T2A / V2A，但走 raw waveform + direct x-prediction 路线。
- [[方向/AI语音/模型/Stable Audio 3|Stable Audio 3]]：通用音频 / 音乐生成对照，评估多用 FAD / VGGish 口径。
- [[方向/AI语音/知识/基础概念/Flow Matching（流匹配）|Flow Matching]]：MMAudio 的生成训练范式之一。
- [[方向/AI语音/评估/FD_PaSST（PaSST 特征 Fréchet 距离）|FD_PaSST]]：V2A 分布匹配指标，MMAudio 生态常用。
- MMAudio-LABEL：基于 foundational audio generation model 做事件标签生成的后续方向；当前未建笔记。

## 7. 待验证

- 官方 checkpoint 版本（16k / 44.1k、large / small、v1 / v2）与各 benchmark 分数的精确对应。
- 与 WavFlow、PAVAS、MGAudio、ThinkSound 等后续 V2A 模型在同一 av-benchmark 口径下的最新排名。
- ComfyUI / Replicate / HF Space 等社区工作流是否使用官方权重、是否修改 prompt / sampler / duration 设置。

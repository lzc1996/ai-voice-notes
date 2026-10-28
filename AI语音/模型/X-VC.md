---
title: X-VC
类型: 模型
发表时间: 2026-04-14
时间依据: arXiv v1 首次提交日；v3 于 2026-09-04 更新
任务:
  - 语音转换
  - zero-shot voice conversion
  - 实时语音转换
开放状态:
  - paper
  - code
  - demo
  - weights
aliases:
  - XVC
  - "X-VC: Zero-shot Streaming Voice Conversion in Codec Space"
  - Zero-shot Streaming Voice Conversion in Codec Space
tags:
  - 类型/对象
  - 方向/AI语音
  - 任务/语音转换
  - 主题/音频codec
  - 主题/zero-shot
---

# X-VC

## 0. 背景

**问题现场**：zero-shot 实时语音转换要把源语音换成未见过目标说话人的音色、保留语言内容，且支持低延迟流式推理。

**前序路线的缺口**：直接在 waveform / spectrogram 空间重建的路线（如离线扩散 VC）难以兼顾实时性与交互场景需求。

**X-VC 的切入点**：在预训练神经 codec 的 latent space 里做一步式转换，用 dual-conditioning acoustic converter 同时建模源 codec latents 与目标参考的 frame-level acoustic condition，并以 chunkwise inference + overlap smoothing 实现流式。

## 1. 身份

`X-VC` 是上海交通大学等提出的 zero-shot streaming voice conversion 系统，论文题目是 *X-VC: Zero-shot Streaming Voice Conversion in Codec Space*。它的目标是把源语音转换成未见过目标说话人的音色，同时保留源语音的语言内容，并支持低延迟流式推理。

边界：X-VC 不是 TTS，也不是通用语音对话模型。它输入的是源语音 + 目标参考语音，输出目标音色下的源内容；和 [[方向/AI语音/知识/基础概念/Zero-shot Voice Cloning（零样本声音克隆）]] 的文本到语音克隆不同，voice conversion 的源内容直接来自输入语音。

## 2. 核心信息

- **核心路线**：在预训练神经 codec 的 latent space 里做一步式转换，而不是直接在 waveform 或 spectrogram 空间重建。
- **条件设计**：dual-conditioning acoustic converter 同时建模源 codec latents、目标参考语音导出的 frame-level acoustic condition，并通过 adaptive normalization 注入 utterance-level speaker embedding。
- **训练策略**：使用 generated paired data，并用 standard / reconstruction / reversed 三种 role-assignment 减少训练-推理不匹配。
- **流式推理**：chunkwise inference + overlap smoothing，对齐 codec 的 segment-based training 范式。
- **开源形态**：官方 GitHub 发布代码，Hugging Face 发布 checkpoint；推理脚本用 `current=0` 表示离线、`current>0` 表示流式。
- **依赖组件**：推理前需准备 GLM-4-Voice-Tokenizer（semantic tokenization）和 ERes2Net speaker encoder；训练初始化另需 SAC pretrained checkpoint。

## 3. 核心机制

```text
source speech
  -> pretrained neural codec encoder
  -> source codec latents

target reference speech
  -> frame-level acoustic condition
  -> utterance-level speaker embedding

source codec latents + target acoustic condition + speaker embedding
  -> dual-conditioning acoustic converter
  -> converted codec latents
  -> codec decoder
  -> converted speech with target timbre
```

关键判断：X-VC 把实时 VC 的难点从“直接合成波形”改成“在 codec latent 中做目标音色迁移”。这样可以复用 codec 的压缩和解码能力，同时把 target speaker 的细粒度条件放进 converter，而不是只靠一个全局 speaker embedding。

## 4. 使用判断

- 看**实时语音换声 / 配音**：X-VC 比离线扩散 VC 更贴近交互场景，重点看延迟、音色相似度和内容保持。
- 看**codec-space VC**：适合与 Seed-VC、MeanVC、FreeVC、Vevo 这类 voice conversion 路线对照。
- 看**评估口径**：不能只听自然度；需要同时看 [[方向/AI语音/评估/WER（词错误率）]] / CER、[[方向/AI语音/评估/SpkSim]]、跨语言相似度和 streaming latency。
- 看**安全边界**：具备 zero-shot voice conversion 能力，只应放在授权、研究或受控产品场景里评估。

## 5. 测试基准与性能

- 论文摘要报告：X-VC 在 Seed-TTS-Eval 上取得中英文 streaming WER 最优，并在同语言 / 跨语言设置下保持较强 speaker similarity。
- 论文摘要还报告：X-VC 的 offline real-time factor 明显低于对比基线；具体表格数字待精读论文表格后补。

## 6. 相关对象

- [[方向/AI语音/MOC - TTS]]：voice conversion 与 TTS / 声音克隆是相邻生产链路。
- [[方向/AI语音/知识/基础概念/Zero-shot Voice Cloning（零样本声音克隆）]]：区分文本驱动声音克隆与语音到语音的 voice conversion。
- [[方向/AI语音/知识/基础概念/NAC（神经音频 Codec）]]：X-VC 在 pretrained neural codec latent space 中做转换。
- [[方向/AI语音/模型/GLM-4-Voice]]：官方实现依赖 GLM-4-Voice-Tokenizer 做 semantic tokenization。
- [[方向/AI语音/模型/X-Codec2]]：相邻的 LLM-friendly speech codec 路线，可作为 codec-space 语音生成/转换对照。
- [[方向/AI语音/数据集/VCTK]]：voice conversion 常用多说话人语料生态。

## 7. 来源

- [X-VC: Zero-shot Streaming Voice Conversion in Codec Space（arXiv:2604.12456）](https://arxiv.org/abs/2604.12456)
  - 内容定位：论文入口，记录 zero-shot streaming VC 定位、codec latent space 一步式转换、dual-conditioning acoustic converter、generated-pair training、role assignment 和 Seed-TTS-Eval 摘要结果。
  - 用途：确认模型身份、发布时间、核心机制和评测口径。
  - 核验日期：2026-09-15
- [Jerrister/X-VC（GitHub）](https://github.com/Jerrister/X-VC)
  - 内容定位：官方代码仓库，包含在线 demo、环境配置、checkpoint 放置、离线/流式推理脚本、训练配置和 MIT license。
  - 用途：确认代码开放、依赖组件、推理入口和开源许可证。
  - 核验日期：2026-09-15
- [chenxie95/X-VC（Hugging Face）](https://huggingface.co/chenxie95/X-VC)
  - 内容定位：官方 checkpoint / model card 页面，标注 arXiv 2604.12456、MIT license、依赖说明、推理/训练入口和 checkpoint 使用方式。
  - 用途：确认权重开放与工程下载入口。
  - 核验日期：2026-09-15
- [X-VC Demo](https://x-vc.github.io/)
  - 内容定位：官方样例页，展示 X-VC 的 zero-shot streaming voice conversion 摘要和音频样例。
  - 用途：试听转换质量、延迟和跨语言样例。
  - 核验日期：2026-09-15

## 8. 待验证

- 论文表格中的 Seed-TTS-Eval 具体 WER / SIM / RTF / latency 数字。
- GitHub checkpoint 与论文 v3 是否完全对应，尤其是训练数据、chunk 参数和 smoothing 配置。
- 中文实时场景里，X-VC 与 Seed-VC、MeanVC、Qwen3-TTS voice cloning 的延迟和音色保持差异。
- GLM-4-Voice-Tokenizer、ERes2Net speaker encoder、SAC training init 是否需要拆成独立实现链路笔记。

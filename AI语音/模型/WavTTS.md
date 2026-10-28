---
title: WavTTS
类型: 模型
发表时间: 2026-06
时间依据: arXiv 首次提交日
任务:
  - 语音合成
相关主题:
  - 扩散模型
  - 语音生成
相关模型:
  - "[[方向/AI语音/模型/DiT-Flow]]"
  - "[[方向/AI语音/模型/WavFlow]]"
开放状态: []
aliases: []
tags:
  - 类型/对象
  - 方向/AI语音
---
# WavTTS

## 0. 背景

- **原始波形路线的地位确认**：此前 raw-waveform 端到端 TTS（如早期端到端模型）质量明显落后潜空间扩散系；WavTTS 报告在 WER、UTMOS 自然度、说话人相似度上**接近当前 SOTA 潜空间零样本 TTS（如 F5-TTS）**，显著优于此前端到端模型——原始波形路线不再是陪跑。
- **开源可复现**：代码 MIT 协议（基于 [[方向/AI语音/模型/F5-TTS|F5-TTS]] 代码库），checkpoint 在 Hugging Face 公开。
- **对 vault 的意义**：与 [[方向/AI语音/知识/技术路线/语音生成 tokenizer codec 技术路线|tokenizer/codec 路线]] 并行的另一极——"不要中间表示，直接在波形上学生成"。

## 1. 身份

`WavTTS`（arXiv:2606.03455，2026-06）是**直接建模原始波形的生成式 TTS**：零样本（zero-shot）语音合成，不经过 mel、VAE latent 或 codec token 中间表示，从文本 + 参考语音直接生成波形——论文称这是首个把与潜空间扩散模型的质量差距抹平的原始波形生成式 TTS。基于 **Flow Matching + Diffusion Transformer（DiT）** 架构，属于 [[方向/AI语音/知识/基础概念/Flow Matching（流匹配）|flow matching]] 谱系。

边界：WavTTS 不是 autoregressive 路线（不像 codec-LM），也不是潜空间生成（不像 [[方向/AI语音/知识/生成式语音增强/扩散模型与语音|F5-TTS 类]] 在压缩 latent 上生成）；它把生成直接放在原始波形空间，训练端到端、无中间表示信息损失。

## 2. 核心机制

```text
reference audio + transcription（零样本声纹条件）
  -> 文本 + 参考 prompt 编码
  -> 波形 patchification（直接切原始波形 patch）
  -> DiT + Flow Matching（噪声感知 schedule）
  -> 多尺度 mel 辅助监督（感知引导）
  -> 直接输出 raw waveform
```

关键点：

- **无中间表示**：绕开 mel / VAE / codec，避免各环节信息损失，训练端到端。
- **flow matching + DiT**：延续 FM 低步数确定性生成路线。
- **参考音频 prompting**：参考语音 + 其转写作为说话人条件，实现零样本克隆。
- **多尺度 mel 辅助监督**：训练时用多尺度 mel 损失做感知引导，弥补纯波形 loss 的感知盲区。
- **语种**：官方 checkpoint 支持英文与中文，输出 16 kHz；训练数据为 Emilia。

## 3. 使用注意

- **16 kHz 输出**：比主流 TTS 的 24 kHz 低，高保真听感 / 高音质场景要先确认是否够用。
- **checkpoint 许可**：官方权重为 **CC BY-NC 4.0**（Emilia 数据集许可限制）——商用需自训或换训练数据；代码本体 MIT。
- **同代码系**：基于 F5-TTS 代码库改造，熟悉 FM 系 TTS 的工程可直接上手。
- **新项目**：5 个 commit 级别的早期开源状态，接口和配置可能快速变动。

## 4. 关键来源

- [WavTTS: Towards High-Quality Zero-Shot TTS via Direct Raw Waveform Modeling](https://arxiv.org/abs/2606.03455)
  - 内容定位：原始论文，原始波形 FM + DiT 零样本 TTS，报告逼近潜空间 SOTA。
  - 用途：方法机制、评测与时间依据。
  - 核验日期：2026-08-11
- [cwx-worst-one/WavTTS GitHub](https://github.com/cwx-worst-one/WavTTS)
  - 内容定位：官方代码（MIT），基于 F5-TTS 代码库，含 CLI 推理与训练脚本。
  - 用途：复现 / 改写的代码入口。
  - 核验日期：2026-08-11
- [worstchan/WavTTS - Hugging Face](https://huggingface.co/worstchan/WavTTS)
  - 内容定位：官方 checkpoint（CC BY-NC 4.0）与 vocab。
  - 用途：下载权重做零样本合成。
  - 核验日期：2026-08-11

## 5. 相关对象

- [[方向/AI语音/知识/基础概念/Flow Matching（流匹配）|Flow Matching]]：生成机制的理论基础（FM + DiT）。
- [[方向/AI语音/知识/生成式语音增强/扩散模型与语音|扩散模型与语音]]：TTS 谱系（NaturalSpeech 系、F5-TTS 为 FM 版）；WavTTS 是"直接波形 FM"的新成员。
- [[方向/AI语音/知识/技术路线/语音生成 tokenizer codec 技术路线|语音生成 tokenizer codec 技术路线]]：对照路线——codec/token 中间表示 vs 直接波形。
- [[方向/AI语音/知识/基础概念/Vocoder（声码器）|Vocoder]]、[[方向/AI语音/知识/基础概念/NAC（神经音频 Codec）|NAC]]：潜空间 / token 路线需要的输出侧组件；WavTTS 不需要。
- [[方向/AI语音/知识/生成式语音增强/DiT 与语音增强（DiT-based Speech Enhancement）|DiT 与语音增强]]：DiT 骨干在语音任务中的另一应用面。
- [[方向/AI语音/模型/WavFlow|WavFlow]]：通用音频生成域的直接波形 FM 姊妹工作（T2A / V2A）。

## 6. 待验证

- 与 F5-TTS 及其他潜空间零样本 TTS 在**中文**上的直接对比（WER / 自然度 / 相似度）。
- 24 / 48 kHz 支持状态；实时性（RTF）与推理成本。
- 商用路线（自训数据 / 许可处理）是否可行。

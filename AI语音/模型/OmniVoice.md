---
title: OmniVoice
类型: 模型
参数量: 0.8B
发表时间: 2026-04
时间依据: arXiv 首次提交日
任务:
  - 语音合成
相关主题:
  - 扩散模型
  - 语音生成
相关模型:
  - "[[方向/AI语音/模型/WavTTS]]"
开放状态: []
aliases: []
tags:
  - 类型/对象
  - 方向/AI语音
---
# OmniVoice

## 0. 背景

- **开源多语种天花板**：Seed-TTS 中文测试集 WER 0.84%，多语言 SIM-o / WER 超 ElevenLabs v2 与 MiniMax；小语种 / 濒危语言数字化保护的实用门槛大幅降低。
- **速度**：RTF 低至 0.025（约 40× 实时），1 分钟音频约 1.5 秒合成。
- **许可干净**：Apache-2.0 可商用，是 ElevenLabs 类商用模型的免费开源替代——比 WavTTS 的 CC BY-NC checkpoint 更适合产品化。
- **Kaldi 系团队背书**：Daniel Povey 领衔，工程质量和文档完整度高。

## 1. 身份

`OmniVoice`（arXiv:2604.00688，2026-04）是小米 AI 实验室 **k2-fsa（下一代 Kaldi 团队）**开源的多语种**零样本 TTS**：支持 **600+ 语种**，0.8B 参数，用 58.1 万小时开源语音数据训练，**Apache-2.0 许可（可商用）**。论文标题 *OmniVoice: Towards Omnilingual Zero-Shot Text-to-Speech with Diffusion Language Models*，作者含 Daniel Povey 等 Kaldi 系班底。

边界：OmniVoice 是离散 acoustic-token 路线的 TTS（不是直接波形生成，区别于 [[方向/AI语音/模型/WavTTS|WavTTS]]），但用**扩散语言模型风格的离散非自回归**架构单步生成，跳过了传统 TTS 的中间语义 token 阶段。

## 2. 核心机制

```text
text（可选: 参考音频 3–10s / 自然语言音色描述 / 拼音标注）
  -> 单阶段 text -> acoustic token（扩散 LM 风格离散 NAR）
  -> 全码本随机掩码 + 预训练 LLM 初始化
  -> decoder -> waveform
```

关键点：

- **扩散 LM 风格离散 NAR**：离散 acoustic token 上做扩散式生成，非自回归单步，避免 AR 的延迟和错误累积。
- **跳过中间语义 token**：传统两阶段（semantic token → acoustic token）压缩为单阶段，减少中间误差。
- **零样本克隆**：3–10 秒参考音频即可克隆，支持跨语言克隆（如中文参考读英文），内置去噪。
- **语音设计**：不用参考音频，纯自然语言描述生成声音（性别、年龄、音调、口音、方言如四川话/陕西话、耳语风格）。
- **控制能力**：非语言符号（`[laughter]`、`[sigh]`、`[breath]`）、拼音/音素发音纠正（多音字、专有名词）。

## 3. 使用注意

- **硬件**：推荐 6 GB 显存起步，10 GB+ 更稳（官方最佳 H800/H20）；CPU 仅可测试。
- **输出语种**：600+ 语种以 16 kHz 级别合成为主，高保真听感场景需确认采样率与音质预期。
- **架构对比**：离散 token 路线需要 decoder（vocoder 类）还原波形；与直接波形路线（WavTTS）的取舍是"中间表示的信息损失 vs 生成稳定性/可控性"。
- **同名辨析**：还有另一个同名的 **OmniVoice**（声智 SoundAI，"One Model for Many Voices"，2025）——实时语音到语音对话模型，与本模型无关，引用时需写明 arXiv 编号。

## 4. 关键来源

- [OmniVoice: Towards Omnilingual Zero-Shot Text-to-Speech with Diffusion Language Models](https://arxiv.org/abs/2604.00688)
  - 内容定位：原始论文，扩散 LM 风格离散 NAR 架构与评测。
  - 用途：方法机制、作者与指标。
  - 核验日期：2026-08-11
- [k2-fsa/OmniVoice GitHub](https://github.com/k2-fsa/OmniVoice)
  - 内容定位：官方代码仓库（Apache-2.0）。
  - 用途：推理、微调与工程复现入口。
  - 核验日期：2026-08-11
- [k2-fsa/OmniVoice - Hugging Face](https://huggingface.co/k2-fsa/OmniVoice)
  - 内容定位：官方权重、demo Space 与论文页。
  - 用途：下载权重与快速体验。
  - 核验日期：2026-08-11

## 5. 相关对象

- [[方向/AI语音/模型/WavTTS|WavTTS]]：同期开源零样本 TTS 的另一条路线（直接原始波形 FM vs 离散 acoustic token）。
- [[方向/AI语音/知识/技术路线/语音生成 tokenizer codec 技术路线|语音生成 tokenizer codec 技术路线]]：离散 token 表示的技术背景。
- [[方向/AI语音/知识/生成式语音增强/扩散模型与语音|扩散模型与语音]]：扩散 / FM 在 TTS 谱系中的位置。
- [[方向/AI语音/知识/Vocoder（声码器）|Vocoder]]：离散 / 潜表示还原波形的输出侧。

## 6. 待验证

- 与 F5-TTS、WavTTS 在**中文**上的直接对比（WER / 自然度 / 相似度 / RTF）。
- 具体语种清单（600+ 的确切构成与方言覆盖）；16 kHz 输出之外的高采样率支持。
- 声智 SoundAI 版 OmniVoice（实时 S2S）的细节与 arXiv 编号是否需要单独笔记。

---
title: 语音模型 tokenizer 与 LLM tokenizer 对比
类型: 概念
发表时间:
时间依据: 综合对比笔记；覆盖文本 tokenizer、audio codec、HuBERT 与 Qwen 技术报告
相关主题:
  - tokenizer
相关模型:
  - "[[方向/AI语音/模型/HuBERT]]"
  - "[[方向/AI语音/模型/X-Codec]]"
  - "[[方向/AI语音/模型/X-Codec2]]"
  - "[[方向/AI语音/模型/UniAudio-Token]]"
  - "[[方向/AI语音/模型/S3 Tokenizer]]"
  - "[[方向/AI语音/模型/Qwen3-TTS]]"
  - "[[方向/AI语音/模型/Qwen-Audio-VAE]]"
aliases:
  - 语音模型 tokenizer 与 LLM tokenizer 对比
tags:
  - 类型/对象
  - 方向/AI语音
  - 主题/tokenizer
---

# 语音模型 tokenizer 与 LLM tokenizer 对比

## 1. 内容定位

这篇解释“语音模型的 tokenizer”和“LLM 的文本 tokenizer”为什么不是同一类东西：LLM tokenizer 处理离散文本符号；语音 tokenizer / audio tokenizer 要把连续音频压缩成模型能理解或生成的 token / latent。

## 2. 一句话区别

**LLM tokenizer 是文本分词器；语音 tokenizer 更像音频压缩器 + 声学表示器。**

## 3. 对比表

| 维度 | LLM tokenizer | 语音 tokenizer / audio tokenizer |
|---|---|---|
| 输入 | 文本字符串 | 连续音频波形或声学特征 |
| 输出 | 文本 token ID | 声学 token、codec token、semantic token 或 continuous latent |
| 典型方法 | BPE、WordPiece、Unigram、SentencePiece | Neural audio codec、[[方向/AI语音/知识/基础概念/RVQ（残差向量量化）]]、[[方向/AI语音/模型/HuBERT]]/wav2vec 类离散语义 token、VAE latent |
| 时间属性 | 基本不对应真实时间 | 强时间相关，每个 token/latent 对应音频片段 |
| 信息内容 | 字面文本和子词结构 | 语义、音色、韵律、音高、情绪、口音、背景声等 |
| 可逆性 | 通常可无损 detokenize 回文本 | 多数是有损压缩，需要 decoder/vocoder 还原波形 |
| 目标 | 降低词表稀疏性，让 LLM 预测文本序列 | 降低音频序列长度，让模型理解/生成声音 |
| 失败形态 | 分词粒度差、未知词、跨语言切分低效 | 音质损失、韵律丢失、音色漂移、延迟高、重建伪影 |

## 4. LLM tokenizer 在解决什么

文本已经是离散符号，LLM tokenizer 的主要问题是把字符串切成合适的子词单元。BPE 的经典动机是处理罕见词和开放词表；SentencePiece 则把文本 tokenizer/detokenizer 做成语言无关的子词系统；OpenAI 的 `tiktoken` 是面向 OpenAI 模型的快速 BPE tokenizer 实现。

简化链路：

```text
文本字符串 -> BPE / Unigram / WordPiece -> token ID -> LLM -> token ID -> 文本字符串
```

## 5. 语音 tokenizer 在解决什么

音频是连续波形，采样率通常很高，不能像文本一样直接喂给语言模型。语音 tokenizer / audio codec 的目标是把连续音频压缩成更短的离散 token 或连续 latent，同时尽量保留内容、音色和韵律。

简化链路：

```text
音频波形 -> audio encoder / codec / tokenizer -> audio token 或 latent -> 生成模型 -> decoder / vocoder -> 音频波形
```

## 6. ASR 和 TTS 里的 tokenizer 不一样

### 6.1. ASR

ASR 的输出端通常仍然是文本 token：音频 encoder 先把波形变成声学表示，然后 decoder 输出文字 token。此时“tokenizer”很多时候指输出文本 tokenizer；音频输入端更常被叫做 feature extractor / audio encoder。

```text
音频 -> audio encoder -> decoder -> text token -> 文本
```

### 6.2. TTS / audio generation

TTS 通常有两层 tokenizer：输入文本先走文本 tokenizer；输出语音再走 audio tokenizer / codec token / latent。后者决定了语音生成的延迟、音质和可控性。

```text
文本 -> text tokenizer -> TTS model -> audio token / latent -> vocoder -> 音频
```

## 7. Qwen 线里的具体例子

- `Qwen3-TTS-Tokenizer-12Hz`：低帧率离散 speech token，目标是低延迟流式 TTS。
- `Qwen3-TTS-Tokenizer-25Hz`：偏语义内容和 Qwen-Audio 系列衔接。
- `Qwen-Audio-VAE`：连续 audio latent，目标更底层，面向 speech/music/sound 的通用音频生成。

## 8. X-Codec / X-Codec2 里的具体例子

- [[方向/AI语音/模型/X-Codec]]：约 50 Hz 的语义增强多层 RVQ codec，把 SSL semantic feature 融入 audio tokenization，目标是减少 audio LLM 生成时的漏词和语义漂移。
- [[方向/AI语音/模型/X-Codec2|X-Codec2]]：约 50 tokens/s 的 low-bitrate speech tokenizer，把语音转成 Llama-style speech LLM 可预测的离散 token。
- LLaSA：上层 speech LLM，使用 X-Codec2 token，并用 Llama-style Transformer 建模 speech synthesis。

## 9. CosyVoice / S3 Tokenizer 里的具体例子

- [[方向/AI语音/模型/S3 Tokenizer|S3 Tokenizer]]：有监督语义 speech tokenizer，把语音压成更贴近文本语义和副语言信息的离散 token。
- [[方向/AI语音/模型/UniAudio-Token]]：单码本 semantic audio tokenizer，用 SAP / SAE 把 speech-centric token 扩到 speech / sound / music 的 general audio perception。
- CosyVoice：上层 text-to-token LLM 预测 S3 speech tokens，再由 token-to-speech flow matching / vocoder 链路合成语音。

## 10. 关键工程影响

- **序列长度**：文本 token 通常按字词增长；音频 token 按时间增长，帧率直接决定每秒 token 数。
- **延迟**：audio tokenizer 帧率越高，生成越慢；低帧率能降延迟，但可能损失细节。
- **音质**：文本 tokenizer 不影响“声音”；audio tokenizer 会直接影响音色、韵律、自然度。
- **可控性**：audio token 是否保留 speaker、emotion、prosody，决定声音克隆和情绪控制上限。
- **可观测性**：文本 token 可读；audio token/latent 通常不可读，需要听感、MOS、重建误差和下游任务评估。

## 11. 证据表

| 判断 | 可信来源 |
|---|---|
| 文本 tokenizer 主要是子词切分，BPE 用于开放词表和罕见词处理 | Sennrich et al. 2016 BPE 论文；Hugging Face Tokenizer Summary |
| SentencePiece 是语言无关的 tokenizer/detokenizer 框架 | SentencePiece 论文和 Google 官方仓库 |
| `tiktoken` 是 OpenAI 模型使用的快速 BPE tokenizer | OpenAI `tiktoken` 官方 GitHub |
| neural audio codec 把音频编码成离散码或低码率表示，再重建波形 | SoundStream、EnCodec 论文 |
| 普通 acoustic codec 作为 audio LLM tokenizer 可能有语义短板，X-Codec 通过 SSL semantic feature + semantic reconstruction loss 缓解 | X-Codec 论文 |
| semantic speech tokenizer 可能有 acoustic blindness，UniAudio-Token 用 SAP 监督和 SAE gate 扩展 general audio perception | UniAudio-Token 论文 |
| [[方向/AI语音/模型/HuBERT]] 类方法学习离散语音单元，可作为语义 speech token 的来源 | HuBERT 论文 |
| Qwen3-TTS 使用 25Hz/12Hz tokenizer，12Hz 面向低延迟流式 TTS | Qwen3-TTS 技术报告和官方 README |
| Qwen-Audio-VAE 是连续 audio latent 路线，面向通用音频生成 | Qwen-Audio-VAE 技术报告 |

## 12. 相关对象

- [[方向/AI语音/知识/技术路线/语音生成 tokenizer codec 技术路线|语音生成 tokenizer codec 技术路线]]：语音生成 tokenizer / codec 的路线展开。
- [[方向/AI语音/模型/S3 Tokenizer|S3 Tokenizer]]：CosyVoice 使用的 supervised semantic speech tokenizer。
- [[方向/AI语音/模型/X-Codec]]：语义增强 audio codec，把 SSL semantic feature 与 acoustic codec tokenization 结合。
- [[方向/AI语音/模型/X-Codec2|X-Codec2]]：LLaSA 使用的 speech tokenizer / codec。
- [[方向/AI语音/模型/UniAudio-Token]]：single-codebook semantic audio tokenizer，对照 S3 / X-Codec / X-Codec2。
- [[方向/AI语音/模型/Qwen3-TTS|Qwen3-TTS]]：使用 Qwen3-TTS-Tokenizer-12Hz 的专用 TTS。
- [[方向/AI语音/模型/Qwen-Audio-VAE|Qwen-Audio-VAE]]：连续 audio latent 路线。
- [[方向/AI语音/模型/HuBERT|HuBERT]]：hidden-unit / semantic speech token 路线代表。
- [[方向/AI语音/选型/Qwen 语音模型技术路线图|Qwen 语音模型技术路线图]]：Qwen 语音路线总览。

## 13. 来源

- [Neural Machine Translation of Rare Words with Subword Units](https://arxiv.org/abs/1508.07909)
  - 内容定位：BPE 子词分词经典论文，解释用 subword units 处理罕见词和开放词表。
  - 用途：支撑 LLM/text tokenizer 的子词切分逻辑。
  - 核验日期：2026-07-24
- [Hugging Face Tokenizer Summary](https://huggingface.co/docs/transformers/main/tokenizer_summary)
  - 内容定位：Hugging Face 官方文档，概览 WordPiece、BPE、SentencePiece、Unigram 等文本 tokenizer。
  - 用途：支撑 LLM tokenizer 的常见方法分类。
  - 核验日期：2026-07-24
- [SentencePiece: A simple and language independent subword tokenizer and detokenizer](https://arxiv.org/abs/1808.06226)
  - 内容定位：SentencePiece 论文，说明语言无关的 tokenizer/detokenizer 设计。
  - 用途：支撑文本 tokenizer 与 detokenizer 的定义。
  - 核验日期：2026-07-24
- [google/sentencepiece](https://github.com/google/sentencepiece)
  - 内容定位：SentencePiece 官方仓库，记录其作为无监督文本 tokenizer/detokenizer 的工程实现。
  - 用途：支撑 SentencePiece 的官方实现来源。
  - 核验日期：2026-07-24
- [openai/tiktoken](https://github.com/openai/tiktoken)
  - 内容定位：OpenAI 官方 `tiktoken` 仓库，记录其为 OpenAI 模型使用的快速 BPE tokenizer。
  - 用途：支撑 OpenAI/LLM tokenizer 的工程例子。
  - 核验日期：2026-07-24
- [SoundStream: An End-to-End Neural Audio Codec](https://arxiv.org/abs/2107.03312)
  - 内容定位：神经音频 codec 论文，记录端到端神经音频压缩和重建路线。
  - 用途：支撑 audio tokenizer / codec 与文本 tokenizer 不同的压缩属性。
  - 核验日期：2026-07-24
- [High Fidelity Neural Audio Compression](https://arxiv.org/abs/2210.13438)
  - 内容定位：EnCodec 论文，记录高保真神经音频压缩、低码率表示和音频重建。
  - 用途：支撑 codec token / audio compression 路线。
  - 核验日期：2026-07-24
- [Codec Does Matter: Exploring the Semantic Shortcoming of Codec for Audio Language Model](https://arxiv.org/abs/2408.17175)
  - 内容定位：X-Codec 论文，说明 acoustic codec 的语义短板和 semantic-aware audio tokenization 路线。
  - 用途：支撑 speech/audio tokenizer 与下游 audio LLM 语义保持的关系。
  - 核验日期：2026-09-02
- [UniAudio-Token: Empowering Semantic Speech Tokenizers with General Audio Perception](https://arxiv.org/abs/2605.31521)
  - 内容定位：UniAudio-Token 论文，说明 semantic speech tokenizer 的 acoustic blindness 和 SAP/SAE 修正方案。
  - 用途：支撑单码本 semantic audio tokenizer 的 general audio perception 路线。
  - 核验日期：2026-09-02
- [HuBERT: Self-Supervised Speech Representation Learning by Masked Prediction of Hidden Units](https://arxiv.org/abs/2106.07447)
  - 内容定位：HuBERT 论文，记录通过 hidden unit 预测学习语音表示。
  - 用途：支撑语义 speech token / hidden units 路线。
  - 核验日期：2026-07-24
- [Qwen3-TTS Technical Report](https://arxiv.org/abs/2601.15621)
  - 内容定位：Qwen3-TTS 技术报告，记录 25Hz / 12Hz tokenizer、低延迟流式和 TTS 模型族。
  - 用途：支撑 Qwen3-TTS tokenizer 例子。
  - 核验日期：2026-07-24
- [Qwen3-TTS README](https://github.com/QwenLM/Qwen3-TTS/blob/main/README.md)
  - 内容定位：Qwen3-TTS 官方仓库，记录 12Hz tokenizer、模型版本和推理接口。
  - 用途：支撑 Qwen3-TTS tokenizer 的官方工程来源。
  - 核验日期：2026-07-24
- [Qwen-Audio-VAE Technical Report](https://arxiv.org/abs/2607.11738)
  - 内容定位：Qwen-Audio-VAE 技术报告，记录连续 audio latent 和通用音频生成表示。
  - 用途：支撑 continuous audio latent 与离散 tokenizer 的区别。
  - 核验日期：2026-07-24



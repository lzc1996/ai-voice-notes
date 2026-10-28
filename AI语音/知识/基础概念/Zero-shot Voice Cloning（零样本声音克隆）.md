---
title: Zero-shot Voice Cloning（零样本声音克隆）
类型: 概念
发表时间: 2018-06-12
时间依据: SV2TTS arXiv 首次提交日；作为现代参考音频条件 TTS 的早期代表
相关任务:
  - TTS
  - 声音克隆
相关概念:
  - "[[方向/AI语音/知识/基础概念/Enrollment（说话人注册）]]"
相关评估:
  - "[[方向/AI语音/评估/可控 TTS 与声音克隆评估框架]]"
aliases:
  - zero-shot voice cloning
  - Zero-shot Voice Cloning
  - 零样本声音克隆
  - voice cloning
  - 声音克隆
  - instant voice cloning
  - zero-shot TTS
tags:
  - 类型/对象
  - 方向/AI语音
  - 任务/TTS
  - 任务/声音克隆
  - 主题/语音生成
---

# Zero-shot Voice Cloning（零样本声音克隆）

## 1. 身份

`Zero-shot voice cloning` 指模型在**不为目标说话人微调参数**的情况下，用一段参考音频 / acoustic prompt / speaker embedding 作为条件，把目标文本合成为接近该说话人的语音。

典型输入是：目标文本 + 目标说话人的短参考音频；典型输出是：内容按目标文本说、音色尽量接近参考说话人的合成语音。

## 2. 边界

- **不是普通 TTS**：普通 TTS 可以只选预置音色；zero-shot voice cloning 要从参考音频抽取或提示目标说话人身份。
- **不是 [[方向/AI语音/知识/基础概念/Enrollment（说话人注册）]] 本身**：enrollment 是录入/提取说话人条件，voice cloning 是用该条件生成新语音。
- **不是 voice conversion 的同义词**：voice conversion 通常输入一段源语音并转换成目标音色；zero-shot TTS / cloning 通常输入文本并生成新语音。
- **不是 few-shot 微调**：few-shot speaker adaptation 会用少量目标说话人数据更新模型或 adapter；zero-shot 推理时不更新目标说话人参数。
- **不是 VoiceDesign**：VoiceDesign 用自然语言描述生成或选择音色，不要求复刻某个参考说话人。

## 3. 典型链路

```text
reference audio
  -> VAD / 降噪 / 质量检查
  -> speaker embedding 或 acoustic prompt

target text
  -> text frontend / text tokens
  -> 条件声学模型、codec LM 或 speech-token LM
  -> vocoder / codec decoder
  -> waveform
```

两类常见实现：

- **Speaker-encoder conditioned TTS**：先用 speaker verification / speaker encoder 从参考音频提取 embedding，再让 TTS 模型按 embedding 合成；SV2TTS、YourTTS、OpenVoice 属于这一脉络。
- **Acoustic-prompt / codec-LM TTS**：把短参考音频作为声学 prompt 或 codec token 条件，让语音语言模型做 in-context cloning；VALL-E 之后的多种 speech-token / codec-token TTS 都沿着这条路线扩展。

## 4. 质量上限

- **参考音频质量**：太短、带噪、混响、多人声、背景音乐或压缩伪影都会污染 speaker condition。
- **说话人相似度 vs 内容一致性**：音色越像不等于读得越准，评估要同时看 speaker similarity 与 WER / CER。
- **跨语言克隆**：参考音频和目标文本语言不同时，模型可能丢音色、放大口音或把源语言韵律迁移过度。
- **韵律和情绪**：模型可能复制参考音频的情绪、语速和环境声；这在 VALL-E 类 acoustic prompt 路线里尤其明显。
- **安全授权**：声音是可识别生物特征；产品化必须处理授权、名人/公众人物限制、水印、检测和审计日志。

## 5. 评估口径

- 参考音频长度：3 秒、10 秒、30 秒分别测，避免只看单一 demo。
- 内容一致性：中文看 CER，英文/多语言看 WER，必要时做人工错读标注。
- 音色相似度：speaker embedding similarity、[[方向/AI语音/评估/SpkSim]]、主观 ABX / MOS。
- 自然度：MOS / UTMOS、长文本重复/漏读、断句和韵律漂移。
- 鲁棒性：带噪参考、手机录音、远场录音、跨语言和代码切换。
- 合规：授权链路、拒绝策略、音频水印、检测器和日志留存。

完整产品测试入口见 [[方向/AI语音/评估/可控 TTS 与声音克隆评估框架]]。

## 6. 代表路线

- **SV2TTS / speaker verification transfer**：把 speaker verification 模型学到的说话人表示迁移到多说话人 TTS，使系统能合成训练时未见说话人的声音。
- **YourTTS**：基于 VITS 的 multilingual zero-shot multi-speaker TTS / zero-shot voice conversion 路线，强调多语言和低资源语言扩展。
- **VALL-E**：把 TTS 转成 neural codec language modeling，用短参考音频作为 acoustic prompt，是 codec-LM zero-shot TTS 的代表。
- **OpenVoice**：强调短参考音频、跨语言 instant voice cloning，以及音色复制和风格控制的解耦。
- **现代开源/开权重 TTS**：[[方向/AI语音/模型/CosyVoice]]、[[方向/AI语音/模型/Qwen3-TTS]]、[[方向/AI语音/模型/Spark-TTS]]、[[方向/AI语音/模型/ZONOS2]] 都应按同一评估框架比较，而不是只听 demo。

## 7. 相关对象

- [[方向/AI语音/MOC - TTS]]：zero-shot voice cloning 属于 TTS 产品化主线。
- [[方向/AI语音/评估/可控 TTS 与声音克隆评估框架]]：评估入口。
- [[方向/AI语音/知识/基础概念/Enrollment（说话人注册）]]：参考音频录入和 speaker condition 的上游概念。
- [[方向/AI语音/知识/调研与地图/LALM Trust and Safety（音频大模型信任与安全）]]：声音克隆授权、滥用和水印风险。
- [[方向/AI语音/模型/S3 Tokenizer]]、[[方向/AI语音/模型/BiCodec]]、[[方向/AI语音/知识/技术路线/语音生成 tokenizer codec 技术路线]]：底层 speech-token / codec-token 表示。

## 8. 来源

- [Transfer Learning from Speaker Verification to Multispeaker Text-To-Speech Synthesis](https://arxiv.org/abs/1806.04558)
  - 内容定位：SV2TTS 早期代表，定义 speaker encoder + Tacotron 2 + WaveNet 的参考音频条件合成路线。
  - 用途：建立 zero-shot speaker-conditioned TTS 的历史起点。
  - 核验日期：2026-08-18
- [YourTTS: Towards Zero-Shot Multi-Speaker TTS and Zero-Shot Voice Conversion for everyone](https://arxiv.org/abs/2112.02418)
  - 内容定位：多语言 zero-shot multi-speaker TTS / voice conversion 论文。
  - 用途：区分 zero-shot cloning 与 low-resource / multilingual TTS 的关系。
  - 核验日期：2026-08-18
- [Neural Codec Language Models are Zero-Shot Text to Speech Synthesizers](https://arxiv.org/abs/2301.02111)
  - 内容定位：VALL-E 论文，提出 codec language model + acoustic prompt 的 zero-shot TTS 路线。
  - 用途：解释 modern codec-LM / speech-token TTS 为什么能靠短参考音频克隆。
  - 核验日期：2026-08-18
- [OpenVoice: Versatile Instant Voice Cloning](https://arxiv.org/abs/2312.01479)
  - 内容定位：instant voice cloning，强调短参考音频、跨语言克隆和风格控制。
  - 用途：补充 voice cloning 产品形态和风格控制边界。
  - 核验日期：2026-08-18
- [CosyVoice: A Scalable Multilingual Zero-shot Text-to-speech Synthesizer based on Supervised Semantic Tokens](https://arxiv.org/abs/2407.05407)
  - 内容定位：supervised semantic speech tokens + text-to-token LLM + flow matching 的 zero-shot TTS 代表。
  - 用途：连接当前 vault 里的 CosyVoice / S3 Tokenizer 主线。
  - 核验日期：2026-08-18

## 9. 待验证

- 是否单独建立 `Voice Conversion（声音转换）`、`VoiceDesign（音色设计）` 和 `Speaker Similarity（说话人相似度）` 概念页。
- 本地目标模型在中文、跨语言、带噪参考和长文本上的同口径克隆评测。

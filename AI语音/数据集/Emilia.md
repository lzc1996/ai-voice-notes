---
title: Emilia
类型: 数据集
aliases:
  - Emilia-Dataset
  - Emilia dataset
  - Emilia-Large
  - Emilia-YODAS
  - Emilia 语音数据集
tags:
  - 类型/对象
  - 方向/AI语音
  - 任务/TTS
  - 资源/数据集
---

# Emilia

## 1. 身份

Emilia 是 Amphion 团队发布的大规模、多语言、in-the-wild speech generation 数据集，并配套开源 Emilia-Pipe 预处理流程。它主要面向 TTS、speech generation、voice cloning 和 speech-language model 训练，不是传统干净录音棚语料。

## 2. 核心信息

- 原始 Emilia：约 101.7k 小时，主要来自互联网视频平台和播客。
- Emilia-Large：把原始 Emilia 与 Emilia-YODAS 合并，总量约 215.6k 小时。
- 语言：English、Chinese、German、French、Japanese、Korean。
- 数据格式：Hugging Face 上使用 WebDataset；Emilia 与 Emilia-YODAS 合计约 4.5TB、4,343 个 tar shards。
- 字段示例包含 `id`、`wav`、`text`、`duration`、`speaker`、`language`、`dnsmos`。
- 许可要分开看：原始 Emilia 使用 `CC BY-NC 4.0`；Emilia-YODAS 使用 `CC BY 4.0`；原始音频版权仍属于原始视频/音频所有者。

## 3. 用途

- 训练大规模多语言 TTS / zero-shot voice cloning 模型。
- 为 F5-TTS、E2-TTS、MaskGCT、VoxBox 等模型或数据构建提供大规模 speech generation 语料背景。
- 作为“野外语音 + 自动清洗 + metadata”的数据工程案例，参考 Emilia-Pipe 复用到自建语料。
- 和 [[方向/AI语音/数据集/VoxBox|VoxBox]] 对比：Emilia 更像大规模 in-the-wild speech generation 原料；VoxBox 更强调可控 TTS 属性标注。

## 4. 使用注意

- 非商业限制是硬约束；商业用途不要只看 Hugging Face 顶部 license badge。
- 数据来自互联网视频/播客，质量、版权、说话风格、背景声和文本对齐都需要二次抽检。
- `dnsmos` 可作为粗过滤字段，但不能替代人工听感、说话人一致性、文本对齐和版权审核。
- 训练 TTS 时要按语言、说话人、时长、DNSMOS、文本长度和异常字符做采样控制。

## 5. 相关对象

- [[方向/AI语音/MOC - TTS|TTS]]：Emilia 是大规模 TTS / speech generation 训练语料入口。
- [[方向/AI语音/数据集/VoxBox|VoxBox]]：VoxBox 来源中包含 Emilia-CN/EN，并面向可控 TTS 属性标注。
- [[方向/AI语音/模型/Spark-TTS|Spark-TTS]]：同属可控 TTS / voice cloning 语料生态，可与 Emilia 的数据规模和标注方式对照。
- [[方向/AI语音/模型/S3 Tokenizer|S3 Tokenizer]]：CosyVoice/FunAudioLLM 语音 token 路线常与大规模 TTS 数据训练一起出现。
- [[方向/AI语音/知识/OVRL_MOS|OVRL_MOS]]：`dnsmos` 字段可辅助音频质量过滤，但不是完整质量评估。

## 6. 关键资源

- [amphion/Emilia-Dataset](https://huggingface.co/datasets/amphion/Emilia-Dataset)
  - 内容定位：官方 Hugging Face 数据集页，包含 Emilia、Emilia-YODAS、Emilia-Large、语言/时长表、访问条款、WebDataset 结构和加载示例。
  - 用途：下载、许可核对和数据结构入口。
  - 核验日期：2026-08-05
- [Emilia: A Large-Scale, Extensive, Multilingual, and Diverse Dataset for Speech Generation](https://arxiv.org/abs/2501.15907)
  - 内容定位：扩展版论文，讨论 Emilia-Large、规模化和 speech generation 实验。
  - 用途：引用数据规模和跨语言 speech generation 结论。
  - 核验日期：2026-08-05
- [Emilia: An Extensive, Multilingual, and Diverse Speech Dataset for Large-Scale Speech Generation](https://arxiv.org/abs/2407.05361)
  - 内容定位：原始 Emilia / Emilia-Pipe 论文。
  - 用途：理解数据构建、清洗流程和原始版本定位。
  - 核验日期：2026-08-05
- [open-mmlab/Amphion](https://github.com/open-mmlab/Amphion)
  - 内容定位：Amphion 音频、音乐和语音生成工具箱，包含 Emilia/Emilia-Pipe 相关入口。
  - 用途：预处理流程和生态上下文。
  - 核验日期：2026-08-05

## 7. 待验证

- 本地是否需要只下载 Emilia 原始 101k 小时，还是使用 Emilia-Large / Emilia-YODAS。
- 目标项目是否允许使用 `CC BY-NC 4.0` 数据；若涉及商业化，默认不使用原始 Emilia。
- Emilia 与 [[方向/AI语音/数据集/LibriTTS|LibriTTS]]、VCTK、AISHELL-3、WenetSpeech4TTS 在多语言 TTS 训练中的采样比例。
- 是否需要建立 TTS 数据集清单，把 Emilia、VoxBox、[[方向/AI语音/数据集/LibriTTS|LibriTTS]]、LJSpeech、AISHELL-3、WenetSpeech4TTS 放到同一张对照表。

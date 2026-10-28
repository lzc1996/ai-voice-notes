---
title: VoxBox
类型: 数据集
发表时间: 2025-03-03
时间依据: Spark-TTS arXiv 首次提交日
aliases:
  - SparkAudio VoxBox
  - Spark-TTS VoxBox
  - VoxBox dataset
tags:
  - 类型/对象
  - 方向/AI语音
  - 任务/TTS
  - 主题/语音数据集
---

# VoxBox

## 1. 身份

VoxBox 是 SparkAudio / Spark-TTS 引入的大规模语音语料集合，用于可控 TTS、zero-shot voice cloning 和语音属性控制研究。论文把它描述为约 100,000 小时、带完整属性标注的数据集；独立 GitHub 仓库进一步列出约 102,500 小时、47,706,212 条 utterance。

边界：VoxBox 不是单一新采集语料，而是把多个开源中文/英文子语料聚合后，统一组织音频与 metadata，并补充 age、gender、emotion、pitch、speed、syllable 等属性标注。使用时必须回到各子语料原始许可证做合规核对。

## 2. 为什么重要

- **服务可控 TTS**：属性标注让模型能学习 gender、pitch、speaking rate、emotion 等控制维度。
- **服务 voice cloning**：大规模多说话人、多风格语音提高 zero-shot 克隆和跨语言代码切换的覆盖。
- **连接 Spark-TTS**：[[方向/AI语音/模型/Spark-TTS|Spark-TTS]] 的 BiCodec + Qwen2.5 LLM 路线把 VoxBox 作为核心训练数据背景。
- **不是“干净小数据集”**：它更像 TTS 训练语料合集和 metadata 标准化层，适合做大模型 TTS 训练，不适合当轻量评测集直接使用。

## 3. 规模与组成

| 维度 | 记录 |
|---|---|
| 语言 | 中文、英文 |
| 总时长 | GitHub README 记录 102,500.26 小时；论文口径约 100,000 小时 |
| 总 utterance | GitHub README 记录 47,706,212 条 |
| 中文部分 | 25,373,406 条，47,627.15 小时 |
| 英文部分 | 22,332,806 条，54,873.11 小时 |
| Hugging Face 体积 | Dataset card 显示约 4.84 TB；GitHub 下载说明提示完整数据约 5.82 TB |

主要来源包括 AISHELL-3、[[方向/AI语音/数据集/Emilia|Emilia]]-CN/EN、WenetSpeech4TTS、GigaSpeech、LibriSpeech、[[方向/AI语音/数据集/LibriTTS|LibriTTS-R]]、VCTK、情绪语音语料和若干对话/高质量语音子集。

## 4. metadata 字段

VoxBox 的每条样本 metadata 常见字段包括：

- `index`：样本唯一 ID。
- `split`：train / test 等切分。
- `language`：语言，当前主要是中文和英文。
- `age`、`gender`、`emotion`：说话人与话语属性。
- `pitch`、`pitch_std`、`speed`：声学属性。
- `duration`、`speech_duration`：总时长和去首尾静音后的语音时长。
- `syllable_num`、`syllables`：音节级信息。
- `text`：转写文本。
- `wav_path`：音频文件相对路径。

## 5. 使用注意

- **先看许可证**：VoxBox README 明确要求参考每个原始子语料许可证；不能只把 VoxBox 当成统一商业可用数据集。
- **不要全量下载起步**：完整数据 TB 级，先按子集下载 metadata 和少量音频验证字段、采样率、文本质量和许可。
- **属性标签要抽检**：age、emotion、pitch、speed 等自动标注字段适合训练控制能力，但正式实验要抽样检查误标。
- **评测要另建集**：训练语料集合不等于 benchmark；voice cloning、情绪控制、长文本稳定性和安全授权最好单独建评估集。

## 6. 关键资源

- [SparkAudio/voxbox](https://huggingface.co/datasets/SparkAudio/voxbox)
  - 内容定位：Hugging Face 数据集页，记录文件、metadata 字段、下载入口、体积和许可证提示。
  - 用途：下载数据、确认字段结构和使用约束。
  - 核验日期：2026-08-03
- [SparkAudio/VoxBox](https://github.com/SparkAudio/VoxBox)
  - 内容定位：官方 GitHub 仓库，记录中文/英文子语料统计、下载脚本、metadata 示例和许可说明。
  - 用途：确认完整规模、子集组成和下载方式。
  - 核验日期：2026-08-03
- [Spark-TTS paper](https://arxiv.org/abs/2503.01710)
  - 内容定位：Spark-TTS 论文摘要，提出 BiCodec、Qwen2.5 LLM、CoT 控制和 VoxBox 数据集。
  - 用途：确认 VoxBox 与 Spark-TTS 技术路线的关系。
  - 核验日期：2026-08-03

## 7. 相关对象

- [[方向/AI语音/模型/Spark-TTS]]：VoxBox 是其论文提出的核心训练数据背景。
- [[方向/AI语音/MOC - TTS|TTS]]：VoxBox 属于 TTS / voice cloning 训练语料入口。
- [[方向/AI语音/评估/可控 TTS 与声音克隆评估框架|可控 TTS 与声音克隆评估框架]]：VoxBox 的属性标签服务可控 TTS，但评估仍需独立框架。
- [[方向/AI语音/知识/技术路线/语音生成 tokenizer codec 技术路线|语音生成 tokenizer codec 技术路线]]：VoxBox 支撑 Spark-TTS 的 speech token / codec LM 路线。
- [[方向/AI语音/数据集/VCTK|VCTK]]、[[方向/AI语音/数据集/OpenSLR|OpenSLR]]：VoxBox 聚合和依赖的公共语料生态入口。

## 8. 待验证

- VoxBox 的各子语料许可证在目标使用场景中是否允许训练、发布权重和商业部署。
- Hugging Face 体积口径 4.84 TB 与 GitHub 完整下载说明 5.82 TB 的差异来自压缩、LFS 版本还是统计口径。
- Spark-TTS 官方训练代码何时发布，以及是否能复现论文里的数据清洗和属性标注流程。


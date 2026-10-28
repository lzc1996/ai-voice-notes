---
title: StableToken
类型: 模型
发表时间: 2025-09
时间依据: arXiv 首次提交日
任务:
  - 语音表示
  - 语音理解
相关主题:
  - 语音 tokenizer
  - SpeechLLM
相关模型:
  - "[[方向/AI语音/模型/SELM]]"
开放状态: []
aliases: []
tags:
  - 类型/对象
  - 方向/AI语音
---
# StableToken

## 0. 背景

- **UED 降 60%+**：多种噪声条件下 Unit Edit Distance 从 26.17% → 10.17%，同时保持顶级重建保真。
- **SpeechLLM 鲁棒性直接受益**：token 稳定 → 语音理解与语音生成两类下游任务都更鲁棒，是"增强—理解一体化"（[[方向/AI语音/知识/LLM 与 Agent 对语音增强的影响|LLM 与 Agent 对语音增强的影响]] 主线）的输入侧关键件。
- **开源**：代码 + 权重全公开，可直接接 SpeechLLM 链路。

## 1. 身份

`StableToken`（arXiv:2509.22220，ICLR 2026）是腾讯 WeChat AI + 北大提出的**抗噪语义语音 tokenizer**：为 SpeechLLM 提供**对声学扰动稳定**的语义 token。规格：帧率 25 Hz、码本 8,192、约 325 BPS，开源（Apache 系 / 官方仓库 Tencent/StableToken，权重在 HF `tencent/StableToken`）。

边界：它是**语义 tokenizer**（类 [[方向/AI语音/知识/基础概念/SSL 编码器|SSL 编码器]] + 离散化的定位），不是波形还原用声学 codec（[[方向/AI语音/知识/基础概念/NAC（神经音频 Codec）|NAC]] 类）；目标是让 SpeechLLM 的输入 token 在噪声、混响等**与语义无关的声学扰动**下保持稳定。

## 2. 问题

现有语义 tokenizer（如 SSL + k-means / LFQ 系）很脆：即使 SNR 高到语音完全可懂，**与语义无关的声学扰动也会让 token 序列大变**（Unit Edit Distance 可到 26%+）。原因有二：

- 单路径量化架构脆弱（一个分支错，整体错）。
- 训练信号离中间 token 太远，模型不关心 token 层稳定性。

## 3. 核心机制

两个创新协同：

1. **Voting-LFQ 模块**：在 LFQ（lookup-free quantization）基础上做**多分支并行量化**，各分支对同一输入并行处理，用**可微的 bit 级多数投票**合并成单一稳定 token 序列——纠错发生在 bit 级而非粗粒度 token 级。
2. **噪声感知共识训练**：训练时给模型多个"视图"——多数分支看干净输入，随机少数分支看扰动输入；用共识损失把扰动分支拉向干净共识，强制对声学扰动不变。

## 4. 使用注意

- **定位**：输入侧语义表示，不是输出侧波形还原；与声学 codec 的职责要分清。
- **规格**：25 Hz / 325 BPS 是语义 token 的典型低比特率，适合 LLM 上下文压缩；重建保真靠配套 decoder。
- **对比口径**：评测看 Unit Edit Distance（token 稳定性）+ 重建指标（保真）+ 下游 SpeechLLM 任务（理解 / 生成）。

## 5. 关键来源

- [StableToken: A Noise-Robust Semantic Speech Tokenizer for Resilient SpeechLLMs](https://arxiv.org/abs/2509.22220)
  - 内容定位：原始论文，Voting-LFQ + 噪声感知共识训练。
  - 用途：方法机制、规格与评测结果。
  - 核验日期：2026-08-11
- [Tencent/StableToken GitHub](https://github.com/Tencent/StableToken)
  - 内容定位：官方代码仓库。
  - 用途：训练 / 推理 / 集成 SpeechLLM 的代码入口。
  - 核验日期：2026-08-11
- [tencent/StableToken - Hugging Face](https://huggingface.co/tencent/StableToken)
  - 内容定位：官方权重与 README。
  - 用途：下载权重与快速接入。
  - 核验日期：2026-08-11

## 6. 相关对象

- [[方向/AI语音/知识/基础概念/SSL 编码器|SSL 编码器]]：语义 tokenizer 的表示来源（WavLM / HuBERT 类）。
- [[方向/AI语音/知识/技术路线/语音生成 tokenizer codec 技术路线|语音生成 tokenizer codec 技术路线]]：tokenizer / codec 路线全景。
- [[方向/AI语音/知识/基础概念/NAC（神经音频 Codec）|NAC]]：声学 codec 与语义 tokenizer 的分工对照。
- [[方向/AI语音/模型/SELM|SELM]]、[[方向/AI语音/模型/UniSE（Unified Speech Enhancement）|UniSE]]：token + LM 做增强 / 恢复的路线。
- [[方向/AI语音/知识/技术路线/LLM 与 Agent 对语音增强的影响|LLM 与 Agent 对语音增强的影响]]：SpeechLLM 输入稳定性的动机背景。

## 7. 待验证

- 在中文、强混响、codec 伪影场景下与 WavLM + k-means、现有 LFQ tokenizer 的直接对比。
- 接入 vault 目标链路（增强前端 → SpeechLLM）后对下游任务的净收益。
- 与声学 codec（DAC 类）级联时的稳定性表现。

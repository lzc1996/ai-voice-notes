---
title: XTTS-v2
类型: 模型
发表时间: 2024-06-07
时间依据: 论文 arXiv v1 首次提交日（2024-06-07）；XTTS-v2 模型先于论文随 Coqui TTS 工具包释出
任务:
  - TTS
开放状态:
  - paper
  - code
  - weights
aliases:
  - XTTS v2
  - XTTS
  - xtts
tags:
  - 类型/对象
  - 方向/AI语音
  - 任务/TTS
---

# XTTS-v2

## 0. 背景

**问题现场**：zero-shot 声音克隆 TTS 需要广泛的多语言覆盖与免转录的易用部署。

**前序路线的缺口**：此前的多语言 zero-shot TTS 只覆盖少数高资源语言。

**XTTS-v2 的切入点**：在 16 种语言上训练（build upon Tortoise），只需参考音频即可克隆、支持跨语言合成，且部署实践中不需要参考音频的转录文本。

## 1. 身份

XTTS（v2 为其主力开源版本）是 Coqui 推出的**多语言 zero-shot TTS 系统**,目标是解决此前多语言 zero-shot TTS 只覆盖少数高资源语言的问题：在 16 种语言上训练，官方口径称在其中多数语言达到当时 SOTA。声音克隆只需参考音频，部署实践中不需要参考音频的转录文本。

它是「免转录克隆」路线中最早被广泛部署的开源模型之一；技术血统上 build upon Tortoise，为 multilingual 训练、克隆质量与推理速度做了多项改造。

## 2. 核心信息

- **任务面**：多语言 zero-shot voice cloning + TTS；支持短参考音频克隆与跨语言合成（用 A 语言参考说 B 语言文本）。
- **开放状态**：代码在 coqui-ai/TTS 仓库（MPL-2.0）；模型权重受 **Coqui Public Model License（CPML）** 约束，**非商用**，且无官方商用授权通道。
- **维护状态**:Coqui AI 于 2024-01 关停，原仓库不再由创始团队官方维护，社区以 fork 延续维护。
- **生态意义**：因免转录 + 多语言 + 易于本地部署，长期是开源声音克隆事实基线之一，也是后续模型（如 [[方向/AI语音/模型/MaskGCT|MaskGCT]]）论文中的标准对照。

## 3. 核心机制

公开摘要层面的口径：沿用 Tortoise 系「GPT 式自回归主干 + 声学解码」结构，参考音频经 speaker 条件路径注入，文本侧不需要提供参考音频转录。细节（声学 token 方案、解码器组成、v2 相对 v1 的具体改动）未在本页核实，见「待验证」。

## 4. 测试基准与性能

- 官方口径：在 16 种训练语言中的多数达到 SOTA（论文摘要表述，未逐语言复核数字）。
- 第三方语境：MaskGCT 等后续论文的 Seed-TTS-Eval 对照表中包含 XTTS-v2，可作横向参考。

## 5. 边界

- **许可证是硬约束**：权重 CPML 非商用；商用场景需改用其他模型（如 Apache 2.0 的 [[方向/AI语音/模型/Confucius4-TTS|Confucius4-TTS]] 或 MIT 的 [[方向/AI语音/模型/AuK|AuK]])。
- 原公司关停，安全修复与更新依赖社区 fork。
- 长文本稳定性与跨语言口音控制属老一代水平，与 2025 年后的模型有代差。

## 6. 相关对象

- [[方向/AI语音/MOC - TTS]]：任务入口。
- [[方向/AI语音/模型/AuK]]：免转录克隆路线的后续统一基座实例。
- [[方向/AI语音/模型/MaskGCT]]：论文互相对照的免转录路线代表。
- [[方向/AI语音/模型/Confucius4-TTS]]：同为免转录 + 跨语言克隆，许可证更宽松。
- [[方向/AI语音/知识/基础概念/Zero-shot Voice Cloning（零样本声音克隆）]]：任务概念入口。

## 7. 关键来源

- [XTTS: a Massively Multilingual Zero-Shot Text-to-Speech Model（arXiv:2406.04904）](https://arxiv.org/abs/2406.04904)
  - 内容定位：论文主页；明确「build upon Tortoise」、16 语言训练与多语言 zero-shot 动机。
  - 用途：模型定位与训练规模的一手出处。
  - 发表日期：2024-06-07（arXiv v1）
  - 核验日期：2026-09-15
- [coqui-ai/TTS（GitHub）](https://github.com/coqui-ai/TTS)
  - 内容定位：官方代码仓库，XTTS-v2 的加载与推理入口。
  - 用途：确认代码开放状态与部署方式；仓库本身已归档/停更。
  - 核验日期：2026-09-15
- [Local TTS & Voice Cloning Licenses 2026（PromptQuorum）](https://www.promptquorum.com/power-local-llm/local-tts-voice-cloning-piper-coqui-xtts)
  - 内容定位：二手梳理；区分代码 MPL-2.0 与权重 CPML 非商用两层许可，记录 Coqui 2024-01 关停。
  - 用途：许可证与维护状态口径；建议以 CPML 许可证原文复核。
  - 核验日期：2026-09-15

## 8. 待验证

- 「免转录」条件路径的论文/官方文档原文表述（当前为部署实践口径）。
- v2 相对 v1 的架构改动清单；声学 token 与解码器细节。
- XTTS-v2 的确切首次发布日期（随 Coqui TTS 哪个版本释出）。

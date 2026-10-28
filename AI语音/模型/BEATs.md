---
title: BEATs
类型: 模型
发表时间: 2022-12
时间依据: arXiv 2212.09058 于 2022-12 提交；正式发表于 ICML 2023（PMLR v202）
任务:
  - 通用音频表征预训练
  - 音频分类
开放状态: open
aliases:
  - BEATs
  - 预训练 BEATs
  - Bidirectional Encoder representation from Audio Transformers
tags:
  - 类型/对象
  - 方向/AI语音
团队: Microsoft（MSRA + Redmond，合作方哈尔滨工业大学、南开大学）
许可证: MIT（microsoft/unilm 仓库）
相关模型:
  - "[[方向/AI语音/模型/Spatial-Omni|Spatial-Omni]]"
---
# BEATs

## 0. 背景

**1) 问题现场**：通用音频（含环境声、音乐、人声等非语音事件）的自监督预训练长期以**特征重建损失**为主流——当时的 SOTA 音频 SSL 模型（Audio-MAE、SS-AST 等）都在重建时频特征。但重建目标只约束低层时频细节的正确性，被认为缺少高层语义抽象；语言、视觉、语音侧的 SSL 均已转向**离散标签预测**，音频侧却迟迟没有跟上。

**2) 前序路线的缺口**：离散标签预测需要语义丰富的离散标签，而音频是连续信号，又没有语音那样的 phoneme 转写可用，通用音频的声学 tokenizer 难以获得——这是重建范式一直占主导的直接原因。此外 Gong 等发现把语音 SSL 模型直接搬到音频域效果不佳，通用音频建模不能简单复用 HuBERT/wav2vec 2.0 的做法。

**3) BEATs 的切入点**：不追求一次训出完美 tokenizer，而是**迭代框架**——第一轮用随机投影当 tokenizer，以掩码+标签预测训练音频 SSL 模型；再用训好的（或微调后的）SSL 模型蒸馏出语义更丰富的声学 tokenizer，喂给下一轮。tokenizer 与 SSL 模型交替优化、互相提升。

## 1. 身份

BEATs（Bidirectional Encoder representation from Audio Transformers）是微软提出的**通用音频表征预训练框架**：以掩码+离散标签预测为预训练目标、由声学 tokenizer 与音频 SSL 编码器迭代联合优化的 ViT 类模型。

边界：

- 它是**表征模型/编码器**，不生成音频，也不是语音识别专用模型；目标输出是可迁移的通用音频表征，主战场是音频分类。
- 与 HuBERT 等语音 SSL 的区别：面向通用音频（AudioSet 事件分类这类任务），标签来自学到的声学 tokenizer 而非语音转写。
- 论文标题在 arXiv 初版与 ICML 版间措辞有差异（"Pre-Trainings for Audio Classification" → "Audio Pre-Training with Acoustic Tokenizers"），指同一工作。

## 2. 核心信息

- **输入**：16 kHz 音频 → 128 维 Fbank（梅尔谱）→ patch 化为序列。
- **骨干**：ViT-Base 双向编码器（参数量约 90M，见 §9 待验证）。
- **输出**：音频语义表征；分类任务上加微调头或线性探针。
- **任务定位**：AudioSet 事件分类、ESC-50、Speech Commands 等通用音频分类；在下游多模态/空间音频工作中常被**冻结**作语义底座（见 §7）。

## 3. 核心机制

数据流（预训练）：

```text
16kHz 音频 -> 128 维 Fbank -> patch embedding
  -> 块状掩码，仅可见 patch 进 ViT-Base 编码器
  -> 预测器在掩码位置预测声学 tokenizer 给出的离散标签
  -> 交叉熵损失（掩码+标签预测）
```

- **声学 tokenizer**：由上采样卷积层、随机初始化的 softmax 矩阵（码本）与 bi-GRU 聚合层组成；第一轮迭代直接用随机投影产生标签。
- **tokenizer 蒸馏**：从预训练（或 AudioSet 微调后的）BEATs 蒸馏语义知识训练下一代 tokenizer，使其产出的离散标签"语义丰富"——即同一标签覆盖语义相近的声音模式，类似人脑对声音类别的聚类。
- **迭代闭环**：随机投影 tokenizer → BEATs(1) → 蒸馏 tokenizer(2) → BEATs(2) → …；官方按迭代轮次发布 checkpoint（iter1/2/3 等，命名与发布细节见 §9）。

## 4. 测试基准与性能

- **AudioSet-2M**：mAP **50.6%**（微调），当时的纯音频（audio-only）SOTA，且不使用任何外部数据——摘要口径。
- **ESC-50**：微调准确率 **98.1%**。
- 论文称显著超越使用更多数据与参数的先前模型；AudioSet-20K、Speech Commands V2 等分项数字见 §9 待验证。

## 5. 边界

- 预训练目标是**事件级语义分类**导向的表征；对需要低层时频细节的任务（如语音去噪、波形级生成）并非原生强项，用作冻结编码器时需评估表征适配性。
- tokenizer 语义蒸馏依赖 AudioSet 标签，语义覆盖范围受 AudioSet 本体约束。
- 在 FOA/阵列场景中，BEATs 原生只接受单声道谱输入；常见做法是只取全指向 W 通道送入（Spatial-Omni 的做法，见 §7），空间信息需另设分支——BEATs 本身不含任何空间能力。

## 6. 发展脉络

- arXiv 初版（2022-12）→ ICML 2023 正式发表；官方 checkpoint 随迭代轮次更新（BEATs、BEATs2 至 iter3 及微调版）。
- 后续被广泛用作多模态与空间音频模型的**冻结音频语义编码器**组件；具体下游采纳清单见 §9 待验证。

## 7. 相关对象

- [[方向/AI语音/模型/Spatial-Omni|Spatial-Omni]]：以预训练 BEATs 的 patch embedding 为 SO-Encoder 语义分支底座，承接 FOA 全指向 W 通道输入。
- [[方向/AI语音/知识/基础概念/B-format（一阶 Ambisonics）|B-format]]：上述用法中 W 通道即 B-format 的全指向分量。
- Audio-MAE / SS-AST：前序重建式音频 SSL（论文中的对照基线，本库暂无独立页）。
- HuBERT / wav2vec 2.0：语音侧离散标签预测范式的来源，BEATs 把该范式引入通用音频。

## 8. 关键来源

- [BEATs: Audio Pre-Training with Acoustic Tokenizers — arXiv 2212.09058](https://arxiv.org/abs/2212.09058)
  - 内容定位：原始论文，迭代框架、tokenizer 结构与 AudioSet/ESC-50 指标的出处。
  - 用途：本页 §0–§6 的主要依据。
  - 核验日期：2026-10-26
- [BEATs — ICML 2023（PMLR v202）](https://proceedings.mlr.press/v202/chen23ag/chen23ag.pdf)
  - 内容定位：正式发表版，确认作者名单与发表信息。
  - 用途：发表时间与团队口径。
  - 核验日期：2026-10-26
- [microsoft/unilm（BEATs 代码与预训练权重）](https://aka.ms/beats)
  - 内容定位：官方实现与 checkpoint 分发入口（MIT 许可）。
  - 用途：开放状态与获取途径。
  - 核验日期：2026-10-26

## 9. 待验证

- 参数量（约 90M，ViT-Base）与掩码比例等训练细节未对照论文正文逐项核实。
- 各 checkpoint（iter1/2/3、微调版 +）的精确命名、对应迭代与分项指标（AudioSet-20K、Speech Commands V2 等）未整理。
- 下游采纳情况（哪些多模态/空间音频模型以 BEATs 为冻结编码器）未系统核实，目前仅 Spatial-Omni 一例在本库有据。

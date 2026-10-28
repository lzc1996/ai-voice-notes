---
title: HuBERT
类型: 模型
参数量: Base ~95M；Large ~316M；X-Large ~1B
发表时间: 2021-06-14
时间依据: arXiv 首次提交日
任务:
  - ASR
开放状态:
  - paper
  - code
  - weights
aliases:
  - Hidden-Unit BERT
  - HuBERT encoder
  - Facebook AI HuBERT
tags:
  - 类型/对象
  - 领域/AI语音
  - 主题/语音表示
  - 任务/ASR
---

# HuBERT

## 0. 背景

**问题现场**：如何从海量无标注语音中自监督学到可迁移的帧级语音表示，支撑低标注 ASR 与语义 speech token 等下游任务。

**前序路线的缺口**：同为自监督路线的 wav2vec 2.0 在低标注 fine-tune 条件下的表示质量仍有提升空间，HuBERT 在多个子集上匹配或超过它。

**HuBERT 的切入点**：离线聚类（k-means）生成帧级 pseudo-label，Transformer 对 span-masked 区域做 hidden-unit 预测，并以"聚类 → masked prediction → 重聚类"迭代让表示与标签共同变好。

## 1. 内容定位

HuBERT（Hidden-Unit BERT）是 Meta / Facebook AI 提出的自监督语音表示模型。它把语音波形编码成逐帧 hidden states，主要作为 ASR、语音表示学习、语义 speech token、voice conversion 或生成式语音系统的上游 encoder。

边界：HuBERT 不是完整 ASR 产品，也不是 vocoder / audio codec；它学习的是语音表示或 hidden units，是否转写、生成或重建波形取决于下游 head、LM、codec 或 vocoder。

## 2. 核心机制

- 先用离线聚类（常见起点是 MFCC + k-means）给无标注语音生成 frame-level pseudo-label。
- 对连续语音特征做 span masking，让 Transformer 只在 masked 区域预测对应 hidden-unit cluster。
- 通过“聚类 -> masked prediction -> 用学到的表示重新聚类”的迭代，让 pseudo-label 和表示一起变好。
- 训练目标更依赖聚类标签的一致性，而不是每个 cluster 一开始就精准对应音素。

## 3. 核心公式

- 离线聚类生成 pseudo-label（第一步，特征常用 MFCC）：

$$q_t = \arg\min_k \left\| \mathbf{z}_t - \mathbf{c}_k \right\|_2^2$$

说明：$\mathbf{z}_t$ 为第 $t$ 帧特征，$\{\mathbf{c}_k\}_{k=1}^{K}$ 为 k-means 聚类中心，$q_t \in \{1,\dots,K\}$ 为帧级 pseudo-label（hidden unit）。

- soft-label 交叉熵（masked prediction 主目标）：

$$\mathcal{L} = -\sum_{t \in \mathcal{M}} \sum_{k=1}^{K} p(k \mid t) \log P(k \mid \tilde{X}, t)$$

说明：$\tilde{X}$ 为做过 span masking 的输入，$\mathcal{M}$ 为被遮住的帧集合；只对 masked 帧计算损失。

- soft label 与迭代重聚类：

$$p(k \mid t) = \frac{\exp\left(\hat{\mathbf{h}}_t \cdot \hat{\mathbf{c}}_k / \tau\right)}{\sum_{k'} \exp\left(\hat{\mathbf{h}}_t \cdot \hat{\mathbf{c}}_{k'} / \tau\right)}, \qquad q^{(r)} = \mathrm{kmeans}\left(\{\mathbf{h}_t^{(r)}\}\right)$$

说明：$p(k\mid t)$ 用模型输出 $\hat{\mathbf{h}}_t$ 与聚类中心 $\hat{\mathbf{c}}_k$ 的相似度（温度 $\tau$）做软标签，避免硬标签与输出空间错位；第 $r$ 轮训练结束后用新学到的表示 $\mathbf{h}_t^{(r)}$ 重新聚类，生成下一轮 pseudo-label $q^{(r)}$，迭代提升。

## 4. 测试基准与性能

**测试基准**（来源：HuBERT 论文）

- 预训练设置：LibriSpeech（960h）与 Libri-Light（60,000h）。
- fine-tune 数据子集：10min / 1h / 10h / 100h / 960h。
- 评测集：dev-other / test-other（论文摘要口径）。
- 对比基线：wav2vec 2.0（论文）。

**性能指标**

- HuBERT 1B 模型相对当时 SOTA：dev-other 上 WER 相对降低 19%、test-other 上 13%（arXiv 摘要）。
- 绝对 WER 数值（各模型规模 × fine-tune 子集）：待核。
- 匹配 / 超过 wav2vec 2.0 的结论见上文「为什么有用」，不重复。

## 5. 为什么有用

- **低标注 ASR**：论文显示 HuBERT 在 LibriSpeech 960h 和 Libri-Light 60k 预训练设置下，多个 fine-tuning 子集上匹配或超过 wav2vec 2.0。
- **语义 speech token**：hidden units / 离散聚类单元能作为语音语言模型、speech tokenizer 或 voice conversion 的语义侧输入。
- **通用 speech encoder**：Hugging Face 提供 `HubertModel`、`HubertForCTC`、sequence classification 等接口，方便在 Transformers 生态里接入。

## 6. 使用注意

- HuBERT Base / Large / X-Large 的训练数据和参数规模差异很大；比较结果时要同时看模型大小、预训练语料和 fine-tuning 数据。
- ASR 复现要区分 pretrained checkpoint、CTC fine-tuned checkpoint、解码方式和语言模型。
- 做语音增强、分离或 diarization 时，[[方向/AI语音/模型/WavLM|WavLM]] 往往是更直接的 baseline；HuBERT 更适合看 hidden-unit / semantic token 路线。
- 中文、方言、噪声、混响或近场外场景下的层选择和冻结策略需要单独验证。

## 7. 相关对象

- [[方向/AI语音/知识/基础概念/SSL 编码器|SSL 编码器]]：HuBERT 是 cluster / masked unit prediction 路线代表。
- [[方向/AI语音/模型/WavLM|WavLM]]：同属自监督语音表示模型；WavLM 更强调 full-stack speech processing 和鲁棒条件。
- [[方向/AI语音/MOC - ASR|ASR]]：HuBERT 常作为低标注 ASR 的预训练 encoder。
- [[方向/AI语音/知识/技术路线/语音模型 tokenizer 与 LLM tokenizer 对比|语音模型 tokenizer 与 LLM tokenizer 对比]]：HuBERT hidden units 是 semantic speech token 的重要来源。

## 8. 关键来源

- [HuBERT: Self-Supervised Speech Representation Learning by Masked Prediction of Hidden Units](https://arxiv.org/abs/2106.07447)
  - 内容定位：原始论文，记录离线聚类、masked hidden-unit prediction、迭代聚类和 LibriSpeech / Libri-Light 评测。
  - 用途：理解模型机制和论文层面的性能结论。
  - 核验日期：2026-07-30
- [Meta AI - HuBERT: Speech representations for recognition & generation](https://ai.meta.com/blog/hubert-self-supervised-representation-learning-for-speech-recognition-generation-and-compression/)
  - 内容定位：Meta 官方发布说明，解释 clustering + prediction 机制，以及 recognition、generation、compression 使用场景。
  - 用途：确认官方定位和应用边界。
  - 核验日期：2026-07-30
- [fairseq HuBERT example](https://github.com/facebookresearch/fairseq/tree/main/examples/hubert)
  - 内容定位：官方 fairseq 入口，提供 pretrained / fine-tuned checkpoints、训练、fine-tuning 和 decoding 流程。
  - 用途：复现实验和查 checkpoint。
  - 核验日期：2026-07-30
- [Hugging Face Transformers - HuBERT](https://huggingface.co/docs/transformers/model_doc/hubert)
  - 内容定位：Transformers 模型文档，记录 `HubertModel`、`HubertForCTC` 等工程接口。
  - 用途：快速接入 Python / Transformers 生态。
  - 核验日期：2026-07-30

## 9. 待验证

- 当前语音生成 / voice conversion 论文更常用 fairseq HuBERT checkpoint 还是 Transformers checkpoint。
- 对中文语音任务，HuBERT、WavLM、Whisper encoder 的冻结层和中间层选择差异。
- HuBERT hidden units 在当前 speech tokenizer 路线里是否仍是首选，还是已被 codec / VAE latent 替代。
- HuBERT Base / Large / X-Large 在各 fine-tune 子集（10min–960h）上的绝对 WER（test-clean / test-other）待核（论文正文表格未抓取）。

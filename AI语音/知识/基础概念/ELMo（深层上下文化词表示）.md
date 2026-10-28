---
title: ELMo（深层上下文化词表示）
类型: 概念
发表时间: 2018-02-15
时间依据: Peters et al.「Deep contextualized word representations」arXiv v1 首次提交日（2018-02-15）；NAACL 2018 正式发表
相关主题:
  - 语音表示
相关模型:
  - "[[方向/AI语音/模型/AuK]]"
aliases:
  - ELMo
  - elmo
  - 深层上下文化词表示
  - 深度上下文化词表示
  - Embeddings from Language Models
  - Deep contextualized word representations
  - ELMo 式层融合
tags:
  - 类型/对象
  - 方向/AI语音
  - 主题/语音表示
---

# ELMo（深层上下文化词表示）

## 1. 身份

ELMo（Embeddings from Language Models）是 Peters et al. 2018（AI2 / 华盛顿大学）提出的预训练表示方法，两个首创定义了它：

- **上下文化**：静态词嵌入（word2vec / GloVe）给每个词型一个固定向量；ELMo 在大规模语料上训练双向 LSTM 语言模型（biLM），每个 token 的表示随上下文变化，多义词自然消解。
- **全层融合**：表示不取顶层，而是 biLM **全部层**（含与上下文无关的字符 CNN token 层）的可学习加权和——「ELMo 式」层融合由此得名。

范式定位上，ELMo 是 **feature-based 迁移**的代表：冻结 LM，把表示当特征喂给任务模型，与随后 ULMFiT / GPT / BERT 的 fine-tuning 路线相对。2018 年一口气刷新 6 个 NLP 任务 SOTA（SQuAD、SNLI、SRL、coref、NER、SST-5），是 BERT 时代到来的前奏。

## 2. 核心机制

### 2.1. 层加权和公式

biLM 前向、后向各 $L$ 层，token $k$ 共 $2L+1$ 个表示：$\mathbf{h}_{k,0}$（字符 CNN token 层）与 $\mathbf{h}_{k,j}=[\overrightarrow{\mathbf{h}}_{k,j};\overleftarrow{\mathbf{h}}_{k,j}]$（第 $j$ 层双向拼接）。ELMo 对每个任务学一套混合：

$$\mathrm{ELMo}_k^{\mathrm{task}} = \gamma^{\mathrm{task}} \sum_{j=0}^{L} s_j^{\mathrm{task}} \cdot \mathbf{h}_{k,j}, \qquad \mathbf{s} = \mathrm{softmax}(\mathbf{w})$$

三个要素：

1. **每层一个可学习 logit** $w_j$，softmax 归一化成 $s_j$——权重和为 1，可解释为任务的「层配方」；
2. **整体缩放** $\gamma$：各层数值尺度不同，给任务一个总增益旋钮；
3. $w,\gamma$ 随任务模型一起训练，LM 本身冻结；论文另提到可选地对每层先 LayerNorm 再加权。

### 2.2. 为什么要全部层：层分工的证据

论文的逐层探针分析：**低层偏句法**（POS 标注用低层表示最好），**高层偏语义**（词义消歧用高层最好）。不同任务的最优层组合不同，固定取顶层必然顾此失彼——这是「加权全部层」的实证依据，也是它后来成为配方的理由。

### 2.3. 与静态嵌入的关系

ELMo 不替换静态嵌入而是叠加：任务模型把 $\mathrm{ELMo}_k$ 与 GloVe 式词向量拼接作为输入（部分任务在输出端再拼一次）。上下文信息全由 ELMo 部分供给。

## 3. 历史位置

word2vec / GloVe（静态，一词一向量）→ **ELMo**（上下文化 + feature-based）→ ULMFiT / GPT / BERT（上下文化 + fine-tuning）。BERT 论文明确把 ELMo 列为 feature-based 路线的代表并选择了 fine-tuning；但 ELMo 的「取全部层、可学习加权和」没有随 feature-based 式微而消失，而是转入自监督表示的下游评测，成为标准配方（见 §5）。

## 4. 在 AuK 中的角色

[[方向/AI语音/模型/AuK|AuK]] 的语义条件 $c_{\mathrm{sem}}$ 是 ELMo 公式在 MLLM 上的逐字复刻：冻结的 [[Qwen2.5-Omni|Qwen2.5-Omni]] 各层 hidden states 先逐层 LayerNorm，再经 softmax 可学习权重加权、乘可学习标量：

$$c_{\mathrm{sem}} = \gamma \cdot \sum_{\ell} \mathrm{softmax}(\mathbf{w})_\ell \cdot \mathrm{LayerNorm}\!\big(\mathbf{h}^{(\ell)}\big)$$

（开源实现见 `src/auk/model/cfm_edit.py` 的 `layer_weights` / `layer_scale`。）逐层 LayerNorm 是相对原文的现代化补丁——Transformer 各层数值尺度差异远大于 LSTM，不归一化则加权退化成「谁数值大谁主导」。

动机与 ELMo 同构：AuK 的语义条件要同时服务**指令的高层语义**（偏 LLM 高层）与**参考音频的音色/韵律线索**（偏 audio encoder 中低层），选任何单一固定层都会丢掉一头；可学习权重让训练为五族任务各自找到层配方。权重训练后冻结，保证条件分布在训练与推理间一致（详见 [[方向/AI语音/模型/AuK#3.6. 语义编码器为何选 Qwen2.5-Omni|AuK §3.6]]）。

## 5. 谱系：SSL 特征加权一脉

SUPERB 基准（Yang et al. 2021）把「冻结 SSL 编码器 + 全部 Transformer 层可学习加权和」定为 wav2vec 2.0 / [[方向/AI语音/模型/HuBERT|HuBERT]] 下游任务的**标准做法**——即 ELMo 公式原样搬进语音。[[方向/AI语音/知识/基础概念/SSL 编码器|SSL 编码器]] §4「最后一层不一定最好，增强和说话人任务常需中间层或多层平均」是同一条经验的口语版。AuK 的层融合即属 ELMo / SSL 特征选择这一脉，见 [[方向/AI语音/模型/AuK#7. 技术脉络|AuK §7]]。

## 6. 相关对象

- [[方向/AI语音/模型/AuK]]：ELMo 式层融合在 MLLM 语义条件上的近期大规模实例（§4）。
- [[方向/AI语音/知识/基础概念/SSL 编码器]]：语音侧自监督表示选型口径；「取哪层」问题与层融合互为解法。
- [[Qwen2.5-Omni]]：AuK 中被做层融合的冻结编码器。

## 7. 关键来源

- [Deep contextualized word representations（arXiv:1802.05365）](https://arxiv.org/abs/1802.05365)
  - 内容定位：Peters et al. 2018，ELMo 原始论文；层加权和公式、逐层句法/语义分析、6 任务 SOTA 的出处。
  - 用途：本页 §1–§3 的一手出处。
  - 核验日期：2026-09-24
- [SUPERB: Speech processing Universal PERformance Benchmark（arXiv:2105.01051）](https://arxiv.org/abs/2105.01051)
  - 内容定位：Yang et al. 2021，把「冻结 encoder + 全层可学习加权和」定为 SSL 语音表示下游评测的标准配方。
  - 用途：本页 §5「ELMo 式融合转入语音」的依据。
  - 核验日期：2026-09-24
- [AuK Technical Report（arXiv:2609.08936）](https://arxiv.org/abs/2609.08936)
  - 内容定位：§3.2 记录 Qwen2.5-Omni 各层 hidden states 经 LayerNorm 后可学习加权求和的语义条件构造。
  - 用途：本页 §4 的一手出处。
  - 核验日期：2026-09-24

## 8. 待验证

- AuK 训练后的层权重分布未公开——语义条件实际由 Qwen2.5-Omni 哪些层主导，值得从官方权重读出一验。
- 逐层 LayerNorm 相对「直接加权」的实际增益在 AuK 中无消融（原文中归一化只是可选项）。
- ELMo 式加权与「只取某一层」「各层拼接后投影」在语音生成条件上的系统对比，公开文献中未见。

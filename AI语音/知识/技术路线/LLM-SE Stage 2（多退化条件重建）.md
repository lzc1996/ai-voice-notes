---
title: LLM-SE Stage 2（多退化条件重建）
类型: 技术路线
时间依据: 对话沉淀；非单一发表物
上级:
  - "[[方向/AI语音/知识/技术路线/LLM-SE Training Recipe（借鉴 NLP LLM 的语音增强训练配方）]]"
  - "[[方向/AI语音/知识/技术路线/LLM-SE Training Recipe v2（显式解耦训练配方）]]"
相关任务:
  - 语音增强
  - conditional reconstruction
  - multi-degradation training
aliases:
  - 阶段 2：Multi-Degradation Conditional Reconstruction
  - multi-degradation conditional reconstruction
  - degraded evidence conditioned clean token prediction
tags:
  - 类型/对象
  - 方向/AI语音
  - 任务/语音增强
  - 主题/大模型
  - 主题/训练
---

# LLM-SE Stage 2（多退化条件重建）

## 1. 目标

Stage 2 开始进入 LLM-SE 的核心：从退化观测恢复 clean semantic token。v2 显式解耦后，本阶段只负责**内容桶**：

$$
p(s_{clean} \mid e_{degraded},\, spk)
$$

其中 $e_{degraded}$ 是退化语音经 evidence encoder 得到的连续声学证据，$spk$ 是冻结 SV encoder 提取的 speaker embedding，$s_{clean}$ 是 clean semantic token（S3 式 ASR 监督 tokenizer 真值，见 [[方向/AI语音/知识/技术路线/LLM-SE Stage 0（表示空间准备）]] 2.1）。原始波形 $y_{degraded}$ 不直接进入 LLM，只通过 encoder 变成条件输入。

v2 真值来源原则：**输入从 degraded 提，target 从 clean 提**——所有监督信号从 x_clean 用冻结工具提取，噪声从结构上不可能进入监督信号。

与 v1 的关键差异：**Stage 2 不再混训 acoustic token**。v2 生成侧解耦为 $p(s)\,p(a \mid s)$，表现桶（连续 acoustic latent + prosody）由 [[方向/AI语音/知识/技术路线/LLM-SE Stage 3（声学保真）]] 的 FM-DiT 负责；Stage 2 词表里只有 semantic token，但 LM 同时带 prosody 辅助头与退化头（见 §4）。

## 2. Path A / Path B（如何利用 Stage 1）

Stage 1 学的是普通 next-token prediction：

$$
p(s_{clean})=\prod_t p(s_t \mid s_{<t})
$$

Stage 2 不是丢掉 NTP，而是把它改成 conditional NTP：

$$
p(s_{clean} \mid e_{degraded}, spk)=\prod_t p(s_t \mid s_{<t}, e_{degraded}, spk)
$$

也就是：仍然预测下一个 clean semantic token，但每一步额外看 degraded acoustic evidence 和 speaker 条件。Stage 1 提供 clean speech prior，Stage 2 学习"给定退化证据时，prior 应该收敛到哪条 clean token 序列"。

v2 两种路径：

- **Path B（prior-first）**：从 [[方向/AI语音/知识/技术路线/LLM-SE Stage 1（Clean Speech Token LM 预训练）]] 初始化，低 LR / 部分冻结保持 prior 锚定。优势是 clean prior 与 evidence grounding 解耦，便于使用 clean-only 数据和诊断 hard buckets。
- **Path A（直接条件训练）**：像 [[方向/AI语音/模型/UniSE（Unified Speech Enhancement）]] 一样直接训，工程更短、接口更统一；因为 target 就是 clean token，也会隐式学习 clean 分布。

paired 数据够、要快出 baseline 就走 Path A；Path A vs Path B 的对比属 v2 实验矩阵 B.1，方案成型后再做。

## 3. 条件如何接入 LLM（v2 条件侧）

v2 条件侧有两路，都**不进词表、不参与预测**：

```text
y_degraded
  -> evidence encoder（WavLM hidden + gated STFT/mel）
  -> e_degraded                  # continuous feature, not vocab token
  -> pooling / Q-Former 压缩
  -> z_1, z_2, ..., z_L           # soft condition embeddings 或 cross-attention memory

y_degraded
  -> 冻结 SV encoder
  -> speaker embedding            # utterance 级全局向量，prefix / FiLM 注入

s_clean shifted right
  -> token embedding lookup
  -> emb(s_1), emb(s_2), ...
```

要点：

- **evidence 禁止无门控直通**：必须经 pooling / Q-Former / Perceiver / adapter 压缩成 soft condition 或 cross-attention memory（详见 Stage 0 第 3 节）。
- **speaker embedding 是条件不是预测目标**：身份在输入里可读，做成目标等于给"换人"开口子（v2 设计决策备忘）。
- 压缩后 $L$ 与音频时长和压缩率相关；只有 Q-Former / resampler 才会压成固定几十个 latent slots。

训练时 loss mask 掉 continuous condition，只在 clean semantic token 上算 CE：

```text
input_embeds = concat(z_degraded, spk, Embed(s_clean_shifted))
labels       = [-100 ... -100, s_clean_targets]
```

更适合长音频的方式是 cross-attention：

```text
Encoder: e_degraded = EvidenceEncoder(y_degraded)
Decoder: Stage 1 LM initialized clean token decoder

self-attention: clean token history attends to clean token history
cross-attention: clean token hidden states attend to e_degraded
```

## 4. 训练目标（v2，按权重从大到小）

1. **semantic token NTP**（主任务）：teacher forcing，target = S3 tokenizer 从 x_clean 提取的 token。
2. **显式退化一致性**：同 batch 双退化采样（同一 clean 配两种退化实现），两次预测的 token 后验 KL（或隐状态 L2）。退化强度上限 = 内容仍可辨认；退化强到毁内容，一致性假设断裂。
3. **prosody 头 CE**：LLM 顶层 hidden 挂两层 MLP prosody 头，逐帧三路输出——F0（log-F0 约 256 bin 分类，CE）+ V/UV（BCE）+ energy（回归）；真值由 RMVPE / CREPE 从 x_clean 提取并池化到 token 帧率。预测结果在 Stage 3 条件化 DiT，细节见 [[方向/AI语音/知识/技术路线/LLM-SE Stage 3（声学保真）]]。
4. **退化头**：evidence encoder 挂退化分类 / 回归头（噪声类型 / SNR / RT60 / 带宽 / codec），标签 = 仿真流水线元数据（加噪时落盘，零成本）。

**辅助 loss 一律小权重，不得压过 NTP 主任务**（v2 训练稳定性规则）。

## 5. Evidence 不是 Oracle

`e_degraded` 不能天然区分真实音色和噪声。它来自：

```text
y_degraded = clean speech + noise / reverb / bandwidth loss / codec artifact
```

所以它必须被当成 noisy observation，而不是 clean representation。避免噪声泄漏的做法：

- 用 clean token 作为 target，让复制噪声被 loss 惩罚（噪声过滤靠"条件预测 clean target"的任务结构本身，不靠 evidence 表示自身干净）。
- 加 evidence bottleneck：pooling、Q-Former、Perceiver、low-rank adapter。
- 加 gate / confidence：低 SNR、强混响、speech absence 区间降低 evidence 权重。
- 分层使用：高层 SSL 给 LLM，低层 STFT/mel 只给 Stage 3 的 DiT。
- 靠 §4 的显式退化一致性，让 semantic 预测对不同噪声版本保持稳定。

核心平衡：**证据太弱会 hallucinate，证据太强会噪声直通。**

## 6. 退化类型与元数据

数据 mixture 要按退化机制分桶：

```text
additive noise
reverberation
bandwidth limitation
codec artifact
clipping
packet loss / dropout
wind noise
overlapping speaker
real-world microphone recordings
```

按桶看指标，不只看平均值；否则简单 additive noise 会掩盖 dereverb、BWE、declipping、packet loss 的失败。

v2 数据规则：

- **仿真退化存元数据**：噪声类型 / SNR / RT60 / 带宽 / codec 类型在加噪时落盘——退化头的免费标签。
- **同 batch 双退化采样**：同一 clean 每 batch 配两种退化实现，供显式一致性 loss 用。
- **target 侧只收头部质量**：DNSMOS / SIGMOS 打分过滤，target 只从最干净子集出；越噪的数据越只放输入侧。

## 7. 课程式 Mixture

Stage 2 不建议一开始就把所有复合退化全量混在一起。更稳的训练顺序是：

```text
single degradation
  -> two-factor compound degradation
  -> full multi-degradation + real-world recordings
```

推荐调度：

- **warm-up**：先用单一退化和中等难度样本，例如 additive noise、reverb、bandwidth limitation 单独出现，让模型学会 degraded evidence 到 clean token 的基本条件映射。
- **compound**：再加入二元组合，例如 noise + reverb、noise + bandwidth、codec artifact + packet loss，避免模型只学到单一噪声抑制。
- **full mixture**：最后加入真实录音、wind、overlap、clipping、强混响、低 SNR 等 hard buckets。
- **bucket floor**：每个退化桶保留最小采样比例，避免长尾任务被完全遗忘。
- **easy cap**：限制简单 additive noise 的比例，防止平均指标好看但 dereverb / BWE / packet loss 失败。
- **adaptive upsampling**：按 bucket-level validation 调整比例；高 loss、高 [[方向/AI语音/评估/WER（词错误率）]] / [[方向/AI语音/评估/CER（Character Error Rate）]]、低内容准确率或 speaker drift 明显的桶提高采样。
- **replay**：进入复合退化后仍保留单一退化 replay，避免模型学会复杂 mixture 后忘掉基础增强。

比例不要只按自然数据分布设定，而应按任务风险和验证集缺口动态调整。Stage 2 的目标不是拟合真实世界退化频率，而是让模型获得可迁移的条件恢复能力。

## 8. 和 SELM 的关系

[[方向/AI语音/模型/SELM]] 可以看成当前 Stage 2 路线的早期具体化：

```text
SELM:
  noisy waveform -> SSL + k-means token -> LM -> clean token -> HiFi-GAN

当前 Stage 2:
  degraded waveform -> continuous evidence + speaker embedding
  -> conditional clean semantic token prediction（S3 纯语义 token）
  (+ Stage 1 clean speech prior, Path B)
```

差别在于：SELM 主要把 SE 改写成 discrete token sequence modeling；当前 recipe 显式区分 continuous evidence、semantic token、speaker 条件，acoustic 生成分离到 Stage 3，并把 Stage 1 clean prior、Stage 3 acoustic fidelity、Stage 4 preference alignment 分开训练。

如果当前方案只做最小实现：SSL tokenizer、noisy-to-clean token LM、vocoder，就会退化成 SELM 风格 baseline。

## 9. 和 UniSE 的关系

[[方向/AI语音/模型/UniSE（Unified Speech Enhancement）]] 可视为 **Path A 形态的强 baseline**：WavLM 条件特征经 adapter 作为 decoder-only LM 的 prefix，模型自回归预测目标语音的 BiCodec tokens，再由 BiCodec decoder 还原 waveform。

当前 Stage 2 与 UniSE 的主要差异：

- UniSE 直接训练条件 clean token generation（Path A）；当前 recipe 允许先做 Stage 1 semantic prior 再接条件恢复（Path B）。
- UniSE 预测完整 codec token（语义 + 声学 + 全局说话人 token 一起进词表）；v2 词表只有纯语义 token，acoustic 走连续 latent 由 Stage 3 FM-DiT 生成，speaker 走连续 embedding 条件。
- UniSE 的 prefix 是音频长度相关的 WavLM condition；当前 recipe 要求 evidence 经压缩 / 门控（soft condition 或 cross-attention）。
- 当前 recipe 增加显式退化一致性、prosody 头、退化头三个辅助目标，并显式处理 imperfect clean target 的音质分布泄漏（质量过滤 + Stage 4 偏好对齐）。

## 10. 训练方案

```text
1. paired data: y_degraded, x_clean（退化元数据落盘；同 batch 双退化采样）
2. e_y = EvidenceEncoder(y_degraded); spk = SVEncoder(y_degraded)
3. s_x = S3Tokenizer(x_clean); prosody 真值 = RMVPE/CREPE(x_clean) 池化到 token 帧率
4. initialize LLM: Path B from Stage 1 / Path A 直接训
5. train adapter / cross-attn + LLM: NTP（主）+ 一致性 + prosody + 退化头（小权重）
```

v2 实施顺序中的位置：Stage 2 先以**最小闭环**跑通——仅 semantic NTP、无辅助头（Stage 0 -> S2 -> S3），之后再加 speaker 通道 + prosody 头，最后加退化头 + 显式一致性 loss。

推荐参数策略：

- early：freeze / very low-LR LLM，只训 acoustic adapter、projector、cross-attn。
- middle：打开 LoRA 或部分 LLM layers。
- late：小学习率 full finetune，或继续 LoRA。

典型学习率范围：

```text
adapter / projector: 1e-4 ~ 5e-4
cross-attn new params: 5e-5 ~ 2e-4
LLM LoRA: 5e-5 ~ 2e-4
LLM full finetune: 5e-6 ~ 2e-5
```

## 11. 验收标准

v2 指标分工：S2 看 **conditional recovery**。

- **conditional recovery**：degraded 条件下 clean semantic token 恢复质量（不看 clean token perplexity——那测的是 prior 不是条件恢复）。
- **noise-only probe**：喂纯噪声段不得凭空生成语音（信号 / 噪声边界检验）。
- **evidence ablation**：去掉 continuous evidence 后出现更明显 hallucination，说明 evidence branch 真有约束作用。
- 分桶看 [[方向/AI语音/评估/WER（词错误率）]] / [[方向/AI语音/评估/CER（Character Error Rate）]] / 内容准确率 [[方向/AI语音/评估/CAcc]]，改善不能伴随 speaker drift；不只看平均值。
- 辅助头 sanity：prosody 头 F0 预测有效（对比 Stage 0 真值）、退化头分类 / 回归准确率合理。

## 12. 主要风险

- LLM 用语言 prior 直接补内容，导致关键词、数字、专名被改。
- acoustic evidence 条件太弱，模型退化成纯 clean speech generator。
- acoustic evidence 条件太强（无门控直通），噪声、混响、channel 信息泄漏。
- 训练 mixture 被简单噪声主导，混响、削波、丢包能力没学到。
- long audio 用 soft prefix 过长，挤占上下文；必要时换 cross-attention 或 resampler。
- 辅助 loss 权重过大压过 NTP 主任务，或一致性 loss 用到毁内容的强退化上（假设断裂）。
- Path B 初始化时 LR 过高，Stage 1 prior 被 paired 数据分布冲掉。

## 13. 相关对象

- [[方向/AI语音/知识/技术路线/LLM-SE Training Recipe（借鉴 NLP LLM 的语音增强训练配方）]]
- [[方向/AI语音/知识/技术路线/LLM-SE Training Recipe v2（显式解耦训练配方）]]
- [[方向/AI语音/知识/技术路线/LLM-SE Stage 0（表示空间准备）]]
- [[方向/AI语音/知识/技术路线/LLM-SE Stage 1（Clean Speech Token LM 预训练）]]
- [[方向/AI语音/知识/技术路线/LLM-SE Stage 3（声学保真）]]
- [[方向/AI语音/模型/S3 Tokenizer]]
- [[方向/AI语音/模型/SELM]]
- [[方向/AI语音/模型/UniSE（Unified Speech Enhancement）]]
- [[方向/AI语音/模型/WavLM]]
- [[方向/AI语音/模型/Whisper]]
- [[方向/AI语音/模型/HuBERT]]
- [[方向/AI语音/知识/基础概念/FiLM（特征级线性调制）]]
- [[方向/AI语音/评估/WER（词错误率）]]
- [[方向/AI语音/评估/CER（Character Error Rate）]]
- [[方向/AI语音/评估/CAcc]]

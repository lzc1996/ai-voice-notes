---
title: LLM-SE Stage 1（Clean Speech Token LM 预训练）
类型: 技术路线
时间依据: 对话沉淀；非单一发表物
上级:
  - "[[方向/AI语音/知识/技术路线/LLM-SE Training Recipe（借鉴 NLP LLM 的语音增强训练配方）]]"
  - "[[方向/AI语音/知识/技术路线/LLM-SE Training Recipe v2（显式解耦训练配方）]]"
相关任务:
  - 语音增强
  - clean speech token modeling
  - language model pretraining
aliases:
  - 阶段 1：Clean Speech Token LM Pretraining
  - clean speech token LM pretraining
  - clean semantic speech prior
tags:
  - 类型/对象
  - 方向/AI语音
  - 任务/语音增强
  - 主题/语音表示
  - 主题/大模型
  - 主题/训练
---

# LLM-SE Stage 1（Clean Speech Token LM 预训练）

## 1. 目标

Stage 1 的目标是学习 clean speech semantic prior：

$$
p(s_{clean})
$$

这里的 $s_{clean}$ 是 **clean semantic tokens**——v2 定案为 S3 式 ASR 监督纯语义 tokenizer 产出（见 [[方向/AI语音/知识/技术路线/LLM-SE Stage 0（表示空间准备）]] 2.1），不是 fine acoustic codec tokens，也不是连续 acoustic latent。它要让 LLM 学会干净语音在音素、词级上下文、口语节奏和长程语义上的分布。

v2 定位：Stage 1 是**可选 Path B（prior-first）**，不是硬前置。像 [[方向/AI语音/模型/UniSE（Unified Speech Enhancement）]] 一样直接训练 Stage 2（Path A）也会因为 target 是 clean token 而隐式学习 clean 分布——paired 数据够、要快出 baseline 就走 Path A 跳过本阶段。Stage 1 的价值（v2 recipe 6.2）：

- 吃 clean-only 数据，降低 paired 数据压力；
- 把 clean prior 与 degraded evidence grounding 解耦，便于诊断 token 空间；
- 给 Stage 2 提供独立于 paired target 的"干净"锚点——v2 把"什么是信号"分散到四个锚点（表示解耦、退化不变性、质量过滤的 prior、感知 reward），本阶段对应**质量过滤的 prior** 这一锚。

## 2. Clean Speech Token Modeling

### 2.1. 流程示意（概念级）

```mermaid
flowchart LR
    A[高质量 clean waveform] --> B[S3 式 ASR 监督 semantic tokenizer\n冻结]
    B --> C[clean semantic tokens]
    C --> D[LM / speech LM]
    D --> E[clean semantic prior\np(s_clean)]
```

```text
clean waveform（质量过滤后子集）
  -> S3 式 ASR 监督 semantic tokenizer（冻结）
  -> clean semantic tokens s1, s2, ..., sT（25–50 Hz）
  -> LM learns p(s_clean)
```

自回归目标：

$$
p(s_{1:T})=\prod_t p(s_t \mid s_{<t})
$$

也可以做 masked semantic token reconstruction：

```text
masked clean semantic tokens -> reconstruct masked semantic tokens
```

但 Stage 1 的主线仍然是学习 clean-side prior，而不是开始处理真实声学退化。

**tokenizer 生命周期**：只在训练期出现——从 x_clean 提 token 当真值并 [[方向/大模型/训练/Teacher Forcing（教师强制）|teacher forcing]]；推理期 tokenizer 不上线，token 由 LLM 自回归生成。semantic token 不直接解码成音频，它作为自回归上下文塑造 LLM hidden state，hidden state 才是下游 FM-DiT 的接口。

## 3. Token 来源（v2 定案）

主路线：**S3 式 ASR 监督纯语义 tokenizer**（多语言 ASR encoder + FSQ，监督 = 文本转写，无 waveform 重建分支），token 帧率 25–50 Hz，SE 长序列场景优先 25 Hz；零训练 baseline 可用 CosyVoice 官方 speech tokenizer 先跑通。WavLM + kmeans 仅作对照 baseline（其 hidden states 做声纹任务极强，speaker 泄漏明显）。选型理由与纯度边界见 Stage 0 的 2.1 节。

帧率对齐按 Stage 0 约定执行：semantic token 池化 / 重采样到与 acoustic latent 匹配的帧率（约 25 Hz）。

暂时不要主训：

- fine RVQ / residual codec tokens；
- noisy codec tokens；
- 频谱 patch token；
- 需要 waveform reconstruction 才能成立的高码率声学 token；
- 连续 acoustic latent——v2 生成侧显式解耦为 $p(s)\,p(a \mid s)$，表现桶（acoustic latent + prosody）由 Stage 3 的 FM-DiT 负责，Stage 1 只管 $p(s)$，两桶可独立训练、诊断、消融。

## 4. 数据配方

v2 规则：**target 侧只收头部质量**。Stage 1 只用 DNSMOS / SIGMOS 打分过滤后的最高质量 clean 子集；越噪的数据越只放输入侧（Stage 2 条件、一致性训练、Stage 4），永不进 Stage 1。

推荐数据配比：

```text
high-quality clean-only speech: 70%~90%
filtered paired clean target: 10%~30%
```

如果 paired 数据的 clean target 质量参差不齐，Stage 1 应提高高质量 clean-only 数据权重，而不是按自然数据量采样。

## 5. 为什么要 Low Speaker Leakage

Stage 1 要学的是"干净语音内容结构"，不是"某个说话人的声音分布"。如果 semantic token 里包含太多音色、房间、麦克风和 channel 信息，LM 会把这些也当成 prior 学进去，后面 Stage 2/3 更容易：

- 改变说话人；
- 把房间或设备 coloration 当成 clean speech；
- 在听不清时补出不属于输入的音色或韵律；
- 用更低 LM loss 掩盖更差的增强保真。

防线是 v2 定案的 ASR 监督纯语义路线：token 训练没有 waveform 重建分支，speaker / 信道 / 情绪从训练目标上就没有保留激励；再靠 speaker probe 验收兜底（可选增量：量化器后对抗去说话人，见 Stage 0 的 2.1 节）。

## 6. Clean Target 质量偏差

训练集里的 clean 语音常带有难以去除的残余退化，例如轻微底噪、房间混响、带宽限制、压缩痕迹或麦克风 coloration。v2 对此的处理收敛为两点：

- **Stage 1 只学 semantic prior、只收过滤后头部子集**——内容大体可靠，且 acoustic 表现桶不在本阶段，训练集音质分布没有主目标可附着；
- **acoustic 真值的质量约束后移**：acoustic latent / prosody 真值提取同样只从质量过滤子集出（与 target 侧同尺约束），由 Stage 3 及其真值防污染机制承担（见 v2 recipe 6.4 与 Stage 0 的 2.4 节）。

Stage 1 仍需额外检查 quality leakage：是否能从 token 或 hidden state 预测数据源、录音条件、质量桶、带宽或噪声水平。如果能预测得很好，说明 Stage 1 已经学到了不想要的训练集音质分布。

## 7. Prefix 接口选择

v2 条件侧形态：e_degraded 经 pooling / Q-Former 压缩成 soft condition 或 cross-attention memory（禁止无门控直通），speaker embedding 走 prefix / FiLM。Stage 1 是纯 LM、不带条件，但要不要为 Stage 2 的条件形态预留接口，仍有三种选择：

| 方案 | 做法 | 取舍 |
|---|---|---|
| pure LM | `[BOS] s_clean` | prior 最干净，但 Stage 2 接条件前缀时有位置/attention 分布偏移 |
| variable NULL prefix | `[NULL x L_evd] [BOS] s_clean` | 更对齐 Stage 2 evidence 条件长度分布，但训练成本高，且 null prefix 可能污染 clean prior |
| clean evidence prefix | `[evidence(x_clean)] [BOS] s_clean` | 不推荐，容易把 clean target 的音质分布作为条件学进去 |

如果使用 variable NULL prefix，$L$ 应匹配 Stage 2 压缩后 evidence 条件的长度分布，loss 只算 $s_{clean}$，并配合 prefix dropout 或 gate warmup。默认从 pure LM 开始，prefix 对齐问题留到 Path A/B 对比时验证。

## 8. 训练方案

- 用过滤后的 clean speech 建语义 token 数据，不混 noisy / reverb 目标。
- 训练 LLM / speech LM 预测 clean semantic token 序列。
- 可加入 phoneme/text alignment auxiliary，让 token 更贴近内容。
- 可做轻量 semantic token denoising：mask/drop/span corruption 后恢复 clean semantic token，但不要把真实声学退化作为主目标。
- LLM 可以从文本 LLM 初始化，也可以用较小 speech LM 先验证 token 空间是否有效；如果使用文本 LLM 初始化，原有 embedding / lm_head 与语音 token 词表通常不匹配，需要重训、扩展或做 token 对齐。

## 9. 验收标准

v2 指标分工：S1 看 **LM loss / probe / leakage**。

- clean semantic LM loss / perplexity 稳定下降。
- token 三 probe（与 Stage 0 验收同口径）：content probe（能预测 phoneme / text）、degradation invariance（clean 与 noisy token edit distance 低）、speaker leakage 低。
- source / corpus / quality bucket probe 低，说明没有明显学习训练集音质分布。
- masked span 恢复能保持内容合理，但不会引入 speaker hallucination。
- 接入 Stage 2 后（Path B 初始化，低 LR / 部分冻结保持 prior 锚定），conditional recovery 比 Path A 从零训练更快、更稳。

## 10. 主要风险

- token 太声学化，模型学到 `content + speaker + room + channel` 的混合分布。
- token 太语义化，后续无法帮助韵律和局部声学恢复——v2 中这不是 Stage 1 的职责，韵律由 prosody 头与 acoustic 路径承担，但 token 完全丢失发音细节仍会让 Stage 3 缺线索。
- 只看 LM loss，忽略 token 是否可解释、是否对退化稳定。
- Stage 1 混入真实 degraded data 过早，导致 prior 和 denoising 目标缠在一起。
- Stage 1 主训 acoustic codec token，反而提前拟合训练集 clean target 的音质分布。
- 为对齐 Stage 2 条件形态而引入过强 NULL prefix，导致模型依赖假条件。

## 11. 相关对象

- [[方向/AI语音/知识/技术路线/LLM-SE Training Recipe（借鉴 NLP LLM 的语音增强训练配方）]]
- [[方向/AI语音/知识/技术路线/LLM-SE Training Recipe v2（显式解耦训练配方）]]
- [[方向/AI语音/知识/技术路线/LLM-SE Stage 0（表示空间准备）]]
- [[方向/AI语音/知识/技术路线/LLM-SE Stage 2（多退化条件重建）]]
- [[方向/AI语音/模型/S3 Tokenizer]]
- [[方向/AI语音/知识/基础概念/SSL 编码器]]
- [[方向/AI语音/模型/UniSE（Unified Speech Enhancement）]]
- [[方向/大模型/训练/LLM Training Recipe（大模型训练配方总览）]]

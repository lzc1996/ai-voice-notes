---
title: LLM-SE Training Recipe v2（显式解耦训练配方）
类型: 技术路线
发表时间:
时间依据: 对话沉淀；非单一发表物
上级:
  - "[[方向/AI语音/知识/技术路线/LLM-SE Training Recipe（借鉴 NLP LLM 的语音增强训练配方）]]"
相关任务:
  - 语音增强
  - 语音恢复
  - speech-token conditional reconstruction
相关主题:
  - LLM
  - 训练配方
  - 语音增强
  - 表示解耦
  - 半监督
aliases:
  - LLM-SE v2 方案
  - 显式解耦的 LLM-SE 训练配方
tags:
  - 类型/对象
  - 方向/AI语音
  - 任务/语音增强
  - 主题/大模型
  - 主题/训练
  - 主题/语音表示
---

# LLM-SE Training Recipe v2（显式解耦训练配方）

## 1. 核心判断

v1 五阶段骨架不变。v2 变更三件事：

1. **表示显式分四桶**：内容（semantic token）、身份（speaker embedding）、表现（acoustic latent + prosody）、信道染色（不建模，从 evidence gate 掉）。
2. **生成侧双输出路径**：离散 semantic token 走 NTP；连续 acoustic latent 走 FM-DiT。两级生成 $p(s)\,p(a \mid s)$ 的先例充分（FireRedAudio / Ming-UniAudio 的 FM 头、DualSpeechLM 两级自回归、UniAudio 2.0 双分支、Qwen Thinker-Talker），选型依据见 [[方向/AI语音/选型/LLM-SE 架构选型调研（统一音频模型对比）]]。
3. **"干净"不由 paired target 一家定义**：分散到四个锚点——表示解耦、退化过程不变性、质量过滤的 prior、感知 reward。

## 2. 系统结构

```text
条件侧（LM 输入，不进词表，不参与预测）：
  y_degraded -> evidence encoder（WavLM hidden + gated STFT/mel）-> e_degraded
  y_degraded -> 冻结 SV encoder -> speaker embedding（全局，prefix / FiLM 注入）

生成侧（LM 输出）：
  LM --NTP--> clean semantic token（离散，主任务）
  LM --辅助头--> prosody：F0 bin + V/UV（逐帧分类）
  evidence encoder --辅助头--> 退化头：噪声类型 / SNR / RT60 / 带宽

重建侧：
  LM hidden + speaker embedding + prosody + gated evidence
    -> FM-DiT -> acoustic latent（连续，厚 latent）
  acoustic latent -> latent decoder（Stage 0 训练并冻结）-> waveform
```

依赖方向刻意非对称：**evidence -> semantic -> acoustic latent -> waveform**，每级被上一级和 evidence 双重锚定（决策依据见文末备忘）。

## 3. 真值来源（全部来自 clean 侧）

所有监督信号从 x_clean 用冻结的现成工具提取，零人工标注；模型输入从 y_degraded 提取——**输入从 degraded 提，target 从 clean 提**，噪声从结构上不可能进入监督信号。

| 监督目标                 | 真值来源                                  | 工具                                                                              | 规格                             |
| -------------------- | ------------------------------------- | ------------------------------------------------------------------------------- | ------------------------------ |
| semantic token       | x_clean -> 冻结 semantic tokenizer      | **ASR 监督纯语义 tokenizer（S3 式：ASR encoder + FSQ，文本转写监督）**；WavLM+kmeans 仅作 baseline | 25–50 Hz 离散 id                 |
| acoustic latent      | x_clean -> 冻结 latent encoder          | Stage 0 训好的 autoencoder 编码器                                                     | 约 25 Hz × 64 d 连续              |
| prosody（F0 / energy） | x_clean -> 基频提取器                      | RMVPE / CREPE，log-F0 量化约 256 bin + V/UV 标志                                      | 提取后池化到 token 帧率                |
| speaker embedding    | x_clean 或 y_degraded -> 冻结 SV encoder | ECAPA-TDNN / WavLM-SV / WeSpeaker                                               | utterance 级向量                  |
| 退化标签                 | 仿真流水线元数据                              | 加噪脚本落盘                                                                          | 噪声类型 / SNR / RT60 / 带宽 / codec |

## 4. 推理链路（y_degraded -> 增强波形）

1. y_degraded -> evidence encoder -> e_degraded；y_degraded -> SV encoder -> speaker embedding。
2. LLM 自回归逐帧生成 semantic token；prosody 头同步输出 F0 / energy。
3. 每个 audio-step（约 4 帧 latent ≈ 160 ms）：LLM hidden state + speaker embedding + prosody + gated evidence 条件化 FM-DiT，从高斯噪声迭代去噪出 acoustic latent。
4. 完整 latent 序列 -> Stage 0 冻结的 latent decoder -> 24 kHz 增强波形。

要点：

- **semantic token 不直接解码成音频**。它作为自回归上下文塑造 LLM hidden state，hidden state 才是 DiT 的接口；latent decoder（RedAE 式）只吃 latent，无 token 接口。
- **tokenizer 只在训练期出现**：训练时从 x_clean 提真值并 [[方向/大模型/训练/Teacher Forcing（教师强制）|teacher forcing]]；推理期由 LLM 自回归生成 token，tokenizer 不上线。
- **帧率对齐在 Stage 0 约定**：latent 原生帧率由 autoencoder 定（约 25 Hz），semantic token 池化 / 重采样到匹配帧率，prosody 同步池化；DiT 按 audio-step 分组生成。

## 5. 数据配方

- **target 侧只收头部质量**：DNSMOS / SIGMOS 打分过滤，target 只从最干净子集出；输入侧不限质量，越噪的数据越只放输入侧，永不作 target。
- **仿真退化存元数据**：噪声类型 / SNR / RT60 / 带宽 / codec 类型在加噪时落盘——退化头的免费标签。
- **同 batch 双退化采样**：同一 clean 每 batch 配两种退化实现，供显式一致性 loss 用。
- **Stage 1 数据**：只用打分最高的 clean 子集。
- **真实噪声数据**（无 clean 参考）只进三个位置：一致性训练、Stage 4、对比预训练——都不需要配 target。

## 6. 分阶段配方

### 6.1. Stage 0：表示空间与重建栈

训练 / 准备清单（全部训完冻结，不进主模型训练）：

| 组件 | 做法 |
|---|---|
| acoustic latent autoencoder | 确定性 AE（RedAE 式）：多分辨率 STFT recon + adversarial + feature-matching + 语义蒸馏；数据约 50% clean / 25% noisy / 其余音效音乐。encoder 仅供训练期出 target latent，推理不用 |
| semantic tokenizer | **主路线：ASR 监督纯语义 tokenizer（S3 式：多语言 ASR encoder + FSQ，监督 = 文本转写）**，无现成权重则自训；WavLM+kmeans 留作对照 baseline；可选增量：对抗去说话人（调研范围内文献空白） |
| SV encoder | ECAPA-TDNN / WavLM-SV / WeSpeaker 预训练权重，冻结 |
| evidence encoder | WavLM hidden states + gated log-mel / STFT |

验收（不过不进后续阶段）：

- clean encode -> decode 重建质量（系统音质天花板，必须先到位）。
- 带条件重建一致性；prosody / emotion retention（情感语音重建后情绪识别率、F0 相关性）。
- semantic token 三 probe：content（可预测 phoneme/text）、degradation invariance（clean/noisy token edit distance 低）、speaker leakage（难以预测 speaker）。

### 6.2. Stage 1：clean semantic prior（可选，Path B）

- 在过滤后子集上训 clean semantic token LM。
- 验收：LM loss、token probe、speaker leakage。
- 价值：吃 clean-only 数据、降低 paired 压力、给 Stage 2 提供独立于 paired target 的"干净"锚点。paired 数据够、要快出 baseline 就走 Path A 跳过。

### 6.3. Stage 2：退化条件重建

- **输入**：e_degraded（pooling / Q-Former 压缩成 soft condition 或 cross-attention memory，禁止无门控直通）+ speaker embedding（prefix / [[方向/AI语音/知识/基础概念/FiLM（特征级线性调制）|FiLM]]）。
- **初始化**：Path B 从 Stage 1 LM（低 LR / 部分冻结保持 prior 锚定）；Path A 直接训。
- **训练目标**（按权重从大到小）：
  1. semantic token NTP（主任务）
  2. 显式退化一致性：同 batch 双退化，两次预测的 token 后验 KL（或隐状态 L2）
  3. prosody 头 CE（F0 bin + V/UV，监督信号 = 基频提取器从 clean 提取，池化到 token 帧率）
  4. 退化头分类 / 回归（标签 = 仿真元数据）
- **验收**：conditional recovery（不看 clean PPL）、noise-only probe（喂纯噪声段不得凭空生成语音）、evidence ablation。

### 6.4. Stage 3：声学保真

- **训练 FM-DiT**，条件 = LLM hidden + speaker embedding + prosody + gated evidence；latent decoder 默认冻结，可小额解冻联调。
- **prosody 接线**：LLM 顶层 hidden 挂 MLP prosody 头，逐帧出 F0（256 bin CE）+ V/UV（BCE）+ energy（回归），真值由 RMVPE / CREPE 从 x_clean 提取并池化到 25 Hz；注入 DiT 默认用"与同帧 LLM hidden 相加"（AdaLN / FiLM 或独立 cross-attention 为备选）。此通道为本方案自有设计，先例在 TTS / VC 侧（[[方向/AI语音/模型/FastSpeech|FastSpeech 2]] variance adaptor、VC F0 条件），FireRedAudio 等 omni 模型没有。
- **prosody 真值防污染**：真值质量受提取器和录音质量双重限制（energy 最脆：噪底抬高帧能量；F0 较抗造）。约束与 target 侧同尺：质量过滤后的子集才提真值 + tracker 逐帧 confidence 掩码 prosody loss + 逐句归一化，细节见 [[方向/AI语音/知识/技术路线/LLM-SE Stage 0（表示空间准备）]] 2.4。
- **目标**：flow loss + 多分辨率 STFT + adversarial + speaker consistency（SV cosine，与 Stage 0 speaker 通道同一模型）+ ASR consistency + F0 RMSE / energy 相关。
- **验收**：waveform / spectrum / speaker / content 联合指标；跑无 LLM 的 acoustic encoder-decoder baseline 确认声学头上限。

### 6.5. Stage 4：偏好对齐

- 小步偏好调优，reward 分项：感知 MOS 预测器 / ASR / speaker / emotion consistency（预训练 SER / emotion2vec）。
- 输入分布以真实噪声数据为主——这是唯一能把输出推到比训练 target 更干净的机制。
- 验收：reward 分项 + hard case，不看总 reward。

## 7. 训练稳定性规则

- Stage 0 不稳，后面不堆 LLM——先修表示空间。
- 新模块（DiT、辅助头）训练时冻结已训骨干，渐进解冻。
- 辅助 loss（prosody / 退化头 / 一致性）一律小权重，不得压过 NTP 主任务。
- 一致性 loss 的退化强度上限 = 内容仍可辨认；退化强到毁内容，一致性假设断裂。
- 各阶段指标分工：S1 看 LM loss / probe / leakage；S2 看 conditional recovery；S3 看联合指标；S4 看 reward 分项。
- 长序列 attention：[[方向/大模型/模型结构/QK-Norm]]、更长 warmup、gradient clipping、分模块 LR、严格 resume checklist。

## 8. 实验矩阵

原则：先按单一最优路径把方案跑成型，对比消融一律延后。验收项随训练流程执行，是"能不能进下一阶段"的红线；对比项是方案成型后的优化依据。

**A. 必做验收（边训边做）**

1. Stage 0 重建上限：acoustic latent clean encode -> decode 质量（不过不进 Stage 1/2）。
2. Stage 2 conditional recovery（不看 clean token perplexity）。
3. noise-only probe：喂纯噪声段不得凭空生成语音（信号 / 噪声边界检验）。
4. loss 分项监控：STFT / speaker / ASR / prosody / emotion 各指标独立跟踪，不看总和。
5. 解耦三测试：swap（acoustic 路径跨句交换，内容应不动）、probe（semantic token 应预测不出 speaker / 情绪）、路径 ablation（去 acoustic 路径，内容指标应基本不掉）。

**B. 对比消融（方案初步成型后再加）**

1. Path A（直接条件训练）vs Path B（prior-first）。
2. acoustic 路径形态：连续 latent + FM head vs 离散 RVQ / FSQ 多 codebook + MTP 式逐帧残差预测 + ConvNet decoder + 后置保真修复（Qwen3.5-Omni / UALM 式）。
3. LLM ablation：frozen / LoRA / 部分解冻。
4. evidence ablation（检验语义脑补程度）。
5. loss ablation：STFT / speaker / ASR / prosody / emotion 逐项去除，看幻觉与保真变化。
6. 退化头 ablation、一致性 loss ablation。
7. DiT 条件：hidden only vs + semantic token embedding 显式拼接。
8. semantic tokenizer：S3 纯语义 vs WavLM + kmeans baseline。

## 9. 实施顺序

1. **最小闭环**：Stage 0 -> S2（仅 semantic NTP，无辅助头）-> S3（FM-DiT + 基础保真 loss）。
2. **加身份与韵律**：speaker embedding 通道 + prosody 头 + speaker / prosody consistency loss。
3. **加显式解耦机制**：退化多头 + 显式一致性 loss + target 质量过滤。
4. **真实数据阶段**：Stage 4 reward + FixMatch 式自蒸馏（真实噪声弱视图出伪标签，叠仿真退化做强视图训练）。

留待 v3 评估（复杂度高，现阶段不上）：残差 / 噪声通道（y = s + n 显式因子化）、对抗移除（gradient reversal）、对比退化 embedding、薄 latent（表示级内容 / 表现彻底分离）。

## 10. 设计决策备忘

- **speaker embedding 是条件不是预测目标**：身份在输入里可读，做成目标等于给"换人"开口子。prosody 相反——退化输入里提不干净，只能靠模型从证据 + 先验重建，所以是预测目标。输入能可靠读出的做条件，读不干净的做预测。
- **解耦 = 生成与监督的解耦**：$p(s, a) = p(s)\, p(a \mid s)$，semantic 不受 acoustic 影响（可独立训练 / 诊断 / 消融），acoustic 条件依赖 semantic（内容经 LLM hidden 流入 DiT）。方向选择理由：内容最抗退化、有独立先验，应放上游锚定最难恢复的细声学。厚 latent 冗余含内容属预期，不是 bug。
- **acoustic 走连续 latent**：绕开 codec 量化上限（"codec 丢细节 Stage 3 补不回来"）；离散阵营普遍要挂后置保真修复（enhancement VAE / 超分 / FM refiner），说明裸 codec 路径有隐性成本——离散路线以该完整形态作对照，不是裸 token 直出。
- **semantic 要纯语义**：ASR 监督 tokenizer（S3 式）纯度上限最高，token 不服务波形重建、天然少泄漏；WavLM+kmeans 泄漏明显（其 hidden 做声纹极强），仅作 baseline。纯度不丢信息——情绪 / 韵律按四桶设计由 prosody 头与 acoustic 路径承担。对抗去说话人是调研范围内的文献空白，可作差异化增量。
- **情绪 / 韵律是时变量**：全局 token 装不下，必须帧级——acoustic latent 承载 + 显式 F0 / energy 锚定。

## 11. 一句话经验

**v1 靠"target 干净"定义信号；v2 把"什么是信号"分散到四个锚点——显式表示解耦、退化过程不变性、质量过滤的 prior、感知 reward。生成侧是一条非对称依赖链：evidence（最硬的观测）-> semantic（次硬的因子）-> acoustic latent（最软的因子）-> waveform，每级被上一级和 evidence 双重锚定。token 化把 SE 变成分类问题，半监督工具箱第一次顺手，这是相对 UniSE 直接训练的差异化空间。**

## 12. 相关对象

- [[方向/AI语音/知识/技术路线/Audio2Audio Token 与 Latent 定义（SOTA 统一音频模型）]]
- [[方向/AI语音/选型/LLM-SE 架构选型调研（统一音频模型对比）]]
- [[方向/AI语音/知识/技术路线/LLM-SE Training Recipe（借鉴 NLP LLM 的语音增强训练配方）]]
- [[方向/AI语音/知识/技术路线/LLM-SE Stage 0（表示空间准备）]]
- [[方向/AI语音/知识/技术路线/LLM-SE Stage 1（Clean Speech Token LM 预训练）]]
- [[方向/AI语音/知识/技术路线/LLM-SE Stage 2（多退化条件重建）]]
- [[方向/AI语音/知识/技术路线/LLM-SE Stage 3（声学保真）]]
- [[方向/AI语音/知识/技术路线/LLM-SE Stage 4（感知与偏好对齐）]]
- [[方向/AI语音/模型/UniSE（Unified Speech Enhancement）]]
- [[方向/AI语音/模型/SELM]]
- [[方向/AI语音/模型/FireRedAudio]]
- [[方向/AI语音/知识/基础概念/SSL 编码器]]
- [[方向/AI语音/知识/基础概念/Flow Matching（流匹配）]]
- [[方向/AI语音/知识/基础概念/FiLM（特征级线性调制）]]
- [[方向/AI语音/知识/基础概念/Vocoder（声码器）]]

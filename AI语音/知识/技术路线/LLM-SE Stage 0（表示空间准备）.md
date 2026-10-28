---
title: LLM-SE Stage 0（表示空间准备）
类型: 技术路线
时间依据: 对话沉淀；非单一发表物
上级:
  - "[[方向/AI语音/知识/技术路线/LLM-SE Training Recipe（借鉴 NLP LLM 的语音增强训练配方）]]"
  - "[[方向/AI语音/知识/技术路线/LLM-SE Training Recipe v2（显式解耦训练配方）]]"
相关任务:
  - 语音增强
  - speech representation
  - tokenizer design
aliases:
  - 阶段 0：表示空间准备
  - tokenizer / codec / acoustic encoder 单独训练
tags:
  - 类型/对象
  - 方向/AI语音
  - 任务/语音增强
  - 主题/语音表示
  - 主题/训练
---

# LLM-SE Stage 0（表示空间准备）

## 1. 目标

Stage 0 的目标是**定接口**，不是正式训练 SE，也不是训练 LLM。它要回答：LLM 读什么、预测什么，哪些信息走离散 token，哪些信息走连续 latent / 条件分支。

```text
Stage 0 = representation / tokenizer / acoustic autoencoder / condition encoder preparation
```

这一阶段决定后续上限：如果 semantic token 混入太多说话人、房间和麦克风信息，Stage 1 学到的就不是 clean semantic prior；如果 acoustic latent 或 decoder 丢掉太多细节，Stage 3 再大也补不回来。v2 结论：生成侧是双输出路径（离散 semantic token + 连续 acoustic latent），条件侧是 speaker embedding + prosody + degraded evidence。

## 2. 表示分工

| 表示                         | 形态                        | 是否进词表 | 主要作用                                   |
| -------------------------- | ------------------------- | ----: | -------------------------------------- |
| semantic token             | 离散 id                     |     是 | 内容（说了什么）；ASR 监督纯语义（见 2.1）              |
| speaker embedding          | 连续全局向量                    |     否 | 身份锚点（谁在说话），prefix / FiLM 注入（见 2.3）     |
| acoustic latent            | 连续向量                      |     否 | 表现（怎么说的）：情绪、韵律、音色细节（见 2.2）             |
| prosody 条件                 | 连续 F0 / energy            |     否 | 显式韵律锚定，LLM 辅助预测 clean prosody（见 2.4）   |
| degraded acoustic evidence | 连续向量 / 频谱 / hidden states |     否 | 退化输入里真实存在过的声学线索（见 3）                   |
| decoder / FM head          | 生成模块                      |     否 | latent / hidden condition 还原成 waveform |

核心区分：**生成目标只有两个——semantic token（离散，NTP 预测）和 acoustic latent（连续，FM 生成）；speaker embedding、prosody、degraded evidence 都是条件，不进词表、不参与预测**。条件的使用原则：输入里能可靠读出的（身份、观测）做条件；读不干净的（clean 韵律）让模型预测后再当条件用。

注意：acoustic 路径已定为连续 latent 单一形态。离散 acoustic token（RVQ / FSQ 多 codebook + MTP + ConvNet decoder + 后置保真修复）作为对照路径**暂缓**，待方案整体初步成型后再加（见 v2 recipe 实验矩阵）。

语音 tokenizer 与文本 LLM tokenizer 的差异见 [[方向/AI语音/知识/技术路线/语音模型 tokenizer 与 LLM tokenizer 对比]]；本阶段的重点不是复用文本 tokenizer，而是明确语音 token 的信息边界和重建上限。

### 2.1.2. 1 Semantic Tokenizer：ASR 监督纯语义路线（S3 / CosyVoice v1–v2 式）

主路线定为 [[方向/AI语音/模型/S3 Tokenizer]] 式有监督语义 tokenizer；WavLM + kmeans 仅作对照 baseline（其 hidden states 做声纹任务极强，speaker 泄漏明显）。

**结构**：多语言 ASR encoder（SenseVoice-Large / Whisper 式）中间层插入量化器：

```text
waveform -> fbank -> ASR encoder 前段 -> 量化器 -> token id（25–50 Hz）
                                      -> ASR encoder 后段 -> CTC / AED decoder -> 文本转写
```

这里的 fbank 指 [[方向/AI语音/知识/基础概念/Fbank（滤波器组特征）|log-Mel filterbank features]]，是 ASR encoder 的输入特征，不是可逆音频表示。

这里的 CTC / AED decoder 分别指 [[方向/AI语音/知识/基础概念/CTC（连接时序分类）|Connectionist Temporal Classification]] 和 [[方向/AI语音/知识/基础概念/AED（注意力编码器-解码器）|Attention Encoder-Decoder]]，在这条路线里主要是训练期文本监督脚手架。

- **量化器**：v1 用单层 VQ；v2 起改 FSQ（codebook 利用率更高，CosyVoice 2 消融确认 FSQ 是 v1->v2 增益来源之一）。FSQ 词表由 levels 决定，不必人工指定 K。
- **为什么量化器插中间层**：前段把声学特征加工成"值得量化"的表示（直接量化 [[方向/AI语音/知识/基础概念/Fbank（滤波器组特征）|fbank]] 只能得到声学格子）；量化器制造信息瓶颈（每帧一个离散符号）；后段 + ASR loss 提供语义压力——梯度穿过量化器回传，把表示塑造成"足以预测文本"的形状。不能放末端：紧贴文本输出会把 token 压成"带时标的字符"，丢失帧级发音细节（时长、读音方式），下游声学路径就断了"该怎么念"的线索。插入层数是超参，由 content / speaker leakage probe 定。
- **后段是脚手架**：ASR 后段和 decoder 只在训练时提供监督，训完即扔；提取 token 只走"前段 + 量化器"。
- **帧率**：25 Hz / 50 Hz 两档可选；SE 长序列场景优先 25 Hz。

**训练目标**：

$$
\mathcal{L} = \mathcal{L}_{\mathrm{quant}} + \lambda\, \mathcal{L}_{\mathrm{ASR}}(s, w)
$$

$\mathcal{L}_{\mathrm{quant}}$ 是 VQ commit loss 或 FSQ 的隐式量化项；$\mathcal{L}_{\mathrm{ASR}}$ 以文本转写 $w$ 为监督。**关键是没有 waveform 重建分支**——这是它和 codec 的本质区别：codec 的 token 被迫装下重建所需的全部声学信息，ASR 监督 token 只需携带足以预测文本的信息，speaker / 信道 / 情绪从训练目标上就没有保留激励。

**纯度边界**：

- 监督只有文本 => 纯度上限各路线最高；但"纯语义"不等于"只含音素"——ASR 可学习范围内残留的 speaker / 情绪信息仍可能漏入，必须靠 probe 验收（见训练与验收表）。
- CosyVoice v3 把监督扩成 ASR + emotion + language ID + audio event + speaker analysis 的多任务版——对纯语义目标是**反向操作**，停留在 v1–v2 的纯 ASR 监督。
- 可选增量（调研范围内文献空白）：量化器后加**对抗去说话人**（gradient reversal + speaker 分类器），把残余泄漏再压一档；抗扰动可参考 [[方向/AI语音/模型/StableToken]] 的 Voting-LFQ + 噪声共识训练（UED 降 60%+）。

**工程清单**：

- 自训：多语言 ASR 数据（数千小时级带转写）、SenseVoice / Whisper 初始化 encoder、FSQ 量化器；训完冻结，推理期只保留 "waveform -> token" 前段。
- 零训练 baseline：CosyVoice 官方 speech tokenizer ONNX，或第三方 `s3tokenizer` PyPI 包（基于 SenseVoice-Large 反向工程）——先跑通 Stage 1/2，再决定是否自训提纯。
- 边界：它不是 codec，不能独立还原波形——在 LLM-SE 里只负责出 semantic token 真值，波形由 acoustic latent 路径负责，职责正交。
- **生命周期：只在训练期出现**。从 x_clean 提 token 当 NTP 真值并做 [[方向/大模型/训练/Teacher Forcing（教师强制）|teacher forcing]]；推理期 tokenizer 不上线，token 由 LLM 自回归生成。因此它的抗噪性不是硬性要求，degradation invariance probe 更多用于度量纯度。
- **semantic token 不进 RedAE decoder**：RedAE 是纯 autoencoder，decoder 只吃 latent，无 token 接口。语义信息到达波形的完整路径是：semantic token -> 自回归上下文 -> LLM hidden state -> DiT 条件 -> acoustic latent -> decoder。token 是规划层，hidden state 才是 DiT 的接口。

### 2.2.2. 2 Acoustic Latent Autoencoder（重建栈，RedAE 式）

表现桶的主路径是连续 acoustic latent，由 FM-DiT 在 Stage 3 生成、latent decoder 渲染成波形。autoencoder 在 Stage 0 训练并冻结，参照 [[方向/AI语音/模型/FireRedAudio]] 的 RedAE：

```text
x_clean -> latent encoder -> z_clean（约 25 Hz，连续）   # 训练期出 target latent
z_clean -> latent decoder（Transformer + iSTFT / Vocos 式）-> waveform（24 kHz）
```

- **确定性 autoencoder**：$z = E(x)$、$\hat{x} = D(z)$，不做 VAE 式后验、无 KL 项。
- **训练目标**（hybrid）：多分辨率 STFT recon + adversarial + discriminator feature-matching + **语义蒸馏**（MSE 对齐到冻结 teacher encoder 高层特征，防止 latent 只学低层声学纹理、让后续 DiT 好建模；teacher 训后丢弃）。
- **数据混合不只喂 clean**：参照 RedAE 约 50% clean / 25% noisy / 其余音效音乐——让 latent 空间覆盖非干净语音，避免对 noisy 输入出分布外 latent。
- **encoder 只在训练期存在**：推理时 latent 由 FM-DiT 生成，encoder 不上线；主模型训练期 encoder / decoder 均冻结。
- **帧率对齐约定在此定死**：latent 原生帧率（约 25 Hz）为基准，semantic token 池化 / 重采样到匹配帧率，prosody 同步池化；DiT 按 audio-step 分组生成（约 4 帧 ≈ 160 ms）。

### 2.3.2. 3 Speaker Embedding 通道

身份桶用预训练 SV 模型的连续 embedding，**是条件不是预测目标**：身份在输入语音里已经写着，模型不需要"猜"；做成生成目标反而给"换人"开了口子。

- **选择**：ECAPA-TDNN / WavLM-SV / WeSpeaker 预训练权重，冻结；自带度量空间（cosine 相似度即 Stage 3 speaker consistency loss 的现成实现）。
- **形态**：utterance 级全局向量（身份在一句话内近似时不变），prefix / FiLM 注入 LLM 与 DiT，不进词表、不参与 NTP。
- **clean / degraded gap**：训练时可从 clean 提取，推理只能从 degraded 提取，噪声和房间响应会污染 embedding。缓解：选抗噪 SV 模型、增广缩小 gap、clean / degraded embedding 一致性约束；TSE 场景由 enrollment 天然解决。
- **多说话人例外**：SS / TSE 场景全局 embedding 假设失效，届时换 enrollment 条件或逐源 embedding。

### 2.4.2. 4 Prosody 条件

情绪 / 韵律是时变量，全局 token 原理上装不下，必须帧级表示。acoustic latent 隐式承载之外，加显式 F0 / energy 通道做锚定（此为 LLM-SE 自有设计，FireRedAudio 等 TTS 系模型没有——它们的韵律由文本 / 参考音频隐式决定；先例在 TTS/VC 侧：[[方向/AI语音/模型/FastSpeech|FastSpeech 2]] variance adaptor、VC 的 F0 条件）。

- **真值**：x_clean 经基频提取器（RMVPE / CREPE）出 log-F0（量化约 256 bin + V/UV 标志）和 energy，池化到 token 帧率。
- **预测而非提取**：推理期从 degraded 输入提 F0 不可靠（倍频程错误、清浊误判），所以让 LLM 用辅助头预测 clean prosody——把"从噪声里提取"变成"从证据 + 先验里重建"；预测结果条件化 DiT，与 token 同出一门、天然一致。
- **LLM 侧结构**：顶层 hidden state 挂两层 MLP prosody 头，逐帧三路输出——F0 256 bin 分类（CE）+ V/UV 二分类（BCE）+ energy 回归（L1 / L2）；辅助 loss 小权重，不压过 NTP 主任务。
- **DiT 侧接线**：已定——预测的 bin id 查 embedding 后与同帧 LLM hidden state 相加，作为 DiT 条件（latent 与 prosody 同为 25 Hz，逐帧 1:1 对齐）。AdaLN / FiLM、独立 cross-attention memory 等形态暂缓，方案成型后再对比。
- **降级方案**：prosody 头质量不行时，退回抗噪 tracker（CREPE）从 degraded 直接提取当条件，训练时随机混合"clean 预测 / degraded 提取"两种来源做域适应。
- **诊断价值**：F0 RMSE 是 Stage 3 保真 loss 和验收的直接着力点；没有显式 prosody，"韵律被磨平"在 codec / latent 误差里不可分离。
- **真值污染风险**：prosody 是除 acoustic latent 外最受"clean 不干净"影响的通道——真值靠提取器计算，提取器错误直接变成监督噪声。分解来看：F0 相对抗造（周期性检测耐噪 + bin 量化吸收小误差）；**energy 最脆**（噪底直接抬高帧能量，静音 / 弱音帧失真最严重，失败模式是增强输出停顿处能量地板抬高）；V/UV 居中。缓解按性价比：质量过滤同样约束真值提取 -> tracker 逐帧 confidence 掩码 prosody loss -> log-F0 / energy 逐句归一化 -> clean 与增广版本提取一致性自检。最终兜底是 Stage 4 感知 reward。

## 3. Degraded Acoustic Evidence

`degraded acoustic evidence` 是从退化语音中提取的连续观测：

```text
y_degraded
  -> acoustic encoder
  -> e_degraded
```

它可以是 waveform、complex STFT、log-mel、[[方向/AI语音/知识/基础概念/Fbank（滤波器组特征）|fbank]]、SSL hidden states、Whisper/WavLM hidden states、codec pre-quantization latent 等。它**不是干净信息源**，而是 noisy observation：里面同时有真实语音线索、真实音色线索、噪声、混响、channel coloration 和 codec artifact。

因此它不能被无门控直通，否则会把噪声和混响也引入模型。更合理的用法是：

```text
e_degraded
  -> pooling / Q-Former / Perceiver / adapter
  -> soft condition embeddings or cross-attention memory
```

注意：soft condition embeddings 不是 vocab token，不参与预测，不进词表，只作为连续条件。evidence 是条件而非目标——噪声过滤靠"条件预测 clean target"的任务结构本身（information bottleneck），不靠 evidence 表示自身干净。

## 4. 现成组件选择

| 用途 | 现成选择 | 推荐位置 | 风险 |
|---|---|---|---|
| 默认 speech evidence | [[方向/AI语音/模型/WavLM]] | Stage 2 LLM condition | 仍可能带噪声和混响信息 |
| 内容约束 | [[方向/AI语音/模型/Whisper]] encoder | ASR/content evidence | 太偏识别，不保留细声学 |
| SSL baseline | [[方向/AI语音/模型/HuBERT]] / wav2vec 2.0 / XLS-R | semantic-ish evidence | 抗噪和 speaker leakage 需测 |
| 低层声学证据 | log-mel / complex STFT / [[方向/AI语音/知识/基础概念/Fbank（滤波器组特征）]] | Stage 3 decoder condition | 退化最强，必须 gate |
| 说话人线索 | ECAPA-TDNN / WavLM-SV / WeSpeaker | speaker embedding 通道（Stage 2 条件 / Stage 3 consistency） | 噪声和房间响应会污染 embedding |
| waveform detail | EnCodec / DAC / Mimi pre-VQ latent | Stage 3 decoder condition | 很容易把噪声也编码进去 |
| semantic tokenizer | [[方向/AI语音/模型/S3 Tokenizer]] 式 ASR 监督 + FSQ | semantic token 真值提取 | 用 v1–v2 纯 ASR 监督，勿用 v3 多任务版；训练细节待核 |
| acoustic latent autoencoder | 自训 RedAE 式确定性 AE | 重建栈（target latent + waveform decoder） | 数据混合须覆盖 noisy / 音效，否则 latent 空间偏科 |

第一版建议：**WavLM hidden states + gated log-mel / STFT** 做 evidence；speaker embedding 通道（v2 起为必选，不再可选）；codec latent 仅作 decoder 条件备选。

## 5. 训练与验收

| 检查项 | 目标 |
|---|---|
| semantic token content probe | 能预测 phoneme / text / ASR unit |
| semantic token degradation invariance | clean 与 noisy/reverb token edit distance 低 |
| semantic token speaker leakage | 从 token 预测 speaker 困难（纯语义路线的核心验收） |
| acoustic latent 重建上限 | clean encode -> decode 质量到位（系统音质天花板，必须先过） |
| 带条件重建一致性 | latent + speaker embedding + prosody 条件重建与目标一致 |
| prosody / emotion retention | 情感语音重建后情绪识别率、F0 相关性保持 |
| continuous evidence fidelity | 保留频谱、相位、时间结构和退化观测 |
| token rate | LLM 可承受，序列不能过长 |
| clean/degraded alignment | clean 与 degraded 表示能时间对齐 |
| 帧率约定冻结 | latent / semantic token / prosody 同帧率口径已确定 |

验收红线：acoustic latent 重建上限不过，不进 Stage 1/2——先修表示空间，不堆 LLM。

## 6. 主要风险

- semantic token 混入太多 speaker / room / channel，Stage 1 学到的就不是 clean semantic prior（防线：ASR 监督纯语义路线 + speaker leakage probe，见 2.1）。
- acoustic latent autoencoder 只用 clean 训，对 noisy 输入 encode 出分布外 latent（防线：数据混合覆盖 noisy / 音效，见 2.2）。
- degraded acoustic evidence 太强且无门控，会造成噪声、混响、channel 信息泄漏。
- degraded acoustic evidence 太弱，Stage 2 会退化成 LLM 凭 prior 生成 clean speech。
- speaker embedding 的 clean / degraded 提取 gap 导致推理期身份漂移（防线见 2.3）。
- decoder 上限太低，后续模型再大也恢复不了被 tokenizer 丢掉的相位和频谱细节。

## 7. 相关对象

- [[方向/AI语音/知识/技术路线/LLM-SE Training Recipe（借鉴 NLP LLM 的语音增强训练配方）]]
- [[方向/AI语音/知识/技术路线/LLM-SE Training Recipe v2（显式解耦训练配方）]]
- [[方向/AI语音/知识/技术路线/LLM-SE Stage 1（Clean Speech Token LM 预训练）]]
- [[方向/AI语音/知识/技术路线/语音模型 tokenizer 与 LLM tokenizer 对比]]
- [[方向/AI语音/选型/LLM-SE 架构选型调研（统一音频模型对比）]]
- [[方向/AI语音/知识/基础概念/SSL 编码器]]
- [[方向/AI语音/知识/基础概念/Vocoder（声码器）]]
- [[方向/AI语音/模型/S3 Tokenizer]]
- [[方向/AI语音/模型/CosyVoice]]
- [[方向/AI语音/模型/StableToken]]
- [[方向/AI语音/模型/FireRedAudio]]
- [[方向/AI语音/模型/WavLM]]
- [[方向/AI语音/模型/Whisper]]
- [[方向/AI语音/模型/HuBERT]]

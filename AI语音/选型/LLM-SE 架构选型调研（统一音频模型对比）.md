---
title: LLM-SE 架构选型调研（统一音频模型对比）
类型: 选型调研
发表时间:
时间依据: 对话沉淀 + 库内模型笔记 + arXiv 原文核查（2026-09-01）
相关任务:
  - 语音增强
  - 语音生成
  - 音频理解
相关主题:
  - LLM
  - tokenizer
  - 语音表示
  - 架构选型
aliases:
  - LLM-SE 架构选型对比
  - 统一音频模型架构调研
tags:
  - 类型/对象
  - 方向/AI语音
  - 主题/语音表示
  - 主题/大模型
---

# LLM-SE 架构选型调研（统一音频模型对比）

为 [[方向/AI语音/知识/技术路线/LLM-SE Training Recipe v2（显式解耦训练配方）]] 的表示与解码选型做的一线方案对比，避免单一参照 [[方向/AI语音/模型/FireRedAudio]]。

## 1. 对比总表

| 模型 | 输入侧表示 | 语义纯度机制 | 输出侧表示 | 解码链路 | speaker 条件 | SE 相关 |
|---|---|---|---|---|---|---|
| [[方向/AI语音/模型/FireRedAudio]] | 双连续路径：理解 12.5 Hz / 生成条件 RedAE-Patch 6.25 Hz | RedAE 语义蒸馏（teacher 训后丢弃） | LLM audio-step + FM-DiT 连续 latent | RedAE Decoder（iSTFT，24 kHz） | 参考音频 RedAE-Patch prefix | 语音编辑 |
| Qwen3.5-Omni | AuT encoder 连续 6.25 Hz（40M 小时 ASR 数据从头训练） | 无（连续输入） | RVQ 离散 token + MTP 模块逐帧出残差 codebook | causal ConvNet Code2Wav，流式 | Talker system prompt（文本描述 + codec 序列），不用传统 speaker embedding | 无 |
| [[方向/AI语音/模型/DualSpeechLM]] | 离散 USToken：Whisper hidden -> VQ | **理解驱动 loss**（量化向量过冻结 text LLM 对齐文本语义）+ 重建 loss 兜底声学 | 两级：LLM 出 USToken -> AcousticGPT 出 acoustic token | WavTokenizer decoder | **显式 speaker embedding** + Chain-of-Condition 三条件采样 | 无（VC 链路结构相近） |
| [[方向/AI语音/模型/UALM]] | 连续 25 Hz acoustic encoder + MLP adapter | 无（连续输入） | 单 LLM 扩词表出 X-Codec RVQ token（50 Hz × 8 层，delay pattern） | codec decoder 16 kHz -> **enhancement VAE** -> 48 kHz | 文本 prompt | enhancement VAE（间接） |
| [[方向/AI语音/模型/Audex]] | 连续 AF-Whisper 25 Hz × 1280 d + MLP | 无 | 离散 X-Codec2 FSQ（speech，词表 65536）/ X-Codec RVQ（non-speech） | X-Codec2 streaming decoder；non-speech 加 **enhancement VAE** | 未记录 | enhancement VAE（间接） |
| [[方向/AI语音/模型/LongCat-Next]] | 离散：Whisper 特征 -> 8 层 RVQ，12.5 Hz | L_llm 对齐 LLM 语义，**明言保留副语言特征** | RVQ token + DepthTransformer 并行出多层 | 对称 decoder -> coarse Mel -> **FM refiner** -> vocoder | 未记录（支持语音克隆） | 无 |
| [[方向/AI语音/模型/Ming-UniAudio]] | 连续 Z_uni：MingTok VAE + Whisper-v3 初始化 | **语义蒸馏 + ASR 文本对齐**，但刻意保留声学细节 | LLM hidden + **per-token FM head** 出连续表示 | MingTok decoder（Vocos 式 + iSTFT） | 源语音 Z_uni + 自然语言指令 | **最直接：指令编辑含 denoise** |
| [[方向/AI语音/模型/UniAudio 2.0]] | 离散 ReasoningCodec 双分支：reasoning r（低帧率、文本对齐）+ reconstruction s（8 路声学） | **显式因子化拆分** + [[方向/AI语音/知识/基础概念/FiLM（特征级线性调制）]] 回注语义 | 9-stream 进主干，local decoder 逐帧多 codebook 预测 | flow-based decoder | 未记录 | 表征同构（无 SE 任务） |
| [[方向/AI语音/模型/Ming-Flash-Omni]] | 理解侧连续 encoder 特征；生成侧 12.5 Hz 连续 VAE latent | 未记录 | 固定 0.5B audio head 预测 FM 条件 -> FM latent | VAE decode + **super-resolution** -> 44.1 kHz | zero-shot 克隆（形式未记录） | 超分模块（间接） |

## 2. 跨模型规律

1. **理解侧收敛到连续表示**：6.25–25 Hz 的 encoder hidden + adapter 是绝对主流（FireRedAudio、Qwen3.5-Omni、UALM、Audex、Ming 系）；离散化主要发生在**生成侧**。LLM-SE 的 evidence 通道走连续是正确的。
2. **生成侧两大阵营**：
   - 离散多 codebook + 轻量 decoder（Qwen3.5-Omni 的 RVQ+MTP+ConvNet、UALM/Audex 的扩词表直接出 token、LongCat-Next）——流式友好、框架统一；
   - 连续 latent + FM/diffusion 头（FireRedAudio、Ming-UniAudio、Ming-Flash-Omni）——无量化上限、保真优先。
   - **关键观察：离散阵营普遍要挂后置保真修复**（UALM/Audex 的 enhancement VAE、LongCat 的 FM refiner、Ming-Flash 的超分）——codec 量化损失靠后级补偿，这是选离散路线的隐性成本。
3. **语义 -> 声学两级生成是主流范式**：Qwen Thinker-Talker、DualSpeechLM（USToken -> AcousticGPT）、UniAudio 2.0（reasoning r -> reconstruction s）、LongCat DepthTransformer。非对称依赖 $p(s)\,p(a \mid s)$ 有充分先例，不是 FireRedAudio 独有。
4. **speaker 条件两派**：显式 embedding 注入（DualSpeechLM）vs prompt / 参考音频（Qwen3.5-Omni 用 system prompt 承载文本描述 + codec 序列；FireRedAudio 用参考音频 prefix）。前者可直接复用 SV 度量做 consistency loss，后者更灵活但难诊断。
5. **SE 直接相关的只有三家**：Ming-UniAudio-Edit（指令化 denoise，连续表示 + FM head）、UniSE / SELM（专用 SE），以及各家的"增强后级"模块（enhancement VAE / 超分）。**退化建模 + evidence 门控在所有通用模型里都缺席**——这是 LLM-SE 的差异化空间。

## 3. 纯语义 token 路线对比

| 路线 | 代表 | 纯度上限 | 代价 / 风险 |
|---|---|---|---|
| ASR 监督语义 tokenizer | [[方向/AI语音/模型/S3 Tokenizer]]（CosyVoice v1/v2，FSQ） | **最高**：文本转写监督直接对齐内容，token 不服务波形重建 | 需 ASR 转写数据；CosyVoice v3 把 speaker analysis 加回监督，用时要停在纯 ASR 监督版本 |
| 理解驱动量化 | DualSpeechLM USTokenizer（Whisper + VQ + 冻结 text LLM 理解 loss） | 高：直接对齐文本语义空间 | 坦承牺牲声学细节；预训练权重未放出 |
| 结构解耦取语义流 | [[方向/AI语音/模型/BiCodec]]（semantic VQ + global FSQ） | 中：句内时变情绪/韵律会漏回 semantic 流（定长 global token 装不下）；SIM 0.80 说明泄漏不小 | 无 ASR 监督，纯度弱约束 |
| SSL + kmeans / LFQ + 抗扰训练 | [[方向/AI语音/模型/StableToken]]（Voting-LFQ + 噪声共识，UED 降 60%+） | 中：解决退化不变性，**未去说话人** | speaker 泄漏需自测；只能当输入侧 token |
| SSL + kmeans 基线 | WavLM / HuBERT + kmeans | 低：WavLM hidden 做 SV 极强 = 泄漏明显的间接证据 | 零训练成本，适合当对照 baseline |

**空白点**：调研范围内没有任何一家做显式**对抗去说话人 / 去信道**（adversarial removal）——ASR 监督 + 对抗去说话人 + 抗扰共识训练的组合是没人占住的位置。

## 4. 对 LLM-SE v2 的选型结论

1. **semantic tokenizer：WavLM+kmeans 降级为 baseline，主路线改为 ASR 监督纯语义 tokenizer**（S3 式：多语言 ASR encoder + FSQ；无现成权重就自训，监督 = 文本转写）。对抗去说话人作为 v2 的差异化增量（文献空白）。纯语义不丢信息——韵律/情绪按四桶设计由 prosody 头和 acoustic 路径承担。
2. **双输出路径保留**：$p(s)\,p(a \mid s)$ 两级生成先例充分（DualSpeechLM / UniAudio 2.0 / Qwen Thinker-Talker），不再是单一参照 FireRedAudio。
3. **acoustic 主路径仍为连续 latent + FM head**（保真优先，SE 对音质天花板敏感）；**对照改为离散阵营的主流形态**：RVQ/FSQ 多 codebook + MTP 式逐帧残差预测 + ConvNet decoder + 后置保真修复（Qwen3.5-Omni / UALM 式），而不是裸 codec token 直出。
4. **speaker 条件走显式 embedding**（DualSpeechLM 同构），与 speaker consistency loss 共用 SV 模型；prompt 式条件（Qwen3.5-Omni）暂不采用——难以诊断身份泄漏。
5. **解码后级可参考离散阵营的 enhancement VAE / 超分模式**：latent decoder 之后是否加保真修复级，留作 Stage 3 的实验项。

## 5. 相关对象

- [[方向/AI语音/知识/技术路线/Audio2Audio Token 与 Latent 定义（SOTA 统一音频模型）]]
- [[方向/AI语音/知识/技术路线/LLM-SE Training Recipe v2（显式解耦训练配方）]]
- [[方向/AI语音/知识/技术路线/LLM-SE Training Recipe（借鉴 NLP LLM 的语音增强训练配方）]]
- [[方向/AI语音/知识/技术路线/语音生成 tokenizer codec 技术路线]]
- [[方向/AI语音/模型/UniSE（Unified Speech Enhancement）]]
- [[方向/AI语音/模型/SELM]]
- [[方向/AI语音/模型/S3 Tokenizer]]
- [[方向/AI语音/模型/StableToken]]
- [[方向/AI语音/模型/BiCodec]]
- [[方向/AI语音/模型/X-Codec2]]
- [[方向/AI语音/知识/基础概念/FiLM（特征级线性调制）]]

## 6. 关键来源

- [Qwen3.5-Omni Technical Report](https://arxiv.org/abs/2604.15804)（2026-04-17，架构章节：AuT 6.25 Hz encoder、RVQ+MTP+Code2Wav、ARIA、Talker system prompt 条件）
- 库内模型笔记（见对比总表链接），核验日期 2026-09-01

## 7. 待验证

- S3 tokenizer 官方训练细节与规格（词表 / 码率），第三方 s3tokenizer 与官方 ONNX 的一致性。
- StableToken 的 speaker 泄漏 probe（库内未记录）。
- DualSpeechLM USTokenizer 预训练权重发布状态。
- 离散阵营后置 enhancement VAE 在 SE 场景的增益幅度（其设计目标是 codec artifact 修复与升采样，不是降噪）。

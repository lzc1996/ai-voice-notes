---
title: Audio2Audio Token 与 Latent 定义（SOTA 统一音频模型）
类型: 知识梳理
发表时间:
时间依据: 库内模型笔记 + arXiv / GitHub 原文核查（2026-09-07）
相关任务:
  - 语音生成
  - 语音增强
  - 音频理解
相关主题:
  - tokenizer
  - 语音表示
  - LLM
aliases:
  - Audio2Audio 模型 token 定义梳理
  - SOTA 音频模型 latent 定义对比
tags:
  - 类型/对象
  - 方向/AI语音
  - 主题/语音表示
  - 主题/大模型
---

# Audio2Audio Token 与 Latent 定义（SOTA 统一音频模型）

梳理范围：audio-in / audio-out 的统一音频模型（理解 + 生成一体），重点是每个模型**输出侧 token / latent 的定义**——形态、提取器、规格、语义/声学分工、纯度机制、解码方式。纯理解模型（Voxtral 等）不在此列。SE 专用线（[[方向/AI语音/模型/UniSE（Unified Speech Enhancement）]]、[[方向/AI语音/模型/SELM]]）单列对照。

## 1. 定义总表

| 模型                                                     | 输出表示                                                   | 提取器 / 定义方式                                                           | 帧率 / 规格                                      | 语义-声学分工                             | 解码到波形                                                              |
| ------------------------------------------------------ | ------------------------------------------------------ | -------------------------------------------------------------------- | -------------------------------------------- | ----------------------------------- | ------------------------------------------------------------------ |
| [[方向/AI语音/模型/FireRedAudio]]                            | 连续 RedAE latent                                        | 确定性 autoencoder + 语义蒸馏                                               | 25 Hz × 64 d（进 LLM 前 patch 到 6.25 Hz）        | 厚 latent 全含；语义蒸馏保证可建模性              | FM-DiT 生成 latent -> RedAE Decoder（iSTFT，24 kHz）                    |
| [[方向/AI语音/模型/Qwen3.5-Omni]]                         | 离散 RVQ token                                           | Qwen3.5-Omni-Audio-Tokenizer                                         | 未公开；MTP 逐帧出残差 codebook                       | 不拆，声学全在 RVQ 里                       | causal ConvNet Code2Wav（流式）                                        |
| [[方向/AI语音/模型/DualSpeechLM]]                            | 两级离散：USToken + acoustic token                          | USToken = Whisper hidden -> VQ + 理解驱动 loss；acoustic 由 AcousticGPT 生成 | 未记录（2x 下采样）                                  | **显式两级**：语义骨架 -> 声学细节               | WavTokenizer decoder                                               |
| [[方向/AI语音/模型/UALM]]                                    | 离散 X-Codec RVQ token                                   | X-Codec（SSL 特征融合的 RVQ codec）                                         | 50 Hz × 8 层，delay pattern                    | 不拆（X-Codec 每层语义染色）                  | codec decoder 16 kHz -> enhancement VAE -> 48 kHz                  |
| [[方向/AI语音/模型/Audex]]                                   | 离散 X-Codec2 FSQ token（speech）/ X-Codec RVQ（non-speech） | X-Codec2 单层大码本                                                       | 50 Hz，词表 65536                               | 不拆；speech / non-speech 分用 codec     | streaming decoder；non-speech 加 enhancement VAE                     |
| [[方向/AI语音/模型/LongCat-Next]]                            | 离散 RVQ token                                           | Whisper 特征 -> 4x 下采样 -> 8 层 RVQ（L_recon + L_commit + L_llm）          | 12.5 Hz × 8 层                                | 明言保留副语言，不追求纯语义                      | 对称 decoder -> coarse Mel -> FM refiner -> vocoder                  |
| [[方向/AI语音/模型/Ming-UniAudio]]                           | 连续 Z_uni                                               | MingTok-Audio：VAE latent + Whisper-v3 初始化 + 语义蒸馏 + ASR 对齐            | 未记录（pooling 到 LLM 帧率）                        | 刻意不拆：Z_uni 同载语义与声学                  | per-token FM head -> MingTok decoder（Vocos 式 + iSTFT）              |
| [[方向/AI语音/模型/UniAudio 2.0]]                            | 离散双分支：reasoning r + reconstruction s                   | ReasoningCodec：冻结 SSL 专家特征 -> query transformer 压缩 -> RVQ            | r 低帧率；s 为 8 路（phone VQ / music VQ / env RVQ） | **显式因子化**：r 文本对齐，s 以 r 为条件（FiLM 回注） | flow-based decoder                                                 |
| [[方向/AI语音/模型/Ming-Flash-Omni]]                         | 连续 VAE latent                                          | 音频 VAE encoder                                                       | 12.5 Hz                                      | 不拆                                  | 0.5B audio head 预测 FM 条件 -> FM latent -> VAE decode + 超分（44.1 kHz） |
| [[方向/AI语音/模型/Kimi-Audio]]                              | 离散语义 token（输入侧另有连续路）                                   | Whisper 系 tokenizer；输入 = 离散 12.5 Hz + 连续 12.5 Hz 双路                  | 12.5 Hz                                      | 显式双路：离散承担语义，连续保副语言                  | Flow Matching -> mel -> BigVGAN                                    |
| [[方向/AI语音/模型/GLM-4-Voice]]                             | 离散纯语义 token                                            | Whisper encoder 中插 VQ，**ASR 监督**                                     | 12.5 Hz，词表 16384                             | 纯语义单流；声学靠解码器补回                      | Flow Matching decoder（CosyVoice 式），10 token 起播                     |
| [[方向/AI语音/模型/Moshi]]                                   | 离散 Mimi codec token                                    | Mimi 流式 codec，语义层 SSL 蒸馏                                             | 12.5 Hz，1.1 kbps，80 ms 帧延迟                   | **codec 内分层**：语义层（蒸馏）+ 声学层          | Mimi codec decoder 直出                                              |
| [[方向/AI语音/模型/StepAudio 2.5]]                           | 离散音频 token                                             | 未记录                                                                  | 未记录（训练量级 800B 语音 token）                      | 未记录                                 | 未记录                                                                |
| SE 参照：[[方向/AI语音/模型/SELM]]                              | 离散 semantic token 先行                                   | W2V-BERT 系语义 token                                                   | 未记录                                          | 语义 token -> 声学续写两段式                 | token2wav + vocoder                                                |
| SE 参照：[[方向/AI语音/模型/UniSE（Unified Speech Enhancement）]] | 离散 codec token                                         | WavLM 条件 + codec token                                               | 未记录                                          | 不拆                                  | codec decoder + 感知后训练                                              |

规格"未记录"者以原论文为准补齐。

## 2. 三个维度上的收敛规律

**1. 形态：离散 token vs 连续 latent 两大阵营**

- 离散自回归派：Qwen3.5-Omni、UALM、Audex、LongCat-Next、GLM-4-Voice、Moshi、Kimi-Audio、DualSpeechLM、UniAudio 2.0。
- 连续 latent + FM 派：FireRedAudio、Ming-UniAudio、Ming-Flash-Omni。
- **离散派的隐性成本**：普遍挂后置保真修复（UALM / Audex 的 enhancement VAE、LongCat 的 FM refiner、Ming-Flash 的超分）——量化损失靠后级补。

**2. 语义 / 声学拆分的四种位置**

- **codec 内分层**：Moshi（Mimi 语义层蒸馏）、UniAudio 2.0（reasoning / reconstruction 双分支 + FiLM 回注）、X-Codec（每层语义染色）。
- **输入侧双路**：Kimi-Audio（离散语义 + 连续声学）、FireRedAudio（理解路径 / 生成条件路径）。
- **纯语义 token + 外部声学重建**：GLM-4-Voice、S3 / CosyVoice、SELM——token 只管内容，声学由 FM / vocoder 补。
- **不拆（厚表示）**：Qwen3.5-Omni、UALM、Audex、Ming 系。

**3. 语义纯度机制四条路线（纯度递减）**

- **ASR 监督**：GLM-4-Voice、S3 Tokenizer、DualSpeechLM（理解驱动 loss 变体）——文本转写当监督，token 无重建义务，纯度上限最高。
- **SSL 蒸馏**：Moshi（WavLM 类 teacher）、FireRedAudio（RedAE 语义蒸馏）、X-Codec（SSL 特征重建）——染色方向是"加语义"而非"去说话人"。
- **LLM 对齐 loss**：LongCat-Next（L_llm）——对齐 LLM 语义但明言保留副语言。
- **无（纯重建）**：传统 codec——无纯度保证，speaker 信息大量残留。

**帧率规律**：生成侧主流收敛到 **12.5–25 Hz**（Kimi / GLM / Moshi / LongCat / Ming-Flash 均 12.5 Hz；FireRedAudio latent 25 Hz；codec 派 50 Hz）；理解侧连续表示 6.25–25 Hz。帧率越低 LLM 上下文越省，但细声学越依赖解码器补回。

## 3. Benchmark 量化口径：语义与音质

> [!note]
> 这里不是同一测试集上的统一排行榜。不同论文混用 ASR、TTS、codec reconstruction、speech editing、audio understanding 和主观听测；能比较的是“指标指向的能力”，不是绝对名次。

**指标分桶**：

| 评估目标 | 常用指标 | 读法 | 注意 |
|---|---|---|---|
| 语义 / 内容保持 | WER、CER、ACC、no-edit WER、MMAU、MMSU、VoiceBench | WER/CER 越低越好；ACC/benchmark accuracy 越高越好 | 更接近“说对没有”，不保证音色、韵律和自然度。 |
| 音质 / 可懂度 | PESQ、STOI、DNSMOS、UTMOS、MUSHRA、MOSNet | 通常越高越好 | 可能奖励听感但放过语义幻觉；生成式增强不能只看 MOS。 |
| 音色 / 副语言 | SIM、SPK-SIM、speaker similarity、RDE、RAE、arena win rate | SIM / win rate 越高越好；RDE/RAE 越低越好 | speaker embedding 指标会漏掉韵律、情绪和高频细节。 |
| 非语音音频 | FAD、FD、CLAP、AudioBox score | FAD/FD 越低越好；CLAP 越高越好 | 适合 sound/music，不适合直接评价语音增强。 |

**代表性数字**：

| 路线 | 代表模型 | 语义指标证据 | 音质 / 音色指标证据 | 读数判断 |
|---|---|---|---|---|
| 纯语义 token | [[方向/AI语音/模型/GLM-4-Voice]] / [[方向/AI语音/模型/S3 Tokenizer]] | GLM-4-Voice 12.5 Hz、175 bps tokenizer 在 LibriSpeech reconstruction 口径 WER 8.43。 | Ming-UniAudio 官方 tokenizer 对照中，GLM4-Voice-Tokenizer 在 SEED-ZH PESQ/SIM/STOI 为 1.06/0.33/0.61，SEED-EN 为 1.05/0.12/0.60。 | 语义压缩强、LLM 友好，但重建音质和 speaker 保真明显不是目标。 |
| 语义增强 codec | [[方向/AI语音/模型/X-Codec]] / [[方向/AI语音/模型/X-Codec2]] | X-Codec 在 VALL-E AR+NAR zero-shot TTS 上 WER 3.26%，低于 SpeechTokenizer 5.24% 和 acoustic codec 7.70%；ABX within/across 3.3/4.3。 | X-Codec2 记录口径：WER 2.47%、STOI 0.92、PESQ-WB/NB 2.43/3.04、SPK-SIM 0.82、UTMOS 4.13；流式变体 WER 3.24%、STOI 0.913、PESQ-WB 2.34、UTMOS 4.03。 | 比裸 acoustic codec 更稳地保内容，但 token 仍混有 speaker / acoustic 信息。 |
| 显式因子化离散 token | [[方向/AI语音/模型/UniAudio 2.0]] | ReasoningCodec 把 reasoning token 文本对齐，用于 ASR / QA / caption 等理解任务。 | reconstruction token 负责声学细节，并用 flow decoder 回波形；官方有 MUSHRA / reconstruction 评测，但本库尚未录入完整数字。 | 结构上最干净：语义计划和声学重建分流；数字还要回表补齐。 |
| 连续 latent + FM | [[方向/AI语音/模型/Ming-UniAudio]] / [[方向/AI语音/模型/FireRedAudio]] | Ming-UniAudio Seed-ZH/EN WER 0.95/1.85；FireRedAudio Zero-shot TTS 平均 CER/WER 1.20。 | MingTok-Audio tokenizer 在 SEED-ZH PESQ/SIM/STOI 为 4.21/0.96/0.98，SEED-EN 为 4.04/0.96/0.98；FireRedAudio Zero-shot TTS 平均 SIM 0.71，并在语义/声学编辑多项 WER、ACC、SIM、RDE、RAE 上优于 Ming-UniAudio-Edit。 | 音质和可编辑性证据最强，但 latent 是厚表示，语义/声学没有天然剥离。 |
| Omni RVQ token | [[方向/AI语音/模型/Qwen3.5-Omni]] | Qwen3.5-Omni-Plus 报告 MMAU 82.2、MMSU 82.8，LibriSpeech clean/other 1.11/2.23，FLEURS-102 6.55。 | Seed-TTS zh/en WER 0.99/1.26；多语 TTS 报告多数语言 speaker SIM 领先。 | 端到端效果强，但 tokenizer 规格未公开，不能把收益精确归因到 RVQ 表示。 |
| 低延迟 codec LM | [[方向/AI语音/模型/Moshi]] | Mimi 语义层经 SSL 蒸馏，适配全双工 spoken LM。 | 12.5 Hz、1.1 kbps、80 ms frame latency，重心是实时性而非最高保真。 | 是实时全双工基线；音质上限不应按后续大模型同口径排序。 |
| 理解优先双路 | [[方向/AI语音/模型/Kimi-Audio]] | LibriSpeech clean/other WER 1.28/2.42，AISHELL-1 CER 0.60；VoiceBench 平均 76.93。 | 生成侧 TTS / VC 是辅助能力，公开数字更偏理解与对话。 | 输入侧离散语义 + 连续声学有效；不是最强音质参照。 |

**对比结论**：

- 只看语义保持：ASR 监督纯语义 token、ReasoningCodec 的 reasoning token、X-Codec 的 semantic reconstruction 都比纯 acoustic codec 更稳。
- 只看音质重建：MingTok-Audio 这类连续 / 厚 latent 最强；GLM4-Voice 纯语义 token 的低 PESQ/SIM/STOI 反而说明它确实没有承担声学重建职责。
- 看统一模型生成效果：Qwen3.5-Omni、FireRedAudio、Ming-UniAudio 的端到端数字更强，但混入了 LLM、训练数据、decoder 和后训练收益，不能直接当 tokenizer 横评。
- 看 LLM-SE：最合理的研究组合仍是纯语义 token 保内容 + 连续 acoustic latent 保音质 + 显式 speaker / prosody 条件防泄漏。

## 4. 对 LLM-SE 的指向

v2 的选择组合 = **纯语义 token（AS 监督）+ 连续 acoustic latent（FM 生成）+ 显式 speaker / prosody 条件**——上表中没有现成模型落在这个组合上：最近的是 GLM-4-Voice（纯语义 + FM 解码）与 Ming-UniAudio（连续 + FM head + 编辑含 denoise）的交集。差异点仍是 SE 特有的 evidence 条件与退化建模，见 [[方向/AI语音/知识/技术路线/LLM-SE Training Recipe v2（显式解耦训练配方）]] 与 [[方向/AI语音/选型/LLM-SE 架构选型调研（统一音频模型对比）]]。

## 5. 相关对象

- [[方向/AI语音/知识/技术路线/语音生成 tokenizer codec 技术路线]]
- [[方向/AI语音/知识/技术路线/语音模型 tokenizer 与 LLM tokenizer 对比]]
- [[方向/AI语音/选型/LLM-SE 架构选型调研（统一音频模型对比）]]
- [[方向/AI语音/知识/技术路线/LLM-SE Training Recipe v2（显式解耦训练配方）]]
- [[方向/AI语音/知识/技术路线/LLM-SE Stage 0（表示空间准备）]]
- [[方向/AI语音/模型/S3 Tokenizer]]
- [[方向/AI语音/模型/BiCodec]]
- [[方向/AI语音/模型/X-Codec]]
- [[方向/AI语音/模型/X-Codec2]]
- [[方向/AI语音/模型/StableToken]]

## 6. 待验证

- StepAudio 2.5、MiniCPM-o 的 token 规格（帧率 / 词表 / 编码器），需回原始技术报告补记。
- Qwen3.5-Omni Audio Tokenizer 的帧率、codebook 层数与词表（技术报告未公开规格）。
- DualSpeechLM USToken 的帧率与词表；其 acoustic token 的 codec 选型细节。
- 各离散路线 token 的 speaker 泄漏同口径 probe（目前只有零散证据：WavLM hidden 强 SV、BiCodec SIM 0.80、X-Codec2 SPK-SIM 0.82）。

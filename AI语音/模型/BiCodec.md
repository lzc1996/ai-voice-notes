---
title: BiCodec
类型: 模型
发表时间: 2025-03-03
时间依据: Spark-TTS arXiv 首次提交日
任务:
  - 语音表示
  - 语音生成
开放状态:
  - paper
  - code
  - weights
  - demo
aliases:
  - BiCodec 解码器
  - BiCodec decoder
  - single-stream speech codec
  - single-stream decoupled speech tokens
tags:
  - 类型/对象
  - 方向/AI语音
  - 主题/语音表示
  - 主题/语音生成
---

# BiCodec

## 0. 背景

- **单流友好**：比多 codebook 并行 token 更容易交给 decoder-only LLM 自回归预测。
- **属性解耦**：把“说什么”和“谁在说/怎么说”拆开，有利于 voice cloning、性别、语速、音高等控制。
- **低码率**：semantic token 帧率低，减少 LLM 每秒要生成的 token 数。
- **工程代价**：音质、韵律和细节高度依赖 decoder / vocoder 质量；过强压缩可能造成重建损失或控制不稳。

## 1. 身份

BiCodec 是 [[Spark-TTS]] 提出的单流语音 codec / tokenizer，用来把语音拆成两类互补 token：低码率 semantic tokens 表示语言内容，固定长度 global tokens 表示说话人属性、音色和风格。LLM 预测这些离散 token 后，BiCodec decoder 再把 token 重建成连续语音波形。

边界：BiCodec 不是文本 tokenizer，也不是 ASR encoder；它是把连续语音和离散 speech tokens 互相转换的神经 codec。用户说的“BiCodec 解码器”通常指 token-to-waveform 的 decoder 部分。

## 2. 解码器做什么

- 输入：semantic tokens + global tokens，或由 LLM 预测出的单流解耦 speech token。
- 条件：global tokens 提供说话人级属性，semantic tokens 提供局部语言内容。
- 输出：连续语音波形。
- 角色：把 LLM 可建模的离散 token 序列还原成可听音频，是 LLM-based TTS / codec LM 路线里的最后一段。

## 3. 核心公式

$$(S, G) = \mathcal{E}(x), \qquad \hat{x} = \mathcal{D}(S, G)$$

- 解耦编解码：$x$ 为输入语音波形，$S=\{s_1,\dots,s_n\}$ 为低码率 semantic tokens（承载语言内容，帧率低），$G$ 为固定长度 global tokens（承载说话人级属性、音色、风格），$\hat{x}$ 为重建波形；LLM 预测出 $(S, G)$ 后由 decoder $\mathcal{D}$ 还原连续语音。

$$\mathcal{L}_{\mathrm{CE}} = -\sum_{t} \log p_\theta(s_t | s_{<t}, G)$$

- LLM 侧单流 AR 预测：$G$（来自参考音频或条件输入）作为全局条件，semantic token 逐个自回归生成；单流设计比多 codebook 并行 token 更适合 decoder-only LLM。

$$\mathcal{L}_{\mathrm{codec}} = \mathcal{L}_{\mathrm{rec}}(x, \hat{x}) + \lambda_a\,\mathcal{L}_{\mathrm{adv}} + \lambda_v\,\mathcal{L}_{\mathrm{quant}}$$

- codec 训练目标：BiCodec 端到端按 GAN 方式训练；频域重建损失使用 multi-scale mel-spectrogram L1，另有判别器 feature matching、VQ codebook / commitment loss、[[方向/AI语音/知识/基础概念/FSQ（有限标量量化）|FSQ]] global token 稳定训练项，以及 wav2vec 2.0 reconstruction loss 强化语义相关性。

## 4. 训练数据与设置

**BiCodec 自身训练数据**：不是用完整 VoxBox 训练，而是约 **3,000 小时**：LibriSpeech 全训练集 **960h**，再加 **1,000h Emilia-CN** 和 **1,000h Emilia-EN**。全部音频重采样到 **16 kHz**。

**BiCodec 训练设置**：

- global token length：**32**。
- semantic token：**50 TPS**，单 VQ codebook，codebook size **8192**。
- global tokenizer：ECAPA-TDNN encoder + learnable queries + cross-attention；[[方向/AI语音/知识/基础概念/FSQ（有限标量量化）|FSQ]] dimension **6**，每维 **4 levels**，等效 codebook size **4096**。
- 优化器：AdamW，$\beta_1=0.8$，$\beta_2=0.9$。
- batch：每 batch **614.4 秒语音**。
- 收敛：约 **800k training steps**。
- 16 kHz decoder 上采样率：`[8, 5, 4, 2]`；24 kHz 版本为 `[8, 5, 4, 3]`。

**不要混淆**：Spark-TTS 的 LLM 才使用完整 [[方向/AI语音/数据集/VoxBox|VoxBox]] 训练集；论文设置为 AdamW，$\beta_1=0.9$、$\beta_2=0.96$，训练 **3 epochs**，batch size **768 samples**。

## 5. 测试基准与性能

**测试基准**：作为 codec 的评测口径是语音重建质量（MOS / PESQ / STOI / 说话人相似度）与码率（bitrate、semantic token 帧率）；作为 TTS 底层时随 Spark-TTS 在 SEED 等测试集上报内容一致性（WER/CER）与 SS。BiCodec 无独立评测页，数字需从 Spark-TTS 论文正文表格提取。

**性能指标**：

- 独立重建（LibriSpeech test-clean）：codebook size 8192、1 codebook、50 TPS、650 bps；STOI 0.92、PESQ-NB 3.13、PESQ-WB 2.51、UTMOS 4.18、SIM 0.80。
- 低码率变体（LibriSpeech test-clean）：BiCodec-8192-25 为 25 TPS / 325 bps，STOI 0.89、PESQ-NB 2.62、PESQ-WB 2.05、UTMOS 4.13、SIM 0.71。
- 端到端参照（随 Spark-TTS，FunAudioLLM 官方对比表）：SEED test-zh CER 1.2% / SS 66.0%，test-en WER 1.98% / SS 57.3% —— 详见 [[方向/AI语音/模型/Spark-TTS|Spark-TTS]]「测试基准与性能」。

## 6. 表达瓶颈

BiCodec 的 global tokens 是固定长度（当前记录为 32 个），更像一句话/一段参考音的全局摘要，适合承载稳定的 speaker identity、平均音色和整体风格。但如果同一段音频内部情绪、能量、语速、音高或说话风格持续变化，固定 global tokens 可能不够表达这些时间变化；局部变化只能更多落到 semantic tokens、decoder 先验或额外条件里。

这和 FireRedAudio 的 RedAE-Patch Path 形成对照：RedAE-Patch 是随音频时长展开的连续 latent 序列，容量和时间分辨率更高，更适合保留动态副语言/声学变化；但它牺牲了 BiCodec 这类低码率离散 token 的 LLM 友好性和压缩效率。

## 7. 在现有模型里的位置

- [[方向/AI语音/模型/Spark-TTS|Spark-TTS]]：核心底层 codec，Qwen2.5 LLM 预测 BiCodec token，再由 BiCodec decoder 重建语音。
- [[方向/AI语音/模型/UniSE（Unified Speech Enhancement）|UniSE]]：作为离散 token codec，把 LM 生成的目标语音 token 解码成增强后的音频。

## 8. 和相邻概念的区别

- **EnCodec / SoundStream 类 codec**：常见多层 [[方向/AI语音/知识/基础概念/RVQ（残差向量量化）|RVQ]] 或较高 token 率，重建稳但 token 流更长。
- **semantic tokenizer**：偏语言内容，通常不完整保存说话人和声学细节；BiCodec 额外引入 global tokens。
- **continuous audio latent / VAE**：输出连续 latent，适合 diffusion / flow；BiCodec 输出离散 token，更贴近 LLM 自回归建模。

## 9. 关键资源

- [Spark-TTS Project Page](https://sparkaudio.github.io/spark-tts/)
  - 内容定位：官方项目页，说明 Spark-TTS built upon BiCodec，并把语音拆为 semantic tokens 和 global tokens。
  - 用途：建立 BiCodec 的身份和 token 分工。
  - 核验日期：2026-07-28
- [Spark-TTS paper](https://arxiv.org/abs/2503.01710)
  - 内容定位：论文正文说明 BiCodec 的训练数据、训练目标、优化器设置、token 配置和重建指标。
  - 用途：引用 Spark-TTS / BiCodec 的主论文来源。
  - 核验日期：2026-08-18
- [SparkAudio/Spark-TTS](https://github.com/SparkAudio/Spark-TTS)
  - 内容定位：官方推理代码仓库，包含 BiCodec 相关模型和推理链路。
  - 用途：查 decoder 配置、推理接口和工程实现。
  - 核验日期：2026-07-28
- [QuarkAudio-UniSE](https://huggingface.co/TechnoBaptist/QuarkAudio-UniSE)
  - 内容定位：UniSE 模型页，说明 LM 预测 speech tokens 后用 BiCodec 解码成音频。
  - 用途：确认 BiCodec 在语音增强 codec LM 路线中的使用。
  - 核验日期：2026-07-28

## 10. 相关对象

- [[方向/AI语音/知识/基础概念/NAC（神经音频 Codec）|神经音频 Codec]]：BiCodec 属于解耦 speech token codec 的具体实现。
- [[方向/AI语音/知识/技术路线/语音生成 tokenizer codec 技术路线|语音生成 tokenizer codec 技术路线]]：BiCodec 属于低码率离散 speech token 路线。
- [[方向/AI语音/模型/Spark-TTS|Spark-TTS]]：BiCodec 的主要公开案例。
- [[方向/AI语音/模型/UniSE（Unified Speech Enhancement）|UniSE]]：BiCodec decoder 用于统一语音增强输出波形。
- [[方向/AI语音/模型/Qwen-Audio-VAE|Qwen-Audio-VAE]]：连续 audio latent 路线，对比离散 token codec。

## 11. 待验证

- Spark-TTS 里的 BiCodec 和 UniSE 使用的 BiCodec 是否共享同一训练配置、权重来源和 token 设计。
- BiCodec decoder 是否可稳定 chunked / streaming 解码，以及真实首包延迟和边界伪影。
- global tokens 对 voice cloning、性别、音高、语速控制的可分离程度。
- 与 EnCodec、SoundStream、Qwen3-TTS 12Hz tokenizer 在中文长文本、歌声和噪声输入上的重建差异。
- 论文只给 LibriSpeech test-clean 重建指标；中文、长文本和真实噪声输入上的独立 codec 指标仍需实测。

---
title: WavLM
类型: 模型
参数量: Base / Base+ 94.70M；Large 316.62M
发表时间: 2021-10-26
时间依据: arXiv 首次提交日
任务:
  - 语音表示
开放状态:
  - paper
  - code
  - weights
aliases:
  - WavLM 编码器
  - WavLM Encoder
  - Microsoft WavLM
tags:
  - 类型/对象
  - 领域/AI语音
  - 主题/语音表示
---

# WavLM

## 0. 背景

**问题现场**：ASR、说话人、增强、分离等下游任务需要通用的语音表示，且要求对噪声、混响和多说话人场景鲁棒。

**前序路线的缺口**：HuBERT 等前序自监督模型的训练目标未专门考虑噪声与说话人混合条件，在说话人分离、diarization、语音增强等非 ASR 任务上不如 WavLM 适用。

**WavLM 的切入点**：在 masked prediction 预训练中加入 Mix（混入噪声/其他说话人）与 feature span masking，迫使模型从上下文恢复干净语音伪标签并把目标与干扰分开。

## 1. 内容定位

WavLM 是微软提出的自监督语音表示模型，核心形态是 **speech encoder**：把原始语音波形编码成逐帧的上下文特征。它常被下游 ASR、说话人任务、语音增强、语音分离或语音生成系统当作冻结的条件特征提取器。

边界：WavLM 不是 vocoder，也不是 audio codec；它主要输出特征表示，不直接把 token 解码回波形。

## 2. 编码器做什么

- 输入：语音波形。
- 前端：卷积特征提取器把波形降采样成帧级声学特征。
- 主体：Transformer encoder 通过 masked prediction 学习上下文语音表示。
- 输出：多层 hidden states，既包含声学信息，也包含一定语义和说话人信息。

## 3. 为什么有用

- 比手工声学特征更通用：下游模型可以少量标注或直接冻结使用。
- 对噪声、混响和多说话人场景更友好：WavLM 训练目标专门考虑了 speech denoising / utterance mixing。
- 适合作为条件编码器：例如 [[方向/AI语音/模型/UniSE（Unified Speech Enhancement）|UniSE]] 会冻结 WavLM，并平均多层 Transformer 特征作为语音增强任务的条件输入。

## 4. Mix + feature span masking

“Mix feature span masking”可以理解成 WavLM 预训练里的三步组合，而不是一个独立官方模块名：

1. **[[方向/AI语音/知识/基础概念/Mix（语音混合）|Mix]]**：把原始语音和噪声或另一段语音混合，模拟 noisy / overlapped speech。
2. **Feature span masking**：在卷积前端得到的帧级特征上遮住连续时间片段。
3. **Predict clean units**：Transformer 只在 masked span 上预测原始干净语音的离散 pseudo-label。

这个设计让模型不能只记住局部声学纹理，而要从上下文里恢复被遮住的目标语音内容；当输入里混入噪声或其他说话人时，它还被迫学习把目标语音和干扰分开。因此 WavLM 比 [[方向/AI语音/模型/HuBERT|HuBERT]] 更适合做说话人分离、diarization、语音增强等非 ASR 任务的上游 encoder。

## 5. 核心公式

- 混合输入构造（denoising / utterance mixing）：

$$\tilde{X} = X + \alpha N \quad \text{或} \quad \tilde{X} = X_1 + X_2$$

说明：$X$ 为干净语音特征，$N$ 为噪声，$\alpha$ 控制混合强度（对应不同 SNR）；也可直接混入另一段语音 $X_2$，模拟 overlapped speech。

- feature span masking 与 masked prediction 主目标：

$$\mathcal{L} = -\sum_{t \in \mathcal{M}} \log P(q_t \mid \tilde{X}), \qquad \tilde{X}_t = \mathbf{0} \ (t \in \mathcal{M})$$

说明：$\mathcal{M}$ 为卷积前端特征上被遮住的连续时间片段，$q_t$ 为**干净**语音的 cluster pseudo-label；损失只在 masked span 上计算，且目标来自干净语音而非混合信号。

- soft-label 概率（同 HuBERT 系）：

$$P(k \mid t) = \mathrm{softmax}_k\left(\hat{\mathbf{h}}_t \cdot \hat{\mathbf{c}}_k / \tau\right)$$

说明：$\hat{\mathbf{h}}_t$ 为 masked 帧的输出表示，$\hat{\mathbf{c}}_k$ 为聚类中心，$\tau$ 为温度；soft label 交叉熵迫使模型从上下文恢复被遮目标语音、并把目标与混入的噪声/其他说话人区分开。

## 6. 测试基准与性能

**测试基准**（来源：WavLM 论文）

- SUPERB benchmark：15 个子任务（ASR、说话人验证、说话人分离、KWS、意图分类、槽位填充、情感识别等）。
- LibriSpeech 960h 微调（ASR）。
- VoxCeleb1（说话人验证）。
- LibriCSS（语音分离后的 ASR）。

**性能指标**（来源：WavLM 论文）

- LibriSpeech 960h 微调：WavLM Large 在 test-clean 1.8% / test-other 3.2% WER，与 wav2vec 2.0、HuBERT 相当。
- SUPERB：WavLM Large 在 15 个子任务中 14 个超过 HuBERT Large，SUPERB 总分绝对提升 +2.4。
- VoxCeleb1：三套官方 trial list 上 EER 0.383% / 0.480% / 0.986%。
- LibriCSS：相对 Conformer 基线 WER 相对降低 27.7%。

## 7. 流式能力：双向 encoder 天然非流式

WavLM 是纯双向 encoder：第 $t$ 帧的表示依赖**所有帧**（包括未来帧），且计算量 $O(T^2)$。这与严格流式（音频一到就出结果、结果不再变）直接矛盾，因此 WavLM 的"正统"用法是**离线整段编码**。需要流式时只有三条路：

1. **Chunk 内双向（最常用的近似）**：切成固定窗口，窗口内部完整双向、窗口间各算各的。代价是边界效应——靠近 chunk 右边缘的帧缺少未来上下文，表示与整段编码不一致。缓解办法是重叠上下文 + 只保留中间帧：`[左上下文 | 本 chunk | 右 lookahead] → 编码 → 只取本 chunk 的输出`，本质是**用延迟（≈ lookahead 长度）和重复计算换双向性**。
2. **改架构**：因果卷积 + 受限注意力的 [[方向/AI语音/知识/基础概念/Streaming Conformer|streaming Conformer]] / [[方向/AI语音/模型/Emformer|Emformer]] / chunk-wise attention，每帧只依赖"历史 + 有限未来"，可增量输出且结果稳定——但那是另一个模型，不再是 WavLM。
3. **绕开 SSL 前端**：实时产品（如 DeepFilterNet）直接用因果判别模型。

UniSE 的实际形态印证这一点：输入切 5 秒固定段、WavLM 段内双向编码、段间无状态传递（[[方向/AI语音/知识/基础概念/TSE（目标说话人提取）|TSE]]/SS 靠参考音频维持跨段说话人一致性），即"**5 秒级准实时**"而非逐帧流式；UniSE v2 论文也把 full-utterance conditioning 列为局限和未来方向。

一句话：双向 encoder 的流式化没有免费午餐——要么切 chunk 接受边界损失和延迟，要么改架构牺牲全局上下文。

## 8. 和相邻概念的区别

- **[[方向/AI语音/模型/HuBERT|HuBERT]] / wav2vec 2.0**：同属自监督语音表示路线；WavLM 更强调噪声和说话人混合条件下的鲁棒表示。
- **语音 tokenizer / codec**：通常要把语音压成离散 token 或可解码 latent；WavLM 更像特征编码器，不负责音频重建。
- **ASR encoder**：ASR encoder 通常服务转写目标；WavLM encoder 更通用，可迁移到多种 speech processing 任务。

## 9. 关键来源

- [WavLM: Large-Scale Self-Supervised Pre-Training for Full Stack Speech Processing](https://arxiv.org/abs/2110.13900)
  - 内容定位：WavLM 论文，记录自监督预训练目标、denoising / utterance mixing 设计和 full-stack speech processing 评测。
  - 用途：理解 WavLM 为什么能作为通用语音编码器。
  - 核验日期：2026-07-28
- [Microsoft UniSpeech - WavLM](https://github.com/microsoft/UniSpeech/tree/main/WavLM)
  - 内容定位：官方代码和模型入口。
  - 用途：查模型、推理和下游任务使用方式。
  - 核验日期：2026-07-28
- [Hugging Face - microsoft/wavlm-base-plus](https://huggingface.co/microsoft/wavlm-base-plus)
  - 内容定位：常用 WavLM Base+ 模型卡。
  - 用途：快速接入 Transformers 生态。
  - 核验日期：2026-07-28

## 10. 相关对象

- [[方向/AI语音/知识/基础概念/SSL 编码器|SSL 编码器]]：WavLM 是该类自监督语音编码器的具体代表。
- [[方向/AI语音/知识/基础概念/Mix（语音混合）|Mix]]：WavLM 预训练中用于构造 noisy / overlapped speech 的数据操作。
- [[方向/AI语音/模型/UniSE（Unified Speech Enhancement）|UniSE]]：把 WavLM 作为冻结条件特征提取器。
- [[方向/AI语音/模型/DeWavLM-Omni|DeWavLM-Omni]]：UniPASE 中基于 WavLM 微调的 universal speech enhancement 表示模块。
- [[方向/AI语音/MOC - ASR|ASR]]：WavLM 可作为 ASR 或 forced alignment 等任务的上游表示。
- [[方向/AI语音/知识/技术路线/语音模型 tokenizer 与 LLM tokenizer 对比|语音模型 tokenizer 与 LLM tokenizer 对比]]：区分 speech representation、semantic token 和 codec token。
- [[方向/AI语音/知识/基础概念/Reverberation Modeling（混响建模）|混响建模]]：WavLM 的鲁棒表示常用于处理噪声、混响和远场语音。

## 11. 待验证

- UniSE 平均 WavLM 全层特征是否优于只取最后层或特定中间层。（UniSE 论文未消融；SUPERB 等基准上可学习加权和通常略优于等权平均）
- WavLM、[[方向/AI语音/模型/HuBERT|HuBERT]]、Whisper encoder 在语音增强条件编码里的稳定性差异。
- 中文/方言 ASR 或语音 Agent 场景里，WavLM 是否仍是最合适的冻结 encoder。

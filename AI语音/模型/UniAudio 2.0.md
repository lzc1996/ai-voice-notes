---
title: UniAudio 2.0
类型: 模型
发表时间: 2026-02-04
时间依据: arXiv v1 首次提交日
任务:
  - 音频理解
  - 音频生成
  - ASR
  - TTS
  - 音频问答
  - 音乐生成
开放状态:
  - paper
  - code
  - weights
  - demo
aliases:
  - UniAudio2
  - UniAudio2.0
  - UniAudio 2
  - UniAudio2_ckpt
  - "UniAudio 2.0: A Unified Audio Language Model with Text-Aligned Factorized Audio Tokenization"
tags:
  - 类型/对象
  - 方向/AI语音
  - 任务/音频理解
  - 任务/音频生成
  - 任务/ASR
  - 任务/TTS
  - 主题/音频tokenizer
---

# UniAudio 2.0

## 0. 背景

**问题现场**：希望用同一个自回归 text-audio 架构覆盖语音、环境声和音乐的理解与生成任务，音频 token 需同时支持理解、高保真重建和层次化生成。

**前序路线的缺口**：早期 UniAudio 只做统一音频生成；理解任务若只依赖低层 acoustic code、生成任务若只从文本直接猜细粒度声学 token，两头都不理想。

**UniAudio 2.0 的切入点**：文本对齐的因子化音频 tokenizer ReasoningCodec——把音频拆成文本对齐的 reasoning tokens 与重建友好的 reconstruction tokens，再由单个自回归 text-audio 模型处理 9-stream token。

## 1. 身份

`UniAudio 2.0` 是 Dongchao Yang 等提出的统一音频语言模型，目标是用同一个自回归 text-audio 架构覆盖语音、环境声和音乐的理解与生成任务。它从早期 [[方向/AI语音/模型/UniAudio|UniAudio]] 的「统一音频生成」推进到「理解 + 生成 + 少样本 / 零样本泛化」，核心新增是文本对齐的因子化音频 tokenizer：ReasoningCodec。

边界：UniAudio 2.0 不是纯 TTS、纯 ASR 或单一 text-to-music 模型；它的重点是把音频 token 设计成既能支持理解，又能支持高保真重建和层次化生成。

## 2. 核心信息

- **ReasoningCodec**：把音频离散化为 reasoning tokens 和 reconstruction tokens；前者偏文本对齐、高层分析/规划，后者偏声学细节和波形重建。
- **统一架构**：text token 与 audio token 共同进入自回归模型，用多阶段训练和多任务数据构造覆盖理解与生成。
- **训练规模**：论文摘要口径为 100B text tokens + 60B audio tokens。
- **任务面**：GitHub README 列出 speech、sound、music 三类任务，包括 TTS、ASR、speech Q&A、text-to-sound、audio caption、text-to-music、song generation 等。
- **开放状态**：官方 repo、demo 和 Hugging Face checkpoints 已公开；checkpoint 页标注 MIT license。
- **工程注意**：README 说明当前 LLM 支持 8192 版本 `ReasoningCodec.checkpoint`；`ReasoningCodec_1024.checkpoint` 更适合 reconstruction comparison。

## 3. 核心机制

### 3.1. 输入到输出流水线

```text
ReasoningCodec：音频 x -> 冻结 Whisper / music SSL / WavLM 等专家特征 -> query transformer 压缩 -> RVQ -> reasoning tokens r（低帧率、文本对齐）+ reconstruction tokens s（8 路多层声学 token）-> flow decoder / vocoder -> 可重建波形。

音频理解：输入音频 -> ReasoningCodec reasoning tokens r -> 9-stream text-audio 表示（8 路 audio + 1 路 text）-> audio understanding experts + cross-modal experts -> text head -> ASR / caption / QA / 分类答案。

音频生成：文本 prompt / 少样本上下文 -> cross-modal experts -> audio generation experts -> local audio decoder 自回归预测每帧 K 个 audio tokens -> reconstruction tokens s -> flow-based decoder -> speech / sound / music waveform。
```

UniAudio 2.0 的关键在 ReasoningCodec：先把音频拆成文本对齐的 reasoning tokens 和重建友好的 reconstruction tokens，再用单个自回归 text-audio 模型处理 9-stream token 张量。这样理解任务不用只依赖低层 acoustic code，生成任务也不用只从文本直接猜细粒度声学 token。

### 3.2. 核心公式

ReasoningCodec 的因子化口径：

$$
r=\mathcal{T}_{r}(x),\quad s=\mathcal{T}_{s}(x\mid r),\quad \hat{x}=\mathcal{D}(s)
$$

reasoning branch 用 query-based compression：

$$
z=\mathrm{Enc}(Q,h)\in\mathbb{R}^{M\times d},\quad M=\lceil T/K\rceil
$$

reconstruction branch 的 group-wise quantization：

$$
s=\Big(\mathrm{VQ}_{1}(h^{\text{ph}}),\ \mathrm{VQ}_{2}(h^{\text{mu}}),\ \mathrm{RVQ}_{3:8}(h^{\text{env}})\Big)
$$

用 [[方向/AI语音/知识/基础概念/FiLM（特征级线性调制）|FiLM]] 把 reasoning 信息注入 reconstruction 特征：

$$
\mathrm{FiLM}(S_e;\hat{R})=\gamma(\hat{R})\odot S_e+\beta(\hat{R})
$$

统一模型把 backbone 切成理解、跨模态、生成三段：

$$
H^{(u)}=\mathcal{F}_{\mathrm{u}}(h),\quad
H^{(c)}=\mathcal{F}_{\mathrm{cm}}(H^{(u)}),\quad
H^{(g)}=\mathcal{F}_{\mathrm{g}}(H^{(c)})
$$

audio-only expert 只更新音频位置，尽量保留文本路径：

$$
H'=H+M_{\mathrm{aud}}\odot\big(f(H)-H\big)
$$

文本和音频的自回归损失：

$$
\mathcal{L}_{\mathrm{text}}=-\sum_{t\in\mathcal{T}}\log p_{\theta}(x_{t,\mathrm{text}}\mid X_{<t})
$$

$$
\mathcal{L}_{\mathrm{audio}}=-\sum_{t\in\mathcal{A}}\sum_{k=1}^{K}\log p_{\theta}(x_{t,k}\mid x_{t,<k},h^{(g)}_t)
$$

$$
\mathcal{L}_{\mathrm{AR}}=\lambda_{\mathrm{text}}\mathcal{L}_{\mathrm{text}}+\lambda_{\mathrm{audio}}\mathcal{L}_{\mathrm{audio}}
$$

### 3.3. 机制要点

- **factorized tokenization**：reasoning tokens 负责文本对齐抽象，reconstruction tokens 负责声学细节。
- **9-stream 表示**：8 路 audio codebook + 1 路 text stream，让同一 transformer 处理异构 token。
- **专用专家但不换主干**：audio understanding / cross-modal / audio generation 分段提供容量，同时保留自回归接口。
- **reasoning token 降低生成不确定性**：先预测高层语义计划，再预测细粒度 reconstruction token，降低长程声学建模难度。

## 4. 使用判断

- 看**audio tokenizer**：ReasoningCodec 是本页最值得跟踪的点，适合和 [[方向/AI语音/模型/X-Codec2]]、codec LM 路线、连续表示路线对比。
- 看**统一音频底座**：适合和 [[方向/AI语音/模型/Kimi-Audio]]、[[方向/AI语音/模型/FireRedAudio]]、[[方向/AI语音/模型/UALM]]、[[方向/AI语音/模型/Audex]] 比较理解/生成混训后的能力边界。
- 看**泛化能力**：论文重点声称在 speech、sound、music 的 unseen tasks 上有 few-shot / zero-shot generalization；第三方复测前先当作官方口径。

## 5. 相关对象

- [[方向/AI语音/MOC - 音频大模型]]：方向地图。
- [[方向/AI语音/模型/UniAudio|UniAudio]]：ICML 2024 前代，统一 speech / sound / music / singing voice 生成任务。
- [[方向/AI语音/模型/AudioLM]]：audio token LM 路线早期代表。
- [[方向/AI语音/模型/X-Codec2]]：离散 speech codec / tokenizer 对照对象。
- [[方向/AI语音/知识/基础概念/FiLM（特征级线性调制）|FiLM]]：ReasoningCodec reconstruction 分支的语义回注机制。
- [[方向/AI语音/模型/Kimi-Audio]]：通用音频基础模型对照，重点是离散+连续双输入。
- [[方向/AI语音/模型/FireRedAudio]]：理解 + 生成统一模型，对照连续表示解耦路线。
- [[方向/AI语音/模型/UALM]] / [[方向/AI语音/模型/Audex]]：NVIDIA 统一 audio-text LLM 对照线。

## 6. 来源

- [UniAudio 2.0: A Unified Audio Language Model with Text-Aligned Factorized Audio Tokenization（arXiv:2602.04683）](https://arxiv.org/abs/2602.04683)
  - 内容定位：技术论文入口，提出 ReasoningCodec、统一自回归 text-audio 架构、100B text + 60B audio token 训练口径。
  - 用途：确认模型身份、发表时间、核心 tokenizer 设计和训练规模。
  - 核验日期：2026-09-01
- [yangdongchao/UniAudio2（GitHub）](https://github.com/yangdongchao/UniAudio2)
  - 内容定位：官方代码仓库，列出支持任务、安装推理方式、checkpoint 使用建议和 MIT license。
  - 用途：确认代码开放、任务面、ReasoningCodec checkpoint 口径和本地推理入口。
  - 核验日期：2026-09-01
- [Dongchao/UniAudio2_ckpt（Hugging Face）](https://huggingface.co/Dongchao/UniAudio2_ckpt)
  - 内容定位：官方 checkpoint 页，包含 ReasoningCodec、LLM checkpoint、配置与 MIT license。
  - 用途：确认权重开放和 checkpoint 文件结构。
  - 核验日期：2026-09-01
- [UniAudio 2.0 Demo](https://dongchaoyang.top/UniAudio2Demo/)
  - 内容定位：官方 demo 页，给出项目入口、论文、代码/checkpoint 链接和任务样例。
  - 用途：确认 demo 与项目归属。
  - 核验日期：2026-09-01
- [UniAudio: Towards Universal Audio Generation with Large Language Models（ICML 2024 / PMLR）](https://proceedings.mlr.press/v235/yang24x.html)
  - 内容定位：UniAudio 1.x 论文，统一音频生成路线前身，覆盖 speech、sound、music、singing voice 生成。
  - 用途：确认 UniAudio 2.0 的前代路线和差异边界。
  - 核验日期：2026-09-01

## 7. 待验证

- ReasoningCodec 的 reasoning / reconstruction token 是否需要拆成独立概念页。
- UniAudio 2.0 在中文 ASR、长音频理解、song generation 和 speech-to-speech QA 上的第三方复测表现。
- 与 Kimi-Audio、FireRedAudio、UALM、Audex 在统一理解+生成任务上的真实取舍：tokenizer、上下文长度、生成质量、文本能力回退。

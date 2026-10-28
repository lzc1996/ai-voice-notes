---
title: DualSpeechLM
类型: 模型
发表时间: 2025-08-12
时间依据: arXiv v1 首次提交日；AAAI 2026 proceedings 于 2026-03-14 发布
会议: AAAI 2026
任务:
  - 语音理解
  - 语音生成
  - ASR
  - TTS
  - 语音翻译
  - 语音对话
开放状态:
  - paper
  - code
  - demo
aliases:
  - Dual Speech LM
  - DualSpeechLLM
  - UUG
  - Unified Understanding and Generation
  - "DualSpeechLM: Towards Unified Speech Understanding and Generation via Dual Speech Token Modeling with Large Language Models"
tags:
  - 类型/对象
  - 方向/AI语音
  - 任务/语音理解
  - 任务/语音生成
  - 任务/ASR
  - 任务/TTS
  - 主题/音频tokenizer
---

# DualSpeechLM

## 0. 背景

**问题现场**：统一语音理解与生成面临信息粒度冲突——理解需要高层语义，生成需要细粒度声学，且存在 speech-token / text-token modality gap。

**前序路线的缺口**：把同一个 codec token 同时当输入输出的 SpeechLM 难以兼容两种粒度需求，对齐 text LLM 也更难。

**DualSpeechLM 的切入点**：dual-token modeling——输入侧用 USTokenizer 提取偏语义的 USToken，输出侧由 AcousticGPT 生成 acoustic token，辅以 semantic supervision loss 与 Chain-of-Condition 稳定训练。

## 1. 身份

`DualSpeechLM` 是 CUHK / Tencent AI Lab 等提出的统一语音理解与生成模型，核心是把「理解需要高层语义」和「生成需要细粒度声学」拆成两类 speech token：输入侧使用 USTokenizer 产生的 USToken，输出侧生成 acoustic token，再由 AcousticGPT 恢复声学细节。

边界：DualSpeechLM 不是纯 ASR、纯 TTS，也不是把同一个 codec token 同时当输入输出的 SpeechLM；它的价值在于 dual-token modeling，把理解 token 和生成 token 分路建模，减少 speech-token / text-token modality gap，同时保留生成所需声学信息。

## 2. 核心信息

- **USTokenizer**：Understanding-driven Speech Tokenizer，提取更接近文本语义空间的高层 speech token，降低 text LLM 接语音输入的对齐难度。
- **双 token 建模**：USToken 作为 LLM 输入，acoustic token 作为生成输出；不同 token 满足理解和生成的不同信息粒度。
- **AcousticGPT**：接在 text LLM 模块中联合训练，把隐藏状态转成 acoustic token，用来恢复细粒度声学细节。
- **训练稳定性**：论文引入 semantic supervision loss 与 [[方向/AI语音/知识/技术路线/Chain-of-Condition（条件链）|Chain-of-Condition（CoC）]] 策略，目标是稳定统一框架训练并提升语音生成。
- **任务面**：官方 demo 覆盖 TTS、voice conversion、text-to-speech translation、speech conversation；GitHub 推理脚本也列出 ASR / TTS。
- **开放状态**：论文、AAAI 2026 版本、项目 demo、USTokenizer / DualSpeechLM 代码已公开；README 标注 pretrained weights 仍是 coming soon。
- **工程依赖**：repo 示例使用 Phi-3.5-mini-instruct 作 text backbone，并要求 WavTokenizer 配置与 checkpoint 作为 acoustic token 路径。

## 3. 核心机制

### 3.1. 输入到输出流水线

```text
语音理解 / ASR
输入语音 X
  -> Whisper-medium encoder：最终隐藏状态 E
  -> 2× downsampling Encoder + VQ codebook：USToken Z
  -> Adapter：映射到 text LLM input space，得到语义条件 m
  -> text LLM：按文本 token 自回归解码
  -> 输出文本 / 转写 / 语音理解答案

TTS / 语音生成
文本 prompt P + 说话人条件 Spk
  -> text LLM：先生成目标语音的 USToken U^tar（语义骨架）
  -> AcousticGPT：用 CoC 条件 S 与 Spk 生成 acoustic token A^tar
  -> acoustic decoder / WavTokenizer 路径
  -> 输出语音波形

语音到语音任务（VC / T2ST / speech conversation）
输入语音 X_in + 指令 / 文本 prompt P
  -> USTokenizer：输入语音转成 U^in
  -> text LLM：结合 P 和 U^in 生成 U^tar 或文本中间结果
  -> AcousticGPT：从 U^tar + prompt hidden states + Spk 生成 A^tar
  -> acoustic decoder
  -> 输出目标语音
```

总机制：USTokenizer 把输入语音压成偏语义的 USToken，text LLM 负责理解与规划，AcousticGPT 负责把语义骨架翻回可听的 acoustic token。DualSpeechLM 因此不是用同一串 codec token 硬兼容理解和生成，而是让理解输入和生成输出使用不同粒度的 speech token。

### 3.2. USTokenizer

输入语音 $X$ 先经过 Whisper-medium encoder 得到最终隐藏状态 $E$，再经过 2× downsampling Encoder、单层 VQ codebook 得到离散 USToken $Z$。量化向量同时走两条监督：一条经 Decoder 重建 $\hat{E}$，保留必要语音信息；另一条经 Adapter 映射进冻结 text LLM 的 input space，用理解任务反向约束 token 更贴近文本语义空间。

USTokenizer 的三项损失：

$$
\mathcal{L}_{\mathrm{reconstruction}}(E, \hat{E}) = \frac{1}{N} \sum_{i=1}^{N} (E_i - \hat{E}_i)^2
$$

$$
\mathcal{L}_{\mathrm{Under}} = -\sum_{t=1}^{L} \log p(S_t \mid m, S_{<t}; \theta)
$$

$$
\mathcal{L}_{\mathrm{USTokenizer}} = \alpha \cdot \mathcal{L}_{\mathrm{commit}} + \beta \cdot \mathcal{L}_{\mathrm{Under}} + \gamma \cdot \mathcal{L}_{\mathrm{reconstruction}}
$$

这里 $S_t$ 是目标文本 token，$m$ 是 USTokenizer 从 speech prompt 提取的特征，$\alpha, \beta, \gamma$ 是损失权重。理解驱动损失是关键：它不只是让 token 可重建语音，而是让 USToken 更像 text LLM 能直接消费的语义条件。

### 3.3. Dual-token generation

生成任务里，$U^{\mathrm{in}}$ 和 $P$ 分别表示输入语音的 USToken 与 prompt，$U^{\mathrm{tar}}$ 表示目标语音的 USToken，$A^{\mathrm{tar}}$ 表示目标 acoustic token。text LLM 先预测目标 USToken 序列：

$$
p(U^{\mathrm{tar}} \mid P, U^{\mathrm{in}}; \theta) = \prod_{t=1}^{L} p(U^{\mathrm{tar}}_t \mid U^{\mathrm{tar}}_{<t}, P, U^{\mathrm{in}}; \theta)
$$

对应 semantic supervision loss：

$$
\mathcal{L}_{\mathrm{semantic}} = -\frac{1}{L} \sum_{t=1}^{L} \log p(U^{\mathrm{tar}}_t \mid U^{\mathrm{tar}}_{<t}, P, U^{\mathrm{in}}; \theta)
$$

AcousticGPT 再基于语义条件和 speaker embedding 自回归生成 acoustic tokens：

$$
\mathcal{L}_{\mathrm{acoustic}} = -\sum_{t=1}^{L} \log p(A^{\mathrm{tar}}_t \mid A^{\mathrm{tar}}_{<t}, S, Spk; \theta)
$$

$$
S \in \{S_p, U^{\mathrm{tar}}, [S_p; U^{\mathrm{tar}}]\}
$$

最终生成损失：

$$
\mathcal{L}_{\mathrm{generation}} = \lambda \cdot \mathcal{L}_{\mathrm{semantic}} + \xi \cdot \mathcal{L}_{\mathrm{acoustic}}
$$

### 3.4. Chain-of-Condition（CoC）

CoC 是 AcousticGPT 的条件采样策略，详见 [[方向/AI语音/知识/技术路线/Chain-of-Condition（条件链）]]。训练时等概率从三种条件里采样：prompt hidden states $S_p$、预测/目标 USToken $U^{\mathrm{tar}}$、拼接条件 $[S_p; U^{\mathrm{tar}}]$；推理时固定使用拼接条件 $[S_p; U^{\mathrm{tar}}]$。作用是让 AcousticGPT 不过拟合单一路径，并在 USToken 预测不准时仍可依赖 prompt hidden states 提供更稳的语义条件。

### 3.5. 机制要点

- **为什么双 token**：USToken 牺牲一部分声学细节换 text alignment；acoustic token 补回生成需要的音色、韵律、说话人等细节。
- **为什么 semantic loss 重要**：没有它，生成任务里的 USToken 质量会塌，AcousticGPT 条件变差，TTS/VC/T2ST/SC 指标显著下降。
- **为什么 reconstruction loss 不能删**：删掉后某些文本/翻译类任务可能更贴文本空间，但 SER、TTS、VC 这类需要细粒度语音信息的任务明显变差。

## 4. 使用判断

- 看**SpeechLM 统一建模**：DualSpeechLM 是「理解 token 输入 + 声学 token 输出」的代表，适合和 [[方向/AI语音/模型/UniAudio 2.0]] 的 ReasoningCodec 因子化 token 对照。
- 看**语音生成可控性**：CoC 与 semantic supervision 是训练稳定性的关键点，但权重未公开前只能先看论文和 demo。
- 看**系统边界**：它关注 unified speech understanding / generation，不等于全模态 Omni；视觉、长视频和工具调用不是主线。

## 5. 相关对象

- [[方向/AI语音/MOC - 音频大模型]]：方向地图。
- [[方向/AI语音/知识/技术路线/Chain-of-Condition（条件链）]]：DualSpeechLM AcousticGPT 的条件采样策略。
- [[方向/AI语音/模型/UniAudio 2.0]]：同样关注 audio tokenizer 的理解/生成统一，但使用 ReasoningCodec 因子化路线。
- [[方向/AI语音/模型/Kimi-Audio]]：通用音频基础模型对照，重点是离散语义 token + 连续声学特征双输入。
- [[方向/AI语音/模型/FireRedAudio]]：理解 + 生成统一模型，对照连续表示解耦路线。
- [[方向/AI语音/模型/UALM]] / [[方向/AI语音/模型/Audex]]：统一 audio-text LLM 对照线。
- [[方向/AI语音/模型/AudioLM]] / [[方向/AI语音/模型/Moshi]]：codec token / speech language modeling 早期和实时对照。
- [[方向/AI语音/知识/技术路线/语音生成 tokenizer codec 技术路线]]：tokenizer / codec 路线总入口。

## 6. 来源

- [DualSpeechLM: Towards Unified Speech Understanding and Generation via Dual Speech Token Modeling with Large Language Models（arXiv:2508.08961）](https://arxiv.org/abs/2508.08961)
  - 内容定位：arXiv 论文入口，提出 USTokenizer、dual-token modeling、semantic supervision loss 与 Chain-of-Condition。
  - 用途：确认模型身份、arXiv 首次提交日期、核心方法和任务边界。
  - 核验日期：2026-09-01
- [DualSpeechLM - AAAI Proceedings](https://ojs.aaai.org/index.php/AAAI/article/view/40663)
  - 内容定位：AAAI 2026 proceedings 页面，列出作者、DOI、页码 33728–33736 与 2026-03-14 发布日期。
  - 用途：确认正式会议版本和发表信息。
  - 核验日期：2026-09-01
- [lavendery/UUG（GitHub）](https://github.com/lavendery/UUG)
  - 内容定位：官方实现仓库，包含 USTokenizer、DualSpeechLM 代码、训练/推理脚本、依赖说明和权重发布状态。
  - 用途：确认代码开放、Phi-3.5-mini-instruct / WavTokenizer 依赖、ASR/TTS 推理入口和权重仍待发布。
  - 核验日期：2026-09-01
- [DualSpeechLM Demo](https://lavendery.github.io/Unified-Understanding-and-Generalization-Demo/)
  - 内容定位：官方 demo 页，展示 TTS、voice conversion、T2ST、speech conversation 等任务样例。
  - 用途：确认模型任务面和生成样例入口。
  - 核验日期：2026-09-01

## 7. 待验证

- pretrained weights 发布后，USTokenizer 与 DualSpeechLM 的实际可复现程度。
- USTokenizer 是否需要拆成独立对象页，尤其是与 UniAudio 2.0 ReasoningCodec、X-Codec2、WavTokenizer 的对比。
- 在中文 ASR/TTS、跨语种 T2ST、speech conversation 上相对 Kimi-Audio、FireRedAudio、UALM、Audex 的第三方复测差异。

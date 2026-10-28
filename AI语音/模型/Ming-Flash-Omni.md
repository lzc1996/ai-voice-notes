---
title: Ming-Flash-Omni
类型: 模型
参数量: 100B MoE / 6.1B 激活参数（论文口径）；HF 2.0 模型卡写作 100B / 6B active
发表时间: 2025-10-28
时间依据: arXiv v1 首次提交日；Ming-flash-omni 2.0 官方权重页记录 2026-02-11 发布
任务:
  - 多模态理解
  - 视频理解
  - 音频理解
  - 上下文 ASR
  - 方言 ASR
  - TTS
  - 语音生成
  - 音频生成
  - 图像生成
  - 图像编辑
开放状态:
  - paper
  - code
  - weights
  - demo
aliases:
  - Ming-flash-omni
  - Ming Flash Omni
  - MingFlashOmni
  - Ming-flash-omni Preview
  - Ming-flash-omni-Preview
  - Ming-flash-omni 2.0
  - Ming-flash-omni-2.0
  - inclusionAI/Ming-flash-omni-2.0
  - "Ming-Flash-Omni: A Sparse, Unified Architecture for Multimodal Perception and Generation"
tags:
  - 类型/对象
  - 方向/AI语音
  - 领域/大模型
  - 主题/多模态
  - 任务/音频理解
  - 任务/TTS
  - 任务/语音生成
---

# Ming-Flash-Omni

## 0. 背景

**问题现场**：构建开源全模态 Omni 模型，统一覆盖 image / text / video / audio 感知与 text / image / audio 生成，音频线上重点是 context-aware ASR、方言 ASR 与 speech / sound / music 统一生成。

**前序路线的缺口**：让语音走离散 codec token 的生成路线存在量化损失。

**Ming-Flash-Omni 的切入点**：稀疏 MoE thinker（100B 总参 / 约 6.1B 激活）+ 12.5 Hz 低帧率连续 VAE acoustic latent + flow-matching 生成头，绕开离散 token 量化损失。

## 1. 内容定位

`Ming-Flash-Omni` 是 Inclusion AI / Ant Group 的开源 Omni-MLLM，沿着 `Ming-Omni` 升级到更稀疏的 Ling-Flash-2.0 MoE 底座。它支持 image / text / video / audio 输入，输出 text / image / audio；在音频线上的关注点是 context-aware ASR、方言 ASR，以及把 speech / sound / music 放进单通道连续声学生成路径。

边界：它不是纯语音模型，也不是 [[方向/AI语音/模型/Ming-UniAudio]] 这种 speech LLM；Ming-Flash-Omni 是全模态 perception + generation 模型，音频生成只是其中一条输出路径。和 [[方向/AI语音/模型/LongCat-Next]] 类似，它更适合作为「开源全模态 Omni」对象，放入音频大模型 MOC 是为了跟踪语音输入/输出能力。

## 2. 核心信息

- **基座**：Ling-Flash-2.0 sparse MoE，论文口径 100B total / 6.1B active per token；2.0 模型卡写作 100B total / 6B active。
- **版本线**：Preview 于 2025-10-27 公开，2.0 于 2026-02-11 公开；2.0 是当前官方推荐下载版本。
- **输入/输出**：官方模型卡列出 image、text、video、audio 输入，image、text、audio 输出。
- **音频能力**：context-aware ASR、Chinese dialect ASR、zero-shot voice cloning、speech / sound effects / music joint generation、细粒度 vocal attribute control。
- **视觉能力**：time-interleaved VideoRoPE、generative segmentation-as-editing、single-stream diffusion transformer、identity preservation、高保真图中文字渲染。
- **训练流程**：perception stage 做 progressive pre-training、two-stage instruction tuning、GRPO；generation stage 冻结 perception MLLM，分别优化图像生成器并复用预训练音频生成器。

## 3. 核心机制

### 3.1. 输入到输出流水线

```text
多模态理解：text / image / video / audio -> modality preprocessing + encoders -> time-interleaved VideoRoPE / audio encoder / image encoder -> multimodal aggregate -> Ling-Flash-2.0 MoE thinker -> text tokens -> 文本答案 / ASR / 视频理解 / 多轮跨模态对话。

语音 / 音频生成：LLM 生成文本 token + downsampled VAE acoustic latents -> fixed Qwen2.5-0.5B audio head 自回归预测 flow-matching conditioning signal -> continuous acoustic latent / flow head -> speech / sound / music waveform（44.1 kHz 统一采样率 + super-resolution）。

图像生成 / 编辑：文本与多模态条件 -> multi-scale learnable queries -> single-stream diffusion transformer -> noisy latent 与参考图像 VAE latent 统一注意力 -> image decoder -> 生成 / 编辑图像；segmentation 被转成 semantics-preserving editing 任务。
```

Ming-Flash-Omni 的机制核心是「稀疏 MoE thinker + 连续生成头」：理解侧用统一多模态 encoder 聚合到 LLM，生成侧不再让语音走离散 speech token，而是用低帧率连续 VAE latent 和 flow-matching head 合成声学输出；图像侧用单流 diffusion transformer 把理解与编辑/生成目标靠近。

### 3.2. 核心公式

MoE 路由可按 top-$k$ sparse expert 口径理解：

$$
h' = \sum_{e\in \operatorname{TopK}(r(h), k)} g_e(h)\,E_e(h)
$$

其中 $r(h)$ 是 router，$g_e(h)$ 是第 $e$ 个 expert 的门控权重，Ming-Flash-Omni 的有效计算量来自只激活少数 expert：

$$
P_{\mathrm{total}}\approx100\mathrm{B},\quad P_{\mathrm{active}}\approx6.1\mathrm{B}\ \text{per token}
$$

音频生成改用低帧率连续 acoustic latent，tokenizer 压缩口径：

$$
R_{\mathrm{audio}}=12.5\ \mathrm{Hz},\quad z_{1:T}=\mathrm{VAE}_{\mathrm{enc}}(x_{44.1k})
$$

audio head 从 LLM text tokens 和 downsampled VAE latents 预测 flow condition：

$$
c_t = H_{\mathrm{audio}}(y_{<t}, z_{\le t}^{\downarrow})
$$

flow-matching 生成头可按连续路径速度场训练口径理解：

$$
\mathcal{L}_{\mathrm{FM}}=\mathbb{E}_{t,x_0,x_1}\left\lVert v_{\theta}(x_t,t,c)-\left(x_1-x_0\right)\right\rVert_2^2
$$

视觉生成 / 编辑的 flow objective：

$$
\mathcal{L}_{\mathrm{img}}=\mathbb{E}_{t,\epsilon,x}\left\lVert v_{\theta}(x_t,t,\text{cond})-v^{*}(x_t,t,x)\right\rVert_2^2
$$

GRPO 阶段按组内相对优势更新策略，适合多任务 reward：

$$
A_i=\frac{r_i-\operatorname{mean}(r_{1:G})}{\operatorname{std}(r_{1:G})},\quad
\mathcal{L}_{\mathrm{GRPO}}=-\frac{1}{G}\sum_{i=1}^{G}\min\left(\rho_i A_i,\operatorname{clip}(\rho_i,1-\epsilon,1+\epsilon)A_i\right)
$$

### 3.3. 机制要点

- **稀疏扩容**：总参数扩到 100B，但每 token 只激活约 6B，降低全模态模型的推理成本。
- **理解与生成两阶段**：perception MLLM 负责看/听/读/推理，generation heads 负责把结果落到 speech 或 image。
- **语音生成走连续 latent**：绕开离散 codec token 的量化损失，代价是生成头和 VAE/flow 链路更复杂。
- **图像生成引入 segmentation-as-editing**：把分割变成生成式编辑任务，用编辑质量反向强化细粒度感知。

## 4. 使用判断

- 看**开源全模态 Omni**：适合和 [[方向/AI语音/模型/LongCat-Next]]、[[方向/AI语音/模型/Qwen3-Omni]]、[[方向/AI语音/模型/MiniCPM-o]] 对照。
- 看**音频路线**：重点不是 codec token，而是 12.5 Hz 连续 VAE latent + flow head，对照 [[方向/AI语音/模型/Ming-UniAudio]]、[[方向/AI语音/模型/Kimi-Audio]]、[[方向/AI语音/模型/X-Codec]] / [[方向/AI语音/模型/X-Codec2]]。
- 看**工程落地**：100B MoE 仍是服务器侧模型；SGLang-Omni 文档建议 thinker 做 tensor parallel，talker 单独占 GPU。
- 看**评估口径**：官方声明覆盖视觉、音频、图像生成等多类 benchmark，跨模型结论仍需第三方复测。

## 5. 相关对象

- [[方向/AI语音/MOC - 音频大模型]]：本页归属的方向地图。
- [[方向/AI语音/模型/Ming-UniAudio]]：同属 Inclusion AI Ming 音频线，但 Ming-UniAudio 是专门 speech LLM / continuous speech representation。
- [[方向/AI语音/模型/LongCat-Next]]：开源原生多模态 / Omni 对照，重点是 DiNA 离散多模态 token。
- [[方向/AI语音/模型/Qwen3-Omni]] / [[Qwen2.5-Omni]]：全模态语音交互对照线。
- [[方向/AI语音/模型/MiniCPM-o]]：端侧实时全模态对照。
- [[方向/AI语音/模型/Kimi-Audio]]：通用音频底座对照，重点是离散语义 token + 连续声学特征混合输入。
- [[方向/AI语音/模型/Qwen-Audio-VAE]]：连续 audio latent / VAE 路线对照。
- [[方向/AI语音/模型/X-Codec]] / [[方向/AI语音/模型/X-Codec2]]：离散 codec token 路线对照。

## 6. 来源

- [Ming-Flash-Omni: A Sparse, Unified Architecture for Multimodal Perception and Generation（arXiv:2510.24821）](https://arxiv.org/abs/2510.24821)
  - 内容定位：技术报告入口，记录 Ming-Flash-Omni 的 100B/6.1B MoE、统一感知生成、音频/视觉机制和 arXiv 版本历史。
  - 用途：确认模型身份、发表时间、参数口径、任务范围和核心机制。
  - 核验日期：2026-09-02
- [Ming-Flash-Omni arXiv HTML](https://arxiv.org/html/2510.24821)
  - 内容定位：论文 HTML，可检索架构、Audio generation、VideoRoPE、GRPO、训练流程和数据构造。
  - 用途：抽取输入到输出机制、12.5 Hz VAE tokenizer、continuous acoustic latent 和训练公式口径。
  - 核验日期：2026-09-02
- [inclusionAI/Ming（GitHub）](https://github.com/inclusionAI/Ming)
  - 内容定位：官方 Ming 仓库，包含 Ming-flash-omni 2.0 README、模型下载、环境配置、cookbook 和 demo。
  - 用途：确认开源代码、版本线、下载入口和本地运行路径。
  - 核验日期：2026-09-02
- [inclusionAI/Ming-flash-omni-2.0（Hugging Face）](https://huggingface.co/inclusionAI/Ming-flash-omni-2.0)
  - 内容定位：官方 2.0 权重页，列出模型输入/输出模态、100B/6B active、MIT license、ModelScope 下载和用法。
  - 用途：确认当前推荐权重、开放许可证和工程接入口。
  - 核验日期：2026-09-02
- [inclusionAI/Ming-flash-omni-Preview（Hugging Face）](https://huggingface.co/inclusionAI/Ming-flash-omni-Preview)
  - 内容定位：Preview 权重页，记录 2025-10-27 preview release、100B-A6B MoE、ContextASR / dialect ASR / voice clone 等能力说明。
  - 用途：确认 Preview 与 2.0 的版本关系和早期能力口径。
  - 核验日期：2026-09-02
- [SGLang-Omni Ming cookbook](https://github.com/sgl-project/sglang-omni/blob/main/docs/cookbook/ming_omni.md)
  - 内容定位：SGLang-Omni 部署文档，说明 Ming-flash-omni-2.0 可通过 OpenAI-compatible endpoint serving，并拆为 thinker / talker pipeline。
  - 用途：确认实际服务链路、GPU 拆分和 speech pipeline 工程约束。
  - 核验日期：2026-09-02

## 7. 待验证

- Ming-Flash-Omni 2.0 与 Preview 在权重、tokenizer、audio head、图像生成器上的具体差异。
- Ming-Flash-Omni 和 [[方向/AI语音/模型/Ming-UniAudio]] 是否共享 VAE audio tokenizer / continuous generation head，或只是同团队相邻路线。
- context-aware ASR、方言 ASR、speech / sound / music single-channel generation 的第三方复测。
- 100B MoE 本地 serving 的显存、吞吐、首包延迟、talker 流式边界伪影和 voice clone 稳定性。

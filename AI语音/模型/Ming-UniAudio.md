---
title: Ming-UniAudio
类型: 模型
参数量: 16.8B MoE / 2.8B 激活参数；公开模型名为 Ming-UniAudio-16B-A3B
发表时间: 2025-10-26
时间依据: arXiv v1 首次提交日；官方项目页/模型卡另有 2025-09-30 发布口径
任务:
  - 音频理解
  - ASR
  - TTS
  - 语音生成
  - 语音编辑
  - 上下文 ASR
开放状态:
  - paper
  - code
  - weights
  - benchmark
aliases:
  - Ming UniAudio
  - Ming-UniAudio-16B-A3B
  - Ming-UniAudio-16B-A3B-Edit
  - MingTok-Audio
  - Ming-Unitok-Audio
  - Ming-Freeform-Audio-Edit
  - "Ming-UniAudio: Speech LLM for Joint Understanding, Generation and Editing with Unified Representation"
tags:
  - 类型/对象
  - 方向/AI语音
  - 任务/音频理解
  - 任务/ASR
  - 任务/TTS
  - 任务/语音编辑
  - 主题/音频tokenizer
---

# Ming-UniAudio

## 0. 背景

**问题现场**：让一个 speech LLM 用统一表示同时覆盖语音理解（ASR / 上下文 ASR）、生成（TTS）和自然语言指令的 free-form 语音编辑。

**前序路线的缺口**：理解侧用连续特征、生成侧用离散 token 的分裂表示，使语义编辑与声学编辑难以统一到同一表示流上。

**Ming-UniAudio 的切入点**：MingTok-Audio 连续统一表示 $Z_{\text{uni}}$（VAE + Whisper 初始化语义模块）同时服务理解与生成，生成用 per-token diffusion / flow-matching head，编辑无需显式 timestamp 条件。

## 1. 内容定位

`Ming-UniAudio` 是 Inclusion AI / Ant Group 提出的 speech LLM，目标是用统一连续语音表示同时覆盖 speech understanding、speech generation 和 instruction-based free-form speech editing。它的核心对象不是离散 codec token，而是 `MingTok-Audio`：一个基于 VAE + causal Transformer 的连续语音 tokenizer，把语义信息和声学细节压到同一套连续表示里。

边界：它不是 [[方向/AI语音/模型/UniAudio 2.0]] 的同名后续，也不是纯 TTS / ASR 系统；更适合放在「统一语音表示 + 语音编辑」路线下，和 [[方向/AI语音/模型/Kimi-Audio]] 的离散+连续混合输入、[[方向/AI语音/模型/DualSpeechLM]] 的双 token、[[方向/AI语音/模型/Qwen3-Omni]] 的端到端 Omni 线对照。

## 2. 核心信息

- **统一表示**：MingTok-Audio 生成连续 $Z_{\text{uni}}$，同时服务理解和生成，避免理解侧连续特征与生成侧离散 token 分裂。
- **tokenizer 架构**：encoder / semantic module / decoder 三段；semantic module 基于 Whisper large-v3 encoder 改造，decoder 预测 complex spectrogram 后经 iSTFT 合成。
- **主干模型**：16.8B MoE / 2.8B active decoder-only LLM，公开模型名为 `Ming-UniAudio-16B-A3B`。
- **生成头**：不用离散 audio vocabulary 直接生成 codec token，而是用 per-token diffusion / flow-matching head 从 LLM hidden states 合成连续语音表示。
- **编辑能力**：`Ming-UniAudio-16B-A3B-Edit` 面向自然语言指令语音编辑，覆盖 deletion / insertion / substitution、denoise、speed / pitch / volume、dialect / emotion conversion 等。
- **开放形态**：官方开放技术报告、GitHub repo、Hugging Face / ModelScope 权重、MingTok-Audio tokenizer 和 Ming-Freeform-Audio-Edit benchmark。

## 3. 核心机制

### 3.1. 输入到输出流水线

```text
MingTok-Audio：输入语音 x -> waveform reshape + frame projection -> unidirectional Transformer encoder -> VAE latent Gaussian -> compact Z_latent -> Whisper large-v3 初始化的 semantic module -> high-dimensional Z_uni -> unidirectional Transformer decoder + Vocos-style synthesis head -> complex spectrogram -> iSTFT -> 重建语音。

音频理解 / ASR：输入语音 -> MingTok-Audio 得到 Z_uni -> pooling audio token compression 降到 LLM 帧率 -> decoder-only MoE LLM -> text head 自回归输出 transcription / answer / context ASR。

语音生成 / TTS：文本 prompt / 上下文 -> decoder-only MoE LLM -> hidden states + predicted semantic sequence -> per-token diffusion / flow-matching head -> continuous speech representation -> MingTok-Audio decoder -> 语音波形。

free-form speech editing：源语音 + 自然语言编辑指令 -> Z_uni + instruction tokens -> LLM 先理解局部/全局编辑目标，可输出 CoT_text -> per-token diffusion head 合成目标连续表示 -> decoder -> 编辑后语音。
```mermaid

机制重点是闭环表示流：$Z_{\text{uni}}$ 既要足够高维、语义丰富，能作为 LLM 输入做理解；又要能通过低维 $Z_{\text{latent}}$ 和 decoder 回到高保真语音。这样语义编辑和声学编辑都不需要先切出显式 timestamp region。

### 3.2. 核心公式

MingTok-Audio encoder 输出 VAE latent distribution，并由 semantic module 映射到统一表示：

$$
q_{\phi}(Z_{\text{latent}}\mid x)=\mathcal{N}(\mu_{\phi}(x),\sigma_{\phi}^{2}(x)I),\quad
Z_{\text{uni}}=f_{\text{sem}}(Z_{\text{latent}})
$$

声学重建阶段使用 VAE-GAN 风格 generator loss：

$$
\mathcal{L}_{G}=\lambda_{\text{rec}}\mathcal{L}_{\text{rec}}+\lambda_{\text{adv}}\mathcal{L}_{\text{adv}}+\lambda_{\text{fm}}\mathcal{L}_{\text{fm}}+\lambda_{\text{kl}}\mathcal{L}_{\text{KL}}
$$

语义蒸馏把 unified feature 对齐到冻结 Whisper encoder 的语义输出：

$$
\mathcal{L}_{\text{distill}}=\mathrm{MSE}(Z_{\text{uni}},Z_{\text{semantic}})
$$

统一 tokenizer 训练同时保留语义对齐与声学重建：

$$
\mathcal{L}_{\text{align}}=-\sum_{t=1}^{T}\log P(y_t\mid Z_{\text{uni}},y_{<t})
$$

$$
\mathcal{L}=\lambda_{\text{align}}\mathcal{L}_{\text{align}}+\lambda_{\text{rec}}\mathcal{L}_{\text{rec}}
$$

LLM 输入前用 pooling 压缩连续语音特征：

$$
Z_{\text{uni}}^{\prime}[i]=\mathtt{Pooling}(Z_{\text{uni}}[pi:p(i+1)]),\quad i=0,\dots,\left\lfloor\frac{l_{\text{uni}}}{p}\right\rfloor-1
$$

生成头按 per-token flow matching 理解；论文明确采用 OT path 和 CFG，但没有展开完整目标，可按通用口径记为：

$$
\mathcal{L}_{\text{FM}}=\mathbb{E}_{t,x_0,x_1}\left\lVert v_{\theta}(x_t,t,h)-\left(x_1-x_0\right)\right\rVert_2^2
$$

连续 token 没有天然 `<EOS>`，所以额外 stop head 做逐帧二分类，loss 以 0.01 缩放：

$$
\mathcal{L}_{\text{stop}}=0.01\cdot\mathrm{CE}(s_t,\hat{s}_t)
$$

### 3.3. 机制要点

- **连续统一表示**：用 $Z_{\text{uni}}$ 同时承载语义和声学，而不是理解/生成各用一套 tokenizer。
- **高维理解 + 低维生成**：$Z_{\text{latent}}$ 提供生成可建模性，semantic module 把它扩成 LLM 可用的高维语义表示。
- **生成不走离散词表**：LLM 负责自回归规划，per-token diffusion head 负责高质量连续语音合成。
- **编辑是 understand-then-synthesize**：先理解自然语言编辑意图，再合成目标语音；语义编辑偏局部，声学编辑偏全局。

### 3.4. 架构示意（概念级）

> [!note] 架构示意（概念级）
> 按本页已有输入—中间表示—输出链路整理，不替代论文结构图。

```
flowchart LR
  A["文本 / 源语音 + 指令"] --> B["MingTok-Audio unified representation"]
  B --> C["MoE speech LLM"]
  C --> D["Per-token diffusion / flow head"]
  D --> E["Tokenizer decoder"]
  E --> F["编辑后或生成语音"]
  C --> G["文本 / ASR 输出"]
```

## 4. 使用判断

- 看**语音编辑**：比普通 TTS / ASR 更值得关注的是无需 timestamp condition 的自然语言语音编辑。
- 看**表示路线**：适合和 [[方向/AI语音/模型/UniAudio 2.0]] 的 factorized discrete audio tokens、[[方向/AI语音/模型/Kimi-Audio]] 的离散+连续双输入对照。
- 看**生成质量**：连续表示 + flow head 有利于保留声学细节，但工程复杂度高于纯离散 codec LM。
- 看**上下文 ASR**：官方报告显示 context ASR / 方言 ASR 是强项之一，但跨报告 benchmark 仍要谨慎复测。

## 5. 相关对象

- [[方向/AI语音/MOC - 音频大模型]]：本页归属的方向地图。
- [[方向/AI语音/模型/Ming-Flash-Omni]]：同属 Inclusion AI Ming 系列，但 Ming-Flash-Omni 是全模态 Omni-MLLM，Ming-UniAudio 是专门 speech LLM。
- [[方向/AI语音/模型/Kimi-Audio]]：通用音频底座对照，重点是离散语义 token + 连续声学特征混合输入。
- [[方向/AI语音/模型/UniAudio 2.0]]：统一音频理解/生成对照，重点是 ReasoningCodec 的因子化 token。
- [[方向/AI语音/模型/DualSpeechLM]]：统一语音理解/生成对照，重点是 USToken + acoustic token 双 token 建模。
- [[方向/AI语音/模型/Qwen3-Omni]] / [[Qwen2.5-Omni]]：端到端 Omni 语音交互对照。
- [[方向/AI语音/模型/Whisper]]：semantic module 初始化和语义蒸馏相关背景。
- [[方向/AI语音/模型/X-Codec2]]：离散 codec token 路线对照。

## 6. 来源

- [Ming-UniAudio: Speech LLM for Joint Understanding, Generation and Editing with Unified Representation（arXiv:2511.05516）](https://arxiv.org/abs/2511.05516)
  - 内容定位：技术报告入口，描述 MingTok-Audio、Ming-UniAudio 主干、free-form speech editing、训练公式和评测结果。
  - 用途：确认模型身份、发表时间、参数口径、核心机制和公式。
  - 核验日期：2026-09-01
- [inclusionAI/Ming-UniAudio（GitHub）](https://github.com/inclusionAI/Ming-UniAudio)
  - 内容定位：官方代码仓库，包含模型介绍、下载入口、环境配置、demo、SFT recipe 和评测说明。
  - 用途：确认开源状态、模型/benchmark 下载入口和工程复现路径。
  - 核验日期：2026-09-01
- [inclusionAI/Ming-UniAudio-16B-A3B（Hugging Face）](https://huggingface.co/inclusionAI/Ming-UniAudio-16B-A3B)
  - 内容定位：官方基础模型权重页，列出 speech understanding / generation 能力、模型下载和环境说明。
  - 用途：确认公开权重、模型名和使用入口。
  - 核验日期：2026-09-01
- [Ming-Unitok-Audio project page](https://xqacmer.github.io/Ming-Unitok-Audio.github.io/)
  - 内容定位：官方项目 / demo 页面，展示 free-form speech editing、audio understanding、voice clone 和 multilingual synthesis 示例。
  - 用途：确认项目演示范围和编辑任务形态。
  - 核验日期：2026-09-01

## 7. 基准性能与待实验

以下结果整理自 [Ming-UniAudio arXiv 论文](https://arxiv.org/abs/2511.05516) Table 11–14。WER 越低越好，SIM、ACC 越高越好；中文 / 英文结果按论文原表分别记录。

#### 7.1.1. ContextASR Bench

| 场景 | WER↓ | NE-WER↓ | NE-FNR↓ |
|---|---:|---:|---:|
| Speech-English | 4.00 | 3.56 | 3.69 |
| Dialogue-English | 5.34 | 8.73 | 2.53 |
| Speech-Mandarin | 1.58 | 5.98 | 2.40 |
| Dialogue-Mandarin | 3.04 | 9.50 | 1.48 |

论文称 Ming-UniAudio 在 ContextASR Bench 的 12 个子任务中有 8 个达到 SOTA；这里保留论文结论，不把它改写成跨基准总排名。

#### 7.1.2. 多数据集 ASR

| 数据集 | aishell2-ios | LS-clean | Hunan | Guangyue | Chuanyu | Shanghai |
|---|---:|---:|---:|---:|---:|---:|
| Ming-UniAudio WER↓ | 2.84 | 1.62 | 9.80 | 5.51 | 5.46 | 14.65 |

#### 7.1.3. Speech generation

| 数据集 | WER↓ | SIM↑ |
|---|---:|---:|
| Seed-zh | 0.95 | 0.70 |
| Seed-en | 1.85 | 0.58 |

#### 7.1.4. Speech editing

| 任务 | WER zh/en↓ | ACC zh/en↑ | SIM zh/en↑ | No-edit WER zh/en↓ | 其他 |
|---|---|---|---|---|---|
| Deletion-basic | 11.89 / 14.85 | 100 / 82.22 | 0.78 / 0.76 | 11.49 / 24.26 | — |
| Deletion-full | 22.92 / 27.60 | 82.92 / 85 | 0.81 / 0.74 | 17.50 / 35.21 | — |
| Insertion-basic | 3.42 / 6.63 | 80 / 71.43 | 0.83 / 0.79 | 3.52 / 17.70 | — |
| Insertion-full | 3.89 / 7.59 | 79.31 / 62.31 | 0.83 / 0.79 | 4.10 / 18.84 | — |
| Substitution-basic | 4.52 / 8.99 | 78.62 / 59.78 | 0.82 / 0.78 | 4.63 / 19.28 | — |
| Substitution-full | 4.56 / 7.64 | 76.62 / 65.62 | 0.83 / 0.77 | 4.75 / 18.39 | — |
| Dialect conversion | 8.93 | 0.50 | 0.66 | — | — |
| Speed alteration | 5.88 / 17.53 | — | 0.66 / 0.57 | — | RDE 6.36 / 5.92 |
| Pitch alteration | 7.45 / 13.37 | — | 0.36 / 0.24 | — | — |
| Volume alteration | 1.71 / 1.35 | — | 0.86 / 0.80 | — | RAE 14.9 / 11.7 |
| Add sound | 3.59 | — | 0.78 | — | DNSMOS OVRL 2.46 |

#### 7.1.5. DNS Challenge

| 系统 | DNSMOS OVRL↑ | DNSMOS SIG↑ | DNSMOS BAK↑ |
|---|---:|---:|---:|
| Ming-UniAudio | 3.26 | 3.59 | 3.97 |

- **结构决策**：暂不把 `MingTok-Audio` 拆成独立 tokenizer 页；当前它只服务本页，先保留在 Ming-UniAudio 的表示路线中，等被其他 Ming 音频 / Omni 模型复用或需要独立 benchmark 时再拆。
- `Ming-UniAudio-16B-A3B-Edit` 与基础 `Ming-UniAudio-16B-A3B`、[[方向/AI语音/模型/Ming-Flash-Omni]]、Ming-Lite-Omni 的具体权重继承关系。
- free-form speech editing 在非官方 benchmark、真实口语指令和更长音频上的泛化表现。
- vLLM / Docker 路径在非 H800/H20 服务器上的显存、RTF 和依赖复杂度。

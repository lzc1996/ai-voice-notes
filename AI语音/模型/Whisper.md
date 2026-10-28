---
title: Whisper
类型: 模型
参数量: tiny 39M；base 74M；small 244M；medium 769M；large 1550M；turbo 809M
发表时间: 2022-09-21
时间依据: OpenAI 官方发布日
任务:
  - ASR
开放状态:
  - paper
  - api
aliases:
  - OpenAI Whisper
  - whisper-1
  - Robust Speech Recognition via Large-Scale Weak Supervision
tags:
  - 类型/对象
  - 方向/AI语音
  - 任务/ASR
---

# Whisper

## 0. 背景

**问题现场**：需要一个覆盖多语言转写、语音翻译与语言识别的通用、可复现的 ASR 基线。

**Whisper 的切入点**：用 680,000 小时多语言、多任务监督数据训练 encoder-decoder Transformer，音频按 30 秒片段转 log-Mel spectrogram 进 encoder，自回归解码输出文本 token。

## 1. 身份

Whisper 是 OpenAI 发布的 automatic speech recognition（ASR）模型族，原始开源版本面向多语言语音识别、语音翻译和语言识别；OpenAI API 中仍提供 `whisper-1` 作为 speech-to-text / translation 模型。

边界：Whisper 是稳定通用 ASR 基线，不是完整会议系统。它原生不解决说话人分离、VAD、热词强约束、会议段落合并和术语纠错，这些通常要靠外部工程链路补齐。

## 2. 核心信息

- 训练：OpenAI 说明 Whisper 使用 680,000 小时多语言、多任务监督数据训练。
- 架构：encoder-decoder Transformer；音频按 30 秒片段处理，转换为 [[方向/AI语音/知识/基础概念/Spectrogram（声谱图）|log-Mel spectrogram]] 后进入 encoder。
- 能力：多语言转写、语言识别、语音翻译到英文。
- API：`whisper-1` 可用于 transcription / translation；截至 2026-07-28，OpenAI Help Center 说明 `whisper-1` 不支持 streaming。
- 开源定位：本地推理适合作为离线、可复现、低成本 ASR baseline。

### 2.1. 架构示意（概念级）

> [!note] 架构示意（概念级）
> 按本页已有输入—中间表示—输出链路整理，不替代论文结构图。

```mermaid
flowchart LR
  A["Waveform"] --> B["Log-mel spectrogram"]
  B --> C["Transformer encoder"]
  C --> D["Autoregressive decoder"]
  D --> E["Text tokens"]
```

## 3. 核心公式

- log-Mel 声谱图输入（encoder 前端）：

$$X_{t,f} = \log\left(\mathrm{Mel}\big(|\mathrm{STFT}(x)|\big)[t,f]\right)$$

说明：$x$ 为 16 kHz 原始波形，$\mathrm{STFT}$ 得短时幅度谱，$\mathrm{Mel}$ 投影到 80 维 Mel 刻度；$X \in \mathbb{R}^{T \times 80}$ 为 encoder 的帧级输入（$T$ 为帧数，对应 30 秒片段）。

- encoder-decoder 交叉注意力：

$$\mathbf{H} = \mathrm{Encoder}(X), \quad \mathrm{Attn}_t = \mathrm{softmax}\left(\frac{Q_t K^\top}{\sqrt{d_k}}\right) V$$

说明：$\mathbf{H}$ 为 encoder 输出的声学表示；解码端每一步以 $\mathbf{H}$ 为 key/value（$K = W_K \mathbf{H}$、$V = W_V \mathbf{H}$），以解码器状态为 query $Q_t$，$\sqrt{d_k}$ 为缩放因子。

- 自回归解码与序列交叉熵训练目标：

$$P(y_t \mid y_{<t}, X) = \mathrm{softmax}(W_o \mathbf{h}_t^{dec}), \qquad \mathcal{L} = -\sum_{t=1}^{T_y} \log P(y_t \mid y_{<t}, X)$$

说明：$y_{<t}$ 为已生成 token 序列（含 language / task / timestamps 等特殊任务 token），$\mathbf{h}_t^{dec}$ 为解码器隐状态，$W_o$ 为词表投影；$\mathcal{L}$ 为多任务监督下的标准序列交叉熵损失。

## 4. 测试基准与性能

**测试基准**

- LibriSpeech test-clean / test-other：论文主基准，后续评测沿用。
- Common Voice 15、Fleurs：官方 large-v3 发布评测的逐语言 WER/CER（中文、日文、泰文等按 CER 统计）。
- 论文附录 D.1 / D.2 / D.4：覆盖 tiny→large-v3、turbo 全模型族的多语言 WER/CER 明细。
- 真实场景参考：会议、播客、客服录音等（第三方汇总，非官方基准）。

**性能指标**

| 基准 | large-v3 WER（%） |
| --- | --- |
| LibriSpeech test-clean | 2.7 |
| LibriSpeech test-other | 5.2 |
| Common Voice 15（多语言） | 9.0 |

- large-v3 相对 large-v2 错误率降低约 10%–20%（Common Voice 15 + Fleurs 逐语言；官方 large-v3 发布口径）。
- turbo 为 large-v3 的优化版，官方称精度损失最小（官方发布口径）。
- 真实场景参考值：会议 / 播客等约 8%–12%，劣质客服录音约 17.7%（第三方汇总，待核）。

（来源：2.7 / 5.2 / 9.0 为论文与官方发布口径、多方引用一致；10%–20% 与 turbo 说明见官方 large-v3 发布材料。）

## 5. 什么时候选 Whisper

- 需要离线开源 ASR 基线，尤其是多语言、英文、公开视频/播客/字幕处理。
- 需要做模型横评：Whisper 是 Qwen3-ASR、FunASR、GPT-4o Transcribe、Seed-ASR 对比时的必要参照。
- 任务不强依赖说话人分离、严格热词、实时 partial 稳定输出或中文企业会议工程链路。

## 6. 不适合直接承担的任务

- **会议转写**：需要外接 VAD、diarization、标点、段落、术语修正。
- **实时语音 Agent**：开源 Whisper 可做流式改造，但不是最省延迟的默认方案；API `whisper-1` 不支持 streaming。
- **强热词/术语控制**：prompt 更像上下文提示，不是严格词表约束。
- **细粒度强制对齐**：普通转写时间戳不等于 forced aligner。

## 7. 为什么没有继续走开源 Whisper 主线

更准确地说：OpenAI 没有停止语音识别跟进，而是把后续主线从“开源独立 ASR 基线”转到 **GPT-4o / Realtime / Audio API** 里的语音模型。Whisper 仍适合作为本地可复现 ASR baseline；更新的云端路线则是 `gpt-4o-transcribe`、`gpt-4o-mini-transcribe` 和 `gpt-realtime-whisper` 这类 API 模型。

- **产品重心变化**：从离线转写基线转向低延迟语音 Agent、实时转写、语音交互和多模态工作流。
- **架构路线变化**：后续 speech-to-text 模型建立在 GPT-4o / GPT-4o-mini 架构和专门音频训练之上，不是简单发布一个“Whisper vN”开源 checkpoint。
- **接口策略变化**：更强的新模型主要通过 API 和 Realtime API 提供；`whisper-1` 继续作为 legacy / baseline 入口存在。
- **工程边界变化**：`whisper-1` 不支持 streaming；低延迟 live transcription 由 Realtime transcription 路线承接。

## 8. 关键资源

- [OpenAI - Whisper model page](https://developers.openai.com/api/docs/models/whisper-1)
  - 内容定位：`whisper-1` 当前 API 模型页，说明 general-purpose speech recognition、transcription / translation 端点。
  - 用途：确认 API 形态和当前模型入口。
  - 核验日期：2026-07-28
- [OpenAI - Introducing Whisper](https://openai.com/index/whisper/)
  - 内容定位：OpenAI 发布页，记录 680,000 小时多语言多任务数据、架构和开源定位。
  - 用途：模型身份、训练数据规模和架构来源。
  - 核验日期：2026-07-28
- [Robust Speech Recognition via Large-Scale Weak Supervision](https://cdn.openai.com/papers/whisper.pdf)
  - 内容定位：Whisper 论文 PDF。
  - 用途：引用训练方法、模型评估和 long-form transcription 结论。
  - 核验日期：2026-07-28
- [OpenAI Help Center - Audio API FAQ](https://help.openai.com/en/articles/7031512-whisper-audio-api-faq)
  - 内容定位：Whisper / Audio API FAQ，说明 transcription、translation、大文件和 streaming 边界。
  - 用途：确认 `whisper-1` API 限制。
  - 核验日期：2026-07-28
- [OpenAI - Introducing next-generation audio models in the API](https://openai.com/index/introducing-our-next-generation-audio-models/)
  - 内容定位：OpenAI 发布 `gpt-4o-transcribe` / `gpt-4o-mini-transcribe`，说明相对原始 Whisper 的 WER、语言识别和准确率改进。
  - 用途：解释后续语音识别路线转入 GPT-4o 音频 API。
  - 核验日期：2026-07-30
- [OpenAI - Advancing voice intelligence with new models in the API](https://openai.com/index/advancing-voice-intelligence-with-new-models-in-the-api/)
  - 内容定位：OpenAI 发布 `GPT-Realtime-Whisper` 等实时语音模型，强调低延迟 streaming speech-to-text。
  - 用途：解释 Whisper 名称在实时转写产品线中的延续。
  - 核验日期：2026-07-30
- [OpenAI - GPT-Realtime-Whisper model page](https://developers.openai.com/api/docs/models/gpt-realtime-whisper)
  - 内容定位：`gpt-realtime-whisper` 模型页，说明面向 live audio 的低延迟 transcript deltas 和 Realtime transcription endpoint。
  - 用途：确认实时转写模型入口。
  - 核验日期：2026-07-30

## 9. 相关对象

- [[方向/AI语音/MOC - ASR|ASR]]：Whisper 是 ASR 方向的通用开源基线。
- [[方向/AI语音/选型/ASR 模型选型矩阵|ASR 模型选型矩阵]]：Whisper 与 Qwen3-ASR、FunASR、GPT-4o Transcribe、Seed-ASR 的工程选型对比。
- [[方向/AI语音/模型/Qwen3-ASR|Qwen3-ASR]]：中文/方言、本地专用 ASR 和 forced alignment 对比对象。
- [[方向/AI语音/模型/WavLM|WavLM]]：两者都可作为语音 encoder/表示路线参考，但 Whisper 更偏 ASR 端到端任务。
- [[方向/AI语音/知识/基础概念/Reverberation Modeling（混响建模）|混响建模]]：远场、混响、噪声会直接影响 Whisper 这类 ASR 的鲁棒性。

## 10. 待验证

- `whisper-1`、`gpt-4o-transcribe`、`gpt-4o-mini-transcribe` 在中文、方言、长音频和噪声场景里的当前差距。
- 本地 Whisper large-v3 / turbo 与云端 `whisper-1` 在同一测试集上的差异。
- faster-whisper / whisper.cpp / stable-ts 等生态工具的时间戳、吞吐和部署边界。
- large-v3 / turbo 在中文、方言测试集（Aishell、WenetSpeech 等）上的 CER 数字待核（论文附录 D 逐语言数据为图片，未直接入库）。
- 会议 / 播客 / 客服真实场景 WER（约 8%–12%、17.7%）来自第三方汇总，待统一小样本集复核。

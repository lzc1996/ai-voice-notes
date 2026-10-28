---
title: FunASR
类型: 工具
发表时间: 2023-05-18
时间依据: arXiv 首次提交日
任务:
  - ASR
开放状态:
  - paper
  - code
  - demo
aliases:
  - Fun-ASR
  - fun-asr
  - FunASR toolkit
  - Paraformer
tags:
  - 类型/对象
  - 方向/AI语音
  - 任务/ASR
---

# FunASR

## 0. 背景

**问题现场**：生产级中文语音识别（会议转写、电话质检、长音频批处理）需要把识别、VAD、标点、时间戳、热词、说话人分离组合成可部署的 pipeline，而非单一模型所能覆盖。

**FunASR 的切入点**：ModelScope / Alibaba 生态的工业级工具链，以 predictor 驱动非自回归的 Paraformer 为核心 ASR 模型，配套 FSMN-VAD、CT-Transformer 标点等组件，支持本地/私有化部署。

## 1. 身份

FunASR 是 ModelScope / Alibaba 生态里的工业级语音识别工具链，覆盖 ASR、VAD、标点恢复、时间戳、热词、说话人相关任务和多说话人识别。QwenCloud 文档里的 `fun-asr` / Fun-ASR 则更像云端模型/服务名，适合做批处理转写、热词和说话人分离场景。

边界：FunASR 不是单一模型名。它既包括开源 toolkit，也包括 Paraformer、FSMN-VAD、CT-Transformer punctuation、SenseVoice / Fun-ASR 系列等模型和服务入口。

## 2. 什么时候选 FunASR

- 会议转写：需要 VAD、说话人分离、标点、时间戳和段落后处理。
- 企业语音批处理：电话质检、客服录音、长音频文件转写。
- 中文工程链路：需要热词、术语和中文场景适配。
- 本地/私有化：想把 ASR、VAD、标点、diarization 组合成可部署 pipeline。

## 3. 不适合直接承担的任务

- 需要全模态理解：优先看 Qwen-Omni 或 VLM + ASR 字幕链路。
- 只要离线通用 baseline：[[方向/AI语音/模型/Whisper|Whisper]] 更简单。
- 需要 Qwen 专用中文方言/强制对齐路线：优先看 [[方向/AI语音/模型/Qwen3-ASR|Qwen3-ASR]] / Qwen3-ForcedAligner。

## 4. 工程组件

- **ASR**：Paraformer、SenseVoice、Fun-ASR 等识别模型。
- **[[方向/AI语音/知识/基础概念/VAD（Voice Activity Detection）|VAD]]**：FSMN-VAD，用于切分长音频和端点检测。
- **标点**：CT-Transformer punctuation，用于给 ASR 文本恢复标点。
- **时间戳**：字级或片段级时间戳，用于字幕、对齐和剪辑。
- **热词**：对领域词、姓名、产品名做识别偏置。
- **说话人相关**：speaker verification / diarization / multi-talker ASR，用于会议和电话场景。

## 5. 核心公式

FunASR 是工具链而非单一模型；其核心 ASR 模型 Paraformer 采用 predictor 驱动的非自回归架构，下面给出 CIF 机制与常用训练损失。

- Paraformer 的 CIF 集成（predictor 驱动的非自回归）：

$$\tilde{\mathbf{h}}_u = \frac{\sum_{t=a_u}^{b_u} \alpha_t \mathbf{h}_t}{\sum_{t=a_u}^{b_u} \alpha_t}, \qquad \sum_{t=a_u}^{b_u} \alpha_t \approx 1$$

说明：$\mathbf{h}_t$ 为声学编码器帧级输出，$\alpha_t \in [0,1]$ 由 predictor 逐帧预测；当累计和跨过整数值 $u$ 时，把区间 $[a_u, b_u]$ 内的帧加权集成成一个 token 级表示 $\tilde{\mathbf{h}}_u$，从而并行输出全部 token，无需自回归逐字生成。

- 训练损失（token 级交叉熵 + 辅助 CTC）：

$$\mathcal{L} = \mathcal{L}_{\mathrm{CE}} + \lambda \mathcal{L}_{\mathrm{CTC}}, \quad \mathcal{L}_{\mathrm{CE}} = -\sum_{u=1}^{U} \log P(\tilde{y}_u \mid \tilde{\mathbf{h}}_u)$$

说明：$\tilde{y}_u$ 为参考文本 token，$\lambda$ 为辅助权重；CTC 辅助损失帮助模型学习对齐。

- CTC 损失（SenseVoice / UniASR 等模型常用）：

$$\mathcal{L}_{\mathrm{CTC}} = -\log \sum_{\boldsymbol{\pi} \in \mathcal{B}^{-1}(\mathbf{y})} P(\boldsymbol{\pi} \mid X)$$

说明：$\boldsymbol{\pi}$ 为带空白/重复的对齐路径，$\mathcal{B}$ 为去重去空白的映射，$\mathbf{y}$ 为参考文本；对全部合法对齐路径求边缘化。

## 6. 测试基准与性能

**测试基准**

- 中文基准：Aishell1 / Aishell2（官方 benchmark 文档）、WenetSpeech（第三方整理）。
- 论文横评：AISHELL-1 / AISHELL-2，对比 Espnet、WeNet、K2、Blockformer。

**性能指标**（CER%，来源：FunASR 官方 benchmark 文档 benchmark_pipeline_cer.md）

| 模型 | Aishell1 test | Aishell2 test_ios |
| --- | --- | --- |
| Paraformer-large（离线） | 1.94 | 2.84 |
| Paraformer-large-long | 2.10 | 2.87 |
| Paraformer-large-contextual | 2.02 | 2.85 |
| Paraformer-large-online（流式） | 3.34 | 3.86 |
| Paraformer（标准） | 3.69 | 4.63 |

- 流式 vs 离线：online 变体 CER 约为离线版两倍（官方 benchmark 文档）。
- WenetSpeech（Paraformer-large，第三方整理）：dev 3.57、test_meeting 6.97、test_net 6.74（待核）。
- RTF：实时版 Paraformer 约 0.0093（约百倍实时）（第三方整理，待核）。
- SenseVoice / Fun-ASR 系列模型的 WER/CER 与 RTF 数字：待核。

## 7. 关键资源

- [FunASR README](https://github.com/modelscope/FunASR)
  - 内容定位：官方开源仓库，记录 ASR、VAD、标点、说话人分离、时间戳、热词和部署工具链。
  - 用途：本地部署、模型列表和工程入口。
  - 核验日期：2026-07-29
- [FunASR docs](https://modelscope.github.io/FunASR/)
  - 内容定位：官方文档站，说明统一 Python 接口和生产级 ASR / VAD / punctuation / diarization 等能力。
  - 用途：快速上手和接口查询。
  - 核验日期：2026-07-29
- [FunASR paper](https://arxiv.org/abs/2305.11013)
  - 内容定位：论文说明 Paraformer 时间戳、热词、FSMN-VAD 和 CT-Transformer punctuation 等组件。
  - 用途：引用 toolkit 设计和核心组件来源。
  - 核验日期：2026-07-29
- [QwenCloud Fun-ASR](https://www.qwencloud.com/models/fun-asr)
  - 内容定位：QwenCloud `fun-asr` 云端模型页，强调中文方言、热词、说话人分离等生产功能。
  - 用途：云端服务选型。
  - 核验日期：2026-07-29

## 8. 相关对象

- [[方向/AI语音/MOC - ASR|ASR]]：FunASR 是 ASR 工程链路的重要工具栈。
- [[方向/AI语音/知识/基础概念/VAD（Voice Activity Detection）|VAD]]：FunASR 的 FSMN-VAD 可做长音频切分和端点检测。
- [[方向/AI语音/选型/ASR 模型选型矩阵|ASR 模型选型矩阵]]：FunASR 与 Qwen3-ASR、Whisper、GPT-4o Transcribe 等路线对比。
- [[方向/AI语音/模型/Qwen3-ASR|Qwen3-ASR]]：专用 Qwen ASR 模型线，适合对比本地模型和云端能力边界。
- [[方向/AI语音/模型/Whisper|Whisper]]：通用离线 ASR baseline。
- [[方向/AI语音/评估/CER（Character Error Rate）|CER]]：中文 ASR 评估常用字符级错误率。

## 9. 待验证

- 开源 FunASR、QwenCloud `fun-asr`、FunAudioLLM/Fun-ASR-Nano 的模型边界和许可证差异。
- 说话人分离、热词、时间戳在长会议中文/方言场景里的真实稳定性。
- 与 Qwen3-ASR、Whisper、GPT-4o Transcribe 在同一 30 条小样本集上的 CER、延迟和后处理成本。
- SenseVoice / Fun-ASR 系列的 WER/CER 与 RTF 数字、WenetSpeech 表与 RTF 0.0093 的原始出处（当前来自第三方整理，待核）。



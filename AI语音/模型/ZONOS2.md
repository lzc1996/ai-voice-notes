---
title: ZONOS2
类型: 模型
参数量: 8B total / 900M active
发表时间: 2026-06-12
时间依据: Zyphra 发布页日期为 2026-06-12；arXiv 技术报告首次提交日为 2026-06-23
任务:
  - TTS
  - 声音克隆
团队:
  - Zyphra
开放状态:
  - paper
  - code
  - weights
  - demo
  - api
许可证:
  - Apache-2.0（arXiv / Hugging Face）
  - MIT（GitHub README，待核）
aliases:
  - Zonos 2
  - Zonos2
  - Zonos V2
  - ZONOS2 8B
  - "ZONOS2: Real-time TTS with High-Fidelity Voice Cloning"
tags:
  - 类型/对象
  - 方向/AI语音
  - 任务/TTS
  - 任务/声音克隆
---

# ZONOS2

## 0. 背景

**问题现场**：需要开源/开权重的实时 TTS，兼顾高保真 zero-shot 声音克隆、自然度、韵律与低延迟。

**前序路线的缺口**：前作 Zonos-v0.1 为 1.6B 规模、训练语料约 200K 小时，规模与数据覆盖有限。

**ZONOS2 的切入点**：扩展到 8B total / 900M active 的 sparse MoE decoder-only 架构，训练语料扩至 6M+ 小时，生成 RVQ / DAC audio tokens 解码到 44.1 kHz 波形。

## 1. 身份

`ZONOS2` 是 Zyphra 发布的开源 / 开权重实时 TTS 模型，主打高保真 zero-shot voice cloning、自然度、韵律和低延迟。它从 Zonos-v0.1 的 1.6B 规模扩展到 **8B total / 900M active** 的 sparse MoE 架构，并把训练语料从约 200K 小时扩展到 6M+ 小时。

边界：ZONOS2 是专用 [[方向/AI语音/MOC - TTS|TTS]] / voice cloning 模型，不是 ASR，也不是端到端语音 Agent。它适合比较“本地开权重声音克隆 TTS”和云端闭源 TTS 的质量、延迟、授权与安全边界。

## 2. 核心链路

```text
text
  -> NeMo text normalization / UTF-8 bytes
  -> speaker embedding（reference audio / ECAPA-TDNN）
  -> decoder-only MoE transformer
  -> RVQ / DAC audio tokens
  -> 44.1 kHz mono waveform
```

## 3. 核心信息

- **架构**：decoder-only Transformer + sparse MoE backbone；技术报告称它是开放 TTS 里的 MoE 架构探索。
- **音频表示**：输出 [[方向/AI语音/知识/基础概念/RVQ（残差向量量化）|RVQ]]-based audio codec tokens；官方 README 描述为生成 DAC tokens，再解码到 waveform。
- **语言支持**：Tier 1 为 English、Mandarin Chinese、Japanese；Tier 2/3 覆盖韩语、俄语、意大利语、法语、西语、越南语、德语、希伯来语、印地语、阿拉伯语等更多语言。
- **推理形态**：官方提供基于 Mini-SGLang 的本地 TTS server，默认 `http://localhost:1919`，并提供 OpenAI-compatible `/v1/audio/speech` endpoint。
- **控制项**：支持参考音频声音克隆、speaking rate / speed、quality buckets、accurate / expressive mode，以及 happy / sad / angry / surprised 等 emotion direction 控制。
- **平台限制**：官方本地高性能路径标注 Linux x86_64 + NVIDIA CUDA；另有 ggml 实现用于 CPU / 跨平台支持，需单独验证速度。

## 4. 核心公式

条件自回归音频 token 生成：

$$
p_\theta(\mathbf{a}|\mathbf{b},\mathbf{s},\mathbf{q}) = \prod_{t=1}^{T} p_\theta(a_t \mid a_{<t}, \mathbf{b}, \mathbf{s}, \mathbf{q})
$$

其中 $\mathbf{b}$ 是 normalized UTF-8 byte / text 条件，$\mathbf{s}$ 是参考音频提取的 speaker embedding，$\mathbf{q}$ 是语速、质量、情绪等控制条件，$\mathbf{a}$ 是 [[方向/AI语音/知识/基础概念/RVQ（残差向量量化）|RVQ]] / DAC audio token 序列。

## 5. 测试基准与性能

- 官方技术报告用 quality、speaker similarity、WER 和自建 `ZTTS1-Eval` 评估 ZONOS2，并称其在自然度、韵律和声音克隆 fidelity 上达到 SOTA / 竞争性表现。
- Zyphra 发布页还提到 `seed-tts eval` 与 `ZTTS1-Eval`，并强调 ZONOS2 在 speaker similarity 与 prosody 指标上表现突出。
- 公开摘要层面没有足够稳定的完整表格数字；本笔记先记录评测口径，具体 MOS / SIM / WER 表格等下一轮精读技术报告时补。

## 6. 使用注意

- **授权要核清**：arXiv / Hugging Face 标注 Apache-2.0，但 GitHub README 当前写 MIT；商用前按权重、代码、第三方组件分别复核。
- **实时不等于低成本**：8B total 虽只有 900M active，但本地高性能路径仍依赖 NVIDIA CUDA；CPU / ggml 路线要实测 RTF 和首包延迟。
- **声音克隆有安全边界**：参考音频授权、名人声音、情绪控制和滥用检测需要进入产品评估，不应只看 demo 听感。
- **OpenAI-compatible 只是接口兼容**：音色、语速、情绪、streaming PCM 和输出格式仍按 ZONOS2 server 的参数语义处理。

## 7. 关键来源

- [ZONOS2 Technical Report](https://arxiv.org/abs/2606.24320)
  - 内容定位：技术报告，记录 8B / 900M active MoE 架构、6M+ 小时训练语料、ZTTS1-Eval、权重与代码开放口径。
  - 用途：方法定义、训练规模、评测口径和开放状态依据。
  - 核验日期：2026-08-11
- [Zyphra/ZONOS2 - Hugging Face](https://huggingface.co/Zyphra/ZONOS2)
  - 内容定位：官方权重页，记录 Apache-2.0、语言分层、本地推理 server、44.1 kHz mono PCM 输出和 Python API。
  - 用途：权重下载、部署入口和许可证核对。
  - 核验日期：2026-08-11
- [Zyphra/ZONOS2 - GitHub](https://github.com/Zyphra/ZONOS2)
  - 内容定位：官方推理代码，记录 Mini-SGLang server、voice cloning、conditioning controls、emotion control 和 API 参数。
  - 用途：本地部署、接口参数和控制能力入口。
  - 核验日期：2026-08-11
- [ZONOS2 release page](https://www.zyphra.com/our-work/zonos2)
  - 内容定位：Zyphra 发布页，定位 ZONOS2 为实时 TTS / high-fidelity voice cloning，并说明 MoE、Zyphra Cloud、benchmark 与样例。
  - 用途：发布背景、产品定位和 demo 入口。
  - 核验日期：2026-08-11

## 8. 相关对象

- [[方向/AI语音/MOC - TTS]]：ZONOS2 属于专用 TTS / voice cloning 模型。
- [[方向/AI语音/模型/Qwen3-TTS]]、[[方向/AI语音/模型/Spark-TTS]]：同属开源 / 开权重 TTS 与声音克隆对比对象。
- [[方向/AI语音/知识/技术路线/语音生成 tokenizer codec 技术路线]]：ZONOS2 的 [[方向/AI语音/知识/基础概念/RVQ（残差向量量化）|RVQ]] / DAC token 路线属于 codec-token TTS。
- [[方向/AI语音/知识/基础概念/NAC（神经音频 Codec）]]、[[方向/AI语音/知识/基础概念/Vocoder（声码器）]]：音频 token 与 waveform 解码的底层表示入口。
- [[方向/AI语音/评估/可控 TTS 与声音克隆评估框架]]：用于评估声音克隆、情绪控制、长文本稳定性和安全边界。

## 9. 待验证

- arXiv / Hugging Face 的 Apache-2.0 与 GitHub README 的 MIT 表述如何分工：权重、推理代码、第三方组件分别是什么许可证。
- 官方技术报告完整表格中的 MOS、speaker similarity、WER、ZTTS1-Eval 和 streaming latency 数字。
- 本地目标机器上的首包延迟、RTF、显存占用、长文本稳定性和中文情绪控制效果。
- 与 Qwen3-TTS、Spark-TTS、CosyVoice、F5-TTS、ElevenLabs v3 在中文/英文 voice cloning 上的同口径对比。

---
title: GenSE
类型: 框架
发表时间: 2025-02-05
时间依据: arXiv 首次提交日；ICLR 2025 conference paper
任务:
  - 语音增强
相关主题:
  - 语音表示
  - 语音生成
  - 低幻觉
开放状态:
  - paper
  - code
  - demo
  - weights
代码状态: 官方 GitHub `yaoxunji/gen-se` 当前包含 `infer.py`、`components/`、`configs/`、`models/` 和推理命令；Hugging Face `yaoxunji/gen-se` 当前发布 SimCodec 与 N2S/S2S checkpoint。README 的 TODO 仍写着 release inference / pre-trained model，疑似未同步更新。
aliases:
  - "GenSE: Generative Speech Enhancement via Language Models using Hierarchical Modeling"
  - Generative Speech Enhancement via Language Models using Hierarchical Modeling
  - Generative Speech Enhancement
  - hierarchical LM-based speech enhancement
tags:
  - 类型/对象
  - 方向/AI语音
  - 任务/语音增强
  - 主题/语音表示
  - 主题/语音生成
---

# GenSE

## 0. 背景

- **早期明确的 LM 化 SE 框架**：继 [[方向/AI语音/模型/SELM|SELM]] 之后，把 semantic/acoustic token 分层和神经 codec 接口做得更系统。
- **连接增强与语音大模型**：相比只输出波形，GenSE 的 token 表示更容易和 SpeechLM / codec LM 生态衔接。
- **暴露核心风险**：低 SNR 下 LM 可能生成听起来干净但内容改变的语音，后续 [[方向/AI语音/模型/L3-SE|L3-SE]]、[[方向/AI语音/模型/DDSE|DDSE]]、PASE 等路线都在处理这一类 hallucination 问题。

## 1. 身份

`GenSE` 是 *Generative Speech Enhancement via Language Models using Hierarchical Modeling* 提出的 LM-based speech enhancement 框架。它把语音增强从连续信号回归改写成条件语言建模：先把语音拆成 semantic tokens 和 acoustic tokens，再用语言模型生成干净语音 token，最后解码回增强语音。

边界：GenSE 不是传统频谱掩码模型，也不是扩散 / Flow Matching 模型；它属于 [[方向/AI语音/知识/基础概念/SE（语音增强）导论|语音增强]] 的 codec/token LM 路线。和 [[方向/AI语音/模型/SELM|SELM]] 相比，GenSE 更明确区分 semantic token 与 acoustic token 的生成阶段；和 [[方向/AI语音/模型/UniSE（Unified Speech Enhancement）|UniSE]] 相比，GenSE 更偏单任务语音增强，不是统一 SR / TSE / SS 框架。

## 2. 核心链路

```text
noisy speech
  -> pretrained SSL model -> noisy semantic tokens
  -> custom single-quantizer neural codec -> noisy acoustic tokens
  -> LM stage 1: clean semantic token generation
  -> LM stage 2: clean acoustic token generation with token-chain prompting
  -> neural codec decoder
  -> enhanced waveform
```

## 3. 关键设计

- **语义 / 声学分层**：先生成 clean semantic tokens，再生成 clean acoustic tokens，降低一次性预测全部 token 的不稳定性。
- **SpeechLM 式建模**：把 SE 当成 conditional language modeling，而不是 waveform / spectrogram regression。
- **单量化器 codec**：用自设计 single-quantizer neural codec 产生 acoustic tokens，服务 LM 生成和 waveform 重建。
- **Token-chain prompting**：acoustic token 生成阶段利用 token chain prompt 维持 timbre consistency，缓解说话人/音色漂移。
- **语义信息注入**：目标是让增强前端与后端 SpeechLM / 音频大模型共享离散表示空间，走向“增强—理解一体化”。

## 4. 测试基准与性能

- 论文摘要报告：GenSE 在 benchmark datasets 上超过 state-of-the-art SE systems，重点提升 speech quality 与 generalization capability。
- 论文被 ICLR 2025 接收为 conference paper；项目 demo 页面提供对比音频。
- 具体 PESQ、STOI/ESTOI、DNSMOS、WER、speaker similarity、RTF 和 ablation 表格待全文精读补齐。

## 5. 使用注意

- **生成式增强要查内容保真**：不能只看 MOS / DNSMOS，需要一起看 WER、dWER、CAcc、SpeechBERTScore 或人工转写。
- **自回归两阶段有延迟成本**：semantic 和 acoustic 两阶段生成提升稳定性，但实时 Agent 前端要单独测 RTF 和首包。
- **codec 上限锁音质**：single-quantizer codec 的重建质量、token rate 和 speaker preservation 会限制最终听感。
- **单任务定位**：若目标是统一 SR / TSE / SS，更适合看 UniSE；若目标是低幻觉表示回归，更适合对比 UniPASE / L3-SE / PASE。
- **工程可测性**：相比 [[方向/AI语音/模型/SELM]]，GenSE 当前更适合作为可跑的生成式 SE baseline；先用官方 `infer.py` + Hugging Face checkpoint 跑小样本，再决定是否投入复现训练。

## 6. 关键来源

- [GenSE arXiv](https://arxiv.org/abs/2502.02942)
  - 内容定位：原始论文页面，记录 GenSE 的摘要、作者、arXiv 提交日期和 hierarchical modeling 机制。
  - 用途：模型身份、任务边界和方法摘要。
  - 核验日期：2026-08-11
- [GenSE ICLR 2025 paper](https://openreview.net/pdf?id=1p6xFLBU4J)
  - 内容定位：ICLR 2025 conference paper PDF，记录完整方法、图表、实验和 demo 链接。
  - 用途：后续精读公式、指标和消融。
  - 核验日期：2026-08-11
- [GenSE demo page](https://yaoxunji.github.io/gen-se)
  - 内容定位：公开音频 demo 页面。
  - 用途：主观听样例和对比 enhanced speech。
  - 核验日期：2026-08-11
- [GenSE GitHub](https://github.com/yaoxunji/gen-se)
  - 内容定位：官方实现仓库；当前包含 `components/`、`configs/`、`models/`、`infer.py` 和 `requirements.txt`，README 给出 speech enhancement 推理命令。
  - 用途：代码复现、推理入口和依赖确认。
  - 核验日期：2026-09-17
- [GenSE Hugging Face](https://huggingface.co/yaoxunji/gen-se/tree/main)
  - 内容定位：官方 checkpoint 发布页；当前文件约 14.5 GB，包含 `g_00100000`、`config.json`、`n2s_wavlm.ckpt`、`n2s_xlsr.ckpt`、`s2s_wavlm.ckpt`、`s2s_xlsr.ckpt`。
  - 用途：权重下载和版本边界确认。
  - 核验日期：2026-09-17

## 7. 相关对象

- [[方向/AI语音/模型/SELM]]：同属 discrete token + language model 的早期 SE 路线。
- [[方向/AI语音/模型/UniSE（Unified Speech Enhancement）]]：后续 decoder-only LM-based 统一语音增强框架。
- [[方向/AI语音/模型/DDSE]]：后续 disentangled neural codec LM，强调解耦表示、delay mode 和 DPO 降幻觉。
- [[方向/AI语音/模型/L3-SE]]：后续低幻觉 LM-based SE，强调 noise-invariant acoustic-semantic distillation。
- [[方向/AI语音/知识/基础概念/NAC（神经音频 Codec）]]：GenSE 的 acoustic token / decoder 依赖 neural codec 思路。
- [[方向/AI语音/知识/基础概念/SSL 编码器]]：GenSE 的 semantic token 来自预训练 self-supervised speech model。

## 8. 待验证

- GitHub README 的 TODO 是否只是未更新，还是推理 pipeline / 权重仍有未发布组件；以实际 `infer.py` 跑通为准。
- semantic tokenizer、single-quantizer codec 的具体 token rate、codebook size 和训练目标。
- benchmark 绝对指标、消融表、RTF / 参数量，以及 hierarchical modeling 相对 single-stage 的具体收益。
- 中文、低 SNR、强混响和远场会议里，GenSE 的内容幻觉是否明显高于 L3-SE / DDSE / UniPASE。

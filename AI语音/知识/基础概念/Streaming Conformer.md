---
title: Streaming Conformer
类型: 概念
发表时间:
时间依据: 架构族；非单一发表物
相关任务:
  - ASR
相关主题:
  - 模型架构
相关模型:
  - "[[方向/AI语音/模型/Emformer]]"
  - "[[方向/AI语音/模型/WavLM]]"
aliases:
  - Streaming Conformer
tags:
  - 类型/对象
  - 方向/AI语音
  - 任务/ASR
  - 主题/模型架构
---

# Streaming Conformer

## 1. 身份

Streaming Conformer 是把 Conformer ASR encoder 改造成低延迟流式识别组件的一类方法。它保留 Conformer 的“全局注意力 + 局部卷积”建模思路，但限制未来上下文，并通过 chunk、cache 或 causal / limited-context convolution 让模型能增量输出。

边界：这里记录的是“流式 Conformer 架构模式”，不是单个模型发布。它也不是完整会议转写系统；RNN-T / CTC decoder、VAD、分段、说话人分离、标点和热词仍是外部工程链路。

## 2. 核心信息

- 基础：Conformer 用 self-attention 捕捉全局交互，用卷积捕捉局部声学特征。
- 流式改造：限制 self-attention 的 right context，改用 causal / lower-right-context convolution，或把输入切成 chunk。
- 缓存目标：复用历史 chunk 的中间激活，避免 buffered streaming 里重叠窗口造成的重复计算。
- 关键权衡：right context 越多，准确率通常越好，但首包延迟和计算开销也会上升。
- 常见解码：CTC 和 RNN-T / Transducer 都可以接 Streaming Conformer encoder。

## 3. 什么时候选 Streaming Conformer

- 需要实时或近实时 ASR，不能等完整 utterance 结束。
- 希望比传统 RNN encoder 更强，同时比全上下文 Conformer 更可控延迟。
- 想做统一 streaming / non-streaming ASR，减少两套模型的训练和部署成本。

## 4. 不适合直接承担的任务

- **离线最高精度转写**：全上下文模型通常更简单，也可能更准。
- **完整会议系统**：仍需要 [[方向/AI语音/知识/基础概念/VAD（Voice Activity Detection）|VAD]]、diarization、标点、分段和术语修正。
- **高保真语音增强或生成**：Streaming Conformer 解决识别 encoder，不解决波形重建。

## 5. 关键资源

- [Conformer paper - arXiv](https://arxiv.org/abs/2005.08100)
  - 内容定位：Conformer 原始论文，说明卷积增强 Transformer 同时建模局部和全局依赖。
  - 用途：确认 Streaming Conformer 的基础架构来源。
  - 核验日期：2026-07-31
- [Dynamic Chunk Convolution for Unified Streaming and Non-Streaming Conformer ASR](https://arxiv.org/abs/2304.09325)
  - 内容定位：讨论 dynamic chunk attention、causal convolution 的流式退化问题，并提出 dynamic chunk convolution。
  - 用途：确认 chunk-wise / unified streaming Conformer 的具体改造问题。
  - 核验日期：2026-07-31
- [NVIDIA NeMo - Cache-aware Streaming Conformer](https://docs.nvidia.com/nemo-framework/user-guide/latest/nemotoolkit/asr/models.html#cache-aware-streaming-conformer)
  - 内容定位：工程文档；说明 cache-aware streaming Conformer、right-context 限制、causal convolution、chunk-aware look-ahead 和缓存复用。
  - 用途：确认可落地的训练 / 推理配置入口。
  - 核验日期：2026-07-31

## 6. 相关对象

- [[方向/AI语音/MOC - ASR|ASR]]：Streaming Conformer 是低延迟 ASR encoder 路线。
- [[方向/AI语音/知识/技术路线/语音网络结构与模块|语音网络结构与模块]]：它属于流式 Conformer / chunking / cache 模块组合。
- [[方向/AI语音/模型/Emformer|Emformer]]：相邻低延迟流式 ASR encoder 路线，也围绕长上下文和缓存权衡。
- [[方向/AI语音/模型/WavLM|WavLM]]：WavLM 若要稳定增量输出，通常要换成这类流式 encoder，而不是直接切块套用离线 SSL encoder。

## 7. 待验证

- NeMo FastConformer / Cache-aware Streaming Conformer 是否是当前本地实验最省事的 baseline。
- Streaming Conformer、Emformer、Zipformer、Paraformer streaming 在中文、噪声、远场和实时语音 Agent 场景里的差距。
- 目标链路应优先 CTC、RNN-T，还是 hybrid Transducer-CTC。

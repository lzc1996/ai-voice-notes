---
title: DDSE
类型: 模型
发表时间: 2026-07
时间依据: Speech Communication Volume 182, July 2026
任务:
  - 语音增强
相关主题:
  - 语音表示
  - 语音生成
  - 低幻觉
开放状态:
  - paper
  - demo
aliases:
  - "DDSE: Efficient Neural Codec Language Models for speech enhancement with disentangled representations"
  - Efficient Neural Codec Language Models for speech enhancement with disentangled representations
  - disentangled neural codec language model
  - delay-mode speech enhancement
tags:
  - 类型/对象
  - 方向/AI语音
  - 任务/语音增强
  - 主题/语音表示
  - 主题/低幻觉
---

# DDSE

## 0. 背景

- **不靠单纯堆大模型**：DDSE 的主张是 representation disentanglement + delay mode，而不是把 LM 规模无限放大。
- **正面处理幻觉**：LM-based SE 的失败模式是生成听起来像语音但内容变了；DDSE 用解耦表示和 DPO 同时压这个风险。
- **更接近可部署 codec LM**：delay mode 和小模型规模使它比纯离线 AR codec LM 更接近实时/流式语音增强需求。

## 1. 身份

`DDSE` 是 *Efficient Neural Codec Language Models for speech enhancement with disentangled representations* 提出的 **disentangled neural codec language model**。它把语音增强做成 codec token / language model 问题，但不直接把混在一起的音频 token 丢给 LM，而是先用多组件神经 codec 把输入拆成噪声、语音语义和语音声学三类表示，再由 delay-mode LM 生成干净语音 codes。

边界：DDSE 不是传统掩码增强，也不是扩散/Flow Matching 模型；它属于 [[方向/AI语音/知识/基础概念/SE（语音增强）导论|语音增强]] 里的 codec LM / 自回归 token 路线。和 [[方向/AI语音/模型/SELM|SELM]] 相比，它更强调 codec 表示解耦；和 [[方向/AI语音/模型/UniSE（Unified Speech Enhancement）|UniSE]] 相比，它更强调小模型、delay mode 和流式潜力。

## 2. 核心链路

```text
noisy speech waveform
  -> MDCodec encoder
  -> disentangled codes: noise / speech semantics / speech acoustics
  -> delay-mode multi-scale RQ-Transformer LM
  -> clean semantic + acoustic codes
  -> MDCodec decoder
  -> enhanced waveform
```

## 3. 关键设计

- **MDCodec**：multi-component disentangled neural audio codec，把量化表示拆成 noise features、speech semantic features、speech acoustic features。
- **Disentangled codec input**：LM 同时看环境噪声、语义和声学条件，避免一个 entangled token 同时承载所有因素。
- **Delay-mode AR generation**：在自回归生成中引入 delay mode，可条件于 noisy prompt 和已生成 speech，支持更长输入和潜在 streaming inference。
- **DPO 后训练**：用 Direct Preference Optimization 减轻 audio LM 的 hallucination / 错音素问题，论文还用 token-level entropy 分析其效果。
- **效率定位**：小模型参数量低于头部 LM-based SE 的 1/10，但在 DNS-1 等测试上达到可比质量。

## 4. 测试基准与性能

- ScienceDirect 摘要报告：DDSE 的 disentangled 版本相对 non-disentangled baseline，UTMOS 提升 24%，WER 降低 7.3%。
- 贡献摘要还报告：disentangled input 带来 24% speech quality、27% speaker similarity 提升，并降低 WER。
- DDSE / DDSE-L 在 DNS-1 test set 上达到与 state-of-the-art LM-based SE 可比的表现；DDSE small 的总参数量低于这些模型的 1/10。
- 具体 PESQ、DNSMOS、UTMOS、WER、SIM 绝对数值与模型参数量表待全文精读核对。

## 5. 使用注意

- **仍是生成式增强**：即使有 DPO，codec LM 仍需检查 WER / dWER / CAcc，不能只听 MOS 或看 UTMOS。
- **流式是潜力，不等于已硬实时**：delay mode 支持 potential streaming applications，但实际首包、RTF、chunk 边界伪影需本地复测。
- **解耦依赖 codec 训练**：MDCodec 的 noise / semantic / acoustic 分离质量会直接决定 LM 条件是否可靠。
- **与 UniSE 分工不同**：UniSE 强在统一 SR / TSE / SS 任务框架；DDSE 更像单任务 SE 的高效 codec-LM 设计。

## 6. 关键来源

- [DDSE: Efficient Neural Codec Language Models for speech enhancement with disentangled representations](https://www.sciencedirect.com/science/article/pii/S0167639326000762)
  - 内容定位：Speech Communication 2026 原始论文，提出 MDCodec、delay-mode LM、DPO 后训练，并报告 UTMOS / WER / 参数效率结果。
  - 用途：模型定义、架构、评测口径和指标来源。
  - 核验日期：2026-08-11
- [DDSE demo page](https://qinwen-hu.github.io/ddse-demo/)
  - 内容定位：论文公开 demo 页面。
  - 用途：主观听样例和快速确认项目入口。
  - 核验日期：2026-08-11

## 7. 相关对象

- [[方向/AI语音/模型/SELM]]：早期 discrete token + LM 语音增强框架，DDSE 是后续 codec-LM 路线。
- [[方向/AI语音/模型/UniSE（Unified Speech Enhancement）]]：统一多任务 decoder-only LM-based SE，对比 DDSE 的高效单任务 SE 定位。
- [[方向/AI语音/模型/L3-SE]]：同样关注 LM-based SE 的 linguistic hallucination，但用 noise-invariant acoustic-semantic distillation 解决条件可靠性。
- [[方向/AI语音/知识/基础概念/NAC（神经音频 Codec）]]：DDSE 的底层接口是 disentangled neural audio codec。
- [[方向/AI语音/知识/基础概念/SR（语音恢复）]]：DDSE 属于单人语音恢复 / 增强路线。

## 8. 待验证

- DDSE / DDSE-L / DPO 版本的参数量、RTF、streaming latency 和各测试集绝对指标。
- MDCodec 的具体码本结构、token rate、quantizer 层数和每类 code 的监督方式。
- DPO 偏好构造：用哪些指标判 winner / loser，是否混合内容保持、说话人保持和听感质量。
- 中文、远场会议、强混响和键盘声场景中，DDSE 是否比 UniSE / L3-SE 更低幻觉。

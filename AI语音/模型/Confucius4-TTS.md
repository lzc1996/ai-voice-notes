---
title: Confucius4-TTS
类型: 模型
发表时间: 2026-06-23
时间依据: 2026-06-23 网易有道发布并开源（多家媒体报道口径）；技术报告 arXiv v1 为 2026-08-12
任务:
  - TTS
开放状态:
  - paper
  - code
  - weights
aliases:
  - Confucius4
  - 子曰4.0
  - 子曰 TTS
tags:
  - 类型/对象
  - 方向/AI语音
  - 任务/TTS
---

# Confucius4-TTS

## 0. 背景

**问题现场**：zero-shot 声音克隆通常需要参考音频的转录文本，但 in-the-wild 参考音频往往没有转录，这是部署痛点。

**Confucius4-TTS 的切入点**：免参考文本的语内与跨语言克隆——音色条件全部来自可学习 speaker encoder 对参考音频 SSL 特征的编码，不依赖提示转录做对齐。

## 1. 身份

Confucius4-TTS（子曰 4.0）是网易有道 2026 年开源的**多语言、跨语言 zero-shot TTS 系统**：支持 14 种语言，主打「免参考文本」的语内与跨语言声音克隆——推理时不需要参考音频的转录文本，解决了 in-the-wild 参考音频往往没有转录的部署痛点；有转录时也支持 continuation cloning 模式。

与 [[方向/AI语音/模型/AuK|AuK]] 同属免转录路线且几乎同期：Confucius4-TTS 专注跨语言克隆质量（媒体宣传点为「无口音迁移」),AuK 则把免转录接口扩展到编辑/增强/分离的统一基座。

## 2. 核心信息

- **任务面**:14 语言 zero-shot TTS；语内 + 跨语言克隆；约 3 秒参考音频即可克隆（发布口径）。
- **两阶段架构**:T2S（GPT 式 LLM 主干，**可学习 speaker encoder** 从自监督语音表示中提取音色特征）+ S2A（conditional flow-matching，把语义 token 转成 mel 频谱）,再经声码器出波形。
- **免转录机制**：音色条件全部来自 speaker encoder 对参考音频的编码，不依赖提示转录做对齐；同一模型在有转录时可切换 continuation cloning。
- **开放状态**：代码、权重、demo 全量开源，**Apache 2.0，商用无限制**；官方仓库 netease-youdao/Confucius4-TTS。
- **技术致谢**（仓库 README 口径）：语义编解码参考 Amphion / [[方向/AI语音/模型/MaskGCT|MaskGCT]]，语义特征用 w2v-BERT 2.0,speaker encoder 与文本投影结构参考 [[方向/AI语音/模型/Qwen3-TTS|Qwen3-TTS]]，文本归一化参考 [[方向/AI语音/模型/CosyVoice|CosyVoice]],flow matching 参考 Seed-VC，声码器用 BigVGAN。

## 3. 核心机制

```text
参考音频(无需转录)
  -> SSL 特征(w2v-BERT 2.0)-> 可学习 speaker encoder -> 音色条件
目标文本 -> T2S(LLM,条件 = 音色条件)-> 语义 token
  -> S2A(conditional flow matching)-> mel 频谱
  -> BigVGAN -> waveform
```

设 $x$ 为目标文本 token 序列，$c_{spk}$ 为 speaker encoder 从参考音频提取的连续音色向量，$y$ 为 T2S 生成的语义 token 序列，$m$ 为 S2A 生成的 mel 频谱，$G_{\mathrm{T2S}}$ 和 $G_{\mathrm{S2A}}$ 分别表示两阶段生成器：

$$
y=G_{\mathrm{T2S}}(x,c_{spk}),\qquad
m=G_{\mathrm{S2A}}(y,c_{spk}),\qquad
\hat{a}=G_{\mathrm{BigVGAN}}(m)
$$

第一阶段生成离散语义 token，第二阶段在该序列和音色条件下生成连续 mel 频谱，最后由 BigVGAN 将频谱解码为波形。

## 4. 测试基准与性能

官方自报口径：

- **CV3-Eval 跨语言基准**：六个语言方向平均 [[方向/AI语音/评估/WER（词错误率）|WER]] **3.73%**。
- **内部跨语言测试集人评**:在近期开源与商用系统中取得最佳平均总排名（论文摘要表述，内部集未公开）。

## 5. 边界

- 不支持流式输出，不支持文本情绪控制（早期用户实测反馈口径）。
- 14 语言之外的覆盖未说明；内部人评基准未公开，横向可比性有限。
- 「无口音」为发布宣传口径，论文中的定量证据是 WER 与人评排名，未直接给口音度量的客观指标。

## 6. 相关对象

- [[方向/AI语音/MOC - TTS]]：任务入口。
- [[方向/AI语音/模型/AuK]]：同期免转录路线的统一基座对照。
- [[方向/AI语音/模型/MaskGCT]] / [[方向/AI语音/模型/XTTS-v2]]：免转录克隆路线的先行者，本仓库语义 codec 部分致谢 Amphion/MaskGCT。
- [[方向/AI语音/模型/Qwen3-TTS]] / [[方向/AI语音/模型/CosyVoice]]：speaker encoder 结构与文本归一化的参考来源。
- [[方向/AI语音/知识/基础概念/Zero-shot Voice Cloning（零样本声音克隆）]]：任务概念入口。
- [[方向/AI语音/知识/基础概念/Flow Matching（流匹配）]]:S2A 模块的生成范式。

## 7. 关键来源

- [Confucius4-TTS: Transcript-Free Cross-Lingual Zero-Shot TTS with a Learnable Speaker Encoder（arXiv:2608.11650）](https://arxiv.org/abs/2608.11650)
  - 内容定位：技术报告；定义两阶段架构、免转录动机、CV3-Eval 3.73% 平均 WER 与内部人评结果。
  - 用途：架构与评测数字的一手出处。
  - 发表日期：2026-08-12（arXiv v1）
  - 核验日期：2026-09-15
- [netease-youdao/Confucius4-TTS（GitHub）](https://github.com/netease-youdao/Confucius4-TTS)
  - 内容定位：官方代码、权重、demo 与致谢列表（对 MaskGCT/Qwen3-TTS/CosyVoice/Seed-VC/BigVGAN 的技术继承关系）。
  - 用途：确认开放状态、Apache 2.0 许可与技术来源。
  - 核验日期：2026-09-15
- [网易有道发布 TTS 语音合成引擎 Confucius4-TTS（IT之家）](https://www.ithome.com/0/967/636.htm)
  - 内容定位：发布报道；14 语言、3 秒克隆、本地离线部署、商用无限制等发布口径。
  - 用途：发布日期与产品化口径；宣传性表述需与论文区分。
  - 核验日期：2026-09-15

## 8. 待验证

- 发布日期（2026-06-23，媒体口径）与 arXiv v1（2026-08-12）之间的版本对应关系。
- 「14 语言」的具体语种清单。
- 内部跨语言人评基准的构成与第三方复测。

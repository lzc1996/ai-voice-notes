---
title: LongCat-Next
类型: 模型
参数量: A3B；68.5B 总参数 / 3B 激活参数（LongCat-Flash-Lite 基座口径）；HF 权重页显示 74B params
发表时间: 2026-03-29
时间依据: arXiv v1 首次提交日
任务:
  - 多模态理解
  - 图像生成
  - 音频理解
  - 低延迟语音交互
  - 语音克隆
开放状态:
  - paper
  - code
  - weights
  - demo
aliases:
  - LongCat Next
  - LongCatNext
  - Meituan LongCat-Next
  - 美团 LongCat-Next
tags:
  - 类型/对象
  - 方向/AI语音
  - 领域/大模型
  - 主题/多模态
  - 任务/实时语音交互
---

# LongCat-Next

## 0. 背景

**问题现场**：多模态模型通常为各模态外接专用模块或路径，理解与生成难以在同一框架内统一。

**LongCat-Next 的切入点**：DiNA（Discrete Native Autoregressive）——把文本、视觉、音频统一"词汇化"为离散 token（dNaViT + SAE + RVQ，Whisper encoder + RVQ），由同一个 decoder-only MoE 做 next-token prediction，模态差异留在 tokenizer/detokenizer 两端。

## 1. 内容定位

LongCat-Next 是美团 LongCat 团队发布的原生多模态模型，把文本、视觉和音频统一到同一个离散自回归建模框架里。它更适合作为「原生离散多模态 / Omni」路线对象跟踪：重点不只是接入语音或图像模块，而是用 DiNA 把多模态信号统一成可预测的离散 token。

边界：它不是纯 ASR、纯 TTS、纯 VLM，也不是 ASR/TTS cascade；在本库中放到音频大模型线，是因为它同时覆盖音频理解、低延迟语音对话和语音克隆，并可与 Qwen / MiniCPM / Moshi 等 Omni 语音路线对照。

## 2. 核心信息

- **DiNA 架构**：Discrete Native Autoregressive，把 next-token prediction 扩展到文本、视觉、音频共享的离散 token 空间。
- **基座 / 参数口径**：使用 LongCat-Flash-Lite MoE；论文与技术博客口径为 A3B、68.5B 总参数 / 3B 激活参数，Hugging Face 权重页显示 74B params，后者可能包含多模态组件与权重文件统计差异。
- **视觉 tokenizer**：dNaViT 支持任意分辨率视觉 tokenization / detokenization；结合 SAE 与 8 层 RVQ，官方称达到 28x 视觉压缩。
- **能力范围**：覆盖视觉理解、图像生成、音频问答、speech synthesis、audio-to-audio 与 tool calling 示例。
- **工程门槛**：Transformers 本地示例建议至少 3 张 80GB GPU；基础 SGLang 适配在独立 inference repo 中维护。
- **评测口径**：公开 benchmark 目前以官方报告为主；跨 Qwen3-Omni、Qwen3-VL、专用 ASR/TTS 的结论需要第三方复测。

## 3. 核心机制

### 3.1. 输入到输出流水线

```text
视觉理解 / 生成：图像 I -> SAE 提取语义完整特征 z_p -> 8 层 RVQ 量化为层次视觉 token z -> 多层 token embedding 加和 -> LongCat-Flash-Lite MoE / DiNA 自回归预测 -> 文本答案，或 DepthTransformer 解出多层视觉 token -> dNaViT pixel decoder + flow refiner -> 图像输出。

音频理解：音频波形 x -> Whisper encoder 提取语义与副语言特征 -> 4x downsample -> 8 层 RVQ 量化为 12.5 Hz 音频 token -> 统一多模态 embedding -> decoder-only MoE -> text head 输出转写 / 问答 / 理解结果。

语音生成 / audio-to-audio：文本或音频上下文 -> AS / AE / TE 段标记对齐文本与音频段 -> DiNA 以 parallel 或 serial text-guided audio 策略预测音频 token -> 对称 decoder 重建 coarse Mel -> flow-matching refiner -> vocoder -> 输出语音波形。
```

LongCat-Next 的机制核心是把图像、语音、文本都先「词汇化」为离散 ID，再让同一个 decoder-only MoE 做 next-token prediction；模态差异主要留在 tokenizer / detokenizer 两端，而不是在主干里分出多套专用路径。

### 3.2. 核心公式

视觉 tokenizer 的目标是让离散表示 $z$ 对任务回答近似保留原图信息：

$$
\mathcal{P}(A\mid z,\mathcal{Q})\approx\mathcal{P}(A\mid I,\mathcal{Q})
$$

SAE 先给出预量化表示：

$$
\mathbf{z}_{p}=\mathcal{E}_{\text{sae}}(I)
$$

RVQ 将连续特征分解为多层残差 code：

$$
\mathbf{r}_{0}=f_{\text{proj}}(\mathbf{z}),\quad
\hat{\mathbf{q}}_{l}=\operatorname{VQ}(\mathbf{r}_{l-1}),\quad
\mathbf{r}_{l}=\mathbf{r}_{l-1}-\hat{\mathbf{q}}_{l},\quad
\hat{\mathbf{z}}=\sum_{l=1}^{L}\hat{\mathbf{q}}_{l}
$$

视觉量化目标：

$$
\mathcal{L}_{\text{quant}}=\lambda_{c}\mathcal{L}_{\text{commit}}+\lambda_{s}\mathcal{L}_{\text{semantic}}
$$

视觉 detokenizer 目标：

$$
\mathcal{L}_{\text{dec}}=\lambda_{1}\mathcal{L}_{\text{pixel}}+\lambda_{2}\mathcal{L}_{\text{percep}}+\lambda_{3}\mathcal{L}_{\text{align}}
$$

音频 tokenizer 目标：

$$
\mathcal{L}_{\text{audio}}=\lambda_{1}\mathcal{L}_{\text{recon}}+\lambda_{2}\mathcal{L}_{\text{commit}}+\lambda_{3}\mathcal{L}_{\text{llm}}
$$

DiNA 主干可按统一 token 序列的自回归口径理解：

$$
p_{\theta}(x_{1:T})=\prod_{t=1}^{T}p_{\theta}(x_{t}\mid x_{<t})
$$

### 3.3. 机制要点

- **统一发生在 token 层**：视觉和音频都变成离散 token，主干不再把非文本模态当作外接连续特征。
- **理解 / 生成共用表征**：SAE + RVQ 强调语义完整性，避免只为重建或只为识别优化。
- **多层 token 高效解码**：输入侧多层 embedding 加和，输出侧用 DepthTransformer 并行恢复多层 token。
- **语音生成有文本内引导**：parallel 策略偏低延迟，serial 策略偏语言质量；随机 delay 训练让模型适配不同对齐延迟。

## 4. 使用判断

- 看**原生多模态架构**：重点关注 DiNA 能否把理解与生成统一为同一套 token prediction，而不是单独调优各模态 adapter。
- 看**音频 Agent**：可作为端到端语音交互候选，但实时打断、首包延迟、ASR 可控性和音色一致性仍要本地复测。
- 看**文档视觉 / OCR**：dNaViT 任意分辨率与密集文本能力值得和 [[方向/大模型/VLM/Qwen3-VL]] 对照。
- 看**自部署成本**：A3B 激活规模不等于轻量端侧模型；显存、SGLang 适配和 tokenizer/decoder 依赖是主要工程成本。

## 5. 相关对象

- [[方向/AI语音/MOC - 音频大模型]]：本页归属的方向地图。
- [[方向/AI语音/模型/Qwen3-Omni]] / [[Qwen2.5-Omni]]：端到端全模态 Omni 路线对照。
- [[方向/AI语音/模型/MiniCPM-o]]：端侧全模态实时交互对照。
- [[方向/AI语音/模型/Moshi]]：codec token 与单模型全双工路线对照。
- [[方向/大模型/VLM/Qwen3-VL]]：文档视觉理解与 OmniDocBench 官方对照对象。

## 6. 来源

- [LongCat-Next: Lexicalizing Modalities as Discrete Tokens（arXiv:2603.27538）](https://arxiv.org/abs/2603.27538)
  - 内容定位：技术报告入口，记录 DiNA、dNaViT、文本/视觉/音频统一自回归建模与开源状态。
  - 用途：确认发表时间、论文标题、模型定位和官方 GitHub 入口。
  - 核验日期：2026-09-01
- [meituan-longcat/LongCat-Next（GitHub）](https://github.com/meituan-longcat/LongCat-Next)
  - 内容定位：官方代码仓库与 README，包含模型介绍、关键特性、quick start、推理示例和技术报告 PDF。
  - 用途：确认 DiNA / dNaViT / SAE+RVQ、A3B 口径、任务示例与本地运行门槛。
  - 核验日期：2026-09-01
- [meituan-longcat/LongCat-Next（Hugging Face）](https://huggingface.co/meituan-longcat/LongCat-Next)
  - 内容定位：官方权重页，标注 Any-to-Any、Transformers、multimodal、custom_code、MIT license、74B params 与 arXiv 编号。
  - 用途：确认权重、许可证、模型卡、参数统计口径与 Transformers 加载入口。
  - 核验日期：2026-09-01
- [美团技术团队：美团发布原生多模态 LongCat-Next](https://tech.meituan.com/2026/04/02/LongCat-Next.html)
  - 内容定位：官方中文技术博客，解释 DiNA、dNaViT、SAE、RVQ、68.5B/3B MoE 口径与音频能力。
  - 用途：中文概念定位、参数口径和 benchmark 声明的出处。
  - 核验日期：2026-09-01
- [meituan-longcat/LongCat-Next-inference（GitHub）](https://github.com/meituan-longcat/LongCat-Next-inference)
  - 内容定位：官方推理测试框架，覆盖 image understanding、image generation、audio-to-text、speech synthesis、audio-to-audio。
  - 用途：确认自部署任务形态和 SGLang / Omni-Flow 相关工程入口。
  - 核验日期：2026-09-01

## 7. 待验证

- LongCat-Next 在中文长音频、实时对话打断、voice clone 一致性上的本地效果。
- 官方 OmniDocBench / MMAU / TUT2017 / SeedTTS WER 等指标的第三方复测口径。
- LongCat-Flash-Lite、LongCat-Flash-Omni、LongCat-Next 三者是否需要拆出单独的 LongCat 模型家族页。

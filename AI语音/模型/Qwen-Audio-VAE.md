---
title: Qwen-Audio-VAE
类型: 模型
发表时间: 2026-07-13
时间依据: arXiv 首次提交日
任务:
  - 音频生成
开放状态:
  - paper
aliases:
  - Qwen Audio VAE
  - Qwen-Audio-VAE Technical Report
tags:
  - 类型/对象
  - 领域/AI语音
  - 主题/音频生成
---

# Qwen-Audio-VAE

## 0. 背景

**问题现场**：通用音频生成（text-to-audio、音乐、音效、语音编辑）需要一个高保真重建、低码率、快速编码的音频表示底座，而不只覆盖人声。

**Qwen-Audio-VAE 的切入点**：走连续 audio latent / VAE 路线（12.5 Hz、128 维），把 speech、music、sound 压成紧凑连续 latent，作为 Qwen 通用音频生成的底层模块。

## 1. 内容定位

Qwen-Audio-VAE 是 Qwen 语音/音频路线里偏底层的音频表示模型，不是 ASR，也不是直接面向用户的 TTS。它的价值在于把 speech、music、sound 压成紧凑连续 latent，为后续 text-to-audio、音乐、音效和语音编辑提供生成底座。

## 2. 核心信息

- 表示路线：连续 audio latent / VAE，而不是离散 speech token。
- 目标：高保真重建、低码率、快速编码、支持通用音频生成。
- 领域：speech、music、sound，而不只覆盖人声。
- 与 Qwen3-TTS 的关系：`Qwen3-TTS-Tokenizer-12Hz` 更偏低延迟 TTS 的离散 token；`Qwen-Audio-VAE` 更偏通用音频生成底层表示。

## 3. 核心公式

$$\log p_\theta(x) \ge \mathbb{E}_{q_\phi(z|x)}\big[\log p_\theta(x|z)\big] - D_{\mathrm{KL}}\big(q_\phi(z|x) \,\|\, p(z)\big)$$

- VAE 下界（ELBO）：$x$ 为输入音频（speech / music / sound），$q_\phi(z|x)$ 为编码器，$p_\theta(x|z)$ 为解码器，$z$ 为紧凑连续 latent，$p(z)$ 为先验（如标准正态）；最大化 ELBO 等价于重建误差加 latent 正则最小化。

$$\mathcal{L}_{\mathrm{VAE}} = \mathbb{E}\big[\|x - \hat{x}\|_1 + \lambda\, \mathcal{L}_{\mathrm{feat}}(x, \hat{x})\big] + \beta\, D_{\mathrm{KL}}\big(q_\phi(z|x) \,\|\, p(z)\big)$$

- 训练目标（β-VAE 形式）：时域 L1 加频谱/感知特征损失 $\mathcal{L}_{\mathrm{feat}}$ 负责重建，$\beta$ 权衡 latent 正则强度；$\beta$ 越大 latent 码率越低、重建越粗糙，是高保真与低码率之间的核心旋钮。

$$\mathrm{cr} = \frac{f_s \times C \times b}{f_{\mathrm{lat}} \times D_{\mathrm{lat}}}$$

- 压缩比：分子为输入音频比特率（$f_s$ 采样率、$C$ 声道数、$b$ 每采样比特），分母为 latent 比特率（$f_{\mathrm{lat}}$ 帧率、$D_{\mathrm{lat}}$ 维度）；latent 码率直接决定下游生成模型的上下文长度、训练成本与推理速度。

## 4. 测试基准与性能

**测试基准**：公共 speech / music / sound 基准上的重建质量（PESQ / STOI / VISQOL / MOS）+ latent 码率（帧率 × 维度）；训练规模 500 万小时多域音频。以下数字出自 Qwen-Audio-VAE Technical Report（arXiv 2607.11738）。

**性能指标**：

| 项 | 数值 |
|---|---|
| latent 帧率 / 维度 | 12.5 Hz / D=128 维连续 latent |
| 输入 | 24 kHz 单声道（编码器 480× 下采样） |
| 编码速度 | 32 分钟音频约 541 ms |
| 编码延迟优化 | 3.6×（非对称编解码器 + 延迟感知剪枝） |
| 训练数据 | 500 万小时多域音频 |

- 重建质量（PESQ / STOI / VISQOL / MOS）与 latent bitrate 具体数值：待核（摘要页无分数，需技术报告正文表格）。

## 5. 为什么值得单独跟踪

- 它可能是 Qwen 从 TTS 扩展到 general audio generation 的底层模块。
- 它决定后续音频生成模型的上下文长度、训练成本和推理速度。
- 它能连接 TTS、音效、音乐、声音编辑，而不是只服务语音播报。

## 6. 评估问题

- 重建质量：语音、音乐、环境声是否都稳定。
- 压缩率：latent 帧率、码率、上下文长度收益。
- 生成友好性：latent 是否适合扩散/flow/AR 模型建模。
- 速度：编码和解码是否足够快，能否用于实时或准实时链路。
- 可控性：是否保留音色、韵律、音乐结构和非语音细节。

## 7. 相关对象

- [[方向/AI语音/知识/技术路线/语音生成 tokenizer codec 技术路线|语音生成 tokenizer codec 技术路线]]：Qwen-Audio-VAE 与 12Hz tokenizer 的路线差异。
- [[方向/AI语音/模型/Qwen3-TTS|Qwen3-TTS]]：专用 TTS 分支。
- [[方向/AI语音/选型/Qwen 语音模型技术路线图|Qwen 语音模型技术路线图]]：总路线图。
- [[方向/AI语音/选型/Qwen 语音模型发展脉络|Qwen 语音模型发展脉络]]：Qwen 语音模型时间线。

## 8. 来源

- [Qwen-Audio-VAE Technical Report](https://arxiv.org/abs/2607.11738)
  - 内容定位：Qwen-Audio-VAE 技术报告，记录低码率连续 audio latent、快速编码和面向通用音频生成的设计目标。
  - 用途：定位 Qwen-Audio-VAE 在 Qwen 语音/音频生成路线里的角色。
  - 核验日期：2026-07-24

## 9. 待验证

- 重建质量指标（PESQ / STOI / VISQOL / MOS）与 latent bitrate 的具体数值（技术报告正文表格）。
- 与 DAC / EnCodec / Qwen3-TTS 12Hz tokenizer 在同基准上的对比。


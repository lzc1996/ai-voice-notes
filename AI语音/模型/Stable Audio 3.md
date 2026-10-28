---
title: Stable Audio 3
类型: 模型家族
参数量: small diffusion transformer 459M；medium 1.4B；large 2.7B；SAME-S 108M；SAME-L 852M
发表时间: 2026-05
时间依据: arXiv 编号 2605
任务:
  - 音频生成
开放状态:
  - paper
  - code
aliases:
  - Fast Latent Diffusion Models for Variable-Length Audio Generation and Editing
  - Stability AI Stable Audio 3
tags:
  - 类型/对象
  - 方向/AI语音
  - 任务/音频生成
---

# Stable Audio 3

## 0. 背景

**问题现场**：音频生成需要支持变长生成与 inpainting 编辑，固定最大长度会导致短音频计算浪费且生成慢。

**Stable Audio 3 的切入点**：高压缩 SAME 自编码器（约 4096×）+ DiT 改造的 flow matching 扩散 Transformer，线性插值路径原生支持变长，推理仅 8 步 ping-pong 采样。

## 1. 身份

Stable Audio 3 是 Stability AI 的通用音频生成和编辑**模型家族**，全名是 *Stable Audio 3: Fast Latent Diffusion Models for Variable-Length Audio Generation and Editing*。它面向音乐和音效生成，不是 ASR、TTS 或语音增强主线。

层级定位：这是通用音频生成对象，放在 AI 语音模型目录中是为了记录底层音频表示、latent diffusion、flow matching 和音频编辑能力，避免和 [[方向/AI语音/MOC - TTS|TTS]] 主线混在一起。

## 2. 用途

- 作为变长音频生成和 inpainting 编辑的前沿参考。
- 观察高压缩音频 latent、DiT / flow matching 和高速采样如何组合。
- 和 [[方向/AI语音/模型/Qwen-Audio-VAE|Qwen-Audio-VAE]]、[[方向/AI语音/知识/技术路线/语音生成 tokenizer codec 技术路线|语音生成 tokenizer codec 技术路线]] 对照，判断连续 latent 与 codec token 路线差异。
- 作为通用音频生成相邻方向，不作为 TTS、ASR 或语音增强基线。

## 3. 核心信息

| 模型 | 最大长度 | 扩散 Transformer 参数量 | 自编码器 | 用途 |
|---|---:|---:|---|---|
| small-music | 2m | 459M | SAME-S (108M) | 器乐 |
| small-sfx | 2m | 459M | SAME-S | 音效 |
| medium | 6m 20s | 1.4B | SAME-L (852M) | 音乐 + 音效 |
| large | 6m 20s | 2.7B | SAME-L | 音乐 + 音效，权重未开源 |

- 使用语义-声学自编码器 SAME，把 44.1kHz 立体声音频压缩到约 10.76Hz、256 维 latent 序列，总压缩比约 4096x。
- 扩散 Transformer 基于 DiT 改造，medium / large 使用 differential attention，并加入 memory embeddings 和局部加法条件以支持 inpainting。
- 训练流程包括 flow matching 预训练、蒸馏 warmup、对抗后训练。
- 推理采用 8 步 ping-pong 采样，在速度和质量之间折中。
- 原生支持变长生成，避免固定最大长度导致短音频计算浪费。

## 4. 核心公式

$$\mathcal{L}_{\mathrm{CFM}} = \mathbb{E}_{t,\,x_0,\,x_1}\left[\|v_\theta(x_t, t) - u_t\|^2\right]$$

- 流匹配预训练：$x_t$ 为噪声 $x_0$ 与真实 latent $x_1$ 之间的插值点，$u_t = \mathrm{d}x_t/\mathrm{d}t$ 为对应速度场，$v_\theta$ 为扩散 Transformer 预测的速度；条件包含文本/音效标签，inpainting 经 memory embeddings 与局部加法条件实现。

$$x_t = (1-t)\,x_0 + t\,x_1, \qquad t \in [0, 1]$$

- 线性插值路径：训练时在 $t$ 上均匀采样，天然支持变长生成；推理用 8 步 ping-pong 采样在速度与质量间折中。

$$\mathrm{cr} = \frac{f_s \times C}{f_{\mathrm{lat}}} = \frac{44100 \times 2}{10.76} \approx 4096\times$$

- SAME 自编码器压缩比：$f_s = 44.1$ kHz 采样率、$C = 2$ 声道、$f_{\mathrm{lat}} = 10.76$ Hz latent 帧率；约 10.76 Hz、256 维连续 latent 承载 44.1 kHz 立体声音频。

$$\mathcal{L}_{\mathrm{GAN}} = \mathbb{E}_{x}\left[\log D(x)\right] + \mathbb{E}_{\hat{x}}\left[\log(1 - D(\hat{x}))\right]$$

- 对抗后训练：$D$ 为判别器，$\hat{x}$ 为解码器重建的音频；对抗目标叠加在流匹配预训练与蒸馏 warmup 之后，提升重建的感知质量。

## 5. 测试基准与性能

**测试基准**：音乐/音效生成用 FAD（Fréchet Audio Distance）、CLAP 对齐分及人工评估（官方技术报告 arXiv 2605.17991，具体基准名与分数待核）；速度以官方 README 的 H200 / TensorRT / Mac 推理计时为准。

**性能指标**（生成耗时，官方 GitHub README）：

| 模型 | 5s 音频（H200 / H200+TensorRT / Mac CPU） | 120s 音频（H200） | 峰值显存（H200） |
|---|---|---|---|
| small（433M） | 0.41 s / 0.017 s / 0.70 s | 0.45 s | 1.69 GB |
| medium（1.4B） | 0.60 s / 0.02 s | 0.78 s | 5.07 GB |

- medium 生成 380s 音频仅 1.31 s（H200），远快于实时；chunked 解码 medium@120s 显存 6.49 → 5.14 GB（官方 README）。
- 官方摘要：H200 上 <2 秒生成音乐/音效，MacBook Pro M4 上数秒内（arXiv 摘要）。
- 压缩比与采样步数（4096×、8 步 ping-pong）见「核心信息 / 核心公式」，此处不重复。
- FAD / CLAP 等质量基准分数：待核（技术报告正文未抓到）。

## 6. 边界

- 不解决语音识别、说话人分离、文本转语音或语音增强任务。
- 主要价值在音频生成底层技术，而不是语音产品链路。
- 如果后续建立“通用音频生成”方向，它应迁到该方向下，而不是继续挂在 ASR/TTS MOC。

## 7. 关键资源

- [stable-audio-tools](https://github.com/Stability-AI/stable-audio-tools)
  - 内容定位：Stable Audio 工具和代码入口。
  - 用途：本地推理、训练和编辑流程参考。
  - 来源：`papers-summary/STABLE AUDIO 3.md`
- [stable-audio-3](http://github.com/Stability-AI/stable-audio-3)
  - 内容定位：Stable Audio 3 模型和权重入口。
  - 用途：确认模型家族、权重开放范围和复现方式。
  - 来源：`papers-summary/STABLE AUDIO 3.md`

## 8. 待验证

- FAD / CLAP 等质量基准及分数（技术报告 arXiv 2605.17991 正文，未抓到）。

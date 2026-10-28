---
title: NSNet2
类型: 模型
发表时间: "2020"
时间依据: Microsoft Research paper arXiv v2 2020-09-24；后续 DNS / real-time model papers 延续 NSNet2 命名
任务:
  - 单通道语音增强
  - 实时降噪
  - Deep Noise Suppression
相关评估:
  - DNS Challenge
  - PESQ
  - STOI
  - SI-SDR
开放状态: []
aliases:
  - NSNet 2
  - Noise Suppression Network 2
  - NSNet2 baseline
tags:
  - 类型/对象
  - 方向/AI语音
  - 任务/语音增强
  - 任务/降噪
  - 主题/实时推理
---

# NSNet2

## 0. 背景

**问题现场**：实时通信与端侧部署需要一个低复杂度模型稳定处理加性噪声，而不是覆盖所有 speech restoration 退化。

**NSNet2 的切入点**：以带噪 STFT 对数功率谱为输入，用单帧因果 GRU 网络预测每个频点的抑制增益，配合 SNR/谱/电平数据增强与 level-invariant loss。

## 1. 身份

`NSNet2` 通常指 Microsoft 提出的低复杂度、实时单通道深度噪声抑制模型。它以带噪语音的 STFT 对数功率谱为输入，用因果/单帧处理的循环网络预测每个频点的抑制增益，再通过带噪 STFT 与增益相乘重建增强语音。

它的重点不是覆盖所有 speech restoration 退化，而是用较小模型稳定处理 additive noise，并满足实时通信或端侧部署约束。

## 2. 核心链路

```text
noisy waveform
  -> STFT
  -> log-power spectrum + online normalization
  -> feed-forward embedding
  -> GRU x 2
  -> feed-forward mapping
  -> sigmoid suppression gain
  -> noisy STFT magnitude filtering
  -> iSTFT
  -> enhanced waveform
```

论文中的网络配置包括：

- 输入：log-power spectrum，经训练集全局均值/方差归一化。
- STFT：512 点窗，32 ms square-root Hann window，16 ms frame shift；使用 255 个有效频点。
- 骨干：FF embedding → 两层 400-unit GRU → FF mapping layers。
- 输出：255 维 sigmoid suppression gain，作为实值频谱抑制 mask。
- 参数量：约 2.8M。
- 处理方式：single-frame-in / single-frame-out，不依赖 look-ahead 或额外历史缓冲区。

## 3. 训练重点

NSNet2 的论文重点同时包括模型和训练数据构造：

- **SNR augmentation**：扩大 SNR 范围，并从连续分布采样，而不是只使用少数固定 SNR。
- **Spectral augmentation**：对语音和噪声分别施加随机谱形状滤波，模拟麦克风、房间和传输链路差异。
- **Level augmentation**：改变输入和目标的整体电平，提升对录音响度变化的鲁棒性。
- **Level-invariant loss**：用每条语音的 active speech level 归一化损失，避免高电平样本在 batch 中支配训练。

论文使用带压缩的 magnitude/complex 频谱损失，实验中取压缩指数 `c = 0.3`、complex loss 权重 `α = 0.3`。

## 4. 论文实验

- **数据**：CHiME-2 WSJ-20k，使用单通道左声道实验。
- **训练/验证/测试**：7,138 / 2,418 / 1,998 条 utterances。
- **测试 SNR**：验证和测试条件覆盖约 -6 到 9 dB。
- **指标**：PESQ、STOI、cepstral distance、SI-SDR、fwSegSNR。

论文在 CHiME-2 上报告，加入更宽的 SNR 增强和谱增强后，PESQ、STOI 等指标相对原始训练配方提升；level augmentation 配合普通 level-dependent loss 会损害结果，而使用归一化损失可以缓解这一问题。

## 5. 使用判断

- **适合**：实时通信、单麦克风降噪、端侧语音前端、低延迟 DNS baseline。
- **优势**：模型小、结构简单、时延可控、容易导出到 ONNX 或嵌入式推理链路。
- **限制**：主要预测实值抑制增益，不直接修复相位；对削波、带宽缺失、codec 伪影、强混响和复杂多退化恢复不是主目标。
- **与 GSR 的关系**：NSNet2 是传统 SE / denoising baseline，不是 GSR 级别的通用语音恢复模型。
- **与生成式模型的关系**：它更重视内容稳定、低幻觉和实时性，牺牲强退化下的听感上限；可作为 [[方向/AI语音/知识/基础概念/GSR（General Speech Restoration，通用语音恢复）]] 模型的保守基线。

## 6. 版本与实现边界

- 原始论文题目是 *Data augmentation and loss normalization for deep noise suppression*，论文重点是训练增强与损失归一化；`NSNet2` 作为模型名在 Microsoft DNS 和后续实时降噪资料中延续使用。
- Microsoft 的 real-time deep noise suppression 论文进一步讨论 NSNet2 baseline 的实时计算量、GRU 规模和 DNS-MOS 权衡。
- GitHub、Hugging Face 和 ONNX 上可见的 NSNet2 实现/模型应视为复现或发布工件，不能自动当作 Microsoft 官方训练 recipe；使用时要核对采样率、STFT 配置、归一化方式和后处理。
- `Dynamic nsNet2` 是后续变体，引入 early exiting，使推理可以根据算力或质量约束提前停止；它不是原始 NSNet2。

## 7. 相关对象

- [[方向/AI语音/评估/DNS Challenge（深度噪声抑制挑战）]]：NSNet2 常作为 DNS 任务中的实时降噪基线。
- [[方向/AI语音/模型/MaskSR]]：更强的 full-band / multi-degradation speech restoration 对照。
- [[方向/AI语音/知识/基础概念/SE（语音增强）导论]]：NSNet2 属于判别式、低延迟语音增强路线。
- [[方向/AI语音/知识/基础概念/GSR（General Speech Restoration，通用语音恢复）]]：NSNet2 可作为 GSR 评测中的保守 denoising baseline，但不覆盖完整 GSR 退化空间。

## 8. 关键来源

- [Data augmentation and loss normalization for deep noise suppression](https://arxiv.org/abs/2008.06412)
  - 内容定位：原始论文；记录 STFT、GRU 架构、2.8M 参数、数据增强和 level-invariant loss。
  - 用途：确认模型机制与训练方法。
  - 核验日期：2026-09-20
- [Towards efficient models for real-time deep noise suppression](https://www.microsoft.com/en-us/research/uploads/prod/2021/06/0000656.pdf)
  - 内容定位：Microsoft real-time DNS 论文；讨论 NSNet2 baseline、实时计算量和模型规模权衡。
  - 用途：确认低复杂度实时部署语境。
  - 核验日期：2026-09-20
- [Microsoft DNS challenge paper](https://www.microsoft.com/en-us/research/uploads/prod/2022/07/0009271.pdf)
  - 内容定位：DNS Challenge 相关论文与 baseline 语境。
  - 用途：追踪 NSNet2 在 DNS benchmark 中的使用方式。
  - 核验日期：2026-09-20
- [Community PyTorch / ONNX implementation](https://github.com/noahzhy/NSNet2)
  - 内容定位：非官方复现、ONNX 导出和实时 demo。
  - 用途：工程验证入口；不作为原始模型定义的唯一来源。
  - 核验日期：2026-09-20

## 9. 待验证

- [ ] 固定本地部署版本的采样率、STFT 窗长、hop、归一化统计量和增益后处理。
- [ ] 在同一噪声/RIR/延迟条件下，与 DeepFilterNet、RNNoise 和一个 GSR 模型比较 PESQ、DNSMOS、WER、RTF。

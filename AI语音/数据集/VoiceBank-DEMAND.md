---
title: VoiceBank-DEMAND
类型: 数据集
aliases:
  - VoiceBank+DEMAND
  - VB-DMD
  - VoiceBank DEMAND 数据集
tags:
  - 类型/对象
  - 方向/AI语音
  - 任务/语音增强
  - 资源/数据集
---

# VoiceBank-DEMAND

## 1. 身份

`VoiceBank-DEMAND` 是语音增强领域**使用最广泛的经典基准数据集**，由 Valentini-Botinhao 等人于 2016 年构建（爱丁堡大学）。它把 VoiceBank 语料（与 VCTK 同源）的干净语音和 DEMAND 数据库的真实环境噪声按固定 SNR 混合，提供**成对的 noisy–clean 数据**，供有监督增强模型训练和评测。

- 原始采样率 48 kHz，绝大多数研究重采样到 16 kHz 使用。

## 2. 数据构成

| | 训练集 | 测试集 |
|---|---|---|
| 说话人 | 28 人 | 2 人（训练中未出现） |
| 语料量 | 11,572 对 noisy–clean（约 10 小时） | 824 条 |
| 噪声 | 10 种（8 种 DEMAND 真实噪声 + 2 种人工噪声：babble、speech-shaped） | 5 种 DEMAND 噪声（与训练不重叠） |
| SNR | 0 / 5 / 10 / 15 dB | 2.5 / 7.5 / 12.5 / 17.5 dB |

- **说话人和噪声类型在训练/测试间严格不重叠**，测试 SNR 也故意与训练错开——设计上就在考域外泛化，而不只是拟合。

## 3. 用途

- 有监督语音增强论文的标准对照基准：SEGAN、MetricGAN+、CMGAN、MP-SENet、SEMamba、扩散系（SGMSE、RestoreGrad）等数百篇论文在此报告结果。
- 常用指标组合：[[PESQ]]、[[CSIG CBAK COVL（复合客观质量指标）|CSIG/CBAK/COVL]]、[[STOI 与 ESTOI|STOI]]、[[SI-SDR]]。
- 头部模型表现见 [[SE SOTA（语音增强模型表现）]]：PESQ 从基线 ~1.97 演进到 MP-SENet 的 3.50。

## 4. 使用注意

- **规模小、条件干净**：10 小时训练量、单一语言（英语）、无混响/丢包/codec 失真——2025 后它更像"入门对照组"，不能代表真实场景难度。
- **已趋饱和**：头部模型 PESQ 3.3–3.5 区间挤成一团，区分度下降；新模型的说服力要靠 [[方向/AI语音/评估/URGENT（通用语音增强挑战）|URGENT]]、[[方向/AI语音/评估/DNS Challenge（深度噪声抑制挑战）|DNS Challenge]] 这类大基准。
- 泛化评测扩展版 **VB-DemandEx**（域外 DNS 2020 / EARS-WHAM_v2）专门补这个短板，MambAttention 等模型在此重新拉开差距。
- 混响不在其覆盖范围内，混响场景评测用 REVERB Challenge 或自建 RIR 合成（见 [[Reverberation Modeling（混响建模）]]）。

## 5. 相关对象

- [[方向/AI语音增强/README|AI 语音增强]]
- [[SE SOTA（语音增强模型表现）]]：本基准上的 PESQ 演进表
- [[语音增强评估指标体系]]：配套指标说明
- [[Reverberation Modeling（混响建模）]]：本数据集不覆盖的失真维度

## 6. 关键资源

- [Valentini-Botinhao et al., Interspeech 2016 原始论文](https://arxiv.org/abs/1609.07132)
  - 内容定位：数据集构建方法与基线。核验日期：2026-07-28
- [爱丁堡 DataShare 官方下载](https://datashare.ed.ac.uk/handle/10283/2826)
  - 内容定位：48 kHz 原始数据。核验日期：2026-07-28
- [Hugging Face 16 kHz 镜像](https://huggingface.co/datasets/JacobLinCool/VoiceBank-DEMAND-16k)
  - 内容定位：研究界常用的 16 kHz 重采样版。核验日期：2026-07-28
- [DEMAND 噪声数据库](https://zenodo.org/records/1227121)
  - 内容定位：噪声来源（18 种真实环境多通道录音）。核验日期：2026-07-28

## 7. 待验证

- 本基准上报告的 PESQ 与 URGENT/DNS 大基准排名的相关性（小基准高分是否还能外推）。
- 是否值得为 VB-DemandEx 拆独立笔记（当前在本笔记与 SOTA 笔记内覆盖）。

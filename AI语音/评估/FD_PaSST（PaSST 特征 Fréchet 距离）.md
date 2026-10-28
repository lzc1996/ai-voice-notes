---
title: FD_PaSST（PaSST 特征 Fréchet 距离）
类型: 概念
发表时间:
时间依据: 评测指标；源自 V2A 生成评测惯例与 PaSST（2021）特征
相关任务:
  - 音频生成
  - 音视频生成
aliases:
  - FD_PaSST
  - FD-PaSST
  - FDPassST
  - Fréchet PaSST Distance
  - PaSST 特征 Fréchet 距离
  - PaSST 特征上的 Fréchet 距离
tags:
  - 类型/对象
  - 方向/AI语音
  - 任务/音频生成
  - 指标/音频生成
---

# FD_PaSST（PaSST 特征 Fréchet 距离）

## 0. 背景

- **V2A 基准主线指标**：VGGSound 上几乎所有 V2A 工作都报 FD_PaSST（与 FD_PANNs、KL_PaSST、IS、DeSync 一起），是"分布是否匹配"的主判据。
- **感知特征域**：PaSST 是 AudioSet 预训练的音频 transformer（patchout 高效训练），嵌入比波形/频谱域统计更贴近感知差异。
- **标准工具链**：[av-benchmark](https://github.com/hkchengrex/av-benchmark)（[[方向/AI语音/模型/MMAudio|MMAudio]] 生态的标准化评测工具包）实现 FD_PaSST / FD_PANNs / FD_VGG / IS_PaSST / KL_PaSST / CLAP / DeSync，并预计算 VGGSound / AudioCaps 参考缓存。

## 1. 身份

`FD_PaSST` 是 **video-to-audio（V2A）生成评测的标准分布匹配指标**：在 **PaSST**（Patchout faSt Spectrogram Transformer）768 维嵌入上，计算生成音频与参考音频两个语料集合的高斯矩（均值 + 协方差）之间的 Fréchet 距离。越低越好——衡量"生成的音频特征分布是否贴近真实音频"。

最小公式（Fréchet 距离，设 $\mu_r, \Sigma_r$ 为参考集合、$\mu_g, \Sigma_g$ 为生成集合的特征统计）：

$$
\text{FD} = \left\| \mu_r - \mu_g \right\|^2 + \text{Tr}\!\left(\Sigma_r + \Sigma_g - 2\left(\Sigma_r \Sigma_g\right)^{1/2}\right)
$$

## 2. 边界与同族指标

| 指标 | 特征提取器 | 用途 |
|---|---|---|
| **FD_PaSST** | PaSST（AudioSet 预训练 transformer） | V2A（VGGSound） |
| FD_PANNs | PANNs（CNN 音频分类） | T2A（AudioCaps） |
| FD_VGG / FAD | VGGish | 通用音频 / 音乐（见 [[方向/AI语音/模型/Stable Audio 3]]） |
| [[方向/大模型/基础知识/FID（Fréchet Inception Distance）]] | Inception（图像） | 图像生成（同族源头） |
| KL_PaSST / IS_PaSST | PaSST 标签分布 / 嵌入 | 类别区分度与分布散度 |

## 3. 使用注意

- **语料级指标**：需要足够样本估计高斯矩（corpus-vs-corpus），单条音频无意义；样本数少时方差大。
- **特征器版本敏感**：PaSST 模型版本 / patch 参数不同则嵌入空间不同，分数不可跨实现比较；固定 av-benchmark 缓存口径。
- **参考数（VGGSound 常见量级）**：如 WavFlow 59.98 vs [[方向/AI语音/模型/MMAudio|MMAudio-L]] 60.60 vs PAVAS-L 47.38——同一基准内比较才有意义。
- **要配套看**：FD 只管分布匹配，音画同步靠 DeSync，内容对应靠 CLAP / ImageBind 分数。

## 4. 关键来源

- [av-benchmark（hkchengrex）](https://github.com/hkchengrex/av-benchmark)
  - 内容定位：Audio-Text / Audio-Visual 生成标准化评测工具包，支持 FD_PaSST、FD_PANNs、IS、KL、CLAP、DeSync。
  - 用途：FD_PaSST 的计算实现与 VGGSound / AudioCaps 参考缓存。
  - 核验日期：2026-08-11
- [Efficient Training of Audio Transformers with Patchout（PaSST）](https://arxiv.org/abs/2110.05069)
  - 内容定位：PaSST 原始论文（Koutini 等，Interspeech 2022），patchout 高效音频 transformer。
  - 用途：FD_PaSST 特征提取器的出处。
  - 核验日期：2026-08-11
- [kkoutini/PaSST GitHub](https://github.com/kkoutini/PaSST)
  - 内容定位：PaSST 官方实现与预训练模型（含 HEAR 接口）。
  - 用途：嵌入提取与指标复现的代码入口。
  - 核验日期：2026-08-11

## 5. 相关对象

- [[方向/AI语音/模型/WavFlow|WavFlow]]：V2A 模型，VGGSound 上以 FD_PaSST 59.98 评测。
- [[方向/AI语音/模型/MMAudio|MMAudio]]：V2A / T2A 模型，av-benchmark 生态来源之一。
- [[方向/AI语音/模型/Stable Audio 3|Stable Audio 3]]：音乐 / 音效生成的 FAD（VGGish 特征 Fréchet）对照。
- [[方向/大模型/基础知识/FID（Fréchet Inception Distance）]]：图像生成里的 Fréchet 距离源头。
- [[方向/AI语音/评估/可控 TTS 与声音克隆评估框架|可控 TTS 与声音克隆评估框架]]：语音域评估框架（不同口径，但同属生成评估体系）。

## 6. 待验证

- VGGSound 评测的样本数与 PaSST 版本对分数波动的定量影响。
- KL_PaSST / IS_PaSST / DeSync 是否需要独立笔记。

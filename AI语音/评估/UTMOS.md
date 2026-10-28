---
title: UTMOS
类型: 概念
发表时间: 2022-04-05
时间依据: UTMOS arXiv 首次提交日
aliases:
  - UTokyo-SaruLab MOS
  - UTMOSv2
tags:
  - 类型/对象
  - 方向/AI语音
  - 任务/语音增强
  - 指标/语音质量
---

# UTMOS

## 0. 背景

**问题现场**：TTS/语音转换等合成语音的系统评估依赖昂贵的人工 MOS 听测，需要自动代理做大规模初筛（VoiceMOS Challenge 场景）。

**切入点**：用 wav2vec 2.0 等 SSL 自监督特征 + 轻量预测头回归主观 MOS，并针对域内/域外泛化做训练设计。

## 1. 身份

`UTMOS`（UTokyo-SaruLab System for MOS prediction，现多为 UTMOSv2）是**非侵入式** MOS 预测模型，最初为 VoiceMOS Challenge（TTS/VC 评估）设计，用 SSL 特征（wav2vec 2.0 等）加轻量预测头回归主观 MOS。

- 输出 MOS 1–5；在 URGENT 2024 的分析中，UTMOS 与主观 MOS 排名相关性是所有自动指标里最高的一档（与 [[SCOREQ]] 并列）。

## 2. 用途

- TTS、语音转换、语音增强的无参考质量代理；URGENT 榜单的标准指标之一。
- 适合大规模系统自动排序，替代昂贵的人工听测做初筛。

## 3. 计算口径

- SSL 自监督特征 + 数据集内/域外泛化训练技巧；预测目标为人工 MOS。
- 本质是"拟合特定听测数据集的人类偏好"，跨域迁移性取决于训练语料覆盖。

UTMOS / UTMOSv2 的计算式可以概括为：

$$
\widehat{MOS}=g_\theta(\phi_{SSL}(x))
$$

其中 $\phi_{SSL}(x)$ 是 wav2vec 2.0 等 SSL encoder 的语音表示，$g_\theta$ 是回归 MOS 的预测头。批量结果一般报告：

$$
\overline{UTMOS}=\frac{1}{M}\sum_{i=1}^{M}\widehat{MOS}_i
$$

## 4. 使用注意

- 出身是合成语音评估，对语音增强特有的失真（残留噪声、混响尾、生成式伪影）的标定弱于 [[NISQA]]/DNSMOS；URGENT 用它是因为相关性好，不是因为它理解这些失真。
- 分数绝对值跨数据集不可比，只适合同一评测内排序。
- 见 [[语音增强评估指标体系]]。

## 5. 相关对象

- [[方向/AI语音增强/README|AI 语音增强]]
- [[语音增强评估指标体系]]、[[SE SOTA（语音增强模型表现）]]
- [[NISQA]]、[[OVRL_MOS]]

## 6. 关键资源

- [UTMOS 论文 (Saeki et al., Interspeech 2022)](https://arxiv.org/abs/2204.02152)
  - 内容定位：VoiceMOS Challenge 冠军系统。核验日期：2026-07-28
- [UTMOSv2](https://arxiv.org/abs/2409.09305)
  - 内容定位：改进版，更强泛化。核验日期：2026-07-28

## 7. 待验证

- UTMOS 在强混响、真实通话录音上的分数漂移程度。

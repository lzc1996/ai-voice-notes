---
title: VQScore（语音质量评分）
类型: 指标
发表时间: 2024-02-26
时间依据: arXiv:2402.16321 v1 提交日；论文为 ICLR 2024
相关任务:
  - 语音增强评估
  - 语音数据筛选
  - clean speech quality filtering
aliases:
  - VQScore
  - VQ Score
  - Self-Supervised Speech Quality Estimation and Enhancement Using Only Clean Speech
  - arXiv:2402.16321
  - 语音质量评分
tags:
  - 类型/对象
  - 方向/AI语音
  - 指标/语音质量
  - 主题/无参考评估
  - 主题/数据质量
---

# VQScore（语音质量评分）

## 0. 背景

**问题现场**：生成语音评估与训练数据筛选需要在只有干净语音、没有退化配对标注的情况下自动衡量语音质量。

**切入点**：只用 clean speech 训练 VQ-VAE，用 bottleneck 的量化误差作为质量分——失真越重，量化误差越大（见下文"怎么算"）。

## 1. 身份

`VQScore` 是一种无参考 speech quality score，原始用途是给生成语音 / 合成语音做自动质量评估；在 [[方向/AI语音/模型/RE-USE]] 里被借来筛选 clean speech target 的质量。

核心直觉：VQ-VAE 只用 clean speech 训练时，codebook 会更擅长表示干净语音；噪声、codec、hiss、混响或伪影会让 bottleneck 的量化误差变大。因此它更像**训练数据质量过滤器**，不是完整的听测替代品。

## 2. 怎么算

论文做法是用 VQ-VAE 在 clean speech 上训练质量估计器。推理时，输入语音经过 encoder 得到帧级表示 $z_t$，再经过 vector quantization 得到 $q(z_t)$；失真越重，$z_t$ 和 $q(z_t)$ 的量化误差通常越大，或等价地相似度越低：

$$
e(x)=\frac{1}{T}\sum_t \lVert z_t-q(z_t)\rVert
$$

常见打分口径可理解为反向质量分 / 相似度分：

$$
\mathrm{VQScore}(x) \approx \frac{1}{T}\sum_t \cos(z_t, q(z_t))
$$

工程使用里通常看校准后的 VQScore：分数越高，表示该语音越接近模型从高质量 clean speech 中学到的分布。

## 3. 在 RE-USE 里的用法

- **筛 clean target**：[[方向/AI语音/模型/RE-USE]] 用 VQScore 过滤训练用的干净语音，避免模型把 hiss、麦克风伪影或低质量录音当成目标学习。
- **阈值不是通用常数**：RE-USE 报告 VQScore 阈值 0.50 / 0.65 / 0.72 分别得到约 2518 / 2506 / 629 小时训练语音；0.72 质量高但数据量太小，0.65 是该论文的质量/规模折中。
- **评估定位**：它适合做数据筛选和质量门控，不适合单独判断增强模型最终输出是否保内容、保说话人或主观更自然。

## 4. 边界

- 不检测内容是否被改写；生成式增强仍要配 [[方向/AI语音/评估/CAcc]] / [[方向/AI语音/评估/CER（Character Error Rate）]] / [[方向/AI语音/评估/SpeechBERTScore（语音语义相似度）]]。
- 不检测说话人身份是否漂移；需要配 [[方向/AI语音/评估/SpkSim]]。
- 不等价于 MOS；无参考质量分数需要和 [[方向/AI语音/评估/NISQA]]、[[方向/AI语音/评估/UTMOS]] 或人工听测一起看。

## 5. 关键来源

- [Self-Supervised Speech Quality Estimation and Enhancement Using Only Clean Speech](https://arxiv.org/abs/2402.16321)
  - 内容定位：提出 VQScore，用只在 clean speech 上训练的 VQ-VAE 量化误差估计语音质量。
  - 用途：建立 VQScore 的定义、方向性和使用边界。
  - 发表日期：2024-02-26（arXiv v1；ICLR 2024）
  - 核验日期：2026-08-25
- [VQscore](https://github.com/JasonSWFu/VQscore)
  - 内容定位：VQScore 作者仓库，提供 quality estimation / VQScore 推理和训练代码入口。
  - 用途：确认实现入口和工具状态。
  - 发表日期：2024-12-02（仓库 README 更新记录）
  - 核验日期：2026-08-25

## 6. 相关对象

- [[方向/AI语音/模型/RE-USE]]：把 VQScore 作为 clean speech data filtering 指标。
- [[方向/AI语音/评估/语音增强评估指标体系]]：VQScore 属于无参考质量估计，但更偏数据筛选。
- [[方向/AI语音/工具/SQUIM（语音质量无参考评估）]]：同属无参考语音质量估计工具，但用途和训练来源不同。

## 7. 待验证

- 在中文会议语音、远场录音和 TTS 数据清洗中，VQScore 阈值是否需要重新标定。
- VQScore 与 DNSMOS / NISQA / UTMOS 对低质量 clean target 的排序一致性。

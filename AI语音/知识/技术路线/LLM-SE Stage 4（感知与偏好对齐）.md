---
title: LLM-SE Stage 4（感知与偏好对齐）
类型: 技术路线
时间依据: 对话沉淀；非单一发表物
上级:
  - "[[方向/AI语音/知识/技术路线/LLM-SE Training Recipe（借鉴 NLP LLM 的语音增强训练配方）]]"
  - "[[方向/AI语音/知识/技术路线/LLM-SE Training Recipe v2（显式解耦训练配方）]]"
相关任务:
  - 语音增强
  - preference tuning
  - perceptual alignment
aliases:
  - 阶段 4：Preference / Perceptual Alignment
  - preference / perceptual alignment
  - 感知偏好对齐
tags:
  - 类型/对象
  - 方向/AI语音
  - 任务/语音增强
  - 主题/后训练
---

# LLM-SE Stage 4（感知与偏好对齐）

## 1. 目标

Stage 4 是后训练阶段：**小步偏好调优**，让模型更符合人耳感知、ASR 下游、说话人与情绪一致性，同时不破坏 [[方向/AI语音/知识/技术路线/LLM-SE Stage 3（声学保真）]] 的保真底线。

在 v2 里，Stage 4 是"干净"的四个锚点之一——**感知 reward**。表示解耦、退化不变性、质量过滤的 prior 三个锚都在训练数据内部定义"干净"，只有感知 reward 能把输出推到**比训练 target 更干净**的区域。

关键约束：**偏好对齐只能微调排序和取舍，不能把 SE 变成语音重写。**

## 2. 输入分布：以真实噪声数据为主

v2 数据规则：真实噪声数据（无 clean 参考）只进三个位置——一致性训练、Stage 4、对比预训练，都不需要配 target。Stage 4 是其中唯一能直接优化输出分布的位置：

- Stage 1–3 的监督信号全部来自过滤后的 clean 子集，模型输出上限被训练 target 的平均音质锚住；
- Stage 4 输入换成真实噪声录音（分布外、无参考），reward 由感知 / 一致性模型打分而非与 target 比较——这是唯一能把输出推到比训练 target 更干净的机制。

配套机制（v2 实施顺序第 4 步）：**FixMatch 式自蒸馏**——真实噪声弱视图出伪标签，叠仿真退化做强视图训练，把真实数据分布转写成可监督信号。

## 3. Preference 数据

构造 pairwise preference：同一 degraded input 生成多个 enhanced candidates，然后排序。

候选来源可以包括：

- Stage 3 checkpoint 不同步数；
- 不同 decoding / guidance 强度；
- 不同 loss 权重模型；
- baseline SE 模型；
- 人工 hard case 手动挑选。

偏好来源可以是人工 MOS、DNSMOS/[[方向/AI语音/评估/NISQA]]、ASR consistency、speaker similarity、[[方向/AI语音/评估/CAcc]]、emotion consistency、任务规则或混合 reward。

如果 Stage 3 已经拟合训练集 clean target 的平均音质，Stage 4 的偏好数据应显式包含"clean target 带残余退化"的 hard cases，让 preference / reward 学会偏好更干净、更自然但仍忠实于输入内容和说话人的输出。

## 4. Reward 分解

v2 验收口径：**看 reward 分项 + hard case，不看总 reward**。推荐至少分解成：

```text
R_total = R_quality
        + R_content
        + R_speaker
        + R_emotion
        + R_naturalness
        - R_hallucination
        - R_latency_penalty
```

其中：

- `R_quality`：感知 MOS 预测器（DNSMOS / NISQA 式）、主观质量、噪声残留。
- `R_content`：ASR consistency——[[方向/AI语音/评估/WER（词错误率）]] / [[方向/AI语音/评估/CER（Character Error Rate）]]、关键词、数字、人名、[[方向/AI语音/评估/CAcc]]。
- `R_speaker`：speaker similarity、speaker drift（与 Stage 0 / Stage 3 同一 SV 模型，量纲一致）。
- `R_emotion`：emotion consistency——预训练 SER / emotion2vec 打分，防止增强把情绪磨平（v2 新增分项）。
- `R_naturalness`：韵律、爆破音、弱音、停顿、空间自然度。
- `R_hallucination`：新增词、改词、过度补全、不受输入支持的语音。
- `R_latency_penalty`：流式部署需要约束延迟和 chunk artifact。

## 5. 训练方式

- **小步偏好调优**（v2 定调）：优先离线小步——[[方向/大模型/训练/强化学习/DPO]] / reward-weighted SFT / ranking loss；reward 设计参考 [[方向/大模型/基础知识/Reward Shaping]]。
- 暂缓在线 RL，除非 reward 已经非常可靠；需要 RL 时再比较 [[方向/大模型/训练/强化学习/PPO]] / [[方向/大模型/训练/强化学习/GRPO]] 等路线。
- 每次只小学习率更新 adapter / LoRA / preference head，避免破坏 Stage 3 保真。
- reward 必须分项记录，不能只看总分。

## 6. 验收标准

v2 指标分工：S4 看 **reward 分项 + hard case**。

- reward 各分项（quality / content / speaker / emotion / naturalness / hallucination）独立跟踪，不看总 reward。
- MOS / DNSMOS / [[方向/AI语音/评估/NISQA]] 改善，并放入 [[方向/AI语音/评估/语音增强评估指标体系]] 统一看。
- [[方向/AI语音/评估/WER（词错误率）]] / [[方向/AI语音/评估/CER（Character Error Rate）]] / [[方向/AI语音/评估/CAcc]] 不变差。
- speaker similarity、emotion consistency 不变差。
- hallucination case rate 下降。
- 人工 hard set 上不过拟合，不只优化 proxy metric。
- 真实噪声输入上确认"比 target 更干净"的外推确实发生，而不是只拟合了 reward 模型偏好。
- 流式场景中 latency 和 chunk boundary artifact 不恶化。

## 7. 主要风险

- reward hacking：模型牺牲内容保真换取更好听感。
- ASR 指标误导：WER 变好但音色、韵律、空间感变差。
- speaker reward 误导：保说话人同时保留了房间和麦克风 coloration。
- emotion reward 误导：SER 本身在增强语音上不准，把模型拉向夸张韵律。
- 偏好数据分布窄：模型只适配某类噪声或某类说话人。
- 真实噪声数据的 reward 外推失效：reward 模型在"比训练 target 更干净"的输出上没有可靠刻度。
- 对齐步数过大，Stage 1/2/3 学到的 conditional reconstruction 被冲掉。

## 8. 相关对象

- [[方向/AI语音/知识/技术路线/LLM-SE Training Recipe（借鉴 NLP LLM 的语音增强训练配方）]]
- [[方向/AI语音/知识/技术路线/LLM-SE Training Recipe v2（显式解耦训练配方）]]
- [[方向/AI语音/知识/技术路线/LLM-SE Stage 3（声学保真）]]
- [[方向/AI语音/评估/语音增强评估指标体系]]
- [[方向/AI语音/评估/CAcc]]
- [[方向/AI语音/评估/NISQA]]
- [[方向/AI语音/评估/WER（词错误率）]]
- [[方向/AI语音/评估/CER（Character Error Rate）]]
- [[方向/大模型/基础知识/Reward Shaping]]
- [[方向/大模型/训练/强化学习/DPO]]
- [[方向/大模型/训练/强化学习/PPO]]
- [[方向/大模型/训练/强化学习/GRPO]]
- [[方向/大模型/训练/强化学习/OPD（On-Policy Distillation）]]

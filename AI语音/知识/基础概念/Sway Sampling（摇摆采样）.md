---
title: Sway Sampling（摇摆采样）
类型: 概念
aliases:
  - Sway Sampling
  - 摇摆采样
tags:
  - 类型/对象
  - 方向/AI语音
  - 主题/生成模型
---

# Sway Sampling（摇摆采样）

## 1. 身份

Sway Sampling 是 F5-TTS 提出的推理期 flow 时间网格重映射方法。它把原本等距的求解时间点做单调变形，在不改模型参数和训练过程的情况下，调整固定 NFE 下各时间区间的步长分配。

名称中的 “sampling” 指采样器的时间点安排；实现上是确定性地变换时间网格，不是额外随机抽取语音候选样本。

## 2. 核心机制

令 $N$ 为积分步数，$i=0,\ldots,N$，先构造等距时间网格 $u_i=i/N$，再将每个时间点变换为 $t_i=f_s(u_i)$：

$$
f_s(u)=u+s\left(\cos\left(\frac{\pi}{2}u\right)-1+u\right),\qquad s\in\left[-1,\frac{2}{\pi-2}\right]
$$

其中 $u\in[0,1]$ 是原始归一化时间，$t$ 是变换后的时间，$s$ 是 sway 系数。该映射保持端点 $f_s(0)=0$、$f_s(1)=1$；$s=0$ 时退化为等距网格。

采样器随后在 $t_0,\ldots,t_N$ 上执行原有积分过程。网格点数不变，因此 NFE 不变；变化的是相邻时间点间距及模型计算在时间轴上的分布。

## 3. 系数方向

- $s<0$：内部时间点向较小的 $t$ 偏移；$s=-1$ 时 $f_s(u)=1-\cos(\frac{\pi}{2}u)$，网格在 $t=0$ 一侧更密。
- $s>0$：内部时间点向较大的 $t$ 偏移；系数上界使映射保持单调。
- F5-TTS 论文报告的默认值为 $s=-1$。具体最优值应按模型、求解器和 NFE 验证，不能直接视为通用默认值。

“较小 $t$”对应轨迹的早期还是后期，取决于具体模型的时间方向约定；跨实现比较时应检查时间网格定义。

## 4. 适用边界

- 这是推理调度调整，不改变训练目标、模型结构或权重；原论文称该变换可无重训地用于 flow-matching 模型。
- 固定步数时它重新分配时间点，不减少模型调用次数。有限步数下的质量变化依赖模型与采样配置，需实测。
- 用于 RL rollout 时，rollout 和推理应使用相同的变换后网格，并记录系数，避免时间网格口径不一致。

## 5. 相关对象

- [[方向/AI语音/模型/F5-TTS|F5-TTS]]：提出该方法的 TTS 模型与原始应用。
- [[方向/AI语音/知识/基础概念/Flow Matching（流匹配）|Flow Matching]]：Sway Sampling 调整其推理时间网格。
- [[方向/AI语音/知识/基础概念/T-Grid Rollout（显式时间网格 Rollout）|T-Grid Rollout]]：在显式 rollout 网格中记录并复用 sway 变换。
- [[方向/AI语音/模型/AuK|AuK]]、[[方向/AI语音/模型/SenSE|SenSE]]：已有笔记记录了各自推理配置中的 sway 系数。
- [[方向/AI语音/MOC - TTS|MOC - TTS]]：TTS 方向索引。

## 6. 关键来源

- [F5-TTS: A Fairytaler that Fakes Fluent and Faithful Speech with Flow Matching（arXiv:2410.06885 v3）](https://arxiv.org/html/2410.06885v3)
  - 内容定位：原论文定义 Sway Sampling 的时间映射、系数范围及推理期用法。
  - 用途：公式与方法边界的一手依据。
  - 核验日期：2026-10-12

## 7. 待验证

- 不同模型与 NFE 下，最优 $s$ 是否稳定，以及是否有可迁移的选择准则。

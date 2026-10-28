---
title: CSS（连续语音分离）
类型: 概念
相关主题:
  - 会议转写
  - 多通道分离
aliases:
  - CSS
  - Continuous Speech Separation
  - continuous speech separation
  - 连续语音分离
tags:
  - 类型/对象
  - 方向/AI语音
  - 任务/多通道分离
  - 主题/会议转写
---
# CSS（连续语音分离）

## 1. 身份

`CSS`（Continuous Speech Separation，连续语音分离）是 Microsoft 语音组为**自然会议转写**提出的任务范式（Yoshioka 等 Interspeech 2018 首发，Chen 等 ICASSP 2020 以 [[方向/AI语音/数据集/LibriCSS|LibriCSS]] 数据集确立公开评测口径）：把**不预切分的长会议录音**分离成 $K$ 路与输入等长的信号流，使得**每一路内部不含说话人重叠**，且各路之并保留输入中全部语音内容——分离出的无重叠流可以直接喂给常规单说话人 ASR。

它与经典[[方向/AI语音/知识/基础概念/SS（语音分离）|语音分离]]的关键区别在于**放弃了"按说话人追踪身份"**：CSS 不要求第 1 路始终是张三——只要求任何时刻每路至多一个人在说话。这个放宽让系统不必内嵌 diarization，是 CSS 能工程落地的核心。

## 2. 核心机制

```text
长会议录音（不预切分，含任意位置的重叠）
  -> 滑窗（如 1.6 s 窗 / 0.4 s 移位）
  -> 窗内分离（uPIT 训练，输出 K 路）
  -> stitching：相邻窗的重叠段上，选使两窗输出 MSE 最小的输出排列
  -> K 路无重叠长流（静默路补零保持同步）
  -> 各路独立 ASR -> 转写合并
```

要点：

- **K=2 即够用**：会议重叠分析（Çetin & Shriberg, Interspeech 2006）表明绝大多数会议时间里同时说话者不超过两人，故主流 CSS 取 K=2；单人时段另一路补零。
- **stitching 解决跨窗置换**：窗内 [[方向/AI语音/知识/基础概念/PIT（置换不变训练）|uPIT]] 不管"这一窗的说话人 A 该接上一窗的第几路"，stitching 用重叠段的波形一致性在线确定排列。
- **前端组合**：mask 估计 →（可选稀疏化）→ [[方向/AI语音/知识/基础概念/MVDR（最小方差无失真响应）|MVDR]] 波束形成 → 增益调整，是 [[方向/AI语音/模型/VarArray|VarArray]] 一代的标准链路。

## 3. 评测口径

- **终点指标是 WER 不是 SDR**：speaker-agnostic WER（asclite 对齐多参考），把"分离好不好"直接折成"转写对不对"。[[方向/AI语音/数据集/LibriCSS|LibriCSS]] 提供 0S/0L/OV10–OV40 六档重叠率的分桶分析。
- **continuous input evaluation**：不预切分、无 ground-truth segmentation——这是它与 LibriMix 式预切分评测的分界线。
- 代表数字（LibriCSS，7 麦 CSS 基线）：0% 重叠 11.9–13.4% WER，40% 重叠 19.7–22.0%；无分离基线从 0L 到 0S 恶化 33.9%，CSS 压到 22.7%（口径见 LibriCSS 页）。

## 4. 和相邻概念的区别

| 概念 | 输出 | 与 CSS 的关系 |
| --- | --- | --- |
| [[方向/AI语音/知识/基础概念/SS（语音分离）\|SS]] | 每个说话人一路 | SS 按身份分，CSS 只保证路内无重叠、不管身份 |
| Diarization | "谁在什么时候说话" | CSS 输出无重叠流，diarization 仍需在流上/外部做；CSS 不替代它 |
| E2E speaker-attributed ASR | 直接出带说话人标签的转写 | 端到端对手路线；CSS 是模块化前端路线 |
| [[方向/AI语音/知识/基础概念/GSS（引导源分离）\|GSS]] | 按时间切分引导的分离 | GSS 依赖 diarization 先给段；CSS 不需要 |

## 5. 边界

- **只管重叠，不管归属**：跨窗/跨段的说话人身份一致性不是 CSS 的责任——身份漂移靠 stitching 波形一致性缓解，不保证全局一致。
- K 固定：三人及以上同时说话的密集讨论场景出范围；Graph-PIT（von Neumann 等，Interspeech 2021）一类工作把 CSS 推广到任意人数，属后续扩展。
- 低延迟变体（Yoshioka 等 ICASSP 2019）存在，但标准 CSS 滑窗 stitching 本身是块式处理。
- 评测终点绑定 ASR：若下游不是转写（如助听器听感），CSS 口径不适用。

## 6. 在库内的使用谱系

- [[方向/AI语音/模型/VarArray|VarArray]]：几何无关 CSS 模型（阵列无关 + CSS 范式）。
- [[方向/AI语音/数据集/LibriCSS|LibriCSS]]：CSS 的公开评测数据集与基线口径。
- [[方向/AI语音/数据集/AMI Meeting Corpus（会议语料库）|AMI]]、[[方向/AI语音/数据集/AISHELL-4|AISHELL-4]]、[[方向/AI语音/评估/NOTSOFAR-1（远场会议转写挑战）|NOTSOFAR-1]]：CSS 类前端的主要战场。
- [[方向/AI语音/评估/CHiME and URGENT Chinese Industry Labs（国内工业界参赛记录）|CHiME 参赛记录]]：国内工业界系统普遍采用 CSS + ASR + diarization 链路。

## 7. 关键来源

- [Continuous Speech Separation: Dataset and Analysis（LibriCSS 论文，arXiv:2001.11482）](https://arxiv.org/abs/2001.11482)
  - 内容定位：CSS 公开评测口径的确立论文（数据集、六档重叠率、asclite speaker-agnostic WER、官方基线）。
  - 用途：本页评测口径与基线数字的来源（经库内 [[方向/AI语音/数据集/LibriCSS|LibriCSS]] 页核验）。
  - 核验日期：2026-10-15
- [VarArray: Array-Geometry-Agnostic Continuous Speech Separation（arXiv:2110.05745）](https://arxiv.org/abs/2110.05745)
  - 内容定位：CSS 通用架构的完整描述（K=2 依据、滑窗 stitching、mask→MVDR→增益调整链路、无切分端到端评测）。
  - 用途：本页机制节与链路图的直接依据（全文 HTML 已核）。
  - 核验日期：2026-10-15
- [Recognizing overlapped speech in meetings: a multichannel separation approach using neural networks（Yoshioka et al., Interspeech 2018）](https://www.isca-archive.org/interspeech_2018/yoshioka18_interspeech.html)
  - 内容定位：CSS 范式的首发会议论文。
  - 用途：谱系源头标注。
  - 核验日期：2026-10-15

## 8. 相关对象

- [[方向/AI语音/知识/基础概念/SS（语音分离）|SS]]：CSS 是 SS 在连续流设定下的任务化放宽。
- [[方向/AI语音/知识/基础概念/PIT（置换不变训练）|PIT/uPIT]]：窗内训练准则；跨窗置换由 stitching 处理。
- [[方向/AI语音/知识/基础概念/GSS（引导源分离）|GSS]]：依赖 diarization 的对照前端。
- [[方向/AI语音/模型/VarArray|VarArray]]：CSS 范式的几何无关模型。
- [[方向/AI语音/团队/Microsoft Speech Group（微软语音组）|Microsoft Speech Group]]：CSS 范式的提出与推动团队。

## 9. 待验证

- CSS 首发精确归属（Interspeech 2018 会议论文 vs 同组 ASRU 2019 低延迟版的分工），本页按 LibriCSS 页与 VarArray 参考文献口径记录。
- Graph-PIT 等任意人数 CSS 扩展的细节未展开；出现库内第二处使用再拆。

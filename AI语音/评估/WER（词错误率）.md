---
title: WER（词错误率）
类型: 概念
发表时间:
时间依据: 经典 ASR 错误率指标；非单一发表物
aliases:
  - Word Error Rate
  - WER
  - wer
  - 词错误率
  - 词错率
tags:
  - 类型/对象
  - 方向/AI语音
  - 任务/ASR
  - 指标/ASR
---

# WER（词错误率）

## 0. 背景

**问题现场**：ASR 与语音前端（增强、分离）的收益最终要落到识别任务上度量，需要与词对齐的客观错误率。

**切入点**：词级编辑距离统计替换/删除/插入得到 WER，成为英文 ASR 与 CHiME 类 noisy/distant 挑战赛的事实标准主指标。

## 1. 身份

WER（Word Error Rate，词错误率）是 ASR 评估指标，用**词级编辑距离**衡量识别文本和参考文本之间的差异。它是英文 / 分词语言 ASR 的事实标准口径，也是 [[方向/AI语音/评估/CHiME（语音分离与识别挑战赛）|CHiME]] 等 noisy / distant ASR 挑战赛的主指标——增强前端收益好不好，最终看 WER 降不降。

常用公式：

$$
\text{WER} = \frac{S + D + I}{N}
$$

- `S`：substitution，替换词数。
- `D`：deletion，漏掉词数。
- `I`：insertion，多插入词数。
- `N`：参考文本词数。

## 2. 用途

- 英文 / 空格分词语言 ASR 评估：词是天然对齐单位。
- noisy / distant / 多通道 ASR：[[方向/AI语音/评估/CHiME（语音分离与识别挑战赛）|CHiME]]-3、CHiME-6、CHiME-7/8 DASR 都以 WER（或 tcpWER）定榜，用于检验增强前端 / beamforming 是否带来识别收益。
- 会议转写：tcpWER（time-concatenated WER）处理时间轴拼接后的转写错误，是 NOTSOFAR 类远场会议任务的口径。

## 3. 计算口径

- 先做文本归一化：大小写、标点、数字读法、缩写展开、空格规则——不同工具（sclite / jiwer）默认不同，对比前必须固定。
- 再做词级对齐：按编辑距离统计 `S/D/I`。
- 最后按参考词数归一化：`N` 是参考词数，不是预测词数。
- WER 可以超过 100%，常见原因是插入词很多。
- **中文场景**：词切分本身有歧义，通常改用 [[方向/AI语音/评估/CER（Character Error Rate）|CER]] 更直接。

## 4. 最小例子

```text
reference:  the cat sat on the mat
hypothesis: a cat sat on mat

S = 1（the -> a）
D = 1（the 被漏掉）
I = 0
N = 6
WER = 2 / 6 ≈ 33.3%
```

## 5. 相关对象

- [[方向/AI语音/评估/CER（Character Error Rate）|CER]]：字级错误率，中文 / 无空格语言的主口径；WER 与 CER 是同一编辑距离家族的两个层级。
- [[方向/AI语音/知识/基础概念/Levenshtein Alignment（莱文斯坦对齐）]]：WER 的词级编辑对齐与 `S/D/I` 分解基础。
- [[方向/AI语音/评估/CHiME（语音分离与识别挑战赛）|CHiME]]：WER 是其系列主指标，阵列增强作为降 WER 的手段被评估。
- [[方向/AI语音/MOC - ASR|ASR]]：WER 是 ASR 基础准确率指标。
- [[方向/AI语音/选型/ASR 模型选型矩阵|ASR 模型选型矩阵]]：选型时与 CER、实体错误率、数字错误率一起看。

## 6. 关键来源

- [jiwer measures](https://jitsi.github.io/jiwer/reference/measures/)
  - 内容定位：jiwer 文档列出 WER、MER、WIL、WIP、CER 等 ASR 常用度量，并提供 `wer` API。
  - 用途：工程计算 WER 时的 Python 工具参考。
  - 核验日期：2026-07-28
- [CHiME-3 Results](https://www.chimechallenge.org/challenges/chime3/results)
  - 内容定位：官方结果页，WER 作为多通道 noisy ASR 主指标。
  - 用途：确认 WER 在 CHiME 系列中的定榜口径。
  - 核验日期：2026-08-04

## 7. 待验证

- 中文场景 WER vs CER 的选择口径（与 [[方向/AI语音/评估/CER（Character Error Rate）|CER]] 笔记共用待验证项）。
- tcpWER 在 NOTSOFAR 类远场会议任务里的精确计算口径是否需要独立说明。
- 是否需要统一 ASR 评测脚本，固定文本归一化与 WER/CER 计算（与 CER 笔记共用）。

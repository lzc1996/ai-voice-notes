---
title: "Levenshtein Alignment（莱文斯坦对齐）"
类型: 概念
相关任务:
  - ASR evaluation
  - text alignment
  - error analysis
aliases:
  - Levenshtein distance
  - Levenshtein alignment
  - 莱文斯坦距离
  - 编辑距离
  - 字符串编辑距离
  - 序列编辑对齐
tags:
  - 类型/对象
  - 方向/AI语音
  - 任务/ASR
  - 主题/评估
  - 主题/对齐
---

# Levenshtein Alignment（莱文斯坦对齐）

## 1. 身份

`Levenshtein alignment` 是对两条离散序列做最小编辑代价对齐的方法。允许的基本操作是插入（insertion）、删除（deletion）和替换（substitution）；标准单位代价下，最短编辑路径的长度就是 Levenshtein distance。

在语音中，它通常对参考文本与识别文本的**词、字或音素序列**做对齐，用来统计 WER、CER、PER 的替换/删除/插入，不是把音频帧对到时间轴上的 forced alignment。

## 2. 核心机制

设参考序列为 $r_{1:m}$，假设序列为 $h_{1:n}$，令 $D(i,j)$ 表示前 $i$ 个参考单位与前 $j$ 个假设单位的最小代价：

$$
D(i,j)=\min\begin{cases}
D(i-1,j)+1 & \text{删除 } r_i\\
D(i,j-1)+1 & \text{插入 } h_j\\
D(i-1,j-1)+[r_i\ne h_j] & \text{匹配或替换}
\end{cases}
$$

边界是 $D(i,0)=i$、$D(0,j)=j$。从 $D(m,n)$ 沿反向最短路径回溯，就能得到 token 对、插入空位和删除空位：

```text
reference:  a b c
hypothesis: a x c y
alignment:  a-a, b-x, c-c, ∅-y
distance:   2  = 1 substitution + 1 insertion
```

距离是一个标量；对齐则是产生这个标量的具体操作序列。相同最小代价可能对应多条路径，因此实现的 tie-breaking 会影响逐句的 `S/D/I` 分解，即使总距离相同。

## 3. AI 语音中的用法

- **WER**：先按词切分，再做 Levenshtein 对齐，$mathrm{WER}=(S+D+I)/N$。
- **CER**：先按字符切分，适合中文等没有稳定空格分词的场景。
- **PER / 音素级指标**：按音素序列对齐，常用于发音或 TTS 内容保持分析。
- **错误分析**：保留每个对齐操作，可以定位具体的替换、漏词和插词，而不只看一个总分。

计算前必须固定文本归一化和 tokenization：大小写、标点、数字读法、繁简、空格、英文片段和语气词的处理都会改变对齐结果。

## 4. 与相邻方法的边界

- **不是 forced alignment**：Levenshtein 只看两条离散序列，不需要音频；[[方向/AI语音/工具/MFA（强制对齐工具）]] 和 [[方向/AI语音/工具/WhisperX（长音频转写与对齐）]] 会使用声学证据估计时间边界。
- **不是 CTC 对齐**：[[方向/AI语音/知识/基础概念/CTC（连接时序分类）]] 在训练时对音频帧与文本之间的多条路径求概率和；Levenshtein 是两条已生成离散序列之间的最小代价回溯。
- **不是 Damerau-Levenshtein**：后者额外允许相邻换位；标准 ASR WER/CER 通常只统计替换、删除和插入。
- **不是唯一的相似度定义**：把操作成本改成非单位权重可以适配业务，但结果不能直接当作标准 WER/CER。

## 5. 相关对象

- [[方向/AI语音/评估/WER（词错误率）]]：词级编辑对齐后的标准错误率。
- [[方向/AI语音/评估/CER（Character Error Rate）]]：字符级编辑对齐后的错误率。
- [[方向/AI语音/MOC - ASR]]：ASR 转写、时间戳和评估的方向入口。
- [[方向/AI语音/工具/MFA（强制对齐工具）]]：有音频条件的词/音素时间对齐工具。
- [[方向/AI语音/工具/WhisperX（长音频转写与对齐）]]：转写后接词级强制对齐的工具链。

## 6. 关键来源

- [jiwer measures](https://jitsi.github.io/jiwer/reference/measures/)
  - 内容定位：提供 WER、CER 等 ASR 度量及其工程计算接口。
  - 用途：核对编辑对齐在 ASR 错误率中的使用口径。
  - 核验日期：2026-09-23
- [NIST SCTK](https://github.com/usnistgov/SCTK)
  - 内容定位：NIST Speech Recognition Scoring Toolkit，包含 `sclite` 等 ASR 评分工具链。
  - 用途：作为词级错误对齐、`S/D/I` 统计和评分实现的工程参照。
  - 核验日期：2026-09-23

## 7. 待验证

- [ ] 统一当前 Vault 中 WER/CER/PER 的文本归一化、标点和 tokenization 约定。
- [ ] 对照 `sclite`、`jiwer` 和本地评测脚本的 tie-breaking，解释逐句 `S/D/I` 差异。
- [ ] 评估中文、代码切换和数字密集文本中，字符级、词级和混合 token 对齐的业务相关性。

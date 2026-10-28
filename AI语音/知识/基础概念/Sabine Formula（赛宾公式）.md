---
title: Sabine Formula（赛宾公式）
类型: 概念
发表时间:
时间依据: 历史声学公式；待补精确原始发表年
相关任务:
  - 语音增强
aliases:
  - 赛宾公式（Sabine Formula）
  - Sabine Formula
  - 赛宾公式
  - sabine formula
tags:
  - 类型/对象
  - 方向/AI语音
  - 任务/语音增强
---

# Sabine Formula（赛宾公式）

## 1. 身份

赛宾公式是房间声学里用房间体积和总吸声量估算混响时间（RT60 / T60）的经典经验公式：

$$
T_{60} \approx 0.161 \cdot \frac{V}{A}
$$

其中：

- $T_{60}$：声级衰减 60 dB 所需时间，单位秒。
- $V$：房间体积，单位 m³。
- $A$：等效总吸声量，单位 m² sabin，通常写作 $A=\sum_i S_i\alpha_i$。
- $S_i$：第 $i$ 类表面面积，单位 m²。
- $\alpha_i$：第 $i$ 类材料的吸声系数，通常按倍频程或 1/3 倍频程给出。

## 2. 用途

- 快速估算一个房间的目标 RT60 是否过长或过短。
- 粗算需要增加多少吸声材料：$A_{target}=0.161V/T_{target}$。
- 给 [[方向/AI语音/知识/基础概念/Reverberation Modeling（混响建模）|混响建模]]、RIR 仿真和语音增强数据合成提供参数直觉。

## 3. 反推吸声量

如果已知房间体积和目标混响时间：

$$
A_{target} = 0.161 \cdot \frac{V}{T_{target}}
$$

新增吸声量近似为：

$$
\Delta A = A_{target} - A_{existing}
$$

当 $\Delta A \le 0$ 时，按赛宾公式看已经不缺吸声；实际仍可能需要处理早期反射、驻波或局部反射面。

## 4. 适用边界

- 适合早期方案估算，不适合当作小房间精确声学校准。
- 默认声场足够[[方向/AI语音/知识/基础概念/扩散声场（Diffuse Sound Field）|扩散]]，吸声分布相对均匀。
- 平均吸声系数较高时，赛宾公式会变粗糙；常用 Eyring 公式作修正。
- 公式不直接建模声源/听音位置、散射、空气吸收、房间模态和几何反射路径。

## 5. 和 Eyring 公式的关系

Eyring 公式常写作：

$$
T_{60} \approx \frac{0.161V}{-S\ln(1-\bar{\alpha})}
$$

其中 $S$ 是总表面积，$\bar{\alpha}=A/S$。当 $\bar{\alpha}$ 很小时，$-\ln(1-\bar{\alpha}) \approx \bar{\alpha}$，Eyring 公式会退化到赛宾公式。

## 6. 关键来源

- [MathWorks - Model, Evaluate, and Design Acoustic Spaces](https://www.mathworks.com/help/audio/ug/model-evaluate-and-design-acoustic-spaces.html)
  - 内容定位：给出 Sabine equation、RT60 定义、公式变量和适用限制。
  - 用途：工程实现和参数说明入口。
  - 核验日期：2026-07-28
- [Open Library - Wallace Clement Sabine, Collected Papers on Acoustics](https://openlibrary.org/books/OL23289190M/Collected_papers_on_acoustics)
  - 内容定位：Sabine 声学论文集的公共书目入口。
  - 用途：历史源头和原始文献追索。
  - 核验日期：2026-07-28
- [Arup Strutt - Reverberation Time](https://strutt.arup.com/help/Building_Acoustics/RTInsert.htm)
  - 内容定位：Sabine、Eyring 等混响时间估算公式的工程说明。
  - 用途：核对扩散声场、低/高平均吸声条件下的适用边界。
  - 核验日期：2026-07-28

## 7. 相关对象

- [[方向/AI语音/知识/基础概念/Reverberation Modeling（混响建模）|混响建模]]：赛宾公式是从房间几何和吸声量估计 T60 的入口公式。
- [[方向/AI语音/知识/基础概念/ESS（Exponential Sine Sweep）|ESS]]：ESS 可实测 IR/RIR；赛宾公式则是从几何和材料参数做粗估。

## 8. 待验证

- 小房间语音会议场景里，赛宾估算和实测 ESS / MLS 得到的 RT60 偏差通常有多大。
- 语音增强训练数据合成时，直接采样 T60 和从材料/房间参数推 T60 哪种更贴近真实采集分布。

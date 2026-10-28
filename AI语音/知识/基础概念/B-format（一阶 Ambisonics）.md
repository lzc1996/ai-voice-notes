---
title: B-format（一阶 Ambisonics）
类型: 概念
相关主题:
  - 阵列信号
  - 空间音频
aliases:
  - B-format
  - B-Format
  - FOA
  - First-Order Ambisonics
  - First Order Ambisonics
  - 一阶 Ambisonics
  - 一阶全景声
tags:
  - 类型/对象
  - 方向/AI语音
  - 主题/阵列信号
  - 主题/空间音频
---
# B-format（一阶 Ambisonics）

## 0. 背景

**1) 问题出现时**：1970 年代 Soundfield 麦克风体系要实现含高度的环绕声（periphony），需要一种把声场压缩到极少数通道、且与扬声器布局解耦的传输表示。Gerzon 1973 的 periphony 论文给出 W/X/Y/Z 四分量方案：1 个全指向声压分量加 3 个正交 8 字形声压梯度分量，恰好对应一阶球谐的 4 个基函数——这就是 B-format 的源头。

**2) 名称来历与之后的谱系**：字母 B 来自 Soundfield 麦克风的信号链——A-format 是四胶囊阵列的原始信号，经编码矩阵转换为系数域的 B-format（A/B 按处理阶段排序）。其后：通道排序与归一化被 [[方向/AI语音/知识/基础概念/FuMa（Furse-Malham 编码约定）|FuMa 约定]] 捆绑成事实交换标准（`.amb` 文件载体）；向高阶推广即 [[方向/AI语音/知识/基础概念/Higher-Order Ambisonics（高阶 Ambisonics）|HOA]]，B-format 是其 $N=1$ 特例；2011 年 [[方向/AI语音/知识/基础概念/AmbiX（Ambisonics 交换格式）|ambiX 提案]]（ACN + SN3D）取代 FuMa 成为现代载体，进入 VR/360° 工具链；如今 B-format 形态仍是公开数据集（[[方向/AI语音/数据集/C4DM RIR|C4DM RIR]] 等）的常见格式，并被 Array-Agnostic SE、[[方向/AI语音/模型/Adaptive Rotary Steering（自适应旋转转向）|Adaptive Rotary Steering]] 等选作规范空间输入。

## 1. 身份

B-format 是**一阶 Ambisonics（FOA，First-Order Ambisonics）**的经典通道格式：用 4 个通道描述空间参考点附近的一阶球谐声场——1 个全指向分量 W 加 3 个正交一阶指向性分量 X / Y / Z。$(N+1)^2$ 在 $N=1$ 时正好是 4。

边界：

- 它是 [[方向/AI语音/知识/基础概念/Ambisonics（球谐声场）|Ambisonics]] 在 $N=1$ 时的具体通道形态，不是另一套表示体系；二阶及以上是 [[方向/AI语音/知识/基础概念/Higher-Order Ambisonics（高阶 Ambisonics）|HOA]]。
- 它是**场景表示**，不是麦克风信号：B-format 通道由阵列录音经编码得到（Soundfield 类专用麦克风可直接输出），不直接对应某一只麦克风的波形。
- 它不是完整的三维声场描述：只有 4 个自由度，空域分辨率受一阶硬约束（见 §5）。

## 2. 通道与信号含义

| 通道 | 指向性 | 物理含义 |
| ---- | ------ | -------- |
| W | 全指向 | 声压（球谐 $n=0$ 分量） |
| X | 8 字形，前后 | 前后方向的声压梯度 |
| Y | 8 字形，左右 | 左右方向的声压梯度 |
| Z | 8 字形，上下 | 上下方向的声压梯度 |

W 不是"普通[[方向/AI语音/知识/基础概念/Omni Mic（全向麦克风）|全向麦]]"：在 FuMa 约定下它带 $1/\sqrt{2}$ 缩放（见 §3），直接当 omni 参考通道用会和 X/Y/Z 的比例对不上。

三维 B-format 是 4 通道 $(W,X,Y,Z)$；历史上的水平面版本只有 $(W,X,Y)$ 三通道，与三维 4 通道不是同一对象，数据集标注时需区分。

## 3. 编码约定：FuMa 与 AmbiX

同一组 4 个系数，工程上有两套常见约定，互操作时必须**同时对齐通道顺序、归一化和 W 缩放**。两套约定的完整定义已拆至独立页：[[方向/AI语音/知识/基础概念/FuMa（Furse-Malham 编码约定）|FuMa（Furse-Malham 编码约定）]] 与 [[方向/AI语音/知识/基础概念/AmbiX（Ambisonics 交换格式）|AmbiX（Ambisonics 交换格式）]]。

| 约定 | 通道顺序 | 归一化 | 典型出处 |
| ---- | -------- | ------ | -------- |
| FuMa（Furse-Malham） | W, X, Y, Z | maxN，W 带 $1/\sqrt{2}$ | 早期 Soundfield 录音、C4DM RIR 等老数据集 |
| AmbiX（ACN + SN3D） | W, Y, Z, X | SN3D，一阶 4 通道系数均为 1 | 现代 VR/360° 工具链与多数开源库 |

- **ACN 排序**规则是 $\mathrm{index}=n^2+n+m$；一阶 $m=-1,0,+1$ 依次对应 Y、Z、X，所以 ACN 顺序是 **W, Y, Z, X**，不是 W, X, Y, Z。按 FuMa 顺序读 AmbiX 文件，X/Y/Z 会整体错位。
- **归一化**：一阶下 SN3D 与 FuMa 只差 W 的 $\sqrt{2}$；N3D 相对 SN3D 再乘 $\sqrt{2n+1}$（一阶为 $\sqrt{3}$）。混用会改变各通道相对权重，下游模型学到的空间线索随之变形。
- **FuMa → AmbiX 常用换算**：通道重排 $W,X,Y,Z \rightarrow W,Y,Z,X$，W 乘 $\sqrt{2}$（精确系数见 §7 待验证）。

## 4. 在语音系统里的位置

```text
球面阵 / 可编码阵列录音（或 Soundfield 麦克风）
  -> 一阶球谐编码（各通道 × 球谐基权重求和）
  -> B-format 4 通道系数
  -> 在系数域做 SE / TSE / DOA / 声源跟踪
  -> 双耳解码（HRTF）或扬声器重放
```

- 与高阶同构：B-format 只是 $N=1$ 截断，编码器换高阶即得 [[方向/AI语音/知识/基础概念/Higher-Order Ambisonics（高阶 Ambisonics）|HOA]]；以 B-format 训练的模型可视为 HOA 管线的低阶特例，但**不能**据此推断其在高阶下的表现。
- 与阵列无关性：B-format 系数本身不含阵列几何，是 [[方向/AI语音/知识/技术路线/Array-Agnostic SE（阵列无关语音增强）|Array-Agnostic SE]] 选用的规范空间之一；但把真实阵列编码成 B-format 仍依赖麦克风几何与标定。

## 5. 使用注意

- **分辨率受一阶硬约束**：3 个一阶指向性只给出粗略方向信息，前后、上下的精细区分有限；要更高分辨率必须升阶到 HOA。
- **空间混叠**：有效阶数与 $kr$ 相关，高频段一阶表示会失真；可用带宽还受阵列孔径限制。
- **通道顺序踩坑**：数据集里的"B-format"可能指 FuMa WXYZ（如 C4DM RIR），也可能指 AmbiX WYZX；加载前先确认，错了不是"音质差一点"，而是空间信息错位。
- **W 不能当 omni 参考**：FuMa 的 W 带 $1/\sqrt{2}$ 缩放，直接当 omni 通道会与 X/Y/Z 失配。
- **老数据集的现实**：C4DM RIR 这类 2010 年前后的数据是 FuMa；现代工具链默认 AmbiX，接管线时要显式转换。

## 6. 相关对象

- [[方向/AI语音/知识/基础概念/Ambisonics（球谐声场）|Ambisonics]]：上位体系；B-format 是其 $N=1$ 形态。
- [[方向/AI语音/知识/基础概念/FuMa（Furse-Malham 编码约定）|FuMa]]：B-format 一阶素材最常见的遗留编码约定（WXYZ + maxN）。
- [[方向/AI语音/知识/基础概念/AmbiX（Ambisonics 交换格式）|AmbiX]]：B-format 一阶素材的现代编码方式（ACN + SN3D）。
- [[方向/AI语音/知识/基础概念/Higher-Order Ambisonics（高阶 Ambisonics）|HOA]]：$N\ge2$ 的推广，通道数 $(N+1)^2$。
- [[方向/AI语音/知识/基础概念/Spherical Harmonics（球谐函数）]]：B-format 4 通道对应的球谐基函数。
- [[方向/AI语音/数据集/C4DM RIR]]：以 FuMa B-format 记录的真实 RIR 数据集。
- [[方向/AI语音/模型/Adaptive Rotary Steering（自适应旋转转向）]]：固定 FOA（$N=1$）做旋转转向与 TSE 的模型，B-format 是其输入表示。
- [[方向/AI语音/知识/基础概念/Array Audio Signal（阵列音频信号）]]：编码之前的原始多通道输入。
- [[方向/AI语音/知识/基础概念/Beamforming（波束形成）|Beamforming]]：方向中心方案，与场景中心的 B-format 相对。

## 7. 关键来源

- [Ambisonics: A Practical 3D Audio Theory for Recording, Studio Production, Sound Reinforcement, and Virtual Reality — Zotter & Frank, SpringerOpen 2019](https://link.springer.com/book/10.1007/978-3-030-17207-7)
  - 内容定位：Ambisonics 系统教材，覆盖球谐编码、FuMa/AmbiX 约定、ACN/SN3D/N3D 归一化与一阶解码。
  - 用途：本页通道约定与归一化说明的主要依据。
  - 核验日期：2026-10-15
- [Periphony: With-Height Sound Reproduction — M. A. Gerzon, JAES vol. 21, no. 1, pp. 2–10 (1973)](https://aes2.org/publications/elibrary-page/?id=2012)
  - 内容定位：一阶含高度环绕声体系的原始论文，W/X/Y/Z 四分量的源头。
  - 用途：通道定义与术语出处。
  - 核验日期：2026-10-15
- [Database of Omnidirectional and B-Format Room Impulse Responses — Stewart & Sandler, ICASSP 2010](https://ieeexplore.ieee.org/document/5495703)
  - 内容定位：同时发布全指向与 B-format RIR 的真实测量数据集论文。
  - 用途：真实数据集中 B-format（FuMa WXYZ）的实例依据。
  - 核验日期：2026-10-15

## 8. 待验证

- 编码约定拆分进度：FuMa 已拆出独立页（2026-10-26）；ACN 已有独立页；SN3D 归一化暂由 ACN 页 §2 承载，出现跨领域复用再拆。
- FuMa → AmbiX 的精确换算（W 缩放因子与通道重排）需对照 ambiX 规范原文或 Zotter & Frank 的换算表逐项核实，再作为实现依据（FuMa 页 §7 同此待验证）。
- 水平面 2D B-format（W/X/Y）在具体数据集标注中的区分，尚未在本 vault 中核实过数据源。

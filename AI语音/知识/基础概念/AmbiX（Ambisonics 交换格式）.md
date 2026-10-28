---
title: AmbiX（Ambisonics 交换格式）
类型: 概念
相关主题:
  - 空间音频
aliases:
  - AmbiX
  - ambiX
  - ambiX 格式
  - Ambisonics exchangeable
  - Ambisonics 交换格式
tags:
  - 类型/对象
  - 方向/AI语音
  - 主题/空间音频
---
# AmbiX（Ambisonics 交换格式）

## 0. 背景

**1) 问题现场**：ambiX 提案论文（2011）开篇的场景——拿着自己的 Ambisonic 作品到现场，音响师面对陌生的通道排序、归一化和文件格式无法回放。当时 Ambisonics 发展了近四十年，社区对**如何归一化、存储和交换**数据始终没有一致约定；事实标准只有 `.amb` 容器 + [[方向/AI语音/知识/基础概念/FuMa（Furse-Malham 编码约定）|FuMa]] 编码，但它上限三阶 16 通道、受 WAV 容器 4GB 限制。

**2) 切入点**：Nachbar、Zotter、Deleflie、Sontacchi 在 Ambisonics Symposium 2011（Lexington, KY；作者单位含 IEM Graz）提出 ambiX（"Ambisonics exchangeable"）：ACN 排序 + SN3D 归一化 + CAF 容器（去掉 4GB 限制、支持任意阶），并为混合阶/降阶场景引入 adaptor matrix 扩展。

**3) 之后的谱系**：凭 SN3D"单点源峰值不超 0 阶通道"防削波的性质，被 Google YouTube 360 采纳为基础，随后 Resonance Audio、Meta XR Audio SDK、Unity、Apple 空间音频 API 相继采用 ACN+SN3D；IEM 插件套件、SPARTA、kronihias/ambix 等工具链使其成为 HOA 制作与存档的事实标准。

## 1. 身份

AmbiX 是 Ambisonics 数据交换的**现代格式规范**，由以下部分绑定组成：

- **通道排序**：[[方向/AI语音/知识/基础概念/ACN（Ambisonics 通道编号）|ACN]]，$\mathrm{ACN}(n,m)=n^2+n+m$，一阶即 W、Y、Z、X。
- **归一化**：SN3D（Schmidt 半归一化），任一点源峰值不超过 0 阶（W）通道电平。
- **容器**：Apple Core Audio Format（`.caf`），任意阶 $(N+1)^2$ 通道，无 4GB 限制。
- **扩展**：adaptor matrix——可配置矩阵，对混合阶/降阶信号集做重排、补全、重归一化或嵌入到默认 periphonic 通道集。

边界：

- 与 [[方向/AI语音/知识/基础概念/ACN（Ambisonics 通道编号）|ACN]] 的区分：ACN 只是**排序约定**（一个轴），AmbiX 是**完整格式**（排序 + 归一化 + 容器 + 元数据），与 FuMa 捆绑 WXYZ+maxN 的结构对称。
- 它是格式规范，不是声场表示或算法；说"AmbiX 文件"指按此规范编码的多通道音频。
- 严格意义的 AmbiX 用 SN3D；部分工具/库内部用 ACN+N3D（如 SuperCollider HOA 库），二者差每通道 $\sqrt{2n+1}$ 因子，交换时需确认（见 §4）。

## 2. 格式构成

| 维度 | 规定 | 说明 |
| ---- | ---- | ---- |
| 排序 | ACN（W, Y, Z, X, …） | 见 ACN 页 §1 映射公式与对照表 |
| 归一化 | SN3D | 增益公式见 ACN 页 §2；选择动机是单点源峰值不超 W，防高阶通道削波 |
| 容器 | CAF（`.caf`） | 也常见于普通多通道 WAV + 元数据声明的工程变体 |
| 扩展 | adaptor matrix | 混合阶/受限重放几何（半球、水平环）下降阶复用 |

## 3. 与 FuMa 的对照与转换

| 维度 | AmbiX | [[方向/AI语音/知识/基础概念/FuMa（Furse-Malham 编码约定）|FuMa]] |
| ---- | ---- | ---- |
| 排序 | W, Y, Z, X（ACN） | W, X, Y, Z |
| 归一化 | SN3D | maxN |
| 阶数支持 | 任意阶 | 定义到三阶 |
| 容器 | CAF（无 4GB 限制） | `.amb`（WAV，4GB 上限） |
| 现状 | 事实标准 | 遗留格式 |

一阶 FuMa → AmbiX：通道重排 $W,X,Y,Z \rightarrow W,Y,Z,X$，W 乘 $\sqrt{2}$（精确系数与高阶换算见 FuMa 页 §7 待验证）。

## 4. 现状与工程注意

- **平台与工具默认 AmbiX**：YouTube 360 要求 ACN/SN3D 布局（一阶 W,Y,Z,X）；Resonance Audio、Meta XR Audio SDK、Unity、Apple 空间音频 API、IEM 插件套件、SPARTA 均按此约定。
- **SN3D vs N3D 混用**：库内部约定不一（有的用 ACN+N3D），差 $\sqrt{2n+1}$ 逐通道因子；错了一阶下不一定立刻可闻，高阶下空间线索系统性变形。
- **经验法则**：制作与存档一律用 AmbiX；FuMa 仅用于兼容遗留素材。
- **数据集核对**：老数据集（如 C4DM RIR）是 FuMa；新 Ambisonic 数据集多为 AmbiX，加载前显式确认。

## 5. 相关对象

- [[方向/AI语音/知识/基础概念/ACN（Ambisonics 通道编号）|ACN]]：AmbiX 排序轴的来源约定，SN3D 公式亦由其承载。
- [[方向/AI语音/知识/基础概念/FuMa（Furse-Malham 编码约定）|FuMa]]：遗留对手格式，本页对照表的另一侧。
- [[方向/AI语音/知识/基础概念/Ambisonics（球谐声场）|Ambisonics]]：AmbiX 所约定的信号域。
- [[方向/AI语音/知识/基础概念/Higher-Order Ambisonics（高阶 Ambisonics）|HOA]]：AmbiX 是 HOA 文件与工具链的主流承载格式。
- [[方向/AI语音/知识/基础概念/B-format（一阶 Ambisonics）|B-format]]：一阶信号集本身；AmbiX 是其现代编码方式，FuMa 是其遗留编码方式。
- [[方向/AI语音/知识/技术路线/Adaptive Rotary Steering（自适应旋转转向）|Adaptive Rotary Steering]]：按 ACN 向量化做声场旋转的使用处。

## 6. 关键来源

- [Nachbar, Zotter, Deleflie & Sontacchi, "AMBIX - A SUGGESTED AMBISONICS FORMAT", Ambisonics Symposium 2011, Lexington (KY)](https://ambisonics.iem.at/proceedings-of-the-ambisonics-symposium-2011/ambix-a-suggested-ambisonics-format)
  - 内容定位：ambiX 原始提案，命名（Ambisonics exchangeable）、ACN+SN3D 动机、adaptor matrix 与 IEM 概念实现的出处。
  - 用途：§0/§1/§2 的主要依据；同时核实了 ACN 页作者名单存疑项。
  - 核验日期：2026-10-26
- [Ambisonics: A Practical 3D Audio Theory for Recording, Studio Production, Sound Reinforcement, and Virtual Reality — Zotter & Frank, SpringerOpen 2019](https://link.springer.com/book/10.1007/978-3-030-17207-7)
  - 内容定位：AmbiX/FuMa 约定与 SN3D/N3D/maxN 归一化的系统教材。
  - 用途：§3 对照与换算口径。
  - 核验日期：2026-10-26
- [Ambisonics（社区维基条目，含 YouTube/Resonance/Meta XR 采用情况）](https://handwiki.org/wiki/index.php?title=Engineering:Ambisonics)
  - 内容定位：AmbiX 作为现行 B-format 标准格式、SN3D 被 YouTube 360 采纳、各平台工具链采用情况的次级来源。
  - 用途：§0 谱系与 §4 平台采用情况；次级来源，逐项未核各平台官方文档。
  - 核验日期：2026-10-26

## 7. 待验证

- `.caf` 容器内元数据的具体组织方式与 adaptor matrix 的规格细节未对照论文原文逐节核实。
- 各平台（YouTube/Resonance/Meta XR/Apple）对 ACN+SN3D 的官方文档口径未逐个核对，目前依据社区维基转述。
- SN3D↔N3D 在具体工具（SPARTA/IEM/SuperCollider HOA 库）中的默认设置差异未实测确认。

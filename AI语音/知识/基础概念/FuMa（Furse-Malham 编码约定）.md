---
title: FuMa（Furse-Malham 编码约定）
类型: 概念
相关主题:
  - 空间音频
aliases:
  - FuMa
  - FuMa 约定
  - Furse-Malham
  - Furse-Malham 约定
  - Furse-Malham format
tags:
  - 类型/对象
  - 方向/AI语音
  - 主题/空间音频
---
# FuMa（Furse-Malham 编码约定）

## 0. 背景

**1) 问题出现时**：Ambisonics 作为场景中心表示（见 [[方向/AI语音/知识/基础概念/Ambisonics（球谐声场）|Ambisonics]]）从 1970 年代 Soundfield 麦克风体系发展而来，但球谐系数交换时**通道按什么排、每个通道乘多大增益**长期没有统一标准。一阶含高度（periphonic）信号的 W/X/Y/Z 四通道命名经 Gerzon 1973 起的实践与 Malham & Myatt 1995 的 3D Ambisonics 工作固化，逐渐形成事实约定。

**2) 之后的谱系**：2001 年 Richard Dobson 提出的 `.amb` 文件格式强制采用这套编码，使其成为当时的事实标准；2011 年 [[方向/AI语音/知识/基础概念/AmbiX（Ambisonics 交换格式）|ambiX 格式提案]]（Nachbar, Zotter 等，IEM）用 ACN 排序 + SN3D 归一化取代之，成为现代主流（排序轴见 [[方向/AI语音/知识/基础概念/ACN（Ambisonics 通道编号）|ACN]]）。此后 FuMa 退居遗留格式，主要存身于老数据集与 `.amb` 文件。社区以 Richard Furse 与 Dave Malham 两人命名这套约定（Furse-Malham，缩写 FuMa）。

## 1. 身份

FuMa 是 Ambisonics 数据交换的**遗留编码约定**，由两部分绑定组成：

- **通道排序**：Furse-Malham 排序，通道按非线性字母命名分组排列——$\mathrm{WXYZ}\mid \mathrm{RSTUV}\mid \mathrm{KLMNOPQ}$（一阶 4 通道、二阶 5 通道、三阶 7 通道，共 16 通道）。
- **归一化**：maxN——每个分量归一化到单声源 pan 时增益不超过 1.0（见 §2）。

边界：

- 它是**约定层**（排序 + 归一化），不是声场表示本身；其承载的信号在一阶下就是 [[方向/AI语音/知识/基础概念/B-format（一阶 Ambisonics）|B-format]] 4 通道。
- 排序轴上与 ACN 相对，归一化轴上与 SN3D/N3D 相对——FuMa 把一套特定排序和特定归一化**捆绑**成一个格式，AmbiX（ACN+SN3D）同理；这是它与现代约定最本质的差别。
- 排序本身明确定义到三阶（16 通道）；三阶以上无统一扩展方案。实际工程与数据集中说"FuMa 素材"绝大多数指一阶 4 通道情形。

## 2. 排序与归一化内容

通道对照（FuMa 序 vs 同组分量在 ACN 下的顺序）：

```text
FuMa = W X Y Z | R S T U V | K L M N O P Q
ACN  = W Y Z X | V T R S U | Q O M K L N P
```

- 一阶：FuMa 按 W、X、Y、Z 排；ACN 按 $\mathrm{ACN}(n,m)=n^2+n+m$ 得 W、Y、Z、X。按 FuMa 顺序读 AmbiX 文件，X/Y/Z 整体错位。
- maxN 归一化出自 Jérôme Daniel：数学上不"严格"，但限制单声源 pan 时各通道最大电平，对定点数字接口有工程优势（Malham 原话转述见关键来源）。一阶下 maxN 与 SN3D 只差 W 通道的 $1/\sqrt{2}$ 缩放。

## 3. 与 AmbiX 的对照与转换

| 维度 | FuMa | AmbiX（ACN + SN3D） |
| ---- | ---- | ---- |
| 排序 | W, X, Y, Z（…） | W, Y, Z, X（…） |
| 归一化 | maxN | SN3D |
| 阶数支持 | 定义到三阶，以上无统一扩展 | 任意阶 |
| 典型载体 | `.amb` 文件、老数据集 | 现代 VR/360° 工具链、SPARTA/IEM |
| 现状 | 遗留格式 | 事实标准 |

一阶 FuMa → AmbiX 常用换算：通道重排 $W,X,Y,Z \rightarrow W,Y,Z,X$，W 乘 $\sqrt{2}$；精确系数与二/三阶换算表仍待逐项核实（见 §7，并见 B-format 页 §8）。

## 4. 现状与工程注意

- **`.amb` 文件必为 FuMa**：Dobson 2001 定义的 `.amb`（WAVE_FORMAT_EXTENSIBLE 携带 Ambisonic 子类型 GUID）强制 FuMa 编码，遇到 `.amb` 直接按 ACN 读会错位。
- **老数据集是 FuMa 重灾区**：如 [[方向/AI语音/数据集/C4DM RIR|C4DM RIR]]（2010）为 FuMa WXYZ；现代工具链默认 AmbiX，接管线前显式确认与转换。
- **经验法则**（ICST 工作流口径）：制作与存档一律用 AmbiX，FuMa 仅用于兼容遗留素材。
- **错位后果**：排序与归一化同时错——声像旋转、翻转、响度错误，且一阶下不一定立刻可闻（详见 ACN 页 §2/§4）。

## 5. 相关对象

- [[方向/AI语音/知识/基础概念/Ambisonics（球谐声场）|Ambisonics]]：FuMa 所约定的信号域。
- [[方向/AI语音/知识/基础概念/B-format（一阶 Ambisonics）|B-format]]：FuMa 的主要载体；排序/归一化内容原合并于其 §3，本页为拆出的独立页。
- [[方向/AI语音/知识/基础概念/ACN（Ambisonics 通道编号）|ACN]]：排序轴上的现代对手约定，AmbiX = ACN + SN3D。
- [[方向/AI语音/知识/基础概念/AmbiX（Ambisonics 交换格式）|AmbiX]]：现代对手格式（ACN + SN3D + CAF 容器），本页对照表的另一侧。
- [[方向/AI语音/知识/基础概念/Higher-Order Ambisonics（高阶 Ambisonics）|HOA]]：FuMa 排序定义到三阶，与 HOA 低阶段重叠，三阶以上无 FuMa 统一方案。
- [[方向/AI语音/数据集/C4DM RIR|C4DM RIR]]：以 FuMa B-format 记录的真实 RIR 数据集实例。

## 6. 关键来源

- [Ambisonics: A Practical 3D Audio Theory for Recording, Studio Production, Sound Reinforcement, and Virtual Reality — Zotter & Frank, SpringerOpen 2019](https://link.springer.com/book/10.1007/978-3-030-17207-7)
  - 内容定位：FuMa 与 AmbiX 约定、ACN/SN3D/maxN 对比与换算的系统教材。
  - 用途：§2/§3 约定对照与换算口径的主要依据。
  - 核验日期：2026-10-26
- [Malham & Myatt, "3-D Sound Spatialization using Ambisonic Techniques", Computer Music Journal 19(4): 58–70, 1995](https://doi.org/10.2307/3680991)
  - 内容定位：3D（含高度）Ambisonics 实践的标志性论文，WXYZ 命名与解码实践固化的关键节点。
  - 用途：§0 背景中约定形成期的依据。
  - 核验日期：2026-10-26
- [Ambisonic data exchange formats（社区维基条目）](https://en.wikipedia.org/wiki/Ambisonic_data_exchange_formats)
  - 内容定位：FuMa 排序表（到三阶 WXYZ|RSTUV|KLMNOPQ）、maxN 归一化出处（Daniel）与 `.amb` 格式说明。
  - 用途：§1/§2 通道对照、maxN 属性与 §4 `.amb` 强制 FuMa 的依据；次级来源，逐项系数未核原文。
  - 核验日期：2026-10-26

## 7. 待验证

- "Furse-Malham" 这一名称的首次出处（何时、由谁提出缩写 FuMa）未核实，仅确认为社区通称。
- maxN 逐通道系数表（一阶以上）与 FuMa→AmbiX 二/三阶精确换算未逐项核实；维基条目自注其换算表源自 Chapman (2008) 且标注"under construction"，不可直接作实现依据。
- `.amb` 文件头细节（子类型 GUID、dwChannelMask=0 等）出自维基转述，未对照 Dobson 原始规范。

---
title: ACN（Ambisonics 通道编号）
类型: 概念
相关主题:
  - 空间音频
aliases:
  - Ambisonics Channel Numbering
  - ambisonics channel numbering
  - ACN
  - ACN 排序
  - Ambisonics 通道编号
tags:
  - 类型/对象
  - 方向/AI语音
  - 主题/空间音频
---
# ACN（Ambisonics 通道编号）

## 1. 身份

`ACN`（Ambisonics Channel Numbering）是 [[方向/AI语音/知识/基础概念/Ambisonics（球谐声场）|Ambisonics]] 多通道信号的**线性通道排序约定**：把二维球谐索引 $(n,m)$（阶数 $n$，次数 $m\in[-n,n]$）映射为单一通道序号

$$\mathrm{ACN}(n,m)=n^{2}+n+m$$

即通道按 $a_{00},\,a_{1,-1},\,a_{1,0},\,a_{1,1},\,a_{2,-2},\dots$ 依次排列。$N$ 阶声场共 $(N+1)^2$ 个通道，ACN 取 $0$ 到 $N^2+2N$（0 基；部分文献写作 $+1$ 的 1 基版本）。

ACN 出自 ambiX 格式提案（Nachbar, Zotter, Deleflie & Sontacchi, Ambisonics Symposium 2011, Lexington KY；作者单位含 IEM Graz）——[[方向/AI语音/知识/基础概念/AmbiX（Ambisonics 交换格式）|AmbiX 格式]] = ACN 排序 + SN3D 归一化，现为 HOA 文件与工具链（如 SPARTA、IEM 插件）的主流约定。

## 2. 关键区分：排序与归一化是两个独立轴

Ambisonics 通道约定有两个正交的维度，混淆二者是工程事故的主要来源：

- **排序轴（本页）**：通道按什么顺序排——ACN、[[方向/AI语音/知识/基础概念/FuMa（Furse-Malham 编码约定）|FuMa]]（WXYZ…）、SID 等。
- **归一化轴**：每个 $(n,m)$ 通道的增益尺度——SN3D、N3D、maxN（见 [[方向/AI语音/知识/基础概念/Legendre Functions（勒让德函数）|Legendre Functions]] 页归一化条目）。

SN3D（Schmidt 半归一化，AmbiX 采用）的通道增益：

$$g_{nm}^{\mathrm{SN3D}}=\begin{cases}1, & m=0\\[2pt] (-1)^{n}\sqrt{\dfrac{2\,(n-|m|)!}{(n+|m|)!}}, & m\neq 0\end{cases}$$

同一份 ACN 排序的信号，归一化从 SN3D 换成 N3D 后每个通道都差一个 $n,m$ 相关的增益因子——**只核对排序不核对归一化，解码结果系统性错误但不一定立刻可闻**。

## 3. 与其他排序约定的对照

| 约定 | 排序 | 归一化 | 范围 | 现状 |
| --- | --- | --- | --- | --- |
| **ACN**（AmbiX） | $n^2+n+m$ | SN3D | 任意阶 HOA | 主流（AmbiX/SPARTA/IEM） |
| FuMa（Furse-Malham） | W, X, Y, Z（非线性命名） | maxN（自约定） | 定义到三阶；三阶以上扩展不统一 | 遗留格式 |
| SID（Single Index Designation） | 另一套线性索引 | 与归一化无关 | 任意阶 | 少量工具使用 |

ETSI TR 126 918（沉浸式音频标准化技术报告）列举了上述约定；历史内容多为 FuMa，新管线多为 ACN/SN3D（AmbiX）。

## 4. 工程意义

- **工具互通**：文件头（如 AmbiX 的 `.amb` / ADM 元数据）声明 ACN+SN3D 后，编码器、渲染器、双耳化器才能无损对接。
- **错位风险**：把 FuMa 素材当 ACN 读（或反之）时通道顺序与增益同时错位——声像旋转、翻转、响度错误，且一阶内不一定明显。
- **向量化便利**：ACN 的线性索引让旋转矩阵呈块对角正交结构（[[方向/AI语音/知识/技术路线/Adaptive Rotary Steering（自适应旋转转向）|Adaptive Rotary Steering]] 页即按 ACN 向量化推导旋转）。
- **截断语义清晰**：ACN 下"只保留前 $(N+1)^2$ 个通道"即严格的 $N$ 阶截断，对应 [[方向/AI语音/知识/基础概念/ASM（Ambisonics 信号匹配编码）|ASM]] 的可编码条件 $(N_a+1)^2\le M$。

## 5. 关键来源

- Nachbar, Zotter, Deleflie & Sontacchi, "ambiX – A Suggested Ambisonics Format", Ambisonics Symposium 2011（IEM Graz）
  - 内容定位：ACN 排序与 SN3D 归一化的出处，AmbiX 格式定义。
  - 用途：§1 映射公式与 AmbiX = ACN+SN3D 口径。
  - 核验日期：2026-10-15
- [DAFx 2023 Proceedings（含 SN3D 归一化公式条目）](https://daafx23.create.aau.dk/wp-content/uploads/2023/09/DAFX23_Proceedings.pdf)
  - 内容定位：§2 SN3D 增益公式的直接来源（该论文式 11 口径）。
  - 用途：归一化轴公式。
  - 核验日期：2026-10-15
- ETSI TR 126 918（沉浸式音频技术报告）
  - 内容定位：ACN / FuMa / SID 等排序约定并列举证的来源。
  - 用途：§3 对照表。
  - 核验日期：2026-10-15

## 6. 相关对象

- [[方向/AI语音/知识/基础概念/Ambisonics（球谐声场）|Ambisonics]]：ACN 所约定的信号域。
- [[方向/AI语音/知识/基础概念/AmbiX（Ambisonics 交换格式）|AmbiX]]：以 ACN 为排序轴的完整交换格式（ACN + SN3D + CAF 容器）。
- [[方向/AI语音/知识/基础概念/FuMa（Furse-Malham 编码约定）|FuMa]]：排序轴上的遗留对手约定（WXYZ + maxN），其独立页含与 ACN 的通道对照表。
- [[方向/AI语音/知识/基础概念/Higher-Order Ambisonics（高阶 Ambisonics）|Higher-Order Ambisonics]]：通道规范条目，ACN/SN3D 是其 §通道规范 的内容。
- [[方向/AI语音/知识/基础概念/Legendre Functions（勒让德函数）|Legendre Functions]]：球谐基与归一化因子的数学来源。
- [[方向/AI语音/知识/技术路线/Adaptive Rotary Steering（自适应旋转转向）|Adaptive Rotary Steering]]：按 ACN 向量化做声场旋转的使用处。
- [[方向/AI语音/知识/基础概念/ASM（Ambisonics 信号匹配编码）|ASM]]：ACN 排序下 $(N+1)^2$ 通道计数对应其可编码条件。

## 7. 待验证

- SN3D 增益公式中 $(-1)^n$ 符号约定在不同文献间是否完全一致（与球谐函数 Condon-Shortley 相位的互动）未逐条核对。

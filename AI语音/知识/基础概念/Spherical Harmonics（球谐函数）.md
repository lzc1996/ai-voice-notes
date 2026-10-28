---
title: Spherical Harmonics（球谐函数）
类型: 概念
aliases:
  - Spherical Harmonic
  - Spherical Harmonics
  - 球谐函数
  - 球谐基函数
tags:
  - 类型/对象
  - 方向/AI语音
  - 主题/阵列信号
  - 主题/空间音频
---

# Spherical Harmonics（球谐函数）

## 1. 身份

球谐函数是定义在单位球面 $S^2$ 上的一组正交基函数，可用于表示随方向变化的函数。空间音频和阵列处理中，截断到有限阶的球谐展开构成 [[方向/AI语音/知识/基础概念/Ambisonics（球谐声场）|Ambisonics / HOA]] 的角向表示；球谐函数是基函数，球谐系数是对这些基函数的加权系数，两者不能混为一谈。

## 2. 复球谐函数

采用一组常见的正交归一复球谐约定。令 $n$ 为阶数、$m$ 为阶内索引（$n\ge 0$、$-n\le m\le n$），$\theta$ 为极角（余纬，$0\le\theta\le\pi$），$\phi$ 为方位角（$0\le\phi<2\pi$），$P_n^m$ 为[[方向/AI语音/知识/基础概念/Legendre Functions（勒让德函数）|关联勒让德函数]]；对 $m\ge 0$，一种常见定义为

$$
Y_n^m(\theta,\phi)=\sqrt{\frac{2n+1}{4\pi}\frac{(n-m)!}{(n+m)!}}\,P_n^m(\cos\theta)e^{im\phi}.
$$

在包含 Condon–Shortley 相位的约定下，负索引可由 $Y_n^{-m}=(-1)^m\overline{Y_n^m}$ 得到。不同学科和软件对相位、角度顺序、实/复基与归一化的约定可能不同，使用公式或系数前要先核对约定。

在上述正交归一约定下，$\overline{Y}$ 表示复共轭，$d\Omega=\sin\theta\,d\theta\,d\phi$ 是球面立体角微元，$\delta$ 是 Kronecker delta：

$$
\int_{S^2}Y_n^m(\Omega)\overline{Y_{n'}^{m'}(\Omega)}\,d\Omega=\delta_{nn'}\delta_{mm'}.
$$

## 3. 球谐展开与阶数

令 $f(\Omega)$ 是单位球面上的平方可积角向函数，$c_{nm}$ 是其球谐系数，$N$ 是保留的最高阶，则有限阶展开为

$$
f(\Omega)\approx\sum_{n=0}^{N}\sum_{m=-n}^{n}c_{nm}Y_n^m(\Omega),
\qquad
c_{nm}=\int_{S^2}f(\Omega)\overline{Y_n^m(\Omega)}\,d\Omega.
$$

第 $n$ 阶有 $2n+1$ 个基函数；从 0 阶到 $N$ 阶一共 $\sum_{n=0}^{N}(2n+1)=(N+1)^2$ 个系数。因此提高阶数能表示更细的角向变化，但会增加通道数，实际可用空间分辨率还受阵列孔径、采样与空间混叠限制。

球谐基是球面 Laplace–Beltrami 算子的特征函数（$-\Delta_{\mathbb{S}^2}Y_n^m=n(n+1)Y_n^m$），因此球谐展开又称**球面傅里叶展开**：阶数 $n$ 与欧氏傅里叶的频率同位（都是"空间振荡快慢"），只是球面谱对每个 $n$ 简并出 $2n+1$ 个基。这一条是球谐与 [[知识wiki/Fourier Position Encoding（傅里叶位置编码）|欧氏傅里叶位置编码]] 能直接对话的原因，跨空间的三方对照（含 [[方向/AI语音/知识/基础概念/ASM（Ambisonics 信号匹配编码）|ASM]]）见 [[知识wiki/Basis Function Expansion（基函数展开）|Basis Function Expansion（基函数展开）]]。

## 4. 在空间音频中的作用

- **[[方向/AI语音/知识/基础概念/Higher-Order Ambisonics（高阶 Ambisonics）|HOA]] / Ambisonics**：将声场角向结构投影到有限组球谐基上，系数通道承载该展开；通道排序和缩放取决于所采用的编码约定。
- **声场展开**：三维声压场通常还含径向项（如球贝塞尔或球汉克尔函数）；$Y_n^m$ 描述角向部分，本身不包含麦克风位置、径向传播或阵列校准。
- **旋转**：对声场作整体旋转时，同一阶的一组系数按相应的 Wigner-D 矩阵变换；这使球谐表示适合旋转等变的空间音频处理。

## 5. 相关对象

- [[方向/AI语音/知识/基础概念/Legendre Functions（勒让德函数）]]：球谐函数的极角项由关联勒让德函数构成。
- [[方向/AI语音/知识/基础概念/Ambisonics（球谐声场）]]：HOA / Ambisonics 使用截断球谐展开表示声场。
- [[方向/AI语音/知识/基础概念/ASM（Ambisonics 信号匹配编码）]]：把阵列观测编码为球谐系数。
- [[方向/AI语音/模型/WG-Auto-HOA]]：其声场展开和远场导向矢量使用球谐基函数。
- [[方向/AI语音/知识/基础概念/Array Aperture（阵列孔径）]]：阵列孔径限制可实现的空间分辨率。

## 6. 关键来源

- [Ambisonics: A Practical 3D Audio Theory for Recording, Studio Production, Sound Reinforcement, and Virtual Reality](https://link.springer.com/book/10.1007/978-3-030-17207-7)
  - 内容定位：Ambisonics 教材，覆盖球谐展开、编码、阶数与空间分辨率。
  - 用途：空间音频中球谐基与 HOA 系数表示的参考；该来源已在 [[方向/AI语音/知识/基础概念/Ambisonics（球谐声场）]] 中记录。
  - 核验日期：2026-10-15（沿用关联笔记的来源核验日期，未在本次重新访问）

## 7. 待验证

- 实际处理链采用实球谐还是复球谐、角度定义和归一化约定；不同约定下系数不可直接混用。
- 当前阵列与目标频段下可可靠使用的最高阶数，以及截断对方向分辨率和编码误差的影响。

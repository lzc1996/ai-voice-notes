---
title: Legendre Functions（勒让德函数）
类型: 概念
aliases:
  - Legendre Function
  - Legendre Functions
  - Legendre Polynomial
  - Legendre Polynomials
  - Associated Legendre Function
  - Associated Legendre Functions
  - 勒让德多项式
  - 关联勒让德函数
  - 连带勒让德函数
tags:
  - 类型/对象
  - 方向/AI语音
  - 主题/阵列信号
  - 主题/空间音频
---

# Legendre Functions（勒让德函数）

## 1. 身份

勒让德函数是勒让德微分方程及其推广方程的解，常见于球坐标下的变量分离。设 $x$ 为自变量，$\nu$ 为次数（degree），$\mu$ 为阶数（order），$y(x)$ 为方程解，则勒让德方程和关联勒让德方程分别为

$$
(1-x^2)y''(x)-2xy'(x)+\nu(\nu+1)y(x)=0,
$$

$$
(1-x^2)y''(x)-2xy'(x)+\left[\nu(\nu+1)-\frac{\mu^2}{1-x^2}\right]y(x)=0.
$$

当次数 $\nu=n$ 是非负整数、阶数 $\mu=0$ 时，第一类解是勒让德多项式 $P_n(x)$；当 $n$ 为非负整数且 $m$ 是满足 $0\le m\le n$ 的整数时，第一类关联解记为 $P_n^m(x)$。更一般的次数和阶数下，还有第一类、第二类及其关联形式。本页重点记录球谐函数中使用的整数次数、整数阶数情形。

## 2. 勒让德多项式

对非负整数 $n$，第一类勒让德多项式可由 Rodrigues 公式定义：

$$
P_n(x)=\frac{1}{2^n n!}\frac{d^n}{dx^n}(x^2-1)^n.
$$

例如 $P_0(x)=1$、$P_1(x)=x$、$P_2(x)=\frac{1}{2}(3x^2-1)$。在区间 $[-1,1]$ 上，不同次数的勒让德多项式正交。令 $k$ 为另一个非负整数，$\delta_{nk}$ 为 Kronecker delta：

$$
\int_{-1}^{1}P_n(x)P_k(x)\,dx=\frac{2}{2n+1}\delta_{nk}.
$$

## 3. 关联勒让德函数

对整数 $n\ge 0$ 和 $0\le m\le n$，采用包含 Condon–Shortley 相位的约定时，关联勒让德函数定义为

$$
P_n^m(x)=(-1)^m(1-x^2)^{m/2}\frac{d^m}{dx^m}P_n(x),\qquad -1\le x\le 1.
$$

这里 $m$ 是阶数，不是幂；$m=0$ 时退化为 $P_n(x)$。在 $[-1,1]$ 上，NIST DLMF 将这类函数记为 Ferrers 函数 $\mathsf{P}_n^m(x)$，而许多教材和工程文献简写为 $P_n^m(x)$。

该函数满足关联勒让德方程：

$$
(1-x^2)\frac{d^2P_n^m}{dx^2}-2x\frac{dP_n^m}{dx}+\left[n(n+1)-\frac{m^2}{1-x^2}\right]P_n^m(x)=0.
$$

相位约定会改变符号。例如在上述约定下 $P_1^1(x)=-\sqrt{1-x^2}$；有些定义省略 $(-1)^m$，此时对应函数整体相差 $(-1)^m$。引用球谐函数公式时，应同时核对关联勒让德函数的相位与球谐函数的归一化，而不能只看符号 $P_n^m$。

## 4. 与球谐函数的关系

球谐函数将角向依赖拆为极角部分与方位角部分。令 $\theta$ 为余纬（$0\le\theta\le\pi$）、$\phi$ 为方位角，$Y_n^m$ 为球谐函数，则其结构可写为

$$
Y_n^m(\theta,\phi)\propto P_n^m(\cos\theta)e^{im\phi}.
$$

其中 $P_n^m(\cos\theta)$ 提供余纬方向的变化，$e^{im\phi}$ 提供方位角变化，比例因子由所选归一化决定。实球谐表达式也会使用同一关联勒让德函数，但可能采用正弦/余弦项和不同的角度定义。完整基函数见 [[方向/AI语音/知识/基础概念/Spherical Harmonics（球谐函数）|Spherical Harmonics]]。

## 5. 使用时的约定

- **次数与阶数**：球谐函数通常满足 $n\ge0$ 且 $|m|\le n$；$n$ 决定球谐阶，$m$ 是同一阶内的方位索引。
- **负阶**：上面的 Rodrigues 型定义写出的是 $0\le m\le n$；负阶通过负阶关联函数关系或球谐函数的共轭关系延拓，具体符号与系数取决于所用相位和归一化约定。
- **角度到自变量的映射**：以余纬 $\theta$ 表示方向时常用 $x=\cos\theta$；以仰角 $\epsilon$ 表示时可写为 $x=\sin\epsilon$。两者关系为 $\epsilon=\frac{\pi}{2}-\theta$，具体要看文献对角度的定义。
- **相位与归一化**：Condon–Shortley 相位、球谐归一化、实/复基和通道排序是不同约定；ACN/SN3D 等编码约定也不能仅由 $P_n^m$ 的定义推出。
- **函数种类**：部分文献把“勒让德函数”用于一般次数/阶数的 $P_\nu^\mu$、$Q_\nu^\mu$；“勒让德多项式”特指非负整数次数、零阶的 $P_n$。

## 6. 相关对象

- [[方向/AI语音/知识/基础概念/Spherical Harmonics（球谐函数）]]：关联勒让德函数构成球谐函数的极角部分。
- [[方向/AI语音/知识/基础概念/Ambisonics（球谐声场）]]：Ambisonics 以球谐系数表示声场角向结构。
- [[方向/AI语音/模型/Adaptive Rotary Steering（自适应旋转转向）]]：其实球谐基公式使用 $P_n^{|m|}(\sin\phi)$，其中 $\phi$ 表示仰角。
- [[方向/AI语音/模型/AmbiDrop]]：其球谐定义使用 $P_n^m(\cos\theta)$。

## 7. 关键来源

- [NIST Digital Library of Mathematical Functions, §14.2 Legendre’s Equation](https://dlmf.nist.gov/14.2)
  - 内容定位：勒让德方程与关联勒让德方程。
  - 用途：核对两类微分方程的形式。
  - 核验日期：2026-10-20
- [NIST Digital Library of Mathematical Functions, §14.6 Integer Order](https://dlmf.nist.gov/14.6)
  - 内容定位：整数阶 Ferrers 函数及其导数表示。
  - 用途：核对关联勒让德函数的定义与 Condon–Shortley 相位。
  - 核验日期：2026-10-20
- [NIST Digital Library of Mathematical Functions, §18.3 Classical Orthogonal Polynomials](https://dlmf.nist.gov/18.3)
  - 内容定位：经典正交多项式，包括勒让德多项式。
  - 用途：核对勒让德多项式的正交多项式性质。
  - 核验日期：2026-10-20
- [NIST Digital Library of Mathematical Functions, §18.5 Explicit Representations](https://dlmf.nist.gov/18.5)
  - 内容定位：经典正交多项式的显式表示。
  - 用途：核对勒让德多项式的 Rodrigues 公式。
  - 核验日期：2026-10-20

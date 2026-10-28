---
title: Higher-Order Ambisonics（高阶 Ambisonics）
类型: 概念
aliases:
  - HOA
  - Higher Order Ambisonics
  - High-Order Ambisonics
  - 高阶全景声
tags:
  - 类型/对象
  - 方向/AI语音
  - 主题/阵列信号
  - 主题/空间音频
---

# Higher-Order Ambisonics（高阶 Ambisonics）

## 1. 身份

Higher-Order Ambisonics（HOA）是在球谐基上表示三维声场的高阶 Ambisonics 形式，通常指二阶及以上（最高阶 $N\ge2$）。它是场景中心的声场表示，不是麦克风阵列类型，也不等于特定扬声器布局。广义的 [[方向/AI语音/知识/基础概念/Ambisonics（球谐声场）|Ambisonics]] 包含一阶与高阶形式；一阶 Ambisonics（FOA，$N=1$）有 4 个三维球谐通道，通常不称为 HOA。

令 $N$ 为保留的最高球谐阶，$n$ 为单个球谐函数的阶（$0\le n\le N$），$m$ 为该阶内的索引（$-n\le m\le n$）。完整三维展开包含

$$
M_{\mathrm{3D}}=\sum_{n=0}^{N}(2n+1)=(N+1)^2
$$

个球谐系数通道。因此二阶有 9 个、三阶有 16 个、四阶有 25 个通道。实际通道排序取决于所选编码规范，不能仅由阶数推断。

## 2. 信号表示

HOA 把某个空间参考点附近的声场投影到有限组角向基函数上。令 $p(\Omega,f)$ 为频率 $f$ 处、方向 $\Omega$ 上的声场角向函数，$a_{nm}(f)$ 为其第 $(n,m)$ 个球谐系数，$Y_n^m(\Omega)$ 为该方向上的球谐基函数，则截断到 $N$ 阶的角向表示为

$$
p(\Omega,f)\approx\sum_{n=0}^{N}\sum_{m=-n}^{n}a_{nm}(f)Y_n^m(\Omega).
$$

其中球谐函数是基，$a_{nm}$ 是基上的系数；基函数定义见 [[方向/AI语音/知识/基础概念/Spherical Harmonics（球谐函数）|Spherical Harmonics]]。从真实麦克风信号获得这些系数需要结合阵列几何与传感器响应进行编码或估计：

```text
麦克风信号 + 阵列几何 / 标定
  -> 球谐系数估计与阶数截断
  -> HOA 通道 a_nm
  -> 空间音频处理、旋转或解码
```

## 3. 阶数与通道数

- **完整三维展开**：每阶 $n$ 有 $2n+1$ 个系数，累计到 $N$ 阶为 $(N+1)^2$ 个通道。
- **水平二维展开**：只表示水平面内的角向变化，常见圆谐表示累计为 $2N+1$ 个通道；它与完整三维 HOA 的通道计数不能混用。
- **阶数折中**：提高 $N$ 可表示更精细的角向结构，但通道数、编码/解码计算量都会上升。实际可用阶数还受阵列孔径、麦克风数与布局、信噪比、标定误差及空间混叠限制。

## 4. 与相邻概念的边界

- **Ambisonics**：上位的场景中心表示体系；HOA 指其中二阶及以上的高阶展开，FOA 则是一阶特例，其通道格式见 [[方向/AI语音/知识/基础概念/B-format（一阶 Ambisonics）|B-format]]。
- **球谐函数**：构成展开的角向基；HOA 是用有限阶球谐系数表示声场的信号形式。
- **阵列无关性**：HOA 系数不直接绑定某一组麦克风通道，但把真实阵列编码到 HOA 仍依赖麦克风几何、标定和有效带宽。因此“在 HOA 域运行”不自动等于端到端跨阵列泛化。
- **通道规范**：[[方向/AI语音/知识/基础概念/ACN（Ambisonics 通道编号）|ACN]] 规定通道排序，SN3D/N3D 等规定归一化；这些是编码约定，不是 HOA 阶数本身。

## 5. 在 AI 语音中的用法

HOA 可作为语音增强、说话人提取、声源定位等模型的空间表示域。阵列输入先编码成球谐系数，模型再在系数域处理声场；换阵列时，编码前端仍需适配新的几何与校准。

- [[方向/AI语音/模型/WG-Auto-HOA]]：在 HOA 域进行移动目标说话人提取，并讨论 Ambisonics 阶数与麦克风编码条件。
- [[方向/AI语音/模型/Adaptive Rotary Steering（自适应旋转转向）]]：用 Ambisonics 系数做旋转转向；其已报告实验固定为 FOA，不能据此当作 HOA 高阶性能验证。
- [[方向/AI语音/知识/技术路线/Array-Agnostic SE（阵列无关语音增强）]]：将 Ambisonics / eigenbeam 作为几何无关规范空间的一类路线。

## 6. 相关对象

- [[方向/AI语音/知识/基础概念/Ambisonics（球谐声场）]]：包含 FOA、HOA 与 Ambisonics 编码/解码的上位概念页。
- [[方向/AI语音/知识/基础概念/Spherical Harmonics（球谐函数）]]：HOA 展开的角向基函数。
- [[方向/AI语音/知识/基础概念/Legendre Functions（勒让德函数）]]：关联勒让德函数构成球谐函数的极角部分。

## 7. 关键来源

- [Ambisonics: A Practical 3D Audio Theory for Recording, Studio Production, Sound Reinforcement, and Virtual Reality — Zotter & Frank, 2019](https://link.springer.com/book/10.1007/978-3-030-17207-7)
  - 内容定位：Ambisonics 教材，覆盖球谐表示、阶数、编码、解码与高阶解码。
  - 用途：本页 HOA 与球谐展开关系、阶数及通道数说明的主要参考；该来源也记录在 [[方向/AI语音/知识/基础概念/Ambisonics（球谐声场）]]。
  - 核验日期：2026-10-20
- [Replicating outdoor environments using VR and ambisonics: a methodology for accurate audio-visual recording, processing and reproduction — Georgiou et al., 2024](https://link.springer.com/article/10.1007/s10055-024-01003-1)
  - 内容定位：VR 场景的 Ambisonics 录制、处理与重放方法，涉及 HOA 场录及解码。
  - 用途：补充 HOA 在空间音频采集与再现中的应用背景。
  - 核验日期：2026-10-20

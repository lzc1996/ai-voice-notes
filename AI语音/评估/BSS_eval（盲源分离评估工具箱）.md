---
title: BSS_eval（盲源分离评估工具箱）
类型: 工具
发表时间: 2005
时间依据: BSS_EVAL Toolbox User Guide（Revision 2.0）技术报告年份；指标定义论文为 2006 年 IEEE TASLP
aliases:
  - BSS EVAL
  - bss_eval
  - 盲源分离评估
tags:
  - 类型/对象
  - 方向/AI语音
  - 任务/语音增强
  - 指标/信号保真
---

# BSS_eval（盲源分离评估工具箱）

## 0. 背景

**问题现场**：分离系统的输出允许对参考做一定滤波而不算失真，朴素误差度量无法区分目标、干扰、噪声与算法伪影四类失真来源。

**切入点**：Vincent 等提出允许有限长失真滤波器的投影分解框架，SDR/SIR/SAR/SNR 四指标口径至今是分离论文报告波形保真度的事实标准。

## 1. 身份

BSS_eval 是 IRISA/Inria 的 E. Vincent、C. Févotte、R. Gribonval 发布的 **MATLAB 工具箱 + 指标框架**（GPL 协议），用于（盲）源分离算法的客观评估。它定义的 SDR / SIR / SAR / SNR 四指标分解口径（Vincent et al., IEEE TASLP 2006）至今仍是语音分离论文报告波形保真度的事实标准。

边界：它是"怎么把估计信号拆成目标/干扰/噪声/伪影"的分解与度量框架，不是分离算法本身；现代深度学习实践里更多用的是它的 Python 移植（见第 4 节）。

## 2. 核心机制

数据流：

```text
估计源 ŝ + 参考源组 {s_j}
  -> 允许长度为 L 的失真滤波器（默认 512 tap），把 ŝ 投影到各参考子空间
  -> 分解 ŝ = s_target + e_interf + e_noise + e_artif
  -> 能量比取对数 -> SDR / SIR / SAR / SNR
```

分解细节是口径的一部分：目标、干扰、噪声各成分允许通过一个有限长的线性失真滤波器（即"允许分离系统对信号做一定的滤波而不算失真"），剩余无法解释的部分记为伪影 $e_{artif}$。四个指标的定义见 [[方向/AI语音/评估/SIR（信号干扰比）|SIR]] 页。v3.0（2008）起支持时变失真滤波器等扩展。

## 3. 版本与实现

- **原版 MATLAB 工具箱**：User Guide Revision 2.0（2005），工具箱 3.0 版（2008，E. Vincent 维护），GPL；入口函数 `bss_eval_sources` / `bss_eval_images` / `bss_eval_mix`。
- **mir_eval**（Python）：`mir_eval.separation.bss_eval_sources`，标准移植，分离论文常用。
- **fast_bss_eval**（Python/NumPy/PyTorch）：快速实现，支持逐样本/逐块、可微（可作损失），并提供 SI-SDR / SI-SIR 等尺度不变变体。
- **museval**：MUSDB 音乐分离基准的评估封装，同样基于 BSS_eval 口径。

## 4. 使用注意

- **口径来自实现参数**：失真滤波器长度、分窗/步长、是否零均值化都会影响数值；跨论文比较必须确认实现与参数。
- **SDR 的"half-baked"批评**：Le Roux et al. (ICASSP 2019) 指出 BSS_eval SDR 的口径混乱与尺度敏感性，推动了 [[SI-SDR]] 口径的普及——新工作报波形保真优先 SI 变体。
- 音乐噪声等伪影只看 SAR，干扰抑制只看 [[方向/AI语音/评估/SIR（信号干扰比）|SIR]]；单独报 SDR 会掩盖问题出在哪一项。
- 可微实现（fast_bss_eval）让指标可直接当训练损失，但训练目标口径与评测口径不一致时要防过拟合指标。

## 5. 相关对象

- [[方向/AI语音/评估/SIR（信号干扰比）|SIR]]：本工具箱定义的干扰抑制指标。
- [[SI-SDR]]：同一族指标的尺度不变现代化口径。
- [[方向/AI语音/知识/基础概念/SS（语音分离）|语音分离]]：主要应用场景。
- [[方向/AI语音/评估/语音增强评估指标体系|语音增强评估指标体系]]：指标地图入口。

## 6. 关键来源

- [BSS_EVAL Toolbox User Guide（Revision 2.0, HAL/Inria）](https://inria.hal.science/inria-00564760/en/)
  - 内容定位：工具箱用法、分解口径与引用方式的官方文档。
  - 用途：版本与许可（GPL）、入口函数的权威依据。
  - 核验日期：2026-09-30
- [Vincent, Gribonval, Févotte, "Performance measurement in blind audio source separation", IEEE TASLP 2006](https://ieeexplore.ieee.org/document/1643671)
  - 内容定位：SDR/SIR/SAR/SNR 分解的原始论文。
  - 用途：指标定义依据。
  - 核验日期：2026-09-30
- [fast_bss_eval（GitHub）](https://github.com/fakufaku/fast_bss_eval)
  - 内容定位：现代快速/可微 Python 实现，含 SI 变体。
  - 用途：本地实验的推荐实现候选。
  - 核验日期：2026-09-30
- [mir_eval（GitHub）](https://github.com/craffel/mir_eval)
  - 内容定位：标准 Python 移植（`mir_eval.separation`）。
  - 用途：与论文数字对齐时的参照实现。
  - 核验日期：2026-09-30

## 7. 待验证

- v3.0 的时变失真滤波器在现代语音分离评测中是否仍被使用（多数深度学习论文直接报 SI 变体）。
- 本地分离实验选 fast_bss_eval 还是 mir_eval：数值一致性与速度对比。

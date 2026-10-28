---
title: Direct Path（直达声）
类型: 概念
发表时间:
时间依据: 房间声学基础概念；非单一发表物
相关任务:
  - 语音增强
  - 去混响
  - 多通道增强
aliases:
  - Direct Path
  - direct path
  - Direct Sound
  - direct sound
  - 直达声
  - 直达路径
  - 直达声路径
tags:
  - 类型/对象
  - 方向/AI语音
  - 主题/房间声学
  - 主题/RIR
  - 主题/混响
---

# Direct Path（直达声）

## 1. 身份

`Direct Path`（直达声 / 直达路径）是声源发出的声音不经过墙面、桌面、天花板等反射，沿最短路径直接到达麦克风的那一部分。它通常是 [[方向/AI语音/知识/基础概念/Reverberation Modeling（混响建模）|RIR]] 中最先到达的峰，也是最接近原始语音内容的成分。

最小结构：

```text
RIR = direct path + early reflections + late reverberation
```

边界：direct path 不是 early reflections。Early reflections 是直达声之后几十毫秒内、经墙面或物体一次/少数几次反射到达的成分；direct path 没有经过反射。

## 2. 为什么重要

- **时间锚点**：early / late 分界通常从 direct path 到达点开始算，不是从 wav 文件开头算。
- **训练目标对齐**：[[方向/AI语音/模型/RE-USE]] 的 time-shifted anechoic target 就是把 dry speech 对齐到 direct path 的到达时间。
- **空间线索**：多麦阵列的 TDOA / IPD / DOA 最直接来自各麦克风 direct path 到达时间差。
- **距离信息**：direct path 与晚期混响的能量比形成 [[方向/AI语音/知识/基础概念/Reverberation Modeling（混响建模）|DRR]]，可反映说话人距离和房间混响强度。

## 3. 和 early reflections 的区别

| 成分 | 路径 | 时间位置 | 作用 |
|---|---|---|---|
| Direct path | 声源直接到麦克风 | 最早到达 | 最干净，决定时间对齐与主要空间线索 |
| Early reflections | 经墙面/桌面/天花板等少数反射 | 直达声后约 0–50 ms | 可增强响度和空间感，也可能造成梳状滤波 |
| Late reverberation | 大量多次反射 | 更晚的混响尾部 | 主要降低清晰度和 ASR 准确率 |

## 4. 采样点直觉

声源到麦克风距离为 $d$，声速为 $c$，direct path 延迟为：

$$
\tau_0=\frac{d}{c}
$$

采样率为 $f_s$ 时，对应采样点：

$$
n_0=\tau_0 f_s
$$

例：距离 1 m，声速约 343 m/s，延迟约 2.9 ms；16 kHz 下约 47 samples。

## 5. 相关对象

- [[方向/AI语音/知识/基础概念/Reverberation Modeling（混响建模）]]：direct path 是 RIR 三段结构的第一段。
- [[方向/AI语音/模型/RE-USE]]：用 direct-path aligned target 定义更合适的增强训练目标。
- [[方向/AI语音/知识/基础概念/ISM（Image Source Method，镜像声源法）]]：仿真 RIR 时，direct path 是零反射路径。
- [[方向/AI语音/知识/基础概念/DOA（到达方向）]]：direct path 到达时间差是方向估计的重要线索。
- [[方向/AI语音/知识/基础概念/IPD（通道间相位差）]]：direct path 贡献最稳定的相位差线索。

## 6. 待验证

- 目标评测/训练数据中 early target 截断窗口到底以 direct path、RIR 起点，还是文件起点为零点。
- 固定阵列增强中，direct path / early reflections / late reverberation 哪部分应作为最终 clean target。

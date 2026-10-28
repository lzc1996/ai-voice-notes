---
title: SPL（声压级）
类型: 概念
相关主题:
  - 声学
  - 音频处理
aliases:
  - Sound Pressure Level
  - sound pressure level
  - dB SPL
  - SPL
  - 声压级
  - 声压
tags:
  - 类型/对象
  - 方向/AI语音
  - 主题/声学
  - 主题/音频处理
---

# SPL（声压级）

## 1. 身份

`SPL`（Sound Pressure Level，声压级）是声学里衡量**空气声压大小**的对数刻度：把测得声压（RMS）与参考声压 $p_0$ 相比取对数。空气中参考声压为 **20 µPa**（$2 \times 10^{-5}$ Pa），对应人耳听阈，定义为 0 dB SPL。

最小公式：

$$
L_p = 20 \log_{10}\left(\frac{p}{p_0}\right), \quad p_0 = 20\ \mu\text{Pa}
$$

参考刻度速记：

| 声压 | dB SPL | 含义 |
|---|---|---|
| 20 µPa | 0 | 听阈（1 kHz） |
| 0.02 Pa | ≈ 60 | 1 米外正常对话 |
| 1 Pa | 94 | 声校准器标准输出（1 kHz） |
| 2 Pa | 100 | 现场音乐 / 嘈杂环境 |
| 65 Pa | ≈ 130 | 痛阈 |

## 2. 边界

- **dB SPL ≠ dBFS**：[[方向/AI语音/知识/基础概念/dBFS（满刻度分贝）|dBFS]] 是数字域相对满刻度的电平，无绝对声压意义；两者换算需要麦克风灵敏度、增益和校准。
- **dB SPL ≠ dBV / dBu**：dBV 参考 1 V RMS、dBu 参考 0.7746 V，是电压域刻度；麦克风灵敏度常用 dBV/Pa 把两者接起来。
- **dB SPL ≠ 响度（loudness）**：SPL 是物理量，响度是主观感知；同一声压级在不同频率听感不同（A 加权即为此而生）。
- **水下声学参考不同**：水听器常用 1 µPa 参考，比较时必须写清参考点。

## 3. 频率加权

- **A 加权（dBA）**：模拟人耳频率响应，噪声法规 / 健康标准主流口径（如工作场所 8 小时 85 dBA）。
- **C 加权（dBC）**：更平直，用于峰值 / 低频突出的噪声。
- **Z 加权**：无加权（flat）。

## 4. 工程用途

- **麦克风灵敏度**：dBV/Pa 表示 1 Pa（94 dB SPL）输入时输出的电压——0 dBV/Pa = 1 V RMS @ 94 dB SPL；典型驻极体 / MEMS 灵敏度约 −60 到 −22 dBu @ 94 dB SPL。用灵敏度 + 增益就能把数字电平换算回 dB SPL。
- **声学测量链**：[[方向/AI语音/知识/基础概念/TSP（Time-Stretched Pulse）|TSP]] / [[方向/AI语音/知识/基础概念/ESS（Exponential Sine Sweep）|ESS]] 测 RIR 前用声校准器（94 dB @ 1 kHz）标定，测量记录必须含声压级。
- **产品安全 / 合规**：耳机、助听器输出限值和环境噪声法规都按 dB SPL（dBA）定阈值。
- **动态范围评估**：设备底噪（dB SPL A）与最大声压级（如 120 dB SPL）之差决定可用动态范围。

## 5. 常见坑

- **参考点必须写清**：空气中 20 µPa、水下 1 µPa、dBV/Pa 的电压参考——漏写参考点数字就没意义。
- **RMS vs peak**：SPL 通常指 RMS 声压；峰值（如冲击声）另算，混用会差出十几 dB。
- **距离衰减**：自由场点源每加倍距离声压级 −6 dB——不写测量距离的 SPL 无法比较。
- **dB SPL 不是响度**：同样 60 dB SPL 的 100 Hz 与 4 kHz 音，主观响度差别很大；谈"听起来多响"用 dBA 或响度模型。

## 6. 关键来源

- [Sound pressure - Wikipedia](https://en.wikipedia.org/wiki/Sound_pressure)
  - 内容定位：声压与 SPL 的定义、20 µPa 参考、公式与常用参考值（0 dB 听阈、94 dB = 1 Pa、130 dB 痛阈）。
  - 用途：建立 SPL 定义与参考刻度口径。
  - 核验日期：2026-08-11
- [Sound pressure and decibels - Optimus Audio Academy](https://optimusaudio.com/en/academy/physical-acoustics/1448-sound-pressure-and-decibels)
  - 内容定位：声压与 dB 的工程解释，含 dBV/Pa 麦克风灵敏度换算。
  - 用途：确认麦克风灵敏度与 dB SPL 的工程换算口径。
  - 核验日期：2026-08-11

## 7. 相关对象

- [[方向/AI语音/知识/基础概念/Level（电平）]]：电平总入口，用来区分数字电平、声压级、电压电平和响度。
- [[方向/AI语音/知识/基础概念/dBFS（满刻度分贝）|dBFS]]：数字域电平刻度；与 dB SPL 换算需灵敏度 + 增益 + 校准。
- [[方向/AI语音/知识/基础概念/TSP（Time-Stretched Pulse）|TSP]]、[[方向/AI语音/知识/基础概念/ESS（Exponential Sine Sweep）|ESS]]：RIR 测量链，测量记录需含声压级。
- [[方向/AI语音/知识/基础概念/Reverberation Modeling（混响建模）|Reverberation Modeling]]：声学环境参数与声压测量同属测量场景。
- [[方向/AI语音/知识/基础概念/Audio Leakage（漏音）|Audio Leakage]]：漏音评估涉及声压级测量。

## 8. 待验证

- 当前采集链路上麦克风灵敏度、增益与 dB SPL 的换算是否已校准（近讲 vs 远场两套口径）。
- 耳机 / 助听输出安全限值（dB SPL）是否需要按产品目标单独记录。
- 噪声合规（85 dBA 等）阈值是否进入产品需求。

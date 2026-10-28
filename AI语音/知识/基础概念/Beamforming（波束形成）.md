---
title: Beamforming（波束形成）
类型: 概念
相关主题:
  - 阵列信号
  - 多通道增强
aliases:
  - Beamform
  - beamform
  - Beamforming
  - beamforming
  - Beamformer
  - beamformer
  - 波束形成
  - 波束赋形
  - 空间滤波
tags:
  - 类型/对象
  - 方向/AI语音
  - 主题/阵列信号
  - 主题/多通道增强
---
# Beamforming（波束形成）

## 1. 身份

Beamforming（波束形成）是在 [[方向/AI语音/知识/基础概念/Array Audio Signal（阵列音频信号）|麦克风阵列]] 上做的**空间滤波**：给每个麦克风通道施加延迟、相位或滤波权重，让目标方向的语音相干叠加，同时压低其他方向的噪声、回声或干扰说话人。

最小直觉：

```text
目标方向对齐 -> 多通道相加 -> 目标声增强 / 其他方向被抑制
```

边界：beamforming 不是 [[方向/AI语音/知识/基础概念/DOA（到达方向）|DOA]]，也不是完整语音增强系统。DOA 估计“声音从哪里来”；beamforming 用方向、阵列几何或时频 mask 生成空间滤波器；后面通常还要接 [[方向/AI语音/知识/基础概念/AEC（声学回声消除）]]、WPE、neural denoise、ASR 或 LLM。

## 2. 常见类型

- **Delay-and-Sum（DAS）**：按目标方向补偿各通道时延后相加；简单、稳、低延迟。
- **Filter-and-Sum**：每个通道先过滤波器再求和；频域多通道处理常用。
- **[[方向/AI语音/知识/基础概念/MVDR（最小方差无失真响应）|MVDR]]**：在保持目标方向无失真的约束下，最小化输出噪声功率；会议和远场 ASR 常见。
- **GSC**：把目标通道和阻塞矩阵 / 自适应噪声抵消组合起来，工程上可解释。
- **Neural beamformer**：用神经网络估计 mask、空间协方差或滤波权重，再交给 [[方向/AI语音/知识/基础概念/MVDR（最小方差无失真响应）|MVDR]] / WPD / neural post-filter。

## 3. 在语音系统里的位置

```text
multichannel waveform
  -> channel sync / gain / bad-channel check
  -> AEC（有播放参考时）
  -> VAD / DOA / speaker activity
  -> beamforming
  -> WPE / neural SE / post-filter
  -> enhanced mono / target stream
  -> ASR / audio LLM
```

Beamforming 的目标通常是把多通道输入压成一路更干净、更接近目标说话人的音频；它也可以输出多个方向的 beamformed streams，供 [[方向/AI语音/知识/基础概念/SS（语音分离）|SS]]、[[方向/AI语音/知识/基础概念/TSE（目标说话人提取）|TSE]] 或 directional ASR 使用。

## 4. 使用注意

- **先验条件很硬**：阵列几何、通道同步、采样率、麦克风顺序和增益都要可信。
- **近场/远场不同**：远场常用平面波方向；近场还要考虑距离和球面传播。
- **强混响会削弱方向性**：反射声会让空间谱变宽或多峰，常要配合 WPE / dereverberation。
- **移动声源要跟踪**：静态权重可能追不上走动说话人，需要 VAD / DOA tracking / adaptive update。
- **不是幻觉型生成**：beamforming 更偏保真前端，听感上限不一定最高，但内容改写风险低。

## 5. 和相邻概念的区别

| 概念                        | 作用      | 和 beamforming 的关系           |                                     |
| ------------------------- | ------- | --------------------------- | ----------------------------------- |
| [[方向/AI语音/知识/基础概念/DOA（到达方向）]]   | 估计声源方向                      | 可给 beamforming 提供目标方向               |
| [[方向/AI语音/知识/基础概念/AEC（声学回声消除）]] | 消除扬声器回声 | 通话链路里通常放在 beamforming 前后一起调 |                                     |
| [[方向/AI语音/知识/基础概念/WPE（加权预测误差）]]   | 多通道去混响                      | 常接在 beamforming 前后，处理晚期混响           |
| [[方向/AI语音/知识/基础概念/SS（语音分离）]]    | 拆多人语音                       | beamforming 可作为多通道分离前端或输出流          |
| [[方向/AI语音/知识/基础概念/TSE（目标说话人提取）]]   | 只提取目标说话人                    | 目标方向可作为 TSE clue，beamformer 可实现定向提取 |

## 6. 关键来源

- [Beamforming - MathWorks](https://www.mathworks.com/discovery/beamforming.html)
  - 内容定位：波束形成基础介绍，说明传感器阵列通过时延 / 相位控制强化目标方向信号。
  - 用途：建立 beamforming 作为阵列空间滤波的基础定义。
  - 核验日期：2026-08-04
- [Microphone Array Beamforming - MathWorks](https://www.mathworks.com/help/audio/ug/microphone-array-beamforming.html)
  - 内容定位：麦克风阵列 beamforming 示例，覆盖 delay-and-sum 和 [[方向/AI语音/知识/基础概念/MVDR（最小方差无失真响应）|MVDR]] 的音频场景。
  - 用途：确认语音/音频链路里的 DAS、[[方向/AI语音/知识/基础概念/MVDR（最小方差无失真响应）|MVDR]] 口径。
  - 核验日期：2026-08-04
- [pyroomacoustics.beamforming - pyroomacoustics documentation](https://pyroomacoustics.readthedocs.io/en/pypi-release/pyroomacoustics.beamforming.html)
  - 内容定位：pyroomacoustics 的 beamforming 模块。
  - 用途：查看研究工程里麦克风阵列、RIR 和波束形成的组合实现。
  - 核验日期：2026-08-04
- [Advances in Microphone Array Processing and Multichannel Speech Enhancement](https://arxiv.org/abs/2502.09037)
  - 内容定位：麦克风阵列处理与多通道语音增强综述，覆盖传统阵列、深度学习和 all-neural beamformer。
  - 用途：把 beamforming 放回多通道 SE / 阵列前端地图。
  - 核验日期：2026-08-04

## 7. 相关对象

- [[方向/AI语音/知识/基础概念/Array Audio Signal（阵列音频信号）|Array Audio Signal]]：beamforming 的输入基础。
- [[方向/AI语音/知识/基础概念/Omni Mic（全向麦克风）]]：阵列指向性 = 阵因子 × 单元指向性；单元全向（$a_m\equiv1$）是导向矢量只含几何相位、权重有闭式解的前提。
- [[方向/AI语音/知识/基础概念/Array Aperture（阵列孔径）]]：决定低频指向性、主瓣宽度和空间分辨率上限。
- [[方向/AI语音/知识/基础概念/AEC（声学回声消除）]]：有播放参考时，通常要和 beamforming 一起确定前后顺序。
- [[方向/AI语音/知识/基础概念/DOA（到达方向）|DOA]]：常作为目标方向条件。
- [[方向/AI语音/知识/基础概念/IPD（通道间相位差）|IPD]]：neural beamformer / mask 估计常用的相位空间线索。
- [[方向/AI语音/知识/基础概念/MVDR（最小方差无失真响应）|MVDR]]：常见的约束最小方差波束形成算法。
- [[方向/AI语音/知识/基础概念/SE（语音增强）导论|SE（语音增强）导论]]：beamforming 属于多通道增强 / 传统 DSP 前端。
- [[方向/AI语音/知识/基础概念/SS（语音分离）|SS]]、[[方向/AI语音/知识/基础概念/TSE（目标说话人提取）|TSE]]：多说话人场景中常与 beamforming 联用。
- [[方向/AI语音/知识/基础概念/TSP（Time-Stretched Pulse）|TSP]]：可用于测量阵列传递函数，辅助 beamforming 校准。

## 8. 词源与术语历史

Beam（光束形象）+ Forming（塑造）：借用"手电筒光束"的视觉形象，指用阵列信号处理算法在空间中"塑造"出具有特定方向性的声波或电磁波能量束。

术语演变路线（时间线未经一手文献核验，见待验证）：

- **定向天线阵列（1900–1920s）**：无线电先驱通过调整多天线相位，让无线电波集中向某个方向发射，当时称 Directive Antenna Array。
- **雷达 beam shaping / beam steering（1930–40s）**：二战前后雷达为精准探测，通过相位控制让窄波束扫描。
- **DSP 确立 "Beamforming" 术语（1960s）**：阵列信号处理学科建立，多通道加权求和（delay-and-sum）、调相位幅度实现定向增强；大量用于海军声纳阵列和地震波探测。
- **现代扩展**：麦克风阵列（智能音箱、降噪耳机）、5G / Wi-Fi 6 Massive MIMO 基站将信号"对准"终端发射。

## 9. 待验证

- [ ] "Beamforming" 术语确立时间线：1960s 随 DSP 确立的说法，与 Van Veen & Buckley 1988 *Beamforming: A versatile approach to spatial filtering*（IEEE ASSP Magazine）作为常见普及出处的说法不一致，需查一手文献。
- [ ] 冷战时期声纳阵列（Sonar Array）作为早期主要应用：史实出处待查。
- 是否需要独立拆 DAS、GSC、WPD、neural beamformer。
- 当前目标设备的阵列几何和同步质量是否足以支撑可靠 beamforming。
- 实时语音 Agent 链路中，beamforming 与 AEC / neural denoise 的顺序和延迟预算。

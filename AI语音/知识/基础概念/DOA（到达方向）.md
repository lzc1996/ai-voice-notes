---
title: DOA（到达方向）
类型: 概念
相关主题:
  - 阵列信号
  - 声源定位
aliases:
  - Direction of Arrival
  - direction of arrival
  - 到达方向
  - 波达方向
  - 声源方向
  - 声源定位方向
tags:
  - 类型/对象
  - 方向/AI语音
  - 主题/阵列信号
  - 主题/声源定位
---
# DOA（到达方向）

## 1. 身份

`DOA`（Direction of Arrival，到达方向 / 波达方向）是在 [[方向/AI语音/知识/基础概念/Array Audio Signal（阵列音频信号）|麦克风阵列]] 中估计声源相对阵列的方向，通常表示为 azimuth（方位角）和可选 elevation（俯仰角）。它回答“声音从哪个方向来”，不一定回答“声源在三维空间哪个坐标点”。

边界：DOA 不是 [[方向/AI语音/知识/基础概念/Beamforming（波束形成）|beamforming]] 本身，也不是完整 source localization。DOA 可以作为 beamforming、[[方向/AI语音/知识/基础概念/TSE（目标说话人提取）|TSE]]、会议 diarization、机器人听觉和多通道 ASR 的条件；若要估计距离或坐标，还需要阵列几何、房间模型、多阵列或更多约束。

## 2. 基本直觉

- 同一声源到达不同麦克风的时间、相位和能量略有差异。
- 阵列几何已知时，这些差异可以反推出声源方向。
- 远场常近似为“平面波 + 方向角”；近场还要考虑距离和球面波。

## 3. 常见方法

- **TDOA / GCC-PHAT**：先估计通道间到达时间差，再由阵列几何换算方向。
- **SRP-PHAT**：在候选方向上做 steered response power 搜索，常用于混响鲁棒定位。
- **MUSIC / NormMUSIC**：子空间方法，利用协方差矩阵区分信号子空间与噪声子空间。
- **[[方向/AI语音/知识/基础概念/MVDR（最小方差无失真响应）|MVDR]] / beam scan**：扫描不同方向的波束输出能量或空间谱。
- **神经 DOA**：用多通道特征、[[方向/AI语音/知识/基础概念/IPD（通道间相位差）|IPD]] 或 spatial spectrum 训练模型直接估方向或目标方向 embedding。

## 4. 在语音系统里的位置

```text
multichannel waveform
  -> sync / gain / channel QA
  -> VAD / speech activity
  -> DOA / speaker direction estimate
  -> [[方向/AI语音/知识/基础概念/Beamforming（波束形成）|beamforming]] / TSE / diarization / ASR metadata
```

工程上，DOA 常和 VAD、AEC、[[方向/AI语音/知识/基础概念/Beamforming（波束形成）|beamforming]] 一起放在前端；给 LLM / ASR 的通常不是 raw DOA 算法内部状态，而是更稳定的 metadata：目标方向、置信度、speaker turn、增强后单通道音频。

## 5. 使用注意

- **阵列几何是前提**：麦克风位置、朝向、采样同步和通道顺序错了，DOA 会整体偏。
- **混响会造假峰**：早期反射和墙面回声可能被误认为真实声源方向。
- **多人同时说话会多峰**：单一 DOA 不够，需要多源 DOA、TSE 或 SS 联合处理。
- **静音段不要估方向**：通常要先做 VAD / speech activity gating。
- **角度不等于身份**：同一方向可以有多人，移动说话人也会让方向随时间漂移。

## 6. 关键来源

- [Direction of Arrival Estimation - MathWorks](https://www.mathworks.com/discovery/direction-of-arrival-estimation.html)
  - 内容定位：DOA 估计基础介绍，覆盖 beamscan、[[方向/AI语音/知识/基础概念/MVDR（最小方差无失真响应）|MVDR]]、MUSIC 等常见算法。
  - 用途：建立 DOA 与阵列信号处理的基础定义。
  - 核验日期：2026-08-04
- [pyroomacoustics.doa - pyroomacoustics documentation](https://pyroomacoustics.readthedocs.io/en/pypi-release/pyroomacoustics.doa.html)
  - 内容定位：pyroomacoustics 的 DOA 算法模块，列出 MUSIC、NormMUSIC、SRP-PHAT、CSSM、WAVES、TOPS、FRIDA 等方法。
  - 用途：确认研究/工程中常见 DOA 算法族。
  - 核验日期：2026-08-04
- [Advances in Microphone Array Processing and Multichannel Speech Enhancement](https://arxiv.org/abs/2502.09037)
  - 内容定位：麦克风阵列处理与多通道语音增强综述。
  - 用途：把 DOA 放回阵列增强、beamforming 和多通道 SE 的整体地图。
  - 核验日期：2026-08-04

## 7. 相关对象

- [[方向/AI语音/知识/基础概念/Array Audio Signal（阵列音频信号）|Array Audio Signal]]：DOA 是阵列信号中的核心空间 metadata。
- [[方向/AI语音/知识/基础概念/Array Aperture（阵列孔径）]]：影响方向分辨率和低频定位可靠性。
- [[方向/AI语音/知识/基础概念/IPD（通道间相位差）|IPD]]：DOA 估计常用的通道间相位线索。
- [[方向/AI语音/知识/基础概念/Beamforming（波束形成）|Beamforming]]：常使用 DOA 或 [[方向/AI语音/知识/基础概念/steering vector（导向矢量）|steering vector]] 形成目标方向空间滤波器。
- [[方向/AI语音/知识/基础概念/MVDR（最小方差无失真响应）|MVDR]]：可使用目标方向或 RTF 形成无失真约束波束。
- [[方向/AI语音/知识/基础概念/TSE（目标说话人提取）|TSE]]：方向角可作为目标说话人线索。
- [[方向/AI语音/知识/基础概念/SS（语音分离）|SS]]：多源 DOA 可辅助多人分离。
- [[方向/AI语音/知识/基础概念/SE（语音增强）导论|SE（语音增强）导论]]：多通道增强常用 DOA / beamforming / WPE。
- [[方向/AI语音/知识/基础概念/Mix（语音混合）|Mix]]：构造多通道训练样本时，声源 DOA / RIR 影响空间标签。

## 8. 待验证

- 是否需要独立拆 [[TDOA]]、SRP-PHAT、MUSIC。
- 当前目标硬件阵列的麦克风几何、坐标系定义和 0 度方向。
- 给 ASR / LLM 后端保留 DOA 是用连续角度、离散方向桶，还是 speaker turn metadata。

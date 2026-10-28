---
title: Array vs Multi-Channel（阵列与多通道）
类型: 概念
相关任务:
  - 语音增强
  - 多通道增强
相关主题:
  - 阵列信号
aliases:
  - 阵列与多通道（Array vs Multi-Channel）
  - Array vs Multi-Channel
  - 阵列与多通道
  - 多通道不等于阵列
  - array vs multi-channel
tags:
  - 类型/对象
  - 方向/AI语音
  - 任务/语音增强
  - 任务/多通道增强
  - 主题/阵列信号
---

# Array vs Multi-Channel（阵列与多通道）

## 1. 身份

两个常被混用但并不等同的概念：

- **多通道（multi-channel）**是**信号属性**：输入/输出有几个通道。
- **阵列（array）**是**物理结构**：多个空间分布的麦克风同时采样同一声场，通道间携带可利用的空间信息——时延差、声压差。

**判断标准**：通道间是否被用来提取空间/方位信息——是，则无论叫法如何都属于阵列处理范式。

## 2. 四种错位情况

- **是多通道但不是阵列**：回放制式（立体声、5.1/7.1.4 环绕声、Ambisonics 的通道是扬声器馈送）；多轨录音（每个乐器一支麦，各录各的）；辅助传感器（骨传导麦 + 空气麦、ANC 参考麦/误差麦）；双耳助听器协同（通常称 binaural 而非 array）。
- **是阵列但产出单通道**：[[方向/AI语音/知识/基础概念/Beamforming（波束形成）|波束形成器]]本身就是"阵列输入 → 单通道输出"，阵列 ≠ 多通道输出。
- **灰色地带**：Ambisonics 一体麦（如四面体 4 芯）物理上是小阵列，但使用语境叫"声场麦克风"；分布式 ad-hoc 阵列（手机 + 耳机多设备）无固定几何，学界仍归在 array 家族。

## 3. 文献约定

speech enhancement / separation 语境下 "multi-channel speech enhancement" 默认指麦克风阵列输入、利用空间信息的增强，与单通道（single-channel / monaural）对举——本 vault 的阵列增强笔记沿用此约定。更大范围的 "multi-channel audio"（rendering、codec）往往指回放/编码制式，需看上下文区分。

## 4. 相关对象

- [[方向/AI语音/知识/基础概念/Array Audio Signal（阵列音频信号）|阵列音频信号]]：阵列信号携带的空间信息及其前端-后端分工。
- [[方向/AI语音/知识/调研与地图/Array Speech Enhancement Frontier（阵列语音增强前沿调研）|阵列语音增强前沿调研]]：本页拆自该调研的术语辨析节。
- [[方向/AI语音/知识/基础概念/Beamforming（波束形成）|波束形成]]：最典型的阵列处理。

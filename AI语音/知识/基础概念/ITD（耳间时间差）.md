---
title: ITD（耳间时间差）
类型: 概念
相关主题:
  - 阵列信号
  - 双耳听觉
  - 空间音频
aliases:
  - ITD
  - itd
  - Interaural Time Difference
  - interaural time difference
  - 耳间时间差
  - 通道间时间差
  - 到达时延差
tags:
  - 类型/对象
  - 方向/AI语音
  - 主题/阵列信号
  - 主题/双耳听觉
  - 主题/空间音频
---
# ITD（耳间时间差）

## 1. 身份

`ITD`（Interaural Time Difference，耳间时间差）：双耳声学中同一声音到达左耳与右耳的**时间差**——水平方位的主要定位线索之一（Duplex theory 的低频支柱，Lord Rayleigh）。在阵列语境中泛指**通道间到达时延差**（inter-channel time difference）。

几何定义（球面波路径差除以声速）：

$$
\text{ITD} = \frac{\| \mathbf{r}_{\text{src}} - \mathbf{r}_L \| - \| \mathbf{r}_{\text{src}} - \mathbf{r}_R \|}{c}
$$

远场球头模型（Woodworth 近似，$\theta$ 为方位角、$a$ 为人头半径）：

$$
\text{ITD}(\theta) \approx \frac{a}{c}\,(\theta + \sin\theta), \qquad
\max \text{ITD} \approx \frac{2a}{c} \approx 650\text{–}700\,\mu\text{s}
$$

边界：ITD 是**时间差**线索，不是能量差、不是相位特征本身——它高频段受相位缠卷困扰，主要低频（< ~1.5 kHz）可靠；高频靠 [[方向/AI语音/知识/基础概念/ILD（双耳声级差）|ILD]] 或包络 ITD（ENV-ITD）补充。

## 2. 与 IPD / ILD 的关系

- **IPD 是 ITD 的频域相位版本**：$\text{IPD}(f) = 2\pi f \cdot \text{ITD} \pmod{2\pi}$——同一物理量在 STFT 域的投影；低频可无模糊反解 ITD，高频缠卷（wrap）失效。
- **Duplex theory**：低频用 ITD（相位差），高频用 ILD（声级差）——两者互补覆盖整个频带。
- **"ITD/ILD 保持"**（如 [[方向/AI语音/模型/mSGMSE|mSGMSE]]）：增强输出保留通道间时间差与电平差 → 声源方位感知不被破坏。

## 3. 在增强 / 阵列里的角色

- **双耳助听**：[[方向/AI语音/评估/ECHI（助听对话增强）|ECHI]] 的双耳 4 麦设备——破坏 ITD 会让用户丢失"声音来自哪"的方位感知。
- **空间保真评测**：双耳渲染的 ILD / ITD 误差是保向增强（[[方向/AI语音/模型/Direction-Preserving MIMO|Direction-Preserving MIMO]]）的评估口径之一。
- **定位**：ITD 反演可估方位（[[方向/AI语音/知识/基础概念/DOA（到达方向）|DOA]] 的双耳手段）。
- **神经前端选型**：STFT 域模型常用 [[方向/AI语音/知识/基础概念/IPD（通道间相位差）|IPD]]（天然相位表示）而非显式 ITD；波形域 / 时域模型隐式利用 ITD。
- **对时钟敏感**：通道采样不同步、时钟漂移直接破坏 ITD——远不如 ILD 稳健。

## 4. 相关对象

- [[方向/AI语音/知识/基础概念/ILD（双耳声级差）|ILD]]：声级差线索，高频互补。
- [[方向/AI语音/知识/基础概念/IPD（通道间相位差）|IPD]]：ITD 的频域相位版本。
- [[方向/AI语音/知识/基础概念/Haas Effect（哈斯效应）|Haas Effect]]：直达声与反射声的 ITD 线索冲突时，定位由先到波前主导。
- [[方向/AI语音/知识/基础概念/DOA（到达方向）|DOA]]：ITD 反演定位。
- [[方向/AI语音/模型/Direction-Preserving MIMO|Direction-Preserving MIMO]]、[[方向/AI语音/模型/mSGMSE|mSGMSE]]：保 ITD/ILD 的增强模型。
- [[方向/AI语音/评估/ECHI（助听对话增强）|ECHI]]：双耳助听设备场景。

## 5. 待验证

- ECHI 双耳设备上增强算法的 ITD 保持与主观定位感的相关性（MUSHRA 之外的方位感评测）。
- 神经前端中显式 ITD vs IPD 特征的使用比例与收益差距。

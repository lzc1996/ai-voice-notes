---
title: Microsoft Speech Group（微软语音组）
类型: 团队
aliases:
  - 微软语音组
  - Microsoft Speech Group
  - Microsoft Teams 语音团队
tags:
  - 类型/对象
  - 方向/AI语音
  - 任务/语音增强
  - 任务/多通道增强
---

# Microsoft Speech Group（微软语音组）

## 1. 身份

微软语音研究团队，研究与产品（Teams、Azure Speech）结合最紧的工业团队之一；也是 [[方向/AI语音/评估/DNS Challenge（深度噪声抑制挑战）|DNS Challenge]] 的组织者。

## 2. 代表作

- **分布式异步阵列增强**（windowed cross-attention，2025）：处理设备位置动态变化、时钟异步的 ad-hoc 阵列，面向"手机+耳机+笔记本"式多设备协同拾音（[arXiv](https://arxiv.org/abs/2507.16104)），模型页见 [[方向/AI语音/模型/Windowed Cross-Attention（窗口交叉注意力异步阵列增强）]]。
- **Teams Voice Isolation**（2024 GA）：声纹注册 + 个性化深度语音增强，只保留本人声音并滤掉旁人说话，"个性化语音分离"产品化的标志；其多通道演进线见 [[方向/AI语音/模型/Geometry-Agnostic PSE（几何无关多通道个性化语音增强）]]。产品线全景见 [[方向/AI语音/知识/调研与地图/Personalized SE（个性化语音分离产品线调研）|Personalized SE（个性化语音分离产品线调研）]]。
- **多设备拾音链条**：[[方向/AI语音/模型/Project Denmark（多设备云端 ad-hoc 组阵会议转写）|Project Denmark]]（2019，ad-hoc 组阵转写）→ [[方向/AI语音/模型/PickNet（ad-hoc 阵列实时通道选择）|PickNet]]（2022，实时通道选择）→ WCA（2025）。
- **DNS Challenge**：深度噪声抑制 benchmark 的组织方，实时增强评测主线的定义者。

## 3. 可信度依据

- 研究与产品同源：论文方法直接进 Teams。
- 领域服务：DNS Challenge 长期作为增强方向的公共评测。

## 4. 相关笔记

- [[方向/AI语音/知识/调研与地图/Array Speech Enhancement Team Map（阵列增强团队地图）|阵列增强团队地图]]
- [[方向/AI语音/知识/调研与地图/Array Speech Enhancement Frontier（阵列语音增强前沿调研）|阵列语音增强前沿调研]]

---
title: LSZone（轻量车载多区域语音分离）
类型: 模型
任务:
  - 车载多区域语音分离
  - 实时语音增强
开放状态:
  - paper
aliases:
  - LSZone
  - Lightweight Spatial Information Modeling Architecture for Real-Time In-Car Multi-Zone Speech Separation
tags:
  - 类型/对象
  - 方向/AI语音
  - 任务/多通道分离
  - 主题/高效化
---

# LSZone（轻量车载多区域语音分离）

## 0. 背景

**问题现场**：车厢内多区域（多座位）拾音需要实时分离各区域说话人，且受车载算力约束。

**前序路线的缺口**：SpatialNet 类方法保留了空间区分能力，但计算成本难以满足车载实时处理需求。

**LSZone 的切入点**：空间信息提取与压缩模块 SpaIEC 结合 Mel 频谱与 IPD 特征，压缩空间建模负担，换取轻量实时推理。

## 1. 身份

LSZone 面向车载多区域语音分离，目标是在保留空间区分能力的同时降低 SpatialNet 类方法的计算成本，满足车载实时处理需求。

## 2. 核心机制

- 设计空间信息提取与压缩模块 SpaIEC。
- 摘要说明 SpaIEC 结合 Mel 频谱和 IPD 特征，压缩空间建模负担。

## 3. 边界

方法针对车厢多区域拾音；摘要不足以证明其适用于非车载房间或任意麦克风布局。具体吞吐和延迟尚未核对。

## 4. 来源

- [LSZone: A Lightweight Spatial Information Modeling Architecture for Real-Time In-Car Multi-Zone Speech Separation（arXiv:2510.10687）](https://arxiv.org/abs/2510.10687)

## 5. 相关对象

- [[方向/AI语音/知识/技术路线/Efficient Multichannel SE（多通道语音增强高效化）]]
- [[方向/AI语音/知识/基础概念/IPD（通道间相位差）]]

## 6. 待验证

- SpaIEC 的压缩位置、模型尺寸、车载硬件延迟、区域串扰和下游识别结果。

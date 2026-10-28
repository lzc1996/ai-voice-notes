---
title: Sonic Visualiser（音频可视化分析）
类型: 工具
发表时间:
时间依据: 音频可视化工具；非单一论文
相关主题:
  - 音频分析
  - 音频可视化
aliases:
  - Sonic Visualiser
  - Sonic Visualizer
  - 音频可视化分析工具
tags:
  - 类型/工具
  - 方向/AI语音
  - 主题/音频处理
---

# Sonic Visualiser（音频可视化分析）

## 1. 身份

`Sonic Visualiser` 是桌面音频可视化和标注工具，适合细看 waveform、spectrogram、pitch、onset、beat 等时间序列分析结果。

## 2. 什么时候用

- 需要比 Audacity 更细的多层可视化和标注。
- 检查增强前后某个频段、瞬态或节奏结构是否被破坏。
- 对音乐 / 环境音 / 非语音一维信号做可视化诊断。

## 3. 当前语音增强用途

- 作为 [[方向/AI语音/工具/Praat（语音学分析工具）]] 的补充：Praat 偏语音学，Sonic Visualiser 偏通用音频可视化。
- 对生成式增强的瞬态、噪声尾巴、带宽变化做目检。

## 4. 安装方式

- Windows：官网下载 64-bit Windows installer。
- Linux：优先用官方 64-bit AppImage；Ubuntu 也可用官方 `.deb`。
- 插件：基础软件不自带 Vamp analysis plugins，需要额外下载插件包。

## 5. 内网迁移

- Windows：拷贝 installer 到内网安装。
- Linux：拷贝 AppImage，内网机执行 `chmod +x SonicVisualiser*.AppImage` 后运行；`.deb` 需要同时带依赖。
- 插件：把 Vamp 插件目录一并拷贝，保持和目标系统架构一致。

## 6. 外部入口

- [Sonic Visualiser official site](https://www.sonicvisualiser.org/)

## 7. 相关对象

- [[方向/AI语音/知识/基础概念/Spectrogram（声谱图）]]
- [[方向/AI语音/知识/技术路线/音频方案迁移到一维信号]]

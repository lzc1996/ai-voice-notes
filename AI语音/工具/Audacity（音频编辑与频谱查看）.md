---
title: Audacity（音频编辑与频谱查看）
类型: 工具
发表时间:
时间依据: 开源音频编辑工具；非单一论文
相关主题:
  - 音频编辑
  - 音频分析
aliases:
  - Audacity
  - 音频编辑工具
tags:
  - 类型/工具
  - 方向/AI语音
  - 主题/音频处理
---

# Audacity（音频编辑与频谱查看）

## 1. 身份

`Audacity` 是开源音频编辑器，适合快速听样本、剪切片段、导入导出格式、粗看 spectrogram 和检查波形异常。

## 2. 什么时候用

- 快速听 noisy / enhanced / clean 的差异。
- 切出问题片段，导出给模型或评估脚本复现。
- 查看削波、长静音、响度过低、明显高频噪声。

## 3. 边界

- 它是编辑和肉眼检查工具，不是可复现实验管线。
- 大规模特征和指标仍应放到 [[方向/AI语音/工具/librosa（Python 音频分析库）]] 或 [[方向/AI语音/工具/torchaudio（PyTorch 音频工具库）]]。

## 4. 安装方式

- Windows：官网下载 Windows installer，按向导安装。
- Linux：优先下载官方 64-bit AppImage，`chmod +x Audacity*.AppImage` 后运行；也可用发行版包管理器，但版本可能滞后。
- 可选：需要更多格式导入 / 导出时，另装 Audacity 对应 FFmpeg library。

## 5. 内网迁移

- Windows：拷贝 installer；如果要静默部署，优先找 `.msi` 或企业软件分发工具处理。
- Linux：拷贝 AppImage 最省事；若拷 `.deb`，要同时准备依赖包。
- 离线手册 / FFmpeg：从官网下载 manual 和 FFmpeg 支持包，一起放进内网软件包目录。

## 6. 外部入口

- [Audacity official site](https://www.audacityteam.org/)

## 7. 相关对象

- [[方向/AI语音/知识/基础概念/音频数据预处理]]
- [[方向/AI语音/知识/基础概念/Sample Rate（采样率）]]
- [[方向/AI语音/知识/基础概念/dBFS（满刻度分贝）]]

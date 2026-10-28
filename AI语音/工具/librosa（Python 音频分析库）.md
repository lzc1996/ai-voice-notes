---
title: librosa（Python 音频分析库）
类型: 工具
发表时间:
时间依据: Python 音频分析库；非单一论文
相关主题:
  - 音频分析
  - 特征提取
  - Python
aliases:
  - librosa
  - Python 音频分析库
tags:
  - 类型/工具
  - 方向/AI语音
  - 主题/音频处理
  - 主题/特征提取
---

# librosa（Python 音频分析库）

## 1. 身份

`librosa` 是 Python 音频分析库，常用于加载音频、重采样、STFT、mel spectrogram、MFCC、onset / beat / pitch 等传统音频特征。

## 2. 什么时候用

- 批量检查采样率、时长、响度、静音比例和频谱统计。
- 快速画 [[方向/AI语音/知识/基础概念/Spectrogram（声谱图）]]、mel、MFCC。
- 写研究脚本和数据 QA，不直接承担深度学习训练。

## 3. 边界

- 需要 GPU、模型管线或 WavLM / wav2vec2 时，用 [[方向/AI语音/工具/torchaudio（PyTorch 音频工具库）]]。
- 传统声学特征标准集可用 [[方向/AI语音/工具/openSMILE（声学特征提取工具）]]。

## 4. 安装方式

```bash
python -m venv .venv
source .venv/bin/activate  # Windows: .venv\Scripts\activate
python -m pip install librosa
```

Conda 环境可用：

```bash
conda install -c conda-forge librosa
```

## 5. 内网迁移

```bash
# 联网机：按目标机 Python 版本下载
python -m pip download -d wheelhouse librosa

# 内网机：离线安装
python -m pip install --no-index --find-links wheelhouse librosa
```

Linux / Windows 轮子不要混用；如果内网机没有编译器，务必在联网机下载到完整二进制 wheel。更稳的做法是把含 librosa 的 conda 环境用 `conda-pack` 整体迁移。

## 6. 外部入口

- [librosa documentation](https://librosa.org/doc/latest/)

## 7. 相关对象

- [[方向/AI语音/知识/基础概念/STFT（短时傅里叶变换）]]
- [[方向/AI语音/知识/基础概念/Spectrogram（声谱图）]]
- [[方向/AI语音/知识/基础概念/Energy-based VAD（基于能量的语音活动检测）]]

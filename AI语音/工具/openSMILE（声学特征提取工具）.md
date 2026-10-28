---
title: openSMILE（声学特征提取工具）
类型: 工具
发表时间:
时间依据: 声学特征提取工具；非单一论文
相关主题:
  - 声学特征
  - 情感计算
  - 副语言分析
aliases:
  - openSMILE
  - SMILE
  - 声学特征提取工具
tags:
  - 类型/工具
  - 方向/AI语音
  - 主题/特征提取
---

# openSMILE（声学特征提取工具）

## 1. 身份

`openSMILE` 是经典声学特征提取工具，常用于语音情感、说话风格、副语言、健康语音和传统机器学习特征工程。

## 2. 什么时候用

- 需要标准化特征集，如 eGeMAPS、ComParE、MFCC、F0、energy、jitter、shimmer。
- 需要把每段音频变成表格特征，接传统分类器或回归模型。
- 做可解释声学分析，而不是端到端深度模型。

## 3. 边界

- 它偏手工声学特征，不替代 [[方向/AI语音/知识/基础概念/SSL 编码器]]。
- 研究 WavLM / codec LM 时，openSMILE 更适合做补充诊断和可解释侧特征。

## 4. 安装方式

Python 包最省事：

```bash
python -m pip install opensmile
```

命令行 `SMILExtract`：从 GitHub release 下载 openSMILE 压缩包，解压后使用 `bin/SMILExtract` 或 `bin/SMILExtract.exe`。

## 5. 内网迁移

- Python 用法：联网机 `python -m pip download -d wheelhouse opensmile`，内网机 `python -m pip install --no-index --find-links wheelhouse opensmile`。
- CLI 用法：直接拷贝 release 压缩包；Windows 保持 `SMILExtract.exe` 和同目录 DLL 在一起，Linux 解压后把 `bin` 加到 `PATH`。
- 需要自定义 PortAudio / FFmpeg / OpenCV 支持时，尽量在联网 Linux 构建好二进制再拷贝，内网现编依赖最麻烦。

## 6. 外部入口

- [openSMILE documentation](https://audeering.github.io/opensmile/)

## 7. 相关对象

- [[方向/AI语音/工具/librosa（Python 音频分析库）]]
- [[方向/AI语音/知识/基础概念/Spectral Envelope（频谱包络）]]

---
title: torchaudio（PyTorch 音频工具库）
类型: 工具
发表时间:
时间依据: PyTorch 生态音频库；非单一论文
相关主题:
  - 音频处理
  - 特征提取
  - PyTorch
aliases:
  - torchaudio
  - PyTorch 音频工具库
tags:
  - 类型/工具
  - 方向/AI语音
  - 主题/音频处理
  - 主题/深度学习
---

# torchaudio（PyTorch 音频工具库）

## 1. 身份

`torchaudio` 是 PyTorch 官方音频库，覆盖音频 I/O、transforms、datasets、预训练 pipelines、WavLM / wav2vec2 类模型接入和语音质量估计示例。

## 2. 什么时候用

- 实验代码已经在 PyTorch 里，想避免 numpy / torch 来回转换。
- 需要批量重采样、mel、spec augmentation、训练数据管线。
- 需要直接取 [[方向/AI语音/模型/WavLM]] / wav2vec2 hidden states 或跑 [[方向/AI语音/工具/SQUIM（语音质量无参考评估）]]。

## 3. 当前语音增强用途

- 复现 UniSE 类链路里的 WavLM 条件特征。
- 对增强结果跑无参考质量估计或和 PESQ / STOI / SI-SDR 脚本拼接。

## 4. 安装方式

CPU 版示例：

```bash
python -m pip install torch torchaudio
```

GPU 版不要手写猜 CUDA wheel，使用 PyTorch 官网 selector 生成命令；原则是 `torch`、`torchaudio`、Python 版本和 CUDA runtime 对齐。

## 5. 内网迁移

```bash
# 联网机：使用和目标机一致的 Python / CUDA wheel 源
python -m pip download -d wheelhouse torch torchaudio

# 内网机
python -m pip install --no-index --find-links wheelhouse torch torchaudio
```

如果要用预训练 bundle / SQUIM / WavLM，联网机先设置 `TORCH_HOME` 并跑一次下载权重，再把 `TORCH_HOME` 整体拷到内网机同路径或重新设置环境变量。

## 6. 外部入口

- [torchaudio documentation](https://pytorch.org/audio/stable/)

## 7. 相关对象

- [[方向/AI语音/知识/基础概念/SSL 编码器]]
- [[方向/AI语音/模型/WavLM]]
- [[方向/AI语音/工具/SQUIM（语音质量无参考评估）]]

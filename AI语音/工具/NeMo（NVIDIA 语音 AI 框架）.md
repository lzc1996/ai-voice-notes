---
title: NeMo（NVIDIA 语音 AI 框架）
类型: 工具
发表时间:
时间依据: NVIDIA 语音 AI 框架；非单一论文
相关主题:
  - ASR
  - TTS
  - diarization
  - speech AI
aliases:
  - NeMo
  - NVIDIA NeMo
  - NVIDIA 语音 AI 框架
tags:
  - 类型/工具
  - 方向/AI语音
  - 主题/工具链
---

# NeMo（NVIDIA 语音 AI 框架）

## 1. 身份

`NeMo` 是 NVIDIA 的 AI 框架，语音部分覆盖 ASR、TTS、speaker diarization、speech classification、speech LLM 等任务，偏工程化和 GPU 训练 / 推理生态。

## 2. 什么时候用

- 需要较完整的 ASR / TTS / diarization 训练和部署链路。
- 需要 FastConformer、流式 ASR、NVIDIA GPU 生态或生产化示例。
- 需要把研究模型推进到更工程化的训练配置。

## 3. 边界

- 依赖和配置比轻量工具重，不适合只做几个样本的声学分析。
- 只提特征或跑小脚本时，用 [[方向/AI语音/工具/torchaudio（PyTorch 音频工具库）]] 更省事。

## 4. 安装方式

NeMo 优先在 Linux / NVIDIA PyTorch 容器里装；Windows 原生不适合，必要时用 WSL2。

```bash
apt-get update && apt-get install -y libsndfile1 ffmpeg
python -m pip install Cython packaging
python -m pip install "nemo_toolkit[asr]"  # 或 "nemo_toolkit[tts]" / "nemo_toolkit[all]"
```

## 5. 内网迁移

- Linux GPU 服务器：优先用 Docker / NGC 容器，联网机 `docker save -o nemo.tar <image>`，内网机 `docker load -i nemo.tar`。
- pip 环境：只建议在同 OS / CUDA / Python 的机器间用 `conda-pack`；NeMo 依赖重，wheelhouse 容易漏系统库。
- 模型：`.nemo` 文件、Hugging Face 缓存、NGC 下载模型都单独归档；内网推理脚本显式指向本地模型路径。

## 6. 外部入口

- [NVIDIA NeMo documentation](https://docs.nvidia.com/nemo-framework/user-guide/latest/overview.html)

## 7. 相关对象

- [[方向/AI语音/知识/基础概念/Streaming Conformer]]
- [[方向/AI语音/MOC - ASR]]
- [[方向/AI语音/MOC - TTS]]

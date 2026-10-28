---
title: SpeechBrain（语音研究工具包）
类型: 工具
发表时间:
时间依据: 开源语音研究工具包；非单一论文
相关主题:
  - ASR
  - TTS
  - speaker recognition
  - speech enhancement
aliases:
  - SpeechBrain
  - 语音研究工具包
tags:
  - 类型/工具
  - 方向/AI语音
  - 主题/工具链
---

# SpeechBrain（语音研究工具包）

## 1. 身份

`SpeechBrain` 是 PyTorch 语音研究工具包，覆盖 ASR、speaker recognition、separation、enhancement、TTS 等任务，适合快速复现实验和搭 baseline。

## 2. 什么时候用

- 想用统一 recipe 跑 ASR、说话人、增强或分离 baseline。
- 需要 PyTorch 生态里的研究框架，但不想从零写训练循环。
- 做教学、论文复现、小中型实验。

## 3. 边界

- 框架层比 [[方向/AI语音/工具/torchaudio（PyTorch 音频工具库）]] 重。
- 如果主要研究 ESPnet-SE、CHiME recipe 或增强-ASR 集成，优先看 [[方向/AI语音/模型/ESPnet]]。

## 4. 安装方式

```bash
python -m venv .venv
source .venv/bin/activate  # Windows: .venv\Scripts\activate
python -m pip install speechbrain
```

跑具体 recipe 时，通常需要 clone 仓库并安装 recipe 下的 `extra_requirements.txt`。

## 5. 内网迁移

- 包：联网机 `python -m pip download -d wheelhouse speechbrain`，内网机离线 `pip install --no-index --find-links wheelhouse speechbrain`。
- 研究 recipe：把 SpeechBrain 仓库、`requirements.txt` / `extra_requirements.txt` 对应 wheelhouse 一起拷入内网。
- 预训练模型：联网机先设置 `HF_HOME` / SpeechBrain 保存目录并跑一次下载，再把缓存和本地 `pretrained_models` 目录拷走。

## 6. 外部入口

- [SpeechBrain official site](https://speechbrain.github.io/)

## 7. 相关对象

- [[方向/AI语音/MOC - ASR]]
- [[方向/AI语音/知识/基础概念/SE（语音增强）导论]]
- [[方向/AI语音/模型/ESPnet]]

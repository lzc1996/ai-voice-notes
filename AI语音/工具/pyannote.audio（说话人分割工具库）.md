---
title: pyannote.audio（说话人分割工具库）
类型: 工具
发表时间:
时间依据: 说话人分割工具库；非单一论文
相关主题:
  - speaker diarization
  - VAD
  - 说话人分析
aliases:
  - pyannote.audio
  - pyannote
  - 说话人分割工具库
  - speaker diarization toolkit
tags:
  - 类型/工具
  - 方向/AI语音
  - 任务/说话人分割
---

# pyannote.audio（说话人分割工具库）

## 1. 身份

`pyannote.audio` 是说话人相关任务工具库，常用于 VAD、speaker change detection、overlapped speech detection、speaker embedding 和 diarization pipeline。

## 2. 什么时候用

- 多人会议、访谈、播客：先分出说话人段，再做 ASR 或语义分析。
- 和 [[方向/AI语音/工具/WhisperX（长音频转写与对齐）]] 拼接，获得说话人标签 + 词级时间戳。
- 做目标说话人任务、泄漏分析或说话人一致性检查。

## 3. 边界

- diarization 不是 speaker identification：通常给的是匿名说话人簇，不是实名身份。
- 强混响、远场、多人重叠时需要人工抽查 DER 和边界错误。

## 4. 安装方式

```bash
python -m pip install pyannote.audio
```

运行 diarization pipeline 前通常还要：安装 `ffmpeg`，在 Hugging Face 接受模型使用条件，创建 access token，然后用 `Pipeline.from_pretrained(..., token=...)` 加载模型。

## 5. 内网迁移

- 包：联网机 `python -m pip download -d wheelhouse pyannote.audio`，内网机 `python -m pip install --no-index --find-links wheelhouse pyannote.audio`。
- 模型：联网环境先接受条款并下载模型；把 `HF_HOME` 缓存整体拷入内网，或把模型 snapshot 拷成固定目录，再用本地路径加载。
- 注意：如果内网不能访问 Hugging Face，token 没用；必须提前把 gated model 权重和 config 准备好，并确认许可证允许内网分发。

## 6. 外部入口

- [pyannote.audio repository](https://github.com/pyannote/pyannote-audio)

## 7. 相关对象

- [[方向/AI语音/知识/基础概念/VAD（Voice Activity Detection）]]
- [[方向/AI语音/知识/基础概念/TSE（目标说话人提取）]]
- [[方向/AI语音/评估/NOTSOFAR-1（远场会议转写挑战）]]

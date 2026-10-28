---
title: MFA（强制对齐工具）
类型: 工具
发表时间:
时间依据: forced alignment 工具；非单一论文
相关主题:
  - forced alignment
  - 标注对齐
  - ASR
aliases:
  - MFA
  - Montreal Forced Aligner
  - 强制对齐工具
tags:
  - 类型/工具
  - 方向/AI语音
  - 任务/ASR
---

# MFA（强制对齐工具）

## 1. 身份

`MFA`（Montreal Forced Aligner）是 forced alignment 工具：给定音频和转写文本，输出音素、词或句子的时间边界。

## 2. 什么时候用

- 已有文本，想把每个词 / 音素对齐到音频时间轴。
- TTS 数据清洗、发音分析、口型 / 字幕对齐、语音学标注。
- 检查 ASR 或人工转写是否和音频错位。

## 3. 边界

- 它不是 ASR；文本错了时，对齐也会被拖偏。
- 需要匹配语言、发音词典和声学模型；方言 / 夹杂语要单独验证。

## 4. 安装方式

官方推荐 conda / mamba：

```bash
conda create -n aligner -c conda-forge montreal-forced-aligner
conda activate aligner
```

常用模型另下：

```bash
mfa model download acoustic english_us_arpa
mfa model download dictionary english_us_arpa
```

## 5. 内网迁移

- 最省事：联网机建好 `aligner` 环境和模型，用 `conda-pack` 打包环境，内网同 OS / 架构解包后运行 `conda-unpack`。
- 模型缓存：设置 `MFA_ROOT_DIR` 到固定目录，下载 acoustic / dictionary / g2p 模型后，把这个目录整体拷到内网。
- Docker 路线：联网机 `docker pull mmcauliffe/montreal-forced-aligner:latest` 后 `docker save`，内网 `docker load`；数据目录用 `-v` 挂载。

## 6. 外部入口

- [Montreal Forced Aligner documentation](https://montreal-forced-aligner.readthedocs.io/)

## 7. 相关对象

- [[方向/AI语音/工具/ELAN（多层语音视频标注工具）]]
- [[方向/AI语音/MOC - TTS]]
- [[方向/AI语音/MOC - ASR]]

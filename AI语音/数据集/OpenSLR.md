---
title: OpenSLR
类型: 数据集
aliases:
  - Open Speech and Language Resources
  - openslr
tags:
  - 类型/对象
  - 方向/AI语音
  - 资源/数据集
---

# OpenSLR

## 1. 身份

OpenSLR（Open Speech and Language Resources）是一个公开语音与语言资源站点，用来托管和索引语音识别、语音处理、文本、音频与相关软件资源。它更像数据源/资源目录，不是单一数据集。

## 2. 用途

- 检索 ASR、TTS、说话人、语音增强相关公开语料和辅助资源。
- 作为 Kaldi/语音研究复现实验的数据下载入口或备用镜像入口。
- 查找中文、低资源语言、多语种、RIR、噪声等可复用资源。

## 3. 关键资源

- [OpenSLR Home](https://www.openslr.org/index.html)
  - 内容定位：官方首页说明 OpenSLR 的定位、资源托管目标、Kaldi 相关镜像、下载并发限制和镜像站。
  - 用途：建立对象身份和下载注意事项。
  - 核验日期：2026-07-28
- [OpenSLR Resources](https://www.openslr.org/resources.php)
  - 内容定位：官方资源索引，按 SLR 编号列出资源名称、类别和摘要。
  - 用途：检索具体语音、文本、音频、软件和辅助资源。
  - 核验日期：2026-07-28

## 4. 相关对象

- [[方向/AI语音增强/README|AI 语音增强]]：该方向已有 [[方向/AI语音/评估/DNS Challenge（深度噪声抑制挑战）|DNS Challenge]]、RIR/噪声资源线索；OpenSLR 可作为候选数据入口。
- [[方向/AI语音/数据集/LibriSpeech|LibriSpeech]]：OpenSLR SLR12 托管的英文 ASR 基准语料。
- [[工具/Kaldi|Kaldi]]：OpenSLR 首页明确提到部分软件镜像服务于 Kaldi scripts。

## 5. 收尾决策

- **笔记结构**：OpenSLR 继续作为资源索引；只有在某个资源被多条路线反复引用、需要记录独立 benchmark 口径或需要单独追踪许可证时，才拆成对象页。当前不为 `MUSAN`、`AISHELL`、`WenetSpeech` 批量建空壳页。
- **下载策略**：镜像、并发和断点续传属于本机下载任务，不在 OpenSLR 总页固化默认值；实际下载时以该资源当前官方页面和本地网络条件为准。
- **许可证**：不把 OpenSLR 首页的“可下载”解释成统一再分发许可。每个资源按自己的许可证和来源页单独核验，真正进入训练/发布链路时再补对象级记录。


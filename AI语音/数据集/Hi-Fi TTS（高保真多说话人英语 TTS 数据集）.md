---
title: "Hi-Fi TTS（高保真多说话人英语 TTS 数据集）"
类型: 数据集
发表时间: "2021"
时间依据: Interspeech 2021 论文；OpenSLR SLR109 发布页
任务:
  - 多说话人 TTS
  - 高保真语音合成
  - 说话人条件建模
  - 声音克隆相关研究（可扩展用途）
相关基准:
  - LibriVox
  - Project Gutenberg
aliases:
  - HiFi-TTS
  - Hi-Fi TTS
  - Hi-Fi Multi-Speaker English TTS Dataset
  - SLR109
tags:
  - 类型/对象
  - 方向/AI语音
  - 任务/TTS
  - 任务/多说话人
  - 资源/数据集
---

# Hi-Fi TTS（高保真多说话人英语 TTS 数据集）

## 1. 身份

`Hi-Fi TTS` 是面向高质量英文文本转语音研究的多说话人语料，官方托管入口为 OpenSLR SLR109。数据主要来自 LibriVox 有声书语音与 Project Gutenberg 文本，目标是提供比常见 22/24 kHz 朗读语料更高采样率、更长时长的训练资源。

它适合做多说话人 TTS、说话人条件建模、声学模型/声码器训练和高保真语音生成；它不是专门为少样本声音克隆评测设计的 benchmark，做 voice cloning 时需要额外定义参考音频、样本预算和跨说话人评测协议。

## 2. 核心信息

| 维度 | 内容 |
|---|---|
| 说话人 | 10 位英语说话人 |
| 总时长 | 约 291.6 小时，论文概述为约 292 小时 |
| 单说话人时长 | 每位至少约 17 小时 |
| 采样率 | 44.1 kHz |
| 来源 | LibriVox 有声书音频 + Project Gutenberg 文本 |
| 托管 | OpenSLR SLR109 |
| 下载包 | `hi_fi_tts_v0.tar.gz`，约 41 GB |
| 许可证 | CC BY 4.0 |

## 3. 数据构成与内容

- 语音以英语朗读为主，来自有声书内容，整体风格偏清晰、连续、长时段叙述。
- 语音与文本配对，适合训练 text-to-speech 的文本前端、声学建模和 waveform/codec 解码链路。
- 10 位说话人提供有限但可控的 speaker 条件变化；它更适合验证多说话人建模和音质，而不是覆盖大量口音或极宽的说话人分布。
- 高采样率使其适合研究高频细节、声码器、音频 codec 和高保真重建，但也显著增加存储、I/O 和训练成本。

## 4. 研究用途

- **多说话人 TTS**：以 speaker ID 或 speaker embedding 作为条件，训练共享 TTS 模型。
- **高保真声码器**：验证 44.1 kHz waveform 重建和高频细节保留。
- **语音生成表示**：作为 audio tokenizer、codec、latent TTS 或 waveform decoder 的训练/评估语料。
- **说话人条件实验**：测试 speaker representation 是否能保持音色一致性与跨文本泛化。
- **声音克隆相关研究**：可作为训练或预训练语料，但不能替代专门的 zero-shot/few-shot cloning 评测集。

## 5. 使用注意

- **朗读域偏差**：来源是有声书朗读，不等同于自然对话、客服、会议或 in-the-wild speech。
- **说话人规模有限**：10 位说话人足以做多说话人条件实验，但不适合支撑大规模 speaker generalization 结论。
- **文本域偏差**：Project Gutenberg 文本偏书面语，句法、词汇和标点分布与现代对话不同。
- **高采样率成本**：44.1 kHz 训练会放大显存、磁盘、数据加载和 batch 设计压力；与 22/24 kHz 模型比较时要说明重采样口径。
- **许可证边界**：数据集页面标注 CC BY 4.0，但实际发布、再分发和衍生数据仍应保留署名并核验当前 release 的许可文件。
- **评测边界**：论文/数据集主要支持 TTS 质量与多说话人建模研究，不自动提供统一的 MOS、speaker similarity 或 cloning protocol。

## 6. 与相邻语料的关系

- 相比 [[方向/AI语音/数据集/LibriTTS|LibriTTS]]：Hi-Fi TTS 说话人数量更少，但采样率更高、单说话人时长更集中，适合高保真生成与声码器研究。
- 相比 [[方向/AI语音/数据集/VCTK|VCTK]]：Hi-Fi TTS 更强调长时长和高采样率；VCTK 更适合多说话人、口音与短句条件下的对比。
- [[方向/AI语音/数据集/OpenSLR|OpenSLR]]：官方资源索引与下载入口。
- [[方向/AI语音/MOC - TTS|TTS]]：该数据集属于英文多说话人 TTS 语料线。

## 7. 关键来源

- [OpenSLR SLR109 - Hi-Fi TTS](https://www.openslr.org/109/)
  - 内容定位：官方下载入口、数据规模、文件名、采样率和许可证。
  - 用途：下载与版本核验。
  - 核验日期：2026-09-20
- [Hi-Fi Multi-Speaker English TTS Dataset](https://www.isca-archive.org/interspeech_2021/bakhturina21_interspeech.pdf)
  - 内容定位：数据构建、说话人规模、时长、采样率和研究定位。
  - 用途：核验论文口径与使用边界。
  - 核验日期：2026-09-20
- [Hi-Fi TTS arXiv record](https://arxiv.org/abs/2104.01497)
  - 内容定位：论文元数据与公开版本。
  - 用途：引用和版本追踪。
  - 核验日期：2026-09-20

## 8. 待验证

- [ ] 补录官方目录结构、metadata 字段和推荐 train/dev/test 使用方式。
- [ ] 如用于声音克隆，单独定义参考音频长度、说话人划分和授权审计规则。

---
title: DEMUCS
类型: 模型
发表时间: "2019"
时间依据: DEMUCS 原始论文 arXiv 2019；Hybrid Demucs / HT-Demucs 后续论文
任务:
  - 音乐源分离
  - 人声提取
  - stem 分离
相关评估:
  - MUSDB18
  - SDR
  - SI-SDR
开放状态:
  - paper
  - code
  - pretrained-weights
aliases:
  - Demucs
  - Hybrid Demucs
  - HT-Demucs
  - Music Source Separation with Demucs
tags:
  - 类型/对象
  - 方向/AI语音
  - 任务/源分离
  - 任务/音乐源分离
  - 主题/波形建模
  - 主题/混合域建模
---

# DEMUCS

## 0. 背景

**问题现场**：音乐源分离需要把混合波形拆成 vocals / drums / bass / other 等可单独编辑或重混的 stem。

**DEMUCS 的切入点**：端到端 waveform U-Net + 双向 LSTM 建模长时上下文；后续 Hybrid 版本同时建模 waveform 与 spectrogram 双域，HT-Demucs 再在混合域瓶颈引入 Transformer。

## 1. 身份

`DEMUCS` 是面向音乐源分离（Music Source Separation, MSS）的深度模型家族。它把一首混合音乐拆成 vocals、drums、bass 和 other accompaniment 等 stem，核心目标是从混合波形中恢复可单独编辑或重混的音轨。

DEMUCS 不是通用语音增强模型，也不是多人语音分离的默认方案；它的主要对象是音乐混音中的源拆分，标准评测语料是 MUSDB / MUSDB18-HQ。

## 2. 架构演进

```text
waveform mixture
  -> waveform U-Net encoder
  -> bidirectional recurrent bottleneck
  -> waveform decoder
  -> separated music stems
```mermaid

主要版本线：

- **原始 DEMUCS**：端到端 waveform-to-waveform U-Net，使用双向 LSTM 建模长时上下文。
- **Hybrid Demucs**：同时建模 waveform 与 spectrogram 两个域，在时域保留相位和瞬态信息，在频域利用频谱结构，最后融合两路输出。
- **HT-Demucs**：在 Hybrid Demucs 的混合域瓶颈中加入 Transformer，用域内 self-attention 与跨域 attention 建模长距离依赖和 waveform/spectrogram 交互。

### 2.1. 架构示意（概念级）

> [!note] 架构示意（概念级）
> 按本页已有输入—中间表示—输出链路整理，不替代论文结构图。

```
flowchart LR
  A["Waveform mixture"] --> B["Waveform U-Net encoder"]
  B --> C["Bidirectional recurrent bottleneck"]
  C --> D["Waveform decoder"]
  D --> E["Separated sources / enhanced waveform"]
```

## 3. 标准输出

四 stem 设定通常输出：

- `vocals`：主唱与伴唱等人声；
- `drums`：鼓组与打击乐；
- `bass`：低频贝斯；
- `other`：其他伴奏和乐器。

官方实现还支持部分六 stem 设定，例如进一步拆分 guitar、piano 等，但具体输出取决于 checkpoint、训练配方和命令行配置。

## 4. 训练与评测

- **主基准**：MUSDB18 / MUSDB18-HQ。
- **常见指标**：SDR 及其变体，必要时补充 SI-SDR、源间串音和主观听感。
- **训练目标**：让估计 stem 与真实 stem 尽量一致，同时减少不同源之间的泄漏。
- **论文演进**：原始 DEMUCS 在 MUSDB 上报告了较强的平均 SDR；Hybrid Demucs 通过混合域建模进一步提升分离质量；HT-Demucs 用 Transformer 替换部分混合域瓶颈。

论文数字必须绑定具体版本、checkpoint、MUSDB 变体和是否使用额外训练数据；不能把原始 DEMUCS、Hybrid Demucs 和 HT-Demucs 的分数直接混在一张表里。

## 5. 使用判断

- **适合**：人声伴奏分离、音乐 stem 提取、混音重制、音乐编辑、伴奏生成和音乐数据预处理。
- **不适合直接替代**：NSNet2 一类实时降噪、VoiceFixer 一类通用语音恢复、会议多人语音分离或目标说话人提取。
- **优势**：端到端波形建模，能同时利用时域瞬态、频域结构和长时音乐上下文。
- **代价**：模型和推理成本高于轻量语音增强网络；对混合中未见过的乐器、强失真和复杂人声效果仍可能产生串音或伪影。
- **工程注意**：输出 stem 的命名、采样率、segment 长度、overlap-add 和 checkpoint 版本必须固定，否则结果不可直接比较。

## 6. 与语音任务的边界

- **音乐源分离（MSS）**：一首歌拆成 vocals / drums / bass / other，DEMUCS 的主任务。
- **语音分离（SS）**：多人混合语音拆成各说话人轨道，目标、数据和指标不同。
- **语音增强（SE）**：保留一路目标语音并抑制噪声/混响，通常不是 DEMUCS 的主设计目标。
- **目标说话人提取（TSE）**：需要参考说话人线索，DEMUCS 的标准四 stem 任务不包含这一条件。

在本库里，DEMUCS 更应该挂在 `Source Separation` / 音乐分离路线，而不是 `Speech Enhancement` 主线上。

## 7. 版本与实现边界

- 官方 `facebookresearch/demucs` 仓库提供 PyTorch 实现、v4 HT-Demucs、推理、训练和 model bags。
- 官方仓库已于 2025-01-01 归档并变为只读；后续 fork、封装包和第三方 UI 不应自动视为官方维护版本。
- `Hybrid Demucs` 与 `HT-Demucs` 是架构家族中的后续版本，不等同于最初的 waveform-only DEMUCS。
- 运行结果依赖 checkpoint、segment、overlap、设备和后处理设置；引用“Demucs 的 SDR”时必须写清具体版本。

## 8. 相关对象

- [[方向/AI语音/知识/基础概念/Source Separation（源分离）]]：源分离总入口，区分音乐源分离和语音分离。
- [[方向/AI语音/知识/基础概念/SS（语音分离）]]：多人语音分离的相邻任务。
- [[方向/AI语音/知识/基础概念/SE（语音增强）导论]]：单路语音增强，对照 DEMUCS 的音乐分离定位。
- [[方向/AI语音/知识/基础概念/GSR（General Speech Restoration，通用语音恢复）]]：通用语音恢复路线，非 DEMUCS 主任务。
- [[方向/AI语音/模型/VoiceFixer]]：高保真语音恢复模型，对照 DEMUCS 的音乐源分离目标。
- [[方向/AI语音/模型/NSNet2]]：实时语音降噪 baseline。

## 9. 关键来源

- [Music Source Separation in the Waveform Domain](https://arxiv.org/abs/1911.13254)
  - 内容定位：原始 DEMUCS 论文，介绍 waveform-domain U-Net 与双向 LSTM。
  - 用途：确认模型家族起点和音乐源分离任务。
  - 核验日期：2026-09-20
- [Hybrid Spectrogram and Waveform Source Separation](https://arxiv.org/abs/2111.03600)
  - 内容定位：Hybrid Demucs 论文，介绍 waveform/spectrogram 双域建模。
  - 用途：确认混合域架构和后续性能路线。
  - 核验日期：2026-09-20
- [Hybrid Transformers for Music Source Separation](https://arxiv.org/abs/2211.08553)
  - 内容定位：HT-Demucs 论文，介绍混合域 Transformer 与跨域 attention。
  - 用途：确认 v4 及 Transformer 演进。
  - 核验日期：2026-09-20
- [Official Facebook Research Demucs repository](https://github.com/facebookresearch/demucs)
  - 内容定位：官方 PyTorch 实现、v4 checkpoint、推理/训练文档和仓库归档状态。
  - 用途：工程使用与版本核验。
  - 核验日期：2026-09-20

## 10. 待验证

- [ ] 固定本地使用的 Demucs checkpoint、stem 设定、segment/overlap 和输出采样率。
- [ ] 在同一 MUSDB18-HQ split 下记录 SDR、串音和推理耗时，避免混用不同版本的官方数字。

---
title: "FSD50K（Freesound Dataset 50K）"
类型: 数据集
发表时间: "2020-10-02"
时间依据: Zenodo v1.0 发布日期；论文发表于 2022
任务:
  - 声音事件分类
  - 音频标签
  - 弱监督学习
  - 声音事件检测（可扩展用途）
相关基准:
  - AudioSet Ontology
  - Freesound
aliases:
  - FSD50K
  - Freesound Dataset 50K
  - FSD 50K
tags:
  - 类型/对象
  - 方向/AI语音
  - 任务/声音事件分类
  - 任务/音频标签
  - 任务/弱监督学习
  - 资源/数据集
---

# FSD50K（Freesound Dataset 50K）

## 1. 身份

`FSD50K`（Freesound Dataset 50K）是一个基于 Freesound 音频、采用人工标签、面向大词表声音事件识别的开放数据集。它包含 51,197 个音频片段、超过 100 小时音频，并使用 AudioSet Ontology 中的 200 个类别。

它的主要设计目标是**多标签声音事件分类/音频标签**，同时可被用于弱监督声音事件检测、表示学习和跨数据集实验。它不是一个以逐帧起止时间标注为核心的强标签 SED 数据集。

## 2. 数据规模与划分

| 维度 | 总计 | Dev | Eval |
|---|---:|---:|---:|
| 音频片段 | 51,197 | 40,966（80.0%） | 10,231（20.0%） |
| 时长 | 108.3h | 80.4h | 27.9h |
| 类别 | 200 | — | — |
| 上传者 | 7,225 | 4,936 | 2,289 |
| 平均标签数/片段 | 1.22 | 1.11 | 1.67 |
| 单片段时长 | 0.3–30 秒 | — | — |

音频为单声道、16-bit、44.1 kHz PCM；片段长度可变，而不是固定的 10 秒切片。

论文将开发集进一步拆为 train 与 val，用于训练和验证；eval 主要用于系统比较。由于 Freesound 的上传者可能贡献多个相似或相关片段，数据划分强调**上传者不跨 split**，以减少内容污染和过高估计泛化能力。

## 3. 标签与标注口径

- 200 个类别来自 AudioSet Ontology 的一个子集，类别分布不均衡。
- 标签主要是**片段级弱标签**，表示某类声音是否出现在片段中，不提供标准化的 onset/offset 时间戳。
- 标注流程区分声音是否“存在且占主导”（Present and predominant）与“存在但不占主导”（Present but not predominant），因此标签不只是简单的二元 presence。
- 短片段中的事件可能接近整段音频，表现出准强标签特征；长片段的片段级标签则更弱。
- 数据包含 ground truth、Freesound 元数据以及数据创建过程中的辅助元数据。

## 4. 数据集构建逻辑

```text
Freesound 音频
  -> AudioSet Ontology 关键词与候选标签
  -> 候选片段筛选
  -> 人工标签验证与质量控制
  -> 按上传者等规则划分 dev / eval
  -> 对 eval 做更充分的标签复核
  -> 发布 waveform、ground truth 与元数据
```

FSD50K 的重要动机是为 AudioSet 提供一个更容易复现的开放替代：AudioSet 的原始 YouTube 音频并不以可稳定再分发的 waveform 形式发布，而 FSD50K 直接发布音频波形与相关标注。

## 5. 研究用途

- **多标签声音事件分类**：判断一个片段中出现了哪些声音事件。
- **音频标签与检索**：使用 200 类共享词表建立大词表音频标签系统。
- **弱监督声音事件检测**：研究如何从片段级标签学习时间定位能力，但需要额外的模型假设或伪强标签策略。
- **表示学习与迁移**：与 AudioSet Ontology 共享部分词表，便于做跨数据集评测或域适配。
- **数据集构建方法研究**：分析人工验证、上传者划分、评测集精修和 Freesound 数据偏差。

## 6. 论文与基准观察

原始论文的重点不只是“数据量大”，还包括数据集构建与评测设计：

- 评测集的质量和代表性比单纯扩大训练集更关键。
- 对 Freesound 数据，按上传者划分是控制泄漏和相似片段污染的重要条件。
- 变长音频与片段级弱标签会给固定窗口训练带来“伪强标签”风险：把整段标签直接复制到每个 patch，可能在没有目标事件的 patch 上制造错误正例。
- FSD50K 的开放 waveform、较大词表和 AudioSet Ontology 对齐，使其适合做可复现的声音事件分类基准；但它不能自动替代强标签 SED 数据集。

## 7. 使用边界

- **标签边界**：没有统一的逐帧起止时间标注，不能直接当作强标签 SED 训练集。
- **长度边界**：0.3–30 秒的变长片段要求模型明确处理 padding、裁剪、patch 聚合和 clip-level pooling。
- **分布边界**：数据来自 Freesound 用户上传，存在录音设备、上传者、内容选择和标签难度偏差。
- **类别边界**：200 类是 AudioSet Ontology 的子集，不代表完整 AudioSet 词表，也不等于家庭、城市或工业声景的完整覆盖。
- **评测边界**：应明确使用 dev 的哪个 validation split，以及是否使用外部数据或预训练模型。
- **许可证边界**：数据集包含不同 Creative Commons 许可，代码许可与音频内容许可不是一回事；再分发和商业使用必须逐文件核验。

## 8. 相关对象

- [[方向/AI语音/数据集/DESED（Domestic Environment Sound Event Detection）]]：同属声音事件识别/检测数据线；DESED 更强调家庭环境和合成/真实标签组合，FSD50K 更强调大词表、开放 waveform 与片段级弱标签。

## 9. 关键来源

- [FSD50K 官方 companion site](https://fsannotator.upf.edu/fsd/release/FSD50K/)
  - 内容定位：数据集定位、规模、200 类词表、开发/评测划分和 Freesound 元信息。
  - 用途：确认对象身份与官方入口。
  - 核验日期：2026-09-20
- [FSD50K v1.0 Zenodo record](https://zenodo.org/records/4060432)
  - 内容定位：下载文件、ground truth、词表、元数据、版本和 DOI。
  - 用途：核验 v1.0 发布日期、音频格式、片段时长与许可证说明。
  - 核验日期：2026-09-20
- [FSD50K: an Open Dataset of Human-Labeled Sound Events](https://arxiv.org/abs/2010.00475)
  - 内容定位：数据集构建流程、划分原则、标注限制、基线实验和使用注意事项。
  - 用途：记录数据设计逻辑与证据边界。
  - 核验日期：2026-09-20
- [Published paper PDF](https://signalprocessingsociety.org/sites/default/files/uploads/publications_resources/docs/FSD50KFonseca.pdf)
  - 内容定位：正式论文全文、数据统计表和实验细节。
  - 用途：核验 51,197 片段、108.3 小时、dev/eval 统计与弱标签讨论。
  - 核验日期：2026-09-20

## 10. 待验证

- [ ] 如需复现，补录官方 baseline 仓库、依赖和推荐的 train/val split。
- [ ] 在实际发布或商用前，逐文件核验音频的 Creative Commons 许可证与署名要求。

---
title: "TUT Urban Acoustic Scenes 2018（城市声学场景数据集）"
类型: 数据集
发表时间: "2018"
时间依据: DCASE 2018 Task 1 / dataset release
任务:
  - 声学场景分类
  - 设备失配鲁棒性评估
  - 环境声音识别
相关基准:
  - DCASE 2018 Task 1
  - TUT Acoustic Scenes 2018 Mobile
aliases:
  - TUT Urban Acoustic Scenes 2018
  - TUT-ASC2018
  - TUT Urban ASC 2018
  - 城市声学场景分类 2018
tags:
  - 类型/对象
  - 方向/AI语音
  - 任务/声学场景分类
  - 任务/环境声音识别
  - 评测/DCASE
  - 资源/数据集
---

# TUT Urban Acoustic Scenes 2018（城市声学场景数据集）

## 1. 身份

`TUT Urban Acoustic Scenes 2018` 是 DCASE 2018 Task 1 的城市声学场景分类数据集。它把连续城市环境录音切成 10 秒片段，要求系统判断片段属于哪一种整体声学场景。

它评估的是**场景级上下文识别**，不是 `DESED` 或 `FSD50K` 那类“某个声音事件是否出现”的事件检测/标签任务；例如，目标是识别“地铁站”或“公园”，而不是定位“狗叫”或“警报”出现的时间。

## 2. 目标场景

数据集包含 10 类城市环境：

| 类别 | 含义 |
|---|---|
| `airport` | 机场 |
| `shopping_mall` | 购物中心 |
| `metro_station` | 地铁站 |
| `pedestrian_street` | 步行街 |
| `public_square` | 公共广场 |
| `street_traffic` | 交通街道 |
| `tram` | 有轨电车 |
| `bus` | 公交车 |
| `metro` | 地铁车厢 |
| `park` | 公园 |

## 3. 数据规模与录音设置

- **录音城市**：六个欧洲大城市。
- **场景采集**：每个地点约 5–6 分钟连续录音。
- **片段长度**：10 秒。
- **开发集规模**：8,640 个片段，约 24 小时；官方任务划分为 6,122 个训练片段和 2,518 个测试片段。
- **主设备**：Device A，双耳麦克风，48 kHz / 24-bit。
- **移动设备扩展**：提供多个录音设备的变体，用于研究设备失配和域偏移。

开发集按地点/录音来源组织，而不是把同一连续录音的相邻窗口随机打散到 train/test；复现实验时应沿用官方 split。

## 4. 任务与评测

标准任务是对每个 10 秒片段输出一个声学场景类别。核心问题包括：

- 场景之间的整体声学纹理与长时上下文建模；
- 录音设备、频响和携带方式变化带来的域偏移；
- 同一场景内不同地点、时段和人流密度造成的类内变化。

官方任务通常以分类准确率及其按场景/设备拆分的结果比较系统。报告结果时应说明使用的是 device-A development split、mobile track 还是 leaderboard/evaluation release。

## 5. 研究用途

- **声学场景分类**：训练 CNN、CRNN、Transformer 或 audio embedding 模型识别城市环境。
- **设备失配鲁棒性**：比较训练设备与测试设备不同情况下的性能下降。
- **环境声音表征**：作为城市环境声的分类基准或预训练/迁移评测集。
- **域泛化与增强**：研究设备模拟、频谱增强、录音条件归一化和跨城市泛化。

## 6. 使用边界

- **场景 vs 事件**：标签描述整个 10 秒片段的环境，不提供事件起止时间；不要把场景准确率直接解释成事件检测能力。
- **城市域边界**：数据来自有限的欧洲城市与固定场景类别，不等于全球城市声景覆盖。
- **设备边界**：device-A 与 mobile track 反映的是特定设备组合，不能代表所有手机、耳机或麦克风。
- **切分边界**：连续录音切片存在强相关性，必须尊重官方 split，避免随机窗口切分造成泄漏。
- **任务边界**：它适合 acoustic scene classification；若需要事件级标签、强时间标注或重叠事件评测，应转向 [[方向/AI语音/数据集/DESED（Domestic Environment Sound Event Detection）]]、[[方向/AI语音/数据集/FSD50K（Freesound Dataset 50K）]] 等对象。
- **许可证边界**：不同发布包的许可与使用条款应以对应 Zenodo 记录和官方任务页为准，发布前单独核验。

## 7. 相关对象

- [[方向/AI语音/数据集/DESED（Domestic Environment Sound Event Detection）]]：声音事件检测 benchmark；标签粒度与 TUT Urban Acoustic Scenes 不同。
- [[方向/AI语音/数据集/FSD50K（Freesound Dataset 50K）]]：大词表、片段级声音事件标签数据集；可用于对照 scene classification 与 sound event tagging。

## 8. 关键来源

- [DCASE 2018 Task 1：Acoustic Scene Classification](https://dcase.community/challenge2018/task-acoustic-scene-classification)
  - 内容定位：任务定义、10 类场景、录音城市、设备设置和官方 split。
  - 用途：核验任务边界与评测口径。
  - 核验日期：2026-09-20
- [TUT Urban Acoustic Scenes 2018 Development Dataset](https://zenodo.org/records/1228142)
  - 内容定位：开发集音频、元数据与文档。
  - 用途：核验 8,640 片段、约 24 小时和开发集文件。
  - 核验日期：2026-09-20
- [TUT Urban Acoustic Scenes 2018 Evaluation Dataset](https://zenodo.org/records/1293883)
  - 内容定位：官方评测集发布记录。
  - 用途：区分 development 与 evaluation release。
  - 核验日期：2026-09-20
- [A multi-device dataset for urban acoustic scene classification](https://arxiv.org/abs/1807.09840)
  - 内容定位：数据集论文，介绍多城市、多设备采集和分类任务。
  - 用途：记录数据设计动机、设备失配问题与研究边界。
  - 核验日期：2026-09-20

## 9. 待验证

- [ ] 补录 mobile track 的完整设备列表、每类片段数量和官方 scoring script。
- [ ] 如用于迁移学习，固定官方 split 与自定义跨城市/跨设备 split，避免把两个口径混在一起。

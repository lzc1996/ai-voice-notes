---
title: "DESED（Domestic Environment Sound Event Detection）"
类型: 数据集
发表时间: "2020"
时间依据: DCASE 2020 Task 4 / DESED benchmark
任务:
  - 声音事件检测
  - 声音分离（DCASE 2020 联合任务）
  - 半监督学习
aliases:
  - DESED
  - Domestic Environment Sound Event Detection
  - DESED dataset
tags:
  - 类型/对象
  - 方向/AI语音
  - 任务/声音事件检测
  - 任务/声音分离
  - 评测/DCASE
  - 资源/数据集
---

# DESED（Domestic Environment Sound Event Detection）

## 1. 身份

`DESED`（Domestic Environment Sound Event Detection）是围绕**家庭环境声音事件检测**建立的数据集与 DCASE 任务基准。它把真实录音的弱标签/无标签数据，与合成 soundscape 的强标签数据组合起来，用于研究弱监督、半监督和合成数据辅助的声音事件检测。

DESED 更适合被理解为一个随 DCASE 年份演进的 benchmark family，而不是一份完全静态、只有一个下载版本的数据包：DCASE 2020 同时研究声音事件检测与声音分离，DCASE 2022 的 Task 4 则聚焦声音事件检测。

## 2. 目标事件

公开任务围绕 10 类家庭环境事件：

| 类别 | 含义 |
|---|---|
| `speech` | 人声 |
| `dog` | 狗叫 |
| `cat` | 猫叫 |
| `alarm_bell_ringing` | 警报、铃声或敲铃 |
| `dishes` | 餐具声 |
| `frying` | 炒制或煎炸声 |
| `blender` | 搅拌机声 |
| `running_water` | 流水声 |
| `vacuum_cleaner` | 吸尘器声 |
| `electric_shaver_toothbrush` | 电动剃须刀或电动牙刷声 |

## 3. 数据构成

### 3.1. DCASE 2022 Task 4 开发数据

官方任务页给出的开发集组成包括：

- **真实弱标签数据**：1,578 个已核验的弱标签片段。
- **真实无标签数据**：14,412 个同域无标签片段。
- **合成强标签数据**：10,000 个 synthetic strongly labeled clips。
- **验证集**：1,168 个片段，包含 4,093 个事件。
- **片段长度与任务口径**：以 10 秒家庭环境音频片段为主。

真实数据提供更接近部署的录音分布，合成数据提供精确的事件起止时间，二者共同支撑弱监督/半监督训练。

### 3.2. DCASE 2020 任务扩展

DCASE 2020 还提供或使用了：

- 真实弱标签录音；
- 真实无标签录音；
- 合成强标签 soundscapes；
- 隔离事件与背景录音，用于合成和分离实验；
- 围绕重叠事件与背景干扰的检测-分离联合评测。

采样率需要按子集与任务版本区分：真实录音通常为 44.1 kHz，合成数据与基线流程常使用 16 kHz。

## 4. 评测口径

DCASE 2022 Task 4 主要使用 **PSDS（Polyphonic Sound Detection Score）**，并通过不同场景分别强调：

- 事件定位速度与时间边界质量；
- 类别混淆控制与检测可靠性。

因此，DESED 的结果不能只用一个普通 F1 数字概括；比较论文或系统时，需要同时记录任务年份、PSDS 场景、标签类型和是否使用外部数据/预训练模型。

## 5. 研究用途

- **声音事件检测**：评估家庭环境中多事件、多标签和重叠事件检测。
- **弱监督/半监督学习**：利用少量弱标签、无标签真实录音和强标签合成录音的组合。
- **合成数据有效性研究**：观察精确事件边界是否能弥补真实强标注的缺失。
- **检测与分离联动**：在 DCASE 2020 口径下，研究分离是否能改善事件检测，尤其是重叠事件和非目标声音干扰场景。

## 6. 论文与基准观察

DESED synthetic soundscapes 的 benchmark 研究指出：

- 事件的时间定位仍然是主要难点；
- 混响和非目标声音会显著降低检测质量；
- 源分离对处理非目标声音干扰具有潜在帮助，但不应被理解为对所有检测场景都自动有效。

这些是特定 benchmark 设计下的观察，不等于对所有家庭环境录音或所有 SED 模型的普遍定律。

## 7. 使用边界

- **版本边界**：DCASE 2020 与 DCASE 2022 的任务定义不同；引用结果时必须写明年份和 Task。
- **域边界**：类别集中在家庭环境，不代表通用城市声景、工业声景或会议声景。
- **标注边界**：真实录音与合成录音的标签精度不同；合成强标签不能直接等同于真实录音中的人工强标签。
- **分布边界**：合成 soundscape、真实弱标签和真实无标签数据之间存在域差异，训练收益依赖混合比例与增强策略。
- **许可证边界**：DESED 仓库代码为 MIT 许可，但数据集及其组成资源保留各自许可证，不能把代码许可当成数据再分发许可。
- **采样率边界**：真实录音、合成数据和基线流程的采样率可能不同，复现实验时要固定重采样口径。

## 8. 相关对象

- [[方向/AI语音/信息源/语音会议与期刊]]：DCASE 是该信息源页跟踪的声音事件检测与语音评测入口之一。

## 9. 关键来源

- [DCASE 2022 Task 4：Sound Event Detection in Domestic Environments](https://dcase.community/challenge2022/task-sound-event-detection-in-domestic-environments)
  - 内容定位：任务定义、开发集组成、10 类事件、验证集规模与 PSDS 评测口径。
  - 用途：核验当前公开任务的对象边界和评测定义。
  - 核验日期：2026-09-20
- [DESED 官方仓库](https://github.com/turpaultn/DESED)
  - 内容定位：下载工具、元数据、合成 soundscape 生成、类别列表和基线入口。
  - 用途：核验资源组织、代码许可与复现入口。
  - 核验日期：2026-09-20
- [DCASE 2020 Task 4：Sound Event Detection and Separation in Domestic Environments](https://dcase.community/challenge2020/task-sound-event-detection-and-separation-in-domestic-environments)
  - 内容定位：检测与分离联合任务、数据子集和采样率口径。
  - 用途：记录 DESED 的历史任务边界与分离研究线。
  - 核验日期：2026-09-20
- [Sound Event Detection and Separation: a Benchmark on DESED Synthetic Soundscapes](https://arxiv.org/abs/2011.00801)
  - 内容定位：合成 soundscape benchmark 的研究问题与主要观察。
  - 用途：记录定位、混响、非目标声音和分离收益的证据边界。
  - 核验日期：2026-09-20

## 10. 待验证

- [ ] 按具体 DCASE 年份补录训练集、开发集和评测集的完整文件清单。
- [ ] 如需复现，固定采样率、外部数据许可和 PSDS 场景后再对比结果。

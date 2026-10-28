---
title: AISHELL-4（中文会议语料库）
类型: 数据集
发表时间: 2021-04-08
时间依据: arXiv 首次提交日（Interspeech 2021 接收）
aliases:
  - AISHELL-4
  - AISHELL4
  - AISHELL-4 中文会议语料库
  - AISHELL-4 多通道会议数据集
tags:
  - 类型/对象
  - 方向/AI语音
  - 任务/会议转写
  - 任务/多通道增强
  - 任务/说话人分离
  - 资源/数据集
---

# AISHELL-4（中文会议语料库）

## 1. 身份

`AISHELL-4` 是 2021 年发布的中文会议语料库（Interspeech 2021，arXiv:2104.03603）：**真实录制**的会议室场景多通道数据，8 麦圆阵采集，共 120 小时、211 场会议，每场 4–8 名说话人，面向会议场景的语音前端增强、分离、识别与说话人日志（diarization）。

边界：不是仿真或重录数据（区别于 LibriCSS 的扬声器重录路线），全部为真实会议室中的自然对话；论文称发布时是唯一公开的中文会话类多说话人语料（此前公开多说话人会议集几乎均为英文）。

团队：西北工业大学 ASLP（通讯作者 Lei Xie）、微软、北京希尔贝壳（AISHELL 数据方）、中科大（Jun Du）。

## 2. 数据构成

| 维度 | 内容 |
|------|------|
| 语言 | 中文普通话（母语说话人，无强口音） |
| 规模 | 120 小时 / 211 场会议，每场约 30 分钟讨论 |
| 说话人 | 每场 4–8 人；训练集 36 人、评估集 25 人，性别均衡 |
| 采集设备 | 桌面 8 麦圆阵 + 每位参会者头戴麦近讲参考（用于对齐与标注选优） |
| 场地 | 10 个会议室，小 / 中 / 大三类（7×3×3 至 15×7×3 m³），墙面含水泥、玻璃等 |
| 距离 | 麦克风-说话人 0.6–6.0 m |
| 重叠率 | 训练集平均 19.04%，评估集平均 9.31% |
| 噪声 | 真实室内噪声：敲击、键盘、开关门、风扇、气泡音等，由参会者自然制造 |
| 标注 | TextGrid：段级时间戳与转写、说话人信息（数量 / id / 性别）、非语音事件（停顿 / 笑 / 咳嗽 / 呼吸）、重叠段标记 |
| 许可 | 数据 CC BY-SA 4.0（OpenSLR SLR111）；基线代码 Apache 2.0 |

## 3. 用途

- **真实场景多通道前端增强 / 分离**：真实混响、重叠说话与室内噪声，官方 baseline 即 mask 估计 + MVDR 波束形成路线。
- **会议 ASR / speaker-attributed ASR**：段级转写与说话人归属齐备。
- **Speaker diarization**：提供每场的 speaker voice activity 标注。
- **联合优化 / 多模态建模**：论文定位目标之一（从单任务到相关任务联合优化）。
- **中文会议数据多样性**：弥补公开多说话人会议语料以英文为主的缺口。

## 4. 划分口径

| 划分 | 规模 | 说明 |
|------|------|------|
| 训练集 | 107.50 小时 / 191 场 | 参会者在录音期间保持位置固定 |
| 评估集 | 12.72 小时 / 20 场 | 参会者可在小范围内自然移动 |

- 训练 / 评估无房间重叠，仅 1 名说话人重叠。
- 论文口径只给 train / eval 两划分；baseline 的仿真训练数据另有开发集（仿真 364h 训练 / 10h 开发），真实录音侧未单列官方 dev。
- baseline 前端仿真数据口径：LibriSpeech 460h 干净语音 + MUSAN / AudioSet 噪声，按 8 麦阵列拓扑仿真 RIR（RT60 0.2–0.8 s，SNR [5, 20] dB，SDR [-5, 5] dB，重叠率三档均匀配比）。

## 5. Baseline 与结果口径

- 链路：diarization（Kaldi CHiME-6 SAD + ResNet x-vector + AHC / VBx 聚类）→ 前端分离（3 层 LSTM mask 估计，输入为通道 1 幅度谱 + 4 对麦克风 cosIPD，PIT 训练，mask-based MVDR，最多 2 说话人假设）→ Transformer ASR（joint CTC / CE）。
- 指标：**speaker independent CER**（用真值边界切分，只评前端 + ASR）与 **speaker dependent CER**（全链路，含 diarization），由 Asclite 多假设对齐计算。
- 结果：SI CER 32.56%（无前端）→ 30.49%（加前端）；SD CER 41.55% → 39.86%。
- 代码：PyTorch 训练与评测框架 felixfuyihui/AISHELL-4（Apache 2.0），含 data_preparation / front_end / asr / sd / evaluation 五模块。

## 6. 使用注意

- **中文指标看 CER 不看 WER**：官方口径为 SI / SD 两种 CER，跨论文比较必须先核对口径。
- **训练 / 评估重叠率分布不同**：19.04% vs 9.31%，评估集相对更容易；且评估集允许说话人小范围移动，与训练集条件不完全对齐。
- **不要与仿真 / 重录集混用口径**：LibriCSS（重录）、SMS-WSJ（仿真）与 AISHELL-4（真实录制）声学条件不同，前端指标不能直接横比。
- **baseline 仅为 2021 参考线**：前端最多假设 2 说话人、diarization 不处理重叠说话；与后续系统比较时需注明基线口径。
- 采样率、阵列几何等工程参数未在论文正文明示，以下载数据实际口径为准（见待验证）。

## 7. 关键来源

- [AISHELL-4 论文（arXiv:2104.03603，Interspeech 2021）](https://arxiv.org/abs/2104.03603)
  - 内容定位：原始论文摘要页，数据集定位、规模（120h / 211 场 / 4–8 人）与接收信息。
  - 用途：核验对象身份、任务定位与发表口径。
  - 核验日期：2026-08-18
- [AISHELL-4 论文 HTML 全文（v4）](https://arxiv.org/html/2104.03603v4)
  - 内容定位：全文细节——场地尺寸、距离范围、重叠率统计、近讲头戴麦参考、仿真参数与 baseline 公式及 CER 结果。
  - 用途：核验数据构成表、划分口径与 baseline 链路。
  - 核验日期：2026-08-18
- [OpenSLR SLR111](https://www.openslr.org/111/)
  - 内容定位：官方下载镜像，CC BY-SA 4.0 许可、提供方（北京希尔贝壳）与引用信息。
  - 用途：确认许可与下载入口。
  - 核验日期：2026-08-18
- [felixfuyihui/AISHELL-4（GitHub）](https://github.com/felixfuyihui/AISHELL-4)
  - 内容定位：官方 PyTorch baseline 仓库，SI / SD 任务定义与评测流程，代码 Apache 2.0。
  - 用途：复现基线、核对任务口径。
  - 核验日期：2026-08-18
- [AISHELL 官方产品页](http://www.aishelltech.com/aishell_4)
  - 内容定位：公司官方入口（OpenSLR 外链指向）；本次抓取失败（页面需 JS 渲染）。
  - 用途：备选下载入口，可用性待核。
  - 核验日期：2026-08-18

## 8. 相关对象

- [[方向/AI语音/数据集/AMI Meeting Corpus（会议语料库）|AMI Meeting Corpus]]：英文会议语料对标对象（多模态、IHM / SDM / MDM 口径）。
- [[方向/AI语音/评估/NOTSOFAR-1（远场会议转写挑战）|NOTSOFAR-1]]：更现代的远场会议转写挑战（英文，已知阵列几何）。
- [[方向/AI语音/评估/CHiME（语音分离与识别挑战赛）|CHiME]]：baseline 的 diarization 沿用 CHiME-6 方案。
- [[方向/AI语音/知识/基础概念/MVDR（最小方差无失真响应）|MVDR]]：baseline 前端的核心波束形成器。
- [[方向/AI语音/知识/基础概念/IPD（通道间相位差）|IPD]]：baseline 分离网络的空间特征输入。
- [[方向/AI语音/评估/CER（Character Error Rate）|CER]]：官方评测指标口径。
- [[方向/AI语音/团队/NWPU ASLP Lab（西工大 ASLP 实验室）|NWPU ASLP Lab]]：主导团队（通讯作者 Lei Xie）。
- [[方向/AI语音/团队/Microsoft Speech Group（微软语音组）|Microsoft Speech Group]]：合作团队。
- [[方向/AI语音/知识/调研与地图/Array Speech Enhancement Frontier（阵列语音增强前沿调研）|阵列语音增强前沿调研]]：本库在经典评测集中的定位（"8 麦圆阵约 120h 中文会议"）。

## 9. 待验证

- 音频采样率 / 位深与圆阵几何参数（直径、麦间距）：论文正文未明示，需以下载数据实际口径为准。
- 近讲头戴麦信号是否随公开数据一同发布，还是仅用于内部标注对齐。
- 官方产品页 aishelltech.com/aishell_4 的当前可用性（本次抓取因 JS 渲染失败）。
- 后续主流系统在 AISHELL-4 上的对比口径（[[方向/AI语音/知识/基础概念/CSS（连续语音分离）|CSS]]、神经 diarization、端到端 speaker-attributed ASR 的 CER）。
- 是否需要为 AliMeeting / M2MeT 建独立页并与本页互链（中文 8 麦会议姊妹集）。

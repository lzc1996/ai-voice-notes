---
title: AliMeeting（阿里会议语料库）
类型: 数据集
发表时间: 2021-10-14
时间依据: arXiv 首次提交日（ICASSP 2022 接收）
aliases:
  - AliMeeting
  - AliMeeting Corpus
  - 阿里会议语料库
  - AliMeeting 中文会议语料库
  - M2MeT
  - M2MeT 挑战赛
tags:
  - 类型/对象
  - 方向/AI语音
  - 任务/会议转写
  - 任务/说话人日志
  - 任务/ASR
  - 资源/数据集
---

# AliMeeting（阿里会议语料库）

## 1. 身份

`AliMeeting` 是阿里巴巴 Speech Lab 联合 AISHELL Foundation、北京希尔贝壳发布的中文会议语料库（ICASSP 2022，arXiv:2110.07393）：**真实录制**的会议室场景多通道数据，桌面 8 通道指向性麦克风阵列采远场 + 每位参会者头戴麦采近场，共 **118.75 小时**（摘要口径约 120 小时），每场会议 2–4 名说话人、15–30 分钟自由讨论，面向 speaker diarization 与多说话人 ASR。

边界：不是仿真或重录数据，全部为真实会议室自然对话；发布时与 [[方向/AI语音/数据集/AISHELL-4|AISHELL-4]] 是仅有的两个公开中文会议数据集，AliMeeting 在其基础上增加说话人数与会议场地数，并特意加入高重叠率的多人讨论。

同时它是 **ICASSP 2022 M2MeT 挑战赛**（Multi-channel Multi-party Meeting Transcription）的官方数据：挑战赛以 AliMeeting + Aishell-4 为训练数据，设 speaker diarization 与 multi-speaker ASR 两个 track。

团队：Alibaba Group Speech Lab（中国 / 新加坡）、AISHELL Foundation、北京希尔贝壳（作者 Fan Yu、Shiliang Zhang、Yihui Fu、Lei Xie、Siqi Zheng 等）。

## 2. 数据构成

| 维度 | 内容 |
|------|------|
| 语言 | 中文普通话（母语说话人，无强口音） |
| 规模 | 118.75 小时（Train/Eval/Test 合计；摘要口径约 120 小时） |
| 会议 | Train 212 场、Eval 8 场、Test 20 场（OpenSLR 口径），每场 15–30 分钟 |
| 说话人 | 每场 2–4 人；Train 456 人、Eval 25 人，性别均衡；Train / Eval 无说话人重叠 |
| 采集设备 | 桌面 8 通道指向性麦克风阵列（远场）+ 每位参会者头戴麦（近场），远近场同步到同一时间轴 |
| 场地 | 13 个会议室，小 / 中 / 大三类（8–55 m²），墙面含水泥、玻璃等 |
| 距离 | 麦克风-说话人 0.3–5.0 m |
| 重叠率 | Train 平均 42.27%，Eval 平均 34.76%（特意覆盖高重叠多人讨论） |
| 噪声 | 真实室内噪声：敲击、键盘、开关门、风扇、气泡音等，由参会者自然制造 |
| 标注 | TextGrid：段级时间戳与转写、说话人信息（数量 / id / 性别）、非语音事件（停顿 / 噪声 / 重叠） |
| 许可 | OpenSLR 页标注免费下载，具体 license 条款未见（见待验证） |

## 3. 用途

- **会议 ASR / 多说话人 ASR**：高重叠率中文会议，SOT 类序列化输出方法的常用训练 / 评测数据。
- **Speaker diarization**：2–4 人、高重叠、真实室内噪声，M2MeT Track 1 官方数据。
- **真实场景多通道前端增强 / 波束形成**：8 通道远场阵列真实录音 + 近讲参考，适合评估 beamforming 前端对下游转写的收益。
- **Speaker-attributed ASR / 会议富转写**：同时考验识别内容与说话人归属（"who speaks what at when"）。
- **中文会议数据多样性**：弥补公开会议语料以英文为主的缺口，是 [[方向/AI语音/数据集/AISHELL-4|AISHELL-4]] 的姊妹集。

## 4. 划分口径

| 划分 | 规模 | 说明 |
|------|------|------|
| Train | 104.75 小时 / 212 场 | 挑战赛开始即发布 |
| Eval | 4 小时 / 8 场 | 随 Train 一同发布 |
| Test | 10 小时 / 20 场（OpenSLR 口径） | 挑战赛最终打分阶段才发布音频；只提供远场 8 通道音频 + 句级分割时间戳，不给头戴麦音频与转写 |

- Test 的句级分割时间戳由重叠段合并生成（合并重叠段直到无重叠为止）。
- Train / Eval 录制时参会者保持位置固定。

## 5. M2MeT 挑战赛口径

- **Track 1 Speaker Diarization**：指标 DER（speaker confusion + false alarm + missed detection 时长占比），Hungarian 算法对齐，挑战赛只比 0.25 s collar；Test 只给远场 8 通道音频与句级时间戳，要求输出每场 RTTM。
- **Track 2 Multi-Speaker ASR**：指标 CER；重叠段两种计法——utterance-based FIFO（按开始时间排序、`<sc>` 拼接）与按说话人合并后全排列，baseline 实验采用 FIFO。
- **Sub-track I（受限数据）**：仅可用 AliMeeting、Aishell-4、CN-Celeb；**Sub-track II**：不限数据，但须在系统描述中列出所用数据与仿真方案。

## 6. Baseline 与结果口径

- **前端**：取阵列第 1 通道为 Ali-far；CDDMA Beamformer 输出为 Ali-far-bf；头戴麦近讲为 Ali-near；实验均基于单通道数据。
- **Diarization baseline**：CHiME-6 Kaldi 系统——ResNet 说话人 embedding（CN-Celeb 训练）+ PLDA + AHC 预聚类 + VBx 聚类；提供分割时间戳（oracle SAD）。
- **ASR baseline**：ESPnet Conformer（12 层 encoder / 6 层 decoder）+ SOT（Serialized Output Training，`<sc>` 标记说话人切换），4950 常用汉字建模单元；结论级口径：SOT 多说话人模型显著优于单说话人模型，beamformer 前端在 Ali-far-bf 上有正向收益。
- **具体 DER / CER 数值未核验**（论文 Table 3/4/5，本次抓取的 HTML 表格内容缺失，见待验证）。
- 代码：yufan-aslp/AliMeeting（GitHub），含 ASR 与 diarization 两个 track 的 recipe。

## 7. 使用注意

- **中文指标看 CER / DER**：跨论文比较必须核对 CER 计法（FIFO vs 全排列）与 DER collar（0 vs 0.25 s）。
- **重叠率明显高于 AISHELL-4**：42.27% / 34.76% vs 19.04% / 9.31%，AliMeeting 更侧重高重叠讨论场景，难度口径不能直接横比。
- **Test 集口径特殊**：仅远场音频 + 分割时间戳，无公开转写（挑战赛打分用）；公开下载是否含 Test 需以实际数据为准。
- **不要与仿真 / 重录集混用口径**：与 LibriCSS（重录）、SMS-WSJ（仿真）声学条件不同，前端指标不能直接横比。
- 采样率、阵列几何等工程参数未在论文正文明示（见待验证）。

## 8. 关键来源

- [M2MeT 论文摘要页（arXiv:2110.07393，ICASSP 2022）](https://arxiv.org/abs/2110.07393)
  - 内容定位：摘要与提交历史（v1 2021-10-14），120 小时、8 麦阵列 + 头戴麦、2–4 说话人、双 track 定位。
  - 用途：核验对象身份、规模口径与挑战赛定位。
  - 核验日期：2026-08-10
- [M2MeT 论文 HTML 全文（v3）](https://arxiv.org/html/2110.07393v3)
  - 内容定位：全文细节——118.75h 划分（104.75/4/10）、13 场地 8–55 m²、距离 0.3–5.0 m、重叠率 42.27% / 34.76%、DER / CER 评测定义、CDDMA / SOT baseline。
  - 用途：核验数据构成表、划分口径、挑战赛规则与 baseline 链路。
  - 核验日期：2026-08-10
- [OpenSLR SLR119](https://www.openslr.org/119/)
  - 内容定位：官方下载镜像（Alibaba Group 提供），118.75h 划分、212 / 8 / 20 场会议口径、M2MeT 介绍与引用 BibTeX。
  - 用途：确认下载入口与场次数口径。
  - 核验日期：2026-08-10
- [yufan-aslp/AliMeeting（GitHub）](https://github.com/yufan-aslp/AliMeeting)
  - 内容定位：官方 baseline 仓库，ASR 与 Speaker Diarization 两个 track 的 recipe。
  - 用途：复现基线、核对任务口径。
  - 核验日期：2026-08-10
- [M2MeT 挑战赛官网](https://www.alibabacloud.com/m2met-alimeeting)
  - 内容定位：论文脚注给出的官方挑战赛入口；本次未抓取，可用性待核。
  - 用途：挑战赛规则与结果的官方入口。
  - 核验日期：2026-08-10

## 9. 相关对象

- [[方向/AI语音/数据集/AISHELL-4|AISHELL-4]]：姊妹集（8 麦圆阵约 120h 中文会议），M2MeT 的共同训练数据。
- [[方向/AI语音/数据集/AMI Meeting Corpus（会议语料库）|AMI Meeting Corpus]]：英文会议语料对标对象。
- [[方向/AI语音/评估/NOTSOFAR-1（远场会议转写挑战）|NOTSOFAR-1]]：更现代的远场会议转写挑战（英文，已知阵列几何）。
- [[方向/AI语音/评估/CHiME（语音分离与识别挑战赛）|CHiME]]：diarization baseline 沿用 CHiME-6 的 Kaldi 方案。
- [[方向/AI语音/评估/CER（Character Error Rate）|CER]]：Track 2 评测指标口径。
- [[方向/AI语音/知识/基础概念/Beamforming（波束形成）|Beamforming]]：baseline 前端（CDDMA Beamformer）所属家族。
- [[方向/AI语音/知识/调研与地图/Array Speech Enhancement Frontier（阵列语音增强前沿调研）|阵列语音增强前沿调研]]：本库在经典评测集中的定位（"8 麦约 119h 中文会议"）。

## 10. 待验证

- Baseline 的具体 DER / CER 数值：论文 Table 3/4/5，本次抓取的 HTML 表格内容缺失。
- 音频采样率 / 位深、8 通道阵列几何（拓扑、直径、麦间距）：论文正文与 OpenSLR 页均未明示，以下载数据实际口径为准。
- 数据许可条款：OpenSLR 页标注免费下载，具体 license 未见。
- Test 集（10h / 20 场）是否随 OpenSLR 公开数据一同发布。
- 挑战赛官网 alibabacloud.com/m2met-alimeeting 的当前可用性。
- M2MeT 最终排名与 top systems 链路（ICASSP 2022 challenge summary paper，具体出处待查）。
- 是否需要为 Alibaba Speech Lab / AISHELL Foundation 建独立团队页。

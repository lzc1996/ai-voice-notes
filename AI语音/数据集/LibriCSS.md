---
title: LibriCSS
类型: 数据集
发表时间: 2020-01-30
时间依据: arXiv 首次提交日（v1 2020-01-30）
任务:
  - 语音分离
  - 会议转写
aliases:
  - LibriCSS
  - LibriCSS Dataset
  - LibriCSS 数据集
  - LibriCSS 连续语音分离数据集
tags:
  - 类型/对象
  - 方向/AI语音
  - 任务/语音分离
  - 任务/会议转写
  - 主题/远场语音
  - 主题/阵列信号
  - 资源/数据集
---

# LibriCSS

## 1. 身份

`LibriCSS` 是 Microsoft（Zhuo Chen、Takuya Yoshioka、Liang Lu、Tianyan Zhou、Zhong Meng、Yi Luo、Jian Wu、Xiong Xiao、Jinyu Li，ICASSP 2020，arXiv:2001.11482）发布的**[[方向/AI语音/知识/基础概念/CSS（连续语音分离）|连续语音分离（CSS）]]真实录音评测数据集**：把 LibriSpeech 语句拼接成"模拟会话"，在普通会议室里用扬声器重放，再用 **7 麦圆阵**远场收录。目标是把语音分离评测从"预切分、完全重叠、信号级指标（SDR/SI-SNR）"的旧范式拉到"连续流、部分重叠、以 ASR WER 为终点"的实用口径。

边界：不是语音增强/听感优化数据集，终点指标是 speaker-agnostic WER；主要变量是重叠率与真实房间混响，不覆盖强噪声主线。CSS 任务概念源自同组此前的会议转写工作（Yoshioka 等 ICASSP 2018 / ASRU 2019），因原始会议录音不公开而制作本数据集作公开替代。

## 2. 数据构成

| 维度 | 内容 |
|------|------|
| 语言 | 英语（LibriSpeech 有声书朗读） |
| 规模 | 约 10 小时，10 个 session，每 session 约 1 小时 |
| 单元 | 每 session 含 6 个 10 分钟 mini session，各占一档重叠率 |
| 重叠率（OVR） | 0%（细分 0S/0L 两档）、10%、20%、30%、40%；OVR = 重叠区总长 / 语音总长 |
| 说话人 | 每 mini session 8 人，随机选自 LibriSpeech test-clean 的 40 人；每 mini session 52–125 句 |
| 采集 | 会议室内扬声器重放 + 7 麦圆阵收录；扬声器位置每 session 随机，距阵列 33–409 cm |
| 通道口径 | 7ch 全阵列与 1ch 单通道两套测试数据 |
| 标注 | ground-truth 语句切分（与近讲参考音频互相关对齐得到）；附每 session 的 speaker enrollment 列表 |
| 获取 | 官方 GitHub 仓库脚本下载（归档存 Google Drive），含 mini-session 录音与重放源信号 |

0% 重叠细分两档：

- **0S（短静默）**：句间静默 0.1–0.5 秒，考验快速轮流说话。
- **0L（长静默）**：句间静默 2.9–3.0 秒。

## 3. 评测协议

两套协议共用同一套 Kaldi/PyKaldi2 ASR（BLSTM 声学模型，960h LibriSpeech 多条件训练，4-gram LM），分离好坏只看 WER：

- **Utterance-wise evaluation**：用 ground-truth 切分逐句分离再识别；一句输入产生多个分离假设时取 WER 最低者，等价于传统分离评测口径。
- **Continuous input evaluation**：不预切分，把 mini session 切成长段（60–120 秒、约 8–10 句，段边界落在静默处）后做分离 + 识别；用 NIST SCTK 的 asclite 把两个候选流与多份参考对齐，计 speaker-agnostic WER。这是 CSS 算法的主口径。
- **开发集**：Session0 可用作调参开发集。

## 4. 基线与结果口径

官方基线为说话人无关 CSS（Yoshioka 等 Interspeech 2018 路线）：BLSTM 估计 3 个 TF mask（两路语音 + 一路噪声，噪声 mask 供波束形成），输出两条"任一时刻至多一个说话人"的流；输出方式分谱掩码与 mask 驱动 MVDR 两种。

- **离线/批处理**：utterance-wise 评测按整句批处理。
- **在线/流式**：continuous 评测用滑窗分块（过去/当前/未来三个子窗），标准配置 1.2s–0.8s–0.4s（固有时延 1.2s，即当前窗 + 未来窗）；另有 0.8s 时延两档配置（1.6–0.8–0.0 与 0.8–0.4–0.4），结果显示保留 0.4s 未来上下文明显更好。
- 分离模型：三层 1024 单元 BLSTM + ReLU 投影，206h 人工混响混合语音训练（train-clean-100/360，T60 0.15–0.6s，各向同性噪声 SNR 0–10dB）。

代表性 WER（%，官方仓库脚本复现口径）：

| 口径 | 0S | 0L | 10% | 20% | 30% | 40% |
|------|-----|-----|------|------|------|------|
| 连续输入，不分离基线（中心麦） | 15.4 | 11.4 | 21.7 | 27.2 | 34.3 | 40.4 |
| 连续输入，7ch CSS 基线 | 11.9 | 9.7 | 13.4 | 15.1 | 19.7 | 22.0 |
| 逐句（oracle 切分），7ch 基线 | 8.3 | 8.4 | 11.6 | 16.0 | 18.4 | 21.6 |

主要结论（论文口径）：

- 少量重叠即显著推高 WER；即使 7ch MVDR，40% 与 0% 重叠间的差距仍然很大。
- 单通道分离在无重叠时反而推高 WER（引入失真）；3 麦时无重叠场景无明显收益。
- 无分离基线从 0L 到 0S WER 相对恶化 33.9%（快速轮流说话串音），CSS 把该恶化压到 22.7%。
- 参考下界：同一 ASR 在无混响版 0S/0L 上 WER 为 4.9%/5.1%。

## 5. 用途

- **CSS / 会议前端分离算法评测**：0–40% 六档重叠率支持按重叠度分解分析，是该方向事实标准基准之一。
- **ASR 终点口径**：分离收益直接以 WER 呈现，避免 SDR/SI-SNR 与实际可用性脱节。
- **阵列前端对比**：论文含 7ch/5ch/3ch（直线、三角）/1ch 消融，可对照麦克风数与阵列几何的影响。

## 6. 使用注意

- **规模小、偏朗读腔**：10 小时、源为有声书朗读，不是自然会议口语；结论外推到真实会议需谨慎（真实会议口径见 [[方向/AI语音/数据集/AMI Meeting Corpus（会议语料库）]]、[[方向/AI语音/评估/NOTSOFAR-1（远场会议转写挑战）]]）。
- **Speaker-agnostic WER**：asclite 对齐不带说话人归属，不能直接当 speaker-attributed 转写评测。
- **环境相对干净**：主要退化是混响与重叠，不覆盖强噪声场景。
- **复现要走官方脚本**：数据归档目录结构与 ASR/scoring 工具预期不同，需用仓库 dataprep 脚本重组；PyKaldi2 依赖 Docker。

## 7. 关键来源

- [Continuous Speech Separation: Dataset and Analysis（arXiv:2001.11482）](https://arxiv.org/abs/2001.11482)
  - 内容定位：原始论文摘要页，v1 2020-01-30，ICASSP 2020，Microsoft。
  - 用途：核验对象身份、CSS 任务定义与数据集动机。
  - 核验日期：2026-08-10
- [论文全文 HTML（arXiv:2001.11482）](https://arxiv.org/html/2001.11482)
  - 内容定位：论文全文，含数据构成（10h / 10 session / 6 mini session / 0–40% OVR / 7 麦圆阵 / 33–409 cm）、ASR 协议、基线配置与 Table 1–3 结论。
  - 用途：核验数据规格、评测协议、基线机制与结果口径。
  - 核验日期：2026-08-10
- [LibriCSS 官方仓库（chenzhuo1011/libri_css）](https://github.com/chenzhuo1011/libri_css)
  - 内容定位：官方评测代码、数据下载脚本、基线示例波形、WER 复现数字与 speaker enrollment 列表。
  - 用途：核验复现流程与基线 WER 表。
  - 核验日期：2026-08-10

## 8. 相关对象

- [[方向/AI语音/数据集/LibriSpeech|LibriSpeech]]：源语料（语句取自 test-clean 的 40 名说话人）。
- [[方向/AI语音/团队/Microsoft Speech Group（微软语音组）|Microsoft Speech Group]]：制作团队；CSS 路线源自该组的会议转写工作。
- [[方向/AI语音/知识/基础概念/SS（语音分离）|SS（语音分离）]]：CSS 是 SS 在连续流设定下的任务化。
- [[方向/AI语音/知识/基础概念/MVDR（最小方差无失真响应）|MVDR]]：基线输出方式之一，mask 驱动 MVDR 明显优于纯谱掩码。
- [[方向/AI语音/知识/基础概念/TF Mask（时频掩码）|TF Mask]]：基线分离模型的估计目标（两路语音 mask + 一路噪声 mask）。
- [[方向/AI语音/评估/WER（词错误率）|WER]]：唯一终点指标（speaker-agnostic 口径）。
- [[方向/AI语音/数据集/AMI Meeting Corpus（会议语料库）|AMI Meeting Corpus]]：真实会议对照；LibriCSS 是重录拼接的简化口径。
- [[方向/AI语音/评估/NOTSOFAR-1（远场会议转写挑战）|NOTSOFAR-1]]：更现代的远场会议转写基准，CSS 类前端的后续战场。
- [[方向/AI语音/知识/调研与地图/Array Speech Enhancement Frontier（阵列语音增强前沿调研）|阵列语音增强前沿调研]]：本库跟踪入口（经典评测集锚点）。

## 9. 待验证

- Table 1/2/3 的完整数值矩阵（本页仅录官方仓库脚本复现的三行代表数字；论文中 1ch/3ch/5ch 与谱掩码各行未逐一抄录）。
- Speaker enrollment 列表的使用约束细节（仓库建议按 unused_uttid 顺序使用以保证公平比较）。
- 数据归档（Google Drive）的许可条款与当前可用性。

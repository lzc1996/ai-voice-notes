---
title: SMS-WSJ（空间化多说话人 WSJ 语料库）
类型: 数据集
发表时间: 2019-10-30
时间依据: arXiv:1910.13934 v1 提交日（投稿 ICASSP 2020）
aliases:
  - SMS-WSJ
  - Spatialized Multi-Speaker Wall Street Journal
  - Spatialized Multi-Speaker WSJ
  - 空间化多说话人 WSJ
tags:
  - 类型/对象
  - 方向/AI语音
  - 任务/语音分离
  - 任务/多通道增强
  - 资源/数据集
---

# SMS-WSJ（空间化多说话人 WSJ 语料库）

## 1. 身份

`SMS-WSJ`（Spatialized Multi-Speaker Wall Street Journal）是帕德博恩大学通信工程系（Drude、Heitkaemper、Boeddeker、Haeb-Umbach）发布的**仿真多通道双人混合语音数据库**，面向多通道源分离 / 提取算法的训练、评估与细粒度分析（arXiv:1910.13934，投稿 ICASSP 2020）。

与早期 WSJ 系混合集（WSJ0-2mix 及其空间化版本）的关键差异：

- 使用**全部 WSJ0+1 语料**，并保证 train / validation / test 的**说话人集合严格不相交**（WSJ0-2mix 的训练说话人会出现在开发集）。
- 几何设置完全随机化：房间尺寸、阵列中心、阵列旋转、说话人方位全部随机采样。
- 提供每个麦克风上的语音镜像（speech image），并区分**早达 / 晚达分量**，支持 invasive 指标与去混响评估——这是真实录制集（如 CHiME-5）做不到的。

## 2. 数据构成

| 维度 | 内容 |
|------|------|
| 语音来源 | WSJ（si284 / dev93 / eval92，沿用 Kaldi WSJ 划分命名），剔除带口头标点的语句 |
| 采样率 | 8 kHz（由原始 WSJ 降采样） |
| 混合方式 | 两人混合；短语句零填充并对齐到随机均匀偏移，混合长度由较长语句决定 |
| 阵列 | 6 麦圆形阵列，直径 20 cm（半径 10 cm），位置 / 朝向随机 |
| 几何 | 源到阵列中心距离 ~ U(1 m, 2 m)；方位角均匀采样，不强制最小角距（两源可在同一方向） |
| RIR | [[方向/AI语音/知识/基础概念/ISM（Image Source Method，镜像声源法）]]（Allen & Berkley，Habets 实现）仿真；T60 ~ U(200 ms, 500 ms)；补偿飞行时间偏移 |
| 噪声 | 人工白传感器噪声，SNR ~ U(20 dB, 30 dB)（作者明确不做空间相干背景噪声仿真） |
| 附带信号 | 各麦克风语音镜像、早达（RIR 起点后 50 ms）/ 晚达分量、干净源信号 |
| 生成代码 | [github.com/fgnt/sms_wsj](https://github.com/fgnt/sms_wsj)，论文中所有表格可用代码复现 |

## 3. 划分口径

| 划分 | 混合数 | 唯一语句数 | 来源 |
|------|--------|-----------|------|
| train | 33,561 | 33,561 | si284 |
| validation | 982 | 491 | dev93 |
| test | 1,332 | 333 | eval92 |

- 说话人集合在三个划分间严格不相交；保留 Kaldi WSJ split 以兼容现成 ASR recipe。
- 对比：WSJ0-2mix 有 20,000 混合但仅 8,769 唯一语句，SMS-WSJ 的 33,561 条唯一语句全部可用于声学模型训练。

## 4. 评估口径与基线

论文本身是分离指标的批判性评估，主要结论：

- **远场混响场景推荐 BSS-Eval SDR（以干净源信号为参考）而非 SI-SDR**：SI-SDR 不允许短 FIR 滤波可解释的偏差，紧凑阵列下换参考通道会使 oracle 镜像的 SI-SDR 从 inf 掉到约 −0.3 dB；BSS-Eval SDR（允许最长 512 点滤波）对此稳健。
- **建议同时报多个互补指标（含 WER）**，降低系统钻单一指标空子的风险；数据库因开放语音镜像而支持 invasive SDR。

官方基线（test 集，Table 2）：cACGMM 空间聚类 + Souden MVDR 波束形成；Kaldi TDNN-F 声学模型 + WSJ 三元语言模型。

| 系统 | BSS-Eval SDR / dB | PESQ | STOI | WER / % |
|------|-------------------|------|------|---------|
| 未处理观测（单通道） | −0.40 | 1.50 | 0.659 | 79.03 |
| cACGMM + 掩码 | 9.55 | 1.83 | 0.780 | 39.0 |
| cACGMM + MVDR | 12.32 | 2.06 | 0.820 | 18.7 |
| oracle IBM + MVDR | 12.88 | 2.06 | 0.829 | 14.5 |
| oracle 早达镜像 | 54.42 | 2.35 | 0.862 | 7.34 |

## 5. 用途

- **多通道语音分离 / 提取的标准仿真基准**：Paderborn 系及后续多通道分离 / 增强论文常用；[[方向/AI语音/模型/TF-GridNet|TF-GridNet]] 报了 1/2/6 通道口径，[[方向/AI语音/模型/ArrayDPS|ArrayDPS]] 用 3 通道 SMS-WSJ 做无监督分离主基准。
- **分离 + 识别联合评估**：附带竞争力 Kaldi ASR 基线，可考核前端对 WER 的影响。
- **去混响与指标研究**：早达 / 晚达镜像分解支持训练预测早达分量的网络与 invasive 指标计算。

## 6. 使用注意

- **不要与 WSJ0-2mix / Spatialized WSJ0-2mix 混淆**：划分、说话人不重叠性、混响与通道数都不同，数字不能横比。
- **核对 SDR 定义**：跨论文比较时确认是 SI-SDR、BSS-Eval SDR 还是 invasive SDR，以及参考信号（源信号 / 镜像 / 早达镜像）；论文明确建议远场用 BSS-Eval SDR。
- **8 kHz 带宽**：面向 16 kHz 目标域（会议、穿戴）时只能作方法验证。
- **仿真简化**：噪声为空间白传感器噪声（非真实相干背景噪声），RIR 为 [[方向/AI语音/知识/基础概念/ISM（Image Source Method，镜像声源法）]] 仿真；真实阵列泛化需另配真实数据验证。
- **WSJ 语料授权**：生成数据库需自备 WSJ0+1（LDC 授权细节见待验证）。

## 7. 相关对象

- [[方向/AI语音/知识/技术路线/SMS-WSJ Heuristic（SMS-WSJ 启发式）]]：读 SMS-WSJ 结果时的工作性评测判断规则。
- [[方向/AI语音/团队/UPB Haeb-Umbach Group（帕德博恩大学 Haeb-Umbach 组）|UPB Haeb-Umbach Group]]：发布团队。
- [[方向/AI语音/模型/TF-GridNet|TF-GridNet]]：在 SMS-WSJ 上报 1 / 2 / 6 通道分离结果的监督式强基线。
- [[方向/AI语音/模型/ArrayDPS|ArrayDPS]]：以 3 通道 SMS-WSJ 为主基准的无监督扩散分离。
- [[方向/AI语音/数据集/WSJ0（华尔街日报语料库）|WSJ0]]：本库的语音底料（WSJ0+1 全量）与 LDC 授权来源。
- [[方向/AI语音/数据集/WHAM|WHAM]]：同为 WSJ 系混合数据集（wsj0-2mix + 真实噪声，单通道定位）。
- [[方向/AI语音/知识/基础概念/Reverberation Modeling（混响建模）|Reverberation Modeling]]：镜像法 RIR 仿真与早达 / 晚达分解。
- [[方向/AI语音/知识/基础概念/MVDR（最小方差无失真响应）|MVDR]]：官方基线的波束形成器。
- [[方向/AI语音/评估/SI-SDR|SI-SDR]]：论文批判性讨论其在远场混响场景的适用性。
- [[方向/AI语音/知识/调研与地图/Array Speech Enhancement Frontier（阵列语音增强前沿调研）|阵列语音增强前沿调研]]：SMS-WSJ 在经典评测集中的定位。

## 8. 关键资源

- [SMS-WSJ: Database, performance measures, and baseline recipe for multi-channel source separation and recognition（arXiv:1910.13934）](https://arxiv.org/abs/1910.13934)
  - 内容定位：原始论文摘要页，身份核验（Paderborn、投稿 ICASSP 2020、全部 WSJ0+1、说话人集合严格分离、几何随机化）。
  - 用途：对象身份与发布口径。
  - 核验日期：2026-08-10
- [arXiv:1910.13934 HTML 全文](https://arxiv.org/html/1910.13934)
  - 内容定位：数据库设计（33,561 / 982 / 1,332 划分、8 kHz、6 麦 20 cm 圆阵、距离 1–2 m、T60 200–500 ms、白噪 20–30 dB）、指标讨论（BSS-Eval SDR vs SI-SDR）与基线结果（Table 2）。
  - 用途：数据构成、划分口径、评估口径与基线数字。
  - 核验日期：2026-08-10
- [fgnt/sms_wsj（GitHub）](https://github.com/fgnt/sms_wsj)
  - 内容定位：官方生成代码与 recipe 仓库（论文 Sec.1 给出的地址，含 BSS recipe、指标调用与 Kaldi ASR recipe）。
  - 用途：数据库生成与结果复现入口。
  - 核验日期：2026-08-10

## 9. 待验证

- 论文是否正式收录于 ICASSP 2020 proceedings（arXiv 摘要页仅注明 "Submitted to ICASSP 2020"）。
- WSJ0+1 的 LDC 授权要求与生成数据库的实际存储 / 算力开销（论文未在抓取内容中说明）。
- GitHub 仓库当前维护状态与依赖版本可用性（未抓取仓库页面核验）。
- vault 内各模型页引用 SMS-WSJ 结果时的口径是否统一（[[方向/AI语音/模型/TF-GridNet|TF-GridNet]] 页注明 6 通道数字未核）。

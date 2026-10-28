---
title: SpatialNet
类型: 模型
参数量: small 1.2M（8kHz）/1.6M（16kHz）；large 6.5M（8kHz）/7.3M（16kHz）
发表时间: 2023-07-31
时间依据: arXiv 首次提交日（v1）；期刊版 IEEE/ACM TASLP vol. 32, 2024
任务:
  - 语音分离
  - 语音增强
  - 去混响
  - 多通道增强
团队:
  - "[[方向/AI语音/团队/Audio-WestlakeU（西湖大学音频实验室）]]"
开放状态:
  - paper
  - code
  - demo
aliases:
  - SpatialNet
  - Online SpatialNet
  - oSpatialNet
  - "SpatialNet: Extensively Learning Spatial Information for Multichannel Joint Speech Separation, Denoising and Dereverberation"
tags:
  - 类型/对象
  - 方向/AI语音
  - 任务/语音分离
  - 任务/语音增强
  - 任务/多通道增强
  - 主题/空间信息建模
---

# SpatialNet

## 0. 背景

- **证明空间信息可以纯靠网络学**：不用 IPD/ILD 手工特征、不用显式波束形成，仅靠复谱 + narrow-band/cross-band 交错建模即在 7 个基准上达到 SOTA。
- **空间 vs 频谱的清晰归因**：同位置双说话人实验 SDR 15.1→1.8 dB 显著退化，说明其主要依赖空间信息而非频谱信息——副作用是跨语言泛化好（英↔中几乎不掉点）。
- **参数/算力效率高**：large 参数 6.5M、算力约 TF-GridNet 的 1/3 而指标更强，成为"多通道判别前端"槽位的常用候选。

## 1. 身份

`SpatialNet` 是西湖大学 Changsheng Quan 与 Xiaofei Li 提出的多通道联合语音分离、去噪与去混响网络（IEEE/ACM TASLP 2024），核心主张是"充分地"从多通道复谱中学习空间信息，而非依赖手工空间特征或显式波束形成。它由其前身 NBC（Interspeech 2022 窄带 Conformer）扩展而来。

边界：SpatialNet 不是 [[方向/AI语音/知识/基础概念/Beamforming（波束形成）|beamforming]]——它不在网络内显式估计 steering vector 或空间滤波权重，而是端到端复谱映射。它是与 [[方向/AI语音/模型/TF-GridNet|TF-GridNet]] 并列的强判别式多通道骨干，常被后续工作（[[方向/AI语音/模型/Geo-DConv|Geo-DConv]]、[[方向/AI语音/模型/Direction-Preserving MIMO|Direction-Preserving MIMO]]）当作固定阵列基线或神经估计器复用。

## 2. 核心机制

整体数据流：多通道波形 -> STFT -> 逐 T-F bin 拼接各通道实部/虚部（$2M$ 维向量）-> T-Conv1d 输入层 -> $L$ 个交错的 narrow-band block 与 cross-band block -> 线性输出层 -> $P$ 个目标说话人直达声复谱（$2P$ 维）-> iSTFT。

```text
多通道波形 -> STFT -> [Re/Im 拼接 2M 维逐 TF bin]
  -> narrow-band block（逐频带沿时间建模）↔ cross-band block（逐帧沿频率建模）× L
  -> 目标直达声复谱 -> iSTFT -> 增强/分离波形
```

输入特征只用多通道 STFT 的实部与虚部拼接，**不显式计算 IPD/ILD** 等手工空间特征——论文把 IPD/ILD 作为动机讨论，空间信息由网络从复谱中自学。隐张量始终保持 $F \times T \times C$。

**Narrow-band block**（逐频带独立处理，频带间共享参数；消融显示是主要贡献者）：

- MHSA（沿时间轴的多头自注意力）：承担"基于空间向量的说话人聚类"；注意力图可视化显示不同 head 分别聚类语音帧与非语音帧。
- T-ConvFFN（两层线性间插入 3 个时间维组卷积 + GN + SiLU）：做时间平滑 / 统计量估计与混响（CTF）建模。

**Cross-band block**（逐帧独立处理，帧间共享）：

- 2 个频率维组卷积模块（F-GConv1d + PReLU）：学习相邻频率相关性。
- 1 个 full-band linear 模块：先降维到 $C''$，再用 $C''$ 个沿频率轴的独立线性映射（F-Linear，参数在所有 cross-band block 间共享），学习直达声 RTF 的全频相关性（相位随频率线性、斜率即 TDOA）。

训练损失为时域负 SI-SDR + PIT；LibriCSS 实验（可能空输出流）改用负 SA-SDR；在线版用负 SNR。

## 3. 核心公式

输入特征构造：对每个 T-F bin，把 $M$ 个通道的 STFT 实虚部堆成向量：

$$\mathbf{x}(t,f) = \big[\operatorname{Re}X_1(t,f), \operatorname{Im}X_1(t,f), \dots, \operatorname{Re}X_M(t,f), \operatorname{Im}X_M(t,f)\big] \in \mathbb{R}^{2M}$$

其中 $X_m(t,f)$ 为第 $m$ 个麦克风通道的复 STFT，$t$、$f$ 为帧与频点索引。

Block 级联：第 $l$ 层特征由 narrow-band 与 cross-band 两个子模块交错作用：

$$\mathbf{H}^{(l)} = \big(\text{cross-band} \circ \text{narrow-band}\big)\big(\mathbf{H}^{(l-1)}\big), \qquad \mathbf{H}^{(l)} \in \mathbb{R}^{F \times T \times C}$$

其中 narrow-band 对每个频点 $f$ 沿时间轴做 MHSA + T-ConvFFN，cross-band 对每帧 $t$ 沿频率轴做 F-GConv1d + full-band linear。

训练目标（PIT 下的负 SI-SDR）：

$$\mathcal{L} = \min_{\pi \in \Pi} \sum_{p} -\operatorname{SI\text{-}SDR}\big(\hat{s}_{\pi(p)}, s_p\big), \qquad \operatorname{SI\text{-}SDR}(\hat{s}, s) = 10\log_{10}\frac{\|s_t\|^2}{\|\hat{s} - s_t\|^2}$$

其中 $\Pi$ 为输出流与目标说话人的全部排列，$s_p$、$\hat{s}_{\pi(p)}$ 为目标与估计直达声波形，$s_t = \frac{\langle \hat{s}, s\rangle}{\|s\|^2}s$ 为尺度投影目标。

## 4. 测试基准与性能

**测试基准**（TASLP 正文）：SMS-WSJ（消融用 SMS-WSJ-Plus）、WHAMR!、Spatialized WSJ0-2mix、LibriCSS、REVERB Challenge、CHiME 3/4。主论文未使用 M2MeT 或 RealMAN（RealMAN 是同实验室后续数据集，在 Geo-DConv 等工作中才作测试床）。

**性能指标**：

| 任务 / 配置 | 模型 | 关键数字 | 对比 |
|---|---|---|---|
| SMS-WSJ 6ch（联合分离+去噪+去混响） | SpatialNet-large | SI-SDR **25.1 dB**、NB-PESQ 4.17、WER **6.70%** | TF-GridNet 22.8 dB / 4.08 / 6.76% |
| SMS-WSJ 2ch | SpatialNet-large | SI-SDR 23.3 dB | TF-GridNet 20.3 dB |
| WHAMR! 2ch | SpatialNet-large | SI-SDR **14.1 dB** | TF-GridNet 13.7 dB |
| Spatialized WSJ0-2mix 4ch（8k, max） | SpatialNet-large | SDR **32.7 dB** | DasFormer(min) 26.1 dB；small 已超所有基线 |
| LibriCSS 7ch（≤40% overlap） | SpatialNet-large | WER **6.9%** | MISO1-BF-MISO3 8.3% |
| CHiME 3/4 simulated 6ch | SpatialNet-small | SI-SDR 22.1 dB | 与两阶段神经波束（22.0 dB）相当 |

效率（4 秒 6 通道）：small 23.1/46.3 G/s（8k/16kHz），large 119.0/237.9 G/s；对比 TF-GridNet 11M 参数、348/696 G/s——SpatialNet-large 参数更少、算力约 1/3。

消融（SMS-WSJ-Plus，small）：去掉 MHSA 后 SI-SDR 13.8→9.5 dB、WER 15.9%→31.6%，贡献最大；cross-band 模块贡献次之但明显。

## 5. 典型用途

- **多通道判别式增强/分离骨干**：在固定阵列场景与 TF-GridNet 并列的强基线，覆盖联合分离、去噪、去混响。
- **阵列泛化改造的宿主模型**：[[方向/AI语音/模型/Geo-DConv|Geo-DConv]] 以 SpatialNet / TF-GridNet 为固定阵列基线，用坐标动态卷积改造成 array-invariant。
- **神经协方差估计器**：[[方向/AI语音/模型/Direction-Preserving MIMO|Direction-Preserving MIMO]] 用轻量 OnlineSpatialNet 估计尺度归一化噪声协方差 Cholesky 因子，接入保向 MIMO Wiener 滤波。
- **系统前端**：AISHELL-5 基线系统用 "AEC + IVA + SpatialNet" 作车内多通道前端。

## 6. 使用注意

- **依赖固定阵列几何**：原生 SpatialNet 假设固定阵列；可变阵列需 Geo-DConv 类改造。
- **强在空间线索，弱在同位置分离**：两个说话人空间位置接近时性能大幅下降，与频谱主导模型的失败模式互补。
- **官方无预训练 checkpoint**：NBSS 仓库只提供训练/测试脚本与数据生成脚本，需自行训练。
- **在线需换变体**：离线版的 MHSA 是双向的，流式部署要用 Online SpatialNet（MSA / Retention / Mamba 三种因果变体，Mamba 最好）+ ST+LF（短信号训练 + 长信号微调）策略，否则长流上长度外推崩溃。

## 7. 关键来源

- [SpatialNet: Extensively Learning Spatial Information for Multichannel Joint Speech Separation, Denoising and Dereverberation](https://arxiv.org/abs/2307.16516)
  - 内容定位：主论文（v1 2023-07-31，v2 2023-12-22；期刊版 IEEE/ACM TASLP vol. 32, pp. 1310–1323, 2024, DOI 10.1109/TASLP.2024.3357036），定义 narrow-band / cross-band 交错架构与全部基准结果。
  - 用途：本页机制、公式与性能数字的出处。
  - 核验日期：2026-09-24
- [Audio-WestlakeU/NBSS](https://github.com/Audio-WestlakeU/NBSS)
  - 内容定位：官方仓库（MIT License，PyTorch Lightning），含 `models/arch/SpatialNet.py`（离线）与 `OnlineSpatialNet.py`（在线）、训练/测试脚本、SMS-WSJ-Plus 数据生成脚本；无官方预训练权重。
  - 用途：复现与代码入口。
  - 核验日期：2026-09-24
- [SpatialNet 项目主页](https://audio.westlake.edu.cn/Research/SpatialNet.htm)
  - 内容定位：项目页，含音频示例。
  - 用途：听感验证与演示入口。
  - 核验日期：2026-09-24
- [Multichannel Long-Term Streaming Neural Speech Enhancement for Static and Moving Speakers](https://arxiv.org/abs/2403.07675)
  - 内容定位：在线版论文（v1 2024-03-12，IEEE SPL 2024），提出 oSpatialNet-MSA / Ret / Mamba 因果变体与 ST+LF 训练策略，覆盖静态与移动说话人（0.12–0.4 m/s）。
  - 用途：流式部署路线出处。
  - 核验日期：2026-09-24

## 8. 相关对象

- [[方向/AI语音/团队/Audio-WestlakeU（西湖大学音频实验室）|Audio-WestlakeU]]：SpatialNet 的团队入口，McNet / RealMAN 同出此实验室。
- [[方向/AI语音/模型/TF-GridNet|TF-GridNet]]：并列的强判别式多通道骨干，主论文直接对比对象；SpatialNet-large 参数更少、算力约 1/3。
- [[方向/AI语音/模型/McNet|McNet]]：同实验室另一条级联 full/narrow-band 空间-频谱模块路线；在线版论文的在线基线之一。
- [[方向/AI语音/模型/Geo-DConv|Geo-DConv]]：把 SpatialNet 改造为 array-invariant 的几何动态卷积工作（RealMAN 上验证）。
- [[方向/AI语音/模型/Direction-Preserving MIMO|Direction-Preserving MIMO]]：以 OnlineSpatialNet 为神经协方差估计器的保向 MIMO 增强。
- [[方向/AI语音/数据集/WHAM|WHAM / WHAMR!]]：SpatialNet 双耳噪声-混响分离评测数据集。
- [[方向/AI语音/评估/REVERB Challenge（混响语音挑战）|REVERB Challenge]]：SpatialNet 评测基准之一。

## 9. 待验证

- 在线版论文未给明确"算法延迟毫秒数"指标，STFT 32ms 窗 / 16ms hop 下的实际端到端延迟需自行核算。
- 与 TF-GridNet、McNet、[[方向/AI语音/模型/CrossNet|CrossNet]]、DeFTAN2 在本地场景（中文、近讲/远讲、麦数变化）的延迟与 WER 取舍。
- Geo-DConv 改造后的 SpatialNet（1.3M）在固定阵列原始场景是否掉点：Geo-DConv 论文（arXiv:2607.18658）显示 Random 4-Mics 训练的 Geo 版 SI-SDR 3.92，低于固定阵列原版 5.23——跨阵列泛化与单阵列上限存在取舍，但论文未测 Geo 版在固定满阵列下的成绩。
- TF-GridNet 待验证项中提到的统一"判别式增强骨干"对比表（DCCRN、DeepFilterNet、TF-GridNet、McNet、SpatialNet）是否值得建立。

---
title: McNet
类型: 模型
发表时间: 2022-11-16
时间依据: arXiv 首次提交日
任务:
  - 语音增强
  - 多通道增强
团队:
  - "[[方向/AI语音/团队/Audio-WestlakeU（西湖大学音频实验室）]]"
开放状态:
  - paper
  - code
  - demo
aliases:
  - MCNET
  - "McNet: Fuse Multiple Cues for Multichannel Speech Enhancement"
  - Fuse Multiple Cues for Multichannel Speech Enhancement
  - Multi-cue fusion network
  - McNet 系列
tags:
  - 类型/对象
  - 方向/AI语音
  - 任务/语音增强
  - 任务/多通道增强
  - 主题/阵列信号
---

# McNet

## 0. 背景

**问题现场**：多通道语音增强需要同时利用阵列空间信息与参考通道频谱信息恢复干净语音，并可作为 ASR 前端。

**前序路线的缺口**：只靠空间 cue 或只靠单通道频谱 cue 都不够——二者在不同频率尺度上互补，单一利用会留缺口。

**McNet 的切入点**：full-band / narrow-band spatial 与 sub-band / full-band spectral 四模块级联，融合多尺度空间与频谱 cue 后输出掩码。

## 1. 身份

`McNet` 是 [[方向/AI语音/团队/Audio-WestlakeU（西湖大学音频实验室）|Audio-WestlakeU]] 提出的 multi-cue fusion network，用于 multichannel speech enhancement。它把多通道语音增强里的空间信息、频谱信息，以及 full-band / narrow-band / sub-band 不同观察尺度串起来建模。

边界：McNet 是阵列 / 多通道语音增强模型，不是 [[方向/AI语音/知识/基础概念/Beamforming（波束形成）|beamforming]] 公式，也不是 CHiME 这类评测基准。它可以作为 ASR 前端，但核心任务仍是增强参考通道语音；它不预测文字，也不包含 ASR decoder。

一句话口径：**McNet / [[方向/AI语音/模型/Mel-McNet|Mel-McNet]] 做的是 speech enhancement；ASR 是下游使用方式和评估场景。**

## 2. 核心机制

McNet 级联四个模块，每个模块利用一类 cue：

| 模块 | 作用 |
|---|---|
| full-band spatial module | 跨频率利用空间线索，建模阵列通道间关系。 |
| narrow-band spatial module | 在窄带上利用空间线索，更接近经典阵列处理的频点级建模。 |
| sub-band spectral module | 用局部频带模式区分语音和噪声。 |
| full-band spectral module | 建模全频谱依赖，补足跨频率语音结构。 |

这条路线的要点是：多通道增强不能只靠空间 cue，也不能只靠单通道频谱 cue；二者在不同频率尺度上互补。

## 3. 核心公式

空间 cue（通道间相位差 IPD）：

$$\phi_{ij}(t,f) = \angle X_i(t,f) - \angle X_j(t,f), \qquad \mathbf{z}_{\mathrm{sp}}(t,f) = \big[\cos\phi_{ij}(t,f);\ \sin\phi_{ij}(t,f)\big]$$

其中 $X_i$ 为第 $i$ 个麦克风的复谱（常取相邻通道对）；正余弦形式避免相位卷绕，供 full-band / narrow-band spatial 模块使用。

频谱 cue：

$$P(t,f) = \log\big|X_{\mathrm{ref}}(t,f)\big|$$

其中 $X_{\mathrm{ref}}$ 为参考通道复谱；对数幅度谱供 sub-band / full-band spectral 模块使用。

多 cue 融合与掩码：

$$\hat{M} = \operatorname{Fusion}\big(\hat{M}_{\mathrm{FBS}},\, \hat{M}_{\mathrm{NBS}},\, \hat{M}_{\mathrm{SBS}},\, \hat{M}_{\mathrm{FSS}}\big), \qquad \hat{S}(t,f) = \hat{M}(t,f)\,X_{\mathrm{ref}}(t,f)$$

四个模块分别输出 full-band spatial、narrow-band spatial、sub-band spectral、full-band spectral 的估计掩码 $\hat{M}_{\mathrm{FBS}}$ / $\hat{M}_{\mathrm{NBS}}$ / $\hat{M}_{\mathrm{SBS}}$ / $\hat{M}_{\mathrm{FSS}}$，经融合后作用于参考通道谱得到增强输出（掩码为实值或复值依实现而定）。

训练损失（SI-SNR）：

$$\mathcal{L} = -10\log_{10}\frac{\|s_t\|^2}{\|\hat{s} - s_t\|^2}, \qquad s_t = \frac{\langle \hat{s}, s\rangle}{\|s\|^2}\,s$$

其中 $s$、$\hat{s}$ 为目标与估计波形，$s_t$ 为按尺度缩放后的目标投影。

## 4. 测试基准与性能

**测试基准**（ar5iv）：

- 数据：CHiME-3 模拟集（7,138 / 1,640 / 1,320 训练 / 开发 / 测试，16 kHz）；平板 6 麦阵列，第 5 通道为参考；目标为延迟叠加的**无混响**语音，背景噪声为 4 类真实环境录音（bus / café / pedestrian / street junction）；训练 SNR 随机 −5~10 dB；STFT 512 点（32 ms）Hann 窗 / 256 点移。
- 基线：MNMF Beamforming、Oracle MVDR（上限参照）、CA Dense U-net、Narrow-band Net、[[方向/AI语音/模型/FT-JNF（Frequency-Time Joint Non-linear Filter）|FT-JNF]]。
- 指标：NB-PESQ / WB-PESQ / STOI(%) / SDR(dB)（论文未报 SI-SDR）。

**性能指标**（ar5iv Table 1/2）：

| 配置 | NB-PESQ | WB-PESQ | STOI(%) | SDR(dB) |
|---|---|---|---|---|
| 离线 McNet | **3.38** | **2.73** | **97.6** | **19.6** |
| 离线 FT-JNF（次优） | 3.17 | 2.48 | 96.2 | 17.7 |
| Oracle MVDR（上限参照） | 2.49 | 1.94 | 97.0 | 17.3 |
| 在线 McNet | **3.29** | **2.67** | **97.2** | **19.0** |

- McNet 在线成绩高于全部对比方法的离线成绩；消融中 narrow-band spatial 与 full-band spectral 模块最重（在线 WB-PESQ 2.67 → 去窄带空间 2.51 / 去全带频谱 2.52）。

## 5. Mel-McNet

[[方向/AI语音/模型/Mel-McNet|Mel-McNet]] 是 McNet 的 Mel 域在线版本（Interspeech 2025，见独立笔记）：多通道 STFT 先压到 Mel 域，输出 enhanced LogMel 供 ASR 消费；代价是相位与细频率结构有损。

## 6. 使用判断

- 适合：固定或较稳定麦克风阵列、多通道会议/远场语音、服务 ASR 的增强前端、在线增强研究。
- 不适合：纯单通道降噪、未知/异步分布式阵列、只追求 MOS 的生成式增强榜单。
- 和 [[方向/AI语音/知识/基础概念/GSS（引导源分离）|GSS]] 的区别：GSS 依赖 diarization / speaker activity 引导分离；McNet 是监督式神经多通道增强模型，不一定需要外部说话人活动标签。

## 7. 关键来源

- [McNet: Fuse Multiple Cues for Multichannel Speech Enhancement](https://arxiv.org/abs/2211.08872)
  - 内容定位：McNet 原始论文，提出 full-band spatial、narrow-band spatial、sub-band spectral、full-band spectral 四模块级联。
  - 用途：理解 McNet 的架构和发表时间。
  - 核验日期：2026-08-05
- [McNet project page](https://audio.westlake.edu.cn/Research/McNet.htm)
  - 内容定位：西湖大学官方项目页，含方法说明、音频样例和对比对象。
  - 用途：确认 McNet 属于 Audio-WestlakeU / Xiaofei Li 组路线。
  - 核验日期：2026-08-05
- [Audio-WestlakeU/McNet](https://github.com/Audio-WestlakeU/McNet)
  - 内容定位：官方 PyTorch 实现。
  - 用途：复现 McNet 训练与推理。
  - 核验日期：2026-08-05
## 8. 相关对象

- [[方向/AI语音/团队/Audio-WestlakeU（西湖大学音频实验室）|Audio-WestlakeU]]：McNet / Mel-McNet 的主要团队入口。
- [[方向/AI语音/知识/基础概念/Array Audio Signal（阵列音频信号）|Array Audio Signal]]：McNet 属于麦克风阵列输入的多通道增强范式。
- [[方向/AI语音/知识/基础概念/Beamforming（波束形成）|Beamforming]]、[[方向/AI语音/知识/基础概念/MVDR（最小方差无失真响应）|MVDR]]：经典阵列前端基线；McNet 走监督式神经多 cue 融合路线。
- [[方向/AI语音/评估/CHiME（语音分离与识别挑战赛）|CHiME]]：McNet / Mel-McNet 常在 CHiME-3 等多通道 noisy ASR 场景上评估。
- [[方向/AI语音/知识/基础概念/Spectrogram（声谱图）|Spectrogram]]：McNet 系列以 STFT / Mel spectrogram 表示作为核心输入输出。
- [[方向/AI语音/模型/Mel-McNet|Mel-McNet]]：同系列 Mel 域在线变体（独立笔记）。

## 9. 待验证

- McNet / Mel-McNet 在本地会议阵列样本上的增强指标、WER 和实时性。
- Mel 域输出直接接 ASR 与先 vocoder 重建再 ASR 的差异。
- IPD 特征的通道对选择与掩码类型（实值 / 复值）的具体形式待核。

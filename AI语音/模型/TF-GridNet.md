---
title: TF-GridNet
类型: 模型
参数量: 14.5M（WSJ0-2mix 1-ch 口径；多通道配置视任务变化）
发表时间: 2022-09-08
时间依据: arXiv 首次提交日；扩展版 full/sub-band 论文 2022-11-22 提交
任务:
  - 语音分离
  - 语音增强
  - 多通道增强
团队:
  - "[[方向/AI语音/团队/Z.-Q. Wang Group（Zhong-Qiu Wang 组）]]"
开放状态:
  - paper
  - demo
aliases:
  - TF-GridNet
  - TFGridNet
  - TF-GRIDNET
  - Time-Frequency GridNet
  - "TF-GridNet: Making Time-Frequency Domain Models Great Again for Monaural Speaker Separation"
  - "TF-GridNet: Integrating Full- and Sub-Band Modeling for Speech Separation"
tags:
  - 类型/对象
  - 方向/AI语音
  - 任务/语音分离
  - 任务/语音增强
  - 任务/多通道增强
  - 主题/时频建模
---

# TF-GridNet

## 0. 背景

- **把 T-F 域重新打强**：在 Conv-TasNet 等时域模型之后，TF-GridNet 证明复数 STFT 域仍能做到强分离 / 增强。
- **可解释地融合尺度**：full-band 看全局频谱结构，sub-band 看局部时间动态，attention 看长时依赖。
- **成了公共基线**：后续多通道增强、生成-预测融合、universal SE 论文经常默认拿 TF-GridNet 或其变体做判别式基线。

## 1. 身份

`TF-GridNet` 是 Zhong-Qiu Wang 等提出的 time-frequency domain speech separation / enhancement 网络。它把 full-band modeling、sub-band temporal modeling 和 cross-frame self-attention 组合起来，在 STFT 时频网格上做 complex spectral mapping。

边界：TF-GridNet 不是 [[方向/AI语音/知识/基础概念/Beamforming（波束形成）|beamforming]]，也不是扩散 / Flow Matching 生成模型。它是强判别式时频网络骨干；在多通道系统里可以和 [[方向/AI语音/知识/基础概念/MVDR（最小方差无失真响应）|MVDR]] / multi-frame Wiener filter / neural beamformer 联用，也可以作为生成-预测混合系统里的 predictive branch。

## 2. 核心机制

TF-GridNet 在 complex STFT 上工作，通常把 real / imaginary components 堆成输入特征，输出目标源的 real / imaginary components。

每个 TF-GridNet block 主要包含三类模块：

| 模块 | 作用 |
|---|---|
| intra-frame full-band module | 在同一帧内跨频率建模，捕捉全频谱结构。 |
| sub-band temporal module | 在局部频带上沿时间建模，捕捉语音动态和局部谐波/瞬态。 |
| cross-frame self-attention module | 跨帧建模长时依赖，补足纯局部卷积的上下文不足。 |

## 3. 核心公式

复谱映射：输入输出均在复数 STFT 域，把实部 / 虚部堆叠为特征：

$$X_c(t,f) = \big[\operatorname{Re}X(t,f);\ \operatorname{Im}X(t,f)\big], \qquad \hat{S}_c(t,f) = \mathrm{TF\text{-}GridNet}(X_c)$$

其中 $X(t,f)$、$\hat{S}(t,f)$ 分别为输入混合与目标源的复谱，$[\cdot;\cdot]$ 为特征拼接；输出分量还原为目标复谱 $\hat{S} = \hat{S}_c^{[1]} + j\,\hat{S}_c^{[2]}$，经 iSTFT 得到增强波形 $\hat{s}$。

Block 级联：每个 block 由三类子模块组成（内部次序见原论文）：

$$\mathbf{M}^{(l)} = \big(\text{cross-frame self-attention} \circ \text{sub-band temporal} \circ \text{intra-frame full-band}\big)\big(\mathbf{M}^{(l-1)}\big)$$

其中 $\mathbf{M}^{(l)}$ 为第 $l$ 个 block 的 T-F 特征张量；intra-frame full-band 在同一帧内沿频率建模全频谱结构，sub-band temporal 在局部频带上沿时间建模语音动态，cross-frame self-attention 跨帧建模长时依赖。

Sub-band temporal 与 cross-frame attention 的标准形式：

$$\mathbf{M} \mathrel{+}= \operatorname{Conv1D}_t(\mathbf{M}) \ \text{（逐频带沿时间）}, \qquad \operatorname{Attn}(Q,K,V) = \operatorname{softmax}\!\left(\frac{QK^{\mathsf{H}}}{\sqrt{d_k}}\right)V$$

其中 $Q = \mathbf{M}W_Q$、$K = \mathbf{M}W_K$、$V = \mathbf{M}W_V$ 为帧间 query / key / value 投影，$d_k$ 为缩放维度。

训练损失（SI-SNR）：

$$\mathcal{L} = -\operatorname{SI\text{-}SNR}(\hat{s}, s) = -10\log_{10}\frac{\|s_t\|^2}{\|\hat{s} - s_t\|^2}, \qquad s_t = \frac{\langle \hat{s}, s\rangle}{\|s\|^2}\,s$$

其中 $s$、$\hat{s}$ 为目标与估计波形，$s_t$ 为按尺度缩放后的目标投影，$\langle\cdot,\cdot\rangle$ 为内积。

## 4. 测试基准与性能

**测试基准**（扩展版论文 ar5iv）：

- **WSJ0-2mix**（单通道无混响双说话人分离）：8 kHz，20k / 5k / 3k 训练 / 验证 / 测试，说话人相对电平 [−5, 5] dB，utterance 完全重叠。
- **SMS-WSJ**（混响双说话人分离）：33,561 / 982 / 1,332，8 kHz，6 麦 20 cm 圆阵，说话人-阵列距离 1.0–2.0 m，T60 0.2–0.5 s，弱白噪 20–30 dB；分 1-ch（mic 1）/ 2-ch（mics 1+4）/ 6-ch 评估。
- **WHAMR!**（噪声-混响双耳分离）：8 kHz，T60 0.2–1.0 s，主说话人 vs 噪声 SNR −6~3 dB，距离 0.66–2.0 m。
- **WSJ0CAM-DEREVERB**（自建去混响）：16 kHz，8 麦 20 cm 圆阵，距离 0.75–2.5 m，T60 0.2–1.3 s，SNR 5–25 dB。
- **L3DAS22**（噪声-混响增强挑战）：16 kHz，两个 4 通道 Ambisonic 阵，SNR 6–16 dB，评分 (STOI + (1−WER))/2。
- 通用设置：32 ms 窗 / 8 ms hop，square-root Hann，无数据增强；基线含 QDPN、SepFormer、Conv-TasNet、DPRNN、DPRNN-TasNet、MISO-BF-MISO 类系统等。

**性能指标**（ar5iv）：

| 任务 / 配置 | 最佳配置 | 关键数字 |
|---|---|---|
| WSJ0-2mix（1-ch） | TF-GridNet（14.5 M 参数） | SI-SDRi **23.5 dB**、SDRi 23.6 dB（前最佳 QDPN 22.1 dB） |
| SMS-WSJ 1-ch | DNN1+SCMFWF+DNN2 | SI-SDR **18.45 dB**、PESQ 3.70、eSTOI 0.952、WER **7.91%**（oracle 直接路径 6.28%） |
| SMS-WSJ 2-ch | DNN1+MCMFWF(15,14)+DNN2 | SI-SDR **20.30 dB**、PESQ 3.81、eSTOI 0.967、WER 7.41%（超卷积波束形成基线 ConvBF 19.40 dB） |

- 6-ch SMS-WSJ、WHAMR!、WSJ0CAM-DEREVERB、L3DAS22 的数字在抓取时表格被截断，论文声称均为 SOTA → 待核。

## 5. 典型用途

- **Speech Separation**：单通道 / 多通道说话人分离，常在 WSJ0-2mix、SMS-WSJ、WHAMR! 等任务中作为强基线。
- **Speech Enhancement / Dereverberation**：在 noisy-reverberant enhancement、dereverberation、多通道增强中作为判别式骨干。
- **Universal SE 预测分支**：[[方向/AI语音/模型/GAP-URGENet|GAP-URGENet]] / [[方向/AI语音/模型/UniPASE|UniPASE]] 路线里，TF-GridNet 常承担“守内容、守客观指标”的 predictive branch。
- **潜变量压缩器骨干**：[[方向/AI语音/模型/DiT-Flow|DiT-Flow]] 的 VAE 压缩器使用 TF-GridNet 编码器骨干。

## 6. 使用注意

- **不是天然低延迟**：full-band / attention / 双向上下文设置会影响流式部署，要单独看 causal 版本和 lookahead。
- **不是空间滤波器**：多通道时仍需要显式空间线索、beamformer 或多通道 complex mapping 设计。
- **强在客观保真，不一定主观最悦耳**：作为判别式模型，常适合和生成式分支互补。

## 7. 关键来源

- [TF-GridNet: Making Time-Frequency Domain Models Great Again for Monaural Speaker Separation](https://arxiv.org/abs/2209.03952)
  - 内容定位：TF-GridNet 早期 ICASSP 2023 工作，面向单通道说话人分离。
  - 用途：确定 TF-GridNet 的起点和 time-frequency modeling 口径。
  - 核验日期：2026-08-05
- [TF-GridNet: Integrating Full- and Sub-Band Modeling for Speech Separation](https://arxiv.org/abs/2211.12433)
  - 内容定位：扩展版论文，明确 full-band / sub-band / cross-frame self-attention 三类模块，并覆盖单通道、多通道、去混响和增强任务。
  - 用途：建立本页的核心机制与适用边界。
  - 核验日期：2026-08-05
- [Zhong-Qiu Wang publication page](https://zqwang7.github.io/)
  - 内容定位：作者主页列出 TF-GridNet 及后续相关工作。
  - 用途：团队和后续路线入口。
  - 核验日期：2026-08-05

## 8. 相关对象

- [[方向/AI语音/团队/Z.-Q. Wang Group（Zhong-Qiu Wang 组）|Z.-Q. Wang Group]]：TF-GridNet 的主要团队入口。
- [[方向/AI语音/知识/基础概念/SS（语音分离）|SS]]：TF-GridNet 最初定位是 speech separation 强基线。
- [[方向/AI语音/知识/基础概念/SE（语音增强）导论|SE（语音增强）导论]]：TF-GridNet 是判别式深度增强阶段的代表骨干。
- [[方向/AI语音/知识/基础概念/Spectrogram（声谱图）|Spectrogram]]：TF-GridNet 直接在 complex STFT / T-F grid 上建模。
- [[方向/AI语音/模型/GAP-URGENet|GAP-URGENet]]、[[方向/AI语音/模型/UniPASE|UniPASE]]：使用 TF-GridNet 作为预测式分支或历史路线基线。
- [[方向/AI语音/模型/McNet|McNet]]：另一条多 cue 多通道时频增强路线。
- [[方向/AI语音/数据集/WHAM|WHAM / WHAMR!]]：TF-GridNet 常见评测数据集入口。

## 9. 待验证

- 当前 vault 是否需要单独拆 TF-GridNet v2、TS-TFGridNet、CWS-TF-GridNet 等变体。
- 本地中文会议 / Agent 场景里，TF-GridNet 与 McNet、SpatialNet、MVDR + neural post-filter 的延迟和 WER 取舍。
- 是否建立统一“判别式增强骨干”对比表：DCCRN、DeepFilterNet、TF-GridNet、McNet、SpatialNet。
- 6-ch SMS-WSJ、WHAMR!、WSJ0CAM-DEREVERB、L3DAS22 的具体数字（ar5iv 抓取时表格截断，仅见论文声称 SOTA）。

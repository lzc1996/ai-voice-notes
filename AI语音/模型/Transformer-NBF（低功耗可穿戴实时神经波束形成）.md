---
title: Transformer-NBF（低功耗可穿戴实时神经波束形成）
类型: 模型
参数量: 约 0.25M（Table IV 口径；mask CNN ≈20k，SAD 27.6k）
发表时间: 2026-09-27
时间依据: arXiv 首次提交日（v1）
任务:
  - 语音增强
  - 多通道增强
团队: Luca Bompani、G. Oltrecolli、M. Fariselli、F. Conti（单位待核）
开放状态:
  - paper
  - code
aliases:
  - Transformer-NBF
  - Transformer-Based Neural Beamforming for Real-Time Speech Enhancement on Smart Low-Power Hearables
tags:
  - 类型/对象
  - 方向/AI语音
  - 任务/多通道增强
  - 主题/高效化
---

# Transformer-NBF（低功耗可穿戴实时神经波束形成）

## 0. 背景

**问题现场**：可穿戴助听设备需要在 MCU 级超低功耗硬件上做实时多通道语音增强，而此前的 MCU SE 生态全是单通道方案。

**前序路线的缺口**：作者前作 DATE 2026 的 CNN-only 神经波束形成性能有限（STOI 94.19）；更大算力平台上的神经波束形成虽早有先例但无法落到 MCU 级。

**Transformer-NBF 的切入点**：CNN 慢分支（~1 s 感受野）估计 MVDR 权重 + 轻量 Transformer 快分支（~30 ms）逐帧预测加性校正，配混合精度、交错调度、SAD 门控与自定义 attention kernel，在 GAP9 上实现 15 ms 帧延迟、45.9 mW。

## 1. 身份

`Transformer-NBF` 是 Bompani 等（arXiv:2609.33755，2026-09）提出的 **MCU 级实时多通道神经波束形成系统**：6 麦输入，CNN 估计 [[方向/AI语音/知识/基础概念/MVDR（最小方差无失真响应）|MVDR]] 权重 + 轻量 Transformer 逐帧校正，部署在 GAP9 超低功耗 RISC-V SoC 上，15 ms 帧延迟、平均功耗 45.9 mW。论文自称首个直接跑在 MCU 级设备上的实时多通道 Transformer 神经波束形成管线。

边界：它不是通用 SE 骨干模型，而是一套**面向部署的系统方案**（混合精度 + 交错调度 + SAD 门控 + 自定义 attention kernel）包着一个较小的算法内核；结论绑定 8 kHz、6 麦、单目标说话人、GAP9 平台。它是作者此前 DATE 2026 单 CNN 波束形成工作的扩展。

## 2. 核心信息

- **输入**：6 麦波形，8 kHz；STFT 窗 64 ms / hop 15 ms（$t_{stft}$/$t_{hop}$）；mask CNN 每次消费 1 s 音频（$t_{mask}$）。
- **输出**：单通道增强波形（加权求和 + iSTFT）。
- **规模**：全管线约 0.25M 参数；混合精度——MVDR/波束形成 float32、mask CNN int8（NE16 加速器）、Transformer float16（FPU SIMD）。
- **任务口径**：单目标说话人、扩散噪声、混响房间的空间滤波增强。

## 3. 核心机制

数据流：

```text
6 麦波形 → SAD 门控（无语音则跳过整条管线）
  → STFT（6 通道）
  → G1（慢，每 ~564 ms 一次）：
      G1_1 mask CNN（参考通道 RI 谱 → 语音掩码 M_ss；噪声掩码 M_nn = 1 − M_ss）
      G1_2 由掩码估计语音/噪声协方差 → MVDR 权重 w_MVDR
  → G2（快，每 15 ms 帧一次）：
      Transformer 从原始 6 通道 STFT 直接预测加性校正 Δw
      w_final = w_MVDR + Δw → 归一化 → 加权求和 → iSTFT
```

要点：

- **时间尺度分离**：CNN 用 1 s 感受野捕获近似平稳的声场结构（噪声统计 + 空间配置），输出权重可长时间保持；Transformer 只看 ~30 ms（当前+前一帧），跟踪快变细节。这让最重的 G1（354 MMACs，占管线 80%）可以低频运行。
- **Transformer 校正**：输入 $F\times D$，$D=2\cdot2\cdot M=24$（2 帧 × RI × 6 麦）；1D 频率卷积 + 单层 12 头 [[方向/大模型/模型结构/MHA（Multi-Head Attention）|MHSA]]（频率维作序列，每头 D/H=2 维，恰对应每麦每帧一对实虚部）；线性投影输出 $F\times M$ 复数校正。不看 CNN 内部表示，只加在最终权重上。
- **交错执行**：每 15 ms 帧切 10 ms 给 G1（逐层推进）+ 5 ms 给 G2；G2 永不停帧，G1 跨帧摊销——每 366 ms（基底频点）/ 564 ms（G1 降频降压到 0.65 V/240 MHz）产出一套新权重。
- **SAD**：1-D ResNet-8（27.6k 参数，76 MMACs，比全管线便宜 6×），int8 下 98.5% 准确率、**99.9% recall**（漏检语音=整段丢弃，故 recall 优先）；静默期只留麦克风 + SAD 常开（6.64 mW）。
- **部署优化**：自定义 FlashAttention 式融合 kernel（逐行 score 驻留 L1），attention 从 NNTool 基线 9.25M cycles（942 kB L2 + 400 kB L3）压到 1.65M cycles（仅 L1）；6 通道谱放外部 RAM，L2 峰值 1447 kB 卡进 1.5 MB。

## 4. 核心公式

窄带近似下的信号模型：

$$Y_m(\omega,n)=S(\omega,n)\,R_m(\omega,n)+K_m(\omega,n)$$

其中 $S$ 为干净语音、$R_m$ 为第 $m$ 麦的房间冲激响应、$K_m$ 为加性噪声。

掩码与协方差估计：

$$M_{nn}=1-M_{ss},\qquad \mathbf{\Phi}_{vv}(\omega)=\sum_{n=1}^{N}M_{vv}(\omega,n)\,\mathbf{Y}(\omega,n)\mathbf{Y}^{H}(\omega,n),\quad vv\in\{ss,nn\}$$

其中 $\mathbf{Y}(\omega,n)=[Y_1,\dots,Y_M]^T$ 为多通道观测向量，$M_{ss}\in\mathbb{R}^{F\times N}$ 为 CNN 输出的语音掩码。

MVDR 权重与 Transformer 校正：

$$\mathbf{w}_{\mathrm{MVDR}}=\frac{\mathbf{\Phi}_{nn}^{-1}\mathbf{\Phi}_{ss}}{\operatorname{tr}\big(\mathbf{\Phi}_{nn}^{-1}\mathbf{\Phi}_{ss}\big)},\qquad w_{\text{final}}(\omega)=w_{\text{MVDR}}(\omega)+\Delta w(\omega)$$

其中 $\mathbf{\Phi}_{nn}$、$\mathbf{\Phi}_{ss}$ 为噪声/语音空间协方差矩阵，$\Delta w(\omega)\in\mathbb{C}^{M}$ 为 Transformer 输出的逐频点加性校正。训练损失为波束形成输出的 [[方向/AI语音/评估/SI-SDR|SI-SDR]]（SI-SNR 口径）。

## 5. 测试基准与性能

**测试基准**（论文 §IV）：

- 数据：gpurir 仿真的 6 麦扩散噪声混响场景，Voice Bank + DEMAND（8 kHz）；训练 28 说话人 × 10 噪声 × SNR {0,5,10,15} dB；测试 2 个未见说话人 × 5 种未见噪声 × SNR {2.5,7.5,12.5,17.5} dB；房间 3–6 m、$T_{60}\sim U(0.2,0.8)$ s；优化器 Adam（lr 1e-4，early stopping patience 2）。
- 硬件：GAP9 SoC（RISC-V FC + 9 核 CL + NE16 加速器，370 MHz/0.8 V 与 240 MHz/0.65 V 两档）；能耗用 Nordic Power Profiler Kit 实测。
- 指标：STOI / ESTOI / PESQ-WB / SI-SNR；成本：参数量、MMACs、cycles、mJ、平均功率 mW。

**性能指标**（Table I，算法精度）：

| 配置 | STOI(%) | ESTOI(%) | PESQ-WB | SI-SNR(dB) |
|---|---|---|---|---|
| Noisy | 92.38 | 86.97 | 2.609 | 10.15 |
| CNN 单独 | 94.19 | 89.95 | 2.947 | 17.70 |
| Transformer 单独 | 95.98 | 91.96 | 3.262 | 19.79 |
| **CNN + Transformer** | **98.04** | **95.52** | **3.747** | **22.02** |

组合无需额外融合层即超过任一单分支（vs Transformer +2.23 dB SI-SNR；vs CNN +4.32 dB）。

**量化与部署**（固定噪声实现的可比口径）：

| 配置 | STOI(%) | PESQ-WB | SI-SNR(dB) |
|---|---|---|---|
| 全 float32 | 98.01 | 3.768 | 21.90 |
| CNN int8 | 97.98 | 3.760 | 21.54 |
| **部署版（int8 CNN + fp16 Transformer + fp32 MVDR）** | **97.65** | **3.676** | **20.26** |

- MVDR 级对精度极敏感：int8 输出完全崩溃，fp16 也把可懂度压到低于未处理输入——故协方差/矩阵求逆恒保持 float32。
- 权重保持容忍度（Fig. 5）：**句内**固定权重越久指标单调越好（整句一次估计最优），因为声场句内近似平稳；跨句必须刷新——这是 G1 可降频运行的依据。
- 调度实测：基底档（全 0.8 V/370 MHz）每 366 ms 出权重、平均功率 66.1 mW；优化档（G1 降 0.65 V/240 MHz）564 ms、**45.9 mW（−31%）**，每次推理约 25.9 mJ。无 NE16 时 240 MHz 下 G1 需 796 ms，1 秒约束被击穿——加速器是必要条件。
- 系统级：100 mAh 电池，连续运行仅 7.2 h；权重每秒一次 8.3 h；叠加 SAD 门控（语音占 ~30%）后 **18.2–20.3 h**，超过 16 h 全天目标（含 6 个 0.9 mW MEMS 麦克风）。

**与 MCU 部署 SE 的对比**（Table IV，节选）：

| 模型 | 参数量 | 量化 | ms/inf | MAC/cyc | GMAC/J | STOI |
|---|---|---|---|---|---|---|
| TinyLSTM | 0.33M | INT8+QAT | 4.26 | 0.36 | 0.14 | – |
| RNNoise | 0.21M | INT8+QAT | 3.28 | 0.45 | 1.84 | – |
| GRU256 | 0.98M | MixFP16-INT8 | 1.70 | 2.41 | 17.46 | – |
| streaming TCN | 0.83M | INT8-BFP16 | 4.3 | 3.3 | 28.90 | 93.36 |
| CNN Only（作者前作） | 0.20M | MixFP32-INT8 | 3.8 | 3.10 | 20.20 | 94.19 |
| **Ours** | 0.25M | MixFP32-FP16-INT8 | 5 | 3.14 | 23.94 | **97.65** |

唯一效率更高的是单通道 streaming TCN（3.3 MAC/cyc、28.9 GMAC/J），但作者在本数据上复训它只有 STOI 93.36 / SI-SNR 18.83——6 通道空间信息换来 +4.29 STOI、+1.43 dB SI-SNR。

## 6. 边界

- 全部结果在 **8 kHz 仿真数据**上，非真实录音；单目标说话人；VoiceBank 规模小。
- 首次性声明限定于 "MCU-class device"；更大算力平台上的神经波束形成早有先例。
- 设计取舍：G2 每帧 5 ms 执行是 SoC 级静态时间片调度的产物，换平台需重做 kernel 与调度；Transformer 校正的收益（vs CNN 单独 +4.32 dB）是在该数据集上测得，未见跨数据集验证。
- 待机功耗含麦克风常开假设（0.9 mW × 6），实际助听器麦克风功耗可能更低。

## 7. 发展脉络

- 前作：同一作者的 DATE 2026 CNN-only 神经波束形成（即本管线的 G1 分支），本作加 Transformer 校正并完整部署。
- 设计思想对照 SlowFast（快慢分支），但慢分支尺度差一个数量级：SlowFast 慢分支窗 ≤20 ms、每 10 ms 更新，重用即掉点；本系统慢分支整合 ~1 s，输出对陈旧权重容忍——相反的行为来自慢时间尺度的选择。
- MCU SE 生态：TinyLSTM（STM32F7）、RNNoise/NNoM（Cortex-M）、Rusci 等 GAP9 混合精度 RNN——全是单通道；本工作把多通道波束形成带进 MCU 级。

## 8. 相关对象

- [[方向/AI语音/知识/基础概念/MVDR（最小方差无失真响应）|MVDR]]：波束形成权重闭式解的来源（协方差矩阵 formulation）。
- [[方向/大模型/模型结构/MHA（Multi-Head Attention）|MHA / MHSA]]：Transformer 校正模块的单层多头注意力。
- [[方向/AI语音/评估/STOI 与 ESTOI|STOI / ESTOI]]、[[方向/AI语音/评估/SI-SDR|SI-SDR]]、[[方向/AI语音/评估/PESQ|PESQ]]：评估指标口径。
- [[方向/AI语音/知识/技术路线/Efficient Multichannel SE（多通道语音增强高效化）]]：所在技术路线。
- [[方向/AI语音/知识/技术路线/Hybrid Array SE（传统神经混合阵列增强）]]：神经 mask + 经典 MVDR 的混合路线实例。

## 9. 关键来源

- [Transformer-based Neural Beamforming for Real-Time Speech Enhancement on Smart Low-Power Hearable Devices（arXiv:2609.33755）](https://arxiv.org/abs/2609.33755)
  - 内容定位：原始论文（全文 HTML 已核），架构、混合精度方案、GAP9 部署调度、能耗与系统级电池寿命全部结果。
  - 用途：本笔记全部数字与机制描述的来源。
  - 核验日期：2026-10-15
- [Bomps4/Minimal_beamforming_Transformer（GitHub）](https://github.com/Bomps4/Minimal_beamforming_Transformer)
  - 内容定位：论文声称的官方代码仓库。
  - 用途：复现与部署细节核对。
  - 核验日期：2026-10-15

## 10. 待验证

- 作者单位（UniBO / GreenWaves 背景）与正式发表 venue 未在摘要页确认。
- GitHub 仓库是否包含 GAP9 部署 kernel（自定义 attention、调度代码）还是仅模型训练部分。
- 16/24/48 kHz 采样率下的可移植性；真实录音（非 gpurir 仿真）上的表现。
- SAD 门控策略在语音碎片极多的场景（频繁启停）下的延迟毛刺。

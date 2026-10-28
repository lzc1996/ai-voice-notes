---
title: CrossNet
类型: 模型
参数量: 6.6M（8kHz）/ 8.2M（16kHz）
发表时间: 2024-03-06
时间依据: arXiv 首次提交日（v1）；期刊版 IEEE/ACM TASLP vol. 32 (2024) 更名 TF-CrossNet
任务:
  - 语音分离
  - 语音增强
  - 去混响
  - 多通道增强
团队: Perception and Neurodynamics Laboratory (PNL), The Ohio State University
开放状态:
  - paper
  - code
aliases:
  - TF-CrossNet
  - "CrossNet: Leveraging Global, Cross-Band, Narrow-Band, and Positional Encoding for Single- and Multi-Channel Speaker Separation"
tags:
  - 类型/对象
  - 方向/AI语音
  - 任务/语音分离
  - 任务/语音增强
  - 任务/多通道增强
相关模型:
  - "[[方向/AI语音/模型/SpatialNet]]"
  - "[[方向/AI语音/模型/TF-GridNet]]"
---

# CrossNet

## 0. 背景

**问题现场**：单通道与多通道说话人分离/增强需要同时兼顾分离质量、参数量与算力开销。

**前序路线的缺口**：TF-GridNet 性能强但参数量与 GFLOPs 偏高（CrossNet 以约一半参数量在噪声-混响条件反超）；SpatialNet 的逐频点 MHA 限制跨频率长程相关，且长语音上位置编码 OOD 导致性能退化。

**CrossNet 的切入点**：在 SpatialNet 框架上用 GMHSA + RCPE 替换逐频点 MHA，并去掉 narrow-band MHA，以更少参数和算力覆盖全局跨频依赖。

## 1. 身份

`CrossNet`（期刊版更名 `TF-CrossNet`）是俄亥俄州立大学 PNL 实验室（Vahid Ahmadi Kalkhorani、DeLiang Wang）提出的**复数谱映射（complex spectral mapping）说话人分离模型**，同时覆盖单通道与多通道、无混响/混响/噪声-混响三类条件。架构在 [[方向/AI语音/模型/SpatialNet|SpatialNet]] 框架上改造：用全局多头自注意力（GMHSA，[[方向/大模型/模型结构/MHA（Multi-Head Attention）|MHSA]] 的跨帧全局变体）+ 随机块位置编码（RCPE）替换 SpatialNet 的逐频点 MHA，并保留其 cross-band / narrow-band 模块（narrow-band 内去掉 MHA）。

边界：CrossNet 是判别式分离/增强骨干，不是生成式模型，也不是 ASR 系统；与推荐系统里 Deep & Cross Network（DCN）的 cross network 完全是两回事。

## 2. 核心信息

- **输入**：多通道混合波形按参考通道方差归一化 → STFT（Hann 256/128，8kHz 下 32 ms/16 ms）→ 堆叠所有通道的实部/虚部（RI），维度 $M \times F \times T$（$M$ 为通道×2 的 RI 堆叠，$F$ 频点数，$T$ 帧数）。
- **输出**：每个说话人直达声信号的 RI 谱 → iSTFT → 乘回输入方差恢复能量尺度。
- **规模**：$B=12$ 个 CrossNet block，隐藏通道 $H=192$、$H'=16$、$H''=384$；GMHSA 用 $L=4$ 头、嵌入维 $D=64$。
- **任务口径**：核心是 speaker separation（SS），兼做增强与去混响；评估在 8 kHz 的 WSJ0-2mix / WHAMR! / SMS-WSJ 上。

## 3. 核心机制

数据流：

```
混合波形 → 方差归一化 → STFT → RI 堆叠
  → Encoder（Conv1D，M×F×T → H×F×T）
  → B × [ GMHSA → Cross-band → Narrow-band ]（输入加 RCPE）
  → Output Linear → 各说话人 RI → iSTFT → 乘回方差
```

各模块要点：

- **GMHSA（全局多头自注意力）**：单个 point-wise 卷积一次产出 $L$ 组 Q/K/V（替代 TF-GridNet 的三个串行 Conv1D），**先把所有频率特征合并进通道维再做帧间 MHA**——与 SpatialNet 逐频点 MHA 不同，每帧可注意到任意帧的全部频率与特征通道，捕获跨频率+跨嵌入的长程相关。
- **RCPE（随机块位置编码）**：正弦/余弦 PE 矩阵 $\mathrm{PE}(t,\cdot)$ 预计算到最大推理长度 $T^{\max}$；训练时随机截取连续块 $[\tau, \tau+T-1]$，推理时取前 $T$ 个。无可学习参数，解决长语音位置编码 OOD 导致的性能衰减。
- **Cross-band 模块**（沿用 SpatialNet）：两个频率维分组卷积（F-GConv1d）抓邻频相关 + 全带线性模块（每通道一个 $\text{Linear}_i$，参数在所有 block 间共享）。
- **Narrow-band 模块**：改造版 Conformer 卷积块（LN → Linear 升维 $H\to H''$ → T-Conv（3 层 T-GConv1D）→ Linear 降回 $H$）；相比 SpatialNet 的 narrow-band block **去掉了 MHA**——消融显示窄带相关已被 GMHSA 覆盖。

损失：WSJ0-2mix 用纯 [[方向/AI语音/评估/SI-SDR|SI-SDR]] 损失；其余数据集用幅度损失 + SI-SDR：

$$\mathcal{L}=\mathcal{L}_{\text{Mag}}+\mathcal{L}_{\text{SI-SDR}},\qquad \mathcal{L}_{\text{SI-SDR}}=-\sum_{c=1}^{C}10\log_{10}\frac{\|\boldsymbol{s}_{c}\|_{2}^{2}}{\|\hat{\boldsymbol{s}}_{c}-\alpha_{c}\boldsymbol{s}_{c}\|_{2}^{2}}$$

其中 $\boldsymbol{s}_c$、$\hat{\boldsymbol{s}}_c$ 为第 $c$ 个说话人的目标与估计波形，$\alpha_c$ 为尺度匹配系数；$\mathcal{L}_{\text{Mag}}$ 为 STFT 幅度的 $L_1$ 误差按目标幅度 $L_1$ 范数归一化。

## 4. 测试基准与性能

**WSJ0-2mix（单通道无混响分离，8 kHz）**：mixture SI-SDR = 0 dB。

| 方法 | 参数量 | SI-SDRi | SDRi |
|---|---|---|---|
| TF-GridNet*（作者 checkpoint） | 8.2M | 22.8 | 22.9 |
| TF-GridNet | 14.5M | 23.5 | 23.6 |
| **CrossNet** | **6.6M** | 23.2 | 23.4 |

**WHAMR!（单通道噪声-混响分离）**：

| 方法 | SI-SDR | SDR | PESQ | eSTOI |
|---|---|---|---|---|
| SpatialNet (large) | 10.2 | 11.2 | 2.54 | 0.772 |
| TF-GridNet (2-stage) | 11.2 | 12.3 | 2.79 | 0.808 |
| **CrossNet** | **11.8** | **12.9** | **2.91** | 0.823 |

**SMS-WSJ（6 麦圆阵，含 ASR 下游 [[方向/AI语音/评估/WER（词错误率）|WER]]）**：

| 方法 | SI-SDR | SDR | PESQ | eSTOI | WER(%) |
|---|---|---|---|---|---|
| TF-GridNet (2-stage) | 22.8 | 24.9 | 4.08 | 0.980 | 6.76 |
| SpatialNet（同训练配置复训） | 24.8 | 26.9 | 4.15 | 0.985 | 6.66 |
| **CrossNet** | **25.8** | **27.6** | **4.20** | **0.987** | **6.30** |
| Oracle direct-path | $\infty$ | $\infty$ | 4.50 | 1.000 | 6.16 |

CrossNet 的 WER 6.30% 已接近 oracle 6.16%；单通道 SMS-WSJ 上 SI-SDR 19.2 dB，比 1-stage TF-GridNet 高 3.0 dB。

**消融（WHAMR!）**：加 GMHSA → SI-SDR +1.3 dB、PESQ +0.31；加 RCPE → 再 +0.3 dB、+0.07；去掉 narrow-band MHA → 参数 −20%、GFLOPs −33%，PESQ 仅降 0.01。

**算力**（4 秒 6 通道音频，GFLOPs）：

| 模型 | 8 kHz GFLOPs | 8 kHz 参数 | 16 kHz GFLOPs | 16 kHz 参数 |
|---|---|---|---|---|
| TF-GridNet | 348.4 | 11.0M | 695.6 | 11.2M |
| SpatialNet | 119.0 | 6.5M | 237.9 | 7.3M |
| **CrossNet** | **96.3** | 6.6M | **191.7** | 8.2M |

## 5. 边界

- **变长鲁棒性**：RCPE 使不同语音长度下性能稳定，长混合语音上 SpatialNet 会退化而 CrossNet 不退化甚至略升。
- **单阶段即可**：CrossNet 后接单通道多帧 Wiener 滤波（SCMFWF）的 2-stage 版本提升很小（WHAMR! 上 SI-SDR 11.8→12.0），作者认为 Wiener 滤波效果已被卷积层内化，2-stage 不必要。
- **训练效率**：半精度训练；作者称训练比 TF-GridNet 更快更稳。
- **未覆盖**：评估均在 8 kHz 模拟数据（WSJ0 系）上，真实录音、16 kHz 多通道增强场景论文未报；非因果离线架构，无在线/低延迟版本。

## 6. 发展脉络

- 上游：[[方向/AI语音/模型/TF-GridNet|TF-GridNet]]（2022）确立 T-F 域复数谱映射 + 跨帧注意力路线；[[方向/AI语音/模型/SpatialNet|SpatialNet]]（2023，西湖大学）提供全带/窄带模块与空间信息建模框架。
- CrossNet（2024-03 arXiv；IEEE/ACM TASLP 2024 期刊版更名 **TF-CrossNet**，DOI 10.1109/TASLP.2024.3492803）：GMHSA + RCPE 改造。
- 下游：AV-CrossNet（2024）把 CrossNet 扩展到音视频分离；[[方向/AI语音/模型/MeCo|MeCo]]（Interspeech 2026）把 CrossNet 作为判别式骨干之一做生成式校正的泛化评估。

## 7. 相关对象

- [[方向/AI语音/模型/SpatialNet|SpatialNet]]：CrossNet 的架构母体；同配置复训对比中 CrossNet SI-SDR +1.0 dB、WER −5.7% 相对。
- [[方向/AI语音/模型/TF-GridNet|TF-GridNet]]：主要基线；CrossNet 以约一半参数量在噪声-混响条件下反超。
- [[方向/AI语音/模型/DeFTAN2|DeFTAN2]]：同生态位判别式多通道分离器（MeCo 实验中并列骨干）。
- [[方向/AI语音/模型/MeCo|MeCo]]：把 CrossNet 当判别式前端做生成式校正泛化测试。
- [[方向/AI语音/评估/SI-SDR|SI-SDR]]：核心分离指标与训练损失。

## 8. 关键来源

- [CrossNet: Leveraging Global, Cross-Band, Narrow-Band, and Positional Encoding for Single- and Multi-Channel Speaker Separation (arXiv:2403.03411)](https://arxiv.org/abs/2403.03411)
  - 内容定位：原始论文，架构、RCPE、消融与 WSJ0-2mix/WHAMR!/SMS-WSJ 全部结果。
  - 用途：本笔记全部指标与机制描述的来源。
  - 核验日期：2026-10-15
- [ahmadikalkhorani/CrossNet (GitHub)](https://github.com/ahmadikalkhorani/CrossNet)
  - 内容定位：官方 PyTorch 实现。
  - 用途：复现与本地部署评估。
  - 核验日期：2026-10-15
- [TF-CrossNet, IEEE/ACM TASLP 2024 (DOI 10.1109/TASLP.2024.3492803)](https://dl.acm.org/doi/pdf/10.1109/TASLP.2024.3492803)
  - 内容定位：期刊版，更名为 TF-CrossNet。
  - 用途：确认期刊出处与更名事实。
  - 核验日期：2026-10-15

## 9. 待验证

- 期刊版 TF-CrossNet 相对 arXiv 版的具体改动（标题变化之外）未核对。
- CrossNet 在真实会议录音（非 WSJ0 系模拟）上的分离/增强表现，以及与 SpatialNet、TF-GridNet 在本地场景的延迟与 WER 取舍。
- 团队 PNL (Ohio State) 暂无独立笔记，如出现第二个该组对象再建。
- 官方仓库 checkpoint 与论文数字的一致性。

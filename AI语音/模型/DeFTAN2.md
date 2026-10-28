---
title: DeFTAN2
类型: 模型
参数量: 4.0M（base）；7.7M（large）
发表时间: 2023-08
时间依据: arXiv 首次提交日
任务:
  - 语音增强
  - 多通道增强
开放状态:
  - paper
aliases:
  - DeFTAN2
  - DeFTAN-II
  - DeFTAN-2
  - DeFTAN II
  - "DeFTAN-II: Efficient Multichannel Speech Enhancement with Subgroup Processing"
  - Dense Frequency-Time Attentive Network II
  - Efficient Multichannel Speech Enhancement with Subgroup Processing
tags:
  - 类型/对象
  - 方向/AI语音
  - 任务/语音增强
  - 任务/多通道增强
  - 主题/阵列信号
  - 主题/注意力机制
---

# DeFTAN2

## 0. 背景

**问题现场**：多通道语音增强需要以远低于强基线的参数量与算力达到同等增强质量。

**前序路线的缺口**：TF-GridNet 质量强但代价高（14.7M 参数 / 462.2 G MAC/s）；DeFTAN-I 为复数掩码路线，II 代改为复数映射并压缩复杂度。

**DeFTAN2 的切入点**：STFT 域复数谱映射 + 密集时频注意力 + 子组处理（SDB 顺序拼接压缩），base 版以 TF-GridNet 的 27% 参数、14% 算力反超其性能。

## 1. 身份

`DeFTAN2`（DeFTAN-II，Dense Frequency-Time Attentive Network II）是 KAIST（Dongheon Lee、Jung-Woo Choi，arXiv:2308.15777，IEEE/ACM TASLP 2024）提出的**高效多通道语音增强模型**：STFT 域复数谱映射 + 密集时频注意力（SDB / CEA / DPFN 模块）+ **子组处理（subgroup processing）**压缩算力——base 版仅 4.0M 参数 / 64.5 G MAC/s，在 WSJCAM0 上超过 [[方向/AI语音/模型/TF-GridNet|TF-GridNet]]（14.7M / 462.2 G）。

边界：非因果、STFT 域复数谱映射增强（不是分离，也不是流式）；DeFTAN-I（IEEE SPL 2023）是复数**掩码**路线，II 代改为复数**映射**并压缩复杂度；在 [[方向/AI语音/模型/MeCo|MeCo]] 里它被当作**多说话人分离骨干**使用（corrector 在其冻结输出上训练），属增强原论文之外的用法。

## 2. 核心机制

```text
M 通道波形
  -> 复数 STFT（32 ms 窗 / 16 ms 移）
  -> 实虚部沿通道堆叠 2M×T×F -> 3×3 up-conv + LN -> C=256
  -> 子组处理：通道维拆 G=4 组（D=64），顺序拼接压缩（SDB）
  -> 6（base）/ 12（large）个 DeFTAN-II 块：
       F-transformer + T-transformer（各含 1D SDB）
       + CEA（卷积高效注意力）+ DPFN（双路径前馈）
  -> transposed conv -> 2D SDB -> iSTFT
```

关键点：

- **复数谱映射**（vs DeFTAN-I 的复数掩码）：直接回归复数谱。
- **SDB（Split Dense Block）**：替代 DenseNet 块——子组顺序拼接 + 压缩回 D 通道，"复用前序特征而不线性增长通道维"；G=4 时 2D SDB 内存约为 dense 块的 1/4。
- **子组处理**：麦克风通道**不按空间组独立处理**，而是合并进联合特征图，由 SDB 学跨通道 / 空间关系。
- **CEA**：3×3 conv + GLU 局部强调的 Q/K、1×1 线性投影的 V，高效注意力顺序（KᵀV 先行）、4 头——参数研究里超 CSA / EA（SI-SDR 17.1 vs 16.4，MAC/s 更低）。
- **DPFN**：仅对一半特征做膨胀卷积（核 5，逐块膨胀翻倍）后拼接原样另一半——近 CFN 质量、约 60% 算力（17.3 dB @ 72.5 G vs CFN 17.5 dB @ 121.4 G）。
- **训练**：PCM loss（L3DAS22 用 SI-SDR）。

## 3. 结果口径

### 3.1. WSJCAM0（4 通道，T60 0.2–1.3 s，SNR 5–25 dB；SI-SDR ↑ / PESQ ↑ / STOI ↑）

| 模型 | SI-SDR | PESQ | STOI | 参数 | MAC/s |
|---|---|---|---|---|---|
| TPARN | 10.4 | 3.43 | 0.969 | 3.2 M | 71.8 G |
| DeFTAN（I 代） | 15.7 | 3.63 | 0.981 | 2.7 M | 95.6 G |
| TF-GridNet | 17.5 | 3.82 | 0.983 | 14.7 M | 462.2 G |
| **DeFTAN-II（base）** | **18.4** | **3.92** | **0.987** | **4.0 M** | **64.5 G** |
| DeFTAN-II（large） | 20.6 | 4.02 | 0.991 | 7.7 M | 124.0 G |

- base 版以 **TF-GridNet 的 27% 参数、14% 算力**取得更高分数。
- **DNS Challenge**（SNR −10~10 dB）：base 12.0 / 3.35 / 0.953（TF-GridNet 10.9 / 3.18 / 0.939）。
- **L3DAS22**（8 通道 Ambisonic，WER %）：base 1.64 / 0.989 / 0.986；large 1.25 / 0.994 / 0.991——总榜第一，超两阶段 TF-GridNet（1.29，29.4M / 924.6 G）且成本一个量级更低。
- **真实办公室零微调**（未见过阵列几何）：WER 53.3%（带噪）→ 5.2%（增强）vs 3.7%（干净）。
- **在 MeCo 中**：DeFTAN2-base 作冻结分离骨干（PESQ 1.88 / SI-SDR 9.31 裸输出），MeCo 校正后 SI-SDR 10.08。

## 4. 使用判断

- 适合：算力敏感的多通道增强（参数 / MAC 效率是核心卖点）；"要 TF-GridNet 级质量但跑得动"的场景。
- 不适合：流式 / 低延迟（非因果）；纯分离任务（原论文做增强；分离用法见 DeFT-Mamba 与 MeCo）。
- 风险：非因果离线定位；官方代码 / 权重可用性需核；大模型 / 生成式精修路线下的增量收益需对照。

## 5. 关键来源

- [DeFTAN-II: Efficient Multichannel Speech Enhancement with Subgroup Processing（arXiv:2308.15777）](https://arxiv.org/abs/2308.15777)
  - 内容定位：原始论文（IEEE/ACM TASLP 2024）。
  - 用途：架构、子组处理、CEA/DPFN 与全部实验数据。
  - 核验日期：2026-08-10
- [论文 HTML 版（ar5iv）](https://ar5iv.labs.arxiv.org/html/2308.15777)
  - 内容定位：同论文可读 HTML 版本。
  - 用途：模块细节与消融（SDB / CEA / DPFN 参数研究）。
  - 核验日期：2026-08-10

## 6. 相关对象

- [[方向/AI语音/模型/MeCo|MeCo]]：以 DeFTAN2-base 为冻结分离骨干（corrector 训练于其输出）。
- [[方向/AI语音/模型/TF-GridNet|TF-GridNet]]：被超越的强基线（质量与算力双重）。
- [[方向/AI语音/模型/McNet|McNet]]：多通道增强的判别式对照路线。
- [[方向/AI语音/模型/DeFTAN-AA|DeFTAN-AA]]：同作者在 DeFTAN-II block 上加 GSDB / ST / SOCA 的阵列无关版本（Interspeech 2024）。
- DeFT-Mamba（arXiv:2409.12413，同作者）：DeFTAN + Mamba 的通用多通道分离版（尚无独立笔记）。
- [[方向/AI语音/模型/SGMSE+|SGMSE+]] / [[方向/AI语音/知识/生成式语音增强/扩散模型与语音|扩散模型与语音]]：生成式对照路线（MeCo 一文的坐标系）。

## 7. 待验证

- 官方代码 / 权重（作者 GitHub: donghoney0416，含 DeFT-Mamba）。
- 在 MeCo 中做分离骨干的数据配置（说话人数、训练数据）与增强原论文口径的差异。
- 中文会议阵列、低 SNR 下的真实表现。

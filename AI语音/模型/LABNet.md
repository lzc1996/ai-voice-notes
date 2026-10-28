---
title: LABNet
类型: 模型
发表时间: 2025-07
时间依据: arXiv 首次提交日（v1 2025-07-22）
任务:
  - 语音增强
  - 多通道增强
团队:
  - "[[方向/AI语音/团队/USTC-NERCSLIP（中科大 NERCSLIP 实验室）]]"
方法范式:
  - 判别式
参数量: 52k（16 kHz 多通道版与单麦版同参数量；MACs 0.316G / 80M）
开放状态:
  - paper
  - code
aliases:
  - LABNet
  - Lightweight Attentive Beamforming Network
  - 轻量注意力波束形成网络
  - "LABNet: A Lightweight Attentive Beamforming Network for Ad-hoc Multichannel Microphone Invariant Real-Time Speech Enhancement"
tags:
  - 类型/对象
  - 方向/AI语音
  - 任务/语音增强
  - 任务/多通道增强
  - 主题/分布式阵列
  - 主题/阵列无关
  - 主题/高效化
  - 主题/实时推理
---

# LABNet

## 0. 背景

**问题现场**：ad-hoc 场景中麦克风数量与几何可变，需要轻量、实时的多通道语音增强。

**前序路线的缺口**：固定阵列主流做法要求训练与测试通道数一致，扩容需改模型重训；既有 ad-hoc 方法中 FaSNet 系延迟高达 120–220 ms，DFSNet 依赖难以获得的真实 TDOA。

**LABNet 的切入点**：跨通道注意力（CCA，Q 取参考通道、K/V 取全部通道，与序列长度/置换无关从而保证麦克风不变性）+ 三阶段框架把多通道归约到 1 路，参数量 52k、一次训练覆盖任意通道配置。

## 1. 身份

`LABNet`（Lightweight Attentive Beamforming Network，轻量注意力波束形成网络）是 USTC NERC-SLIP（中科大语音及语言信息处理国家工程研究中心；Haoyin Yan、Jie Zhang、Chengqian Jiang、Shuang Zhang）提出的 **ad-hoc 阵列多通道实时语音增强**方法（arXiv:2507.16190，v1 2025-07-22 / v3 2025-08-27；截至 2026-10-27 仍无会议 / 期刊收录，但[官方仓库](https://github.com/Jokejiangv/LABNet) 声明本工作已扩展并投至 *IEEE Trans. Audio, Speech, Lang. Process.*（TASLPRO），题名 *A Collaborative Neural Speech Enhancement Framework for Distributed Microphone Arrays*，状态 under review）。

它不走**固定阵列**（训练与测试的通道数须一致、扩容需改模型重训）这条主流做法，改用 **CCA（跨通道注意力）**与**三阶段框架**把多通道数归约到 1 路后接解码器，故通道数只影响计算量、不影响参数（机制见「核心机制」）。

边界：属**阵列无关**意义上的 ad-hoc 口径——麦克风**数量与几何均可变**、**单次训练**即保持不变（microphone invariance, MI）；与**分布式阵列**不是一回事：不做设备间异步采样率偏移（SRO）、采样时间偏移（STO）、丢包与无线传输压缩的补偿，该线由 [[方向/AI语音/模型/CaSNet|CaSNet]] 代表，而 CaSNet 的主干沿用 LABNet 设计、是 LABNet 的“未压缩姊妹模型”，逐项区别见「相关对象」。严格任务是估计参考通道（固定第 1 路，自适应选参考列为 future work）的含混响语音 $y_1$，不做去混响、不做多说话人分离；实验全为单数据集仿真（训练 6 麦 / 测试 12 麦）。

## 2. 核心机制

```text
含噪多通道波形 {x_c}, c = 1..C（任意几何与数量，第 1 路为参考）
  -> STFT：功率压缩幅度谱 + 相位差 PD（拼接成 3 维网络输入）
  -> 参数共享卷积编码器逐通道编码 -> h^e_c
  -> Stage 1 通道内处理：DPR（参数共享）逐通道 -> CCA 聚合 -> 参考通道表示 h^s1_r
  -> Stage 2 成对对齐：[h^s1_r : h^s1_c] 拼接 -> 共享 Linear 降维 -> DPR 自适应时间对齐 -> CCA -> h^s2_1
  -> Stage 3 后精修：DPR -> h^s3_1
  -> 解码器 -> 参考通道幅度谱掩码
  -> Griffin-Lim（1 次迭代）精修相位 + iSTFT -> 估计波形 ŷ1
```

### 2.1. CCA（Cross-Channel Attention，跨通道注意力）

- 输入是全部通道的编码隐表示 $h_{\text{in}} \in \mathbb{R}^{B \times F \times T \times C \times D}$，其中参考通道记为 $h^1_{\text{in}}$。
- **Q 由参考通道生成**（序列长度 1，LN + Linear），**K、V 由全部通道生成**（序列长度 C，同样 LN + Linear），输出 $h_{\text{out}} = \text{MHA}(Q,K,V) + h^1_{\text{in}}$，4 个注意力头，带残差。
- 论文给的两条理由：① 参考通道可**自适应、选择性地**吸收其它通道的有价值信息（替代 [12] 的简单平均）；② 注意力机制与序列长度和置换无关 → **保证 MI**，同时把通道数归约为 1，符合 MISO 范式。

### 2.2. 三阶段框架

- **Stage 1 通道内处理**：参数共享的 DPR 逐通道捕捉时间/频率依赖，再由 CCA 聚合；CCA 保留参考通道的时间信息、注入其它通道的空间线索。
- **Stage 2 成对对齐（pair-wise alignment）**：把参考通道表示 $h^{s1}_r$ 与每个通道的表示沿隐藏维拼接，经**参数共享的线性层**降维后送入 DPR 做**自适应时间对齐**（任意麦位导致的传播时延不同），最后再经一次 CCA 把多通道压成单通道 $h^{s2}_1$。
- **Stage 3 后精修**：单个 DPR 对 $h^{s2}_1$ 进一步时频建模。三个阶段缺一性能均下降，其中 Stage 1 影响最大。

### 2.3. 主干与训练

- 整体结构**扩展自单通道实时 SE 模型 LiSenNet**：特征提取、编码器/解码器、损失与波形重建的配置均沿用，多通道部分是本工作的新增。
- **DPR（dual-path recurrent）**：双路径架构，频率维用 Bi-GRU、时间维用单向 GRU，隐藏维融合用 ConvGLU。
- **损失**：功率压缩幅度谱 MSE + 复数谱 MSE + metric loss（MetricGAN 式判别器预测 PESQ，即 PESQ 参与优化）。
- **训练**：训练时动态打乱通道排列并随机取 1–6 通道；语音切成 4 s 段；AdamW，100 epochs，梯度裁剪 5.0，学习率 5e-4 起、每 epoch ×0.98；STFT Hann 窗长 512（32 ms）、帧移 256（16 ms）；CCA 头数 4；GLA 1 次迭代。

## 3. 核心公式

**1. 多通道信号模型：**

$$x_c = y_c + n_c = y * h_c + n_c, \qquad c = 1, 2, \ldots, C$$

$y$ 为时域语音源，$h_c$ 为源到第 $c$ 个麦克风的 RIR，$*$ 为卷积，$y_c$ 为接收到的含混响语音，$n_c$ 为（多个混响噪声叠加的）加性噪声，$C$ 为麦克风数（几何任意）。目标是从 $\{x_c\}_{c=1}^{C}$ 估计 $y_1$（第 1 路为参考）。

**2. CCA 输出：**

$$h_{\text{out}} = \text{MHA}(Q, K, V) + h^1_{\text{in}}$$

$Q$ 由参考通道隐表示 $h^1_{\text{in}}$ 经 LN + Linear 得到（序列长度 1），$K$、$V$ 由全部通道 $h_{\text{in}} \in \mathbb{R}^{B \times F \times T \times C \times D}$ 同法得到（序列长度 $C$），$\text{MHA}(\cdot)$ 为多头注意力；$B$、$F$、$T$、$D$ 分别为批大小、频点数、帧数与隐藏维。注意力与序列长度/置换无关，是 MI 的来源。

**3. Stage 1（通道内处理 + 聚合）：**

$$h^{s1}_c = \text{DPR}(h^{e}_c), \quad c = 1, 2, \ldots, C; \qquad h^{s1}_r = \text{CCA}\big(h^{s1}_1, h^{s1}_2, \ldots, h^{s1}_C\big)$$

$h^{e} = [h^1_e, h^2_e, \ldots, h^C_e] \in \mathbb{R}^{B \times C \times D \times T \times F}$ 为编码器输出，DPR 在各通道间共享参数。

**4. Stage 2（成对对齐 + 再融合）：**

$$\tilde{h}_c = \text{DPR}\big(\text{Linear}(h^{s1}_r : h^{s1}_c)\big), \quad c = 1, 2, \ldots, C; \qquad h^{s2}_1 = \text{CCA}\big([\tilde{h}_1, \tilde{h}_2, \ldots, \tilde{h}_C]\big)$$

$[\cdot : \cdot]$ 为沿隐藏维的拼接；Linear 参数共享，DPR 负责把参考通道与其它通道之间的传播时延对齐掉。

**5. Stage 3（后精修）：**

$$h^{s3}_1 = \text{DPR}(h^{s2}_1)$$

解码器据此 $h^{s3}_1$ 产生参考通道的幅度谱掩码。

## 4. 结果口径

**实验设置**：仿真集 = WSJ0 干净语音 + WHAM! 噪声；12776 段 / 24.9 h 训练、1206 段 / 2.2 h 验证、651 段 / 1.5 h 测试；每段 1 个目标说话人 + 随机 1–3 个噪声源，整体 SNR 均匀采样于 [−5, 15] dB；房间长宽 5–10 m、高 3–4 m，声源与麦克风距墙 ≥0.5 m，T60 随机 0.1–0.5 s，RIR 由 gpuRIR 的 image method 生成；16 kHz。**训练/验证用 6 麦，测试集用 12 麦**评估未见麦数下的性能（Table I 另给 6 麦测试结果）。

### 4.1. Table I：6 麦克风测试集对比

| 方法 | 域 | 参数量 | MACs | 延迟 | PESQ | STOI | CSIG | CBAK | COVL |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| Noisy | – | – | – | – | 1.48 | 0.81 | 3.10 | 2.09 | 2.27 |
| Oracle MVDR | T-F | – | – | – | 2.18 | 0.78 | 3.87 | 2.33 | 3.06 |
| EaBNet | T-F | 2.8M | 7.4G | 20 ms | 2.76 | 0.93 | 4.40 | 3.33 | 3.64 |
| McNet | T-F | 1.9M | 30.1G | 32 ms | 2.82 | 0.94 | 4.39 | 3.33 | 3.67 |
| FaSNet | T | 2.8M | 9.1G | 220 ms | 2.18 | 0.90 | 3.66 | 2.59 | 2.93 |
| FaSNet-TAC | T | 2.3M | 11.7G | 120 ms | 2.25 | 0.91 | 3.70 | 2.67 | 2.99 |
| DFSNet | T | 549k | 1.7G | 4.5 ms | 2.01 | 0.87 | 3.57 | 2.45 | 2.79 |
| **LABNet** | T-F | **52k** | **0.316G** | 64 ms | **2.92** | 0.93 | **4.42** | 3.24 | **3.70** |

- Oracle MVDR 用含噪信号的真实空间协方差矩阵，是 MVDR 系波束形成的上界；DNN 方法（EaBNet / McNet / LABNet）在其之上。
- LABNet **PESQ 2.92 与 [[方向/AI语音/评估/CSIG CBAK COVL（复合客观质量指标）|COVL]] 3.70 为全表最高**，参数量比 EaBNet/McNet 少 1–2 个数量级（52k vs 1.9M–2.8M），MACs 0.316G 亦为最低（EaBNet 7.4G、McNet 30.1G）。
- 代价：**延迟 64 ms** 高于 EaBNet 20 ms 与 DFSNet 4.5 ms；**CBAK 3.24 低于 EaBNet/McNet 的 3.33**；STOI 0.93 与 EaBNet 持平、略低于 McNet 0.94。
- 对 ad-hoc 方法（[[方向/AI语音/模型/FaSNet（滤波求和网络）|FaSNet]] / FaSNet-TAC / DFSNet）：LABNet 全指标领先，且 FaSNet 系因双路径分段延迟高达 120–220 ms，DFSNet 依赖难以获得的真实 TDOA。

### 4.2. Table II：单麦克风与 SOTA 单通道 SE 对比

| 方法 | 参数量 | MACs | PESQ | STOI | COVL |
| --- | --- | --- | --- | --- | --- |
| Noisy | – | – | 1.48 | 0.81 | 2.27 |
| CRN | 17.6M | 2.6G | 2.00 | 0.88 | 2.97 |
| DCCRN | 3.7M | 14.4G | 2.33 | 0.90 | 3.16 |
| FullSubNet | 5.6M | 30.9G | 2.45 | 0.90 | 3.34 |
| Fast FullSubNet | 6.8M | 4.1G | 2.17 | 0.89 | 3.09 |
| LiSenNet | 48k | 72M | 2.51 | 0.88 | 3.28 |
| **LABNet** | 52k | 80M | 2.51 | 0.88 | 3.29 |

- 单麦版 LABNet 与单通道基线 LiSenNet 打平（PESQ 2.51 vs 2.51），多出的 4k 参数 / 8M MACs 来自 CCA 模块。
- 相对 FullSubNet 只占 **0.9% 参数、0.3% MACs**，但 COVL 3.29 略低于 FullSubNet 的 3.34、高于 DCCRN 的 3.16。

### 4.3. Table III：三阶段消融（6 麦）

| 配置 | 参数量 | MACs | PESQ | STOI | COVL |
| --- | --- | --- | --- | --- | --- |
| LABNet | 52k | 316M | 2.92 | 0.93 | 3.70 |
| w/o Stage 1 | 39k | 203M | 2.79 | 0.92 | 3.57 |
| w/o Stage 2 | 38k | 197M | 2.83 | 0.92 | 3.60 |
| w/o Stage 3 | 41k | 299M | 2.85 | 0.92 | 3.64 |
| w/ TAC（替换 CCA） | 52k | 308M | 2.89 | 0.92 | 3.67 |

- 三阶段缺一即降，**Stage 1 影响最大**（2.92 → 2.79），说明通道内建模 + 全通道空间线索是后续阶段的基础。
- **CCA 优于 TAC**（2.92 / 3.70 vs 2.89 / 3.67），且 TAC 版 MACs 反而略低（308M vs 316M），即增益不是靠算力堆出来的。

### 4.4. Fig. 2：麦克风数扫描

论文给出 FaSNet-TAC / DFSNet / LABNet 在不同麦克风数下的 PESQ 与 MACs 曲线：LABNet 训练时最多见过 6 麦，仍可泛化到更多通道（麦数越多计算量越高）；麦数增加的边际收益递减，因此通道数可按资源-性能折中灵活取。**原文未给该图的具体数值。**

## 5. 测试基准与性能

**测试基准**：全程单数据集仿真——WSJ0（干净语音）+ WHAM!（噪声），gpuRIR image method 生成 RIR，SNR ∈ [−5, 15] dB、T60 ∈ [0.1, 0.5] s、1 目标 + 1–3 噪声源、16 kHz；训练/验证 6 麦、测试 12 麦（另给 6 麦表）。基线覆盖三类：传统（Oracle MVDR，用真值 SCM）、固定阵列（EaBNet、McNet）、ad-hoc（FaSNet、FaSNet-TAC、DFSNet），以及单麦场景下的 CRN / DCCRN / FullSubNet / Fast FullSubNet / LiSenNet。指标：PESQ、STOI、CSIG / CBAK / COVL 三个复合 MOS；成本：参数量、MACs、算法延迟。消融覆盖三阶段与 CCA vs TAC 替换。

**性能指标**：完整数字见「结果口径」（Table I：6 麦 PESQ 2.92 / STOI 0.93 / CSIG 4.42 / CBAK 3.24 / COVL 3.70，52k 参数、0.316G MACs、64 ms；Table II：单麦 PESQ 2.51 / STOI 0.88 / COVL 3.29，52k、80M；Table III：三阶段消融与 CCA/TAC 对比），此处不重复。

（来源：笔记正文「结果口径」，核验日期 2026-10-09）

## 6. 使用判断

- **适合**：算力极紧的端侧多通道前端（52k 参数、0.316G MACs）；麦克风数量/布放会变的 ad-hoc 场景，且希望**一次训练覆盖多种阵列配置**；对 60 ms 级延迟可接受、需要单路输出的增强链路（参考通道口径）；作为同组下游模型（如 [[方向/AI语音/模型/CaSNet|CaSNet]]）的骨架复用。
- **不适合**：需要**去混响**（目标本身是含混响的 $y_1$，不是无混响语音）；多说话人分离（单目标 MISO）；超低延迟场景（64 ms，DFSNet 4.5 ms / EaBNet 20 ms 更优）；真实**分布式/异步**设备集合（无 SRO/STO 补偿、无传输压缩，该场景应看 [[方向/AI语音/模型/CaSNet|CaSNet]] / [[方向/AI语音/模型/SAMbA|SAMbA]]）；需要远超 6 麦的训练规模（论文只验到 12 麦推理）。
- **风险**：
  - **训练目标含 PESQ**：metric loss 用判别器预测 PESQ，PESQ 既是优化目标又是主报告指标，而多数对比基线（EaBNet/McNet/FaSNet 系）不使用该损失，主表 PESQ 优势不完全是同口径比较。
  - **仿真口径**：全部实验为同步、同端、单数据集仿真，"ad-hoc" 只在**数量与几何**维度被验证，未涉及真实录音、真实多设备异步链路。
  - **12 麦结果只有曲线**：正文 Table 只有 6 麦数值，未见麦数下的逐项数字。
  - **延迟劣势**：GLA 1 次迭代已计入 64 ms，仍高于同为 T-F 域的 EaBNet（20 ms）。
  - **噪声不占优**：CBAK（背景噪声侵入度）低于 EaBNet/McNet，即抑制噪声的相对表现弱于其整体 PESQ 排名。

## 7. 关键来源

- [LABNet: A Lightweight Attentive Beamforming Network for Ad-hoc Multichannel Microphone Invariant Real-Time Speech Enhancement（arXiv:2507.16190）](https://arxiv.org/abs/2507.16190)
  - 内容定位：arXiv 摘要页，v1 2025-07-22、v2 2025-08-25、v3 2025-08-27，cs.SD / eess.AS，作者 Haoyin Yan、Jie Zhang、Chengqian Jiang、Shuang Zhang（USTC NERC-SLIP）；摘要页无会议接收 comment。
  - 用途：对象身份、作者与时间口径核验。
  - 核验日期：2026-10-27（复核 v3 仍为最新版、仍无 venue comment）
- [LABNet 全文（arXiv:2507.16190v3 HTML）](https://arxiv.org/html/2507.16190v3)
  - 内容定位：全文，含公式 (1)–(7)、CCA 与三阶段描述、Table I/II/III 全部数值、Fig. 2 与实验设置。
  - 用途：核心机制、边界与全部结果数字的来源。
  - 核验日期：2026-10-09
- [Jokejiangv/LABNet（GitHub）](https://github.com/Jokejiangv/LABNet)
  - 内容定位：官方开源实现（论文摘要末句给出该地址）。README 除摘要外声明两条：① 本工作已扩展投 TASLPRO（*A Collaborative Neural Speech Enhancement Framework for Distributed Microphone Arrays*，under review）；② 仓库内容仅为 `train.py` / `test.py` / `config.yaml` / `data_module.py` / `model/`，**无 LICENSE、无预训练权重、无依赖声明**；30 次提交，最近一次 2025-10-10（删除 `samples/readme.md`）。
  - 用途：开放状态、期刊扩展去向与复现完备性核验。
  - 核验日期：2026-10-27

## 8. 相关对象

- [[方向/AI语音/团队/USTC-NERCSLIP（中科大 NERCSLIP 实验室）|USTC-NERCSLIP]]：提出团队；同线的 Jie Zhang / Haoyin Yan 增强工作还有 [[方向/AI语音/模型/PGUSE|PGUSE]]、[[方向/AI语音/模型/UniSE（Unified Speech Enhancement）|UniSE]]。
- [[方向/AI语音/模型/CaSNet|CaSNet]]：同组后代模型，端侧编码器与 DPR 直接沿用 LABNet 设计，LABNet 是其"未压缩姊妹模型"基线；CaSNet 用 CWQ 替换 LABNet 的 CCA。
- [[方向/AI语音/模型/McNet|McNet]]、[[方向/AI语音/模型/Mel-McNet|Mel-McNet]]：多通道 SE 的固定阵列对照系；McNet 是本文主表基线之一。
- [[方向/AI语音/知识/技术路线/Array-Agnostic SE（阵列无关语音增强）|Array-Agnostic SE]]：LABNet 属于"通道数与几何均可变"这一路线的端侧代表。
- [[方向/AI语音/知识/技术路线/Efficient Multichannel SE（多通道语音增强高效化）|Efficient Multichannel SE]]：52k 参数 / 0.316G MACs / 64 ms 的极轻量口径。
- [[方向/AI语音/知识/技术路线/Distributed Multichannel SE（分布式异步多通道增强）|Distributed Multichannel SE]]：ad-hoc 起点的上游概念；LABNet 本人不处理 SRO/STO 异步，是该路线的**前置前提**而非成员。
- [[方向/AI语音/知识/基础概念/Beamforming（波束形成）|Beamforming]]、[[方向/AI语音/知识/基础概念/MVDR（最小方差无失真响应）|MVDR]]、[[方向/AI语音/知识/基础概念/SCM（空间协方差矩阵）|SCM]]：Oracle MVDR 基线用真值 SCM；LABNet 走"神经隐式波束形成"路线而非显式滤波系数。
- [[方向/AI语音/知识/基础概念/IPD（通道间相位差）|IPD]]：输入特征中的相位差（PD）即该类通道间相位线索。
- [[方向/AI语音/知识/基础概念/Array vs Multi-Channel（阵列与多通道）|Array vs Multi-Channel]]：LABNet 是"多通道数可变 + 几何可变"的阵列口径样本。
- [[方向/AI语音/知识/基础概念/SDPA（缩放点积注意力）|SDPA]]：CCA 的多头注意力实现基础。
- [[方向/AI语音/评估/PESQ|PESQ]]、[[方向/AI语音/评估/STOI 与 ESTOI|STOI]]：主报告指标（PESQ 同时是 metric loss 的训练目标）。
- [[方向/AI语音/数据集/WHAM|WHAM]]：WSJ0+WHAM! 仿真集的噪声来源。
- [[方向/AI语音/知识/调研与地图/Array Speech Enhancement Frontier（阵列语音增强前沿调研）|阵列语音增强前沿调研]]：本对象对应"全神经端到端与高效化"（P6 端侧/流式/高效化）与阵列泛化条目。
- [[方向/AI语音/模型/RT-SEMamba（实时语音增强 Mamba）|RT-SEMamba]]、[[方向/AI语音/模型/CUSIDE-array|CUSIDE-array]]、[[方向/AI语音/模型/Cloud-Boosted MC-SE（云端增强低算力多通道增强）|Cloud-Boosted MC-SE]]：同处"低算力多通道/实时"象限的可比对象。

## 9. 待验证

- 发表去向（2026-10-27 复核）：arXiv 摘要页仍无 comment 字段、最新版仍是 v3（2025-08-27），未见正式 venue；唯一线索是官方仓库 README 声明的 TASLPRO 扩展版（under review，未公开）。待核：该 TASLP 稿件与 [[方向/AI语音/模型/CaSNet|CaSNet]]（ICASSP 2026，压缩-发送）是"同一扩展的两步"还是并列两篇——两者题名均含 Distributed Microphone Arrays，但 CaSNet 已单独成文并开源。
- Table I 的 **Causal / MI 两列逐行标记**：全文抽取文本中该两列错位，正文只给了 MI 的定性陈述（LABNet 保持 MI；FaSNet/FaSNet-TAC/DFSNet 亦为 MI；EaBNet/McNet 为固定阵列），LABNet 的**时域因果性**未在正文明确声明（DPR 频率维用 Bi-GRU、时间维用单向 GRU，倾向因果但需查代码确认）。
- **12 麦测试的逐项数值**：正文仅以 Fig. 2 曲线呈现，未列表；未见各麦克风数下的 PESQ/MACs 具体数字。
- **真实录音与真实 ad-hoc 硬件**：全部实验为 gpuRIR 同步仿真，无真实多设备、异步时钟、SRO/STO、丢包的验证。
- **metric loss 的具体权重与实现**：论文将其细节指向 LiSenNet [14]，本文未展开；LiSenNet 在 vault 内暂无独立页。
- **GLA 1 次迭代的相位质量上限**，以及换相位感知/复数域建模的收益空间。
- 与 2025–2026 年其它超轻量多通道模型的横向对比（Mel-McNet、ARiSE、CUSIDE-array 等未出现在本文基线中）。
- **RealMAN 结果不在原文**：本文只做 WSJ0+WHAM! 仿真，无任何 RealMAN 数字；聚合榜上"LABNet RealMAN PESQ 2.34 / STOI 0.90 / COVL 3.14"是 [[方向/AI语音/模型/CaSNet|CaSNet]]（arXiv:2601.17711）复现其未压缩版本后报的值（6 麦、RealMAN 真实语音+噪声训练），不可当作本文主张，见 [[方向/AI语音/评估/RealMAN 测试结果清单|RealMAN 测试结果清单]]。
- GitHub 仓库复现完备性（2026-10-27 已核）：无 LICENSE、无预训练权重、无 requirements，仅 `train.py` / `test.py` / `config.yaml` / `data_module.py` / `model/`；即"代码可见但不可直接跑通"，复现需自备 WSJ0 + WHAM! 与 gpuRIR 仿真链路，授权条款亦不明。
- 跨笔记口径差：[[方向/AI语音/模型/CaSNet|CaSNet]] 的复现表把 LABNet 的 WSJ0-WHAM! 记为 PESQ 2.92 / STOI 0.93 / COVL **3.69**，本文 Table I 为 **3.70**（PESQ / STOI 一致）；0.01 级差属重训口径，引用时应标明出自哪一篇。

---
title: REDnet
类型: 模型
发表时间: 2026-08
时间依据: arXiv 首次提交日（v1 2026-08-25；arXiv 页 Comments 仅 "in submission"，无会议接收信息）
任务:
  - 语音分离
方法范式:
  - 判别式
开放状态:
  - paper
aliases:
  - REDnet
  - RED（recursive encoder and decoder）
  - Recursive Encoder and Decoder Network
  - 递归编码器-解码器网络
  - "REDnet: Recursive Encoder and Decoder for Speech Separation under Unknown Number of Speakers and Variable Number of Microphones"
tags:
  - 类型/对象
  - 方向/AI语音
  - 任务/语音分离
  - 主题/阵列无关
---

# REDnet

## 0. 背景

**问题现场**：语音分离部署中说话人数与麦克风数都可能变化（会议人数不定、设备组合可换），需要一个模型同时容纳未知说话人数与可变麦数。

**前序路线的缺口**：主流路线先把通道补齐/归一并按固定流数输出；TAC 式跨麦全局平均会压缩通道特有信息，cross-attention 类显式两两建模有二次复杂度；FlexIO 的人数由外部 prompt 给定、模型不做计数。

**REDnet 的切入点**：RE 逐麦递归编码累积统一表示（对麦数线性复杂度），RD 递归解码逐轮检测是否还有活跃说话人、有则分离一个并从残差中剥掉。

## 1. 身份

`REDnet`（recursive encoder and decoder network）是南方科技大学（SUSTech）计算机科学与工程系 Fulin Wu、Zhong-Qiu Wang 提出的**递归编码器-解码器语音分离网络**（arXiv:2608.24659v1 [eess.AS]，2026-08-25，Comments 为 "in submission"，暂无会议/期刊信息）。

它不走「先把通道补齐/归一并按固定流数输出」这条主流路线，而用**一个 DNN** 同时容纳未知说话人数与可变麦数（论文自称首次把两个自由度放进同一模型）：**RE** 逐麦递归编码、把各通道信息顺序累积成一个统一表示，**Backbone** 精修该表示，**RD** 逐轮检测是否还有活跃说话人，有则分离一个并从残差中剥掉、无则终止（机制见「核心机制」）。

边界：核心是**双可变口径**——输入侧（麦数 $P$ 可变、几何未知，运行期由输入直接得知）与输出侧（说话人数 $C$ 未知、须在推理时估计）同时放开，用**递归**把两侧接在一起；与 [[方向/AI语音/模型/FlexIO|FlexIO]] 同为单模型柔性输入输出，区别在于 FlexIO 的人数由外部 prompt 给定、模型不做计数，REDnet 在递归解码中把人数数出来，是单阵列、不做分布式多设备增强（[[方向/AI语音/模型/CaSNet|CaSNet]] 一类为分布式单目标增强），不是 attractor 式（潜空间选说话人、与最终估计关系不透明）；相邻路线的区别见「相关对象」；严格口径是**分离**不是增强，输出是**参考麦克风**（第 1 麦）上的目标信号，不是各通道增强像。

## 2. 核心机制

```text
逐麦克风 STFT 混合 Y_p（实虚部，2×T×F）
  -> [RE] 逐麦递归编码：I_p = I_{p-1} + Enlarge(REBlock(Shrink(concat(I_{p-1}, X_p)))), I_0 = 0
       p = 1..P 依次递归（第 1 麦为参考麦）-> 累积表示 I_P
  -> [Backbone] 精修 -> Z
  -> [RD] 递归解码（O_1 = Z）：
       第 c 轮：Shrink(O_c) -> [说话人检测器] --无活跃说话人--> 停止
                                        |
                                    有 -> RDBlock -> U_c -> Deconv2D -> Ŝ^RD_1(c)
                                        |
                                    Enlarge(U_c) = G_c -> 门控更新 O_{c+1} = O_c ⊙ (1 − sigmoid(G_c))
                                        |
                                    Deconv2D(O_{c+1}) -> X^RM_1(c+1)（监督剩余说话人之和）
       {U_c} -> triple-path 说话人交互块（跨说话人/频率/时间）-> 共享 Deconv2D -> Ŝ^TP_1(c)
  -> 参考麦上的 Ĉ 路估计（C = 1 时即单通道增强）
```

### 2.1. 递归编码器 RE

- 每个麦克风的 STFT 表示 $Y_p$ 先经独立 Conv2D 嵌入为 $X_p \in \mathbb{R}^{D \times T \times F}$（各麦共享该 Conv2D，同名同色块参数共享）。
- 递归体：把上一轮累积表示与当前麦表示按第一维拼接 $A_p = \text{concat}(I_{p-1}, X_p) \in \mathbb{R}^{2D \times T \times F}$ → pointwise Conv2D 的 shrink 层压到 $E \times T \times F$ → REBlock 建模 → enlarge 层（同为 pointwise Conv2D）还原到 $D$ → **残差加回** $I_{p-1}$ 得到 $I_p$。
- 论文给出的动机（原话）：这种「只让当前麦克风与累积表示交互」的设计，既避开 [[方向/AI语音/知识/基础概念/TAC（变换-平均-拼接）|TAC]] 式跨麦全局平均带来的**通道特有信息压缩**，也避开显式两两通道建模（cross-attention 类）的**二次复杂度**，对麦克风数保持**线性复杂度**；并声称 RE 比 TAC 更好地捕获空间线索（观察性结论，无探针证据）。

### 2.2. 递归解码器 RD

- **说话人检测器**：对 shrink 后的 $E \times T \times F$ 特征在时间与频率上平均池化得 $E$ 维向量 → 单隐层 MLP（SiLU 隐激活）+ sigmoid，输出「是否至少有一个活跃说话人」的概率（图 2(c)）。
- **训练口径**：用 oracle 人数 $C$ 展开 RD 共 $C$ 轮，**额外多做一次检测步**以让检测器学会停止；标签序列为 $[1,\dots,1,0]$（$C$ 个 1 后接一个 0）。
- **推理口径**：递归直到检测概率低于预设阈值 $\tau$（取 0.5），得到估计人数 $\hat{C}$ 后输出对应路数的估计。
- **门控 + 残差混合损失**：$G_c$ 由 $U_c$ 经 enlarge 得到，门控 $O_{c+1} = O_c \odot (1 - \text{sigmoid}(G_c))$ 模仿 T-F 掩蔽，把已分离说话人从残差表示里剥掉；再对 $O_{c+1}$ 加 Deconv2D 得 $X^{RM}_1(c{+}1)$，用**剩余说话人目标之和** $\sum_{c'=c+1}^{C} S_q^{(c')}$ 监督（$O_{C+1}$ 跳过，因期望其中已无说话人）。
- **说话人交互（triple-path）**：串行估计的各说话人之间缺少直接交互，故把 $\{U_c\}_{c=1}^{C}$ 送 triple-path 块（跨说话人 MHSA + SwiGLU 单隐层 MLP，再做频率与时间建模），之后用**共享** Deconv2D 输出 $\hat{S}^{TP}_1(c)$。
- 谱系：RD 建立在单通道递归分离范式 OR-PIT 之上，改进点为端到端训练、精炼损失（$L_{RD}/L_{RM}/L_{BCE}$）与说话人交互模块。

### 2.3. 骨干、损失与训练配置

- REBlock / Backbone / RDBlock **同架构不同超参与权重**，均基于 TF-GridNet 块（intra-frame full-band + sub-band temporal + cross-frame self-attention），两处改动：所有 PReLU 换 SiLU；在 intra-frame full-band 与 sub-band temporal 模块前插入 TF-Locoformer 的 Conv-SwiGLU。
- 超参：REBlock/RDBlock $D=64, B=4, I=4, J=4, H=256, L=4$；Backbone $D=128, I=1, J=1$。Conv-SwiGLU 内 Conv1D/Deconv1D 核 3、步长 1；跨说话人 MHSA 4 头、MLP 扩展比 3；说话人交互块堆叠 $B=2$。
- 损失已从消融确认全部有效：门控（vs 加法残差）、SiLU、Conv-SwiGLU、三重损失项与更高的 $w_{BCE}$ 逐项涨点；$w_{BCE}$ 提高还能稳定检测器训练。
- 训练：Adam，lr 从 $5\times10^{-4}$ 起、验证损失 3 epoch 不降则减半；batch size 1；段长 8 s（RDnet/REDnet）/ 4 s（REnet）；梯度裁剪 L2 范数 1.0；bfloat16 混合精度。每路麦克风先归一到单位样本方差；STFT 窗 16 ms、帧移 8 ms、sqrt-Hann 分析窗。

## 3. 核心公式

**1. 阵列混合的信号模型（原文式 (1)）：**

$$Y_p(t,f) = \sum_{c=1}^{C} S_p^{(c)}(t,f) + V_p(t,f)$$

$t, f, p, c$ 分别为时间帧、频点、麦克风与说话人索引；$Y_p$、$S_p^{(c)}$、$V_p$ 为麦克风 $p$ 上的混合、说话人 $c$ 的 target-speech 与非目标信号频谱。取第 1 麦为参考麦，目标是估计 $\{S_1^{(c)}\}_{c=1}^{C}$；$P$ 与 $C$ 逐条混合可变。

**2. 递归编码（RE 的累积表示，来自 §4.1）：**

$$I_p = I_{p-1} + \text{Enlarge}\Big(\text{REBlock}\big(\text{Shrink}(\text{concat}(I_{p-1}, X_p))\big)\Big), \qquad I_0 = \mathbf{0}$$

$X_p$ 为第 $p$ 麦的 Conv2D 嵌入，$I_p \in \mathbb{R}^{D \times T \times F}$ 为吸收前 $p$ 个麦克风后的累积表示；Shrink/Enlarge 均为 pointwise Conv2D，残差连接使递归只做增量更新。全部 $P$ 麦处理完后 $I_P$ 送入 Backbone 得 $Z$。

**3. 门控式残差表示更新（原文式 (2)）：**

$$O_{c+1} = O_c \odot \big(1 - \text{sigmoid}(G_c)\big)$$

$O_c$ 为第 $c$ 轮开始时的残差表示（$O_1 = Z$），$U_c$ 为第 $c$ 个说话人的特征、经 enlarge 得 $G_c$；门控模仿 T-F 掩蔽，把已分离说话人从残差中剥除，使后续轮次只含尚未分离的说话人（这也是 $L_{RM}$ 的监督对象）。

**4. 总体损失（原文式 (3) 前的定义）：**

$$\mathcal{L} = w_{RD}\,\mathcal{L}_{RD} + w_{RM}\,\mathcal{L}_{RM} + w_{TP}\,\mathcal{L}_{TP} + w_{BCE}\,\mathcal{L}_{BCE}$$

前三项用 SI-SNR 分别惩罚 $\hat{S}^{RD}_1$、$X^{RM}_1$ 与 $\hat{S}^{TP}_1$；$\mathcal{L}_{BCE}$ 为检测器的二元交叉熵（标签 $[1,\dots,1,0]$）。置换对齐口径：$w_{TP}>0$ 时先在 $\mathcal{L}_{TP}$ 上做 PIT 取最优置换、再用该置换算 $\mathcal{L}_{RD}$ 与 $\mathcal{L}_{RM}$；$w_{TP}=0$（不用说话人交互模块）时按 $\mathcal{L}_{RD}$ 定置换并套用到 $\mathcal{L}_{RM}$。

## 4. 结果口径

评测指标：SI-SDR（部分数据集报 SI-SDRi）、BSS-Eval SDR、SIR、NB-PESQ / WB-PESQ、STOI、DNSMOS (OVRL)。**计数口径**：推理时若 $\hat{C} > C$，取估计信号的最优子集计算指标；若 $\hat{C} < C$，用全为 $10^{-8}$ 的信号补齐 $C - \hat{C}$ 路（沿用 SepTDA / SR-CorrNet 的做法）。带 * 的列表示推理使用**估计**说话人数。

### 4.1. REnet（RE 单独验证：可变麦数 / 未见几何），TAC 数据集，SI-SDRi (dB)

（原文 Table 5；REnet 与 TAC 均只在 TAC-ad-hoc 上训练，TAC-fixed-array 留作未见几何测试。）

| 方法 | TAC-ad-hoc P=2 | TAC-ad-hoc P=4 | TAC-ad-hoc P=6 | TAC-fixed-array P=6 |
| --- | --- | --- | --- | --- |
| TAC | 17.8 | 20.2 | 20.9 | 17.1 |
| REnet | 19.3 | 22.3 | 23.4 | 18.5 |

### 4.2. RDnet1（RD 单独验证：未知人数），WSJ0-{2,3,4,5}mix，估计人数，SI-SDRi (dB)（括号为计数准确率 %）

| 模型 | 2-mix | 3-mix | 4-mix | 5-mix |
| --- | --- | --- | --- | --- |
| SepTDA | 23.6 (99.9) | 22.1 (95.9) | 19.5 (90.1) | 16.9 (83.2) |
| SR-CorrNet-B | 24.8 (100.0) | 24.4 (99.7) | 21.9 (97.7) | 19.9 (96.9) |
| RDnet1 | 24.7 (99.9) | 24.5 (99.7) | 22.3 (99.0) | 20.8 (99.2) |

- 计算量（Table 4，GMACs/s）：RDnet1 在 C=2/3/4/5 上为 177.4 / 222.5 / 267.6 / 312.7，SR-CorrNet-B 为 188.2 / 261.9 / 335.5 / 409.1——**用更少算力拿到更高 SI-SDRi**。
- 切换 oracle → 估计人数只掉 0.1 dB（5-mix：20.9 → 20.8），归因于 99.2% 的计数准确率。

### 4.3. RDnet1 消融（WSJ0-{2,3,4,5}mix，已知人数），SI-SDRi (dB)

| 配置 | 2-mix | 3-mix | 4-mix | 5-mix |
| --- | --- | --- | --- | --- |
| 门控换加法残差 | 22.9 | 22.0 | 19.3 | 17.6 |
| 开门控 | 23.2 | 22.3 | 19.7 | 17.8 |
| + SiLU | 23.3 | 22.4 | 19.7 | 18.0 |
| + Conv-SwiGLU | 24.0 | 23.2 | 20.6 | 18.8 |
| $w_{RD}=0,\ w_{TP}=1$（开说话人交互） | 24.6 | 24.2 | 21.9 | 20.3 |
| $w_{RD}=0.1$ | 24.7 | 24.4 | 21.8 | 20.3 |
| $+\,w_{RM}=0.1$ | 24.7 | 24.4 | 22.2 | 20.6 |
| $w_{BCE}=2.5$ | 24.7 | 24.5 | 22.3 | 20.9 |

### 4.4. RDnet2（噪声混响），WSJ0-{1,2,3,4,5}mix-NR，SI-SDR (dB)

| 测试集 | 混合 | MUSE | RDnet2 | MUSE* | RDnet2* |
| --- | --- | --- | --- | --- | --- |
| 1-mix | 4.5 | 11.5 | 16.1 | 11.5 | 16.1 |
| 2-mix | −1.6 | 8.4 | 15.0 | 8.4 | 14.9 |
| 3-mix | −4.6 | 5.4 | 13.6 | 5.3 | 13.5 |
| 4-mix | −6.4 | 2.5 | 12.2 | 2.4 | 12.2 |
| 5-mix | −7.7 | 0.3 | 10.7 | 0.2 | 10.7 |

### 4.5. REDnet 增强结果（C = 1），SDR (dB) / WB-PESQ / STOI（原文 Table 7）

| 条件 (C×P) | 混合 SDR | USES SDR | TUSS SDR | FlexIO SDR | REDnet SDR | FlexIO PESQ | REDnet PESQ | REDnet STOI |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| WHAM! (1×1) | −0.9 | 10.2 | 13.6 | 13.8 | 16.4 | 2.31 | 2.63 | 0.965 |
| WHAMR!-A (1×2) | −0.9 | 15.8 | 13.6 | 15.8 | 18.1 | 2.61 | 2.91 | 0.974 |
| WHAMR!-R (1×2) | 0.0 | 13.8 | 12.4 | 14.9 | 17.5 | 2.58 | 2.93 | 0.973 |
| CHiME-4 (1×4) | 7.6 | 18.3 | 17.1 | 21.3 | 21.4 | 2.86 | 3.21 | 0.982 |
| CHiME-4 (1×5) | 7.6 | 18.3 | 17.1 | 22.3 | 22.2 | 2.96 | 3.30 | 0.985 |

### 4.6. REDnet 分离结果（C > 1），SDR / SIR (dB) / WB-PESQ（原文 Table 8）

| 条件 (C×P) | 混合 SDR | DNN-IVA SDR | TUSS SDR | FlexIO SDR | REDnet SDR | FlexIO SIR | REDnet SIR | FlexIO PESQ | REDnet PESQ |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| WHAMR!-R (2×1) | −4.1 | — | 9.5 | 9.7 | 13.8 / 13.7 | 25.5 | 32.7 | 1.84 | 2.34 |
| WHAMR!-R (2×2) | −4.1 | — | 9.5 | 12.5 | 15.7 | 29.6 | 34.4 | 2.22 | 2.65 |
| WSJ1-CHiME (2×2) | −1.3 | 10.7 | 14.9 | 19.6 | 19.6 | 35.0 | 37.4 | 3.36 | 3.49 |
| WSJ1-CHiME (2×4) | −1.2 | — | 15.1 | 21.6 | 21.2 | 37.3 | 38.3 | 3.60 | 3.69 |
| WSJ1-CHiME (3×3) | −4.2 | 7.7 | 11.4 | 17.3 | 18.2 | 30.4 | 34.0 | 3.03 | 3.24 |

（「混合 SDR」为未处理混合的 SDR；「—」为原文中该基线在该条件下无值。WHAMR!-R (2×1) 的 REDnet 两列 13.8 / 13.7 分别对应估计与 oracle 人数，其余条件两列同值。）

### 4.7. 真实录音 DNSMOS（CHiME-4 测试集，原文 Table 9）

| 方法 | 模拟 1ch | 模拟 5ch | 真实 1ch | 真实 5ch |
| --- | --- | --- | --- | --- |
| MVDR | 2.08 | 2.57 | 1.46 | 1.95 |
| USES | 3.03 | 3.22 | 3.07 | 1.58 |
| U2-C | — | — | 3.08 | — |
| FlexIO | 3.11 | 3.17 | 2.91 | 3.05 |
| REDnet | 3.27 | 3.29 | 3.15 | 3.10 |

（仅用模拟数据训练，REDnet 在 CHiME-4 真实集上仍超过表中的 USES、U2-C 与 FlexIO；各基线的 1ch/5ch 配对已按 REDnet 原文 Table 9 和 FlexIO 原文 Table 5 逐格复核，核验日期 2026-10-27。）

## 5. 测试基准与性能

**测试基准**：三条线各自独立验证再合并成 REDnet——① REnet 在 TAC 数据集（ad-hoc 阵训练 / fixed-array 未见几何测试，16 kHz，C=2，混响目标）；② RDnet1 在 WSJ0-{2,3,4,5}mix（单麦、消声、无噪、8 kHz）、RDnet2 在 WSJ0-{1,2,3,4,5}mix-NR（噪声混响版，额外含单说话人条件）；③ REDnet 严格沿用 FlexIO 的实验设置，五个数据集合并（WSJ0-{2,3}mix、WHAM!、WHAMR!-A/-R、WSJ1-CHiME4、CHiME-4，16 kHz），训练与测试麦克风数刻意留出未见档位（如 WSJ1-CHiME4 的 3 麦、CHiME-4 的 3/5 麦）以检验泛化。基线：REnet 比 TAC（按 USES 设计实现、算力对齐，4 层 TAC vs 4 个 REBlock）；RDnet 比 SepTDA、SR-CorrNet-B、ReSepNet、SepNet、gDPRNN、RSS 与 MUSE；REDnet 主要比 FlexIO（其推理假设已知说话人数与源类型），并附 USES / TUSS / U2-C / DNN-IVA / MVDR。评价含 SI-SDR(i)、BSS-Eval SDR、SIR、NB/WB-PESQ、STOI、DNSMOS，以及 RDnet 的 GMACs/s。

**性能指标**：全部数字见「结果口径」（REnet 在三档 ad-hoc 麦数与未见 fixed-array 上一致优于 TAC；RDnet1 在 3/4/5-mix 超过此前最好的 SR-CorrNet-B 且算力更低；RDnet2 全面优于 MUSE；REDnet 在增强与分离两类任务、模拟与真实录音上多数条件超过 FlexIO 等强基线，且用估计人数推理时几乎不掉点），此处不重复。总体结论：论文声称在多个公开数据集上取得 state-of-the-art，且对真实录音有良好泛化。

（来源：笔记正文「结果口径」，核验日期 2026-10-09）

## 6. 使用判断

- **适合**：需要**一个模型同时覆盖「说话人数未知」与「麦克风数/几何多变」**的部署（会议人数不定、设备组合可换）；希望**免 post-selection、免预设最大说话人数**的说话人数自适应分离（对比 separate-then-select 必须按最大人数输出再挑）；科研上作为「OR-PIT 递归范式 + TF-GridNet 系强骨干 + 端到端训练」的强基线，或用 RE 替代 TAC 做可变麦数编码器（论文报同算力下更好，且复杂度对麦数为线性）。
- **不适合**：低延迟/流式场景——RD 每分离一个说话人就多一轮前向，推理成本随说话人数线性增长，论文只给了 RDnet 的 GMACs/s，未给 REDnet 的延迟/RTF；下游按固定输出流数（固定 N 通道）接线的系统——输出路数 $\hat{C}$ 由阈值 $\tau=0.5$ 决定、会变；只有单说话人增强且算力极紧的场景（该模型仍要走检测 + 递归解码）。
- **风险**：训练期依赖 oracle 人数展开 RD、推理期才估计人数，训练/推理口径不一致；$\tau$ 是控制过分离/漏分离的唯一旋钮，论文未做 $\tau$ 敏感性分析，也未分析计数错误的失败模式（除 WSJ0-mix 上的计数准确率）；"未知几何"的泛化只在 REnet 的 TAC-ad-hoc → TAC-fixed-array 上单独验证，REDnet 整机未做几何泛化消融；真实录音只验了 CHiME-4（DNSMOS）；论文未给代码/权重链接。

## 7. 关键来源

- [REDnet: Recursive Encoder and Decoder for Speech Separation under Unknown Number of Speakers and Variable Number of Microphones（arXiv:2608.24659）](https://arxiv.org/abs/2608.24659)
  - 内容定位：原始论文（v1 2026-08-25，eess.AS，Comments: "in submission"，无会议/期刊信息；作者 Fulin Wu、Zhong-Qiu Wang，南方科技大学计算机科学与工程系）。
  - 用途：核验对象身份（题名、作者、提交日期、venue 状态）、RE/RD 机制与公式（式 (1)(2)、损失定义）、Table 1–9 的全部实验数字与本笔记的边界口径。
  - 核验日期：2026-10-09

## 8. 相关对象

- [[方向/AI语音/团队/Z.-Q. Wang Group（Zhong-Qiu Wang 组）|Z.-Q. Wang Group]]：提出团队（SUSTech；同组产出 TF-GridNet）。
- [[方向/AI语音/模型/TF-GridNet|TF-GridNet]]：REBlock / Backbone / RDBlock 的骨干原型（本工作只改 PReLU→SiLU 并插入 Conv-SwiGLU）。
- [[方向/AI语音/模型/FlexIO|FlexIO]]：最直接的对标与主基线——同为单模型柔性输入输出，但说话人数靠外部 prompt 给定、模型不做计数。
- [[方向/AI语音/知识/基础概念/PIT（置换不变训练）|PIT]]：RD 所属的递归分离范式源头（OR-PIT 谱系）——PIT 本身不解决说话人数未知，REDnet 用「检测器 + 逐人递归解码」补上计数能力。
- [[方向/AI语音/模型/UniArray|UniArray]]：同属"输入维度可变"的阵列几何无关路线，机制不同——UniArray 先用 [[方向/AI语音/知识/基础概念/Neural-VME（神经虚拟麦克风估计）|VME]] 把通道数补齐归一，REDnet 用递归编码器逐麦累积、不补通道。
- [[方向/AI语音/模型/Geo-DConv|Geo-DConv]]：几何条件化路线（坐标已知时显式注入），与 REDnet 的不喂坐标、几何未知路线相对。
- [[方向/AI语音/模型/AmbiDrop|AmbiDrop]]：另一条 array-agnostic 路线（Ambisonics 规范表示 + 通道 dropout），REDnet 不改表示域、直接在逐麦 STFT 上递归累积。
- [[方向/AI语音/模型/MSEN（特征束多阶编码器）|MSEN]]：同属几何无关阵营的编码器设计（特征束多阶空间编码）。
- [[方向/AI语音/知识/技术路线/Array-Agnostic SE（阵列无关语音增强）|Array-Agnostic SE]]：REDnet 的技术路线归属。
- [[方向/AI语音/知识/技术路线/Distributed Multichannel SE（分布式异步多通道增强）|Distributed Multichannel SE]]：ad-hoc 阵列相邻路线；REDnet 的 RE 面向可变麦数，但不含分布式异步与带宽约束。
- [[方向/AI语音/知识/基础概念/SS（语音分离）|SS]]、[[方向/AI语音/知识/基础概念/Array vs Multi-Channel（阵列与多通道）|Array vs Multi-Channel]]：任务与阵列口径背景。
- [[方向/AI语音/知识/基础概念/Beamforming（波束形成）|Beamforming]]：论文相关工作中处理可变麦数的第一类做法（线性滤波），REDnet 与之对照。
- [[方向/AI语音/数据集/WHAM|WHAM]]、[[方向/AI语音/评估/CHiME（语音分离与识别挑战赛）|CHiME]]：REDnet 训练/评测数据来源（WHAM!/WHAMR! 系、CHiME-4）。
- [[方向/AI语音/评估/SI-SDR|SI-SDR]]、[[方向/AI语音/评估/SIR（信号干扰比）|SIR]]、[[方向/AI语音/评估/PESQ|PESQ]]、[[方向/AI语音/评估/STOI 与 ESTOI|STOI 与 ESTOI]]、[[方向/AI语音/评估/OVRL_MOS|DNSMOS (OVRL)]]：评测指标。
- [[方向/AI语音/知识/调研与地图/Array Speech Enhancement Frontier（阵列语音增强前沿调研）|阵列语音增强前沿调研]]：本对象在阵列无关 / 柔性阵列阵营中的定位入口。

## 9. 待验证

- **venue 与开源**：arXiv Comments 仅 "in submission"，无会议/期刊接收信息；全文（含参考文献）均未给出代码或权重链接。
- **Table 1 的 RE 行**：纯文本导出为分栏平铺，REnet 的 P / C 取值（含 `{}, {6}`、`{}, {2}` 两行）错位无法可靠归属；本笔记只写了明确的「TAC-ad-hoc 训练 / TAC-fixed-array 测试」，RE 训练时的具体麦数档位待查原表。
- **Table 8 的 REDnet 两列**：多数条件估计 / oracle 两列同值，仅 WHAMR!-R (2×1) 出现 13.8 与 13.7 两个值；哪一列对应估计人数需查原表（正文只说"用估计人数时仅轻微下降"）。
- **效率口径**：只给了 RDnet 的 GMACs/s 与 C=2/3/4/5 的计算量，未给 REDnet 整机的延迟、RTF、显存，也未讨论递归深度增加时的推理成本。
- **阈值 $\tau$**：0.5 的选取依据、敏感性，以及计数错误的失败模式（漏检 vs 过检）未分析。
- **机制论断证据**：RE 优于 TAC 的"更好捕获空间线索"为论文观察性结论，未给可视化/探针实验。
- **泛化边界**：未见几何只在 TAC-fixed-array 上验过（REnet）；未见麦数档位在 REDnet 上参与测试，但"训练未出现过的说话人数 > 训练最大值"的行为未说明；真实录音泛化仅 CHiME-4 的 DNSMOS。

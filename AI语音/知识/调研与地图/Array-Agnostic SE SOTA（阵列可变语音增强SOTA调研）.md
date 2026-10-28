---
title: Array-Agnostic SE SOTA（阵列可变语音增强SOTA调研）
类型: 调研
核验日期: 2026-10-28
证据状态: 作者报告结果；未独立复现
相关任务:
  - 语音增强
  - 语音分离
  - 目标说话人提取
  - Ambisonics 编码
aliases:
  - 阵列可变语音增强SOTA
  - 阵列无关语音增强SOTA
  - Array-Agnostic Speech Enhancement SOTA
  - 阵列可变方案SOTA
tags:
  - 类型/对象
  - 方向/AI语音
  - 任务/语音增强
  - 任务/语音分离
  - 任务/多通道增强
  - 主题/阵列无关
  - 主题/阵列信号
---

# Array-Agnostic SE SOTA（阵列可变语音增强SOTA调研）

> [!abstract] 结论先行
> 截至 **2026-10-28**，没有跨任务、跨数据集、跨评测协议都成立的单一“阵列可变 SOTA”。更可靠的结论是：已知坐标的真实录音 SE 优先验证 **Geo-DConv**；重视广几何、坏麦鲁棒性和公开实现优先 **AmbiDrop**；仿真双人 AGA-SS 的强数值候选是 **UniArray**；需要同时处理可变麦数与未知说话人数时，**REDnet** 最直接，但仍是投稿中的预印本证据；穿戴设备（眼镜 / 耳机）优先看 **HyBeam**（混合 mic × beamformer），但只有仿真与 arXiv 证据。
>
> 本页数值均为**论文作者报告，尚未独立复现**。除特别注明外，分数越高越好；不同表格之间不得直接比较数值大小。已有强前端且允许离线后处理时，另将 **Uni-ArrayDPS** 列为生成式精修候选；它不是独立的阵列前端。
>
> **一页横排见 §2**：14 个方案（16 行，含两个双骨干变体）拆成 **A 评分表**（DNSMOS / **SI-SDR 三件套** / PESQ）、**B 设置表**（参数量与算力 / 训练阵列 / 训练数据 / 测试数据）与 **C 其它指标表**（SDR / WER / COVL / CER），并给出固定阵列侧的容量对齐参照；**各行的测试条件（测试阵列、SNR、混响、采样率、任务）逐条列在 §2.2**，跨行比较前先看那张表。读之前先记住一个事实——**DNSMOS 这一列 16 行里有 11 行是空的**，这是该阵营共同的评测缺口，不是本页漏抄。

## 1. 判定口径与检索范围

### 1.1. 这里的 SOTA 指什么

本页回答“**在某一任务、某一训练/测试协议下，哪些方案有领先或特别有部署价值的作者报告结果**”，而不是制作一个跨任务总分榜。入选需满足以下至少一项：

- 在原文的同条件对照中取得领先结果，且能核到完整表格；
- 在未见几何、未见麦数、坏麦或未知说话人数等关键维度上提供独特证据；
- 作为限定协议下的强基线或工程起点，有明确的比较价值。

“作者自称 SOTA”本身不构成入选依据。正式发表、预印本和只有摘要证据的工作分别标记；**同行评审状态不等于结果已被独立复现**。

### 1.2. 任务必须拆开

| 任务缩写 | 本页含义 | 不能与什么混排 |
| --- | --- | --- |
| SE | 单目标语音增强，可能含降噪、去混响；须注明直接路径或其他目标 | 多人分离的 SI-SDRi、Ambisonics 系数重建 |
| SS / CSS | 多人语音分离 / 连续语音分离；CSS 常以 WER 为终点 | 单目标 SE 的 SDR、PESQ |
| 柔性输入输出 | 同一模型覆盖不同麦数和输出人数；人数可能给定或自动估计 | 固定输出流、只做 SE 的模型 |
| 生成式精修 | 用原始混合和判别式前端输出生成精修语音；须与同一前端成对比较 | 独立前端的端到端结果、无监督 BSS |
| TSE | 目标说话人提取；GC-SSF 使用目标 DOA 作为空间提示 | 无方向或无注册信息的通用 SE |
| Ambisonics 编码 | 从物理阵列重建空间声场系数 | 干净语音波形增强 |
| 无监督 BSS | 不用配对干净分离目标训练的盲源分离 | 有监督 SE / SS |

采样率、目标信号、训练数据、测试几何是否见过、麦数、说话人数和指标定义也必须一致，才能作严格横向排名。

**边界排除**：Spatial-Magnifier（固定已知几何的空间上采样）、CrossArray-PF（多阵列协同 spotforming）、WG-Auto-HOA / Adaptive Rotary Steering（HOA 域，严格说是 order-agnostic 而非 array-agnostic）不纳入本页主表。把它们混进来，会把「阵列无关」与「固定几何补全 / 分布式协同 / 阶数无关」三类问题重新合并。

### 1.3. 检索与证据等级

- **时间范围**：以 2022–2026 年的 array-agnostic / array-invariant / geometry-agnostic / variable-microphone 工作为主；最后检索于 2026-10-28，补入此前遗漏的 Uni-ArrayDPS 生成式精修支路。
- **来源**：arXiv 原文，ISCA、IEEE、MERL 等官方出版页，Crossref 元数据，以及作者官方代码仓库；辅以核心论文的参考文献向前追溯。
- **纳入**：与可变麦数、未见几何或阵列无关表示直接相关，并有可核验的方法与结果。
- **A｜正式论文＋全文证据**：可核到正式出版信息与结果表。
- **B｜预印本＋全文证据**：可核到结果表，但不能把投稿中写成已接收。
- **C｜摘要级证据**：只能记录作者主张，不能据此给出定量冠军。

本页是分协议文献调研，不是 PRISMA 式穷尽性系统综述，也不是同条件复现横评。文献键对应同目录 `references.bib`，逐项访问记录见 §9。

## 2. 一页横排（DNSMOS · SI-SDR · 参数量 · 训练设置）

> [!warning] 读表规则
> §2.1 拆成两张表：**A 表只放分数**（输入 / 输出 / 增益 / PESQ / DNSMOS），**B 表只放训练与测试设置**；另有一张按行存档的 **C 表（其它指标）**。三表行一一对应。同一张表里**只有落在同一「组」的行可以互相比较**（G1 RealMAN 几何泛化 / G2 仿真增强 / G3 仿真分离 / G4 CHiME-4 真实分离 / G5 生成式精修）。DNSMOS 大量为「—」不是漏抄：这些论文根本没报，原因与补法见 §2.5。**不得把增益填进绝对值列**；增益带 **†** 的是本页推算（输出 − 输入），不带 † 的才是作者报告，见 §2.1.1；SDR 与 WER 不是 SI-SDR 变体。参数量与算力不可互相推断。G1′ 指 RealMAN 6 麦固定档，麦数、采样率与 G1 的 ≤4 麦随机档都不同，只能各自组内比。**逐行测试条件见 §2.2**。

### 2.1. 阵列可变 / 无关阵营

#### A. 评分表（只放分数）

| 方案（年份·证据） | 组 | 输入 SI-SDR<br>（noisy，dB） | 输出 SI-SDR<br>（绝对，dB） | 增益 SI-SDRi<br>（dB） | PESQ | DNSMOS<br>SIG / BAK / OVRL |
| --- | --- | ---: | ---: | ---: | ---: | --- |
| **SpatialNet-Geo-DConv**（2026·A） | G1 | −9.47 | **4.22** | **13.69** † | 2.48 | **3.16 / 3.51 / 2.68** |
| **TF-GridNet-Geo-DConv**（2026·A） | G1 | −9.47 | 3.90 | 13.37 † | 2.59 | 3.21 / 3.62 / **2.77** |
| USES2-comp（同表重测） | G1 | −9.47 | 4.17 | 13.64 † | 2.52 | 3.02 / 3.50 / 2.56 |
| FaSNet-TAC（老基线） | G1 | −9.47 | −0.81 | 8.66 † | 1.74 | 2.48 / 3.18 / 2.05 |
| **[[方向/AI语音/模型/AmbiDrop]]**（FT-JNF 骨干，2026·A） | G2 | −6.20 / −6.35 | 5.06 / **4.77** | **11.26 / 11.12** † | 1.81 / 1.78 | — |
| AmbiDrop（IC-ConvTasNet 骨干） | G2 | −6.20 / −6.35 | 2.48 / 1.40 | 8.68 / 7.75 † | 1.49 / 1.43 | — |
| **[[方向/AI语音/模型/HyBeam]]**（2025·B） | G2 | — | 1.0 / **1.1** | — | 1.63 / **1.65** | — |
| **[[方向/AI语音/模型/DeFTAN-AA]]**（2024·A） | G2 | −7.80 | 9.4 | **17.20** † | 2.95 | — |
| **[[方向/AI语音/模型/SFB-NSE]]**（TSCBM+FB，2025·B） | G2 | — | — | — | 2.76 | — |
| **[[方向/AI语音/模型/UniArray]]**（2025·A） | G3 | — | 未报 | **13.46**（作者报告） | —（未录） | — |
| **[[方向/AI语音/模型/REDnet]]**（2026·B） | G4 | — | — | — | 3.30 | — / — / **3.15**（1ch）<br>— / — / 3.10（5ch） |
| **[[方向/AI语音/模型/FlexIO]]**（2026·A） | G4 | — | — | — | 2.96 | — / — / 2.91（1ch）<br>— / — / 3.05（5ch） |
| **[[方向/AI语音/模型/VarArray]]**（2022·A） | G3 | — | — | — | — | — |
| **[[方向/AI语音/模型/LABNet]]**（2025·A） | G1′ | — | — | — | 2.34 | — |
| **[[方向/AI语音/模型/CaSNet]]**（2026·A） | G1′ | — | — | — | 2.27 | — |
| **[[方向/AI语音/模型/Uni-ArrayDPS]]**（USES2 前端，2026·B） | G5 | −6.10 | 1.30 / 2.40 | 7.40 / 8.50 † | WB 2.14 / 2.24 | — / — / 2.73（4麦）<br>— / — / 2.74（8麦） |

> [!note] † 标记的含义
> **† = 本页推算值**（该行「输出 SI-SDR」减去「输入 SI-SDR」），不是作者报告值；四舍五入到两位小数，原始数字可能相差 0.01。没给 noisy 行的方案一律留「—」，不内插、不拿同组均值代填。AmbiDrop 两行的成对数值顺序均为 seen / unseen 几何。Uni-ArrayDPS 行的 7.40 / 8.50 dB † 是相对**未处理 noisy 输入**；相对同一 USES2 前端的精修增益只有 +0.21 / +0.20 dB（§4.5），不要把前者读成精修器贡献。**作图时请把 † 值与作者报告值分色或分纹样**（空心柱 / 虚线段），并在图注写明「† 为本页推算」。

**PESQ 列保留论文原值，不区分 NB / WB**；带宽、采样率与目标信号的差异见 §2.2，跨行比较前先确认口径。

#### B. 训练与测试设置

| 方案                      | 参数 / 算力                 | 训练阵列                                                         | 训练数据                                                           | 测试数据 · 口径                                                               |
| ----------------------- | ----------------------- | ------------------------------------------------------------ | -------------------------------------------------------------- | ----------------------------------------------------------------------- |
| SpatialNet-Geo-DConv    | 1.3M / 6.08 G/s         | 随机 ≤4 麦（几何、麦数、通道顺序同时随机）                                      | RealMAN train：83.7 h 语音 + 144.5 h 噪声，8 kHz                     | RealMAN test（8 kHz、直达路径、同一固定 4 麦子阵）；Table 2 另测 1 / 2 / 5 麦 + CHiME-4；G1 |
| TF-GridNet-Geo-DConv    | 8.3M / 73.12 G/s        | 同上                                                           | 同上                                                             | 同上                                                                      |
| USES2-comp              | 2.5M / 70.26 G/s        | 同上，同训练预算                                                     | 同上                                                             | 同上                                                                      |
| FaSNet-TAC              | 2.7M / 9.76 G/s         | 同上                                                           | 同上                                                             | 同上；结构只对麦数 / 排列不变                                                        |
| AmbiDrop（FT-JNF）        | 0.14M / 未报              | 20 种 7 麦 1D / 2D / 3D 阵；理想 2 阶 Ambisonics 9 通道               | 仿真 WSJ0 + 镜像法（小时未报）                                            | 同批 7 麦阵的 seen / unseen 几何；Project Aria 真实眼镜；G2                          |
| AmbiDrop（IC-ConvTasNet） | 未报 / 未报                 | 同上                                                           | 同上                                                             | 同上                                                                      |
| HyBeam                  | 未报 / 未报                 | 8 个 4 麦眼镜框阵（共 11 种，留出 0c / 1 / 4）；低频 raw mic + 高频 beamformer | 仿真 WSJ0 + 镜像法，16 kHz，T60 0.2–0.5 s                             | 11 种穿戴阵的 seen / unseen（留出 0c / 1 / 4）；G2                                |
| DeFTAN-AA               | 2.2M / 35.7 G/s         | **单一** 4 麦圆阵 r = 10 cm                                       | DNS-Challenge 2020 + 镜像法，SNR −10~10，T60 0.2–1.2                | 仿真 6 阵 × 3/4/8 麦 + **作者自采**真实 2 阵 × 100 条（ReSpeaker v2.0 圆阵 + UMA-16 矩形子阵）；G2                                    |
| SFB-NSE                 | 未报 / 28.3 G FLOPs       | **单一** 5 麦 UCA r = 0.5 cm                                    | VoiceBank+DEMAND 仿真，T60 0.2–0.35，SNR −5~10                     | 未见 UCA：7 / 9 麦 × r = 1 / 1.5 cm；G2                                      |
| UniArray                | 7.20M / 12.96 G/s       | 8 麦圆阵 r = 5 cm + 4 组子集 + 通道置换                                | 空间化 WSJ0-2mix，RT60 0.1–1.0，SNR 10–20                           | 10 种未见几何（圆 / 线阵，2–8 麦）；双人分离；G3                                          |
| REDnet                  | 未报 / 177.4–312.7 GMAC/s | 训练含 2/4/6 麦，测试留 3/5 麦                                        | 五数据集合并（WSJ0-2mix/3mix、WHAM!、WHAMR!、WSJ1-CHiME4、CHiME-4），16 kHz | CHiME-4 真实 1 / 5 麦（DNSMOS）+ 仿真 1×5（SDR）；G4                              |
| FlexIO                  | 3.42–3.59M / 未报         | 1–5 麦，测试留 3/5 麦                                              | 同 REDnet 五数据集                                                  | CHiME-4 真实 1 / 5 麦（WER / DNSMOS）+ 仿真 1×5；G4                             |
| VarArray                | 2.77M / 0.75 G/s        | 8 麦 AMI 阵 + 4 麦子集                                            | AMI 会议语料（CSS）                                                  | AMI-MDM 8 / 4 麦 + 微软内部 MS 7 / 3 麦（真实会议）；G3                              |
| LABNet                  | 0.052M / 0.316 G/s      | 训练 1–6 麦随机 + 置换（单一 6 麦阵派生）                                   | WSJ0+WHAM! 24.9 h                                              | RealMAN 6 麦（CaSNet 重测）；原文另测 WSJ0+WHAM! 12 麦；G1′                         |
| CaSNet                  | 0.052M / 0.325 G/s      | 训练 1–6 麦随机，测试 2–12 麦                                         | WSJ0-WHAM! 24.9 h + RealMAN 83.7 h                             | RealMAN 6 麦（另测 2–12 麦）+ WSJ0-WHAM! 仿真；G1′                               |
| Uni-ArrayDPS            | 未报 / 300 步 + 前端         | 前端随机 2–8 麦；先验单通道，不含阵列参数                                      | 前端：DNS 仿真 80k × 10 s；先验：DNS 220 h                              | RealMAN static 前 4 / 8 麦（真实 SE）+ 仿真 4 / 8 麦双人 SS；G5                     |

#### C. 其它指标（按行存档，不进排序）

| 方案 | 指标 | 数值 |
| --- | --- | --- |
| SpatialNet-Geo-DConv | SDR（BSS-Eval） | 9.72 |
| TF-GridNet-Geo-DConv | SDR（BSS-Eval） | 9.05 |
| USES2-comp | SDR（BSS-Eval） | 8.62 |
| FaSNet-TAC | SDR（BSS-Eval） | 5.76 |
| AmbiDrop（FT-JNF） | STOI（seen / unseen） | 0.86 / 0.84 |
| AmbiDrop（IC-ConvTasNet） | STOI | —（未报） |
| HyBeam | STOI（seen / unseen） | 0.82 / 0.82 |
| DeFTAN-AA | WER | 14.7% |
| SFB-NSE（TSCBM+FB） | CSIG / CBAK / COVL / STOI | 4.36 / 3.30 / 3.64 / 0.947 |
| UniArray | WB / NB-PESQ、STOI | 未录（原文只报 SI-SDRi 13.46） |
| REDnet | SDR（1×5 仿真） | 22.2 |
| FlexIO | SDR（1×5 仿真） | 22.3 |
| VarArray | WER（AMI 8 / 4 麦） | 17.7 / 18.5% |
| LABNet | STOI / COVL | 0.90 / 3.14 |
| CaSNet | STOI / COVL | 0.89 / 3.06 |
| Uni-ArrayDPS（USES2 前端） | 精修增益 / CER / UTMOSv2 | +0.21 / +0.20 dB；39.3 / 35.5%；2.76 / 2.80 |

> 这表只做存档：BSS-Eval SDR 与 SI-SDR 不是同一尺度，WER / CER 是识别口径，COVL 是复合感知分，都不能与 A 表的 SI-SDR / PESQ 直接排序。

五点读法先说在前面：

- **A 表 16 行里只有 5 行有 DNSMOS**（Geo-DConv 两个变体、REDnet、FlexIO、Uni-ArrayDPS），其余 11 行是空的。
- **参数量跨三个数量级**（52k → 8.3M，见 B 表），但性能排序跟参数量排序几乎无关，见 §2.4 第 3 条。
- **B 表的训练阵列一栏能直接读出机制**：单阵列训练（DeFTAN-AA、SFB-NSE）靠结构不变性；随机子阵训练（Geo-DConv）靠数据覆盖 + 坐标条件；Ambisonics 编码（AmbiDrop）靠规范表示；HyBeam 靠多阵列训练 + 频带线索分工。Uni-ArrayDPS 则在运行时把阵列信息放入 SCM 与 FCP。
- **A 表把 SI-SDR 拆成三列：输入 / 输出 / 增益**，等于把「报告三件套」直接铺在表里。输入与输出的数值来自论文；只有 UniArray 直接报告增益，增益列里带 **†** 的 8 行是本页用「输出 − 输入」算的，算式与输入行出处见 §2.1.1。剩余「—」才是论文真的没给。
- **SDR / WER / COVL / CER 放在 C 表**：BSS-Eval SDR（REDnet / FlexIO）与 SI-SDR 不是同一尺度，VarArray 只有 WER，都不能进 A 表；C 表只做行级存档。

### 2.1.1. SI-SDR 与 SI-SDRi：两种口径差在哪

A 表原本最容易读错的一列就是「SI-SDR」。必须分清两个量：

$$\mathrm{SI\text{-}SDRi}=\mathrm{SI\text{-}SDR}_{\text{enhanced}}-\mathrm{SI\text{-}SDR}_{\text{input}}$$

- **SI-SDR**：增强**输出**相对干净参考的绝对保真度（dB）。与任务难度强相关——混响重、SNR 低时绝对值自然低。
- **SI-SDRi**：相对**同一测试集未处理混合**的**增益**（dB）。衡量「改善了多少」，与输入混合的质量强绑定。

三个后果：

1. **同一模型的两个数可以差 10 dB 以上**。DeFTAN-AA 的 SI-SDR 是 9.4，而它的输入混合是 −7.8，所以增益是 17.20 dB（A 表 † 值）。UniArray 只报增益 13.46、不报绝对值——两者放进一列会直接得出「UniArray 强于 DeFTAN-AA」的错误结论，而同口径下恰好相反。
2. **换算需要 noisy 行**。只要论文给了未处理输入那一行，增益就能算；没给就不能换算——所以 A 表里仍有 7 行增益是「—」，那不是漏抄。
3. **增益依赖输入 SNR，跨数据集不可比**。同一个模型换个更低 SNR 的混合，增益会变大——「增益高」不等于「输出好」。

**† 值的依据：输入行出处**（算法只有一步——「该行绝对 SI-SDR − 同表输入 SI-SDR」，逐句相减后平均）

| 数据组 | 未处理输入行出自 | 覆盖的行 |
| --- | --- | --- |
| RealMAN 几何泛化（G1） | Geo-DConv（arXiv 2607.18658v1）Table 1「No processing」，−9.47 dB | SpatialNet-Geo / TF-GridNet-Geo / USES2-comp / FaSNet-TAC |
| AmbiDrop 仿真（G2） | AmbiDrop（arXiv 2607.00548v1）Table I「Noisy (Input)」：训练阵 −6.20、未见阵 −6.35 dB | FT-JNF 与 IC-ConvTasNet 两个骨干 |
| DeFTAN-AA 仿真（G2） | DeFTAN-AA Table 1「带噪」行，−7.80 dB | DeFTAN-AA（M = 4 参考阵） |
| UniArray 分离（G3） | 原文只给增益、无 noisy 行 | 13.46 为作者报告，故不带 † |
| Uni-ArrayDPS RealMAN（G5） | Uni-ArrayDPS（arXiv 2603.24810v1）Table II「Noisy」，−6.10 dB | Refined USES2 的 4/8 麦输出 1.30 / 2.40 dB；对应 7.40 / 8.50 † |

**不能把增益当作绝对值排序**：UniArray 只报告增益 13.46，没有绝对值，不能把它写成“绝对值 13.46 > DeFTAN-AA 9.40”。即便只在增益口径内，DeFTAN-AA 17.20 > SpatialNet-Geo 13.69 ≈ USES2 13.64 > UniArray 13.46 > TF-GridNet-Geo 13.37 > AmbiDrop 11.12 > FaSNet-TAC 8.66，也不能跨任务宣布冠军。Uni-ArrayDPS 在 A 表的 † 增益是相对**未处理 noisy 输入**；其相对**原 USES2 前端**的提升只有 4/8 麦 **+0.21 / +0.20 dB**，后者才衡量精修器本身的贡献。

**四条常见误用**：

1. 把增益填进绝对值列（本表此前 UniArray 13.46 与 DeFTAN-AA 9.4 并列就是这种情况，现已拆列）。
2. 拿 SI-SDRi 跨数据集比——输入混合不同，增益的起跑线不同。
3. 只看增益不看绝对值——AmbiDrop 的基线在未见阵列上绝对 SI-SDR 是 **−15.08**，增益为负且远低于输入的 −6.35；此时任何「增益」说法都会掩盖输出已经不可用。
4. 以为 SI-SDR(i) 高就等于听感好——它与感知脱钩，见 [[方向/AI语音/评估/SI-SDR]]。

**报告规范（三件套）**：未处理输入的 SI-SDR、增强输出的绝对 SI-SDR、以及两者之差。只给增益时，读者无法判断输出到底在哪一档。

### 2.2. 测试条件逐项（为什么这些数字不能横比）

A 表里同一列数字跨行不可比的根源不止「指标不同」，而在四个轴上全都不一致：**测试阵列（麦数 / 几何 / 是否 OOD）· 信号条件（真实或仿真 / SNR / 混响）· 采样率 · 任务与目标信号**。下表逐行给出这四轴；同一组内条件完全相同的行合并为一行。

| 行（组） | 任务 / 目标信号 | 测试数据 | 测试阵列（麦数 × 几何） | 与训练的失配 | SNR · 混响 | 采样率 | 指标 |
| --- | --- | --- | --- | --- | --- | --- | --- |
| **固定阵列上界档**（SpatialNet / TF-GridNet / USES2-comp / FaSNet-TAC，G1-固定） | 单目标 SE；目标 = 直达路径滤波语音 | RealMAN 真实录音 | 训练与测试为**同一固定子阵**（论文称 geometry-specific upper bound） | 无 | 混噪沿用 RealMAN 配置，SNR 数值未在文中列出 | **8 kHz**（256 点窗 / 128 帧移，4 s 段） | SDR / SI-SDR / PESQ / STOI / P808 / SIG / BAK / OVRL |
| **阵列无关档**（SpatialNet-Geo-DConv / TF-GridNet-Geo-DConv / USES2-comp / FaSNet-TAC，G1） | 同上 | RealMAN；另 CHiME-4（6 麦真实） | 随机 ≤4 麦子阵（几何、麦数、通道顺序同时随机）；Table 2 另测 1 / 2 / 5 麦 | **麦数与几何同时 OOD**（训练最多见 4 麦，测到 5 / 6 麦） | 同上 | **8 kHz**（同上） | 同上 |
| **AmbiDrop**（FT-JNF / IC-ConvTasNet，G2） | SE（降噪 + 去混响）；目标 = 阵前参考麦的**直达路径**分量 | 仿真 WSJ0 + 镜像法（训练阵与测试阵分开）；Project Aria 真实眼镜录音 | 20 个 **7 麦** 1D / 2D / 3D 阵，r = 0.05 / 0.1 m，自由场与刚性球 ATF；输入为**理想 2 阶 Ambisonics 9 通道** | 未见几何（麦数仍为 7） | 目标 + 5 个干扰源，房间与声源设置沿用文献 [21]（SNR / T60 未录）；Aria 真实集另加噪至 SNR 30 dB | 16 kHz | SI-SDR / PESQ / STOI |
| **HyBeam**（G2） | SE；目标 = 阵前参考麦信号（含混响） | 仿真 WSJ0 + Pyroomacoustics 镜像法 | 训练 8 个 **4 麦眼镜框阵**；测试 11 阵（留出 0c / 1 / 4），随机偏航 | 未见几何（麦数仍为 4） | T60 0.2–0.5 s；传感器噪声 30 dB 输入 SNR；5 个干扰源分占 20°–340° | 16 kHz | SI-SDR / PESQ / STOI |
| **DeFTAN-AA**（G2） | SE（降噪 + 去混响） | 仿真（LibriSpeech + DNS 噪声，镜像法）；**作者自采**真实 2 阵 × 100 条（ReSpeaker v2.0 + UMA-16） | 仿真 6 种阵（参考圆 / 变半径圆 / 矩形 / 线 / 四面体 / 随机）× 3 / 4 / 8 麦，孔径 2–20 cm；真实 4 麦圆阵 r = 2.7 cm + 8.2×4.2 cm 矩形阵 | 未见几何 + 未见麦数 | 仿真 SNR −10~10 dB、T60 0.2–1.2 s；真实 SNR 5 dB、T60 0.2 s、办公室 4.1×6×2.5 m | 16 kHz（512 点 / 32 ms / F = 257） | SI-SDR（另报 PESQ / STOI） |
| **SFB-NSE**（G2） | SE | 仿真 VoiceBank+DEMAND（镜像法；训练 / 测试噪声类型不重叠） | 测试 4 种**未见 UCA**：7 / 9 麦 × r = 1 / 1.5 cm；扫描共 9 组（M = 5/7/9 × r = 0.5/1/1.5 cm） | 未见几何，但**同为 UCA**，只变 M 与 r | SNR −5~10 dB、T60 0.2–0.35 s、房间 3×3×2.5 ~ 7×9×3 m、目标与干扰最小方位差 5° | 16 kHz（25 ms / 400 点、hop 6.25 ms，由窗长推得） | PESQ / CSIG / CBAK / COVL / STOI |
| **UniArray**（G3） | **双人分离**；目标 = 干净混响语音 | 仿真空间化 WSJ0-2mix | 10 种未见几何：C-8-10 … L-2-5（圆 / 线阵，2–8 麦，r = 3–10 cm） | 未见几何 + 未见麦数 | SNR 10–20 dB、RT60 0.1–1.0 s、重叠率 10–100%、扩散噪声 | 16 kHz | **SI-SDRi** / WB·NB-PESQ / STOI |
| **REDnet / FlexIO**（G4） | 增强 + 分离；人数 REDnet 自动估计、FlexIO 需外部给定 | CHiME-4 真实（DNSMOS）+ 五数据集仿真（SDR） | CHiME-4 1 / 3 / 5 麦（3、5 麦为未见档）；仿真 1–5 麦 | 未见麦数 | 真实集为 CHiME-4 自带噪声与混响（未控 SNR）；仿真沿用 WHAM! / WHAMR! 配置 | 16 kHz | DNSMOS OVRL / SDR / SI-SDR / SIR / PESQ / STOI |
| **VarArray**（G3） | CSS（连续分离）→ 每路 ASR | AMI-MDM（真实会议）+ 微软内部 MS（真实） | AMI 8 麦圆阵 r = 10 cm（另测取奇数麦的 4 麦）；MS 7 麦 = 6 麦圆阵 r = 4.25 cm + 圆心麦 | 几何已知，但**麦数减档**（8→4、7→3） | 真实会议混响，未控 SNR；评测无 ground-truth 切分 | 16 kHz | **WER**（asclite） |
| **LABNet / CaSNet**（G1′） | SE；目标 = 参考通道**含混响**语音 | RealMAN 真实（LABNet 行由 CaSNet 重测） | 固定 **6 麦**档（CaSNet 另测 2–12 麦）；LABNet 原文为 6 麦训练 / 12 麦测试 | 无（同麦数同几何） | RealMAN 混噪 **SNR −5~15 dB** | 16 kHz | PESQ / STOI / COVL |
| **Uni-ArrayDPS**（G5） | 判别式 SE / 双人 SS 前端＋生成式精修；目标 = 参考麦无混响语音 | 仿真 ad-hoc 阵列；RealMAN 静态真实语音与噪声，真实集仅 SE | 仿真逐样本随机 8 麦，评测取前 4/8 麦；RealMAN 取前 4/8 麦 | 判别前端承担阵列适配；RealMAN 为跨域测试，不是系统的未见拓扑扫描 | 仿真 SNR −10~5 dB、T60 0.13–0.55 s；RealMAN static 子集自混 SNR −15~5 dB（**非官方 test 混合集**） | 16 kHz | SI-SDR / PESQ / STOI / eSTOI / DNSMOS / UTMOSv2 / WER / CER |

**四条断裂轴**（决定哪两行能并读）：

| 轴 | 实际分布 | 后果 |
| --- | --- | --- |
| **采样率** | G1 全档 **8 kHz**（RealMAN 重采样以降算力）；其余全部 16 kHz | PESQ 有 NB / WB 之别；COVL 的回归域本身就是 8 kHz；DNSMOS 随带宽的偏移未量化 |
| **目标信号** | RealMAN 系 = 直达路径滤波语音；AmbiDrop = 阵前参考麦直达路径；UniArray = **干净混响**；VarArray = 每说话人信号 → ASR | SI-SDR 的「满分位置」不同：−0.81（G1）与 9.4（G2）之间差的是任务难度，不是模型强弱 |
| **指标口径** | SE / SS / CSS 三类任务混排；SI-SDR 绝对值、SI-SDRi 增益、BSS-Eval SDR、WER 四种量并存 | SI-SDR 与 **SI-SDRi** 不可互换（13.46 是增益，DeFTAN-AA 的 9.4 是绝对值、其增益为 17.20 †；换算后排序会反转，见 §2.1.1）；SDR 与 WER 更不可换算 |
| **真实 / 仿真** | 真实录音只有 G1、G1′、G4 与 VarArray（AMI、MS、Aria）；G2、G3 全为仿真 | 仿真集上 SNR 与 T60 全覆盖、可做受控扫描；真实集没有这些自由度，只能报「在什么场景下」 |

**组内真正同条件的三对**（可以逐格比较）：

1. **G1 的 4 行**（含固定阵列上界档）——同表、同数据、同 8 kHz、同 4 s 分段、同评测脚本，是本页唯一严格可控的横评。
2. **REDnet / FlexIO**——REDnet 严格沿用 FlexIO 的实验设置与数据划分。
3. **LABNet / CaSNet**——同属 RealMAN 6 麦固定档，同一套混噪流程。

**两条容易踩的坑**：

- **G1 与 G1′ 的差别不只是麦数**。除「≤4 麦随机 vs 6 麦固定」外，还有 **8 kHz vs 16 kHz** 与「几何泛化 vs 固定几何」两重差异，所以 D 组（清单 §5）的 SI-SDR 4.22 与 A 组的 PESQ 2.34 **完全不能并读**，即使都在 RealMAN 上。
- **AmbiDrop 的 30 dB 只属于 Aria 子集**，不是它仿真实验的混合 SNR；把它当作「AmbiDrop 在 30 dB 下评测」会读错。

**RealMAN 上的三套协议，不能互称“官方”**：

- **官方 Variable-Array 档**（RealMAN 论文 §4.3；仓库 `configs/realman_enh_generalization_16kHz.yaml`）：**16 kHz**、随机子阵训练、固定 **5 麦 {0,1,5,9,13}** 测试。
- **本页 G1**：Geo-DConv 自建协议，**8 kHz**、随机 ≤4 麦训练、1/2/5 麦测试。
- **Uni-ArrayDPS 的 RealMAN**：static 子集自混 **−15~5 dB**，**不是官方 test 混合集**（官方 test 平均 SNR ≈ **−0.8 dB**）。

三者都写 RealMAN，但麦数、采样率、混噪口径都不同；任何「RealMAN SOTA」表述都必须先指明协议，否则会把 4 麦 8 kHz 的 4.22 dB 与官方 5 麦 16 kHz 的基线混为一谈。

**置换等变：声明多、实测无**。Geo-DConv 在正文声明并证明置换等变，UniArray / LABNet 训练时用通道置换，但本页 16 行里没有任何一行报告置换测试的数值——它目前是机制声明，不是可比较的证据。要验证，需固定模型在同一批测试片段上随机置换通道顺序，报告指标均值与方差，而不是只看单次结果。

### 2.3. 固定阵列侧：容量对齐参照

**（a）同表实测**：Geo-DConv Table 1 的 Fixed-Array 档是该论文为固定阵列专门训练的上界，与 Geometry-Invariant 档**同数据、同训练预算、同评测集**，唯一差别是训练时阵列是否可变。这是本库唯一一处干净可控的「容量对齐」实测。

| 参照 | 参数量 | 算力 | SIG | BAK | OVRL | SI-SDR | PESQ |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| SpatialNet（固定阵列上界） | 1.2M | 5.99 G/s | 3.11 | 3.58 | 2.67 | **5.23** | 2.56 |
| ↳ SpatialNet-Geo-DConv（≤4 麦可变） | 1.3M | 6.08 G/s | **3.16** | 3.51 | **2.68** | 4.22 | 2.48 |
| TF-GridNet（固定阵列上界） | 8.2M | 73.03 G/s | 3.13 | 3.63 | 2.71 | **5.29** | **2.72** |
| ↳ TF-GridNet-Geo-DConv（≤4 麦可变） | 8.3M | 73.12 G/s | **3.21** | 3.62 | **2.77** | 3.90 | 2.59 |
| USES2-comp（同为可变麦基线） | 2.5M | 70.26 G/s | 3.02 | 3.50 | 2.56 | 4.17 | 2.52 |
| FaSNet-TAC | 2.7M | 9.76 G/s | 2.48 | 3.18 | 2.05 | −0.81 | 1.74 |
| BSRNN（**单通道**容量锚） | 16.9M | 21.15 G/s | 2.61 | 3.29 | 2.18 | −1.38 | 1.94 |
| No processing | — | — | 1.99 | 1.84 | 1.49 | −9.47 | 1.54 |

（末两行不是固定阵列，放这里是为了给「容量」与「通道数」各一个锚点：16.9M 的单通道 2.18 OVRL，仍低于 1.2M 的 6 麦固定阵列 2.67。）

**（b）其它阵营的容量对齐**（不同论文、各自口径，只能做「同参数档对照」，不能横比）

| 可变/无关方案（参数） | 同档对照（参数） | ΔSI-SDR（绝对值之差） | ΔOVRL | 说明 |
| --- | --- | --- | --- | --- |
| AmbiDrop FT-JNF（0.14M） | 原 FT-JNF（0.14M，同骨干同训练） | seen：5.06 vs 5.93 → **−0.87**<br>unseen：4.77 vs −15.08 → **+19.85** | 未报 | 全库最干净的对照：骨干零改动，只换输入表示 + dropout |
| DeFTAN-AA（2.2M） | GSDB+ST（2.0M，同文、固定 M=4） | 9.4 vs 10.3 → −0.9 | 未报 | 与更小的 DeFTAN-II（0.8M，9.8 dB）比仍低 → 参数买的是跨 M 稳定性 |
| LABNet（0.052M） | EaBNet 1.9M / McNet 2.8M（固定阵列，RealMAN 6 麦） | PESQ 2.34 vs 2.17 / 2.12（**+0.17 / +0.22**） | 未报 | 参数少 36–54 倍仍更高：容量不是瓶颈 |
| SFB-NSE（28.3G FLOPs） | DPRNN+TAC（31.3G，近算力对齐） | PESQ 2.76 vs 2.25 | 未报 | 两条都属「麦数无关」，不是严格固定阵列对照 |
| UniArray（7.20M） | VarArray+CA（7.13M，同参数档） | 13.46 vs 9.28（SI-SDRi）→ **+4.18** | 未报 | 该仿真分离协议**没有固定阵列上界行**，是空白 |
| REDnet / FlexIO | 互为同族对照（均未报参数量） | SDR 22.2 vs 22.3 | 3.15 vs 2.91（1ch） / 3.10 vs 3.05（5ch） | 只能用 OVRL 区分，且 REDnet 参数未知，容量对齐做不了 |

### 2.4. 五条读法

1. **DNSMOS 是这一阵营的系统性空白**。14 个方案、16 行里只有 5 行有 DNSMOS，而且都是「实验里出现了真实录音」的那些（RealMAN、CHiME-4）。纯仿真论文按惯例只报有参考指标——因为仿真集有 clean reference，DNSMOS 在同分布数据上区分度也低。结果是：**想做跨方案横评，第一件事不是找更好的模型，而是统一补跑 DNSMOS**。

2. **容量对齐后，阵列无关的代价几乎全部落在 SI-SDR，听感维度反而略升**。SpatialNet：SI-SDR 绝对值 −1.01 dB，但 SIG +0.05、OVRL +0.01；TF-GridNet：绝对值 −1.39 dB，但 SIG +0.08、OVRL +0.06。这里是**两个系统之间的差**，不是 SI-SDRi（增益相对未处理输入），两者不要混读。合理解释是 SI-SDR 对波形相位与精细结构敏感，而可变通道/坐标条件化损失的正是这部分；谱包络与噪声抑制维持得住，所以 SIG/OVRL 不降。这也说明「阵列无关必然全面掉点」不成立。

3. **容量不是瓶颈，通道数与空间建模方式才是**。52k 的 LABNet 在 RealMAN 6 麦上 PESQ 反超 1.9M 的 EaBNet 与 2.8M 的 McNet；反方向看，16.9M 的 BSRNN 单通道 OVRL 2.18，低于 1.2M 的 6 麦 SpatialNet 2.67。任何「参数量更大所以更强」的推断在这条线上都失效。

4. **参数与算力严重脱钩，只报参数量的表会误导**。SpatialNet-Geo 1.3M / 6.08 G/s 对 USES2-comp 2.5M / 70.26 G/s：参数差 1.9 倍，算力差 11.5 倍，SI-SDR 却 4.22 > 4.17。本页把 MACs 与参数量并列，原因就在这里。

5. **前端训练有三条主要路线，运行时精修是另一条路**：单一阵列训练（DeFTAN-AA、SFB-NSE）——最省数据，但只在特定几何族内成立（UCA / 圆阵）；多几何或随机子阵训练（Geo-DConv、AmbiDrop、UniArray、HyBeam）——泛化来自数据覆盖、规范表示或物理线索分工；真实数据训练（只有 Geo-DConv 与 CaSNet 用 RealMAN 83.7 h 训练，LABNet 的 RealMAN 结果由 CaSNet 重测）。**同时满足「真实数据训练 + 可变麦数 + 报 DNSMOS」的，目前只有 Geo-DConv**。Uni-ArrayDPS 不改前端训练，而在推理时通过 SCM 和 FCP 引入阵列信息；其 training-free 只指精修器不额外训练，前端和干净语音扩散先验仍需分别训练。

### 2.5. 空格与补法

| 缺口 | 为什么空 | 怎么补 |
| --- | --- | --- |
| DNSMOS（AmbiDrop / DeFTAN-AA / SFB-NSE / UniArray / VarArray / LABNet / CaSNet） | 纯仿真实验，作者按有参考指标惯例报 PESQ / SI-SDR / STOI | 在同一批测试音频上补跑 DNSMOS P.835；优先级最高的是 AmbiDrop（有官方 checkpoint，成本最低） |
| SFB-NSE / UniArray / REDnet 参数量 | 原文只给 FLOPs 或 GMACs | 按架构描述复算；REDnet 可从 TF-GridNet 同构配置（D=64、B=4、I=4、J=4、H=256、L=4）估算，属估算值不可当原文引用 |
| DeFTAN-AA / SFB-NSE / UniArray / AmbiDrop 的训练小时数 | 只给仿真生成配置，不给总时长 | 需按配置自行统计；这类行不能参与「数据规模效率」比较 |
| 固定阵列上界（除 Geo-DConv 外全部缺失） | 只有 Geo-DConv 专门训了 Fixed-Array 档作上界 | 其它论文必须自建同数据、同参数档的固定阵列对照，否则「阵列无关的代价」无从量化——这是本页最该补的一列 |
| AmbiDrop 的 DNSMOS 与 RealMAN 结果 | 只在仿真集与 Aria 上评测 | 用官方 checkpoint 在 RealMAN 上跑一次，即可与 G1 组并表 |

## 3. 单目标语音增强（SE）

### 3.1. Geo-DConv：已知坐标、真实录音 SE 的优先验证项

**证据：A（Interspeech 2026，官方日程已列）；文献键 `liu2026geodconv`。** [[方向/AI语音/模型/Geo-DConv|Geo-DConv]] 用麦克风坐标生成动态卷积核，可接入 SpatialNet 或 TF-GridNet；前提是坐标可用，不是无几何信息的方案。

原文 Table 1 的 RealMAN **8 kHz、直接路径目标、Geometry-Invariant** 主表如下。训练使用不超过 4 麦的可变子阵；该表是固定测试几何上的主比较，不应改写成“任意未见拓扑全面获胜”。

| 方法 | 参数 | MACs (G/s) | SDR (dB) | SI-SDR (dB) | PESQ | STOI | OVRL |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| FaSNet-TAC | 2.7M | 9.76 | 5.76 | −0.81 | 1.74 | 0.73 | 2.05 |
| USES2-comp | 2.5M | 70.26 | 8.62 | 4.17 | 2.52 | 0.86 | 2.56 |
| SpatialNet-Geo-DConv | 1.3M | 6.08 | **9.72** | **4.22** | 2.48 | 0.86 | 2.68 |
| TF-GridNet-Geo-DConv | 8.3M | 73.12 | 9.05 | 3.90 | **2.59** | **0.87** | **2.77** |

因此，SpatialNet-Geo-DConv 的优势是 **SDR、SI-SDR、效率和质量的平衡**，不是所有指标都第一；TF-GridNet-Geo-DConv 的 PESQ、STOI、OVRL 更高，但 SI-SDR 反而低于 SpatialNet-Geo 和 USES2-comp。

原文 Table 2 的变麦数及跨数据集结果进一步限定了结论：

| 方法 | 未见 5 麦 SI-SDR (dB) | 未见 5 麦 PESQ | 未见 5 麦 OVRL | CHiME-4 OVRL |
| --- | ---: | ---: | ---: | ---: |
| USES2-comp | **4.91** | 2.60 | 2.59 | 2.55 |
| SpatialNet-Geo-DConv | 4.65 | 2.53 | 2.69 | 2.64 |
| TF-GridNet-Geo-DConv | 4.54 | **2.67** | **2.79** | **2.73** |

- 训练最多见 4 麦时，未见 5 麦的 SI-SDR 由 USES2-comp 领先，不能把 Geo-DConv 写成所有麦数档位都最好。
- Geo 版本的 CHiME-4 OVRL 更高，但这里只有无参考质量指标，不能推出跨数据集所有维度都领先。
- 未检索到官方代码或权重；坐标标定误差也缺少系统消融。它是优先验证候选，不是已经开箱即用的统一冠军。

### 3.2. AmbiDrop：跨几何与坏麦鲁棒性最完整，且有公开实现

**证据：会议版 A，扩展版 B；文献键 `tatarjitzky2026ambidrop`、`tatarjitzky2026ambidrop_ext`。** [[方向/AI语音/模型/AmbiDrop|AmbiDrop]] 将物理阵列经 ASM 编码到**二阶、9 通道 Ambisonics**，训练时以通道 dropout 模拟编码误差。网络输入维度固定，不等于物理麦克风只能有固定数量。

扩展版 Table I 的同骨干对照如下（SI-SDR / PESQ / STOI）：

| 骨干 | 测试阵列 | 原骨干 | 原骨干 + AmbiDrop |
| --- | --- | --- | --- |
| FT-JNF | 训练时见过的几何 | 5.93 / 1.72 / 0.85 | 5.06 / **1.81** / **0.86** |
| IC-ConvTasNet | 训练时见过的几何 | 2.92 / 1.37 / 0.78 | 2.48 / **1.49** / **0.79** |
| FT-JNF | 未见几何 | −15.08 / 1.38 / 0.54 | **4.77 / 1.78 / 0.84** |
| IC-ConvTasNet | 未见几何 | −12.27 / 1.24 / 0.45 | **1.40 / 1.43 / 0.76** |

- **未见几何的收益很强，但不是没有代价**：训练几何上，FT-JNF 加 AmbiDrop 后 SI-SDR 从 5.93 降到 5.06 dB，减少 0.87 dB；IC-ConvTasNet 也略有下降。
- 扩展版覆盖 20 种仿真 7 麦 1D/2D/3D 阵列，并另做 Project Aria 真实录音实验。它比只测少量圆阵的工作更适合支撑“广几何鲁棒性”判断。
- Fig. 7 的文字结果显示，缺 1 麦时基线 SI-SDRi 从约 12 dB 降至约 4 dB；AmbiDrop 到只剩 4 麦时约从 11.5 降至 9.5 dB。这是**坏麦鲁棒性**证据，不是更高固定阵列峰值分数的证明。
- ASM 需要相应的阵列传递函数或校准信息，且受编码阶数、空间采样与传感器误差约束；“阵列无关学习”不等于“推理完全不需要阵列信息”。
- [官方仓库](https://github.com/mikitt012/AmbiDrop)在 2026-10-09 已核到训练/评测管线与检查点；README 提醒复现数值接近但不完全一致。会议版与扩展版的作者名单不同，参考文献中分别著录；扩展版是**投稿 TASLP 的预印本**。

### 3.3. DeFTAN-AA：单一阵列训练后的跨形状、跨麦数稳定候选

**证据：A；文献键 `lee2024deftan`。** [[方向/AI语音/模型/DeFTAN-AA|DeFTAN-AA]] 只用一个 4 麦圆阵训练，再测试未见形状和 3/4/8 麦，适合研究“不堆多几何训练集”的泛化。

- 固定 4 麦参考圆阵上，DeFTAN-AA 的 SI-SDR 为 **9.4 dB**，低于 GSDB+ST 的 **10.3 dB**；说明它用峰值性能换取泛化，而非固定阵列冠军。
- 不同未见几何下，3 麦为 **8.1–8.5 dB**，4 麦为 **9.0–9.4 dB**，8 麦为 **9.4–9.7 dB**。
- 配置为 2.2M 参数、35.7G MAC/s；非因果。真实录音只有两种阵列、一个房间、100 条，证据规模有限。

### 3.4. SFB-NSE：限定 UCA 协议的主表领先者

**证据：B；文献键 `zheng2025sfb`。** [[方向/AI语音/模型/SFB-NSE|SFB-NSE]] 用固定空间滤波器组替代逐通道 TAC。训练只见 5 麦、半径 0.5 cm 的 UCA，测试未见 7/9 麦、半径 1/1.5 cm 的 UCA；全部是 VoiceBank+DEMAND 仿真。

| 方法 | FLOPS | PESQ | CSIG | CBAK | COVL | STOI |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| DPRNN+TAC | 31.3G | 2.25 | 4.09 | 3.06 | 3.23 | 0.914 |
| TSCBM+select | 28.3G | 2.50 | 4.02 | 3.21 | 3.32 | 0.934 |
| DPRNN+FB | 2.77G | 2.25 | 4.15 | 2.98 | 3.26 | 0.911 |
| TSCBM+FB | 28.3G | **2.76** | **4.36** | **3.30** | **3.64** | **0.947** |

TSCBM+FB 是该主表的领先者，DPRNN+FB 则是更轻量的前端替换证据。**不能外推为任意几何 SOTA**：训练与测试仍同属 UCA，滤波器需要随新几何重算，且没有真实录音或官方代码；正式发表状态未确认。

### 3.5. MSEN：值得跟踪，但暂不进入定量主表

**证据：A（出版）＋C（本次只取得摘要）；文献键 `zhang2026msen`。** [[方向/AI语音/模型/MSEN（特征束多阶编码器）|MSEN]] 是 ICASSP 2026 的 eigenbeam 多阶编码工作，摘要声称在随机平面阵列上改善 PESQ、CSIG、CBAK、COVL、STOI 并降低算力。

本次 IEEE 页面无法提取全文，公开 PDF 请求返回 418，尚未核到结果表。因此**不填具体分数、不据此宣布定量 SOTA**；应在取得正式全文后补基线、数据、阵列范围、参数量与 MACs。

### 3.6. HyBeam：穿戴混合线索，主表唯一的 mic × beamformer 机制

**证据：B（[arXiv:2510.22637](https://arxiv.org/abs/2510.22637) v1，2025-10-26；未见正式发表信息）；文献键 `barilan2025hybeam`。** [[方向/AI语音/模型/HyBeam]] 按频带混合两类线索：低频用 raw microphone signals，高频并入 beamformer 输出；实验是 4 麦眼镜框阵、11 种阵列（8 个训练、留出 0c / 1 / 4）。

- 实验 2（seen / unseen）：STOI **0.82 / 0.82**、PESQ 1.63 / **1.65**、SI-SDR 1.0 / **1.1 dB**——换几何不退化，是 G2 里最直接的穿戴阵列证据。
- 实验 1（仅标称阵训练）：mic-only 在标称 / 小扰动占优（STOI 0.82 / PESQ 1.56 / SI-SDR 1.1 dB），大扰动塌缩（0.60 / 1.19 / −8.2 dB）；beamformer-only 更稳（0.70 / 1.27 / −4.5 dB）——这正是 hybrid 的动机。
- 频带分析：1 kHz 以下 mic 线索占优、1–4 kHz beamformer 线索占优；4–8 kHz 所有模型都未超带噪输入。
- **限制**：论文没有报未处理输入的 SI-SDR，所以 A 表增益列只能留「—」、不能算 †；全部为仿真（WSJ0 + 镜像法），未报参数量 / 算力 / RTF；麦数固定 4，变化的是几何与偏航。
- 与 AmbiDrop 的分工：AmbiDrop 把阵列压进 Ambisonics 规范域（靠表示），HyBeam 保留原始通道并显式构造波束输出（靠物理线索分工）——两条路线在「谁承担几何」上正好相反。

## 4. 语音分离与柔性输入输出

### 4.1. UniArray：仿真 WSJ0-2mix 的 AGA-SS 强数值候选

**证据：A（IEEE SPL 2025；实验表取 arXiv v1）；文献键 `chen2025uniarray`。** [[方向/AI语音/模型/UniArray|UniArray]] 以虚拟麦克风估计统一通道维度，再融合谱与空间特征；任务是**双人分离**，不是单目标 SE。

训练为 8 麦、半径 5 cm 圆阵的空间化 WSJ0-2mix。Table II 在 10 种未见几何上的结果为：

| 方法 | 未见几何平均 SI-SDRi (dB) | 参数 | MACs (G/s) |
| --- | ---: | ---: | ---: |
| FasNet-TAC | 9.66 | 2.76M | 18.17 |
| VarArray | 9.41 | 2.77M | **0.75** |
| VarArray+CA | 9.28 | 7.13M | 1.84 |
| SDNet | 10.83 | **0.89M** | 22.56 |
| UniArray | **13.46** | 7.20M | 12.96 |

UniArray 比 SDNet 高 **2.63 dB**，MACs 更低，但参数为 7.20M 对 0.89M；VarArray 的 MACs 又低得多。故应称为“该仿真协议的强数值候选”，不能称为真实录音 SE 冠军。原文未见官方代码，且结果不覆盖真实多人会议。

### 4.2. REDnet：可变麦数与未知人数结合得最直接

**证据：B；文献键 `wu2026rednet`。** [[方向/AI语音/模型/REDnet|REDnet]] 用递归编码器逐麦累积，用递归解码器检测并逐一分离说话人。与 [[方向/AI语音/模型/FlexIO|FlexIO]] 不同，它不把输出人数作为外部 prompt 的必需输入。

| 方法 | CHiME-4 仿真 1×5 SDR (dB) | 同条件 PESQ | 真实 1 麦 DNSMOS | 真实 5 麦 DNSMOS |
| --- | ---: | ---: | ---: | ---: |
| FlexIO | **22.3** | 2.96 | 2.91 | 3.05 |
| REDnet | 22.2 | **3.30** | **3.15** | **3.10** |

- 前两项来自 REDnet Table 7，后两项来自 Table 9；1×5 表示 1 个说话人、5 个麦克风。REDnet 并非全指标领先。
- Table 9 中 FlexIO 的真实 1/5 麦 DNSMOS 正确配对为 **2.91 / 3.05**，不是 3.08 / 3.05；本库 REDnet 对象页已同步修正。
- REDnet 的未见几何证据只在 **REnet 子模块**的 TAC-ad-hoc → fixed-array 实验，整机缺少独立几何泛化消融。
- 真实录音仅 CHiME-4 单说话人条件，缺真实多说话人、整机 RTF、代码和权重。2026-08-25 的 v1 标记为 **in submission**，不能写成已接收。

### 4.3. FlexIO：输出人数可外部给定时，统一接口更直接

**证据：A；文献键 `masuyama2026flexio`。** FlexIO 在单一模型中覆盖 1–5 麦、1–3 人，训练/测试刻意留出 3 麦或 5 麦等未见档位。它的关键价值是统一增强与分离接口，不是自动说话人计数。

真实 CHiME-4 的 1/5 麦 WER 为 **6.8% / 4.5%**，mask-MVDR 为 **6.7% / 4.5%**：FlexIO 与经典链相当，而不是真实 WER 领先。论文未给官方模型代码，也未验证真实多说话人、超过 5 麦或超过 3 人的条件。

### 4.4. VarArray：CSS 谱系基线，不是当前统一冠军

**证据：A；文献键 `yoshioka2022vararray`。** [[方向/AI语音/模型/VarArray|VarArray]] 以置换无关特征和 TAC 实现可变麦数 CSS，AMI-dev 的 8/4 麦 WER 分别为 **17.7% / 18.5%**。其终点是会议转写，且固定双输出流；另一组 MS 数据是微软内部集。适合作为谱系与效率基线，不能与 UniArray 的 SI-SDRi 直接排名。

### 4.5. Uni-ArrayDPS：已有强前端时的离线生成式精修候选

**证据：B（arXiv v1）；文献键 `xu2026uniarraydps`。** [[方向/AI语音/模型/Uni-ArrayDPS|Uni-ArrayDPS]] 将 [[方向/AI语音/模型/ArrayDPS-Refine|ArrayDPS-Refine]] 从单人增强扩展到增强与双人分离。它用原始多通道混合和判别式前端输出估计噪声空间协方差（SCM），再用干净语音扩散先验进行后验采样；阵列信息通过 SCM 与 FCP 回投影进入，而不是作为单通道扩散先验的网络输入。

**DPS 家族的四代谱系**（本页只收后两代，前两代是它们的直接前提）：

| 代际 | 方法 | 任务 | 阵列怎么进 | 证据 |
| --- | --- | --- | --- | --- |
| 2025 | [[方向/AI语音/模型/ArrayDPS]]（ICML 2025） | 无监督盲分离 | 逐源估 ATF，白噪声假设 | A |
| 2026-03 | [[方向/AI语音/模型/ArrayDPS-Refine]] | 多通道 SE 精修 | 噪声 SCM 似然 | B |
| 2026-03 | [[方向/AI语音/模型/Uni-ArrayDPS]] | SE + SS 统一 | 同上 + 判别/生成插值 | B |
| 2026-10 | [[方向/AI语音/模型/VM-ArrayDPS]] | 无监督盲分离 | IVA 虚拟麦 + 一致性约束 | B |

四代共享同一前提——预训练干净语音扩散先验 + 一个判别式（或 IVA）估计；差别只在**观测算子怎么估**（ATF / SCM / 虚拟麦）与任务覆盖。这也是它们都不需要按阵列训练的原因。

它是**后端 refiner，不是独立阵列前端，也不是无监督 BSS**。training-free 只表示精修器不针对新前端、任务或阵列额外训练；系统仍需要训练好的判别式前端，以及用约 220 小时 DNS-Challenge 干净语音训练的单通道扩散先验。与 §5.3 的 VM-ArrayDPS 不能直接混排。

RealMAN Table II 的同前端对照如下，均为默认 $\xi=0.4$、$\alpha=0.5$、$T'=300$，未处理输入 SI-SDR 为 −6.10 dB；4/8 麦共用扩散先验：

| 指标 | USES2，4 麦 | 精修后，4 麦 | USES2，8 麦 | 精修后，8 麦 |
| --- | ---: | ---: | ---: | ---: |
| SI-SDR (dB) | 1.09 | **1.30** | 2.20 | **2.40** |
| WB-PESQ | 2.09 | **2.14** | 2.19 | **2.24** |
| CER (%) ↓ | 40.2 | **39.3** | 35.6 | **35.5** |
| DNSMOS | 2.69 | **2.73** | 2.71 | **2.74** |
| UTMOSv2 | 2.71 | **2.76** | 2.78 | **2.80** |

- **提升应相对同一前端计算**：SI-SDR 只增加 0.21 / 0.20 dB；A 表相对 noisy 的 7.40 / 8.50 dB † 包含 USES2 前端本身的贡献，不能全部归给扩散精修。
- **证据覆盖前后端与两类任务**：原文另测 TADRN、FaSNet-TAC 和固定阵列 SpatialNet，覆盖仿真增强与双人分离。RealMAN 是静态说话人、前 4/8 麦的真实录音跨域测试，前端与先验均未用 RealMAN 训练；真实多人分离仍未验证。
- **不是完整的未见几何或坏麦证据**：仿真使用逐样本随机布放的阵列，RealMAN 只取前 4/8 麦；没有系统的线阵/圆阵拓扑留出、通道失效或 2–3 麦测试，也未与 Geo-DConv 的 RealMAN 协议对齐。
- **自然度与内容保持要一起看**：输出还需 FCP 对齐，并与判别式结果插值；$\xi$ 控制观测约束与感知质量的取舍。仅看 DNSMOS 或 UTMOSv2 会漏掉内容失真与幻觉风险，应同时报告 CER/WER、SI-SDR 和必要的人工听测。
- **只定位离线**：默认从 $T'=300$ 起步，论文扫描到 400；还需前端推理与逐采样步的 FCP，未报整机 RTF、显存和总参数。官方目前只有 [demo 页](https://xzwy.github.io/Uni-ArrayDPS/)，未提供完整模型代码，不能当作开箱即用方案。

## 5. 相邻任务的代表性候选

### 5.1. DOA 引导 TSE：GC-SSF

**证据：B；文献键 `li2026gcssf`。** GC-SSF 将麦克风位置和目标 DOA 联合编码，经 FiLM 调制空间选择性滤波器。实验是 **WSJ0 仿真、固定 4 麦、DOA 引导 TSE**，不支持可变麦数。

Table 2 的平均 PESQ：

| 方法 | 训练几何 | Circ 测试 | ULA 测试 | Random 测试 |
| --- | --- | ---: | ---: | ---: |
| SSF-Circ | Circ | **2.95** | 1.16 | 1.20 |
| SSF-Random | Random | 2.04 | 2.02 | 1.93 |
| GC-SSF | Random | 2.53 | **2.41** | **2.46** |

GC-SSF 的跨几何结果更强，但匹配 Circ 的 SSF-Circ 仍是 2.95。它证明的是几何条件化的迁移收益，不是取代匹配阵列上界；原文未给代码链接。

### 5.2. Ambisonics 编码：ADEPS

**证据：B；文献键 `milstein2026adeps`。** [[方向/AI语音/模型/ADEPS|ADEPS]] 用扩散后验采样和阵列物理采集算子做零样本编码，**不是语音增强**。

Table 2 的全阶声场设置（$N_{eff}=15$、先验 $N_p=5$）中，随机 4/5/6 麦阵列的 SI-SDR：

| 方法 | 4 麦 | 5 麦 | 6 麦 |
| --- | ---: | ---: | ---: |
| Linear | 6.71 | 7.82 | 9.09 |
| ADEPS | **9.85** | **10.57** | **12.67** |

但同样三档的相干性，Linear 为 **0.82 / 0.82 / 0.83**，ADEPS 为 **0.74 / 0.76 / 0.80**，并非所有空间指标更好。Table 3 的固定 4 麦上，阵列特定 Diff-Enc 的 SI-SDR **9.52** 也高于 ADEPS 的 **9.23**。

必须保留两个口径限制：原文写明系数**评估至 $N_{enc}=1$**，不能把这些数解释为完整 5 阶重建的全面领先；推理还需 150 步反向采样和 30.8M 参数，未给 RTF。[官方仓库](https://github.com/Amitmils/ADEUPS)仍标记 work in progress / full code will be released，不能当作完整开源实现。

### 5.3. 无监督 BSS：VM-ArrayDPS

**证据：B；文献键 `sun2026vmarraydps`。** [[方向/AI语音/模型/VM-ArrayDPS|VM-ArrayDPS]] 将 IVA 输出作为虚拟麦克风，加入扩散后验采样的多通道一致性约束。它解决的是**无监督盲分离**，不是干净目标 SE，也没有给出系统的未见几何扫描。

3 麦、2 人、8 kHz SMS-WSJ 的 Table 1：

| 选择策略 | 方法 | SDR (dB) | SI-SDR (dB) | PESQ | eSTOI |
| --- | --- | ---: | ---: | ---: | ---: |
| 非 oracle ML | ArrayDPS | 16.9 | 16.2 | 3.49 | 0.883 |
| 非 oracle ML | VM-ArrayDPS | **17.7** | **17.0** | **3.53** | **0.894** |
| oracle Max | VM-ArrayDPS | 17.9 | 17.2 | 3.56 | 0.898 |

ML 按似然选样本，适合作为非 oracle 口径；Max 按 SI-SDR 选样本，需要目标参考，不能拿最高分冒充部署结果。该工作仅仿真、投稿 ICASSP 2027 尚在评审，且没有自身完整代码仓库。

### 5.4. 生成式 MIMO（边界对照）：mSGMSE

**证据：A（ICASSPW 2024，pp. 455–459）；文献键 `kimura2024msgmse`；本页不填定量格。** [[方向/AI语音/模型/mSGMSE]] 用条件扩散**联合生成所有通道**，天生保 ITD/ILD，并给出未知几何的适配技术；REVERB real（含训练未见几何）上仍提升 ASR。

- **它不是 array-agnostic**：通道数固定，几何适配只是鲁棒性，因此不进 §2 的 A 表。
- 与 Uni-ArrayDPS 正好互补：mSGMSE 让生成模型**自己生成空间线索**（MIMO 联合分布），Uni-ArrayDPS 让生成模型只做**单通道先验 + SCM 观测约束**。两者代表「生成式要不要自己生成空间」的两端，可作 §4.5 的对照。
- 成本口径要小心：NTT demo 的 mSGMSE+Ensemble 报 RTF **7.87**（SI-SDR 8.1 / PESQ 2.58 / ESTOI 0.86），是 ensemble 变体、不是常规成本；主论文数值表本页未核。

## 6. 按场景选型

| 场景 | 首选验证对象 | 选择理由与前置条件 |
| --- | --- | --- |
| 已知麦克风坐标、RealMAN 类真实录音 SE | [[方向/AI语音/模型/Geo-DConv]] | 主表 SDR/SI-SDR 与效率突出；接受无官方代码、需要标定，分指标看结果 |
| 多设备/不规则阵列、可能坏麦、希望尽快跑通 | [[方向/AI语音/模型/AmbiDrop]] | 广几何和坏麦证据较完整，有代码/检查点；需要 ASM 所需阵列信息，峰值并非总更高 |
| 穿戴设备（眼镜 / 耳机）、几何随佩戴变化 | [[方向/AI语音/模型/HyBeam]] | 低频 mic + 高频 beamformer，seen/unseen 无退化；仅仿真、无 noisy 行、麦数固定 4 |
| 只有一种阵列训练数据，测试形状与麦数会变 | [[方向/AI语音/模型/DeFTAN-AA]] | 跨形状、3/4/8 麦稳定性；非因果且真实验证规模小 |
| 明确限定紧凑 UCA、希望替换 TAC 前端 | [[方向/AI语音/模型/SFB-NSE]] | 滤波器组有主表和效率证据；不可外推到任意拓扑 |
| 仿真双人分离、追求未见几何 SI-SDRi | [[方向/AI语音/模型/UniArray]] | Table II 强数值；参数不小，缺真实数据和官方代码 |
| 麦数可变，说话人数未知且需自动估计 | [[方向/AI语音/模型/REDnet]] | 双可变接口最直接；投稿中，整机几何与真实多人证据不足 |
| 麦数和输出人数可变，但人数可由外部给定 | [[方向/AI语音/模型/FlexIO]] | 增强/分离统一接口，真实 WER 与 mask-MVDR 相当；无官方模型代码 |
| 已有强前端、允许离线精修以增强自然度与识别率 | [[方向/AI语音/模型/Uni-ArrayDPS]] | 与同一前端成对比较有稳定增益；需扩散先验，采样昂贵，无完整代码，不替代阵列前端 |
| 已知目标 DOA、固定麦数的跨几何提取 | GC-SSF | 跨形状 PESQ 更强；不是可变麦数或通用 SE |
| 离线、任意阵列到 Ambisonics 的编码 | [[方向/AI语音/模型/ADEPS]] | 零样本编码 SI-SDR 较强；注意评估阶数、空间相干性和采样成本 |
| 无配对目标、少麦盲分离 | [[方向/AI语音/模型/VM-ArrayDPS]] | 相对 ArrayDPS 的同协议增益；仅仿真，使用非 oracle 结果 |

MSEN 暂列“取得全文后再评估”，而不是凭摘要挤入上述定量首选。

## 7. 建议的统一横评协议

现状对照：本页各行的测试条件（测试阵列、SNR、混响、采样率、任务与目标信号）已逐条列在 §2.2，下面 8 条即针对那四轴断裂提出的收敛方案。

1. **任务与目标先锁死**：SE、SS/CSS、TSE、编码、BSS 分表；固定采样率、目标信号、参考通道、训练数据和调参预算。SI-SDR 绝对值与 SI-SDRi 增益分列报告，并同时给出未处理输入的 SI-SDR（否则增益无法换算，见 §2.1.1）。
2. **阵列拆分按几何而非只按麦数**：至少包含 seen geometry / seen $M$、seen geometry / unseen $M$、unseen shape / seen $M$、unseen shape / unseen $M$；几何按完整拓扑留出，而非把随机子阵都当成未见几何。
3. **分别测试扰动轴**：通道置换、坐标/ATF 误差、坏麦、孔径变化、1D/2D/3D、同步误差。坏麦测试同时报告剩余麦数与空间采样条件。
4. **人数口径单列**：已知人数 prompt、自动估计人数、oracle 人数不能混排；固定双输出流与可变输出流也不直接等价。
5. **保留两类参照**：固定阵列专属模型作性能上界参照，mask-MVDR 等可解释链作工程下界/基线；AmbiDrop、Geo-DConv、UniArray 等统一训练档后再比较。精修器必须保留同前端未精修行，分开报告相对 noisy 与相对前端的增益，并固定先验、采样预算和插值系数；成本同时包含前端和精修器。
6. **仿真与真实都测**：至少一个真实多阵列集和一个真实多说话人集；CHiME-4 的单人真实结果不能替代真实多人会议。
7. **质量、内容、空间、效率一起报**：SI-SDR(i)/SDR、PESQ、STOI/eSTOI、DNSMOS，固定识别器的 WER；需要空间输出时报告 ILD/IC 等空间保真。参数、MACs、RTF、延迟、显存均包含 ASM/动态核/编码器等前端开销。
8. **给不确定性**：多个训练种子，按语句 bootstrap 置信区间，预先固定模型选择规则；oracle Max 与非 oracle ML 分开。当前文献结果不足以支持跨方法统计显著性声明。

## 8. 研究空白与复现优先级

- **当前没有同条件、全任务的统一横评**：本页只能给分协议候选，不能把 RealMAN、WSJ0-2mix、CHiME-4、VoiceBank+DEMAND 的数值排成一列。
- **真实多说话人＋未见几何仍是薄弱点**：REDnet 的真实证据是单人 CHiME-4，UniArray、GC-SSF、VM-ArrayDPS 主要是仿真；Uni-ArrayDPS 的真实集也只测单人 SE。
- **峰值与鲁棒性要同时呈现**：AmbiDrop 在训练几何上的 SI-SDR 略降，GC-SSF 不如匹配 Circ 的 SSF，Geo-DConv 在未见 5 麦 SI-SDR 上不如 USES2-comp。
- **实时性证据不足**：DeFTAN-AA 非因果；ADEPS、VM-ArrayDPS、Uni-ArrayDPS 是多步扩散；REDnet 缺整机 RTF。不能用 MACs 单独推断端到端实时可用。
- **标定误差没有系统消融**：Geo-DConv 依赖麦克风坐标，AmbiDrop 依赖 ASM 的 ATF / 校准；两者都没有报告坐标误差或 ATF 失配的敏感性曲线。对「阵列无关」阵营，这比再刷 0.1 dB 更值得补——坐标错 1 cm 会不会把 4.22 dB 打回 USES2 的 4.17，目前没人知道。
- **复现顺序**：若目标是 SE，先跑公开 AmbiDrop，再实现 Geo-DConv，并以 USES2-comp / 固定阵列骨干作同数据对照；若目标是多人接口，按人数是否已知选择 REDnet 或 FlexIO；若目标是仿真 AGA-SS，再实现 UniArray 与 SDNet/VarArray 基线。已有强前端且研究离线精修时，再实现 Uni-ArrayDPS，先固定前端复现 Table II 的同条件对照。
- **待补证据**：MSEN 正式全文与结果表、Geo-DConv 官方实现、REDnet 整机几何消融和真实多人测试、ADEPS 完整代码、Uni-ArrayDPS 完整实现与整机 RTF、HyBeam 的 noisy 行与参数/算力、mSGMSE 主论文数值表，以及统一置信区间与置换测试。
- **跟踪**：Virtual-Flow（NeurIPS 2026，*Virtual Microphone-based Speech Enhancement via Unsupervised Flow Matching*）目前只有收录页与题名，未核全文；若属实，属「虚拟麦前端 + 生成」一类，应与 VM-ArrayDPS 一起看。

## 9. 来源日志

下表记录本页实际采用的来源和证据边界；完整 BibTeX 字段以同目录 `references.bib` 为准。

| 文献键 | 来源与状态 | 本页采用内容与访问限制 |
| --- | --- | --- |
| `liu2026geodconv` | [Geo-DConv 原文](https://arxiv.org/abs/2607.18658)；Interspeech 2026，[官方日程](https://www.isca-archive.org/interspeech_2026/booklet.pdf)已列 | 全文 Table 1/2；真实 RealMAN、CHiME-4 跨数据集；未见官方代码。Table 1 的 Fixed-Array 上界档与 SIG/BAK/PESQ 于 2026-10-28 补核（§2.3a 来源） |
| `tatarjitzky2026ambidrop` | [会议版 arXiv](https://arxiv.org/abs/2509.14855)；[正式 DOI](https://doi.org/10.1109/ICASSP55912.2026.11462120) | ICASSP 2026，pp. 14732–14736；作者为 Michael Tatarjitzky、Boaz Rafaely，与扩展版分开著录 |
| `tatarjitzky2026ambidrop_ext` | [扩展版 arXiv](https://arxiv.org/abs/2607.00548)；投稿 TASLP 的预印本 | 全文 Table I、Fig. 7；20 个仿真阵列和 Aria；[代码/检查点](https://github.com/mikitt012/AmbiDrop)于 2026-10-09 核验 |
| `chen2025uniarray` | [UniArray arXiv](https://arxiv.org/abs/2503.05110)；[正式 DOI](https://doi.org/10.1109/LSP.2025.3562949) | IEEE Signal Processing Letters 32 卷，2025，pp. 2164–2168；实验表取 arXiv v1 Table II；仿真双人 AGA-SS；未见官方代码 |
| `wu2026rednet` | [REDnet arXiv](https://arxiv.org/abs/2608.24659)；v1，in submission | 全文 Table 7/9；REnet 子模块与整机证据不可混同；无代码链接 |
| `masuyama2026flexio` | [FlexIO arXiv](https://arxiv.org/abs/2510.21485)；[MERL 正式记录](https://www.merl.com/publications/TR2026-034)；[DOI](https://doi.org/10.1109/ICASSP55912.2026.11462393) | ICASSP 2026；Table 3–5 与真实 WER；无官方模型代码 |
| `lee2024deftan` | [DeFTAN-AA 官方论文页](https://www.isca-archive.org/interspeech_2024/lee24g_interspeech.html) | Interspeech 2024；Table 1/2 与真实实验；非因果 |
| `zheng2025sfb` | [SFB-NSE arXiv](https://arxiv.org/abs/2504.01392)；预印本 | 全文 Table I；仅 UCA 仿真；正式发表状态未确认，无代码 |
| `zhang2026msen` | [MSEN IEEE 页](https://doi.org/10.1109/ICASSP55912.2026.11464064) | ICASSP 2026；本次仅摘要级，PDF 请求 418，故不列定量结果 |
| `li2026gcssf` | [GC-SSF arXiv](https://arxiv.org/abs/2605.18442)；预印本 | 全文 Table 2；固定 4 麦 DOA-TSE；无代码链接 |
| `milstein2026adeps` | [ADEPS arXiv](https://arxiv.org/abs/2608.24558)；v3 预印本 | 全文 Table 2/3；编码而非 SE；[官方仓库](https://github.com/Amitmils/ADEUPS)仍为 WIP |
| `xu2026uniarraydps` | [Uni-ArrayDPS arXiv v1](https://arxiv.org/abs/2603.24810)；预印本，未核到正式发表信息 | 2026-10-28 复核全文 Table I–III；采用 RealMAN Table II 的同 USES2 前端 4/8 麦默认精修结果；覆盖仿真 SE/SS 与真实 SE；只有 demo，无完整代码 |
| `sun2026vmarraydps` | [VM-ArrayDPS arXiv](https://arxiv.org/abs/2610.09334)；投稿 ICASSP 2027 | 全文 Table 1；ML 与 oracle Max 分开；仅仿真，无自身完整代码 |
| `barilan2025hybeam` | [HyBeam arXiv](https://arxiv.org/abs/2510.22637)；v1 2025-10-26，未见正式发表信息 | 全文 §V 实验 1/2；穿戴 4 麦 11 阵；无 noisy 行、无参数量/算力；仅仿真 |
| `kimura2024msgmse` | [IEEE 10626291](https://ieeexplore.ieee.org/document/10626291)；ICASSPW 2024，pp. 455–459 | 仅作边界对照，未核对定量表；RTF 7.87 来自 NTT demo 的 Ensemble 变体 |
| `yang2024realman` | [RealMAN arXiv](https://arxiv.org/abs/2406.19959)；NeurIPS 2024 Datasets and Benchmarks | 官方 Variable-Array 协议、16 kHz、5 麦 {0,1,5,9,13}；test 平均 SNR ≈ −0.8 dB |
| `yoshioka2022vararray` | [VarArray arXiv](https://arxiv.org/abs/2110.05745)；[正式 DOI](https://doi.org/10.1109/ICASSP43922.2022.9746876) | ICASSP 2022，pp. 6027–6031；CSS/WER 基线，固定双输出流 |

主体网页与元数据于 2026-10-27 核验；2026-10-28 补核 Geo-DConv 固定阵列对照，并回补 Uni-ArrayDPS 全文及结果表；同日补入 HyBeam 主表行、mSGMSE 边界对照与 RealMAN 三套协议说明。个别仓库可用性采用表中注明的较早核验日期。没有为缺失 DOI 的预印本补写虚构 DOI。

## 10. 相关阅读

- [[方向/AI语音/知识/技术路线/Array-Agnostic SE（阵列无关语音增强）|Array-Agnostic SE 技术路线]]：术语、机制谱系与研究价值。
- [[方向/AI语音/知识/技术路线/阵列可变方案技术路线概览图|阵列可变方案技术路线概览图]]：一页式路线结构。
- [[方向/AI语音/知识/技术路线/阵列可变技术路线热度趋势图|阵列可变技术路线热度趋势图]]：按首次公开年份的文献数量趋势，不代表性能排行榜。
- [[方向/AI语音/知识/调研与地图/SE SOTA（语音增强模型表现）|通用 SE SOTA]]：固定阵列和通用语音增强榜单；与本页的阵列泛化口径互补。
- [[方向/AI语音/知识/调研与地图/Array SE SOTA（阵列语音增强SOTA调研）|阵列语音增强SOTA总览]]：固定几何、真实录音/挑战赛、阵列 TSE 与生成式精修的总览；本页是它的阵列无关分册，固定阵列上界与「1 dB 代价」在那页有同表对照。
- [[方向/AI语音/知识/调研与地图/Array Speech Enhancement Survey Report（阵列语音增强技术调研报告）|阵列语音增强技术调研报告]]：综合技术背景。
- [[方向/AI语音/知识/调研与地图/Array-Agnostic SE Industry（工业界阵列可变语音增强调研）|工业界阵列可变语音增强调研]]：微软 / 亚马逊 / USTC 等工业侧链条与部署约束（异步、带宽、WER 口径）。

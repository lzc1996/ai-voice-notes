---
title: C2D Projection（近讲麦到远场投影）
类型: 模型
发表时间: 2026-06
时间依据: arXiv 首次提交日（v1 2026-06-11）；ICASSP 2026 接收（Barcelona，4–8 May 2026，pp. 18912–18916）
任务:
  - 语音增强
  - 多通道增强
  - ASR
方法范式:
  - 经典-神经混合
开放状态:
  - paper
aliases:
  - C2D projection
  - C2D Projection
  - Close-to-Distant Microphone Projection
  - Close-to-Distant microphone Projection (C2D projection)
  - 近讲麦到远场投影
  - 近讲麦到远场麦投影
tags:
  - 类型/对象
  - 方向/AI语音
  - 任务/多通道增强
  - 任务/ASR
  - 主题/真实数据
  - 主题/信号处理
  - 主题/数据处理
---

# C2D Projection（近讲麦到远场投影）

## 0. 背景

**问题现场**：真实录音训练多通道语音增强缺乏训练目标——仿真数据与真实声学失配，而直接拿近讲麦（CM）当目标在多源场景被实验证否（CHiME6 上 CM training 的 tcpWER 高出一个量级）。

**C2D Projection 的切入点**：训练期用同时录到的 CM 与 DM 估计跨域投影矩阵（PMWF 的跨域变体，分子换成跨域互协方差），把 CM 投影成 DM 处的源像作监督；测试期只需 DM 观测与 GSS/PMWF 辅助输入。

## 1. 身份

`C2D projection`（Close-to-Distant microphone Projection，近讲麦到远场麦投影）是 [[方向/AI语音/团队/NTT Speech Group（NTT 语音组）|NTT]]（Tomohiro Nakatani、Rintaro Ikeshita、Naoyuki Kamo、Marc Delcroix、Shoko Araki）提出的**真实录音训练目标生成方法**（ICASSP 2026，arXiv:2606.13109，2026-06）。

它的分歧点在标签来源：不靠仿真数据，而是在训练期用同时录到的近讲麦（CM）与远场麦（DM）估一个**跨域投影矩阵**（PMWF 的跨域变体，掩码在 CM 上估），把 CM 投影成 **DM 处的源像**，与 DM 观测配成一对做普通监督学习（机制见「核心机制」）。

边界：不是新 SE 网络（增强器复用 PDRE 的简化版 DRE + mNCSN++ 骨干），不是测试期前端（CM 与 oracle diarization 只在训练期），不是 DM 阵列上的波束形成权重（$M_c \times M_d$ 的跨域映射）；目标不是无混响干净语音，而是带 DM 域 ATF/混响与相位、功率标度的源像；GSS/PMWF 输出只作辅助输入、不是训练标签。与 [[方向/AI语音/模型/Mixture to Beamformed Mixture（波束形成混合弱监督）|M2BM]] 的逐项对比见 §8：M2BM 把空间滤波的产物当弱标签，C2D 是把 CM 跨域重构成 DM 参考。假设前提与风险见 §6；严格任务是真实录音上的**多通道语音增强**（非分离），实验数据为 CHiME6（训练、dev/eval）与 CHiME8 eval。

## 2. 核心机制

```text
训练期（CM + DM + oracle diarization 都可用：CHiME6 训练集，8 路佩戴 CM + 24 路阵列 DM）
  -> 对 CM、DM 分别做 WPE 去混响
  -> 用 oracle diarization 切出目标说话人的片段
  -> 在 CM 上跑 GSS（cACGMM + 标签引导），得目标说话人的 TF mask φ̂_n(t,f)
  -> 用该 mask 在 CM 域估 Φ_n^{cc}（目标源 SCM）、Φ_v^{cc}（其他说话人+噪声 SCM），
     并用 CM×DM 观测估跨域互协方差 Φ_n^{cd}
  -> W_n(f) = (Φ_n^{cc} + μ Φ_v^{cc})^{-1} Φ_n^{cd}；rank-1 时化为 PMWF 变体（分母 μ + tr{Φ_v^{-1}Φ_n^{cc}}）
  -> x̂_n^d(t,f) = W_n(f)^H x_c(t,f)      ← 远场干净参考（DM 域源像估计）
  -> 与 DM 观测 x_d 组成 (distorted, reference) 对

测试期（只有 DM）
  DM 观测 + GSS/PMWF 输出（辅助输入，各取按 SNR 选出的 M=4 通道）
  -> DRE（mNCSN++ 递归增强，MIMO 4 通道输出）
  -> 网络输出之后再做 post-filtering（post-masking + BAN）
```

### 2.1. 投影矩阵是 PMWF 的跨域变体

- 判据：最小化"CM 经 $W_n$ 变换后与 DM 源像的投影误差" + $\mu \times$"变换后残留的无关信号功率"（式 (5)）。无关信号 $v_n^c$ = 其他说话人在 CM 上的源像 + CM 上的加性噪声（式 (6)）。
- 论文明确说这个代价函数**与 SDW-MWF 等价，只是观测域与目标域不同**（CM 域 vs DM 域）；闭式解为式 (7)。
- 在 $\Phi_n^{cc}$、$\Phi_n^{cd}$ 近似 rank-1 的假设下化简为式 (11)：**形状上就是 PMWF，唯一差别是分子里的目标 SCM 被换成了跨域互协方差 $\Phi_n^{cd}$**——正是这个替换让算子从"CM 域内的滤波"变成"CM→DM 的投影"。
- $\mu$ 控制"投影误差"与"噪声抑制"的权衡：$\mu = 0$ 时投影误差严格为零（论文在 CHiME6 实验里就取 $\mu = 0$），对应 PMWF 框架内的 MVDR。代价是噪声抑制能力下降。
- 这个矩阵不是"某个方向的空间滤波器"：它不指向任何 DOA，而是把整组 CM 通道映射到每个 DM 通道上。

### 2.2. 三个协方差怎么来（复用 GSS，只做小改动）

- 与原始 GSS 的关键差异：GSS 的 TF mask 与 PMWF **都在 DM 上估**；C2D **在 CM 上估 mask**，再同时用 CM 与 DM 估投影矩阵。论文强调"GSS 方法稍作修改即可提供全部所需技术"。
- 全部数据（含 CM 与 oracle 标签）都可以用来估计投影矩阵——因为投影只用于造训练标签，不受测试期可用性限制。
- 三个协方差都由 mask 加权求和得到（式 (12)–(14)）；因假设"只在 DM 出现的干扰与 CM 不相关"，$\Phi_n^{cd}$ 的估计里不需要额外扣除它。
- 无噪声、ATF 已知时的 oracle 精确解是式 (4)：$W_n(f)^H = \operatorname{diag}\{h_n^d(f)\}^H H_c(f)^{+}$，条件是 $M_c \ge N$。C2D 要解决的问题就是：**在不知道 ATF、又对 CM/DM 里的加性噪声鲁棒的前提下最优地估 $W_n$**。

### 2.3. NN 训练与推理：DRE + mNCSN++ + 辅助输入

- **辅助输入**：CHiME6 每个片段内 DM 上通常有重叠语音，模型必须知道"目标是哪个说话人"，因此把 GSS 的 PMWF 输出作为额外观测输入，与原始 DM 一起送进网络。
- **MIMO**：从 DM 观测与 GSS 输出各选 $M = 4$ 通道作为输入（按 CHiME8 baseline 的 SNR 估计方法选通道），训练参考取生成目标里对应的通道。
- **增强器**：DRE（Deterministic Recursive Enhancement），即去掉 PDRE 的分布估计路径、只估增强语音的简化版；递归调用的增强网络用 mNCSN++，DRE 的实现基于公开的 NCSN++ 代码。
- **post-filter 位置**：GSS 那套 post-filtering（post-masking + BAN）**不作用在**送进网络的 PMWF 输出上，而是作用在**网络输出**上。

## 3. 核心公式

**1. 信号模型（源像形式）：**

$$x_n^c(t,f) = h_n^c(f)\,s_n(t,f), \qquad x_n^d(t,f) = h_n^d(f)\,s_n(t,f)$$

$$\begin{bmatrix} x_c(t,f) \\ x_d(t,f)\end{bmatrix} = \sum_{n=1}^{N}\begin{bmatrix} x_n^c(t,f) \\ x_n^d(t,f)\end{bmatrix} + \begin{bmatrix} v_c(t,f) \\ v_d(t,f)\end{bmatrix}$$

$s_n$ 为第 $n$ 个说话人的干净语音，$h_n^c, h_n^d$ 为其到 CM / DM 的 ATF；假设 ATF 在每个短时片段内时不变，观测 = 各说话人源像之和 + 加性噪声。**训练目标是 DM 处的源像 $x_n^d$**。

**2. 投影输出：**

$$\hat{x}_n^d(t,f) = W_n(f)^H x_c(t,f)$$

$\hat{x}_n^d$ 即生成的远场参考；配对的 distorted 观测是 $x_d(t,f)$。

**3. 估计判据（等价于 SDW-MWF，仅观测域/目标域不同）：**

$$C(W_n(f)) = \mathbb{E}\Big\{\big\| W_n(f)^H x_c(t,f) - x_n^d(t,f)\big\|_2^2\Big\} + \mu\, \mathbb{E}\Big\{\big\| W_n(f)^H v_n^c(t,f)\big\|_2^2\Big\}, \qquad v_n^c(t,f) = \sum_{n'\neq n} x_{n'}^c(t,f) + v_c(t,f)$$

第一项是投影误差，第二项是变换后残留的无关信号（其他说话人 + 加性噪声）功率，$\mu$ 权衡两者。

**4. 闭式解（式 (7)–(10)）：**

$$W_n(f) = \big(\Phi_n^{cc}(f) + \mu\,\Phi_v^{cc}(f)\big)^{-1} \Phi_n^{cd}(f)$$

$$\Phi_n^{cc}(f) = \mathbb{E}\{x_n^c x_n^{cH}\}, \qquad \Phi_v^{cc}(f) = \mathbb{E}\{v_n^c v_n^{cH}\}, \qquad \Phi_n^{cd}(f) = \mathbb{E}\{x_n^c x_n^{dH}\}$$

前两个是 CM 域的目标源 SCM 与无关信号 SCM，第三个是**跨 CM–DM 域的互协方差**——它承担"对齐 DM 域"的职责。

**5. rank-1 假设下化简为 PMWF 变体（式 (11)）：**

$$W_n(f) = \frac{\big(\Phi_v^{cc}(f)\big)^{-1}\Phi_n^{cd}(f)}{\mu + \operatorname{tr}\big\{\big(\Phi_v^{cc}(f)\big)^{-1}\Phi_n^{cc}(f)\big\}}$$

与 PMWF 的差别只在分子：标准 PMWF 分子里是目标 SCM，这里换成跨域互协方差 $\Phi_n^{cd}$，由此实现 CM→DM 投影。$\mu=0$ 时退化为无失真设定（PMWF 框架内的 MVDR），实验中即取 $\mu = 0$。

**6. 无失真 oracle 解（无噪声 + ATF 已知，$M_c \ge N$）：**

$$W_n(f)^H = \operatorname{diag}\{h_n^d(f)\}^H H_c(f)^{+}, \qquad H_c(f) = [h_1^c(f), \dots, h_N^c(f)]$$

$H^{+}$ 为 Moore–Penrose 伪逆。这是 C2D 在理想条件下的上界形式。

**7. 协方差估计（式 (12)–(14)，mask 加权）：**

$$\Phi_n^{cc} = \frac{\sum_t \hat{\phi}_n(t,f)\, x_c x_c^H}{\sum_t \hat{\phi}_n(t,f)}, \qquad \Phi_v^{cc} = \frac{\sum_t (1-\hat{\phi}_n(t,f))\, x_c x_c^H}{\sum_t (1-\hat{\phi}_n(t,f))}, \qquad \Phi_n^{cd} = \frac{\sum_t \hat{\phi}_n(t,f)\, x_c x_d^H}{\sum_t \hat{\phi}_n(t,f)}$$

$\hat{\phi}_n(t,f)$ 是 GSS（cACGMM + oracle 标签引导）**在 CM 上**估计的目标说话人 [[方向/AI语音/知识/基础概念/TF Mask（时频掩码）|TF mask]]。

> 式 (11) 在 arXiv 纯文本抽取中排版错乱，本页给出的形式是按式 (7) 做 rank-1 化简、并与论文自述（"equivalent to PMWF except for $\Phi_n^{cd}$ in the numerator"）核对后的结果；引用前建议以 PDF 原式复核（见「待验证」）。

## 4. 结果口径

**训练/评估条件**：SE 网络**只在 CHiME6 训练集**上训练（用 oracle diarization 生成 C2D 标签，$\mu = 0$）；模型可训练参数 65.7 MB；训练与评估全程对 CM、DM 分别做 [[方向/AI语音/知识/基础概念/WPE（加权预测误差）|WPE]] 去混响；post-filtering（post-masking + BAN）只加在网络输出上。指标为 tcpWER（MeetEval 的多人会议版 [[方向/AI语音/评估/WER（词错误率）|WER]]，同时计识别、说话人归属与时间错误）和 DNSMOS。论文未与 ASR 后端联合训练。

### 4.1. 匹配条件：CHiME6 dev / eval，oracle diarization

| Post filter | SE 方案 | tcpWER dev ↓ | tcpWER eval ↓ | DNSMOS dev | DNSMOS eval |
|---|---|---|---|---|---|
| – | CM training（直接拿 CM 当目标） | 56.31 | 63.15 | 1.99 | 2.12 |
| – | GSS | 20.94 | 27.37 | 2.15 | 2.07 |
| – | A2D | 20.94 | 27.11 | 2.18 | 2.10 |
| – | **C2D（本文）** | **20.13** | **26.54** | **2.32** | **2.20** |
| GSS | GSS | 20.01 | 26.26 | 2.25 | 2.13 |
| C2D | **C2D（本文）** | **19.45** | **25.05** | **2.39** | **2.25** |

- 论文自述：不加 post-filter 时 C2D 相对 GSS 的 tcpWER 相对下降 3.87%（dev）/ 3.13%（eval）；加 post-filter 后为 2.80% / 4.61%。
- **CM training 崩盘**是"CM 不能直接当目标"的实验证据（tcpWER 高出一个量级）；**A2D**（把投影输入从 CM 扩到 CM+DM，等价于在全部 CM+DM 上跑 GSS）只比 GSS 略好，说明把 DM 拉进投影输入反而引入噪声。
- DNSMOS 同向：C2D 在两种 post-filter 设置下都高于 GSS。

### 4.2. 失配条件：CHiME8 eval 四场景，estimated diarization（tcpWER %）

| Post filter | SE 方案 | chime6 | dipco | mixer6 | notsofar1 | average |
|---|---|---|---|---|---|---|
| – | GSS | 38.43 | 32.86 | 20.04 | 24.05 | 28.84 |
| – | C2D（本文） | 37.57 | 30.38 | 20.91 | 20.70 | **27.39** |
| GSS | GSS | 37.26 | 28.22 | 16.16 | 20.60 | **25.56** |
| C2D | C2D（本文） | 36.81 | 28.13 | 18.89 | 20.10 | 25.98 |

读表注意：训练与测试存在**双重失配**（oracle→estimated diarization；CHiME6→CHiME8 其他场景），模型只在 CHiME6 上训过。论文的表述是"C2D 在大多数场景保持对 GSS 的微弱优势，Mixer6 除外"——逐场景看确实如此（不加 post-filter 时 4 个场景全胜，总平均 27.39 < 28.84；加 post-filter 后 chime6 / dipco / notsofar1 胜、mixer6 负 18.89 vs 16.16，**四场景宏平均 25.98 反而略高于 GSS 的 25.56**）。论文把 Mixer6 的退化归因于其 DM 配置与其他场景差异较大；失配鲁棒性列为后续工作。

### 4.3. 消融与对照口径

- **CM training**：证明 CM 直接当目标不可行（见 4.1）。
- **A2D**：证明投影输入不是"越多通道越好"。
- **post-filter 有无**：两种设置下分别对比，C2D 均优于 GSS（但见 4.2 的宏平均注意点）。
- 论文没做的：C2D 标签与"真实 DM 源像"的距离/听感指标（只用下游 tcpWER、DNSMOS 间接证明标签更有用）。

## 5. 测试基准与性能

**测试基准**：训练集 CHiME6 train（N = 4 说话人的晚宴对话，每人一对佩戴麦共 $M_c = 8$ 路 CM；6 个 4 麦阵列共 $M_d = 24$ 路 DM；WPE 预处理；oracle diarization 切片）。匹配条件评估 CHiME6 dev / eval（oracle diarization）；失配条件评估 CHiME8 eval 的四个场景 chime6 / dipco / mixer6 / notsofar1（estimated diarization）。基线：GSS（挑战赛 SOTA 前端）、A2D（本文变体，等价于在 CM+DM 全集上跑 GSS）、CM training（直接拿 CM 当目标）。指标：tcpWER（MeetEval）、DNSMOS。推理链路：DM 观测 + GSS/PMWF 输出各取 4 通道 → DRE（mNCSN++ 递归）→ 网络输出后接 post-filtering（post-masking + BAN）。相关挑战赛背景见 [[方向/AI语音/评估/CHiME（语音分离与识别挑战赛）|CHiME]]。

**性能指标**：完整数字见「结果口径」，此处不重复（匹配条件 C2D+post-filter：dev 19.45 / eval 25.05 tcpWER，DNSMOS dev 2.39 / eval 2.25；失配条件 CHiME8 四场景宏平均 27.39（无 post-filter）/ 25.98（有 post-filter），对照 GSS 的 28.84 / 25.56）。

（来源：笔记正文「结果口径」，核验日期 2026-10-09）

## 6. 使用判断

- **适合**：训练期能同时拿到近讲麦（或任何"比远场干净得多、与远场不同域"的传感器）与远场阵列的真实录音；目标场景是多说话人重叠的会议／晚宴式收录；下游以 ASR 为主、可以用 tcpWER 类会议指标验收。
- **适合**：已有 GSS/PMWF + cACGMM + WPE 工具链——C2D 只要求把 mask 估计搬到 CM 上，其余复用，改动量小。
- **不适合**：只有远场录音（没有 CM，就没有干净源，方法不成立）；单通道或 $M_c < N$ 的配置；说话人与佩戴麦的相对位置频繁大幅变化（ATF 时不变假设）。
- **不适合**：要求"绝对干净、无 DM 域混响"的训练目标——C2D 的参考是 DM 域源像，本身带 DM 的混响/ATF。
- **风险**：标签质量继承全部假设（CM 干净度、DM 独有干扰与 CM 不相关、diarization 正确性）；测试期仍依赖 GSS/PMWF 输出作辅助输入（论文把"去掉这一依赖"列为 future work）；跨场景（尤其阵列配置差异大的场景）会掉点。

  **投影的假设前提（破了会怎样）**：

  | 假设 | 原文依据 | 破了会怎样 |
  |---|---|---|
  | 训练期 CM 与 DM 同时录制，且 CM 比 DM 干净得多 | §1、§4.1（CHiME6 佩戴麦） | CM 自身噪声大时，"干净源"不成立，投影把 CM 的噪声一起搬进标签 |
  | CM 里只有"目标说话人 + 其他说话人 + 加性噪声"；**只在 DM 里出现的干扰与 CM 不相关** | §4.2（因此在式 (14) 中可忽略） | 与 CM 相关的远场干扰（如 DM 信号回灌 CM）会污染跨域互协方差 $\Phi_n^{cd}$，标签被干扰项污染 |
  | ATF 在每个短时片段内时不变 | §3.1（式 (1) 之后） | 片段内明显移动/转头的说话人使源像模型不成立，投影无法对齐 |
  | $\Phi_n^{cc}$ 与 $\Phi_n^{cd}$ 近似 rank-1 | §3.2（由式 (1) 支撑） | 才能化简到式 (11) 的 PMWF 形式；rank-1 不成立时该闭式不再等价 |
  | 需要 $M_c \ge N$ 才能精确反解 | §3.1（式 (4)） | CM 数量少于同时说话人数时，无失真的精确投影不存在 |
  | 目标说话人在 CM 上不重叠（靠 oracle diarization 切段） | §4.2 | diarization 错误会直接写进生成标签 |

  一句话概括风险：**标签质量完全取决于这些假设，而标签质量正是本文相对仿真训练的收益来源**——投影生成的是"比仿真更真、但比真值更脏"的参考。
- **对照选择**：如果只需一个强基线，GSS 已经很接近，C2D 的收益是"小幅、且并非所有失配场景都赢"的 tcpWER 改善；如果任务是多源真实会议，直接拿 CM 当目标（SuperM2M / FNSE-SAT 那类思路）在本任务上被论文证否（见 CM training 一行）。

## 7. 关键来源

- [Generating Training Targets for Real-World Speech Enhancement via Close-to-Distant Microphone Projection（arXiv:2606.13109）](https://arxiv.org/abs/2606.13109)
  - 内容定位：原始论文，ICASSP 2026；提出 C2D projection，把近讲麦投影成远场干净参考用于 SE 训练。
  - 用途：全部公式（式 (1)–(14)）、CHiME6 / CHiME8 实验数字与训练配置的唯一依据。
  - 核验日期：2026-10-09
  - 备注：本机网络策略无法直连 arxiv.org 的 abs 页；题名、作者、提交日期取自 arXiv 正文抽取（`arXiv:2606.13109v1 [eess.AS] 11 Jun 2026`），venue 经检索交叉核验。
- [IEEE Xplore 收录页（document 11464238）](https://ieeexplore.ieee.org/abstract/document/11464238)
  - 内容定位：ICASSP 2026 出版记录（DOI 10.1109/ICASSP55912.2026.11464238，pp. 18912–18916）。
  - 用途：确认会议接收与出版信息。
  - 核验日期：2026-10-09
- [NTT ICASSP 2026 录用论文专题页](https://group.ntt/en/topics/2026/04/30/icassp2026.html)
  - 内容定位：NTT 公布 ICASSP 2026 录用论文列表（含本文）。
  - 用途：作为会议接收的旁证；会议时间地点为 Barcelona，2026-05-04 ~ 05-08。
  - 核验日期：2026-10-09
- [DRE 实现所用的公开 NCSN++ 代码（sp-uhh/sgmse）](https://github.com/sp-uhh/sgmse)
  - 内容定位：论文脚注给出的唯一代码入口（增强网络实现）。
  - 用途：复现增强器部分的入口；C2D 投影本身无官方代码。
  - 核验日期：2026-10-09

## 8. 相关对象

- [[方向/AI语音/模型/Mixture to Beamformed Mixture（波束形成混合弱监督）|Mixture to Beamformed Mixture]]：同属"真实录音造监督信号"，但范式不同（空间滤波产物 vs 跨域投影），差异见下表。

  **与 [[方向/AI语音/模型/Mixture to Beamformed Mixture（波束形成混合弱监督）|Mixture to Beamformed Mixture（波束形成混合弱监督）]] 的本质区别**（两者同属"用真实录音造监督信号"，容易混）：

  | 维度 | Mixture to Beamformed Mixture | C2D Projection |
  |---|---|---|
  | 参考信号来源 | 同一个 DM 观测的内部 | 另一组物理上更干净的传感器（佩戴在嘴边的 CM） |
  | 算子性质 | 空间滤波（波束形成权向量，同域加权求和） | 跨域投影矩阵（$M_c \to M_d$，PMWF 变体，分子换成跨域互协方差 $\Phi_n^{cd}$） |
  | "干净"从哪来 | 靠空间滤波抑制干扰，残留噪声/失真仍在，标签是"更高 SNR 的观测" | 靠 CM 本身的高 SNR，再用投影把 CM 内容重构到 DM 域 |
  | 监督口径 | sample-level weak supervision | 仍是**普通监督学习**（论文自述：generates training targets directly from real data → simple supervised learning） |
  | 额外依赖 | 无（训练、测试都用同一套多通道录音） | 训练期额外需要 CM + oracle diarization；测试期只需 DM |
- [[方向/AI语音/知识/基础概念/GSS（引导源分离）|GSS]]：论文的 SOTA 基线，也是 C2D 的 mask / 协方差估计工具来源（"GSS 稍作修改即可"）。
- [[方向/AI语音/知识/基础概念/MVDR（最小方差无失真响应）|MVDR]]：$\mu = 0$ 时 C2D 在 PMWF 框架内退化为 MVDR。
- [[方向/AI语音/知识/基础概念/DP-MWF（保向多通道维纳滤波）|DP-MWF]]、[[方向/AI语音/知识/基础概念/SCM（空间协方差矩阵）|SCM]]、[[方向/AI语音/知识/基础概念/TF Mask（时频掩码）|TF Mask]]、[[方向/AI语音/知识/基础概念/WPE（加权预测误差）|WPE]]：投影矩阵所属的滤波器家族与三件套工具。
- [[方向/AI语音/模型/PDRE|PDRE]]、[[方向/AI语音/模型/Multi-Stream Diffusion|Multi-Stream Diffusion]]：SE 网络侧的直接前作（DRE 是 PDRE 的简化版；mNCSN++ 来自 Multi-Stream Diffusion）。
- [[方向/AI语音/知识/基础概念/MIMO（多输入多输出）|MIMO]]、[[方向/AI语音/知识/基础概念/NCSN++（噪声条件分数网络）|NCSN++]]：增强器的配置与骨干。
- [[方向/AI语音/知识/基础概念/Microphone Channel Modeling（麦克风信道建模）|Microphone Channel Modeling]]：源像 / ATF 口径的来源。
- [[方向/AI语音/知识/技术路线/Real-Data Array SE（真实数据驱动阵列增强）|Real-Data Array SE]]、[[方向/AI语音/知识/技术路线/Hybrid Array SE（传统神经混合阵列增强）|Hybrid Array SE]]、[[方向/AI语音/知识/技术路线/Array SE Roadmap（阵列语音增强技术路线优先级）|阵列语音增强技术路线优先级]]：C2D 的路线归属（真实数据标签生成 + 经典-神经混合）。
- [[方向/AI语音/知识/调研与地图/Array Speech Enhancement Frontier（阵列语音增强前沿调研）|阵列语音增强前沿调研]]：可挂在「弱监督 / 无监督 / 真实数据」节，与 M2BM 并列但区分范式。
- [[方向/AI语音/实证研究/Less is More（语音增强数据筛选）|Less is More]]：同一主题的另一份证据——"target 质量决定 SE 上限"。
- [[方向/AI语音/评估/CHiME（语音分离与识别挑战赛）|CHiME]]、[[方向/AI语音/评估/WER（词错误率）|WER]]、[[方向/AI语音/评估/NOTSOFAR-1（远场会议转写挑战）|NOTSOFAR-1]]：评估来源（CHiME6 / CHiME8、tcpWER、Notsofar1 场景）。
- [[方向/AI语音/团队/NTT Speech Group（NTT 语音组）|NTT Speech Group]]、[[方向/AI语音/团队/Z.-Q. Wang Group（Zhong-Qiu Wang 组）|Z.-Q. Wang Group]]：作者团队；后者是 SuperM2M（"CM 直接当目标"路线）的作者。

## 9. 待验证

- **式 (11) 原式**：arXiv 纯文本抽取把该式排版打乱，本页形式是按式 (7) 的 rank-1 化简并与论文自述核对的结果，需以 PDF 复核。
- **会话数不一致**：§4.1 写 CHiME6 为 20 个 session、16/2/2 划分；§5.1 写用其中 14 个 session 训练、2 个验证，两者对不上，需以原文/代码确认。
- **C2D 标签质量本身缺乏直接评估**：论文只用下游 tcpWER / DNSMOS 间接证明投影参考更干净，没有给出 $\hat{x}_n^d$ 与真实 DM 源像的距离或听感指标。
- **官方代码**：论文只给 NCSN++ 的公开实现；C2D 投影、A2D 变体与标签生成流程是否有开源实现待查。
- **失配退化归因**：Mixer6 掉点被归因于"DM 配置差异"，但论文未做受控实验证明；CM/DM 通道数与几何变化下的可迁移性未知。
- **与 M2BM 的直接对照**：两篇无交集实验，"跨域投影参考 vs 波束形成弱标签"在同一真实数据上的优劣未验证。
- **去掉 GSS 辅助输入后的表现**：论文把它列为 future work，当前测试期仍依赖 GSS/PMWF 输出。
- **SuperM2M / FNSE-SAT 的适用边界**：论文称它们在单源真实任务上有效，而 C2D 的 "CM training" 在多源 CHiME6 上崩盘；多源场景下这些方法是否同样失效，未见对照。

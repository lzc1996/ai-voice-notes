---
title: FaSNet（滤波求和网络）
类型: 模型
发表时间: 2019-09
时间依据: arXiv 首次提交日（v1 2019-09-29；v2 2019-10-01）；ASRU 2019（通行引用口径，arXiv 页 Comments 栏未标注）
任务:
  - 语音增强
  - 语音分离
  - 多通道增强
方法范式:
  - 判别式
开放状态:
  - paper
aliases:
  - FaSNet
  - Filter-and-Sum Network
  - filter-and-sum network
  - 滤波求和网络
  - "FaSNet: Low-latency adaptive beamforming for multi-microphone audio processing"
tags:
  - 类型/对象
  - 方向/AI语音
  - 任务/语音增强
  - 任务/语音分离
  - 任务/多通道增强
  - 主题/阵列无关
---

# FaSNet（滤波求和网络）

## 0. 背景

**1) 问题现场**：2019 年前后的神经波束形成（neural beamformer）按 FaSNet 原文引言可分三类——

- **滤波式（filtering-based, FB）**：直接学习一组[[方向/AI语音/知识/基础概念/Beamforming（波束形成）|波束形成]]滤波器，在时域或频域做 filter-and-sum（FaS）——各通道分别滤波后求和成单通道输出；滤波器可固定或自适应。
- **掩码式（masking-based, MB）**：估计目标源的时频掩码 → 计算空间协方差 → 解 [[方向/AI语音/知识/基础概念/MVDR（最小方差无失真响应）|MVDR]]/[[方向/AI语音/知识/基础概念/GEV（广义特征值波束形成）|GEV]] 等最优权重；是当时的主流，信号质量与 WER 上都有大幅提升，但系统普遍**非因果**，且需要大上下文才能稳健估计通道间特征。
- **回归式（regression-based, RB）**：不显式产生波束滤波器，把多通道输入直接喂给网络学习目标源的映射，波束形成被假定隐含在映射函数里。

**2) 前序路线的缺口**：

- 频域方法占主导（ASR 场景惯用、且公认比时域方法稳健），但合理的频率分辨率要求长输入，带来**可感知的系统延迟**，不适合要求低延迟响应的在线应用。
- MB 路线的性能依赖掩码估计网络，在在线/因果场景下会退化；原文实验显示即便用 oracle IBM，MB-MVDR 把空间协方差估计窗口压到 100 ms 时 SI-SNRi 直接变负——稳健的空间统计需要足够长的 segment，与低延迟结构性冲突。
- RB 路线不显式产生滤波器，波束行为不可解释、不可控。

**3) FaSNet 的切入点**：把 FB 路线搬到**时域帧级**——由 TCN 在短帧上直接估计自适应 FaS 滤波器，配两阶段参考通道设计，系统延迟只有帧长的两倍（$2L$），面向实时低延迟多麦处理。

## 1. 身份

`FaSNet`（Filter-and-Sum Network，滤波求和网络）是 Yi Luo、Enea Ceolini（共同一作）、Cong Han、Shih-Chii Liu、Nima Mesgarani（Columbia University + University of Zurich/ETH Zurich）提出的**时域自适应神经波束形成器**（ASRU 2019，arXiv:1909.13387）：第一阶段对选定参考麦估计帧级时域波束滤波器并输出预分离结果，第二阶段以预分离输出为线索、用逐对（pair-wise）跨通道特征为其余每个通道估计滤波器，所有通道滤波输出求和得到最终波束输出。滤波估计模块用 TCN（时域卷积网络），全模型仅 1.5M 参数，系统延迟 $2L$（$L$ 为帧长，论文主配置 16 ms → 32 ms 延迟）。

由于第一阶段对非参考麦特征做平均池化、第二阶段所有剩余通道共享同一 TCN，模型对**麦克风数量与排列顺序不变**（[[方向/AI语音/知识/基础概念/TAC（变换-平均-拼接）|TAC]] 论文口径），是 array-agnostic 路线的早期结构方案。原始论文未独立开源代码；可用实现并入 TAC 论文官方仓库（github.com/yluo42/TAC，为 DPRNN+TAC 改版，非原版 TCN 配置）。

边界：不是掩码式波束形成（不估 T-F 掩码、不解 MVDR/GEV 优化问题，直接回归时域滤波器）；也不同于后续 TAC 版 FaSNet——原版为两阶段 + TCN、无跨通道全局池化，TAC 版改为单阶段并在滤波估计模块内插入 TAC。

## 2. 核心机制

时域 FaS 波束形成的问题定义：对 $N\geq 2$ 个麦克风的阵列，估计一组时域滤波器，使各通道滤波后求和的结果最优地重建参考麦中的目标信号。各麦信号先分帧（帧长 $L$ 采样点、hop $H$），FaS 操作在每帧周围的上下文窗上进行以容纳跨麦时延（TDOA）：

$$\hat{\bm{y}}_{t}=\sum_{i=1}^{N}\bm{h}^{i}_{t}\circledast\hat{\bm{x}}^{i}_{t}$$

其中 $t$ 为帧索引，$\hat{\bm{x}}^{i}_{t}=\bm{x}^{i}[tH-L:tH+2L-1]\in\mathbb{R}^{1\times 3L}$ 为麦克风 $i$ 在帧 $t$ 的上下文窗（前后各扩一帧，覆盖 $\pm L$ 采样点的跨麦延迟），$\bm{h}^{i}_{t}\in\mathbb{R}^{1\times(2L+1)}$ 为待学的波束滤波器，$\circledast$ 为卷积，$\hat{\bm{y}}_{t}\in\mathbb{R}^{1\times L}$ 为帧 $t$ 的波束输出。问题归结为：给定观测 $\bm{x}^{i}$ 估计 $\bm{h}^{i}_{t}$。

```text
[分帧] 各麦波形 x^i -> 帧长 L、hop H；上下文窗 x̂^i（3L）
[阶段 1：参考麦]
  NCC：x̂^1 与各非参考麦中心帧 x^i 的余弦相似度 -> f^i（2L+1 维）
  -> 对 N-1 个非参考麦平均池化 -> f̄（排列无关）
  -> [R^1 = x^1 U（通道自身嵌入 K 维）; f̄] -> TCN H1 -> 门控输出层
  -> 参考麦滤波器 h^1_c（C = 目标源数）
  -> h^1_c ⊛ x̂^1 -> 参考麦预分离输出 ŷ^1_c
[阶段 2：剩余麦 i = 2..N，全部共享同一 TCN H2]
  NCC：x̂^i 与 ŷ^1_c 的余弦相似度 -> g^i_c（逐对特征）
  -> [R^i = x^i U; g^i_c] -> TCN H2 -> 门控输出层 -> h^i_c
[求和] ŷ_c = ŷ^1_c + Σ_{i=2..N} x̂^i ⊛ h^i_c
  -> overlap-and-add 还原整句波形
```

### 2.1. 第一阶段：参考通道处理

参考麦从阵列中随机选定（实验里固定取第 1 通道）。跨通道特征用帧级**归一化互相关（NCC）**，论文实现为余弦相似度（受频域方法中 GCC-PHAT 特征启发）：参考麦上下文窗 $\hat{\bm{x}}^{1}$ 与每个非参考麦同帧中心帧 $\bm{x}^{i}$ 逐延迟计算

$$\begin{cases}\hat{\bm{x}}^{1}_{j}=\hat{\bm{x}}^{1}[j:j+L-1]\\ f^{i}_{j}=\dfrac{\hat{\bm{x}}^{1}_{j}(\bm{x}^{i})^{T}}{\|\hat{\bm{x}}^{1}_{j}\|_{2}\,\|\bm{x}^{i}\|_{2}}\end{cases},\quad j=1,\dots,2L+1$$

$\bm{f}^{i}\in\mathbb{R}^{1\times(2L+1)}$ 同时携带 TDOA 信息与内容相关信息。为以排列无关方式合并 $N-1$ 个非参考麦的特征，直接平均池化：

$$\bar{\bm{f}}=\frac{1}{N-1}\sum_{i=2}^{N}\bm{f}^{i}$$

通道自身特征由线性层给出：$\bm{R}^{1}=\bm{x}^{1}\bm{U}$，$\bm{U}\in\mathbb{R}^{L\times K}$，得 $K$ 维嵌入。$[\bm{R}^{1},\bar{\bm{f}}]$ 送入与 Conv-TasNet 同设计的 TCN（映射记 $\mathcal{H}_{1}$），再经**门控输出层**生成 $C$ 个目标源各自的滤波器：

$$\bm{p}^{1}_{c}=\mathcal{H}_{1}\big([\bm{R}^{1},\bar{\bm{f}}]\big),\qquad \bm{h}^{1}_{c}=\tanh(\bm{p}^{1}_{c}\bm{W}^{1}+\bm{b}^{1})\odot\sigma(\bm{p}^{1}_{c}\bm{V}^{1}+\bm{q}^{1})$$

其中 $\bm{p}^{1}_{c}\in\mathbb{R}^{1\times K}$ 为 TCN 输出，$\bm{W}^{1},\bm{V}^{1}\in\mathbb{R}^{K\times(2L+1)}$ 与 $\bm{b}^{1},\bm{q}^{1}$ 为门控层权重与偏置，$\odot$ 为 Hadamard 积。滤波器与上下文窗卷积得参考麦预分离输出 $\hat{\bm{y}}^{1}_{c}=\hat{\bm{x}}^{1}\circledast\bm{h}^{1}_{c}$。

### 2.2. 第二阶段：剩余通道逐对处理

对每个剩余麦 $i$，以其上下文窗 $\hat{\bm{x}}^{i}$ 与第一阶段输出 $\hat{\bm{y}}^{1}_{c}$ 的 NCC（同样取余弦相似度）为**逐对跨通道特征**：

$$g^{i}_{c,j}=\frac{\hat{\bm{x}}^{i}_{j}(\hat{\bm{y}}^{1}_{c})^{T}}{\|\hat{\bm{x}}^{i}_{j}\|_{2}\,\|\hat{\bm{y}}^{1}_{c}\|_{2}},\quad j=1,\dots,2L+1$$

$[\bm{R}^{i},\bm{g}^{i}_{c}]$（$\bm{R}^{i}=\bm{x}^{i}\bm{U}$）送入第二个 TCN $\mathcal{H}_{2}$ 与同构门控层生成 $\bm{h}^{i}_{c}$。**所有剩余麦共享同一 TCN 与门控层**——逐对特征 + 参数共享使第二阶段对麦数与排列不变。最终输出为各通道滤波结果求和：

$$\hat{\bm{y}}_{c}=\hat{\bm{y}}^{1}_{c}+\sum_{i=2}^{N}\hat{\bm{x}}^{i}\circledast\bm{h}^{i}_{c}$$

各帧经 overlap-and-add 还原为整句波形 $\bm{y}^{*}_{c}$。

### 2.3. 训练目标与级联

- **信号级目标**（增强/分离任务）：[[方向/AI语音/评估/SI-SDR|SI-SNR]]，$\mathcal{L}=\frac{1}{C}\sum_{c}\text{SI-SNR}(\bm{y}_{c},\bm{y}^{*}_{c})$；多输出时始终配合 utterance 级 [[方向/AI语音/知识/基础概念/PIT（置换不变训练）|uPIT]] 解决输出排列歧义。
- **频域目标**（ASR 前端）：对输出与目标分别做幅度归一后取 STFT 幅度谱，过 mel 滤波器组 $\bm{M}$，以 SI-MSE 训练：$\mathcal{L}=\frac{1}{C}\sum_{c}\text{MSE}(\bm{Y}_{c}\bm{M},\bm{Y}^{*}_{c}\bm{M})$。
- CHiME-3 上用原始干净源为目标时存在未知时移，采用 shift-invariant training（$\pm 2$ ms 内取最大 SI-SNR）。
- FaSNet 输出波形可直接接任意单通道增强系统（tandem），整条链路仍可端到端训练。

超参：每个 TCN 为 $R=2$ repeats × $P=5$ 个一维卷积块（核 3，输入通道 64、隐通道 320），嵌入维 $K=64$，单 TCN 0.76M 参数；FaSNet 全模型 1.5M（对照单通道 Conv-TasNet 1.9M、tandem 3.4M）。ESE/ASR 任务每个 TCN 每帧估 1 个滤波器，ESS 任务估 2 个（对应两个说话人）。

## 3. 结果口径

**实验设置**：三个任务——ESE（回声环境联合去噪+去混响）、ESS（噪声回声环境下分离两个说话人的直达声）、CHiME-3 多通道含噪 ASR。ESE/ESS 用 TIMIT + gpuRIR（镜像法）仿真：**直径 10 cm 的圆形全向阵列、最多 4 麦**，房间长宽 $[3,8]$ m、高 3 m，声源高 1 m 且距墙 ≥0.5 m；20000/5000/3000 个房间作训练/验证/测试；噪声取自 100 Nonspeech Sounds；ESE 信噪比 $[-5,15]$ dB，ESS 两说话人相对 SNR $[-5,5]$ dB。目标一律为直达声信号；CC 为封闭条件（开发集）、OC 为开放条件（评估集）。帧长主配置 $L=16$ ms（延迟 32 ms）。

- **帧长消融**（Table 4，2 麦 ESE，OC 集 SI-SNRi）：帧长 2/4/8/16 ms → 1.4/2.2/3.0/3.7 dB——帧越长性能越好，但延迟 $=2L$，低延迟场景需权衡。
- **主结果**（Table 5，OC 集 SI-SNRi，dB）：

| 方法 | 因果 | 麦数 | ESE | ESS |
|---|---|---|---|---|
| Conv-TasNet（单通道） | × | 1 | 5.0 | 4.1 |
| Conv-TasNet（单通道） | ✓ | 1 | 3.3 | 2.6 |
| FaSNet | × | 2 / 3 / 4 | 3.7 / 4.1 / 5.0 | 3.6 / 3.9 / 4.6 |
| FaSNet | ✓ | 2 / 3 / 4 | 3.5 / 3.8 / 4.3 | 3.1 / 3.4 / 3.8 |
| Tandem（FaSNet+单通道） | × | 2 / 3 / 4 | 5.5 / 5.0 / 6.4 | 4.4 / 5.5 / 6.1 |

  非因果 4 麦 FaSNet 与单通道 Conv-TasNet 持平；**因果 2 麦 FaSNet（3.5）即超过因果 Conv-TasNet（3.3）**。4 麦 tandem（6.4）与全句 oracle IBM 的 MB-MVDR（6.6）持平，且显著优于 500 ms 短窗估计的 segment 级 oracle MB-MVDR（4.7）——这是论文论证低延迟优势的核心对照。
- **oracle 传统波束形成基准**（Table 2，全句估计，4 麦 OC）：TD-MVDR 3.2/4.3（ESE/ESS）、FD-SDW-MWF 7.9/7.5、MB-MVDR 6.6/6.3、MB-GEV 2.5/2.3。FaSNet 胜过的是时域与短窗频域的 oracle 基线；全句 FD-SDW-MWF 仍是上限（7.9）。
- **CHiME-3 真实录音**（Table 6/7）：SI-SNRi 上 FaSNet 显著优于 Conv-TasNet（去混响干净目标 12.2 vs 8.7，因果 10.6）；WER 上以 mel 谱 + SI-MSE 目标训练时 27.89%，对比官方基线 32.48%，**相对 WER 降低 14.3%**。
- **滤波器可视化**（Fig. 2）：FaSNet 学到内容依赖的波束图——语音段与非语音段的 beampattern 不同，非语音区域呈零陷（null）。
- **TAC 论文转述口径**（arXiv:1910.14104，注意出处不是 FaSNet 原文）：在 TAC 论文自己的实验设置（LibriSpeech 仿真）里，无 TAC 的两阶段 FaSNet 在 ad-hoc 2/4/6 麦上 SI-SNRi 为 5.9/6.9/7.3 dB，固定几何 6 麦圆阵上为 10.0 dB（加 TAC 后 11.3），优于该论文口径下的掩码式神经波束形成基线。

## 4. 使用判断

- 适合：在线、低延迟多麦前端（帧级处理，延迟 $2L$，16 ms 帧对应 32 ms）；麦数/排列不固定的阵列（结构级数量与排列不变）；算力受限场景（1.5M 参数）；作为 ASR 或单通道增强的可级联前端（tandem 配置稳定涨点）。
- 不适合：离线、追求极限信号质量的场景（全句 oracle 频域波束形成如 FD-SDW-MWF 上限更高）；需要极小帧长的场景（2 ms 帧 OC 仅 1.4 dB，小窗掉点明显）。
- 风险：**第一阶段拖累第二阶段**——参考麦预分离失败会沿线索传播到所有剩余通道的滤波估计；**逐对特征缺全局视野**——第二阶段估计某通道滤波器时只看「该通道 × 参考输出」一对，无法利用全部麦克风做全局决策，在各麦声学特性差异大的 ad-hoc 阵列上不稳（两者均为 [[方向/AI语音/知识/基础概念/TAC（变换-平均-拼接）|TAC]] 论文指出的缺口，TAC 即为此而生）；原版 TCN 实现未独立开源，复现只能基于 TAC 仓库的 DPRNN 改版；与 ASR 后端全端到端联合训练在原文中为 future work，未见验证。

## 5. 关键来源

- [FaSNet: Low-latency adaptive beamforming for multi-microphone audio processing（arXiv:1909.13387）](https://arxiv.org/abs/1909.13387)
  - 内容定位：原始论文摘要页（v1 2019-09-29，v2 2019-10-01，CC BY-NC-SA 4.0；Comments 栏未标注发表场所，ASRU 2019 为通行引用口径）。
  - 用途：对象身份、两阶段设计与低延迟定位、14.3% RWERR 的摘要口径。
  - 核验日期：2026-10-21
- [FaSNet HTML 全文（arXiv:1909.13387v2）](https://arxiv.org/html/1909.13387)
  - 内容定位：原文全文（LaTeXML 转换）：§3 两阶段公式（NCC 余弦相似度、平均池化、门控输出层、最终求和）、§4 数据生成与超参（≤4 麦 10 cm 圆阵、TCN R=2/P=5、K=64、0.76M/TCN）、§5 全部结果表（Table 2–7）与 beampattern 可视化。
  - 用途：本页机制公式、实验设置与全部数值口径的来源；引言（§2）FB/MB/RB 三分类为「背景」节素材。
  - 核验日期：2026-10-21
- [yluo42/TAC（GitHub）](https://github.com/yluo42/TAC)
  - 内容定位：TAC 论文官方仓库；仓库根目录含 `FaSNet.py`、`iFaSNet.py`（经 GitHub API 核验），README 明示"在 FaSNet 框架下实现 TAC"，两处修改为单阶段化 + 滤波估计模块内插 TAC，滤波估计块基于 DPRNN。
  - 用途：开源状态核验——yluo42/FaSNet 独立仓库不存在（API 返回 404），FaSNet 可用实现即此仓库的改版，原版 TCN FaSNet 代码未见开源。
  - 核验日期：2026-10-21
- [End-to-end microphone permutation and number invariant multi-channel speech separation（arXiv:1910.14104）](https://arxiv.org/abs/1910.14104)
  - 内容定位：TAC 原始论文（ICASSP 2020），FaSNet 的后继工作；库内口径见 [[方向/AI语音/知识/基础概念/TAC（变换-平均-拼接）|TAC]] 页。
  - 用途：FaSNet 数量/排列不变性的明确表述、两缺口（阶段拖累、逐对缺全局）的出处；ad-hoc 2/4/6 麦 5.9/6.9/7.3 dB 与固定 6 麦圆阵 10.0 dB 数字的真实出处（属 TAC 论文实验口径，非 FaSNet 原文）。
  - 核验日期：2026-10-21

## 6. 相关对象

- [[方向/AI语音/知识/基础概念/TAC（变换-平均-拼接）|TAC]]：直接后继——把 FaSNet 两阶段改单阶段、以共享变换+平均池化+拼接补上全局决策缺口；FaSNet 是 TAC 的原始载体。
- [[方向/AI语音/知识/基础概念/Beamforming（波束形成）|Beamforming]]：FaSNet 属其中 filter-and-sum 家族；[[方向/AI语音/知识/基础概念/MVDR（最小方差无失真响应）|MVDR]]、[[方向/AI语音/知识/基础概念/GEV（广义特征值波束形成）|GEV]] 为原文对照的掩码式/优化式传统路线。
- [[方向/AI语音/知识/基础概念/PIT（置换不变训练）|PIT/uPIT]]：FaSNet 多输出（ESS）训练始终配 uPIT，解决的是**输出说话人**置换；FaSNet 自身结构解决的是**通道**置换，两者正交。
- [[方向/AI语音/知识/技术路线/Array-Agnostic SE（阵列无关语音增强）|Array-Agnostic SE]]：FaSNet 的麦数/排列不变设计是该路线的早期结构方案。
- [[方向/AI语音/模型/VarArray|VarArray]]、[[方向/AI语音/模型/REDnet|REDnet]]、[[方向/AI语音/模型/SFB-NSE|SFB-NSE]]：FaSNet+TAC 系的后续使用、对照与替代（详见各页）。

## 7. 待验证

- ASRU 2019 接收信息：arXiv 摘要页 Comments 栏无标注，当前按通行引用口径，待正式论文集核对。
- 原版 TCN FaSNet 代码：独立仓库 yluo42/FaSNet 确认不存在（404）；TAC 仓库 `FaSNet.py` 为 DPRNN+TAC 改版，是否完整覆盖原版两阶段 TCN 配置待逐行核对。
- 与库内口径的一处出入：TAC 页/调研口径中「固定几何 6 麦圆阵」属 **TAC 论文**的实验设置（LibriSpeech 仿真）；FaSNet 原文实验为**最多 4 麦、直径 10 cm 圆阵**（TIMIT 仿真），引用时需注意区分出处。
- 延迟口径：原文仅给出「系统延迟 $=2L$」，逐帧 hop $H$ 与重叠相加对端到端延迟的精确贡献未推导。

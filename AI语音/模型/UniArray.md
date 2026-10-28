---
title: UniArray
类型: 模型
发表时间: 2025-03
时间依据: arXiv 首次提交日（v1 2025-03-07，无修订版）
任务:
  - 语音分离
方法范式:
  - 判别式
开放状态:
  - paper
aliases:
  - UniArray
  - "UniArray: Unified Spectral-Spatial Modeling for Array-Geometry-Agnostic Speech Separation"
tags:
  - 类型/对象
  - 方向/AI语音
  - 任务/语音分离
  - 主题/阵列无关
  - 主题/虚拟麦克风
---

# UniArray

## 0. 背景

**问题现场**：阵列几何无关语音分离（AGA-SS）——模型要跨不同阵列几何与通道数保持分离性能，无需逐阵列重训。

**前序路线的缺口**：主流"通道内/通道间交替 + 置换无关运算（TAC 求和/注意力）"做法（FasNet-TAC、三路径类）算力高，且通道数可变时空间信息难以归一到固定维度。

**UniArray 的切入点**：在频率分箱级显式建模空间线索——可学习空间字典（SDL）给与通道数无关的空间嵌入、[[方向/AI语音/知识/基础概念/Neural-VME（神经虚拟麦克风估计）|虚拟麦克风估计（VME）]]把通道补齐到上限 $M$，再由层次化双路径 Conformer（时间+频率轴）输出每说话人干净复频谱。

## 1. 身份

`UniArray`（Unified Spectral-Spatial Modeling for Array-Geometry-Agnostic Speech Separation）是湖南大学 × 江南大学 × 南洋理工大学（Weiguang Chen、Junjie Zhang、Xionghu Zhong、Jielong Yang、Eng Siong Chng）提出的**阵列几何无关语音分离（AGA-SS）**方法（IEEE Signal Processing Letters 32 卷，2025，pp. 2164–2168，DOI: [10.1109/LSP.2025.3562949](https://doi.org/10.1109/LSP.2025.3562949)；arXiv:2503.05110，2025-03-07 v1）。正式出版信息于 2026-10-27 经 Crossref 核验。

它不走"通道内 / 通道间交替 + 置换无关运算（TAC 求和 / 注意力）"这条主流做法，改在**频率分箱（frequency-bin）级**显式建模空间线索：可学习**空间字典（SDL）**给出与通道数无关的空间嵌入，**虚拟麦克风估计（VME）**把通道数补齐到上限 $M$，再由**层次化双路径 Conformer** 输出每个说话人的干净复频谱（机制见「核心机制」）。

边界：属阵列泛化里**"通道数归一 + 固定维度空间表示"**这一类，既不是显式坐标条件化（[[方向/AI语音/模型/Geo-DConv|Geo-DConv]]），也不是物理规范域编码（[[方向/AI语音/模型/AmbiDrop|AmbiDrop]]）；与 [[方向/AI语音/模型/Spatial-Magnifier|Spatial-Magnifier]] 同用虚拟麦但目的不同——三者的区别见「相关对象」。严格任务是**分离**，不是狭义 SE；实验仅仿真数据。

## 2. 核心机制

```text
多通道复频谱 X ∈ T×F×2C（C ≤ M，实虚部拼接）
  -> VME：在相邻真实麦克风对之间插值生成虚拟麦克风，通道维补齐到 M
  -> 特征提取与融合：局部谱模式提取器（参考通道 2-D CNN）
                     + SDL（N=64 空间字典，逐频率分箱投影得空间嵌入）
                     -> 迭代注意力特征融合 -> X ∈ T×F×E
  -> 层次化双路径 Conformer：patch merging [1×1, 2×2, 2×2]
                     -> 每个尺度：时间轴 / 频率轴双路径 Conformer
                     -> patch expanding 对称还原分辨率
  -> 每说话人干净复频谱 T×F×2K
```

### 2.1. VME（虚拟麦克风估计）

- 论文称**首次把 VME 用在 AGA-SS**：沿用 [22] 的插值式 VME，在两个真实麦克风之间插值得到虚拟信号的相位与幅度（空间分辨率提升、保留原始音频完整性）。
- 与既往工作的差别在通道数可变：既往 VME 针对固定的一对真实麦克风，UniArray 则一直生成虚拟麦克风直到通道维达到上限 $M$（默认 $M=8$）。虚拟麦克风数量在真实麦克风对之间均匀分配（式 1–2）；**相邻麦克风配对，首个与最后一个也配成一对**，故真实麦克风对数 $N_p$ 等于输入通道数 $C$。
- 消融口径：VME 缺失时通道数用零填充补到 $M=8$；缺 VME 在"未见几何 + 未见通道数"上明显掉点，说明 VME 的作用是维持跨阵列的一致性能。

### 2.2. 特征提取与融合（局部谱模式 + SDL + 注意力融合）

- **局部模式提取器**：2-D CNN 从参考通道（默认通道 0）提取局部谱时模式，沿用作者前作 [26] 在增强任务上的结论。
- **SDL**：从多通道复频谱在频率分箱级建模相位与幅度差。构建可学习空间字典 $\mathbf D=[\mathbf d^{(1)},\dots,\mathbf d^{(N)}]\in\mathbb C^{M\times N}$，把复向量投影到超球面得到空间嵌入 $a(t,f)\in\mathbb R^{N}$（$N=64$）；字典项与复向量**双双归一化**，使 SDL 专注空间结构；嵌入再用平均幅度谱加权，优先考虑高功率频点。字典**跨频带共享**（另有频率相关变体 FSDL 作对照）。嵌入维度 $N$ 与通道数 $C$ 无关，这是"通道数无关"的来源。
- **注意力融合**：迭代式注意力特征融合 [29] 聚合局部/全局上下文并给每个特征图分配注意力分数，谱与空间特征加权求和得融合特征图 $\mathbf X\in\mathbb R^{T\times F\times E}$（谱、空间、融合三种特征维度统一为 $E=64$）。

### 2.3. 层次化双路径分离器

- 频点级输出分辨率高、直接处理算力昂贵，故引入层次化设计：用窗大小为 $P_i\times P_i$ 的 patch merging 层（含一次卷积 + LayerNorm）逐步聚合相邻时频单元；每个尺度后接一个双路径 Conformer 模块（第一层在该频带内建模时间依赖，第二层在同一帧内建模跨频带相关）；对称的反卷积解码器用 patch expanding 层还原原始分辨率。
- 与三路径方法（[[方向/AI语音/模型/TF-GridNet|TF-GridNet]] 类，[5][6]）的差别：不加第三条路径，靠层次化把 MACs 压下来；与传统双路径方法（只在时间轴上做 chunk 内/间）的差别：UniArray 的双路径明确沿**时间轴 + 频率轴**。
- 训练：SI-SDR 损失 + uPIT，目标为干净混响语音，100 epochs；STFT 用 32 ms Hanning 窗、16 ms 帧移；局部模式提取器核 5、步长 1；字典规模 $N$ 与谱嵌入维度 $E$ 均为 64；三个 patch merging 窗为 $[1\times1,2\times2,2\times2]$；Conformer 配置同 [10]。

## 3. 核心公式

**1. 虚拟麦克风在真实麦克风对之间的分配（式 1–2）：**

$$n_i=\left\lfloor \frac{N_v}{N_p}\right\rfloor+\epsilon(i),\qquad \epsilon(i)=\begin{cases}1, & i\le N_v \bmod N_p\\[2pt] 0, & i> N_v \bmod N_p\end{cases}$$

$n_i$ 为第 $i$ 对真实麦克风分到的虚拟麦克风数量，$N_v$ 为需生成的虚拟麦克风总数，$N_p$ 为真实麦克风对数（相邻配对、首尾成对，故 $N_p=C$）；$\epsilon(i)$ 让**前 $N_v \bmod N_p$ 对**各多分一个虚拟麦克风，实现均匀分配。

**2. SDL 空间嵌入与幅度加权（式 3–5）：**

$$\tilde a_n(t,f)=\frac{\langle \mathbf d^{(n)},\mathbf x(t,f)\rangle}{\lvert \mathbf d^{(n)}\rvert\,\lvert \mathbf x(t,f)\rvert},\qquad a_n(t,f)=x_{\mathrm{avg}}(t,f)\cdot \tilde a_n(t,f),\qquad x_{\mathrm{avg}}(t,f)=\frac{1}{M}\sum_{i=1}^{M}\lvert x_i(t,f)\rvert$$

$\mathbf x(t,f)=[x_1(t,f),\dots,x_M(t,f)]$ 为帧 $t$、频点 $f$ 上的 $M$ 维复向量，$\mathbf d^{(n)}$ 为字典第 $n$ 项，$\lvert\cdot\rvert$ 为欧氏范数；归一化的投影 $\tilde a_n$ 把复向量投到超球面，$x_{\mathrm{avg}}$ 为各通道时频点平均幅度（论文记 $x_{\mathrm{avg}}(t,f)=\frac{1}{M}\sum_i\lvert x_i(t,f)\rvert$），二者相乘得到最终空间嵌入 $a_n(t,f)$。注：纯文本来源对式 (3) 分子的内积/共轭写法有排版错乱（见「待验证」），此处按"归一化投影到超球面"的原文描述书写。

## 4. 结果口径

**实验设置**：按 [13] 生成**空间化 WSJ0-2mix**；8 麦圆阵、半径 5 cm、16 kHz；RT60 0.1–1.0 s；重叠语音比例 10%–100%；多通道扩散噪声由 Reverb Challenge 的 ambient noise 与 [36] 工具包生成，混响混合与噪声的 SNR 在 10–20 dB 随机采样。训练时由 8 麦圆阵按麦克风子集 {0,4}、{0,3,5}、{0,2,4,6}、{1,2,3,5,6,7} 派生额外几何，并置换麦克风通道以促使模型学习跨几何空间特征。测试同时覆盖 seen 与 unseen 几何，命名如 C-8-10（圆阵 8 麦、半径 10 cm）、L-2-5（线阵 2 麦、间距 5 cm）。基线：FasNet-TAC、[[方向/AI语音/模型/VarArray|VarArray]]、VarArray+CA（把 TAC 的平均换成通道注意力）、SDNet。指标：SI-SDRi、WB-PESQ、NB-PESQ、STOI。训练目标为**干净混响语音**。

**未见几何主结果**（Tab. II，仅列 SI-SDRi 的平均值；模型规模与 MACs 按 4 秒输入计）：

| 方法 | 未见几何平均 SI-SDRi | 参数量 (M) | MACs (G/s) |
| --- | --- | --- | --- |
| FasNet-TAC | 9.66 | 2.76 | 18.17 |
| VarArray | 9.41 | 2.77 | 0.75 |
| VarArray+CA | 9.28 | 7.13 | 1.84 |
| SDNet | 10.83 | 0.89 | 22.56 |
| UniArray + SDL | **13.46** | 7.20 | 12.96 |
| UniArray + FSDL | 13.27 | 7.46 | 12.96 |

- 未见几何测试集含 10 种：C-8-10 / C-8-4.25 / C-7-4.25 / C-6-4.25 / C-5-4.25 / C-4-4.25 / C-4-3 / C-3-3 / L-3-3 / L-2-5；UniArray(+SDL) 平均较 FasNet-TAC、SDNet 分别提升 **39.3%** 与 **24.3%**（论文口径，与上表 13.46/9.66、13.46/10.83 一致）。
- Seen 几何（Tab. I，篇幅所限只报 8/6/4/2 麦）：C-8-5 上 SI-SDRi **13.76**，较 FasNet-TAC（10.03）与 SDNet 分别提升 **37.2% / 23.7%**；即使降到 2 通道（L-2-10）仍有 **13.50**，较两者提升 **47.7% / 27.8%**（对应基线约 9.14 / 10.56 dB）。四个指标（WB-PESQ、NB-PESQ、STOI、SI-SDRi）全面领先。
- **FSDL 不如共享 SDL**：频率相关字典在 seen 与 unseen 上四个指标均略降，说明跨频带共享的 SDL 更稳、更有效。
- **算力**：UniArray 参数量大于 FasNet-TAC、SDNet，但 MACs（12.96）低于二者（18.17 / 22.56）。
- **消融结论**（Tab. III，正文口径）：① 同时去掉 VME 与 SDL 后 UniArray 仍优于全部基线 → 其架构优于"通道内/通道间交替"；② 去掉 VME 在"未见几何 + 未见通道数"上掉点 → VME 维持跨阵列一致性；③ 有 VME 时 SDL 进一步通过谱/空间独立学习与融合提升性能；④ 单通道输入下 FSDL 泛化良好且对多通道性能影响极小（VME 中 $i=j$ 时虚拟信号与真实信号相同），为统一多通道 AGA-SS 与单通道 SS 提供潜在方案。

## 5. 测试基准与性能

**测试基准**：仿真空间化 WSJ0-2mix（8 麦圆阵半径 5 cm 派生多几何，16 kHz，RT60 0.1–1.0 s，重叠率 10%–100%，扩散噪声 SNR 10–20 dB），训练目标为干净混响语音；测试覆盖 seen 与 unseen 圆阵/线阵共多种通道数与半径/间距；基线为 FasNet-TAC、VarArray、VarArray+CA、SDNet；指标 SI-SDRi、WB-PESQ、NB-PESQ、STOI，另比较参数量与 MACs（4 s 输入）。

**性能指标**：UniArray(+SDL) 在未见几何上平均 SI-SDRi 13.46、seen 几何 C-8-5 达 13.76（完整数字见「结果口径」，此处不重复）；相对基线增益与算力对比同样见该节。消融显示 VME 与 SDL 各有独立贡献，架构本身在两者都去掉时仍强于基线。

（来源：笔记正文「核心机制」「核心公式」「结果口径」，均取自 arXiv:2503.05110 v1 纯文本全文；元数据经 arXiv 摘要页核验，核验日期 2026-10-09）

## 6. 使用判断

- 适合：训练/部署中**阵列几何与通道数多变**、不愿逐阵列重训的多通道语音分离；想用频点级空间线索又不想付三路径算力代价的场景；需要把单通道与多通道分离统一到一个模型的探索。
- 不适合：固定阵列追求极限性能（可用几何先验的固定几何模型更划算）；增强/去噪口径（本文只做 2 说话人分离 + 干净混响目标，不含单说话人增强）；要拿真实录音做工程决策（全文仅仿真数据）。
- 风险：VME 依赖"相邻麦克风配对、首尾成对"的假设，而训练又刻意置换通道，两者相互作用原文未讨论，真实非均匀间距阵列下配对是否成立待验证；单通道能力靠 FSDL 与 VME 退化实现，机制普适性存疑；$N=64$、上限 $M=8$ 等超参未做敏感性分析；论文未给开源代码，Table I/III 数值细节需对照 PDF。

## 7. 关键来源

- [UniArray: Unified Spectral-Spatial Modeling for Array-Geometry-Agnostic Speech Separation（arXiv:2503.05110）](https://arxiv.org/abs/2503.05110)
  - 内容定位：原始论文摘要页（cs.SD / eess.AS，Submitted on 7 Mar 2025，v1 无修订；Comments 记为 "5 pages, Prepirnt"），本地纯文本全文（`2503.05110_UniArray.txt`）为机制/公式/结果口径的依据。
  - 用途：核验题名、作者与提交日期；提供 VME 分配公式、SDL 嵌入公式、实验设置与全部结果表。
  - 核验日期：2026-10-09
- [UniArray 正式出版 DOI](https://doi.org/10.1109/LSP.2025.3562949)
  - 内容定位：IEEE Signal Processing Letters 32 卷，2025，pp. 2164–2168；Crossref 返回的题名与五位作者和原文一致。
  - 用途：确认正式期刊收录，不再将其标为未发表预印本；本页实验数值仍明确取自 arXiv v1 全文。
  - 核验日期：2026-10-27

## 8. 相关对象

- [[方向/AI语音/模型/AmbiDrop|AmbiDrop]]：同属阵列无关阵营；AmbiDrop 走 Ambisonics 规范域 + 通道 dropout，UniArray 走 VME 通道补齐 + 固定维度空间字典，不做物理域变换。
- [[方向/AI语音/模型/Geo-DConv|Geo-DConv]]：显式坐标条件化阵营（需几何已知、把坐标喂给网络）；UniArray 不用坐标，靠字典嵌入吸收几何差异。
- [[方向/AI语音/模型/Spatial-Magnifier|Spatial-Magnifier]]：同样用虚拟麦克风，但目标是固定几何下少麦 → 全阵列 oracle 的空间上采样；UniArray 的 VME 服务于可变通道数的归一化。
- [[方向/AI语音/模型/REDnet|REDnet]]：同属"输入维度可变"路线，机制不同——REDnet 用递归编解码器同时容纳未知说话人数与可变麦数、不做通道补齐，UniArray 靠 VME 补齐后走固定维度空间字典。
- [[方向/AI语音/模型/TF-GridNet|TF-GridNet]]：三路径（intra/inter-channel 交替）路线的代表，是 UniArray 明确要替换掉的高算力范式。
- [[方向/AI语音/知识/技术路线/Array-Agnostic SE（阵列无关语音增强）|Array-Agnostic SE]]：UniArray 所属技术路线（本篇任务口径为分离，非增强）。
- [[方向/AI语音/知识/调研与地图/Array-Agnostic SE SOTA（阵列可变语音增强SOTA调研）|Array-Agnostic SE SOTA]]：UniArray 在仿真双人 AGA-SS 协议下的定量对比与边界。
- [[方向/AI语音/知识/调研与地图/Array Speech Enhancement Frontier（阵列语音增强前沿调研）|阵列语音增强前沿调研]]：本对象在"阵列无关 / 任意几何"阵营中的位置与横评上下文。
- [[方向/AI语音/知识/基础概念/Beamforming（波束形成）|Beamforming]]：VME 的技术出身（虚拟麦克风 + 波束形成文献）。
- [[方向/AI语音/评估/SI-SDR|SI-SDR]]：训练损失（SI-SDR + uPIT）与主指标 SI-SDRi 的来源。
- [[方向/AI语音/数据集/WHAM|WHAM]]：WSJ0-2mix 系的加噪同源数据线，对应本文使用的空间化 WSJ0-2mix。

## 9. 待验证

- 式 (3) 的确切书写（分子的内积/共轭形式、是否含常数因子、字典与向量的归一化顺序）——纯文本提取存在排版错乱，需对照 PDF 图 1 与公式原文。
- VME 的插值公式本体（相位/幅度的插值权重与参考对选择）纯文本未给出，仅知沿用 [22] 的插值式 VME。
- Tab. I（seen 几何）与 Tab. III（消融）的完整数值网格：纯文本按列/行错序，本页仅录入可由正文百分比反查核对的数字，其余需对照 PDF。
- 是否开源（论文与摘要页均未给代码链接）。
- 上限通道数 $M$、字典规模 $N$、patch 窗口等超参的敏感性；以及 VME 相邻配对假设与训练期通道置换的相互作用。
- 真实录音阵列（非均匀间距、非共面）上的表现——论文未做真实数据实验。
- 与 [[方向/AI语音/模型/AmbiDrop|AmbiDrop]] / [[方向/AI语音/模型/Geo-DConv|Geo-DConv]] 的同类对比（不同论文、不同数据集，本文未涉及）。
- 口径小出入：引言记"相对 triple-path 方法在 seen/unseen 上平均提升 24.9% / 24.3%"，而 III-C 节与 Tab. II 记相对 SDNet 平均提升 24.3%、相对 FasNet-TAC 39.3%；引言 24.9% 的参照对象原文未明说。

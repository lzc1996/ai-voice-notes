---
title: VM-UNSSOR
类型: 模型
发表时间: 2025-10
时间依据: arXiv 首次提交日（2025-10-10）；检索核到 ICASSP 2026 收录（IEEE Xplore 条目，页面未直连）
任务:
  - 语音分离
团队:
  - "[[方向/AI语音/团队/Z.-Q. Wang Group（Zhong-Qiu Wang 组）]]"
方法范式:
  - 判别式
  - 无监督
开放状态:
  - paper
aliases:
  - VM-UNSSOR
  - "VM-UNSSOR: Unsupervised Neural Speech Separation Enhanced by Higher-SNR Virtual Microphone Arrays"
  - 虚拟麦克风增强的无监督神经语音分离
tags:
  - 类型/对象
  - 方向/AI语音
  - 任务/语音分离
  - 主题/无监督学习
  - 主题/虚拟麦克风
---

# VM-UNSSOR

## 0. 背景

**问题现场**：无监督神经语音分离在训练期不需要干净标签，监督只能来自 mixture consistency（MC）约束，麦少时约束不足、甚至训不起来（UNSSOR 在 2 麦 determined 条件下崩到 −2.7 dB）。

**前序路线的缺口**：UNSSOR 只有物理麦通道参与 MC 损失，观测端信息量受限。

**VM-UNSSOR 的切入点**：不改分离网络、不加生成式先验，用 IVA 线性解混 + 伪逆回投合成一批 SNR 更高的虚拟麦克风，与物理麦拼接后送入分离 DNN，并把 MC 约束扩到虚拟通道（重加权 $\beta=0.02$）。

## 1. 身份

`VM-UNSSOR`（Unsupervised Neural Speech Separation Enhanced by Higher-SNR Virtual Microphone Arrays）是南方科技大学 SUSTech（Shulin He、Zhong-Qiu Wang）提出的**无监督神经语音分离**方法（ICASSP 2026；arXiv:2510.08914，2025-10-10 v1；会议收录信息经检索核对、页面未直连）。

它不改分离网络结构、也不加生成式先验，而是把经典 BSS 的输出用于**扩维观测端**：以线性空间解混器（IVA）对观测混合做线性投影，合成一批 **SNR 更高的虚拟麦克风（VM）**，与物理麦克风拼接后送入分离 DNN，并把 **mixture consistency（MC）约束**从物理通道扩到虚拟通道（机制见「核心机制」）。

边界：无监督口径指训练期**不需要干净标签**、监督来自 MC 约束，不是自监督 / 弱监督；严格任务是**分离（BSS）**、不是狭义 SE（标签不写 `任务/多通道增强`）；**需在目标域混合上跑**、不是 training-free；虚拟麦只是观测端的线性投影扩维、只用于算额外 MC loss（不作拟合目标），不引入额外硬件或干净数据；它与 [[方向/AI语音/模型/UniArray|UniArray]] 的 VME **同名异义**；[[方向/AI语音/模型/VM-ArrayDPS|VM-ArrayDPS]] 则把 IVA 输出当**扩散采样观测**、training-free，本方法用于**训练期损失**、需训分离器（区别见「相关对象」）；实验仅仿真 SMS-WSJ 两说话人（6 麦 / 2 麦）。

## 2. 核心机制

```text
物理麦混合 Y_R = [Y_1 … Y_Pr]（STFT 域）
  -> 线性空间解混器（IVA Gaussian；备选 spatial clustering / CACGMM）
       W(f)：频域解混矩阵 -> Ŝc(t,f) = wc(f)^H Y_R(t,f)
       A(f) = pinv(W(f)) -> 回投到每个物理麦：Vp,c(t,f) = Ap,c(f)·Ŝc(t,f)
     得 Q = C × Pr 条虚拟麦信号（更高 SNR，但仍由观测线性投影而来）
  -> 拼接观测 {O_k}_{k∈U}，U = R ∪ V，共 Pu = Pr + C·Pr 条通道（6 麦 2 人 = 18）
  -> 分离网络 g：每个说话人输出一个复数估计 Ẑ(c)
  -> 逐通道 FCP：用 Ẑ 的上下文估相对 RIR ĝ_k(c,f)，得该通道的说话人像 X̂_k^FCP
  -> 损失：L_VM = α·Σ_{k∈R} L_MC,k + β·Σ_{k∈V} L_MC,k（+ 可选 ISMS）
```

### 2.1. IVA 虚拟麦构造

- **解混**：IVA（Gaussian 源模型，`torchiva` 实现）估频域解混矩阵 $W(f)\in\mathbb{C}^{C\times P_r}$，$\hat S_c(t,f)=w_c(f)^H Y_R(t,f)$；备选 **spatial clustering**（CACGMM + 跨频对齐）。
- **回投（本方法的关键动作）**：用 $A(f)=\mathrm{pinv}(W(f))$ 把每个分离成分回投到**每一个物理麦**，$V_{p,c}(t,f)=A_{p,c}(f)\hat S_c(t,f)$，得 $Q=C\times P_r$ 条虚拟麦。若只回投参考麦（$Q=C$，即 3c 行的 8 通道配置），MC loss 会被参考麦偏置、性能下降（15.5 dB SI-SDR）。
- **源数设置**：over-determined 阵列跑 3 源 IVA 并丢掉最低能量估计；determined 阵列跑 2 源 IVA。IVA 的 STFT：256 ms 窗 / 32 ms 跳；SC 的 STFT：128 ms 窗 / 16 ms 跳。
- **为什么算虚拟麦**：既是观测的线性投影（满足同一混合模型 → 可进 MC），又比原混合更源主导（高 SNR 线索 → 当伪教师、给源对齐提示）。

### 2.2. 分离网络（物理 + 虚拟拼接输入）

- 输入是物理与虚拟观测的拼接 $\{O_k\}_{k\in\mathcal U}$：$k\in\mathcal R$ 取 $Y_k$，$k=(p,c)\in\mathcal V$ 取 $V_{p,c}$；6 麦 2 人时 18 条通道。
- 论文只称其为 neural separator $g$，结构与训练配方**沿用 UNSSOR 管线**（"the same separator and pipeline"）；正文未给网络结构细节。
- 训练超参（优化器、学习率调度、梯度裁剪、数据增强、数据划分、房间仿真、STFT 配置）均按 UNSSOR 配方；默认权重 $\alpha=1.0$（物理）、$\beta=0.02$（虚拟）。

### 2.3. 一致性约束与重加权

- **逐通道 FCP**：对每条通道 $k\in\mathcal U$，用估计 $\hat Z(c)$ 的长度 $E$ 上下文 $\tilde{\hat Z}(c,t,f)$ 最小二乘估相对滤波器 $\hat g_k(c,f)$，得该通道的说话人像 $\hat X_k^{\text{FCP}}(c,t,f)$（闭式解、逐频点独立）。
- **MC loss**：每个通道上要求"观测混合 ≈ 各说话人像之和"（实部 / 虚部 / 幅度三项加权 + 逐麦能量归一化）——这是无监督监督信号的全部来源。
- **重加权**：$\mathcal L_{\text{VM}}=\alpha\sum_{k\in\mathcal R}\mathcal L_{\text{MC},k}+\beta\sum_{k\in\mathcal V}\mathcal L_{\text{MC},k}$，$\beta$ 太大会让分离器去拟合解混器瑕疵（$\beta=1.0$ 时掉到 14.3 dB），默认 $\beta=0.02$。
- **ISMS**：前作 UNSSOR 用来抑制频率置换；本方法中虚拟麦已提供对齐线索，关掉更优（3f 行）。

## 3. 核心公式

**1. 说话人像混合模型（式 1）：**

$$Y_p(t,f) = \sum_{c=1}^{C} X_p(c,t,f) + \varepsilon_p(t,f)$$

$p$ 索引物理麦、$c$ 索引说话人、$t$ / $f$ 为帧与频点；$X_p(c)$ 是说话人 $c$ 在麦 $p$ 的混响像，$\varepsilon_p$ 吸收残余噪声与建模误差。目标是无监督估计参考麦上的说话人像 $\{X_1(c)\}_{c=1}^{C}$ 且**保留混响**。

**2. 相对 RIR 的短卷积近似（式 2–3）：**

$$\tilde X_1(c,t,f) = \big[X_1(c,t-A,f),\dots,X_1(c,t+B,f)\big]^{T} \in \mathbb{C}^{E},\quad E = A+B+1$$

$$X_p(c,t,f) \approx g_p(c,f)^{H}\,\tilde X_1(c,t,f)$$

小孔径阵列下，同一说话人在相邻麦的像可用短线性滤波器（相对 RIR $g_p(c,f)$）近似——这是 FCP 约束成立的前提。

**3. 逐通道 FCP 估计相对 RIR 与说话人像（式 4–5，虚拟通道为式 12–13）：**

$$\hat g_k(c,f) = \arg\min_{g_k(c,f)} \sum_t \Big| O_k(t,f) - g_k(c,f)^{H}\tilde{\hat Z}(c,t,f) \Big|^2,\qquad \hat X_k^{\text{FCP}}(c,t,f) = \hat g_k(c,f)^{H}\tilde{\hat Z}(c,t,f)$$

闭式解；$O_k$ 在物理通道上是 $Y_k$，在虚拟通道上是 $V_{p,c}$。

**4. MC loss（式 6–7，无监督的损失定义）：**

$$\mathcal L_{\text{MC}} = \sum_{k\in\mathcal U} \mathcal L_{\text{MC},k},\qquad \mathcal L_{\text{MC},k} = \sum_{t,f}\Big[ w_r\,\mathcal R\big(\Delta_k\big) + w_i\,\mathcal I\big(\Delta_k\big) + w_m\,\big(|Y_k| - \big|\textstyle\sum_c \hat X_k^{\text{FCP}}(c)\big|\big) \Big]$$

其中 $\Delta_k = O_k(t,f) - \sum_c \hat X_k^{\text{FCP}}(c,t,f)$，$\mathcal R/\mathcal I$ 取实部 / 虚部，$(w_r,w_i,w_m)$ 控制三项权重，并做逐麦能量归一化。约束只在"重建观测"这一条上，因此不需要干净标签。

**5. ISMS loss（式 8，前作引入、本方法可关）：**

$$\mathcal L_{\text{ISMS}} = \frac{1}{tC}\sum_{c=1}^{C} \frac{\mathrm{var}\big(\log|\hat X_p^{\text{FCP}}(c,t,\cdot)|\big)}{\mathrm{var}\big(\log|Y_p(t,\cdot)|\big)}$$

逐源要求幅度谱沿频率有"散布"而非平坦，从而抑制跨频置换。

**6. IVA 虚拟麦与回投（式 9–11）：**

$$\hat S_c(t,f) = w_c(f)^{H} Y_R(t,f),\qquad V_{p,c}(t,f) = A_{p,c}(f)\,\hat S_c(t,f),\qquad O_k = \begin{cases} Y_k, & k\in\mathcal R\\ V_{p,c}, & k=(p,c)\in\mathcal V\end{cases}$$

$Y_R$ 堆叠 $P_r$ 条物理麦，$A(f)$ 为 $W(f)$ 的伪逆；虚拟麦数是 $Q=C\times P_r$，总输入 $P_u=P_r(1+C)$。

**7. 物理 / 虚拟重加权总损失（式 14）：**

$$\mathcal L_{\text{VM}} = \alpha\sum_{k\in\mathcal R}\mathcal L_{\text{MC},k} \;+\; \beta\sum_{k\in\mathcal V}\mathcal L_{\text{MC},k}$$

$\alpha$（物理）与 $\beta$（虚拟）为可调权重，默认 $\alpha=1.0$、$\beta=0.02$。

## 4. 结果口径

**实验设置**：SMS-WSJ 两说话人语料；训练 / 验证 / 测试集、房间仿真设置与 STFT 配置**全部沿用 UNSSOR**。默认 6 条物理麦（UNSSOR 基线也在 6 麦上训练与评测）；虚拟麦由 IVA 合成，$C=2$、$P_r=6$ → $Q=12$、$P_u=18$。**2 麦实验取 6 麦录音的第 0 与第 3 通道**。指标为官方测试集上平均的 SDR、SI-SDR、NB-PESQ、STOI、eSTOI。

### 4.1. 6 麦 2 人（Table 1，主表 + 消融）

| 行 | 系统 | 输入通道 | VM-loss 通道 | β | ISMS | SI-SDR | SDR | NB-PESQ | STOI | eSTOI |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 0a | Mixture（未处理） | - | - | - | - | 0.0 | 0.1 | 1.87 | 0.603 | 0.722 |
| 1a | Demixer-only（IVA Gaussian） | 6 | - | - | - | 13.4 | 14.8 | 3.08 | 0.866 | 0.948 |
| 1b | ArrayDPS（引用分数） | 6 | - | - | - | 16.2 | 16.9 | 3.49 | 0.884 | - |
| 2a | UNSSOR | 6 | - | - | 开 | 14.7 | 15.5 | 3.42 | 0.887 | 0.956 |
| 2b | UNSSOR + VM-loss | 6 | 18 | 0.02 | 开 | 14.9 | 15.7 | 3.50 | 0.893 | 0.958 |
| 2c | UNSSOR + VM-loss | 6 | 18 | 0.02 | 关 | 15.3 | 16.2 | 3.49 | 0.902 | 0.963 |
| 3a | UNSSOR + VM-input | 18 | - | - | 开 | 16.6 | 17.6 | 3.55 | 0.912 | 0.966 |
| 3b | UNSSOR + VM-input + VM-loss | 18 | 18 | 0.02 | 开 | 16.7 | 17.7 | 3.57 | 0.914 | 0.967 |
| 3c | 仅回投参考麦（8 通道） | 8 | 8 | 0.02 | 开 | 15.5 | 16.4 | 3.52 | 0.906 | 0.965 |
| 3d | VM-UNSSOR | 18 | 18 | 1.00 | 关 | 14.3 | 15.9 | 3.36 | 0.885 | 0.954 |
| 3e | VM-UNSSOR | 18 | 18 | 0.06 | 关 | 16.8 | 17.8 | 3.58 | 0.915 | 0.967 |
| 3f | **VM-UNSSOR（最优）** | 18 | 18 | 0.02 | 关 | **17.1** | **18.0** | **3.59** | **0.918** | **0.969** |

（α 在全部行均为 1.0；"β" 列即虚拟麦权重）

- **只加 VM-loss 不加 VM 输入**（2b/2c）：SI-SDR 14.7 → 14.9 / 15.3 dB，SDR 15.5 → 15.7 / 16.2 dB——虚拟麦即便不进输入也能加强约束。
- **只加 VM 输入**（3a）：SI-SDR 16.6、SDR 17.6 dB；**输入 + 损失合用**（3b）再到 16.7 / 17.7 dB。
- **ISMS 关掉更好**（3b → 3f：16.7 → 17.1 dB；2b → 2c：14.9 → 15.3 dB）；论文解释虚拟麦已提供源主导与对齐线索，ISMS 反而把幅度压得过于平坦、妨碍修正解混器瑕疵。
- **回投全部物理麦 vs 只回投参考麦**（3f vs 3c）：17.1 vs 15.5 dB；论文归因于后者把 MC loss 偏置在参考麦上，全麦回投保持了 MC 平衡。
- **β 的取舍**：β=0.02 最优（17.1 dB），0.06 → 16.8 dB，1.00 → 14.3 dB——β 越大越是在拟合解混器瑕疵。

### 4.2. 解混器对比（Table 2，6 麦 2 人，SI-SDR / dB）

| 系统 | Demixer | 输入通道 | SI-SDR |
| --- | --- | --- | --- |
| Demixer-only | SC | - | 7.4 |
| Demixer-only | IVA | - | 13.4 |
| VM-UNSSOR | SC | 18 | 16.9 |
| VM-UNSSOR | IVA | 18 | 17.1 |

解混质量越好、虚拟麦越好 → 分离越好；方法本身与不同解混器兼容。

### 4.3. determined 2 麦 2 人（Table 3，SI-SDR / dB）

| 系统 | Demixer | 输入通道 | SI-SDR |
| --- | --- | --- | --- |
| Demixer-only | SC（2 麦） | - | 6.2 |
| Demixer-only | IVA（2 麦） | - | 9.1 |
| UNSSOR | - | 2 | -2.7（训不起来） |
| VM-UNSSOR | SC | 6（2 物理 + 4 虚拟） | -0.8 |
| VM-UNSSOR | IVA | 6（2 物理 + 4 虚拟） | 10.7 |

论文的"卖点"行：UNSSOR 在 determined 条件下崩到 −2.7 dB，VM-UNSSOR 用 IVA 虚拟麦拉到 10.7 dB；换 SC 虚拟麦仍失败（−0.8 dB），论文归因于 SC 的虚拟麦质量不足、高 SNR 线索不够稳定训练。

## 5. 测试基准与性能

**测试基准：** 唯一语料 **SMS-WSJ**（两说话人），训练 / 验证 / 测试划分、房间仿真与 STFT 配置沿用 UNSSOR；默认 6 物理麦（$P_r=6$、$C=2$、$Q=12$、$P_u=18$，IVA Gaussian 解混器），另测 determined 2 麦（取 6 麦录音第 0、3 通道）与 spatial clustering 解混器。基线：未处理混合、demixer-only（IVA / SC）、UNSSOR，以及**引用其已发表配置与分数的 ArrayDPS**。指标：SDR、SI-SDR、NB-PESQ、STOI、eSTOI（官方测试集平均）。无监督：训练不需要干净参考，也不需要额外硬件麦克风。

**性能指标：** 完整数字见「结果口径」（6 麦 2 人最优 17.1 dB SI-SDR / 18.0 dB SDR，UNSSOR 14.7 / 15.5；2 麦 2 人 10.7 dB vs UNSSOR −2.7 dB；β 消融 0.02 最优；ISMS 关掉更好），此处不重复。

（来源：笔记正文「结果口径」，核验日期 2026-10-09）

## 6. 使用判断

- 适合：**麦少的阵列也能做无监督分离**——只有 2 麦、又没有干净标签时，UNSSOR 会训不起来，本方法用 IVA 虚拟麦补上约束；也适合需要**在目标域混合上快速自适配**（no labeled data、no extra hardware）的场合。配套要求是**得有能跑的 IVA（或等价的线性解混器）**。
- 适合研究用法：作为"**用经典 BSS 输出扩维观测端**、而不是改网络结构"的范例——与 [[方向/AI语音/模型/VM-ArrayDPS|VM-ArrayDPS]] 把同一思路搬进扩散后验采样形成对照。
- 不适合：想要 training-free（本方法要训练分离器）、想要去混响（目标是保留混响的说话人像）、以及解混器失效的场景（SC 在 2 麦下把方法拖崩，说明虚拟麦质量是硬前提）。
- 风险：ArrayDPS 一行是**引用分数**而非同条件复跑（见「待验证」）；只在 SMS-WSJ 仿真集上验证，未见真实录音 / 会议阵列 / 中文场景；**β 的最优值依赖解混器质量**，换阵列或换解混器需重调。

## 7. 关键来源

- [VM-UNSSOR: Unsupervised Neural Speech Separation Enhanced by Higher-SNR Virtual Microphone Arrays（arXiv:2510.08914）](https://arxiv.org/abs/2510.08914)
  - 内容定位：原始论文（会议版信息见下条）；v1 于 2025-10-10 提交。
  - 用途：题名、作者、公式（式 1–14）、Table 1–3 的全部数字。
  - 核验日期：2026-10-09
- [IEEE Xplore：ICASSP 2026 收录条目（document 11464236）](https://ieeexplore.ieee.org/abstract/document/11464236)
  - 内容定位：会议收录信息（ICASSP 2026）。
  - 用途：确认会议与年份；**本页未能直连该页**（网络策略拦截），收录信息由检索结果核对，页码等细节待补。
  - 核验日期：2026-10-09
- [arXiv PDF（arXiv:2510.08914）](https://arxiv.org/pdf/2510.08914)
  - 内容定位：同论文全文 PDF。
  - 用途：表格与公式细节复核入口（本页正文数字来自论文纯文本抽取）。
  - 核验日期：2026-10-09

## 8. 相关对象

- [[方向/AI语音/知识/基础概念/SS（语音分离）|SS]]：本方法严格所属的任务口径（无监督盲分离，不是狭义 SE）。
- [[方向/AI语音/模型/VM-ArrayDPS|VM-ArrayDPS]]：**同一条"IVA 虚拟麦"线的另一支，但训练口径完全不同**——VM-UNSSOR 用虚拟麦扩 **MC 训练损失**（要训一个分离 DNN，无先验、无扩散）；VM-ArrayDPS 把 IVA 输出当**虚拟麦观测**写进扩散后验采样的似然（training-free、无判别式前端，$Q=0$ 退化为 [[方向/AI语音/模型/ArrayDPS|ArrayDPS]]）。两者对虚拟麦条数 / 权重的取舍也不同（本文 β=0.02、无条数上限，VM-ArrayDPS 默认 2 条、β=0.5）。
- [[方向/AI语音/模型/ArrayDPS|ArrayDPS]]：同组同任务的无监督盲分离扩散路线，本页 Table 1 的对照行；但该行数字是**引用**其已发表配置与分数（vault 中该页记为 3 通道 SMS-WSJ 口径），不是同条件复跑。
- [[方向/AI语音/模型/ArrayDPS-Refine|ArrayDPS-Refine]] / [[方向/AI语音/模型/Uni-ArrayDPS|Uni-ArrayDPS]]：同族不同分支——Refine / Uni 是"判别式前端 + 生成式精修"，本方法没有前端也没有精修，是自己训练的无监督分离器。
- [[方向/AI语音/模型/UniArray|UniArray]]：**"虚拟麦克风"同名异义**——UniArray 的 VME 是在真实麦对之间**插值**生成虚拟麦以归一化通道数（固定几何、阵列无关泛化）；本方法的虚拟麦是**线性解混器的回投投影**（提升 SNR / 增加 MC 约束），目的与构造都不同。
- [[方向/AI语音/模型/USDnet++|USDnet++]]：同组、同"无监督 + 线性预测约束（FCP / 前向滤波）"血脉（论文引 FCP 源流时正引到 USDnet 一系）；区别是任务为去混响。
- [[方向/AI语音/数据集/SMS-WSJ|SMS-WSJ]]：唯一评测语料。
- [[方向/AI语音/评估/SI-SDR|SI-SDR]]、[[方向/AI语音/评估/PESQ|PESQ]]、[[方向/AI语音/评估/STOI 与 ESTOI|STOI 与 ESTOI]]：报告的主指标（另有 SDR）。
- [[方向/AI语音/团队/Z.-Q. Wang Group（Zhong-Qiu Wang 组）|Z.-Q. Wang Group]]：提出团队（SUSTech）。
- [[方向/AI语音/知识/技术路线/Real-Data Array SE（真实数据驱动阵列增强）|Real-Data Array SE]]：本方法"无标签、在目标域混合上直接训"的路线归属。
- [[方向/AI语音/知识/调研与地图/Array Speech Enhancement Frontier（阵列语音增强前沿调研）|阵列语音增强前沿调研]]：无监督（UNSSOR / IVA 虚拟麦）线的跟踪入口。

## 9. 待验证

- **前作 UNSSOR**（NeurIPS 2023，Wang & Watanabe）在 vault 中**暂无独立页**，本页只能在正文里写名字，未建 wikilink；待建页后补链，并把"MC loss / ISMS"细节移到前作页。
- **公式符号**：式 (14) 的两个权重符号在论文纯文本抽取中丢失，本页按 Table 1 表头（"/ weight physical/virtual microphones"）与正文"1.0 for physical / 0.02 for virtual"写成 $\alpha$ / $\beta$；原符号名待与 PDF 复核。
- **式 (7) 的 MC loss 三项**：纯文本抽取中实部 / 虚部项是否带 $|\cdot|$ 包裹有歧义，本页只复刻可确证的结构，具体形式待与 PDF 复核。
- **ArrayDPS 对照行的口径**：Table 1 的 ArrayDPS 数字（SI-SDR 16.2 / SDR 16.9 / PESQ 3.49 / STOI 0.884）是**引用其已发表配置与分数**（论文原话），而 vault 中 [[方向/AI语音/模型/ArrayDPS|ArrayDPS]] 页记的是 **3 通道** SMS-WSJ 口径——两处数字一致（16.2 / 16.9）但通道数不同，是否真为"同一六麦设置"下的可比对照，待核。
- **运行成本**：论文未报告 RTF / 运行时间 / 参数量 / 训练时长 / GPU——无监督训练 + IVA 前端的实际开销未知。
- **是否开源**：正文与结论均未给代码 / 权重链接（待核）。
- **网络结构细节**：分离器只说"沿用 UNSSOR 的 same separator and pipeline"，论文正文未给架构、层数、参数量。
- **真实数据与扩展场景**：仅在 SMS-WSJ 两说话人仿真集（6 麦 / 2 麦）验证；无真实录音、会议阵列（CHiME / RealMAN 类）、中文场景，也未见 3 说话人 / 更多源实验。
- **听感指标**：只报 NB-PESQ / STOI / eSTOI，未见 DNSMOS / UTMOS / NISQA 类感知或自然度指标。

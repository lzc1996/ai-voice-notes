---
title: VM-ArrayDPS
类型: 模型
发表时间: 2026-10
时间依据: arXiv 首次提交日
任务:
  - 语音分离
团队:
  - "[[方向/AI语音/团队/Z.-Q. Wang Group（Zhong-Qiu Wang 组）]]"
方法范式:
  - 生成式-扩散
  - 无监督
开放状态:
  - paper
aliases:
  - VM-ArrayDPS
  - "VM-ArrayDPS: Virtual Microphone Augmented Diffusion Posterior Sampling for Unsupervised Blind Speech Separation"
  - 虚拟麦克风增强的扩散后验采样
tags:
  - 类型/对象
  - 方向/AI语音
  - 任务/语音分离
  - 主题/扩散模型
  - 主题/虚拟麦克风
---

# VM-ArrayDPS

## 0. 背景

**问题现场**：无监督盲语音分离——阵列几何、RIR、声源均未知，且没有配对干净分离目标可供训练。

**前序路线的缺口**：ArrayDPS 的多通道一致性（MC）引导在麦少、观测低 SNR 时失效，其 IVA 输出仅用于 warm initialization，未被充分利用。

**VM-ArrayDPS 的切入点**：不改先验而在观测端扩维——把 IVA 空间解混输出提升为虚拟麦克风观测，与物理麦观测一起写进加权 MC 目标（权重 $\beta$），在整个扩散后验采样过程中持续引导源恢复，$Q=0$ 时退化为 ArrayDPS。

## 1. 身份

`VM-ArrayDPS`（Virtual Microphone Augmented Diffusion Posterior Sampling for Unsupervised Blind Speech Separation）是南方科技大学（SUSTech）计算机科学与工程系 Z.-Q. Wang 组（Jingqi Sun、Haozhan Tang、Shulin He、Zhong-Qiu Wang）提出的**无监督盲语音分离（BSS）**方法（投稿 ICASSP 2027，under review；arXiv:2610.09334v1，2026-10-07 首次提交）。

针对 [[方向/AI语音/模型/ArrayDPS|ArrayDPS]] 的多通道一致性（MC）引导在麦少、观测低 SNR 时失效的问题，它不改先验而在观测端扩维：把 IVA 空间解混的输出提升为**虚拟麦克风观测**，与物理麦观测一起写进**加权 MC 目标**，在**整个扩散后验采样**过程中持续引导源恢复，不加训练、不需干净分离目标（机制见「核心机制」）。

边界：与 [[方向/AI语音/模型/ArrayDPS|ArrayDPS]] 是**扩展 / 增强版，不是独立工作**——机制上的唯一改动在观测端：ArrayDPS 把 IVA 输出仅用于 warm initialization，本文把它当作虚拟麦观测、全程参与后验采样，$Q = 0$ 时恢复原 ArrayDPS。与 ArrayDPS-Refine / Uni-ArrayDPS 的分支区别见「相关对象」；不引入额外物理麦（虚拟麦是现有麦信号的线性空间变换），阵列几何 / RIR / 声源均未知；严格任务是**分离（SS），不是 SE**（任务标签不写 `任务/多通道增强`），评估目标是**混响说话人像**而非去混响性能；数据仅 SMS-WSJ 仿真集（2 / 3 说话人）。

## 2. 核心机制

```text
少量物理麦克风观测 y_1:M
  -> 对物理麦信号做 IVA 频域空间解混 -> 分离输出 v_1:Q（源导向、目标干扰比更高）
                                      = 「虚拟麦克风」观测
  -> 每个扩散步（EDM 采样）：
       1. 单通道语音扩散先验 -> Tweedie 去噪估计 ŝ_σ
       2. FCP 分别估计两条映射：s -> 物理麦 ĥ_{m,c}，s -> 虚拟麦 ĝ_{j,c}
       3. 用当前 ŝ_σ 重建 ŷ_1:M 与 v̂_1:Q，得两套多通道一致性重建误差
       4. 似然 score = −γ(σ)∇Σ_m‖y_m − ŷ_m‖² − β·γ(σ)∇Σ_j‖v_j − v̂_j‖²
       5. 先验 score + 似然 score -> EDM 反向步更新 s_σ
  -> 每条语音跑 5 次采样，按 AVG / Max / ML 三种策略选输出
```

### 2.1. 虚拟麦克风构造（IVA → 虚拟麦）

- 对物理麦克风信号做 **IVA**（频域空间解混滤波器），得到分离信号 $v_j(t)$。相比原始混合，这些输出**更源导向、目标干扰比更高**。
- 之所以叫"虚拟麦克风"：它们不对应任何额外的物理麦位置，而是对现有物理麦信号做**线性空间变换**得到的，因此可以写进**同一套前向声学模型**（$v_j$ 被建模为各源经滤波器 $g_{j,c}$ 卷积求和）。
- 条数上限：$M$ 个物理麦 × $C$ 个源 → 最多 $M \times C$ 条虚拟观测；实践中只用**少量**（默认 2 条）以限制额外计算量。

### 2.2. 虚拟麦克风一致性（加权 MC 目标）

- 把物理与虚拟观测写进**同一个观测似然**：给定源估计时假设两者条件独立，似然 score 变成两组重建误差之和。
- **必须加权**：IVA 输出可能含残留干扰或伪影，强制"完全一致"反而有害。因此引入相对权重 $\beta$，只让虚拟麦项以 $\beta$ 倍参与。
- 论文的经验结论：$\beta = 0.5$ 足够；降到 0.1 明显掉点（SI-SDR 15.5 dB、eSTOI 0.868）——即"把虚拟麦当成完全可靠的测量"不如给它一个中等权重。

### 2.3. 采样、样本选择与实现

- 采样器：**EDM sampler**；先验：预训练**单通道**语音扩散模型；两者配置与权重均从 ArrayDPS 公开实现继承。
- IVA 在采样前跑一次得到虚拟麦；之后每个扩散步都重估 FCP 滤波并重算两组重建误差（Fig. 1 的梯度计算流程）。
- 每条语音**采样 5 次**，三种选择策略：**AVG**（5 个输出求平均）、**Max**（选 SI-SDR 最高的输出）、**ML**（选似然 score 最高的输出）。三种策略在 2 说话人与 3 说话人两组实验上都跑了，用于确认虚拟麦的收益不依赖某一种选择策略。
- **无监督**：不为 VM-ArrayDPS 做任何额外监督训练；网络侧只有一个现成的干净语音扩散先验。

## 3. 核心公式

**1. 盲多通道混合模型（式 1）：**

$$y_m(t) = \sum_{c=1}^{C} h_{m,c}(t) * s_c(t) + n_m(t)$$

$s_c(t)$ 为第 $c$ 个源信号，$h_{m,c}(t)$ 为它到麦克风 $m$ 的房间冲激响应（RIR），$*$ 为卷积，$n_m(t)$ 为加性噪声。盲分离下**源与声学滤波器都不已知**。目标是采样自后验 $p(s_{1:C} \mid y_{1:M})$。

**2. 后验 score 分解与 Tweedie 先验 score（式 3、4）：**

$$\nabla_{s_\sigma} \log p(s_\sigma \mid y) = \nabla_{s_\sigma} \log p(s_\sigma) + \nabla_{s_\sigma} \log p(y \mid s_\sigma), \qquad \nabla_{s_\sigma} \log p(s_\sigma) = \frac{\hat{s}_\sigma - s_\sigma}{\sigma^2}$$

$\sigma$ 为扩散噪声水平；第一项是先验 score，由预训练扩散模型给出的去噪估计 $\hat{s}_\sigma$ 经 Tweedie 公式估计——该项把恢复信号拉回"像语音"的流形上。

**3. 物理麦克风重建与 MC 似然 score（式 5、6、7）：**

$$\hat{y}_m(t) = \sum_{c=1}^{C} \big(\hat{h}_{m,c} * \hat{s}_c\big)(t), \qquad -\log p(y \mid s_\sigma) \propto \sum_{m=1}^{M} \big\| y_m - \hat{y}_m(s_\sigma) \big\|_2^2$$

$$\nabla_{s_\sigma} \log p(y \mid s_\sigma) \approx -\,\gamma(\sigma)\, \nabla_{s_\sigma} \sum_{m=1}^{M} \big\| y_m - \hat{y}_m(s_\sigma) \big\|_2^2$$

用估计的声学传递函数把源估计映射回各麦克风，在加性高斯观测噪声假设下负对数似然正比于重建误差；$\gamma(\sigma)$ 控制当前扩散水平下似然项的贡献强度。

**4. FCP 估计声学滤波器（式 8）：**

$$\hat{h}_{m,c}(f) = \arg\min_{h_{m,c}(f)} \sum_{\tau} \hat{\lambda}(\tau, f)\, \Big| Y_m(\tau, f) - h_{m,c}(f)^{H} \tilde{\hat{S}}_c(\tau, f) \Big|^2$$

在 STFT 域用 **FCP（Forward Convolutive Prediction）** 估计 $K$ 抽头、频率相关的滤波器：$Y_m(\tau,f)$ 为麦克风 $m$ 的观测，$\tilde{\hat{S}}_c(\tau,f)$ **堆叠所需的延迟帧**，$\hat{\lambda}$ 为观测相关的加权项。所得滤波器被当作 RTF 的频率相关近似，用于重建麦克风观测。

**5. 虚拟麦克风重建（式 9）：**

$$\hat{v}_j(t) = \sum_{c=1}^{C} \big(\hat{g}_{j,c} * s_c\big)(t)$$

对每条 IVA 输出 $v_j(t)$，同样用 FCP 估一个滤波器 $\hat{g}_{j,c}$，从当前源估计重建出 $\hat{v}_j$——这一步让虚拟麦进入**同一个前向声学模型**，从而可以不新增物理麦、不新增干净训练数据就施加额外约束。

**6. 虚拟麦克风一致性似然与权重 $\beta$（式 10、11）：**

$$\nabla_{s_\sigma} \log p(y, v \mid s_\sigma) \approx -\,\gamma(\sigma) \nabla_{s_\sigma} \sum_{m=1}^{M} \big\| y_m - \hat{y}_m \big\|_2^2 \;-\; \beta \cdot \gamma(\sigma) \nabla_{s_\sigma} \sum_{j=1}^{Q} \big\| v_j - \hat{v}_j \big\|_2^2$$

$v_{1:Q}$ 为 $Q$ 条虚拟麦克风信号。物理项保留原始空间混合信息，虚拟项提供源导向投影，两者互补；$\beta$ 为虚拟麦损失的相对权重（实验中在验证集上调），**$Q = 0$ 时该式退化为原 ArrayDPS 似然**。

## 4. 结果口径

**实验设置**：SMS-WSJ 语料；2 说话人测试集含 1,332 条混合，8 kHz。仿真阵列：六麦圆阵、直径 20 cm；源-阵距离 $U[1.0, 2.0]$ m；$T_{60}$ 0.2–0.5 s；加性白噪声 SNR 20–30 dB。按 ArrayDPS 设置**只用阵列子集**：2 说话人实验用 **3 个物理麦**，3 说话人实验用 **4 个物理麦**；3 说话人集按 SMS-WSJ 仿真流程自行扩展。每组 5 次采样，AVG / Max / ML 三策略。指标 SDR、SI-SDR、PESQ、eSTOI；**评估目标是混响说话人像**，故衡量分离质量而非去混响。

### 4.1. Table 1：3 通道 2 说话人 SMS-WSJ

VM-ArrayDPS 各配置均为 2 条虚拟麦、$\beta = 0.5$。

| 方法 | SDR (dB) | SI-SDR (dB) | PESQ | eSTOI |
| --- | --- | --- | --- | --- |
| Mixture | 0.1 | 0.0 | 1.87 | 0.603 |
| Spatial Clustering | 9.5 | 8.5 | 2.52 | 0.759 |
| IVA-Laplace | 12.0 | 10.7 | 2.67 | 0.802 |
| IVA-Gaussian | 13.4 | 12.2 | 2.82 | 0.834 |
| UNSSOR | 15.4 | 14.4 | 3.20 | 0.875 |
| ArrayDPS-AVG | 15.8 | 15.0 | 3.37 | 0.864 |
| **VM-ArrayDPS-AVG** | **16.9** | **16.1** | **3.45** | **0.881** |
| ArrayDPS-Max | 17.2 | 16.5 | 3.52 | 0.888 |
| **VM-ArrayDPS-Max** | **17.9** | **17.2** | **3.56** | **0.898** |
| ArrayDPS-ML | 16.9 | 16.2 | 3.49 | 0.883 |
| **VM-ArrayDPS-ML** | **17.7** | **17.0** | **3.53** | **0.894** |

三种选择策略下全部指标一致提升；Max 配置最优（SDR 17.9 dB / SI-SDR 17.2 dB）。传统空间聚类与 IVA 基线低于扩散类方法；UNSSOR（无监督神经分离）SI-SDR 14.4 dB 作为参考点。

### 4.2. Table 2：4 通道 3 说话人 SMS-WSJ

| 方法 | SDR (dB) | SI-SDR (dB) | PESQ | eSTOI |
| --- | --- | --- | --- | --- |
| Mixture | −3.0 | −3.2 | 1.57 | 0.458 |
| ArrayDPS-AVG | 11.5 | 10.5 | 2.82 | 0.763 |
| **VM-ArrayDPS-AVG** | **13.2** | **12.1** | **2.95** | **0.798** |
| ArrayDPS-Max | 13.1 | 12.2 | 3.00 | 0.798 |
| **VM-ArrayDPS-Max** | **14.1** | **13.2** | **3.07** | **0.822** |
| ArrayDPS-ML | 12.8 | 11.9 | 3.00 | 0.792 |
| **VM-ArrayDPS-ML** | **13.9** | **13.0** | **3.05** | **0.817** |

3 说话人比 2 说话人更欠定（4 麦 / 3 源），增益依然稳定：AVG 下 SDR +1.7 dB、SI-SDR +1.6 dB；Max 下 SDR 13.1 → 14.1 dB、eSTOI 0.798 → 0.822。

### 4.3. Table 3：消融（虚拟麦条数与权重 $\beta$，3 通道 2 说话人，AVG）

| 虚拟麦条数 | $\beta$ | SDR (dB) | SI-SDR (dB) | PESQ | eSTOI |
| --- | --- | --- | --- | --- | --- |
| 0 | — | 15.8 | 15.0 | 3.37 | 0.864 |
| 2 | 1.0 | 17.0 | 16.1 | 3.44 | 0.883 |
| 2 | 0.5 | 16.9 | 16.1 | 3.45 | 0.881 |
| 6 | 1.0 | 17.0 | 16.1 | 3.43 | 0.882 |
| 6 | 0.5 | 17.0 | 16.2 | 3.45 | 0.881 |
| 6 | 0.1 | 16.3 | 15.5 | 3.41 | 0.868 |

- **条数**：2 → 6 条没有进一步收益（$\beta=1.0$ 时都是 SDR 17.0 / SI-SDR 16.1）。论文解释：从同一批物理观测派生的通道越多，信息越冗余。
- **权重**：$\beta=1.0 \to 0.5$ 基本持平（PESQ 略升），$\beta=0.1$ 明显掉点。
- 据此定默认配置 **2 条虚拟麦 + $\beta = 0.5$**。

## 5. 测试基准与性能

**测试基准：** SMS-WSJ 语料，8 kHz；六麦圆阵（直径 20 cm，源距 1.0–2.0 m）、$T_{60}$ 0.2–0.5 s、白噪声 SNR 20–30 dB；只用阵列子集（2 说话人用 3 麦、3 说话人用 4 麦），3 说话人集按同一仿真流程扩展。基线：Mixture、Spatial Clustering、IVA-Laplace / IVA-Gaussian（经典空间方法）、UNSSOR（无监督神经分离）、以及**逐项对照的 ArrayDPS**（AVG / Max / ML 三种选择策略同口径）。指标 SDR、SI-SDR、PESQ、eSTOI，评估目标为混响说话人像。无监督：无额外监督训练，扩散先验与 EDM 配置沿用 ArrayDPS 公开实现，每个扩散步重估 FCP 滤波。

**性能指标：** 完整数字见「结果口径」（2 说话人：AVG SDR 15.8 → 16.9 dB；Max SDR 17.2 → 17.9 dB、SI-SDR 17.2 dB；ML SDR 16.9 → 17.7 dB。3 说话人：AVG SDR 11.5 → 13.2 dB、Max SDR 14.1 dB。消融：2 条虚拟麦已足，$\beta=0.5$ 最优，$\beta=0.1$ 掉点），此处不重复。

（来源：笔记正文「结果口径」，核验日期 2026-10-09）

## 6. 使用判断

- **适合**：物理麦少（实验中只用 3 个 / 4 个）、观测 SNR 偏低、且**已有可用的 IVA 解混**的无监督盲分离场景；没有配对训练数据、也不允许为任务训练判别式模型时；作为 ArrayDPS 的**即插替换**——同一扩散先验与采样器，只加观测端的虚拟麦项。
- **适合研究用法**：作为"如何在扩散逆问题里**扩充观测**而不是改进先验"的范例；同一思路（用经典算法输出当额外观测）可迁移到其他逆问题。
- **不适合**：实时 / 低算力部署——仍是多步 EDM 采样，且每个扩散步要重估物理 + 虚拟两套 FCP 滤波并反向传播；论文未报告运行时间 / RTF / NFE。
- **不适合**：需要去混响的场合——评估目标本身是混响说话人像，方法不做去混响。
- **风险**：
  - **Max 选择策略是 oracle 式**（按 SI-SDR 挑样本），部署时不可得；论文用三种策略并列来回避这一点，但 Table 1 的最优数字来自 Max。
  - 虚拟麦来自 IVA，**IVA 解混质量直接决定虚拟观测质量**；IVA 失效时 $\beta$-加权的项可能引入误导性约束。
  - 只在 SMS-WSJ 仿真集上验证（2 / 3 说话人），**未见真实录音、未见会议阵列、未见中文场景**。
  - 虚拟麦条数收益在 2 条即饱和，说明该机制的天花板受"观测同源"限制，不宜期待继续加麦带来线性提升。

## 7. 关键来源

- [VM-ArrayDPS: Virtual Microphone Augmented Diffusion Posterior Sampling for Unsupervised Blind Speech Separation（arXiv:2610.09334）](https://arxiv.org/abs/2610.09334)
  - 内容定位：原始论文；v1 提交于 2026-10-07，comments 注明"Submitted to ICASSP 2027 and currently under review"，无 journal ref / DOI。
  - 用途：虚拟麦构造、加权 MC 目标（式 9–11）、全部实验与消融数据。
  - 核验日期：2026-10-09
- [论文 PDF（arXiv:2610.09334）](https://arxiv.org/pdf/2610.09334)
  - 内容定位：同论文 PDF 全文，含 Table 1–3 与参考文献。
  - 用途：公式与表格细节核对。
  - 核验日期：2026-10-09

## 8. 相关对象

- [[方向/AI语音/模型/ArrayDPS|ArrayDPS]]：**直接前身与被扩展对象**——VM-ArrayDPS 沿用其扩散先验与 EDM 采样配置，把 IVA 输出从 warm initialization 提升为全程参与的虚拟麦观测；$Q=0$ 时退化为 ArrayDPS。
- [[方向/AI语音/模型/ArrayDPS-Refine|ArrayDPS-Refine]] / [[方向/AI语音/模型/Uni-ArrayDPS|Uni-ArrayDPS]]：同族不同分支——Refine / Uni 走"判别式前端 + 生成式精修"（SCM 定似然，面向 SE），VM-ArrayDPS 直接做无监督盲分离（白噪声重建似然 + 观测扩维）。
- [[方向/AI语音/模型/VM-UNSSOR|VM-UNSSOR]]：同属 IVA 虚拟麦线，用法相反——VM-UNSSOR 把虚拟麦信号当作**训练期 mixture-consistency 损失**的额外观察通道（需训分离器，重加权 $\beta=0.02$），VM-ArrayDPS 把 IVA 输出当作**扩散后验采样的观测**、不改训练（training-free）。
- [[方向/AI语音/知识/生成式语音增强/DPS（扩散后验采样）|DPS]]：本文似然引导的理论框架来源。
- [[方向/AI语音/知识/基础概念/Tweedie（Tweedie 公式）|Tweedie 公式]]：式 4 中先验 score 的估计方式。
- [[方向/AI语音/知识/生成式语音增强/SE Generative Prior（语音增强生成先验）|SE 语音增强生成先验]]：本文复用的单通道干净语音扩散先验所属的模型族。
- [[方向/AI语音/数据集/SMS-WSJ|SMS-WSJ]]：唯一评测语料。
- [[方向/AI语音/团队/Z.-Q. Wang Group（Zhong-Qiu Wang 组）|Z.-Q. Wang Group]]：提出团队（SUSTech）。
- [[方向/AI语音/知识/技术路线/Generative Multichannel SE（生成式多通道语音增强）|生成式多通道语音增强]]：本文所属的生成式多通道技术路线。
- [[方向/AI语音/知识/调研与地图/Array Speech Enhancement Frontier（阵列语音增强前沿调研）|阵列语音增强前沿调研]]：ArrayDPS 线（无监督扩散盲分离）的跟踪入口。

## 9. 待验证

- **运行成本**：论文未报告 RTF / 运行时间 / 采样步数 / NFE；每个扩散步要估两套 FCP 滤波并整体反向传播，实际开销未知。
- **是否开源**：正文只提到"inherit from the public ArrayDPS implementation"，未给出 VM-ArrayDPS 自身的代码或权重链接。
- **真实数据**：只在 SMS-WSJ 仿真集（2 / 3 说话人，8 kHz）验证；真实录音、会议阵列（CHiME / RealMAN 类）与中文场景的表现未知。
- **IVA 依赖**：IVA 解混失败或源数估计错误时，虚拟麦的 $\beta$ 项是否会主动伤害分离，论文未做失败案例分析。
- **观察到的符号**：论文 STFT 帧索引与扩散噪声水平在 PDF 文本中都排作 $\tau$，本笔记按论文原话"$\sigma$ is the diffusion noise level"区分写成 $s_\sigma$ / $Y_m(\tau,f)$；同一符号的原始排版待与 PDF 图 1 复核。
- **与 ArrayDPS 数字的细微差异**：本论文 Table 1 引用的 ArrayDPS 数字（ArrayDPS-AVG PESQ 3.37 / eSTOI 0.864；ArrayDPS-ML PESQ 3.49 / eSTOI 0.883）与 vault 中 [[方向/AI语音/模型/ArrayDPS|ArrayDPS]] 页所记（3.38 / 0.865；3.49 / 0.884）有 0.001 量级出入，疑为前作自身版本差异，待核。

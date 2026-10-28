---
title: Mask-based SE for Spatial Audio（掩蔽增强三域对比）
类型: 论文
证据角色: 对比评测型论文
发表时间: 2026-09
时间依据: arXiv 首次提交日（v1 2026-09-16，eess.AS）
核心假设: 时频掩蔽的空间保真代价取决于掩蔽施加在哪个信号域（麦克风通道 / 波束形成输出 / Ambisonics）；增强质量与空间保真之间是权衡而非同时最优
相关任务:
  - 语音增强
  - 空间音频
  - 双耳重放
相关基准:
  - 非公开基准：自建 Monte-Carlo 仿真场景（WSJ 语句 + image method RIR + Cologne HRTF）
相关评估:
  - "[[方向/AI语音/评估/PESQ]]"
  - "[[方向/AI语音/评估/SI-SDR]]"
  - "[[方向/AI语音/评估/STOI 与 ESTOI]]"
支持结论:
  - 波束形成域掩蔽（TFB）语音质量与可懂度最高，但混响保真与残余干扰 ILD 代价最大
  - "[[方向/AI语音/知识/基础概念/Ambisonics（球谐声场）|Ambisonics]] 域掩蔽（TFA）最保残余干扰的空间属性与场景混响"
  - 麦克风域掩蔽（TFM）的语音质量与可懂度在三域中最低，残余干扰 ΔITD 也最大
  - 三个域都保住目标说话人的 ITD / ILD（在知觉阈值内）
  - 期望信号必须取含混响目标，否则 C50 必然劣化
aliases:
  - TFM / TFB / TFA
  - "Mask-Based Speech Enhancement for Spatial Audio: A Comparison of Ambisonics, Beamforming, and Microphone Channels"
  - 掩蔽增强三域对比
  - 掩蔽域对比
tags:
  - 类型/对象
  - 方向/AI语音
  - 任务/语音增强
  - 主题/阵列信号
  - 主题/空间音频
---

# Mask-based SE for Spatial Audio（掩蔽增强三域对比）

> [!abstract] 这页的角色
> 这是**对比评测型论文证据页**：本文没有自命名模型，也不提出新网络。它把同一个 oracle 时频掩蔽分别施加到**麦克风通道 / 波束形成输出 / Ambisonics** 三个信号域，测量增强质量与空间保真的横向权衡。本页记录它的变量拆分、三域处理链、指标读数与可复用边界，**不**把它写成方法页或技术路线页。

## 1. 论文要解释什么

掩蔽式语音增强（mask-based SE）长期默认输出是单通道，评价也主要是 [[方向/AI语音/评估/PESQ]]、[[方向/AI语音/评估/STOI 与 ESTOI]]、[[方向/AI语音/评估/SI-SDR]] 这类"增强做得好不好"的指标。但空间音频应用（沉浸通信、AR/VR、助听、空间重放）要求多通道输出，且必须保住定位、场景感知、听者舒适度和空间释放效应（SRM）所依赖的空间线索。掩蔽会扭曲通道间空间信息。

定位：已有工作（如 Lugasi & Rafaely 2020，即原文 [1]）比较过**波束形成域**与 **Ambisonics 域**的掩蔽，但**没有系统比较过直接作用于麦克风通道的掩蔽**——而麦克风通道恰恰是最常见的信号表示。

一句话：**本文要回答的不是"怎么增强"，而是"掩蔽放在哪个域，增强收益与空间保真代价怎么分配"。**

## 2. 核心假设

| 假设 | 解释 | 需要实验验证什么 |
|---|---|---|
| H1：三域存在质量 / 空间保真权衡 | 掩蔽的空间代价取决于施加域，而非掩蔽本身 | TFB 是否质量最高、TFA 是否空间最好 |
| H2：目标说话人的空间线索在三域都不受损 | 目标是掩蔽要保留的成分，其双耳线索应被完整保留 | ΔITD / ΔILD 是否都在知觉阈值内 |
| H3：残余干扰的空间属性分域差异明显 | 干扰是掩蔽要压制的成分，各域的泄漏路径不同 | 干扰的 ΔITD / ΔILD 谁最低 |
| H4：期望信号定义会决定混响保真 | 用直达声当目标等于主动压掉晚混响 | C50 误差在 direct / reverberant 两种目标下的分裂 |

原文的四条 contribution 与上表对应：(i) 需要含混响的期望参考（原文写作 loss function 中的 reverberant desired reference）才能保住混响；(ii) 波束形成域掩蔽最保语音质量与可懂度；(iii) Ambisonics 域掩蔽最保残余干扰的空间属性；(iv) 所有域都保住了目标信号的空间线索。

## 3. 实验怎么设计

### 3.1. 变量拆分

原文 Table 1（Monte-Carlo 仿真，100 次实现）：

| 变量 | 取值 |
|---|---|
| 语音 | 10 条 WSJ 语句，fs = 16 kHz |
| 房间 | 三个矩形房间：10 × 6 × 3.2 m，T60 = 0.44；13 × 8 × 3.5 m，T60 = 0.56；20 × 10 × 4 m，T60 = 0.75（原文 T60 数值未标单位，按秒，待核） |
| SNR | 目标–干扰：{−20, −10, 0, 10} dB；目标–噪声：20 dB |
| DRR | {−5, 10} dB |
| 几何 | 目标–干扰方位角：{−100, 60} 度 |
| 期望信号 | 目标说话人的直达信号，或完整混响信号 |

场景构造：目标说话人固定在相对阵列 0 度方位，靠距离调 DRR；干扰说话人与目标等距、方位不同；一个白噪声点源放在房间角落以模拟高混响噪声场（总噪声 = 干扰说话人 + 稳态噪声）。RIR 用 [[方向/AI语音/知识/基础概念/ISM（Image Source Method，镜像声源法）]] 计算，声场在球谐域算到 N = 35 阶。每个实现的房间、几何、语音随机抽取，然后在全部 SNR / DRR / 期望信号组合上评估。

### 3.2. 三个域的处理链

三域共享同一条主干，差别只在掩蔽施加点（原文 Eq. 1–11）：

```text
基线表示：Ambisonics a_nm(f)          (Eq. 2)
  -> 解码到波束形成域 b(f) = D_Beam(f) a_nm(f)      (Eq. 4)
  -> 解码到麦克风域   x(f) = D_Mic(f)  a_nm(f)      (Eq. 5)
STFT 后各域乘对角掩蔽矩阵（IRM）：
  x̂ = M_Mic(ω,τ) x    a_hat = M_Amb(ω,τ) a_nm    b̂ = M_Beam(ω,τ) b   (Eq. 8–10)
  -> 回到时域
波束 / 麦克风域结果先反变换回球谐域（Eq. 6, 7）
  -> HRTF 双耳解码 b_l/r(f) = h~_l/r(f)^T a_nm(f)   (Eq. 11)
```

| 域 | 记号 | 掩蔽作用对象 | 该域的构造与规模 |
|---|---|---|---|
| 麦克风通道 | TFM | 麦克风信号 x(ω,τ) | 由 **N = 10 阶** Ambisonics 经 Eq. (5) 导出；刚性球阵列 r = 0.042 m |
| 波束形成输出 | TFB | 波束输出 b(ω,τ) | 由 N = 3 阶 Ambisonics 经 Eq. (4) 导出，用**最大指向性波束形成器**（原文 [1] 的实现） |
| Ambisonics | TFA | 球谐系数 a_nm(ω,τ) | Ambisonics 截断到 **N = 3（16 通道）**，原文称对应 Eigenmike32 这类实用系统 |

- **掩蔽模型**：三域都用实值 **理想比值掩蔽（IRM）**，用已知的期望 / 非期望成分计算，是 **oracle**，实际不可实现；原文明确把它当作"各表示的理论性能上界"，包括对 DNN 方法的上界。
- **下游**：没有 DNN，没有可学习模块。掩蔽后信号直接做双耳 HRTF 解码（Cologne HRTF 汇编 / Neumann KU-100 [23]）。
- **通道规模**：TFB 与 TFM 均为 Q = B = 24 路，采样方向按 spherical t-design 近似均匀分布；TFA 为 16 通道。
- 原文说明解码矩阵一般不保证可逆，但"在本设置下可逆性成立"，只有 Eq. (7) 的求逆可能引入少量误差。

### 3.3. 核心公式（原文 Eq. 1–11）

**三域信号模型（同构三分解：直达 + 混响 + 噪声/干扰）**：

$$\mathbf{x}(f)=\mathbf{x}^{\text{dir}}(f)+\mathbf{x}^{\text{rev}}(f)+\mathbf{n}(f) \tag{Eq.1}$$
$$\mathbf{a}_{nm}(f)=\mathbf{a}_{nm}^{\text{dir}}(f)+\mathbf{a}_{nm}^{\text{rev}}(f)+\mathbf{a}_{nm}^{\text{noise}}(f) \tag{Eq.2}$$
$$\mathbf{b}(f)=\mathbf{b}^{\text{dir}}(f)+\mathbf{b}^{\text{rev}}(f)+\mathbf{b}^{\text{noise}}(f) \tag{Eq.3}$$

其中 $\mathbf{x}(f)$ 为 $Q\times1$ 麦克风信号向量（麦克风位于半径 $r$ 的刚性球面，角度 $\Phi=(\theta_q,\phi_q)$）；$\mathbf{a}_{nm}(f)=[a_{00},a_{1(-1)},a_{10},\dots,a_{NN}]^T$ 为 $(N+1)^2\times1$ Ambisonics 球谐系数向量；$\mathbf{b}(f)$ 为 $B\times1$ 波束输出向量（每个朝向一个 look direction）。

**域间变换（球谐域为基准表示）**：

$$\mathbf{b}(f)=\mathbf{D}_{\text{Beam}}(f)\,\mathbf{a}_{nm}(f) \tag{Eq.4}$$
$$\mathbf{x}(f)=\mathbf{D}_{\text{Mic}}(f)\,\mathbf{a}_{nm}(f) \tag{Eq.5}$$
$$\mathbf{a}_{nm}(f)=\mathbf{D}^{-1}_{\text{Beam}}(f)\,\mathbf{b}(f)=\mathbf{D}^{-1}_{\text{Mic}}(f)\,\mathbf{x}(f) \tag{Eq.6,7}$$

其中 $\mathbf{D}_{\text{Beam}}(f)$、$\mathbf{D}_{\text{Mic}}(f)$ 为线性解码矩阵（最大指向性波束形成器实现沿用原文 [1]）。

**三域掩蔽（对角 IRM 矩阵，STFT 域 $(\tau,\nu)$）**：

$$\hat{\mathbf{x}}=\mathbf{M}_{\text{Mic}}(\tau,\nu)\,\mathbf{x},\qquad \hat{\mathbf{a}}_{nm}=\mathbf{M}_{\text{Amb}}(\tau,\nu)\,\mathbf{a}_{nm},\qquad \hat{\mathbf{b}}=\mathbf{M}_{\text{Beam}}(\tau,\nu)\,\mathbf{b} \tag{Eq.8–10}$$

其中 $\mathbf{M}_{\text{Mic}}$、$\mathbf{M}_{\text{Amb}}$、$\mathbf{M}_{\text{Beam}}$ 均为对角实值理想比值掩蔽（IRM）矩阵——掩蔽在各域是**逐通道独立**的，这是三域空间代价差异的来源。IRM 的具体计算式本文未印出，沿用原文 [1]（Lugasi & Rafaely 2020）的定义。

**双耳解码**（波束/麦克风域先经 Eq. 6/7 回到球谐域）：

$$b^{l/r}(f)=\tilde{\mathbf{h}}^{l/r}_{nm}(f)^{T}\,\mathbf{a}_{nm}(f),\qquad \tilde{h}^{l/r}_{nm}(f)=(-1)^{m}h^{l/r}_{n(-m)}(f) \tag{Eq.11}$$

其中 $\mathbf{h}^{l/r}_{nm}(f)$ 为 HRTF 的球谐域表示（Cologne / Neumann KU-100），$\tilde{\mathbf{h}}$ 为其对称化修改形式。

**期望信号的两种定义**（决定 IRM 的目标成分，见 §5.1）：

$$\text{直达目标：}\ \mathbf{a}^{d}_{nm}=\mathbf{a}_{nm}^{\text{dir}},\ \mathbf{a}^{u}_{nm}=\mathbf{a}^{\text{rev}}_{nm}+\mathbf{a}^{\text{noise}}_{nm};\qquad \text{混响目标：}\ \mathbf{a}^{d}_{nm}=\mathbf{a}_{nm}^{\text{dir}}+\mathbf{a}^{\text{rev}}_{nm},\ \mathbf{a}^{u}_{nm}=\mathbf{a}^{\text{noise}}_{nm}$$

## 4. 实验结果怎么读

### 4.1. 主结果

**C50 误差（dB，越低越好）**，参考为目标的混响信号；原文给出参考值：低 DRR 时全通道平均 C50 = 3.43 dB，高 DRR 时 = 12.92 dB（原文 [18] 给的 C50 恰可觉差 JND ≈ 1 dB）：

| 方法 | DRR = −5 dB，直达目标 | DRR = −5 dB，混响目标 | DRR = 10 dB，直达目标 | DRR = 10 dB，混响目标 |
|---|---:|---:|---:|---:|
| TFM | 3.00 | 0.41 | 2.91 | 0.92 |
| TFB | 9.00 | 0.58 | 7.95 | 1.63 |
| TFA | 3.72 | 0.40 | 3.20 | 0.82 |

**期望信号相关指标**（期望信号取混响目标，全场景平均）：

| 方法 | SI-SDR (dB) | ΔITD (µs) | ΔILD (dB) | ΔC50 (dB) | DBSTOI | PESQ |
|---|---:|---:|---:|---:|---:|---:|
| Noisy | −6.37 | – | – | – | 0.478 | 1.26 |
| TFM | 5.73 | 0 | 0.49 | 0.66 | 0.700 | 2.49 |
| TFA | 9.36 | 0 | 0.07 | 0.61 | 0.745 | 2.66 |
| TFB | 12.93 | 0 | 0.40 | 1.10 | 0.802 | 3.09 |

**残余干扰相关指标**（期望信号取混响目标，全场景平均）：

| 方法 | ΔITD (µs) | ΔILD (dB) |
|---|---:|---:|
| TFM | 463 | 6.67 |
| TFA | 43 | 3.31 |
| TFB | 186 | 7.72 |

知觉阈值按原文引用：ITD 约 100 µs，ILD 约 1 dB。

### 4.2. 结论对应

| 实验现象 | 支持的判断 | 证据强度 | 归属 |
|---|---|---|---|
| TFB 的 SI-SDR / DBSTOI / PESQ 三项全为最高 | 波束形成域掩蔽最保语音质量与可懂度 | 强 | 原文直接支持 |
| TFA 的干扰 ΔITD / ΔILD 在三域中最低（43 µs / 3.31 dB） | Ambisonics 域掩蔽最保残余干扰的空间属性 | 中 | 原文直接支持 |
| 混响目标下 TFA、TFM 的 ΔC50 低于 JND，TFB 最大（DRR = 10 dB 时 1.63 dB，超 JND） | Ambisonics / 麦克风域最保场景混响 | 中 | 原文直接支持 |
| 混响目标下三域目标 ΔITD 全为 0，ΔILD ≤ 0.49 dB | 三域都保住目标的双耳线索 | 强（但见 §5.4 提醒） | 原文直接支持 |
| 直达目标下三域 ΔC50 都远超 JND，TFB 高达 9.00 dB | 用直达声当期望信号必然破坏混响保真 | 强 | 原文直接支持 |
| TFM 的 SI-SDR / DBSTOI / PESQ 全为最低 | 麦克风域掩蔽效果最差 | 强 | 原文直接支持 |
| 原文只报告全场景平均值 | — | — | 原文未给按 SNR / DRR / 房间 / 角度的分层结果 |

**关于"结论是否随 SNR、混响、阵列配置变化"**：原文的 Table 3、Table 4 是**在整个 Monte-Carlo 数据集上平均**的单一读数，只按 DRR 拆了 C50（Table 2）。SNR 的 4 档（−20 / −10 / 0 / 10 dB）、三个房间（T60 = 0.44 / 0.56 / 0.75）、两个干扰方位角（−100 / 60 度）的分层结果**原文没有给出**。因此本页不能声称三域排序在低 SNR 或强混响下依然成立——**这是原文没做的实验，属本页外推禁区**。

## 5. 意外现象与作者解释

### 5.1. 期望信号定义比掩蔽域的影响更大

直达目标 vs 混响目标把 ΔC50 拉开一个数量级：TFB 在 DRR = −5 dB 时从 0.58 dB 涨到 9.00 dB，DRR = 10 dB 时从 1.63 dB 涨到 7.95 dB。作者解释：用直达路径当期望信号**本身就压制晚混响**，无论掩蔽在哪个域都会抬高 C50。结论是按原文说法，"想保住混响这类空间环境属性时，拿直达信号当期望信号是没有用的"，故后续分析全部改用混响目标。

### 5.2. 为什么麦克风域最差——作者给出的泄漏路径解释

原文明确写出三域差异的归因：TFM 表现差"可能源于**高通道相关**以及干扰**对全部麦克风都有贡献**"；TFB "同样受**波束图样旁瓣**影响"；而 TFA "**正交的波束图样**可能更好地抑制这种泄漏"。这是作者对自身结果的解释性陈述，原文并未做消融来单独验证这三条路径。

### 5.3. 质量最优与空间最优落在两个不同域

TFB 拿下 SI-SDR / DBSTOI / PESQ 三项最高（12.93 dB / 0.802 / 3.09），却在混响 ΔC50（1.10 dB，超 JND）和干扰 ΔILD（7.72 dB）上最差；TFA 反之（PESQ 2.66、SI-SDR 9.36 dB，但干扰 ΔITD 仅 43 µs、ΔILD 仅 3.31 dB）。原文的措辞是：波束形成域"以空间保真为代价"（at the expense of spatial fidelity）换来更强的噪声抑制和语音质量。

### 5.4. 一处原文内部不一致（待核）

原文 §4.3.3 与 §4.3.4 给出的知觉阈值是 ITD 约 100 µs、ILD 约 1 dB。但 §4.3.4 同时写"所有方法的 ΔITD 与 ΔILD 都在 JND 之上"，而表 4 里 TFA 的干扰 ΔITD = 43 µs，**低于文中自己给的 100 µs 阈值**。本页据表 4 数值记录为"TFA 的干扰 ITD 误差在三域中最低，且数值上低于文中引用的 ITD 阈值"，关于原文那句"all methods above JND"是否笔误，**待核**。

### 5.5. TFB 在干扰 ILD 上比 TFM 更差

按"波束形成域空间最差"的直觉，TFB 的干扰 ΔILD（7.72 dB）应最差且确实如此，但 TFM 的干扰 ΔITD（463 µs）反而是三域最高——即**"哪个域空间保真最差"随指标而变**：ITD 维度 TFM 最差，ILD 维度 TFB 最差。原文没有对这项指标分裂单独作解释。

## 6. 可复用结论

- **掩蔽施加域是一个显式权衡轴，不是实现细节**：想保残余干扰与场景混响选 Ambisonics 域；想保语音质量与可懂度选波束形成域。原文直接支持这个二分。
- **空间保真必须分开测目标与残余干扰**：目标线索在三域都被保住（ΔITD 全 0），差异只出现在残余干扰上。只报一个"空间保真"总分会把这条信息抹掉。这也呼应调研页 [[方向/AI语音/知识/调研与地图/Array Speech Enhancement Frontier（阵列语音增强前沿调研）]] 的「1.2. 评估矩阵」中"空间保真"一行推荐的 ITD / ILD 误差类检查。
- **期望信号定义要先于方法选择定下来**：要保混响就必须用含混响目标，否则任何域的掩蔽都保不住 C50。这条是本文对工程配置最直接可搬的结论。
- **oracle IRM 上界可作为路线选择的前置筛选**：三域排序在 oracle 条件下已经给出方向性指示，可先据此排除掉不占优的一域（TFM：质量与可懂度最低，残余干扰 ΔITD 最大），再去上 DNN。原文自身把 IRM 定位为"各表示的理论性能上界"。
- **残余干扰的空间属性与 SRM / 场景感知相关**：原文提出 TFA 更好保留干扰空间属性"可能带来 SRM 与更好的场景感知"，但这是原文的推测性表述，未做主观验证。

## 7. 不能外推什么

- **不能推出"Ambisonics 域掩蔽更好"这一总论断**：TFA 只在残余干扰空间属性与 C50 上更好；质量与可懂度上 TFB 明显更好（PESQ 3.09 vs 2.66，DBSTOI 0.802 vs 0.745，SI-SDR 12.93 vs 9.36 dB）。
- **不能外推到 DNN 估计掩码**：本文全部用 oracle IRM。原文把"掩码由 DNN 估计"明确列为 future work，并说分析应扩展到实际系统。
- **不能外推到一阶 Ambisonics 或非理想阵列**：原文 future work 明列这两项。本文只用了 r = 0.042 m 的刚性球形阵列、24 个 t-design 方向、N = 3 阶 Ambisonics。
- **不能外推到真实录音**：场景全部仿真（image method RIR、球谐域声场、Cologne HRTF 数据库、WSJ 朗读语句），没有真实阵列记录，没有阵列失配 / 坏麦 / 时钟漂移。
- **不能当作主观听感结论**：本文**没有任何听测**，全部为客观指标；原文 future work 明说要补 listening tests 评估空间质量与可懂度。
- **不能声称结论随 SNR / 房间 / 几何稳定**：分档结果原文没给（详见 §4.2 末）。唯一按 DRR 拆开的是 C50。
- **不能把 ITD / ILD 误差读成"整体空间感保住"**：本文没有测 IACC、DOA 偏差、binaural MOS，也没有测空间释放效应的行为学收益。指标集合只覆盖 ΔITD、ΔILD、ΔC50、DBSTOI、PESQ、SI-SDR。
- **本页外推（原文未讨论）**：三域的通道数并不对齐——TFA 是 16 通道（N = 3），TFB / TFM 是 24 通道，且 TFM 由 N = 10 阶球谐导出、TFA 自身在 N = 3 截断。本页**不**把三域差异归因拆成"表示形式"与"通道数 / 阶数"，原文没有做这个对照实验。
- **不能把本文塞进路线页**：本文不提出方法，只提供"掩蔽放哪个域"的横向证据；路线沉淀应留在 [[方向/AI语音/知识/技术路线/Hybrid Array SE（传统神经混合阵列增强）]] 或后续空间保真证据汇总页。

## 8. 连接到上层知识

- [[方向/AI语音/知识/调研与地图/Array Speech Enhancement Frontier（阵列语音增强前沿调研）]]：本页可作为其「1.2. 评估矩阵」中"空间保真"一行（ITD / ILD 误差）的直接证据，以及"多通道 SE 输出是否为多通道"这一问题的横向对照。
- [[方向/AI语音/知识/技术路线/Hybrid Array SE（传统神经混合阵列增强）]]：oracle IRM + 最大指向性波束形成 + 双耳解码，是这条路线在没有神经网络时的"传统上界"读法。
- [[方向/AI语音/知识/技术路线/Spatial-Guided SE（空间引导与多模态增强）]]：本文说明空间结构本身既是助益（TFA / TFB 优于 TFM 被归因于空间预处理带来的分离），也是需要被保护的对象。
- [[方向/AI语音/知识/基础概念/TF Mask（时频掩码）]]、[[方向/AI语音/知识/基础概念/Beamforming（波束形成）]]：掩蔽与波束形成的组合方式。
- [[方向/AI语音/知识/基础概念/Array vs Multi-Channel（阵列与多通道）]]：本文正是"多通道输出"与"单通道输出"之外第三种口径——输出是双耳信号，评价落在双耳线索上。
- [[方向/AI语音/知识/基础概念/ITD（耳间时间差）]]、[[方向/AI语音/知识/基础概念/ILD（双耳声级差）]]、[[方向/AI语音/知识/基础概念/IPD（通道间相位差）]]：本文用前两者做空间保真度量（IPD 未使用）。
- [[方向/AI语音/知识/基础概念/Direct Path（直达声）]]、[[方向/AI语音/知识/基础概念/Reverberation Modeling（混响建模）]]、[[方向/AI语音/知识/基础概念/ISM（Image Source Method，镜像声源法）]]：期望信号定义（直达 vs 混响）与 RIR 仿真方法。
- [[方向/AI语音/评估/PESQ]]、[[方向/AI语音/评估/SI-SDR]]、[[方向/AI语音/评估/STOI 与 ESTOI]]：本文的增强质量 / 可懂度指标来源；其中 DBSTOI（deterministic binaural STOI）是双耳变体，vault 的 STOI 页是否覆盖该变体待核。
- [[方向/AI语音/模型/AmbiDrop]]：Ambisonics 域增强的 DNN 化对照——本文用 oracle IRM 给出该域的上界，AmbiDrop 用 [[方向/AI语音/知识/基础概念/ASM（Ambisonics 信号匹配编码）|ASM]] 编码 + 通道 dropout 让任意阵列可进该域。
- [[方向/AI语音/团队/BGU Speech Enhancement Group（本古里安大学语音增强组）]]：作者 Boaz Rafaely 所属单位（BGU 电气与计算机工程学院）；注意该页目前记的是 Opochinsky 组口径，未覆盖 Rafaely 的球形阵列 / 空间音频组，见 §10。

## 9. 关键来源

- [Mask-Based Speech Enhancement for Spatial Audio: A Comparison of Ambisonics, Beamforming, and Microphone Channels](https://arxiv.org/abs/2609.18532)
  - 内容定位：arXiv:2609.18532v1 [eess.AS]，2026-09-16 提交；作者 Sheli Hendel、Boaz Rafaely（Ben-Gurion University）、Dorothea Kolossa（TU Berlin）；由 DFG 项目 KO3434/9-1 资助。全文约 5 页，含 Table 1–4 与 25 条参考文献。
  - 用途：本页唯一权威依据（题名、作者、日期、全部数值、四条 contribution、future work 均取自全文与 abs 页）。
  - 核验日期：2026-10-09
  - 核验方式：abs 页题名 / 作者 / 提交日与全文首页一致；abs 页无 Comments、无 Journal ref 字段。
- [Lugasi & Rafaely, "Speech Enhancement Using Masking for Binaural Reproduction of Ambisonics Signals," IEEE/ACM TASLP, vol. 28, pp. 1767–1777, 2020](https://doi.org/10.1109/TASLP.2020.2998294)
  - 内容定位：本文的 [1]，全文引用最密集的引用点——三域的 IRM 定义、最大指向性波束形成器实现、Ambisonics 球谐信号模型、双耳重放流程均沿用它。本文相对 [1] 新增的第三域是麦克风通道。
  - 用途：把本文放回"波束形成域 vs Ambisonics 域"的既有比较谱系。
  - 核验日期：2026-10-09
  - 核验方式：DOI 经 Crossref 元数据核对（题名、卷 28、页码 1767–1777 与原文 [1] 条目一致）。

## 10. 待验证

- **venue**：abs 页无 Comments / Journal ref，无法判定投稿去向，仅能确认为 arXiv 预印本。
- **三域公平性**：TFA 用 16 通道 / N = 3，TFB 与 TFM 用 24 通道（TFM 还从 N = 10 阶球谐导出）。阶数与通道数差异对结论的贡献未做消融。
- **分层结果缺失**：SNR 四档、三个房间、两个干扰方位的分域结果原文未给，三域排序是否随 SNR / 混响 / 几何翻转无法判断。
- **DNN 掩码下三域排序是否保持**：oracle IRM 是上界，估计掩码的误差分布会改变各域表现，原文列为 future work。
- **一阶 Ambisonics 与非理想阵列**：原文 future work 明列，本文结论不覆盖。
- **主观听测**：原文 future work 明列，无空间质量与可懂度听测数据。
- **vault 口径**：[[方向/AI语音/团队/BGU Speech Enhancement Group（本古里安大学语音增强组）]] 目前把 BGU 写作"R. Opochinsky 等"的组，未提及 Rafaely 的球形阵列 / 空间音频方向；本文是否应并入该页、还是另立 BGU 空间音频组页，待定。
- **调研页回填**：三域对比结论是否值得进 [[方向/AI语音/知识/调研与地图/Array Speech Enhancement Frontier（阵列语音增强前沿调研）]] 的「1.2. 评估矩阵」空间保真一行或新增"掩蔽域选择"条目，待定。

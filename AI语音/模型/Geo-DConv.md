---
title: Geo-DConv（几何感知动态卷积）
类型: 模型
发表时间: 2026-07
时间依据: arXiv 首次提交日
任务:
  - 语音增强
  - 多通道增强
开放状态:
  - paper
aliases:
  - Geo-DConv
  - Geometry-Aware Dynamic Convolution
  - 几何感知动态卷积
  - Towards Array-Invariant Speech Enhancement via Geometry-Aware Dynamic Convolution
tags:
  - 类型/对象
  - 方向/AI语音
  - 任务/语音增强
  - 任务/多通道增强
  - 主题/阵列信号
  - 主题/阵列无关
---

# Geo-DConv（几何感知动态卷积）

## 0. 背景

**问题现场**：SpatialNet / TF-GridNet 类固定阵列 SE 模型的跨通道卷积绑定固定麦克风数与几何拓扑，换设备、换阵列就要重训——部署环境阵列多变时不可用。

**前序路线的缺口**：array-agnostic 一路（通道 dropout、Ambisonics 域编码，如 USES2-comp、[[方向/AI语音/模型/AmbiDrop|AmbiDrop]]）摆脱了几何依赖，但也浪费了几何先验；传统空间特征（[[方向/AI语音/知识/基础概念/IPD（通道间相位差）|IPD]] 类）本身绑定固定几何，无法直接迁移。

**Geo-DConv 的切入点**：在阵列几何**已知**时显式注入坐标——坐标经傅里叶位置编码 + TACT 生成变换系数，对基卷积核线性组合得到随几何动态变化的卷积权重，兼得几何先验与跨阵列泛化（置换等变、可变通道数）。

## 1. 身份

`Geo-DConv`（Geometry-Aware Dynamic Convolution）是上海交大（作者 Zhenglong Liu、Wangyou Zhang、Chenda Li、Yanmin Qian，Interspeech 2026 收录，arXiv:2607.18658，2026-07-21 v1）提出的**几何感知动态卷积框架**：显式利用麦克风坐标，把标准固定阵列 SE 模型改造成 array-invariant 系统。

边界：不是抛弃几何信息的 array-agnostic 方法（通道 dropout / Ambisonics 域编码一路）——相反，它在阵列几何**已知**时显式注入坐标先验，针对的是"已有 array-agnostic 方法浪费了几何先验"这一缺口；改的是骨干网络的空间建模方式（卷积权重随坐标动态生成），不是外加波束形成后处理。

## 2. 核心机制

问题设定：多通道声学特征 $X\in\mathbb{R}^{C\times F\times T}$（STFT 复谱实部/虚部沿频率维拼接），$C$ 为可变麦克风数；每个麦克风带相对坐标 $g_i\in\mathbb{R}^3$（直角 $(x,y,z)$ 或球坐标 $(r,\theta,\phi)$），构成坐标矩阵 $G=[g_1,\dots,g_C]^\top\in\mathbb{R}^{C\times 3}$。Geo-DConv 层即 $Out=\text{Geo-DConv}(G,X)$。

1. **傅里叶位置编码**：把每个麦克风坐标编码成高维位置表示（[[知识wiki/NeRF（神经辐射场）|NeRF]] / NAF 式 INR 编码）。
2. **拓扑感知坐标 Transformer（[[方向/AI语音/模型/TACT（拓扑感知坐标 Transformer）|TACT]]）**：把编码后的坐标当作 $C$ 个 token 过 Transformer Encoder，输出变换系数矩阵 $M\in\mathbb{R}^{C\times b}$。
3. **动态卷积核生成**：$M$ 对一组基卷积核做线性组合，得到随阵列几何变化的卷积权重，替换 SpatialNet / TF-GridNet 首层跨通道卷积；后接 LN + 激活进入后续网络。

```text
mic coordinates G（C×3）
  -> 傅里叶位置编码 γ(·)（C×d_pe）
  -> TACT（Transformer Encoder，全局拓扑建模）
  -> 变换系数矩阵 M（C×b）
基卷积核 K（b×O×Kf×Kt） --M 线性组合--> 动态核 W_dyn（C×O×Kf×Kt）
多通道特征 X（C×F×T） --W_dyn 卷积 + LN + 激活--> 后续骨干（SpatialNet / TF-GridNet）
```

**置换等变**：坐标排列 $P$ 作用下 $G\to PG$ 时，逐点 Fourier PE 与 [[方向/大模型/模型结构/MHA（Multi-Head Attention）|MHSA]] 的置换等变性保证 $M\to PM$，进而 $\mathcal{W}_{dyn}\to P\mathcal{W}_{dyn}$；卷积中 $PX\circledast P\mathcal{W}_{dyn}=X\circledast\mathcal{W}_{dyn}$，输出对通道顺序严格不变（论文显式声明并证明）。

## 3. 核心公式

动态卷积核生成（基核线性组合）：

$$\mathcal{W}_{dyn}^{(c,o,:,:)}=\sum_{j=1}^{b}M_{c,j}\cdot\mathcal{K}^{(j,o,:,:)},\qquad \mathcal{W}_{dyn}\in\mathbb{R}^{C\times O\times K_f\times K_t}$$

其中 $\mathcal{K}\in\mathbb{R}^{b\times O\times K_f\times K_t}$ 为可学习基卷积核（$b$ 基维数、$O$ 固定输出通道、$K_f,K_t$ 频率/时间核尺寸），$M\in\mathbb{R}^{C\times b}$ 为 TACT 生成的变换系数矩阵——任意麦克风数 $C$ 只改变 $M$ 的行数，基核维度固定，这是可变通道的关键。

傅里叶位置编码（逐点、[[知识wiki/NeRF（神经辐射场）|NeRF]] 式）：

$$\gamma(g_i)=\big[\,g_i,\ \sin(2^{0}\pi g_i),\cos(2^{0}\pi g_i),\ \dots,\ \sin(2^{L-1}\pi g_i),\cos(2^{L-1}\pi g_i)\,\big]$$

其中 $L$ 为频段数，编码后 $G_{pe}\in\mathbb{R}^{C\times d_{pe}}$，$d_{pe}=3+6L$。

TACT 前向：

$$G^{(0)}=G_{pe}W_{in},\quad W_{in}\in\mathbb{R}^{d_{pe}\times d_{hidden}}$$

$$Q=G^{(l)}W_Q,\quad K=G^{(l)}W_K,\quad V=G^{(l)}W_V,\qquad Z^{(l+1)}=\mathrm{LayerNorm}\big(Z^{(l)}+\mathrm{MHSA}(Q,K,V)\big)$$

$$M=Z^{(L_{layers})}W_{out},\quad W_{out}\in\mathbb{R}^{d_{hidden}\times b}$$

其中 $G^{(l)}$ 为第 $l$ 层坐标 token 表示，MHSA 在麦克风维做全局注意力以建模阵列拓扑。

置换等变性质（$P$ 为 $C\times C$ 排列矩阵）：

$$PX\circledast P\mathcal{W}_{dyn}=X\circledast\mathcal{W}_{dyn}$$

**实验超参**（论文设置）：$b=8$、$O=16$、球坐标、PE 频段数 $L=6$、$d_{hidden}=64$、Transformer 4 头 2 层。

## 4. 测试基准与性能

**测试基准**（论文 Table 1/2）：

- 数据：真实录制 **RealMAN** 多通道数据集（32 通道、83.7h，室内/室外/半室外/交通）；跨数据集泛化测 **CHiME-4**（6 麦真实录制）。
- 设置三档：Fixed-Array（固定阵列，性能上限参照）、Random 4-Mics（随机 4 麦训练）、Geometry-Invariant（随机 ≤4 麦训练，主对比档）。
- 基线：BSRNN（单通道参照）、[[方向/AI语音/模型/FaSNet（滤波求和网络）|FaSNet]]-TAC、USES2-comp、原版 SpatialNet / TF-GridNet。
- 指标：SDR / SI-SDR / PESQ / STOI / DNSMOS（P808、SIG、BAK、OVRL）；成本口径：参数量、MACs（G/s）。

**性能指标**（Geometry-Invariant 主对比档）：

| 模型 | 参数量 | MACs (G/s) | SDR | SI-SDR | PESQ | STOI | OVRL |
|---|---|---|---|---|---|---|---|
| FaSNet-TAC | 2.7M | 9.76 | 5.76 | −0.81 | 1.74 | 0.73 | 2.05 |
| USES2-comp | 2.5M | 70.26 | 8.62 | 4.17 | 2.52 | 0.86 | 2.56 |
| **SpatialNet-Geo-DConv** | **1.3M** | **6.08** | **9.72** | **4.22** | 2.48 | 0.86 | 2.68 |
| **TF-GridNet-Geo-DConv** | 8.3M | 73.12 | **9.05** | 3.90 | **2.59** | **0.87** | **2.77** |

- **固定阵列上限参照**（Table 1 的 Fixed-Array 档，与上表同数据、同训练预算，唯一差别是训练时阵列固定；2026-10-28 补核 SIG/BAK/PESQ）：

| 参照 | 参数 | MACs (G/s) | PESQ | SIG | BAK | OVRL | SI-SDR |
|---|---|---|---|---|---|---|---|
| SpatialNet（固定阵列上界） | 1.2M | 5.99 | 2.56 | 3.11 | 3.58 | 2.67 | **5.23** |
| ↳ SpatialNet-Geo-DConv（≤4 麦可变） | 1.3M | 6.08 | 2.48 | **3.16** | 3.51 | **2.68** | 4.22 |
| TF-GridNet（固定阵列上界） | 8.2M | 73.03 | **2.72** | 3.13 | 3.63 | 2.71 | **5.29** |
| ↳ TF-GridNet-Geo-DConv（≤4 麦可变） | 8.3M | 73.12 | 2.59 | **3.21** | 3.62 | **2.77** | 3.90 |
| BSRNN（单通道，容量锚） | 16.9M | 21.15 | 1.94 | 2.61 | 3.29 | 2.18 | −1.38 |

  读法：换成可变阵列后 **SI-SDR 掉 1.0–1.4 dB，但 SIG/OVRL 不降反略升**（SpatialNet 2.67→2.68、TF-GridNet 2.71→2.77）。说明代价集中在波形级相位/精细结构，而非听感维度；PESQ 介于两者之间（−0.08 / −0.13）。另注意 16.9M 的单通道 BSRNN OVRL 2.18 低于 1.2M 的 6 麦固定阵列 2.67——容量不如通道数。
- 随机麦数训练有效：Random 4-Mics 档的 Geo 版（SI-SDR 3.92 / 3.56）升到 Geometry-Invariant 档的 4.22 / 3.90，作者归因于可变输入通道数帮助学习动态卷积权重生成。
- 算力：Geo-DConv 只增加约 0.1M 参数；SpatialNet-Geo-DConv 性能与 USES2-comp 相当但 MACs 低一个量级（6.08 vs 70.26）。

**变麦数与跨数据集泛化**（Table 2，训练最多见 4 麦）：

| 模型 | 1 麦 SI-SDR | 2 麦 SI-SDR | 5 麦 SI-SDR | CHiME-4 OVRL |
|---|---|---|---|---|
| USES2-comp | −4.16 | 3.55 | 4.91 | 2.55 |
| SpatialNet-Geo-DConv | 2.30 | 3.97 | 4.65 | 2.64 |
| TF-GridNet-Geo-DConv | 2.76 | 4.12 | 4.54 | 2.73 |

- 单麦时全部方法退化为单通道 SE，Geo 版明显优于 USES2-comp（2.30 / 2.76 vs −4.16 SI-SDR）；麦数增加各方法一致提升。
- 未见的 5 麦、6 麦配置与跨数据集 CHiME-4 上均稳定泛化：CHiME-4 OVRL 从未处理的 1.42 提升到 2.64（SpatialNet-Geo）/ 2.73（TF-GridNet-Geo）。

## 5. 使用判断

- **开源状态（2026-10-23 核查）：无官方代码 / 权重**。arXiv 摘要页与全文 HTML/PDF 均无 GitHub 或项目页链接（论文正文没有 code availability 声明）；GitHub 仓库检索 `Geo-DConv`、`Geometry-Aware Dynamic Convolution` 均为 0 结果；上交 X-LANCE 组织与作者公开账号下未见对应仓库。复现需自行实现 TACT + 基核线性组合（公式与超参齐全：$b=8$、$O=16$、$L=6$、$d_{hidden}=64$、4 头 2 层），数据与骨干可从 RealMAN 公开仓库、NBSS（SpatialNet 官方实现）等复用。
- 适合：阵列几何已知但设备 / 拓扑多变的部署（同一模型跨设备泛化）；让 SpatialNet / TF-GridNet 类固定阵列模型适配未见阵列的研究。
- 不适合：几何完全未知且不可估计的场景（坐标先验不可用，更接近 AmbiDrop 类 array-agnostic 路线）；纯单通道任务。
- 风险：依赖准确的麦克风坐标标定，标定误差影响未实验；Geo-DConv 版在固定阵列上略低于原版（SpatialNet 5.23 vs Geo 版 Random 4-Mics 3.92 SI-SDR），它买的是跨阵列泛化而非单阵列上限。

## 6. 关键来源

- [Towards Array-Invariant Speech Enhancement via Geometry-Aware Dynamic Convolution（arXiv:2607.18658）](https://arxiv.org/abs/2607.18658)
  - 内容定位：原始论文（全文 HTML 已核），v1 2026-07-21，eess.AS / cs.SD，Interspeech 2026 收录；含 Geo-DConv/TACT 全部公式、置换等变证明、RealMAN 与 CHiME-4 结果。
  - 用途：对象身份、机制公式、结果口径的唯一来源。
  - 核验日期：2026-10-15

## 7. 相关对象

- [[方向/AI语音/模型/TF-GridNet|TF-GridNet]]、[[方向/AI语音/模型/SpatialNet|SpatialNet]]：被 Geo-DConv 改造的两个固定阵列模型（Table 1 确认）。
- [[工程/Geo-DConv 复现方案|Geo-DConv 复现方案]]：自建复现的准备工作、已有资产盘点与里程碑。
- [[方向/AI语音/数据集/RealMAN|RealMAN]]：实验用的真实录制 32 通道数据集（独立开源，非本文发布）。
- [[方向/AI语音/模型/HyBeam|HyBeam]]：array-agnostic 另一条路线（低频原始信号 + 高频波束输出的混合方案）。
- [[方向/AI语音/知识/基础概念/IPD（通道间相位差）|IPD]]：传统空间特征绑定固定几何，是 array-agnostic 要摆脱的对象；Geo-DConv 改用显式坐标条件化。
- [[方向/AI语音/知识/基础概念/Array Audio Signal（阵列音频信号）|Array Audio Signal]]：阵列几何是多通道 SE 的核心变量。
- [[方向/AI语音/知识/调研与地图/Array Speech Enhancement Frontier（阵列语音增强前沿调研）|阵列语音增强前沿调研]]：本对象在"阵列无关 / 任意几何"阵营中的位置与横评上下文。

## 8. 待验证

- ~~RealMAN 发布关系~~（已核，2026-10-23）：RealMAN 是西湖大学 AudioLab 与希尔贝壳（AISHELL）联合开源的独立数据集（NeurIPS 2024，arXiv:2406.19959，GitHub `Audio-WestlakeU/RealMAN`，CC-BY-4.0），**不是**随 Geo-DConv 发布；论文参考文献 [14] 即该文，调研页"随论文发布"口径有误，见 [[方向/AI语音/数据集/RealMAN|RealMAN]]。
- 坐标标定误差、坐标系选择（直角 vs 球）对性能的敏感性，论文未做消融。
- 官方代码是否在 Interspeech 2026 会后补放（会议论文常延后开源），需定期复查作者 / X-LANCE 仓库列表。
- Geo-DConv 改造在真实本地阵列（非标定数据集）上的端到端收益。

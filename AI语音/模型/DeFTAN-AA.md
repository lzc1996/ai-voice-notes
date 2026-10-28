---
title: DeFTAN-AA
类型: 模型
参数量: 2.2M（Proposed）
发表时间: 2024-09
时间依据: Interspeech 2024 论文集（2024-09-01–05，Kos；pp. 3360–3364）
任务:
  - 语音增强
  - 多通道增强
开放状态:
  - paper
团队: KAIST（Dongheon Lee、Jung-Woo Choi）
aliases:
  - DeFTAN-AA
  - "DeFTAN-AA: Array Geometry Agnostic Multichannel Speech Enhancement"
  - Array Geometry Agnostic Multichannel Speech Enhancement
  - array-agnostic DeFTAN
  - 几何无关 DeFTAN
相关模型:
  - "[[方向/AI语音/模型/DeFTAN2|DeFTAN2]]"
tags:
  - 类型/对象
  - 方向/AI语音
  - 任务/语音增强
  - 任务/多通道增强
  - 主题/阵列无关
  - 主题/注意力机制
---

# DeFTAN-AA

## 0. 背景

**1) 问题现场**：多通道语音增强相对单通道的价值在于利用空间信息，但真实部署里阵列几何（形状、孔径、麦克风数）几乎每台设备都不同。为每种几何重训一个大型 DNN，时间与成本都不可接受；模型需要在**未见阵列**上直接可用，且不做微调。

**2) 前序路线的缺口**：

- 当时的 array-agnostic 工作大多靠**多几何仿真数据**训练（在尽可能多的阵列配置上堆数据），但覆盖所有可能几何不现实。
- 参数共享 + [[方向/AI语音/知识/基础概念/TAC（变换-平均-拼接）|TAC]] 结构、或"单通道增强 + 多通道波束形成"是主流替代方案，但本质仍是简单通道混合，难以刻画复杂空间关系。
- [[方向/AI语音/模型/DeFTAN2|DeFTAN-II]] 的 SDB 已被证明能在不同**形状**的阵列上保持高性能，但仍有几何依赖；卷积编码器的通道维绑定麦克风数，换 $M$ 直接不可用。
- 因此缺口有两层：**形状泛化**（换几何）与**数量泛化**（换麦克风数），且要在单一阵列训练的前提下成立。

**3) DeFTAN-AA 的切入点**：只用单个 4 麦圆阵训练，用三个模块分别补缺口——GSDB 用 GLU 按信号内容选特征（管形状）、ST 把麦克风维当序列做自注意力（管数量）、SOCA 在空间特征与单通道时频特征间做交叉注意力且不含依赖 $M$ 的参数（管训练/推理麦克风数不一致的过拟合）。

## 1. 身份

`DeFTAN-AA`（Array geometry agnostic DeFTAN，KAIST，Interspeech 2024，DOI: 10.21437/Interspeech.2024-669）是**只用单个 4 麦圆阵训练、却能增强未见阵列形状与未见麦克风数**的多通道语音增强模型。它建立在 [[方向/AI语音/模型/DeFTAN2|DeFTAN2]] 的 DeFTAN-II block 之上，新增三个模块：**GSDB**（gated split dense block，门控通道分组）、**ST**（spatial transformer，通道自注意力编码）、**SOCA**（space-object cross-attention，空间—物体交叉注意力）。

边界：它是**增强**模型（复数谱映射），不是分离；非因果、离线；训练阵列只有一种（4 麦圆阵，半径 10 cm），"array-agnostic" 指推理期泛化，不是多几何训练；没有显式几何条件输入（区别于 Geo-DConv / MSEN 阵营）。

## 2. 核心信息

- **输入**：$M$ 通道带噪混响语音的复数 STFT，实虚部堆叠为 $(2M,T,F)$；论文配置 $F=257$（32 ms 矩形窗、50% 重叠、512 点）。
- **输出**：单通道干净语音的复数谱（complex spectral mapping），与参考通道对齐。
- **任务**：多通道语音增强（降噪 + 去混响）。
- **训练信号**：PCM loss（phase-constrained magnitude）。

## 3. 核心机制

### 3.1. 总体数据流

```text
M 通道复 STFT（2M × T × F）
  ├─ 单通道 Conv2d 编码器 -> 物体特征 O（只含时频模式，不含阵列几何）
  └─ ST：T 作 batch、F 作 embedding、2M 作序列
       -> 通道自注意力（2M × 2M 注意力图）
       -> 实虚部拆开重排为 (M,2,T,F)，与复数谱拼接 -> Up-Conv
       -> 逐通道共享权重的 DeFTAN-II 块精炼 -> 空间特征 S
  S 与 O 送入 SOCA：Q=S，K/V=O，麦克风维作序列
    -> 残差 + FFN -> 沿麦克风维 mean-pool -> (B,C,T,F)
  -> 若干 DeFTAN-II block（论文 Nb=4）-> Down-Conv -> 估计复数谱
```

关键设计：三个模块各自负责一维泛化——GSDB 管**阵列形状**，ST 管**麦克风数量**的可变输入，SOCA 管**训练/推理麦克风数不一致**时的过拟合。

### 3.2. GSDB（gated split dense block）

SDB 是 DeFTAN-II 的核心：unfold-transpose 卷积 + channel shuffle 把通道拆成 $G$ 组、顺序拼接并压缩，兼顾时频邻域与通道信息。GSDB 在其后加 **GLU 门控**：

$$
\mathbf{y} = \mathrm{Conv}(\mathbf{x}) \otimes \sigma(\mathrm{Conv}'(\mathbf{x}))
$$

其中 $\mathbf{x}$ 是 SDB 输出特征，$\mathrm{Conv},\mathrm{Conv}'$ 为两路卷积，$\sigma$ 为 sigmoid，$\otimes$ 为逐元素乘。门控按**信号内容**保留前景语音特征、压掉噪声相关成分，因此不依赖特定阵列几何；代价是输出通道变宽、算力上升（1.1M / 17.2 G，SDB 版 0.8M / 12.4 G）。

### 3.3. ST（spatial transformer）

传统卷积编码器的卷积核通道维绑定 $M$，换麦克风数就不可用。ST 把 $(2M,T,F)$ 的 **时间维当 batch、频率维当 embedding、麦克风维当序列**，做通道自注意力，得到 $2M\times2M$ 的注意力图，建模每一对麦克风之间的关系；序列长度随 $M$ 变，投影参数不随 $M$ 变。输出拆开实虚部、重排为 $(M,2,T,F)$，与原始复数谱拼接后过 Up-Conv，再进共享权重的 DeFTAN-II 块。

单独用 ST 时，固定麦克风数下性能最好（$M=4$ 时 10.3 dB），但对训练时的 $M$ 过拟合：换 $M=3$ 掉到 7.4 dB。

### 3.4. SOCA（space-object cross-attention）

SOCA 解决"训练 4 麦、推理 3/8 麦"的过拟合。它把两路特征做交叉注意力：

- **Q（query）= 空间特征 $S$**：ST 路径经共享权重 DeFTAN-II 块精炼后的输出，含麦克风间空间关系。
- **K/V（key/value）= 物体特征 $O$**：单通道 Conv2d 编码器单独提取的时频特征，不含阵列信息。
- **序列维 = 麦克风通道维**；注意力前对 Q/K/V 各做线性投影，投影参数只作用于特征维，**没有任何参数依赖麦克风数 $M$**。

$$
\mathrm{Attn}(S,O)=\mathrm{softmax}\!\left(\frac{(S W_Q)(O W_K)^{T}}{\sqrt{d}}\right)(O W_V)
$$

其中 $W_Q,W_K,W_V$ 为线性投影，$d$ 为特征维。注意力输出**残差加回空间特征**，再经 FFN，最后沿麦克风维做 **mean-pooling**，得到与 $M$ 无关的 $(B,C,T,F)$ 表示。这样每个麦克风的时频信息都被"问"了一遍空间上下文，而输出形状不随传感器数量变化。

消融显示 SOCA 的代价与收益：

- 与单独 GSDB+ST 相比，$M=4$ 时 SI-SDR 从 10.3 降到 9.4 dB（约 −0.9 dB），参数 2.0M → 2.2M、算力 19.3 G → 35.7 G；
- 但 $M=3$ 从 7.4 升到 8.5 dB、$M=8$ 从 8.3 升到 9.6 dB，且随麦克风数增加性能**单调上升**；
- 只用 GSDB+SOCA（去掉 ST）反而更差（$M=4$ 时 8.6 dB）——SOCA 需要 ST 提供的空间特征才有意义。

一句话：SOCA 用固定的约 1 dB 同阵列性能，换跨麦克风数的稳定性。

### 3.5. 三个模块的分工

| 模块 | 解决什么 | 不解决什么 |
| ---- | -------- | ---------- |
| GSDB | 阵列**形状**变化（GLU 按内容选特征） | 麦克风数变化 |
| ST | 麦克风**数量**变化（序列维=通道） | 对训练麦克风数的过拟合 |
| SOCA | 训练/推理麦克风数**不一致**时的过拟合 | 阵列几何本身（靠 ST 特征） |

## 4. 测试基准与性能

### 4.1. 数据与设置

- **训练/验证**：DNS Challenge 2020 语料，房间 5–10 m × 5–10 m × 3–4 m，镜像源法（pyroomacoustics），SNR −10~10 dB，T60 0.2–1.2 s；**只用 4 麦圆阵（r = 10 cm）**训练。
- **测试**：LibriSpeech 语音 + DNS 噪声，六种阵列——参考圆阵、变半径圆阵、矩形、线性、四面体、随机阵列；孔径 2–20 cm；每种阵列 1000 条；另测 3/4/8 麦。
- **真实录音（作者自采，非公开数据集）**：ReSpeaker v2.0 4 麦圆阵（r = 2.7 cm）与 miniDSP UMA-16 上取的 8.2 × 4.2 cm 矩形阵；办公室 4.1 × 6 × 2.5 m、T60 0.2 s、SNR 5 dB、100 条 3–12 s 录音，**零微调**。论文未给数据集名称，也未见公开下载。
- **配置**：Nb = 4，C = 64，卷积核 3，PCM loss，Adam（lr 0.001、batch 4），100 epoch；指标 SI-SDR / PESQ / WER（wav2vec 2.0）。

### 4.2. 主结果（$M=4$，Table 1）

| 方法 | SI-SDR Ref/Cir/Rec/Lin/Tet/Ran (dB) | PESQ Ref | WER Ref (%) | 参数 | MAC/s |
| ---- | ----------------------------------- | -------- | ----------- | ---- | ----- |
| 带噪 | −7.8 / −7.8 / −7.9 / −7.9 / −7.8 / −7.9 | 1.38 | 97.0 | – | – |
| DeFTAN-II（SDB） | 9.8 / 9.7 / 8.7 / 8.8 / 9.1 / 9.2 | 2.99 | 11.2 | 0.8 M | 12.4 G |
| GSDB+ST | 10.3 / 10.2 / 9.9 / 9.9 / 10.0 / 10.1 | 3.02 | 10.3 | 2.0 M | 19.3 G |
| **DeFTAN-AA（Proposed）** | **9.4 / 9.3 / 9.0 / 9.0 / 9.2 / 9.3** | **2.95** | **14.7** | 2.2 M | 35.7 G |

- 跨阵列最大差距（相对参考阵）：GSDB 版 0.7 dB / 0.12 PESQ / 4.3% WER；SDB 版 1.1 dB / 0.19 / 9.4%。
- 麦克风数变化（Table 2，SI-SDR）：Proposed 在 $M=3$ 为 8.1–8.5 dB、$M=4$ 为 9.0–9.4 dB、$M=8$ 为 9.4–9.7 dB；对比 $M=4$ 的 Mask-beamforming 2.9、FasNet+TAC 4.5、NBDF 4.6、DRC-Net 6.4（参考阵数值）。
- 真实录音：圆阵与矩形阵的 WER 差 0.7%（图 3 具体数值未录入）。

### 4.3. 结果口径

- 固定 $M$、只换几何时，GSDB+ST 更强；换 $M$ 时 Proposed 才反超——SOCA 是为"传感器数量不确定"买的保险，不是无条件的性能提升。
- 每个模块单独都不够：无 SDB 最差（2.8 dB）；只有 GSDB 换 $M$ 不可用；只有 ST 换 $M$ 过拟合；只有 GSDB+SOCA 缺空间编码（8.6 dB）。

## 5. 边界

- **训练只见过一种阵列**：泛化结论来自 3/4/8 麦、2–20 cm 孔径的仿真测试；更少麦克风（< 3）与更大孔径未报告。
- **非因果、离线**：所有模型为非因果系统，不适合流式/低延迟场景。
- **任务口径**：增强（复数谱映射），不是分离；WER 用 wav2vec 2.0 评估，未接 ASR 微调。
- **真实数据规模小**：两种阵列、一个房间、100 条录音，真实场景结论强度有限。
- **算力不是卖点**：2.2M / 35.7 G，比 GSDB+ST 高约 85% MAC/s，换来跨 $M$ 稳定性。

## 6. 发展脉络

- **DeFTAN**（IEEE SPL 2023）：复数掩码 + 密集时频注意力。
- **DeFTAN-II**（IEEE/ACM TASLP 2024，arXiv:2308.15777）：复数映射 + SDB 子组处理，效率大幅提升。
- **DeFTAN-AA**（Interspeech 2024）：在 DeFTAN-II block 上加 GSDB / ST / SOCA，转向 array-agnostic。
- **DeFT-Mamba**（arXiv:2409.12413，同作者）：DeFTAN + Mamba 的多通道分离版（尚无独立笔记）。

## 7. 相关对象

- [[方向/AI语音/模型/DeFTAN2|DeFTAN2]]：父架构，提供 DeFTAN-II block 与 SDB；AA 在其上做阵列泛化。
- [[方向/AI语音/模型/AmbiDrop|AmbiDrop]]：另一条 array-agnostic 路线（Ambisonics 编码 + 通道 dropout），背景节把 ST/SOCA 归为"attention 系、架构复杂"的对照。
- [[方向/AI语音/知识/基础概念/TAC（变换-平均-拼接）|TAC]]：论文点名的前序参数共享/通道混合方案，SOCA 主张比它更能建模复杂空间关系。
- [[方向/AI语音/模型/MSEN（特征束多阶编码器）|MSEN]]： eigenbeam 多阶编码器路线，与 ST/SOCA 的"注意力泛化"是不同分支。
- [[方向/AI语音/知识/调研与地图/Array Speech Enhancement Frontier（阵列语音增强前沿调研）|阵列语音增强前沿调研]]：本对象的调研上下文（阵列无关 / 任意几何）。

## 8. 关键来源

- [DeFTAN-AA: Array Geometry Agnostic Multichannel Speech Enhancement（ISCA Archive）](https://www.isca-archive.org/interspeech_2024/lee24g_interspeech.html)
  - 内容定位：Interspeech 2024 论文摘要页（Lee & Choi，pp. 3360–3364，DOI: 10.21437/Interspeech.2024-669）。
  - 用途：对象身份、摘要级模块定义。
  - 核验日期：2026-10-21
- [论文 PDF（ISCA Archive）](https://www.isca-archive.org/interspeech_2024/lee24g_interspeech.pdf)
  - 内容定位：全文（5 页），含架构、GSDB/ST/SOCA 细节、Table 1/2 与真实录音实验。
  - 用途：本页机制、公式与全部数值的直接出处；全文已读（2026-10-21）。
  - 核验日期：2026-10-21
- [作者项目页（DeFTAN-AA）](https://donghoney0416.github.io/DeFTAN-AA/)
  - 内容定位：论文与视频入口、结果表。
  - 用途：补充入口（本次未打开，按检索结果记录）。
  - 核验日期：2026-10-21（检索确认存在）

## 9. 待验证

- 代码 / 权重：未检索到官方仓库；项目页只列 Paper / Video，开源状态待确认。
- 真实录音图 3 的具体 WER 数值未从正文提取（正文只给"圆阵 vs 矩形阵差 0.7%"）。
- 少于 3 个麦克风、更大孔径、非平面阵列的行为未报告。
- 与 [[方向/AI语音/模型/AmbiDrop|AmbiDrop]]、MSEN 等 array-agnostic 路线未在同条件数据上横评。
- SOCA 是否在其他架构（非 DeFTAN 系）上复用：目前仅见本论文，暂不单拆组件页。

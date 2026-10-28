---
title: Adaptive Rotary Steering（自适应旋转转向）
类型: 模型
发表时间: 2026-01
时间依据: arXiv 首次提交日 2026-01-18（v2 2026-01-21）；ICASSP 2026 接收
任务:
  - 目标说话人提取
  - 语音增强
团队:
  - "[[方向/AI语音/团队/UHH Gerkmann Group（汉堡大学 Gerkmann 组）]]"
方法范式:
  - 判别式
  - 帧级自回归反馈（非生成式）
开放状态:
  - paper
  - demo
aliases:
  - Adaptive Rotary Steering
  - 自适应旋转转向
  - "Adaptive Rotary Steering with Joint Autoregression for Robust Extraction of Closely Moving Speakers in Dynamic Scenarios"
  - 联合自回归框架（joint AR）
tags:
  - 类型/对象
  - 方向/AI语音
  - 任务/目标说话人提取
  - 主题/动态声源
  - 主题/阵列无关
---

# Adaptive Rotary Steering（自适应旋转转向）

## 0. 背景

**问题现场**：Ambisonics 域多说话人动态场景中的目标说话人提取——说话人持续移动、互相靠近交叉，需要按方向锁定目标并跟随其移动。

**前序路线的缺口**：Wang 等的 rotary steering 只处理静止多说话人，整段录音把声场钉在固定方向，无法跟随移动目标。

**Adaptive Rotary Steering 的切入点**：只用目标初始方向做弱引导，逐帧估计时变方向并更新 Wigner-D 旋转矩阵，并把上一帧增强输出回灌给跟踪与增强两路（joint AR），不改动下游网络权重。

## 1. 身份

`Adaptive Rotary Steering`（Adaptive Rotary Steering with Joint Autoregression for Robust Extraction of Closely Moving Speakers in Dynamic Scenarios）是 Jakob Kienegger、Timo Gerkmann（[[方向/AI语音/团队/UHH Gerkmann Group（汉堡大学 Gerkmann 组）|UHH Gerkmann Group]]，ICASSP 2026，arXiv:2601.12345，2026-01）提出的 **Ambisonics 域、面向动态场景的目标说话人提取（TSE）** 框架。

它把 Wang 等的 rotary steering（把声场转到目标方向后再做多通道增强，不改下游网络权重、不加 DoA 条件——转的是声场而非波束）从静止多说话人推广到移动说话人：只用目标的**初始方向**做弱引导，逐帧估计时变方向并更新 **Wigner-D 旋转矩阵**，把**上一帧增强输出**回灌给跟踪与增强两路（机制见「核心机制」）。

边界：输入不是原始麦克风阵列通道，而是球面麦阵录音编码出的球谐系数（Ambisonics，[[方向/AI语音/知识/基础概念/ACN（Ambisonics 通道编号）|ACN]] 排序、ambiX 归一化），阵列无关性因此只是表示层主张，仍需能编码 Ambisonics 的采集前端（[[方向/AI语音/知识/技术路线/Array-Agnostic SE（阵列无关语音增强）|Array-Agnostic SE]] 的「规范空间表示」口径）；题名里的「autoregressive」已判定为**帧级因果时序反馈**——把上一帧增强输出回灌为跟踪与增强网络的额外输入，**不是生成式自回归建模**；与 ARiSE、McNet、AmbiDrop / MSEN、Beamforming 等相邻对象的区别见「相关对象」；严格任务是**目标说话人提取**（重建无回声目标语音的 monopole 系数，而非参考麦信号），全部实验固定 FOA（N = 1）。

## 2. 核心机制

```text
球面麦阵录音 -> 编码为 FOA 球谐系数观测 Y_t（ACN / ambiX / N=1）
  -> 【弱引导】只给定目标的初始 DoA (θ0, φ0)
  -> 固定旋转转向：Y_t 乘 D0ᵀ，把声场中心钉在初始方向
  -> 【AR-TST】跟踪器（SELDnet）输入 = [旋转后的 Y_t ; 上一帧增强输出 Ŝ_{t-1}]
       -> 输出角偏差 Δθ̂_t, Δφ̂_t   （初始方向已对齐，故只需估偏差）
  -> 自适应旋转转向：D̂_t = D(θ0+Δθ̂_t, φ0+Δφ̂_t, 0)，再算 Y_t 乘 D̂_tᵀ
  -> 【AR-SSF】增强器（McNet / SpatialNet）输入 = [旋转后的 Y_t ; Ŝ_{t-1}]
       -> 输出 Ŝ_t（目标无回声语音的 monopole 系数）
  -> Ŝ_t 回灌下一帧（跟踪与增强共用同一条反馈）
```

### 2.1. 固定与自适应旋转转向（Wigner-D）

- **固定旋转转向**（本文对 [7] 静止场景做法的命名）：用初始方向构造 $\mathbf{D}_0$，整段录音都把声场钉在初始 DoA——只提供一次性空间线索，让下游网络自己去学目标的时频谱特征。
- **自适应旋转转向**：用目标当前 DoA $(\theta_t,\phi_t)$ 构造时变 $\mathbf{D}_t$（式 (4)），逐帧跟随移动。
- 两种情况都靠"乘 $\mathbf{D}$ 的逆/转置"实现，不触碰下游网络结构（式 (3) 给出 Wigner-D 的 ZYZ 形式）。
- **强引导 vs 弱引导**：全程给真值方向 = strong guidance（作上界）；只给初始方向 = weak guidance（本文设定）。

### 2.2. 弱引导跟踪（AR-TST 之前的版本）

- 跟踪器不直接输出绝对 DoA，而是**估角偏差**：因为输入声场已被 $\mathbf{D}_0$ 对齐到初始方向，TST 只需要补 $\Delta\theta_t,\Delta\phi_t$，再按式 (5) 合成 $\widehat{\mathbf{D}}_t$。
- 选 SELDnet（CRNN，原为 SELD 任务）作跟踪骨干：去掉声事件检测头 + 因果实现，< 300 k 参数、70 M/s MACs。
- 这一设计让"跟踪"与"增强"共用同一个 rotary steering 作为条件化手段，**与具体子系统实现无关**（论文强调这是它的通用性来源）。

### 2.3. 自回归互连：AR-SSF 与 AR-TST

- **AR-SSF**：把 $\widehat{S}_{t-1}$ 作为**额外通道**拼接到旋转后的含噪输入，送进 McNet / SpatialNet。理由是 $\widehat{S}_{t-1}$ 的谱结构与 $\mathbf{Y}_t$ 的时间相关性有助于拆开空间上歧义的组合（如交叉瞬间）。McNet 增益更大，论文归因于它的多子层输入拼接结构更适合融合时频谱线索。
- **AR-TST**：同样把 $\widehat{S}_{t-1}$ 喂给跟踪网络。难点是对齐：$\widehat{S}_{t-1}$ 是上一帧坐标下的量，因此引入近似式 (6) $\widehat{\mathbf{D}}_t \approx \widehat{\mathbf{D}}_{t-1}$，把 $\widehat{S}_{t-1}$ 与 $\mathbf{Y}_{t-1}$ 在时间上对齐，从而给定位器提供"与含噪观测匹配的目标语音谱型"。
- 论文明确区分：传统"先提直达声再定位"的技巧在自适应旋转转向下失效（目标已被居中，直达声不含空间信息），所以改用**已增强波形**当条件，而不是直达声。
- **joint AR** = AR-SSF + AR-TST 同时开启，是论文的最终方案。

### 2.4. 联合训练与伪 AR 训练

- **双优化器联合训练**：整条管线单次前向，跟踪与增强各用自己的优化器回传（不做交替微调），以保证两个子系统稳定互锁；跟踪与增强沿用 McNet / SpatialNet / SELDnet 的原损失与学习率调度。
- **pseudo-AR 训练**：为规避 AR 的固有不可并行性，采用 recurrent deep stacking 作为伪 AR 训练框架（论文指向 [18] 即 ARiSE 的路线）。
- 训练最多 100 epoch，或连续 10 个 epoch 两个优化器都无提升即收敛；两个 SSF 都用因果变体（SpatialNet 的窄带部分用 Mamba 状态空间模型）。
- 复杂度：AR 版本只增加**不到 1% 参数、1.5% MACs**。

## 3. 核心公式

**1. Ambisonics 球谐基（式 1）：**

$$b_n^m(\theta,\phi) = N_n^{|m|} P_n^{|m|}\big(\sin\phi\big)\begin{cases}\sin\big(|m|\,\theta\big), & m<0\\[2pt] \cos\big(m\,\theta\big), & m\geq 0\end{cases}$$

$\theta$ 为方位角、$\phi$ 为仰角，$P_n^{|m|}$ 为[[方向/AI语音/知识/基础概念/Legendre Functions（勒让德函数）|关联勒让德函数]]，$N_n^{|m|}$ 为归一化因子（本文取 ambiX 口径），$n \leq N$ 为阶数（本文 $N=1$）。归一化取正交或正交归一决定了基在单位球面内积下的性质。

**2. STFT 域观测模型（式 2）：**

$$\mathbf{Y}_{tk} = \mathbf{S}_{tk} + \mathbf{V}_{tk}$$

$t$、$k$ 为帧与频点下标；$\mathbf{S}_{tk}$ 是无回声目标语音对应的 Ambisonics 系数，$\mathbf{V}_{tk}$ 含干扰语音、目标语音的反射成分与噪声。任务目标是重建 $\mathbf{S}_{tk}$ 的 monopole 系数 $\widetilde{S}_{tk}$。

**3. Wigner-D 矩阵（式 3）：**

$$\widetilde{D}^{n}_{mm'}(\alpha,\beta,\gamma) = e^{-\mathrm{j}m\alpha}\, d^{n}_{mm'}(\beta)\, e^{-\mathrm{j}m'\gamma}$$

$\alpha,\beta,\gamma$ 为 ZYZ 约定的欧拉角，$d^n_{mm'}$ 为超越 Wigner-d 函数；复数基下按此展开，再经基变换转成与式 (1) 实球谐匹配的实值块对角正交矩阵 $\mathbf{D}$（ACN 向量化下块对角、酉/正交）。

**4. 自适应旋转转向的时变旋转矩阵（式 4）：**

$$\mathbf{D}_t = \mathbf{D}(\theta_t,\phi_t,0)$$

由目标当前 DoA $(\theta_t,\phi_t)$ 参数化；ZYZ 约定下即先绕 Y 轴（仰角）再绕 Z 轴（方位角），第三角取 0。声场对齐通过乘其逆（此处为正交矩阵的转置）$\mathbf{D}^{\top}$ 实现。

**5. 弱引导下的旋转矩阵合成（式 5）：**

$$\widehat{\mathbf{D}}_t = \mathbf{D}\Big(\theta_0 + \Delta\widehat{\theta}_t,\ \phi_0 + \Delta\widehat{\phi}_t,\ 0\Big)$$

$(\theta_0,\phi_0)$ 是目标的初始方向（唯一给定的先验），$\Delta\widehat{\theta}_t,\Delta\widehat{\phi}_t$ 是跟踪器对时变角偏差的估计——弱引导跟踪只需估偏差，不需估绝对方向。

**6. AR-TST 的时间对齐近似（式 6）：**

$$\widehat{\mathbf{D}}_t \approx \widehat{\mathbf{D}}_{t-1}$$

使上一帧的量（$\widehat{S}_{t-1}$、$\mathbf{Y}_{t-1}$）在当前帧坐标下可直接使用，从而把"匹配目标谱型的已增强信号"作为跟踪器的补充条件。

## 4. 结果口径

**实验设置**（合成集）：三名说话人的混响混合（LibriSpeech 按 Libri3Mix 配对），镜像法 + gpuRIR 仿真鞋盒房间，T60 0.2–0.5 s；远场假设下展开格林函数得到 Ambisonics 系数；FOA（N = 1）、ACN、ambiX 归一化；说话人按 [28] 的随机正弦轨迹持续移动，起始间隔至少 15°，与阵列距离全程保持 1–3 m；STFT 用 32 ms 平方根 Hann 窗、16 ms 跳步。增强骨干取 McNet 与 SpatialNet 的**因果**变体，跟踪骨干取因果 SELDnet；指标为侵入式 PESQ 与 ESTOI。

**实录**（真实录音）：FOA 阵列置于 9.5 m × 5.1 m × 2.4 m、T60 0.35 s 的房间中央；两名男性、一名女性非英语母语者同时朗读 Rainbow Passage 并在阵列前平面随机移动，制造多次交叉与显著变化的距离；切成约 30 s 的 3 段录音。无干净参考，故用非侵入式 NISQA 与下游 ASR（NeMo 的 QuartzNet15x5Base-En）的 WER 评估。

**Table 1（合成集；每格为 McNet / SpatialNet）**：

| 配置（Tracking / AR-SSF / AR-TST） | Params [M] | MACs [G/s] | PESQ | ESTOI [%] |
| --- | --- | --- | --- | --- |
| 未处理输入 | — | — | 1.08 | 31.6 |
| Oracle 方向（强引导） | 1.84 / 1.74 | 29.9 / 18.7 | 2.08 / 2.27 | 77.7 / 83.0 |
| Oracle 方向 + AR-SSF | 1.86 / 1.74 | 30.3 / 18.8 | 2.21 / 2.38 | 80.4 / 84.7 |
| 无跟踪（固定旋转转向） | 1.84 / 1.74 | 29.9 / 18.7 | 1.97 / 2.11 | 75.1 / 80.3 |
| 无跟踪 + AR-SSF | 1.86 / 1.74 | 30.3 / 18.8 | 2.08 / 2.21 | 78.5 / 82.2 |
| SELDnet 跟踪 | 2.13 / 2.03 | 30.0 / 18.8 | 1.98 / 2.11 | 75.5 / 80.6 |
| SELDnet + AR-TST | 2.13 / 2.03 | 30.0 / 18.8 | 2.03 / 2.18 | 76.6 / 81.6 |
| **SELDnet + AR-SSF + AR-TST（joint AR）** | 2.15 / 2.03 | 30.3 / 18.8 | **2.17 / 2.27** | **79.5 / 82.7** |

论文对这张表的读法：

- **强引导显著优于只用初始方向**（Oracle 2.08 / 2.27 与 77.7 / 83.0 对比固定转向的 1.97 / 2.11 与 75.1 / 80.3）。
- **仅用 SELDnet 跟踪相对固定旋转转向只有边际提升**（1.98 / 2.11 与 1.97 / 2.11）——跟踪精度不够时，连续方向并不值钱。
- **AR-TST 与 AR-SSF 各自都带来提升，joint AR 在所有弱引导方法中一致最优**。
- **joint AR 达到"对 SpatialNet 打平、对 McNet 明显超过无 AR 的强引导版本"**（2.17 / 2.27 与 79.5 / 82.7 对比 Oracle 的 2.08 / 2.27 与 77.7 / 83.0）。
- **复杂度代价**：AR 仅 +<1% 参数、+1.5% MACs；SELDnet 本身 < 300 k 参数、70 M/s MACs。
- **错误分布（图 3，仅趋势无数值）**：SELDnet 的句子级平均角度误差（MAE）在"最近干扰说话人角距"越小的时候越差；AR-TST 明显改善近距离下的跟踪，下游 PESQ 随之改善。图 4/图 5 分别给出合成集（PESQ / ESTOI，含 95% 置信区间）与实录（NISQA / WER）的趋势。

## 5. 测试基准与性能

**测试基准**：合成三说话人移动数据集（LibriSpeech + Libri3Mix 配对、镜像法/gpuRIR、T60 0.2–0.5 s、FOA N=1、轨迹见 [28]，起始间隔 ≥ 15°、距离 1–3 m）；真实录音（FOA 阵列、9.5 × 5.1 × 2.4 m、T60 0.35 s、3 人移动朗读 Rainbow Passage、约 30 s × 3 段）。基线阶梯为：未处理 → 固定旋转转向 → SELDnet 跟踪 → +AR-TST → +AR-SSF → joint AR，另以 Oracle 方向（强引导）为各类弱引导的上界；增强骨干在 McNet 与 SpatialNet 两种架构上重复验证。指标：合成集 PESQ / ESTOI，实录 NISQA / WER（QuartzNet15x5Base-En）；复杂度用 Params 与 MACs。

**性能指标**：完整数字见「结果口径」（joint AR 的 PESQ / ESTOI、Oracle 上界、各消融行与复杂度增量都列在该节表格中），此处不重复。

（来源：笔记正文「结果口径」，核验日期 2026-10-09）

## 6. 使用判断

- **适合**：Ambisonics 采集（球面阵 / 可编码 FOA）的多说话人动态场景；目标是"按方向锁定一个人并跟随其移动"的 TSE；想在不改动既有增强网络的前提下把 McNet / SpatialNet 之类**非转向架构**变成空间选择滤波器；延迟敏感（因果实现、AR 只增极少算力）。
- **不适合**：只有普通多通道麦阵、无法拿到 Ambisonics 编码的工程；需要说话人身份线索（enrollment / 视觉）而非方向线索的场景；离线高保真重制（AR 的收益来自流式时序反馈）；说话人静默或频繁切换目标时未验证。
- **风险**：**方向错就全错**——弱引导只给初始方向，初始 DoA 一旦偏离目标（如开局被遮挡或估错）整段可能锁错人；AR 存在跨帧误差累积（论文只测约 30 s 录音）；全流程评估固定在 FOA、仿真用远场假设直接生成球谐系数，真实编码器误差与更高阶 Ambisonics 的行为未验证；基线对比只在 McNet / SpatialNet 两个骨干上，未与其他 Ambisonics 域或阵列无关路线同条件横评。

## 7. 关键来源

- [Adaptive Rotary Steering with Joint Autoregression for Robust Extraction of Closely Moving Speakers in Dynamic Scenarios（arXiv:2601.12345）](https://arxiv.org/abs/2601.12345)
  - 内容定位：原始论文，ICASSP 2026 接收；汉堡大学信号处理组（Kienegger & Gerkmann）。
  - 用途：Ambisonics 信号模型与 Wigner-D 旋转公式、fixed/adaptive rotary steering 定义、AR-SSF / AR-TST 互连、Table 1 全部数值与实验设置。
  - 核验日期：2026-10-09
- [项目页（sp-uhh.github.io/adaptive-rotary-steering）](https://sp-uhh.github.io/adaptive-rotary-steering/)
  - 内容定位：作者提供的轨迹可视化、录音视频与听测样例（论文正文与图 2 均指向此页）。
  - 用途：核对移动轨迹形态与真实录音的主观效果。
  - 核验日期：2026-10-09

## 8. 相关对象

- [[方向/AI语音/团队/UHH Gerkmann Group（汉堡大学 Gerkmann 组）|UHH Gerkmann Group]]：作者团队（Timo Gerkmann 组）。
- [[方向/AI语音/模型/WG-Auto-HOA|WG-Auto-HOA]]：同组姊妹工作（Kienegger & Gerkmann，IWAENC 2026）——同样用帧级 AR 反馈 + 仅初始方向引导，但那篇在 Ambisonics 域把 AR 反馈接在**掩码估计 + 线性 MVDR** 上做移动说话人提取，本文走"声场旋转转向 + 神经时频 / 线性空间解耦"；两篇的 "autoregressive" 同指逐帧递推、均非生成式建模。
- [[方向/AI语音/模型/ARiSE|ARiSE]]：同一"帧级 AR 反馈"范式的前驱，本文明确以它（引文 [18]）为起点并把单说话人多通道场景推广到 TSE；pseudo-AR 训练也沿用其思路。
- [[方向/AI语音/模型/McNet|McNet]]：本文两个下游 SSF 骨干之一（另一个 SpatialNet 无独立页）；rotary steering 让不做方向条件化的它直接当空间选择滤波器用。
- [[方向/AI语音/知识/基础概念/TSE（目标说话人提取）|TSE]]：本文的任务本体，线索模态限定为方向。
- [[方向/AI语音/知识/基础概念/DOA（到达方向）|DOA]]：本文既是跟踪目标（时变 DoA），又是弱引导里唯一给定的先验。
- [[方向/AI语音/知识/技术路线/Spatial-Guided SE（空间引导与多模态增强）|Spatial-Guided SE]]：DOA 条件 TSE 路线的动态场景分支；该页记的"近方向多人困难"正是本文用 AR 时频谱反馈去补的那块。
- [[方向/AI语音/知识/技术路线/Array-Agnostic SE（阵列无关语音增强）|Array-Agnostic SE]]：本文属其中的"规范空间表示"（Ambisonics）口径。
- [[方向/AI语音/模型/AmbiDrop|AmbiDrop]]、[[方向/AI语音/模型/MSEN（特征束多阶编码器）|MSEN]]：同为 Ambisonics / eigenbeam 规范空间域的参照对象（本文未做对比）。
- [[方向/AI语音/知识/基础概念/Beamforming（波束形成）|Beamforming]]、[[方向/AI语音/知识/基础概念/steering vector（导向矢量）|steering vector]]：显式指向权向量的传统路线，与"旋转声场"这条隐式转向路线互为对照。
- [[方向/AI语音/评估/PESQ|PESQ]]、[[方向/AI语音/评估/STOI 与 ESTOI|ESTOI]]、[[方向/AI语音/评估/NISQA|NISQA]]、[[方向/AI语音/评估/WER（词错误率）|WER]]：本文合成集与实录所用指标。
- [[方向/AI语音/数据集/LibriSpeech|LibriSpeech]]：合成集语音来源（按 Libri3Mix 配对）。
- [[方向/AI语音/知识/调研与地图/Array Speech Enhancement Frontier（阵列语音增强前沿调研）|阵列语音增强前沿调研]]：2026 动态声源 / Ambisonics 条目入口（该页尚未收录本文）。

## 9. 待验证

- 官方代码 / 权重未见（论文只给项目页），复现成本与训练时长未知。
- 只做到 FOA（N = 1）：更高阶 [[方向/AI语音/知识/基础概念/Higher-Order Ambisonics（高阶 Ambisonics）|HOA]]、真实球形阵编码误差、阵型/传感器缺失下的行为未测。
- 阵列无关性是"表示层"主张，未做跨几何 / 跨设备实验（与 [[方向/AI语音/模型/AmbiDrop|AmbiDrop]]、[[方向/AI语音/模型/MSEN（特征束多阶编码器）|MSEN]] 的 seen/unseen geometry 口径不同）。
- AR 误差跨帧累积：只测约 30 s 录音与 3 人场景，长录音、目标静默段、目标切换、更多说话人未验证。
- 初始方向错（弱引导先验失效）时的鲁棒性、以及目标丢失后的自恢复能力。
- MAE 的数值只在图 2 / 图 3 中以图形给出，论文未列表；本页因此未收录任何 MAE 数字。
- 与其它 Ambisonics 域方法、与生成式精修 / 增强（如精修类 refiner）能否叠加未验证。
- 任务内未报告 SI-SDR / SIR 等波形或分离指标，也没有客观空间失真度量（除跟踪 MAE 外）。

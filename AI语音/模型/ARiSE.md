---
title: ARiSE
类型: 模型
发表时间: 2025-05
时间依据: arXiv 首次提交日
任务:
  - 语音增强
  - 多通道增强
开放状态:
  - paper
aliases:
  - ARiSE
  - Auto-Regressive Multi-Channel Speech Enhancement
  - "ARiSE: Auto-Regressive Multi-Channel Speech Enhancement"
  - 自回归多通道增强
tags:
  - 类型/对象
  - 方向/AI语音
  - 任务/语音增强
  - 任务/多通道增强
  - 主题/阵列信号
  - 主题/流式
---

# ARiSE

## 0. 背景

**问题现场**：帧在线（流式）多通道语音增强需要在逐帧因果约束下利用空间与时序信息。

**ARiSE 的切入点**：把上一帧估计的目标语音与上一帧估计算出的波束形成混合作为当前帧 RNN 的额外输入，让增强器本体利用已增强历史帧的空间-时序信息（帧级自回归连接，额外开销小）。

## 1. 身份

`ARiSE`（Auto-Regressive Multi-Channel Speech Enhancement）是 Shen、Xueliang Zhang、Z.-Q. Wang（INTERSPEECH 2025，arXiv:2505.22051）提出的**自回归帧在线多通道增强**：把**上一帧估计的目标语音**与**上一帧估计算出的波束形成混合**作为当前帧 RNN 的额外输入——增强器本体利用已增强历史帧的空间-时序信息。

边界：帧在线（streaming）增强器本体（不是后处理 / 精修）；"自回归"指**帧间输入依赖**（区别于生成式自回归的 token 预测）；Z.-Q. Wang 组线（与 [[方向/AI语音/模型/Mixture to Beamformed Mixture（波束形成混合弱监督）|Mixture to Beamformed Mixture]] 同作者线）。

## 2. 核心机制

**模型**：$Y(t,f) = X(t,f) + N(t,f)$（$M$ 麦 STFT），目标 = 参考麦 $q$ 的直达语音，逐帧在线。

**自回归连接**（每帧 RNN 三个输入）：

$$
\hat{X}_q^{\text{NN}}(t) = \text{RNN}\!\left(Y(t),\ \hat{X}_q^{\text{BF}}(t),\ \hat{X}_q^{\text{NN}}(t-1)\right)
$$

- **(a) DNN 自身估计**：$\hat{X}_q^{\text{NN}}(t-1)$（上一帧输出）。
- **(b) 波束形成混合** $\hat{X}_q^{\text{BF}}$：MVDR 权重由 $t-1$ 帧前的估计计算（掩码 $\hat{Z}_q$ → SCM 累积 → $\hat{\mathbf{w}}_q(t-1,f) = [\hat{\Phi}_N^{-1}\hat{\Phi}_X / \mathrm{Tr}(\cdot)]\, \mathbf{u}_q$）。
  - **Eq. 5**：旧帧权重 × 旧帧混合 $\hat{X}_q^{\text{BF}}(t,f) = \hat{\mathbf{w}}_q^H(t-1,f) Y(t-1,f)$。
  - **Eq. 6（更优）**：旧帧权重 × **当前帧**混合 $\hat{\mathbf{w}}_q^H(t-1,f) Y(t,f)$——权重帧间稳定、输出与当前帧对齐。
- **额外开销小**：SCM 累积更新，DNN 只多两个输入特征。

**并行训练**（朴素 BPTT 展开太深太慢）：

- **PARIS 式**：每步两次迭代，第二次才优化——第一次零填充输入造成**输入失配**。
- **RDS 式**（epoch 缓存）：缓存上一 epoch 所有训练混合的预测与 BF 结果，逐 epoch 刷新、随收敛变准——消融中更优的训练器。
- ARiSE 在单张 RTX 3090 上 **< 1 周收敛**（非并行基线一周内未收敛；之后微调仅轻微提升）。

**骨干**：IGCRN（inplace gated convolutional recurrent network）——5 层 iGLU 编码 / 5 层 iTGLU 解码 + 单向 channel-wise LSTM（48 单元），轻量因果 T-F 模型；20 ms 窗 / 10 ms 移；训练 Adam lr 1e-3、参考麦 complex ratio mask、T-F L1。

## 3. 结果口径

**数据**：LibriSpeech + sound-ideas 噪声库、镜像法 RIR；测试 150 句 WSJ0 + NOISEX-92；**6 麦圆阵（半径 8 cm）**、4 噪声 + 1 说话人、T60 0.2–1.0 s、SNR −10~10 dB。

**Table 2 节选（ESTOI / PESQ）**：

| SNR / T60 | Mixture | IGCRN | IGCRN-MVDR | **ARiSE** |
|---|---|---|---|---|
| −5 dB / 0.3 | 0.513 / 1.31 | 0.726 / 2.05 | 0.732 / 2.18 | **0.805 / 2.39** |
| −5 dB / 0.5 | 0.475 / 1.28 | 0.681 / 1.92 | 0.644 / 2.05 | **0.747 / 2.17** |
| 0 dB / 0.3 | 0.640 / 1.61 | 0.837 / 2.53 | 0.838 / 2.35 | **0.884 / 2.82** |
| 5 dB / 0.3 | 0.767 / 1.94 | 0.902 / 2.92 | 0.900 / 2.53 | **0.928 / 3.13** |

- 全条件一致最优；注意 IGCRN-MVDR 的 PESQ 常低于纯 IGCRN（MVDR 后置反而伤感知指标）。
- **消融**（−5 dB）：RDS > PARIS；Eq. 6 > Eq. 5；**BF + DNN 估计一起用最佳**；**BF 单独远好于 DNN 估计单独**——"波束形成结果是远更有效的自回归连接"，多通道场景下 BF 是 AR 信号的关键。

## 4. 使用判断

- 适合：帧在线多通道增强、低 SNR（−5 dB 下增益最大）、算力轻量（IGCRN 骨干）。
- 不适合：离线场景（非因果信息更充分时 AR 收益待验证）；需要可解释波束输出的场景（BF 只是内部 AR 连接）。
- 风险：自回归误差跨帧累积（长音频行为待验证）；RDS 缓存训练依赖实现细节。

## 5. 关键来源

- [ARiSE: Auto-Regressive Multi-Channel Speech Enhancement（arXiv:2505.22051）](https://arxiv.org/abs/2505.22051)
  - 内容定位：原始论文，INTERSPEECH 2025。
  - 用途：AR 连接公式、并行训练、全部实验与消融。
  - 核验日期：2026-08-10
- [论文 HTML 版（ar5iv）](https://ar5iv.labs.arxiv.org/html/2505.22051)
  - 内容定位：同论文可读 HTML 版本。
  - 用途：公式与表格细节快速查阅。
  - 核验日期：2026-08-10

## 6. 相关对象

- [[方向/AI语音/模型/Mixture to Beamformed Mixture（波束形成混合弱监督）|Mixture to Beamformed Mixture]]：同作者线（beamformed mixture 作监督 / 特征的延续）。
- [[方向/AI语音/知识/基础概念/MVDR（最小方差无失真响应）|MVDR]]：AR 连接的 BF 来源（SCM 累积 + 掩码）。
- [[方向/AI语音/模型/CUSIDE-array|CUSIDE-array]]：流式前端对照（chunk 级 vs 帧级）。
- [[方向/AI语音/知识/基础概念/TF Mask（时频掩码）|TF Mask]]：掩码估计（complex ratio mask）。
- [[方向/AI语音/知识/调研与地图/Array Speech Enhancement Frontier（阵列语音增强前沿调研）|阵列语音增强前沿调研]]：2025 全神经端到端条目（补名）。

## 7. 待验证

- 官方代码 / 权重是否开放。
- 自回归误差累积在长音频 / 连续会议场景下的行为。
- 与生成式精修（[[方向/AI语音/模型/MeCo|MeCo]] 类）结合的可能性。

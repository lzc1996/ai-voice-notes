---
title: Normalizing Flow（归一化流）
类型: 概念
发表时间: 2015-05-21
时间依据: Rezende & Mohamed「Variational Inference with Normalizing Flows」arXiv v1 首次提交日（2015-05-21），NF 一词由此进入主流
相关方向:
  - 语音增强
相关模型:
  - "[[方向/AI语音/模型/AuK]]"
aliases:
  - 归一化流
  - normalizing flow
  - normalizing flows
  - NF
tags:
  - 类型/对象
  - 方向/AI语音
---

# Normalizing Flow（归一化流）

## 1. 身份

`Normalizing Flow`（归一化流，NF）是一类**用可逆变换把简单分布显式变形为复杂分布**的生成模型：从容易采样、密度可算的基础分布（通常 $\mathcal{N}(\mathbf{0},\mathbf{I})$）出发，经可逆可微变换 $\mathbf{x}=\mathcal{F}(\mathbf{z})$ 捏成目标分布。名字里的「归一化」指变换会显式补偿对空间的拉伸/压缩（Jacobian 项），保证输出仍是归一化的概率密度。

区别于其他生成范式的两个独特性质：

- **精确似然**：$\log p(\mathbf{x})$ 可精确计算，训练即极大似然，目标稳定、无模式坍塌；
- **双向免费**：采样（$\mathbf{z}\to\mathbf{x}$）与推理（$\mathbf{x}\to\mathbf{z}$）都是一次前向，无需迭代。

代价是**架构受限**：每层必须可逆且 Jacobian log-det 易算，不能直接堆任意网络。

## 2. 核心机制

### 2.1. 变量替换公式

$$\log p(\mathbf{x}) = \log p\!\left(\mathcal{F}^{-1}(\mathbf{x})\right) + \log\left|\det \mathbf{J}_{\mathcal{F}^{-1}}(\mathbf{x})\right|$$

训练 = 对上式做极大似然；可用性完全取决于「可逆 + Jacobian 好算」。

### 2.2. coupling layer：满足约束的经典构造

RealNVP 式耦合层把通道切两半 $(\mathbf{a},\mathbf{b})$，只变一半：

$$\mathbf{a}'=\mathbf{a}, \qquad \mathbf{b}'=\mathbf{b}\odot\exp(\mathbf{s}(\mathbf{a}))+\mathbf{t}(\mathbf{a})$$

其中 $\mathbf{s},\mathbf{t}$ 是任意网络（作用在被冻结的 $\mathbf{a}$ 上，自身无需可逆）。性质：

- **可逆**：$\mathbf{b}=(\mathbf{b}'-\mathbf{t}(\mathbf{a}))\odot\exp(-\mathbf{s}(\mathbf{a}))$ 解析可写；
- **Jacobian 三角阵**：$\log|\det\mathbf{J}|=\sum\mathbf{s}(\mathbf{a})$，开销近乎为零。

单层只动一半通道，故多层堆叠并交错通道翻转/置换，让每半都有机会被变换。

### 2.3. 为什么「可逆 + 有表达力」就能吸收任意非高斯结构

两个性质各自承担一半论证：

- **表达力 → 高斯化映射总存在**：一维情形精确成立——$Z_p=\Phi^{-1}(F_X(X))$（$\Phi$ 为高斯 CDF，$F_X$ 为 $X$ 自身 CDF）把任意连续变量精确变成标准高斯，变换单调可逆；高维推广为 Knothe–Rosenblatt 重排（逐维条件 CDF 变换构成的三角传输映射）。即「抹平非高斯结构的可逆变换」在数学上免费存在，NF 的多层 coupling + 通道翻转正是这类映射的可微逼近器。层数有限时吸收不完全，残差非高斯性留给下游。
- **可逆 → 约束不能造假**：若换成普通不可逆网络，把全部输入映到同一点即可让 KL 归零（退化高斯），约束形同虚设——信息被「删除」而非「重排」。可逆双射让 $\mathbf{z}_p$ 与 $\mathbf{z}$ 信息完全等价，变换只能重排不能删除，故 $\mathbf{z}_p$ 的高斯性一定是结构被真实扭平的结果——非高斯结构被**存进变换本身**而非销毁。

合起来的意义：「像高斯」与「装得多」从互斥变分工——结构复杂度由 flow 兜着，重建信息由 $\mathbf{z}$ 留着，生成侧的便利由高斯锚点保着。

## 3. 在 AuK-VAE 中的角色

[[方向/AI语音/模型/AuK|AuK-VAE]] 的 flow 用法与标准生成模型不同——**不用于生成数据，而用于正则化潜空间**：编码器输出 $\mathbf{z}$ 后，$\mathbf{z}_p=\mathcal{F}(\mathbf{z})$（4 层 residual coupling 夹通道翻转）,KL 约束打在 $q(\mathbf{z}_p|\mathbf{x})$ 对 $\mathcal{N}(\mathbf{0},\mathbf{I})$ 上；解码器与声学条件只用原始 $\mathbf{z}$。可逆性保证两者信息等价，表达力保证 flow 吸收全部非高斯结构——「必须像高斯」的约束落在可扭曲的 $\mathbf{z}_p$ 上，重建友好的 $\mathbf{z}$ 得以自由。训练后 flow 整体丢弃，推理零开销。详见 [[方向/AI语音/模型/AuK#3.3. AuK-VAE：flow-augmented 潜空间|AuK §3.3]]。

## 4. 与 Flow Matching 的区别

名字相近但属两套东西，AuK 恰好两者都用（VAE 挂 NF 做潜空间正则，主干用 flow matching 做生成）：

| | Normalizing Flow | [[方向/AI语音/知识/基础概念/Flow Matching（流匹配）]] |
|---|---|---|
| 变换形式 | 离散可逆层链 | 连续 ODE 速度场 |
| 训练目标 | 精确极大似然 | 速度回归（无精确似然） |
| 架构约束 | 强（coupling 等可逆结构） | 无（可用任意 Transformer） |
| 采样 | 一步直达 | 多步积分 |

## 5. 相关对象

- [[方向/AI语音/模型/AuK]]：NF 作为 VAE 潜空间正则器的近期大规模实例。
- [[方向/AI语音/知识/基础概念/Flow Matching（流匹配）|Flow Matching（流匹配）]]：名字易混的连续流生成范式，对比见 §4。

## 6. 关键来源

- [Variational Inference with Normalizing Flows（arXiv:1505.05770）](https://arxiv.org/abs/1505.05770)
  - 内容定位：Rezende & Mohamed 2015,NF 进入主流的原始文献（变分推断语境）。
  - 用途：概念源头锚点。
  - 核验日期：2026-09-15
- [Density estimation using Real NVP（arXiv:1605.08803）](https://arxiv.org/abs/1605.08803)
  - 内容定位：Dinh et al. 提出 real non-volume preserving 变换，affine coupling layer 的标准出处。
  - 用途：本页 §2.2 耦合层构造的依据；AuK-VAE residual coupling 的技术源头。
  - 核验日期：2026-09-15
- [AuK Technical Report（arXiv:2609.08936）](https://arxiv.org/abs/2609.08936)
  - 内容定位：§4.1 记录 4 层 residual coupling + 通道翻转的 flow 正则化配置与训练后即弃的用法。
  - 用途：本页 §3 的一手出处。
  - 核验日期：2026-09-15

## 7. 待验证

- 「residual coupling」相对标准 affine coupling 的具体改动（论文未展开，需看 AuK 代码确认）。
- NF 在语音生成中除 VAE 正则外的其他用法（如直接做 TTS 声学模型：Glow-TTS、Flow-TTS 一脉），是否值得单独立页。

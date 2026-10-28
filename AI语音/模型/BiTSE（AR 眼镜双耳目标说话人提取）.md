---
title: BiTSE（AR 眼镜双耳目标说话人提取）
类型: 模型
参数量: 约 2.6M
发表时间: 2026-08-10
时间依据: arXiv 首次提交日（v1）
任务:
  - 双耳目标说话人提取
  - 可穿戴阵列语音增强
团队: Selani A. Indrapala、Wageesha N. Manamperi（University of Moratuwa，斯里兰卡）
开放状态:
  - paper
aliases:
  - BiTSE
  - Binaural Target Speaker Extraction in Noisy Multi-Talker Environments for AR Glass Arrays
tags:
  - 类型/对象
  - 方向/AI语音
  - 任务/目标说话人提取
  - 主题/空间引导
---

# BiTSE（AR 眼镜双耳目标说话人提取）

## 0. 背景

**问题现场**：AR 眼镜场景下嘈杂多说话人环境（低 SNR、说话人重叠、头动与声源移动）中，只提取面前目标说话人的声音并保留双耳方向感——普通降噪不够，因为干扰也是语音。

**BiTSE 的切入点**：在 BCCTN 双耳复数卷积 Transformer 去噪骨干上加三个组件——DoA 方位感知自注意力（cyclic 位置编码）、VAD 活动段掩蔽、两阶段损失优化，用 ground-truth 目标方位与语音活动标签引导。

## 1. 身份

`BiTSE`（Binaural Target Speaker Extraction）是 University of Moratuwa 的 Indrapala 与 Manamperi 提出的 **AR 眼镜场景双耳目标说话人提取框架**（arXiv:2608.10106，2026-08，CC BY 4.0）：在 BCCTN 双耳复数卷积 Transformer 去噪骨干上加三个组件——DoA 方位感知自注意力（cyclic 位置编码）、VAD 活动段掩蔽、两阶段损失优化，用 **ground-truth 目标方位 + 语音活动标签**做引导，在 SPEAR challenge 数据集（D2/D3/D4）上评测。

边界：它是**引导条件全给 oracle** 的离线研究（DoA 轨迹与 VAD 均取数据集标注，20 Hz 采样），不含 DOA 估计器与 VAD 检测器；只用 SPEAR 6 麦阵列中的第 5、6 通道（左右耳位）做双耳输入；指标只报 SegSNR 与 PESQ，无主观评测、无双耳空间保真指标。

**问题场景**（一句话版）：你戴 AR 眼镜坐在嘈杂餐厅，多个方向同时有人说话，你想让设备**只提取你面前那个人的声音**放大给你听，且左右耳保留方向感。拆解成三层：① 普通降噪不够——干扰也是语音，降噪模型会把所有说话人都留下；② 所以要做目标说话人提取（TSE）——给模型"要谁"的线索，BiTSE 的线索是**目标方向（DoA）+ 目标什么时候在说话（VAD）**，它的全部增量就是怎么把这两个线索有效喂进网络；③ 提取结果还要是**双耳**的（保留耳间相位差，声音听起来仍来自那个方向），这是第二阶段 IPD 损失的作用。注意：它**不解决"怎么知道你要听谁"**——DoA 与 VAD 都是标注给定的，真实部署中方向估计与活动检测的误差传导未测。

## 2. 核心信息

- **输入**：SPEAR 6 通道 AR 眼镜阵列的第 5/6 通道（双耳左右）STFT + 目标说话人 DoA 轨迹（20 Hz，帧对齐）+ 目标 VAD 标签。
- **输出**：双耳两通道目标说话人信号（CRM + VAD 掩蔽后 iSTFT）。
- **规模**：约 2.6M 参数；azimuth-aware 注意力 16 头。
- **任务口径**：低 SNR、多说话人重叠（D4 中 26%/43%/29% 的音频含 2/3/4 个并发说话人）、含头动与声源移动的餐厅式嘈杂场景。

## 3. 核心机制

```text
双耳混合（L/R 两通道 STFT）
  -> BCCTN 复数卷积编码器（双分支对称）
  -> DoA 轨迹 -> cyclic 位置编码（D=40）-> L2 归一 + FC + PReLU
       -> 与编码器输出逐元素相乘（空间调制）
  -> 复数多头自注意力（16 头）
  -> 解码器 -> 每通道 CRM -> Ŝ_c = M_c · X_c
  -> VAD 二值掩蔽：S̃_c = V(t) · Ŝ_c（目标不活跃的帧直接清零）
  -> iSTFT -> 双耳目标语音
```

要点：

- **DoA 条件化是乘法调制而非拼接**：cyclic 位置编码把方位角映射为周期嵌入（避免 0°/360° 断裂），经 FC+PReLU 后与拼接的编码器输出逐元素相乘，再进复数 MHSA——空间先验以门控方式进入特征。
- **VAD 掩蔽是硬清零**：CRM 先逐 T-F 点估计，再乘 VAD 二值掩码；动机是目标静默段 CRM 输出不可靠，直接置零比让网络猜更稳。
- **两阶段损失**：第一阶段只优化 SegSNR（高学习率 η₁=0.001）先把去噪学稳；第二阶段加 IPD 与 STOI 损失（低学习率 η₂=0.0001）做感知质量与空间一致性的精修，避免破坏已学得的重建能力。
- 骨干 BCCTN（Tokala et al., ICASSP 2024）原本是单人双耳语音增强模型，BiTSE 的贡献是把它扩成 TSE：脚注明确三个增量即 DoA 注意力、活动掩蔽、两阶段损失。

## 4. 核心公式

cyclic 方位位置编码（沿用 Choi & Choi 2025）：

$$\mathrm{PE}_{\mathrm{cyc}}(\phi,2j)=\sin\Big(\sin(\phi)\cdot\frac{\alpha}{10000^{2j/D}}\Big),\qquad \mathrm{PE}_{\mathrm{cyc}}(\phi,2j+1)=\sin\Big(\cos(\phi)\cdot\frac{\alpha}{10000^{2j/D}}\Big)$$

其中 $j\in[0,D/2)$，实现取 $D=40$、$\alpha=20$，φ 用弧度；嵌入 L2 归一化后沿时间维广播。

两阶段掩蔽：

$$\hat{S}_{c}(t,f)=\mathbb{M}_{c}(t,f)\cdot X_{c}(t,f),\qquad \tilde{S}_{c}(t,f)=\mathbb{V}(t)\cdot\hat{S}_{c}(t,f)$$

$\mathbb{M}_c$ 为通道 $c\in\{L,R\}$ 的复数比率掩码（CRM），$\mathbb{V}(t)\in\{0,1\}$ 为目标活动帧标签。

两阶段损失：

$$\mathcal{L}_{\text{stage-1}}=\gamma\,\mathcal{L}_{\text{SegSNR}},\qquad \mathcal{L}_{\text{stage-2}}=\gamma\,\mathcal{L}_{\text{SegSNR}}+\alpha\,\mathcal{L}_{\text{IPD}}+\beta\,\mathcal{L}_{\text{STOI}}$$

其中 $\mathcal{L}_{\text{STOI}}=-\frac{\text{STOI}_L+\text{STOI}_R}{2}$；$\mathcal{L}_{\text{IPD}}$ 为语音掩码加权的目标/估计 IPD 绝对误差（IPD 按 BCCTN 口径由左右通道之比取 arctan 计算）；SegSNR 以 1024 样本帧 / 512 帧移分段（pysepm 实现）。权重 $\gamma=1$、$\alpha=5$、$\beta=1$。

## 5. 测试基准与性能

**测试基准**（论文 §4）：

- 数据：SPEAR（SPeech Enhancement for Augmented Reality）challenge 数据集——AR 眼镜 6 麦阵列、餐厅式真实嘈杂场景；本文只用第 5/6 通道（双耳）。三个子集难度递增：D2 仿真混响+环境噪声；D3 加说话人与听者移动；D4 高噪声+混响+头动+重叠语音。DoA 轨迹与 VAD 标签均为数据集标注（20 Hz）。预定义 Main/Dev 划分；训练前过滤掉活动语音占比 <60% 的片段。
- 配置：16 kHz；STFT 1024 窗 / 512 hop；Adam，batch 8，两阶段各 100 epoch（η₁=0.001 → η₂=0.0001）。
- 基线：6 通道 [[方向/AI语音/知识/基础概念/MVDR（最小方差无失真响应）|MVDR]] 波束形成（4 眼镜麦 + 2 耳内麦，导向矢量由目标 DoA 与 ATF 给出）、BCCTN、BCCTN+DoA。指标：SegSNR 与 PESQ。

**性能指标**（Table 1，SegSNR dB ↑ / PESQ ↑）：

| 模型 | D2 | D3 | D4 |
| --- | --- | --- | --- |
| Unprocessed | −8.69 / 1.45 | −8.67 / 1.46 | −7.34 / 1.21 |
| MVDR（6 通道） | −8.27 / 1.40 | −8.32 / 1.46 | −6.65 / 1.20 |
| BCCTN | −8.78 / 1.64 | −9.15 / 1.71 | −8.26 / 1.31 |
| BCCTN + DoA | −9.10 / 1.67 | −9.17 / 1.75 | −8.34 / 1.33 |
| **BiTSE** | **−2.57 / 1.72** | **−2.57 / 1.80** | **−4.05 / 1.34** |

读数要点：

- SegSNR 上 BiTSE 相对所有基线是**跳变式**提升（−8.x → −2.6），而 MVDR 与 BCCTN 系的 SegSNR 几乎与未处理持平——基线主要改善 PESQ，BiTSE 同时大幅改善两者。
- PESQ 绝对值仍很低（≤1.80），反映 SPEAR 场景极端困难；论文自评 "SegSNR 仍为负，但 PESQ 一致提升说明感知上的干扰噪声被有效压制"。
- MVDR 用满 6 通道仍几乎无提升，作者引 Hafezi et al. 的解释：自适应波束形成对 ATF/DoA 误差敏感，动态多说话人下会引入目标失真。

**损失消融**（Table 2，D2）：纯 SNR 损失去噪强但过平滑（SegSNR −2.50 / PESQ 1.66）；纯 SegSNR 保留时频结构更好；SegSNR + IPD（α=5）+ STOI（β=1）取得最佳组合 −2.57 / 1.72——两阶段方案的最终配置即由此选出。

## 6. 边界

- **全 oracle 引导**：DoA 与 VAD 都是 ground-truth 标注，论文明说此举是为隔离评估提取模块；真实部署还需 DOA 估计器与 VAD 的误差传导未测。
- **指标覆盖窄**：只有 SegSNR + PESQ；训练里用了 IPD/STOI 损失，但没有独立的双耳空间保真评测（如 ΔITD/ΔILD）；无主观听测（列入 future work）。
- 只验证双耳两通道（SPEAR 第 5/6 通道），未利用其余 4 个阵列通道——与用满 6 通道的 MVDR 基线对比时输入口径不对称（但结果仍大幅占优）。
- 单数据集（SPEAR D2–D4），无跨数据集泛化；实时性/量化部署仅列为 future work。
- VAD 硬清零在 VAD 标签错误或边界帧上会直接截断目标语音，无软化机制。

## 7. 发展脉络

- 骨干：BCCTN（Tokala et al., ICASSP 2024）双耳复数卷积 Transformer，原为单人双耳增强；BiTSE 将其扩展为 TSE。
- 方位编码：cyclic positional embedding 取自 Choi & Choi（ICASSP 2025，方向+时间戳引导的多通道目标声提取）——BiTSE 的 DoA+VAD 双线索设定与该工作同源。
- 数据与挑战：SPEAR challenge（Tourbabin et al., Forum Acusticum 2023），官方基线为 MVDR；阵列配置（4 眼镜麦 + 2 耳内麦）来自 Hafezi et al. 2023 的头戴阵列子空间混合波束形成。
- 资助：AHEAD（6026-LK/8743-LK）与斯里兰卡电信监管委员会 TRCSL 研究基金；致谢 Abhayapala 与 Dias；论文披露写作中使用生成式 AI 辅助。

## 8. 相关对象

- [[方向/AI语音/知识/基础概念/TSE（目标说话人提取）|TSE]]：任务范式；BiTSE 的引导线索是 DoA + VAD，属空间-时序线索分支。
- [[方向/AI语音/知识/技术路线/Spatial-Guided SE（空间引导与多模态增强）]]：所在技术路线。
- [[方向/AI语音/知识/基础概念/DOA（到达方向）|DOA]]：核心引导线索（本文取 ground-truth 轨迹）。
- [[方向/AI语音/知识/基础概念/MVDR（最小方差无失真响应）|MVDR]]：SPEAR 官方基线，本文对照对象。
- [[方向/AI语音/知识/基础概念/IPD（通道间相位差）|IPD]]：第二阶段损失的双耳空间线索项。
- [[方向/AI语音/评估/PESQ|PESQ]]、[[方向/AI语音/评估/STOI 与 ESTOI|STOI]]：评测与损失共用的指标口径。
- [[方向/AI语音/模型/Transformer-NBF（低功耗可穿戴实时神经波束形成）|Transformer-NBF]]：同属可穿戴/头戴阵列语音前端，但走波束形成+MCU 部署路线，与 BiTSE 的 TSE+oracle 引导研究口径互补。

## 9. 关键来源

- [BiTSE: Binaural Target Speaker Extraction in Noisy Multi-Talker Environments for AR Glass Arrays（arXiv:2608.10106）](https://arxiv.org/abs/2608.10106)
  - 内容定位：原始论文（v1 2026-08-10，eess.AS，CC BY 4.0；全文 HTML 已核），架构三组件、两阶段损失、SPEAR D2/D3/D4 全部结果与消融。
  - 用途：本笔记全部机制与数字的来源。
  - 核验日期：2026-10-15

## 10. 待验证

- 发表 venue：IEEE 排版但 arXiv 页未标注投稿目标。
- SPEAR 数据集第 5/6 通道对应「左右耳」的说法来自论文，与 SPEAR 官方通道定义（earpiece 位置）建议再核一次。
- IPD 损失按 BCCTN 口径写为 arctan(S_L/S_R)，该形式与标准 IPD 定义（相位差）的差异是否影响空间保真，论文未讨论。
- 无代码/权重链接；VAD 掩蔽在标签含误差时的敏感性未测。

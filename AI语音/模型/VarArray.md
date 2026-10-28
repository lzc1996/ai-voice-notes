---
title: VarArray（阵列几何无关连续语音分离）
类型: 模型
发表时间: 2021-10-26
时间依据: arXiv 首次提交日（v1 2021-10-12，v2 2021-10-26）；ICASSP 2022
任务:
  - 连续语音分离
  - 会议转写前端
团队: Takuya Yoshioka、Xiaofei Wang、Dongmei Wang、Min Tang、Zirun Zhu、Zhuo Chen、Naoyuki Kanda（Microsoft）
开放状态:
  - paper
aliases:
  - VarArray
  - vararray
  - VarArray: Array-Geometry-Agnostic Continuous Speech Separation
tags:
  - 类型/对象
  - 方向/AI语音
  - 任务/多通道分离
  - 主题/阵列无关
---

# VarArray（阵列几何无关连续语音分离）

## 0. 背景

**问题现场**：连续语音分离（CSS）模型通常绑定固定阵列几何与麦数，换阵列就要重训；会议转写前端需要一个不重训即可用于任意麦数/几何的分离模型。

**前序路线的缺口**：split-apply-combine（SAC）式做法不利用通道间非线性相关，且成本随麦数线性放大；几何绑定模型吃不到多种几何的大训练集。

**VarArray 的切入点**：置换无关特征（平均谱幅度 + 相对平均谱 IPD）+ TAC 跨通道层 + Conformer 分离骨干的凝聚式组合，第 3 个 block 后合并通道流以压平计算量随麦数的增长。

## 1. 身份

`VarArray` 是 Microsoft（Yoshioka 等，ICASSP 2022，arXiv:2110.05745）提出的**阵列几何无关[[方向/AI语音/知识/基础概念/CSS（连续语音分离）|连续语音分离（CSS）]]模型**：同一模型不重训即可用于任意麦数/几何的阵列，同时利用通道间非线性相关。它把三个此前独立提出的组件——**置换无关的特征组织**（平均谱幅度 + 相对平均谱的 IPD）、**[[方向/AI语音/知识/基础概念/TAC（变换-平均-拼接）|TAC]] 跨通道层**、**Conformer 分离骨干**——组合成一个高效整体，并以真实会议转写任务（AMI / 微软内部 MS）的端到端 WER 做评测。论文自称首个把 IPD 特征、Conformer CSS 与 TAC 凝聚式组合并在真实会议任务上充分评测的工作。

边界：VarArray 解决的是**几何/麦数无关**，但说话人侧固定 **K=2 输出流**（CSS 口径：只拆重叠，不做 diarization）；评测是会议转写 WER 而非信号级指标；分离输出走 MVDR 波束形成而非直接 mask 波形。

## 2. 核心信息

- **输入**：每通道一个特征向量 $\mathbf{z}_{mt}=[\mathbf{z}^{mag}_{mt},\mathbf{z}^{ipd}_{mt}]$——平均谱幅度 + 相对平均谱的逐通道 [[方向/AI语音/知识/基础概念/IPD（通道间相位差）|IPD]]，窗级归一；特征是**可变大小的集合**，不绑定通道索引顺序。
- **输出**：4 个 TF mask（说话人 ×2 + 平稳噪声 + 瞬态噪声，SSN 式）→ 稀疏化（每 T-F 点只留主导源）→ [[方向/AI语音/知识/基础概念/MVDR（最小方差无失真响应）|MVDR]] 波束形成 → 增益调整 → 2 路无重叠流给 ASR。
- **CSS 口径**：1.6 s 滑窗 / 0.4 s 移位，相邻窗 1.2 s 重叠段按 MSE 最小选置换做 stitching；训练用 [[方向/AI语音/知识/基础概念/PIT（置换不变训练）|uPIT]]。
- **关键工程点**：通道流在第 3 个 Conformer block 后合并成单流——计算量随麦数的增长率被压平。

## 3. 核心机制

- **置换无关特征**：$\bar{X}_{ft}$ 为跨麦克风平均的 STFT；$\mathbf{z}^{mag}_{mt}=(|\bar{X}_{ft}|^2)_f$，$\mathbf{z}^{ipd}_{mt}=\angle(X_{mft}/\bar{X}_{ft})_f$。所有通道共享同一平均参考 → 通道可任意置换、麦数任意。
- **TAC 变体**（式 1）：

$$
\mathbf{o}_{mt}^{\text{out}}=\Big[\text{ReLU}\big(A\mathbf{o}_{mt}^{\text{in}}\big),\;\frac{1}{M}\sum_{\mu\in\mathbb{M}}\text{ReLU}\big(B\mathbf{o}_{\mu t}^{\text{in}}\big)\Big]
$$

通道内变换与跨通道平均拼接；$A$、$B$ 各把维度减半以保总维度不变。TAC 在变换空间聚合全通道信息再回灌各通道，置换不变。
- **结构**：5 个 Conformer block（每 block 5 层 Conformer，4 头、64 维、33 长卷积核），前 3 个逐流并行、TAC 穿插其间，之后合并为单流。同色块共享参数。
- **对照 SAC**：split-apply-combine（同一模型逐通道跑再平均 mask）不利用通道间非线性、且成本随麦数线性放大；VarArray 用 TAC 解决前者、用早合并解决后者。
- **E2E 微调**：MIMO 式把 mask 估计 + MVDR + 特征变换 + S2S ASR 串成端到端网络，冻结 ASR 后端、用 uPIT 式交叉熵在 8.52 h 真实 AMI 训练数据上微调前端；stitching、mask 稀疏化、增益调整都进前向图（增益调整对含大量单说话人样本的训练集是关键）。

## 4. 测试基准与性能

**测试基准**（§4）：

- 训练：438 h 仿真混合（219 h × 两种几何），WSJ SI-284 干净语音 + 镜像法 RIR + 各向同性噪声（Habets–Gannot）+ MUSAN 方向噪声；每个 minibatch 随机抽 3–7 麦；batch 48 × 4 s。
- 链路：MIMO WLP 实时去混响 → CSS（VarArray）→ 每路独立 ASR（注意力 encoder-decoder）→ 转写合并；评测**全程无 ground-truth 切分**。
- 任务：AMI-MDM（8 麦圆阵 r=10 cm；8 麦与取奇数麦的 4 麦两档）与微软内部 MS（7 麦：6 麦圆阵 r=4.25 cm + 圆心麦；7 麦与 3 麦两档）；AMI 用 asclite 评分。

**性能指标**（Table 1，WER%，越低越好）：

| 数据 | 麦数 | BF1（单输出波束） | SAC | Fixed（几何绑定） | VarArray |
| --- | --- | --- | --- | --- | --- |
| AMI-dev | 8 | 25.0 | 18.3 | 18.8 | **17.7** |
| AMI-dev | 4 | 25.5 | 18.8 | — | **18.5** |
| MS | 7 | 17.6 | 16.0 | 16.0 | **15.5** |
| MS | 3 | 17.8 | 16.9 | — | **15.8** |

- VarArray 四种配置全面优于 SAC 与几何绑定基线；优于 Fixed 主要归因于无关模型能吃更大的训练集。
- 训练几何消融（Table 2）：AMI+MS 双几何训练在两个测试集都最好；单几何训练也有可观泛化，AMI 几何子集略优（作者归因于麦间距多样性更大）。
- E2E 微调（Table 3，AMI-eval 含重叠段）：MS 预训练 22.2 → 21.5；AMI+MS 预训练 20.5 → **20.4**；AMI-dev 含重叠段最好 17.5（即摘要口径的 17.5%/20.4%）。增益在非重叠段更明显——作者解读：E2E 让分离输出"对 ASR 更友好"，而非主要靠更强的干扰抑制。

## 5. 边界

- **K=2 固定**：只处理两人重叠的主流会议场景；不做说话人计数/diarization，三人以上同时说话出范围。
- 输出走 MVDR 闭式波束形成：分离质量受 mask → 协方差估计链约束，不是直接波形映射。
- 评测只有 WER 口径（无 SI-SDR/PESQ 信号级表），且 MS 为微软内部集、不可复现；AMI 用 full-corpus ASR 划分、dev 实际当 evaluation 用。
- 几何多样性仅限两种圆阵（训练集只含 AMI/MS 几何的 RIR），泛化结论限于"同类圆阵换麦数/半径"。
- 与 personalized 版本的关联：作者提到平行工作把 array-geometry-agnostic 用于个性化降噪（Taherian et al., arXiv:2110.10330）。

## 6. 发展脉络

- 组件来源：TAC（Luo et al., ICASSP 2020）提供置换/麦数不变层；Conformer CSS（Chen et al., ICASSP 2021）；IPD 特征（Yoshioka et al., ICASSP 2018）；SSN 三源 mask（Yoshioka et al., Interspeech 2018）。
- 下游影响：库内把 AmbiDrop 标为"VarArray 思路的延续"（调研页口径）——同一目标（array-agnostic）换实现路线：VarArray 靠置换无关特征 + TAC 聚合，AmbiDrop 靠 [[方向/AI语音/知识/基础概念/ASM（Ambisonics 信号匹配编码）|ASM]] 编码到规范空间 + dropout。
- 作为基线：[[方向/AI语音/模型/UniArray|UniArray]] 的主对照之一（VarArray / VarArray+CA）；[[方向/AI语音/模型/SFB-NSE|SFB-NSE]] 被点名"未与 VarArray 等 array-agnostic 主流方法对比"。

## 7. 相关对象

- [[方向/AI语音/模型/AmbiDrop|AmbiDrop]]：同一 array-agnostic 目标的后继路线（规范空间 + dropout）。
- [[方向/AI语音/模型/UniArray|UniArray]]、[[方向/AI语音/模型/SFB-NSE|SFB-NSE]]：以 VarArray 为基线/缺口的同路线模型。
- [[方向/AI语音/模型/REDnet|REDnet]]：同属"可变输入维度"路线——REDnet 的 RE 即针对 TAC 式全局平均的改进（逐麦递归累积），且额外放开说话人数。
- [[方向/AI语音/知识/基础概念/PIT（置换不变训练）|uPIT]]：局部窗内训练准则。
- [[方向/AI语音/知识/基础概念/IPD（通道间相位差）|IPD]]：核心空间特征（相对平均谱口径）。
- [[方向/AI语音/知识/基础概念/MVDR（最小方差无失真响应）|MVDR]]：mask 到波形的转换件。
- [[方向/AI语音/知识/技术路线/Array-Agnostic SE（阵列无关语音增强）|Array-Agnostic SE]]：所在技术路线。

## 8. 关键来源

- [VarArray: Array-Geometry-Agnostic Continuous Speech Separation（arXiv:2110.05745）](https://arxiv.org/abs/2110.05745)
  - 内容定位：原始论文（v2 2021-10-26，ICASSP 2022；全文 HTML 已核），特征设计、TAC 变体公式、早合并结构、CSS 链路、AMI/MS 全部 WER 结果与 E2E 微调口径。
  - 用途：本笔记全部机制与数字的来源。
  - 核验日期：2026-10-15

## 9. 待验证

- CSS 与 TAC 已建独立概念页（[[方向/AI语音/知识/基础概念/CSS（连续语音分离）|CSS]]、[[方向/AI语音/知识/基础概念/TAC（变换-平均-拼接）|TAC]]）。
- VarArray 的参数量/实时性口径论文未报（会议系统离线链路）；开源情况未确认（论文未给代码链接）。
- "AMI 几何子集训练更好是因麦间距多样性"为作者推测，无消融验证。

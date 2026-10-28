---
title: MiDashengLM-Spatial
类型: 模型
参数量: 7B（作者按 8B 量级与同档模型对比）
发表时间: 2026-10-08
时间依据: arXiv 首次提交日（v1）；2026-10-15 公开宣传开源
任务:
  - 音频理解
  - 空间音频理解
  - 声事件定位与检测
团队: Xiaomi Dasheng Team（小米）
开放状态:
  - paper
  - code
  - checkpoint
aliases:
  - MiDashengLM-Spatial-7B
  - 小米空间音频理解大模型
tags:
  - 类型/对象
  - 方向/AI语音
  - 主题/音频大模型
  - 主题/空间音频
相关评估:
  - "[[方向/AI语音/评估/MMAU-Pro（音频通用智能基准）]]"
---

# MiDashengLM-Spatial

## 0. 背景

**问题现场**：让一个音频大模型同时具备通用音频理解与空间感知（空间问答、带空间指称的转写、声事件定位），且不牺牲通用理解能力。

**前序路线的缺口**：既有空间音频方案多为空间任务专建、牺牲通用理解；单声道 LALM 输入做通道平均，丢失左右空间线索。

**MiDashengLM-Spatial 的切入点**：在 MiDashengLM-7B 语义通路外新增 Spatial-Dasheng 空间编码器，用单向 HSSC 注入融合，号称首个开源端到端"通用音频理解 + 空间感知"统一 LALM。

## 1. 身份

`MiDashengLM-Spatial` 是小米 Dasheng 团队（arXiv:2610.11156，2026-10-08）提出的**双分支空间音频理解大模型**：在 MiDashengLM-7B 的语义通路之外新增空间音频编码器 Spatial-Dasheng，通过单向的层级语义→空间条件注入（HSSC）整合，号称**首个开源的端到端"通用音频理解 + 空间感知"统一架构** LALM。权重与代码已公开（GitHub + HuggingFace）。

边界：不是传统 SELD 系统（输出不是结构化标签而是开放式语言），也不是单声道 LALM 加提示词——空间信息由专用编码器显式建模。输入限定**双耳（2 通道）**音频，不是任意阵列。

## 2. 核心信息

- **输入**：16 kHz、最长 60 s 的双耳音频 → 双通道 64-bin log-mel（512 Hann 窗 / 160 hop）；单声道数据复制成双通道对齐格式。
- **编码器双分支**：32 层 Dasheng 语义编码器（= MiDashengLM 原音频编码器，不动）+ 12 层 Dasheng 空间编码器（Spatial-Dasheng）。
- **输出**：经 adapter 融合成统一 audio token，进 MiDashengLM 的 LLM 生成文本（场景描述、空间问答、带空间指称的转写）。
- **训练数据**：自合成 1M 条空间场景音频（30–60 s，最多 3 个重叠源）+ 6M 空间 QA 对，约 13,000 小时双耳音频。

## 3. 核心机制

```text
双通道 log-mel
  ├─ 语义分支：Dasheng Semantic Encoder（32 层，冻结原通路）
  └─ 空间分支：Spatial-Dasheng（12 层）
       ↑ 每 8 语义层 → 每 3 空间层注入一次（HSSC，4 个 merge adapter，单向）
  → 末端融合 E_Audio = E^Sem + Adapter(E^Spa)
  → LLM（MiDashengLM 基座）→ 文本输出
```

- **Spatial-Dasheng**：基于 Dasheng-Base（MAE 预训练的帧级 ViT），前置一个轻量 CNN 通道融合模块把多通道输入压成单通道兼容格式；用 multi-ACCDOA 输出格式做 SELD 预训练——$N$ 条 track，每条最多报一个事件的活动性 + DOA + 距离，训练用 [[方向/AI语音/知识/基础概念/PIT（置换不变训练）|PIT]] 解决 track 排列对齐。**不显式建模事件类别**（类别语义由 LLM 侧承担）。
- **HSSC（层级语义到空间条件注入）**：重叠源场景下空间线索必须与语义线索配对；HSSC 把语义分支中间层表示经 MLP adapter 注入空间分支对应层，**单向**——空间表示不回灌语义分支，保证原语义前向通路结构不变。
- **三阶段课程**：I. Spatial-Dasheng 在合成 SELD 数据上预训练（帧级活动性 + DOA + 距离）；II. 初始化进 MiDashengLM-Spatial，在空间音频-文本对（事件级 + 场景级描述）上做对齐；III. 单声道 + 双耳全量混合微调，侧重空间 QA，保持通用与空间的平衡。
- **数据合成管线**：image method / Pyroomacoustics 模拟数千房间的 RIR（直线与圆弧轨迹）+ ARI HRTF 渲染双耳；静态源卷积单个 RIR、移动源沿轨迹做时变卷积；场景描述由 Gemma-4-31B 从元数据 + 原始 caption 合成；QA 由模板从元数据**确定性生成**（源定位、运动轨迹、群体时空关系三类），第四类"空间指称内容理解"用带说话人标注的对话语料（如 AliMeeting）渲染后由 LLM 出题、再把说话人确定性映射回空间方位。

## 4. 核心公式

multi-ACCDOA 学习目标（第 $n$ 条 track、第 $t$ 帧）：

$$\mathbf{O}_{nt}=[\mathbf{P}_{nt},\,d_{nt}],\qquad \mathbf{P}_{nt}=a_{nt}\mathbf{R}_{nt}$$

其中 $a_{nt}\in\{0,1\}$ 为事件活动性，$\mathbf{R}_{nt}=(x_{nt},y_{nt},z_{nt})$ 为单位球面上的 DOA 向量（活动时 $\lVert\mathbf{R}_{nt}\rVert=1$），$d_{nt}\in(0,+\infty)$ 为源距离。

track 级 PIT 损失：

$$\mathcal{L}_{\mathrm{PIT}}=\sum_{t}\min_{\alpha\in\mathrm{Perm}(t)}\left\{\lambda\cdot\ell_{\mathrm{ACCDOA}}(t,\alpha)+(1-\lambda)\cdot\ell_{\mathrm{Dist}}(t,\alpha)\right\}$$

其中 $\alpha$ 为帧 $t$ 上的 track 排列，$\ell_{\mathrm{ACCDOA}}$ 取 MSE、$\ell_{\mathrm{Dist}}$ 取 MAPE，$\lambda$ 平衡两项。

HSSC 注入与末端融合：

$$E_{3k-1}^{\mathrm{Spa}}\leftarrow E_{3k-1}^{\mathrm{Spa}}+\mathrm{Adapter}_{k}\left(E_{8k-1}^{\mathrm{Sem}}\right),\quad k\in\{1,2,3,4\}$$

$$E_{\mathrm{Audio}}=E^{\mathrm{Sem}}+\mathrm{Adapter}\!\left(E^{\mathrm{Spa}}\right)$$

其中 $E^{\mathrm{Sem}}$、$E^{\mathrm{Spa}}$ 为语义/空间分支的中间与最终表示，Adapter 为 MLP 投影。

## 5. 测试基准与性能

**测试基准**（论文 §5）：SELD 用三个真实场景集（EasyCom、STARSS23 立体声版、MRSSound）+ 合成 SynthBinaural-Test，指标 $\mathrm{F}_{45°/1}$、$\mathrm{DOAE}_{\mathrm{CD}}$、$\mathrm{RDE}_{\mathrm{CD}}$；空间理解用 [[方向/AI语音/评估/MMAU-Pro（音频通用智能基准）|MMAU-Pro]] 空间子集与 STAR-Bench 的 Spatial Reasoning 子集（均为真实录音），另加**声道交换 ACR**（左右互换后两答皆对的比例）验证空间接地；通用能力用 MMAU/MuChoMusic/LibriSpeech/AISHELL-2/GigaSpeech2/MusicCaps 等单声道基准。

**Spatial-Dasheng 的 SELD 表现**（$\mathrm{F}_{45°/1}$↑ / $\mathrm{DOAE}_{\mathrm{CD}}$↓ / $\mathrm{RDE}_{\mathrm{CD}}$↓）：

| 模型 | EasyCom F | STARSS23 F | MRSSound F | 合成集 F |
|---|---|---|---|---|
| Spatial-AST | 6.9 | 48.6 | 16.5 | 50.9 |
| PSELDNets | 26.1 | 57.5 | 15.9 | 75.2 |
| **Spatial-Dasheng** | **31.6** | 54.1 | **26.4** | 72.2 |

EasyCom 与 MRSSound 上显著领先，STARSS23 与合成集上与 PSELDNets 互有胜负；值得注意的是它**只在双耳数据上训练**却泛化到立体声 STARSS23，作者据此推断模型能有效利用 [[方向/AI语音/知识/基础概念/ILD（双耳声级差）|ILD]] 定位。

**空间理解基准**（真实录音，Accuracy / 声道交换 ACR）：

| 模型 | 输入 | MMAU-Pro 空间 Acc | MMAU-Pro Chan-Swap ACR | STAR-Bench SR Acc | STAR-Bench Chan-Swap ACR |
|---|---|---|---|---|---|
| Gemini-3.6-Flash | Mono | 48.3 | 12.8 | 47.0 | 10.5 |
| Qwen3-Omni-30B | Mono | 36.6 | 0.0 | 44.7 | 0.0 |
| BAT（唯一开源双耳基线） | Binaural | 23.7 | 7.4 | 0.0 | 0.0 |
| MiDashengLM-7B | Mono | 18.2 | 0.0 | 44.3 | 0.0 |
| **MiDashengLM-Spatial-7B** | **Binaural** | **55.4** | **33.1** | **70.3** | **72.6** |
| 随机 / 人类参考 | – | 21.2 / 88.2 | 13.5 / – | 33.3 / 73.7 | 11.1 / – |

单声道模型的声道交换 ACR 近零（通道平均使表示对左右不敏感），MiDashengLM-Spatial 大幅领先——作者以此证明空间推断**接地于双耳线索**而非语言先验。STAR-Bench SR 上 70.3 已接近人类 73.7。

**通用能力保持**（Table 3）：与 MiDashengLM-7B 持平甚至更优——MMAU-Pro 56.4 vs 55.9、LibriSpeech test-clean WER 1.8 vs 3.6、GigaSpeech2 越南语 16.2 vs 17.7、MusicCaps FENSE 60.0 vs 59.1。**消融**：HSSC 单向版在 18 项中 13 项优于双向注入版；去掉单声道语料仍保留大部分通用能力（AISHELL-2 上接近全量模型，尽管空间语料无中文转写）。

**空间接地的细粒度读数**（合成测试集）：OV1 子集事件召回 >70%、运动状态一致 >88%、时序一致 >96%，但运动轨迹精确匹配 **<20%**；空间 QA 总体 80.6%（OV1）/ 66.9%（OV2，随机基线 28.8%），最弱项是需跨全场景整合的 Spatial Counting。

## 6. 边界

- **仅双耳**：两通道输入无法解上下/前后模糊（STARSS23 评测因此只看左右方位角）；不是任意阵列方案。
- **细粒度空间是短板**：轨迹精确匹配 <20%、多源重叠复杂场景与 Spatial Counting 明显较弱——作者自己在结论中承认。
- **训练数据全仿真**：sim-to-real 在 SELD 上验证过，但空间理解基准的绝对水平仍低于人类。
- **基准 Acc 不足以证明空间接地**：作者明确警告强模型可用语义先验"猜对"空间答案（MMAU-Pro 尤其如此），因此必须搭配声道交换 ACR 读数。
- "首个开源端到端统一"是作者的范围声明（to our knowledge），闭源或同期工作不保证覆盖。

## 7. 发展脉络

- 上游：Dasheng-Base（2024，MAE 帧级 ViT）→ MiDashengLM / MiDashengLM-7B（2025，通用 LALM 基座）→ **MiDashengLM-Spatial**（2026-10）。
- SELD 线：ACCDOA / EINV2 → PSELDNets（预训练 SOTA）；Spatial-Dasheng 用 multi-ACCDOA + PIT 继承这条线。
- 空间 LALM 线：encoder-only（ELSA、Spatial-CLAP、SALM）与 encoder-decoder（BAT、OWL、SPUR、PhaseCoder）——既有方案多为空间任务专建、牺牲通用理解；本作的卖点恰是"不牺牲"。

## 8. 相关对象

- [[方向/AI语音/知识/基础概念/PIT（置换不变训练）|PIT]]：Spatial-Dasheng SELD 预训练的 track 排列对齐准则。
- [[方向/AI语音/评估/MMAU-Pro（音频通用智能基准）|MMAU-Pro]]：空间子集 + 声道交换 ACR 是本文核心评测。
- [[方向/AI语音/模型/Qwen3-Omni|Qwen3-Omni]]、[[方向/AI语音/模型/Qwen2.5-Omni|Qwen2.5-Omni]]：单声道 LALM 对照组（通道平均丢空间线索）。
- [[方向/AI语音/知识/基础概念/ILD（双耳声级差）|ILD]]、[[方向/AI语音/知识/基础概念/DOA（到达方向）|DOA]]：空间感知的声学线索与输出形式。
- [[方向/AI语音/数据集/AliMeeting|AliMeeting]]：第四类空间 QA 的对话语料来源。

## 9. 关键来源

- [MiDashengLM-Spatial: Unifying General Audio Understanding and Spatial Awareness（arXiv:2610.11156）](https://arxiv.org/abs/2610.11156)
  - 内容定位：原始论文（全文 HTML 已核），双分支架构、HSSC、三阶段课程、数据合成管线与全部基准结果。
  - 用途：本笔记全部机制与数字的唯一权威来源。
  - 核验日期：2026-10-15
- [xiaomi-research/midashenglm-spatial（GitHub）](https://github.com/xiaomi-research/midashenglm-spatial)
  - 内容定位：官方代码仓库（论文摘要页声明）。
  - 用途：复现与推理。
  - 核验日期：2026-10-15
- [mispeech/midashenglm-spatial（HuggingFace）](https://huggingface.co/mispeech/midashenglm-spatial)
  - 内容定位：官方模型权重（论文摘要页声明）。
  - 用途：权重获取。
  - 核验日期：2026-10-15

## 10. 待验证

- 许可证：新闻稿称 Apache-2.0，仓库 LICENSE 文件待核。
- MiDashengLM-7B 的 LLM 基座身份与 Spatial-Dasheng 参数量拆分（论文未单独列出）。
- "首个开源端到端统一 LALM"声明与 OWL / PhaseCoder 等同期工作的开源状态核对。
- 中文空间音频理解能力（空间语料无中文转写，仅消融侧面涉及 AISHELL-2）。
- 智能家居 / 座舱场景的落地形态（新闻稿提到"人车家全生态"，无论文内证据）。
- MiDashengLM 基座尚无独立笔记，第二次用到再建。

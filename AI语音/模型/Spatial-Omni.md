---
title: Spatial-Omni
类型: 模型
发表时间: 2026-06-09
时间依据: arXiv 首次提交日（v1）
任务:
  - 音频理解
  - 空间音频理解
  - 声事件定位与检测
团队: 腾讯混元 × 浙江大学
开放状态:
  - paper
  - code
  - checkpoint
  - dataset
aliases:
  - Spatial Omni
  - "Spatial-Omni: Spatial Audio Understanding Integration in Multimodal LLMs via FOA Encoding"
  - SO-Encoder
tags:
  - 类型/对象
  - 方向/AI语音
  - 任务/空间音频理解
  - 任务/声事件定位与检测
  - 主题/音频大模型
  - 主题/空间音频
许可证: 代码 Apache-2.0；发布权重 CC BY-NC-SA 4.0
相关模型:
  - "[[方向/AI语音/模型/Qwen2.5-Omni]]"
  - "[[方向/AI语音/模型/Qwen3-Omni]]"
  - "[[方向/AI语音/模型/PhaseCoder]]"
相关评估:
  - "[[方向/AI语音/评估/MMAU-Pro（音频通用智能基准）]]"
---

# Spatial-Omni

## 0. 背景

**1) 问题现场**：通用 LALM 与 Omni LLM 通常先把音频降为单声道，再提取语义特征；因此声源方向、距离、运动与多源空间关系在进入 LLM 前已经丢失，无法可靠回答“左边是什么声音”“哪个声源更近”等问题。

**2) 前序路线的缺口**：已有空间音频 LLM 证明了显式空间线索的价值，但不少方案需要重训或大改原音频编码器，可能损害其预训练语义能力，也不利于同一模型兼顾单声道与空间音频。与此同时，FOA 空间音频的大规模 QA 语料和覆盖定位、关系、运动及复杂推理的统一基准不足。

**3) Spatial-Omni 的切入点**：保留基座原音频编码器，另加并行的 SO-Encoder，把 FOA 作为独立空间模态投影为少量 spatial tokens；再以 SO-Dataset、SO-QA 和 SO-Bench 补齐训练与评测闭环。

## 1. 身份

`Spatial-Omni` 是腾讯混元与浙江大学提出的**空间音频理解升级框架**，不是单一固定骨干的模型：同一 SO-Encoder、projector 与分阶段训练方法可接入 Qwen Omni、Phi-4-MM、Audio Flamingo 3、Kimi-Audio 等基座，形成 SO-7B、SO-30B、SO-4B、SO-AF3、SO-Kimi 等变体。

边界：它处理的是 **FOA 空间音频理解**，输出文本答案而非增强或生成的音频；不是从 360° 视频生成空间音频的 OmniAudio，也不是任意麦克风几何输入方案。默认原音频塔保持冻结，但 LLM LoRA、projector 和后续阶段的 SO-Encoder 会训练，因此“保留语义通路”不等于整个基座完全不变。

## 2. 核心信息

- **输入**：16 kHz、四通道 FOA，采用 AmbiX/ACN 顺序 `[W,Y,Z,X]`；当前最多使用前 20 秒。W 通道进入基座原音频编码器，完整 FOA 进入 SO-Encoder。
- **输出**：与原音频、视觉和文本 token 联合送入 LLM，生成检测、定位、空间关系、运动分析、多跳推理、场景描述和空间条件语音识别等文本答案。
- **空间 token 成本**：SO-Encoder 输出 10 Hz 帧级表示，projector 压缩为 2.5 tokens/s，即 20 秒输入对应 50 个空间 token。
- **已发布变体**（截至 2026-10-26）：SO-4B（Phi-4-MM）、SO-AF3（Audio Flamingo 3）、SO-7B（Qwen2.5-Omni-7B）、SO-30B（Qwen3-Omni-30B-A3B-Instruct），均有 SO 与 MIX 权重；SO-Kimi、SO-2B、SO-3B 在仓库中仍标为待发布。
- **训练数据**：SO-Dataset 约 40 万条 FOA 音频，包含约 37 万条仿真、2.78 万条公开 SELD 数据和 0.35 万条真实录音；SO-QA 约 210 万对空间问答，覆盖 63 类声事件。

## 3. 核心机制

### 3.1. 总体数据流

```text
FOA [W,Y,Z,X]
  ├─ W 通道 → 基座原音频编码器（默认冻结）→ audio tokens
  └─ 4 路 FOA mel + 3 路 Intensity Vector
       → SO-Encoder（语义分支 + 空间分支 + 门控交叉融合）
       → 10 Hz 帧级空间表示
       → Temporal Pixel Shuffle Projector
       → 2.5 tokens/s 的 spatial tokens

audio tokens + spatial tokens + 可选 visual tokens + text tokens
  → 基座 LLM → 空间问答 / 描述 / 定向语音识别
```

### 3.2. SO-Encoder

- **语义分支**：以[[方向/AI语音/模型/BEATs|预训练 BEATs]] 的 W 通道 patch embedding 为语义底座；三层卷积从七通道输入提取残差空间增量，经可学习权重加回 BEATs 表示，再由一层 Transformer 的 ShallowTemporal 模块形成语义 token。
- **空间分支**：三层 2D CNN 加两层 Transformer 提取高分辨率方向、距离、运动和重叠声源特征。LocalSpatialCrossFuser 用语义 token 作 query、空间 token 作 key/value，通过两层门控交叉注意力融合，sigmoid 门控制融合比例。

### 3.3. SELD 预监督

事件头预测 63 类事件；SourceQueryDecoder 用多组 track query 预测活动性、类别、单位方向向量和距离。训练组合事件交叉熵、track 活动排序/BCE、方向余弦损失与距离 smooth-L1，并用 Hungarian matching 对齐预测和真实轨迹。先稳定事件分类，再引入空间学习，避免空间分支早期干扰 BEATs 语义分支。

### 3.4. 空间对齐与 MIX 回放

- **Temporal Pixel Shuffle Projector**：把相邻帧沿特征维拼接以降低时间长度，再用 LayerNorm 与两层 MLP 映射到 LLM hidden size；压缩上下文长度的同时保留局部帧信息。
- **三阶段空间对齐**：先只训练 projector/必要 adapter；再加入 LLM LoRA；最后联合训练 SO-Encoder、projector 与 LoRA。逐步解冻用于降低早期空间适配对原能力的干扰。
- **MIX 通用能力回放**：混入约 13 万条开源单声道 QA 与 20% SO-QA，空间与单声道数据按 3:1 训练；发布实现还使用学习得到的 null spatial tokens，使同一权重可处理单声道输入。

## 4. 测试基准与性能

### 4.1. SO-Bench 与指标

SO-Bench 是独立测试集，包含 16 个子任务，分为基础检测与估计、空间关系理解、复杂推理与语义三组；覆盖 DS、DT、方位/俯仰/距离估计、按方向或位置识别声源、左右/高低/远近比较、运动分类、声源计数、多跳推理、时空描述与空间语音内容识别。论文概括为约 7K QA，当前仓库发布版明确为 **7,877 条**。指标随任务变化，包括 F1、IoU、容差内准确率与 WER，部分开放答案使用 LLM judge。

### 4.2. SO-Encoder 的 SELD 结果

在 63 类 SO-Dataset 协议下，SO-Encoder 取得 F20 48.6%、DoA 误差 7.3°、相对距离误差 0.20；同为可复现基线的 PSELDNet 分别为 48.4%、12.7°、0.21。该结果支持其几何估计能力，但不直接等于下游 LLM 的空间推理能力。

### 4.3. Spatial-Omni 的下游结果

代表性 SO-Bench 结果如下（除 SC 为 WER↓ 外，其余为对应任务指标↑）：

| 模型 | EAzi | EEle | IS-Loc | RLR | MH | ST | SC↓ |
|---|---:|---:|---:|---:|---:|---:|---:|
| Qwen2.5-Omni（单声道基座） | 10.36 | 32.83 | 24.77 | 49.55 | 10.51 | 11.41 | 85.69 |
| SO-7B | 76.38 | 76.92 | 66.81 | 72.97 | 39.93 | 57.02 | 75.94 |
| SO-7B (MIX) | 79.86 | 80.74 | 68.76 | 74.47 | 37.53 | 57.94 | 78.49 |
| SO-30B (MIX) | 79.16 | 81.43 | 67.41 | 75.97 | 43.24 | 54.34 | 74.18 |

论文报告 SO 系列在 16 项中的 14 项取得前两名。消融显示：零空间 token 明显掉点；只用空间 token 仍能做角度估计，但事件识别、语义绑定与语音识别显著变差，说明准确定位与内容理解需要空间、语义两条通路协同。解冻原音频塔也没有一致增益，RLR 与 MH 反而下降。

### 4.4. 通用能力保持

通用能力保持并非自动成立：7B 版本空间适配后，MMAU 与 MMAU-Pro 平均分分别变化 −9.79 和 −18.53；MIX 相对空间适配模型恢复 +6.00 和 +9.32，但仍未完全回到基座。与此同时，MMAU-Pro Spatial 在 MIX 后仍比基座高 16.17 分，说明回放可以保留主要空间收益。

## 5. 边界

- **输入格式受限**：当前系统统一使用 FOA 与固定坐标约定，尚未系统验证 SALSA、SALSA-Lite 或任意麦克风几何；不能像 PhaseCoder 那样直接声明 geometry-agnostic。
- **时长受限**：当前仅支持最长 20 秒音频，长时场景中的持续跟踪与跨片段推理未解决。
- **复杂场景仍弱**：所有模型多跳推理得分均低于 50，声源计数整体较弱；SELD track 匹配与激活阈值可能限制多源重叠、短事件和模糊空间重叠场景。
- **通用能力有回退**：冻结原音频编码器不能阻止 LLM 空间微调造成通用音频能力下降；MIX 只是部分恢复，且依赖额外单声道回放数据。
- **评测口径需注意**：SO-Bench 由同一工作构建，训练与评测共享数据生成和 QA 模板体系；仿真约占训练音频主体，部分任务还依赖 LLM judge，跨基准与人工复评更有助于确认泛化。
- **开放不等于可随意商用**：代码为 Apache-2.0，但发布权重为 CC BY-NC-SA 4.0，基座、数据集和第三方组件另受各自许可证约束。

## 6. 发展脉络

- 技术上游：[[方向/AI语音/模型/BEATs|BEATs]] 提供 W 通道语义表征底座，SO-Encoder 增加独立空间分支；同一接口再接入 Qwen Omni、Phi-4-MM、Audio Flamingo 3、Kimi-Audio 等不同基座。
- 2026-06：论文与 SO-Dataset、SO-Bench 公开。
- 2026-07：基础 Spatial-Omni 代码、SO-Encoder 与 SO-7B 权重公开。
- 2026-09：SO-30B、SO-4B、SO-AF3 代码分支公开；论文 v2 收录多骨干、MIX 与通用能力实验。
- 2026-10：上述三个骨干的 SO/MIX 权重公开；截至 2026-10-26，SO-Kimi、SO-2B、SO-3B 仍待发布。

## 7. 相关对象

- [[方向/AI语音/模型/Qwen2.5-Omni|Qwen2.5-Omni]]：SO-7B 的基座，也是单声道输入对照。
- [[方向/AI语音/模型/BEATs|BEATs]]：SO-Encoder 语义分支的冻结底座，承接 FOA 全指向 W 通道输入的音频语义表征。
- [[方向/AI语音/模型/Qwen3-Omni|Qwen3-Omni]]：SO-30B 的基座。
- [[方向/AI语音/模型/Kimi-Audio|Kimi-Audio]]：论文验证了 SO-Kimi 变体，但官方仓库尚未发布其代码分支与权重。
- [[方向/AI语音/模型/PhaseCoder|PhaseCoder]]：任意麦克风几何的空间 token 路线；Spatial-Omni 则固定使用 FOA，并保留基座原音频通路。
- [[方向/AI语音/模型/MiDashengLM-Spatial|MiDashengLM-Spatial]]：双耳输入、语义—空间双分支路线；可作输入格式与融合方式对照。
- [[方向/AI语音/知识/基础概念/B-format（一阶 Ambisonics）|B-format]]：SO-Encoder 的四通道 FOA 输入表示。
- [[方向/AI语音/知识/基础概念/DOA（到达方向）|DOA]]：SELD 监督与空间定位评测的核心输出量。
- [[方向/AI语音/评估/MMAU-Pro（音频通用智能基准）|MMAU-Pro]]：用于检查空间适配后的通用能力回退与空间子集收益。

## 8. 关键来源

- [Spatial-Omni: Spatial Audio Understanding Integration in Multimodal LLMs via FOA Encoding（arXiv:2606.10738v2）](https://arxiv.org/html/2606.10738v2)
  - 内容定位：原始论文全文，支持背景、SO-Encoder、projector、训练策略、数据构建、SO-Bench 与实验数字。
  - 用途：对象机制与结果口径的主要权威来源。
  - 核验日期：2026-10-26
- [dieKarotte/Spatial-Omni（GitHub）](https://github.com/dieKarotte/Spatial-Omni)
  - 内容定位：官方代码、发布状态、推理接口、7,877 条评测协议、模型与数据下载入口及许可证。
  - 用途：复现入口与当前开放状态核验。
  - 核验日期：2026-10-26
- [dieKarotte/Spatial-Omni（Hugging Face）](https://huggingface.co/dieKarotte/Spatial-Omni)
  - 内容定位：官方 SO-Encoder 与各骨干 SO/MIX 适配权重；仍需配套原基座模型。
  - 用途：权重获取与许可证核对。
  - 核验日期：2026-10-26

## 9. 待验证

- SO-Encoder、projector 与 LoRA 的参数量、显存和时延开销；“lightweight”尚缺统一成本表。
- SO-Bench 的真实录音占比、按数据来源拆分的表现，以及与训练 QA 模板之间的潜在泄漏或风格重合。
- 在 STAR-Bench、真实设备 FOA 录音和人工复核上的独立复现；目前主要结果来自作者提出的 SO-Bench。
- 超过 20 秒的长音频、多说话人持续跟踪、密集多源计数与跨房间/坐标变换泛化。
- SO-Kimi、SO-2B、SO-3B 的后续发布状态，以及 MIX 在更多基座上的通用能力恢复程度。
- SO-Dataset、SO-QA、SO-Bench 若在其他对象页形成复用，再拆分为独立数据集/评估对象页；首轮不另建 SO-Encoder 组件页。

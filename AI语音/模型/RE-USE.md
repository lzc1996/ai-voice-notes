---
title: RE-USE
类型: 模型
发表时间: 2026-03-03
时间依据: arXiv:2603.02641 v1 提交日；Hugging Face 模型发布日为 2026-03-18
任务:
  - 语音增强
  - universal speech enhancement
开放状态:
  - paper
  - weights
aliases:
  - "RE-USE: Multilingual Universal Speech Enhancement"
  - Rethinking Training Targets, Architectures and Data Quality for Universal Speech Enhancement
  - Rethinking Training Targets, Architectures, and Data Quality for Universal Speech Enhancement
  - Universal Speech Enhancement with Training Target Rethinking
  - arXiv:2603.02641
tags:
  - 类型/对象
  - 方向/AI语音
  - 任务/语音增强
  - 主题/universal-speech-enhancement
  - 主题/数据质量
  - 主题/训练目标
---

# RE-USE

## 0. 背景

- **目标定义比模型更先验**：如果 clean reference 定义错了，排行榜上的 PESQ/ESTOI/SDR 可能会惩罚“更干净但不含 early reflection”的输出。
- **生成式不应从零重建**：直接生成容易幻觉；RE-USE 的设计把生成阶段限制成 residual correction，更像“修过平滑”，不是重写内容。
- **数据质量能压住 hallucination**：高质量 target 能同时提高听感和 ASR CAcc，说明清洗数据不是只为 MOS，而是为了内容保真。
- **对本方向的启发**：固定阵列增强若先用多通道模型输出单通道 enhanced stream，后接 RE-USE 类 refiner 时，target 对齐、早反射保留策略和数据清洗标准必须先定清。

## 1. 身份

`RE-USE` 是 NVIDIA 发布的 multilingual universal speech enhancement 模型；对应论文是 *Rethinking Training Targets, Architectures and Data Quality for Universal Speech Enhancement*。这篇工作的重点不是发明一个复杂新骨干，而是系统重审 USE 的三件事：**训练目标、回归-生成架构组合、训练数据质量**。

边界：它是单通道 universal SE / 音频修复模型，不是阵列增强模型；可以作为固定阵列多通道方案后端的单通道 refiner 参考，但不能替代 [[方向/AI语音/知识/基础概念/Beamforming（波束形成）]]、[[方向/AI语音/知识/基础概念/AEC（声学回声消除）]] 或多通道空间滤波。

## 2. 核心结论

- **训练目标**：传统去混响常用 early-reflected speech 作为 target，但论文认为它会保留可感知混响，拖累 DNSMOS / NISQA / UTMOS 和下游 ASR；更好的目标是按 [[方向/AI语音/知识/基础概念/Direct Path（直达声）|direct path]] 对齐后的 time-shifted anechoic clean speech，即 $s[n-n_0]$。
- **不要直接用未平移 anechoic clean**：直接用 $s[n]$ 作为 target 会有 direct-path 时间错位问题，反而最差；关键不是“early reflections 去不掉”，而是 target 与输入之间的时间对齐要正确。
- **架构**：先训练回归模型保证 fidelity，再冻结回归模型，用 residual GAN / generative stage 修正过平滑区域，试图在 perception-distortion tradeoff 中保内容、补听感。
- **数据质量**：大规模未精筛干净语音会形成性能上限；低质量 clean target 会教模型保留细小噪声、麦克风 hiss 或伪影。论文用 [[方向/AI语音/评估/VQScore（语音质量评分）|VQScore]] 做质量筛选，阈值 0.65 在质量和规模之间取得折中。
- **TTS 数据清洗用途**：USE 不只是前端增强，也能清洗低资源 TTS 训练数据；论文报告 Dutch / Italian TTS 在 CER、WER、speaker similarity、FCD 上均受益。

## 3. Time-shifted anechoic target 是什么

设原始无混响干净语音为 $s[n]$，房间里麦克风实际收到的信号不是从 $n=0$ 立刻出现，而是先经过声源到麦克风的直达传播延迟 $n_0$。这里的 [[方向/AI语音/知识/基础概念/Direct Path（直达声）|direct path / 直达声]] 指声源不经墙面、桌面、天花板等反射，沿最短路径直接到达麦克风的那一部分。因此输入里的 direct path 对应的是延迟后的干净语音：

$$
s[n-n_0]
$$

这里的 $n_0$ 是直达声飞行时间换算成采样点。例：声源离麦克风 1 m，声速约 343 m/s，延迟约 2.9 ms；16 kHz 下约 47 samples。

三种 target 的区别：

- **early-reflected speech**：目标里保留 direct path + early reflections，模型会学着保留一部分房间声。
- **未平移 anechoic clean，$s[n]$**：目标本身很干净，但和输入里的 direct path 不对齐，loss 会惩罚正确延迟位置上的输出。
- **time-shifted anechoic clean，$s[n-n_0]$**：把 dry speech 平移到和输入 direct path 对齐；模型学习“去掉噪声和混响”，而不是额外学习时间校正。

一句话：RE-USE 要的 target 是**和输入直达声同一时间位置上的无混响干净语音**。

### 3.1. 具体怎么平移

RE-USE 不是通过估计每条训练 / 测试样本的 RIR 采集距离来做校正，而是直接从用于合成混响的 RIR 中估计直达声延迟：

$$
n_0 = \arg\max_n |r[n]|
$$

也就是把 RIR 幅度最大的脉冲位置当作 direct-path peak，再把 anechoic clean speech 延迟 $n_0$ 个采样点作为训练目标：

```text
target[n] = s[n - n0]
```

工程上等价于给 dry speech 前面补 $n_0$ 个零，再裁剪到和混响输入同长。这个操作只需要合成数据里的 RIR，不需要房间几何、声源-麦克风距离或声速反推。

边界：如果是真实录音且没有对应 RIR，就不能按这个公式直接构造 shifted anechoic target；只能依赖 close-mic reference、cross-correlation / GCC-PHAT 类信号对齐、人工标定，或改用无监督 / 弱监督目标。推理时也不需要逐条估计 $n_0$：模型在训练中已经学到输出应与输入 direct path 对齐。

## 4. 关键数字

- **训练目标替换收益**：从 early-reflected target 换成 shifted anechoic target 后，URGENT 2025 non-blind 上 DNSMOS 3.06 → 3.25，NISQA 3.23 → 3.85，UTMOS 2.26 → 2.76，CAcc 87.62 → 89.41。
- **GAN refinement 收益**：shifted anechoic + GAN correction 后 DNSMOS 3.26，NISQA 4.12，UTMOS 2.80，CAcc 89.88；论文称在 non-intrusive metrics 和 ASR CAcc 上达到 URGENT 2025 non-blind SOTA。
- **数据筛选口径**：[[方向/AI语音/评估/VQScore（语音质量评分）|VQScore]] 阈值 0.50 / 0.65 / 0.72 分别对应约 2518 / 2506 / 629 小时训练语音；0.72 初期最好但规模太小后续落后，0.65 被采用为折中。
- **发布模型**：Hugging Face `nvidia/RE-USE` 是 9.6M 参数，30 层 bidirectional Mamba，支持 8–48 kHz 单通道输入；模型卡说明 released checkpoint 与论文模型不同，额外加入 microphone response / 更多 codec 等 degradation，并在更小高质量 clean subset 上微调。

## 5. 关键来源

- [Rethinking Training Targets, Architectures and Data Quality for Universal Speech Enhancement](https://arxiv.org/abs/2603.02641)
  - 内容定位：原始论文，系统分析 training target、two-stage architecture、data quality 对 USE 的影响。
  - 用途：建立 RE-USE 的方法依据和关键指标。
  - 发表日期：2026-03-03（arXiv v1；当前 v2 为 2026-04-30）
  - 核验日期：2026-08-25
- [nvidia/RE-USE - Hugging Face](https://huggingface.co/nvidia/RE-USE)
  - 内容定位：NVIDIA 发布的 multilingual universal speech enhancement 权重、模型卡、使用方式和训练数据说明。
  - 用途：确认模型开放状态、支持采样率、参数量、架构和发布口径。
  - 发表日期：2026-03-18（Hugging Face Release Date）
  - 核验日期：2026-08-25

## 6. 相关对象

- [[方向/AI语音/知识/调研与地图/SE SOTA（语音增强模型表现）]]：RE-USE 是“训练目标重审 + 数据质量优先”的代表。
- [[方向/AI语音/评估/URGENT（通用语音增强挑战）]]：论文以 URGENT 2025 non-blind 为主要评测口径。
- [[方向/AI语音/知识/基础概念/Reverberation Modeling（混响建模）]]：核心争议是 dereverberation target 是否保留 early reflections。
- [[方向/AI语音/模型/PGUSE]]、[[方向/AI语音/模型/GAP-URGENet]]：同属 prediction / generation 混合 USE 路线。
- [[方向/AI语音/模型/UniPASE]]、[[方向/AI语音/模型/SenSE]]：同属 universal SE / 低幻觉生成式增强近邻。
- [[方向/AI语音/论文/Toward Universal Speech Enhancement for Diverse Input Conditions（通用语音增强开山作）|Toward Universal SE for Diverse Input Conditions]]：ASRU 2023 首个通道数/时长/采样率无关统一 SE 尝试，universal SE 谱系的先行参照；本页的 multilingual 与数据质量重审属后续演进方向。

## 7. 待验证

- HF `nvidia/RE-USE` checkpoint 与论文实验模型的具体差异：新增 degradation、fine-tune 数据、指标是否可直接横比。
- 在中文真实会议、固定阵列 beamformed output、远场低 SNR 场景中的内容保真和 SpkSim 是否稳定。
- 作为多通道增强后端 refiner 时，是否会破坏空间线索或说话人身份。

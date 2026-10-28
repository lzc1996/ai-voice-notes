---
title: AnyEnhance
类型: 模型
发表时间: 2025-01-26
时间依据: arXiv v1 首次提交日；v3 于 2025-11-03 修订，标注 accepted by IEEE TASLP 2025
任务:
  - 语音增强
  - 歌声增强
  - 语音恢复
  - 目标说话人提取
相关主题:
  - 生成式语音增强
  - masked generative model
  - prompt guidance
  - self-critic
开放状态:
  - paper
  - demo
  - weights
  - baseline-code
代码状态: ModelScope 当前更像权重 / 配置仓库；完整 AnyEnhance recipe 在 open-mmlab/Amphion current main 的原 README 路径不可访问，AnyEnhance-v1 是轻量 baseline 代码。
aliases:
  - "AnyEnhance: A Unified Generative Model with Prompt-Guidance and Self-Critic for Voice Enhancement"
  - A Unified Generative Model with Prompt-Guidance and Self-Critic for Voice Enhancement
  - Any Enhance
  - anyenhance
tags:
  - 类型/对象
  - 方向/AI语音
  - 任务/语音增强
  - 主题/语音生成
  - 主题/语音恢复
---

# AnyEnhance

## 0. 背景

**问题现场**：语音与歌声的前端恢复任务（去噪、去混响、去削波、超分、目标说话人提取）分散在各自的专用模型里，希望一个模型在多任务间共享恢复能力，同时保住内容、说话人和音色。

**AnyEnhance 的切入点**：统一 masked generative model：44.1 kHz DAC 声学 token 上做掩码生成，配合任务条件、prompt guidance 与 self-critic remasking，覆盖 speech 与 singing voice 两域而不逐任务 fine-tune。

## 1. 身份

`AnyEnhance` 是一个统一式生成语音增强模型，论文题目为 *AnyEnhance: A Unified Generative Model with Prompt-Guidance and Self-Critic for Voice Enhancement*。它面向 speech 和 singing voice，把 denoising、dereverberation、declipping、super-resolution、target speaker extraction 放进同一个 masked generative model 中处理，目标是不为每个任务单独 fine-tune。

边界：AnyEnhance 不是传统频谱掩码 / 判别式增强模型，也不是 [[方向/AI语音/知识/基础概念/Flow Matching（流匹配）]] / DiT ODE 采样路线。它更接近 [[方向/AI语音/模型/MaskSR]] / codec-token restoration 谱系：在离散声学 token 或量化表示上做 masked generation，再解码回 waveform。

论文版主模型使用 44.1 kHz [[方向/AI语音/模型/DAC（Descript Audio Codec）]] 作为声学 tokenizer；“统一”主要来自同一套语义增强、任务条件和 masked acoustic generation 机制，而不是把所有任务改写成同一种连续噪声采样过程。

## 2. 核心链路

```text
distorted voice / singing voice y = D(x)
  -> power-law magnitude STFT + task embedding
  -> Transformer encoder + noisy SSL feature
  -> semantic condition h_semantic
  -> 44.1 kHz DAC / 9-layer RVQ acoustic tokens
  -> masked acoustic Transformer decoding
  -> optional clean speaker prompt + self-critic remasking
  -> DAC decoder
  -> enhanced waveform
```

核心问题不是只把噪声去掉，而是让一个模型在多个语音 / 歌声前端任务之间共享恢复能力，同时尽量保住内容、说话人和音色。

## 3. 关键设计

- **Masked generative model**：把声学恢复改写成 masked token prediction / iterative refinement，而不是直接做频谱回归。
- **Semantic enhancement stage**：输入受损音频的 power-law magnitude STFT 和 task embedding；encoder 输出通过 REPA 对齐干净音频的 w2v-BERT 语义特征，并把 noisy SSL feature 加回 encoder 输出，形成 $h_{semantic}=h_{enc}+f(y)$。
- **DAC acoustic tokens**：干净音频经 DAC 的 9 层 residual vector quantizer 得到约 $9\times T$ 的 token 序列；不同 residual layer 分别 embedding 后求和，再由 decoder 预测被 Mask 的 token。
- **离散 diffusion / mask 时间**：论文中的 $t$ 表示 Mask 程度，不是 DiT 的连续高斯噪声时间；mask schedule 为 $\gamma(t)=\sin(\pi t/2T)$。推理从全 Mask token 开始，逐步预测并重新 Mask 低置信度 token，不使用 DDIM / Euler 一类连续噪声 scheduler。
- **Prompt guidance**：训练时以一定概率保留干净音频开头 3 秒作为 prompt，对应受损片段置静音且不计入 loss；推理时把参考说话人的 prompt token 放在序列开头，其余部分保持 Mask。它既支持 TSE，也能改善普通增强的音色保持。
- **Self-critic**：模型先预测 token，再把预测结果回灌给同一 Transformer 的 critic head，估计哪些位置更像不真实或错误生成的 token，用于指导下一轮重新 Mask；总损失为 $L=L_{mask}+L_{REPA}+L_{critic}$。
- **多任务合训**：训练失真覆盖 noise、reverb、clipping、bandwidth limitation、other voice、vocal effect 等，使模型同时学习多类恢复。
- **speech + singing voice**：相比只做 general speech restoration，AnyEnhance 明确把歌声作为目标域之一。

## 4. 测试基准与性能

本节表格数值均整理自 [AnyEnhance arXiv 论文](https://arxiv.org/abs/2501.15417) 的实验表。不同任务使用不同数据集与指标，表内结果用于记录论文口径，不构成跨任务总排名。

### 4.1. 代表性基准结果

| 评测集 | 任务 / 域 | AnyEnhance 代表性结果 | 对比结果 / 解释 |
|---|---|---|---|
| DNS No Reverb | 语音降噪 | OVRL 3.418；NISQA 4.821；Similarity 0.988 | 主指标表现强，论文称 OVRL、NISQA 和 Similarity 均具竞争力 |
| DNS With Reverb | 语音降噪 + 去混响 | SIG 3.500；OVRL 3.204；NISQA 3.722 | SIG、OVRL 较强；混响场景整体难度明显更高 |
| DNS Real Recordings | 真实录音增强 | SIG 3.488；BAK 3.977；OVRL 3.161 | 论文称 SIG、OVRL 为对比模型中最高，BAK 保持竞争力 |
| Librivox GSR | 语音多失真恢复 | MOS 4.183；OVRL 3.308；NISQA 4.346；Similarity 0.955 | MOS 为该表最高；适合观察听感、内容和说话人保持的综合结果 |
| CCMusic GSR | 歌声多失真恢复 | MOS 3.917；OVRL 2.797；NISQA 3.345；Similarity 0.915 | MOS 为该表最高；歌声场景的绝对分数低于语音场景 |
| VCTK TSE | 目标说话人提取 + 多失真 | OVRL 3.275；NISQA 4.570；Similarity 0.925 | 在复杂噪声、混响、削波、带宽限制同时存在时仍保持较强结果 |
| VoiceBank-Demand | 语音增强 | WV-MOS 4.44；PESQ 2.78；ESTOI 0.84 | WV-MOS 高于 Nemo 的 4.41，但 PESQ / ESTOI 低于 Nemo 的 3.27 / 0.88 |

### 4.2. Prompt guidance 消融

| 评测集 | 指标 | 无 prompt | 有 prompt | 变化 |
|---|---|---:|---:|---:|
| Librivox GSR | OVRL | 3.308 | 3.401 | +0.093 |
| Librivox GSR | NISQA | 4.346 | 4.472 | +0.126 |
| Librivox GSR | Similarity | 0.955 | 0.963 | +0.008 |
| CCMusic GSR | OVRL | 2.797 | 2.944 | +0.147 |
| CCMusic GSR | NISQA | 3.345 | 3.571 | +0.226 |
| CCMusic GSR | Similarity | 0.915 | 0.921 | +0.006 |
| Voicefixer SR | OVRL | 3.156 | 3.177 | +0.021 |
| Voicefixer SR | NISQA | 4.201 | 4.339 | +0.138 |
| Voicefixer SR | Similarity | 0.943 | 0.956 | +0.013 |

Self-critic 消融中，论文在 Librivox GSR、CCMusic SR 和 VCTK TSE 上比较了 2–40 个 inference steps；加入 critic head 后，OVRL、SpeechBERTScore 和 Speaker Similarity 随采样步数整体高于不使用 self-critic 的版本。

### 4.3. 训练配置与评估口径

| 项目 | 论文配置 |
|---|---|
| 主模型规模 | 约 363.6M 参数 |
| Transformer 结构 | 24 层 semantic encoder + 24 层 acoustic decoder |
| Audio codec | 44.1 kHz DAC，9 层 RVQ |
| 训练片段 | 8 秒；50% 概率保留前 3 秒作为 prompt |
| 优化步数 | 300k steps；4 GPU；每 GPU batch size 8 |
| 训练时间 | 约 125.8 小时 |
| 推理效率 | DNS No Reverb 单 GPU 平均 RTF 约 0.254 |
| 主评估指标 | DNSMOS、NISQA、SpeechBERTScore、Similarity、MOS |
| 补充指标 | WER、PESQ、ESTOI；CCMusic GSR 未报告 WER，因为 ASR 转写不稳定 |

生成式模型的听感指标和波形对齐指标可能分离：VoiceBank-Demand 上 AnyEnhance 的 WV-MOS 高于 Nemo，但 PESQ / ESTOI 更低。因此不能只用 PESQ / ESTOI 判断 AnyEnhance 是否有效。

## 5. 使用判断

- **适合看统一前端增强**：同一模型覆盖降噪、去混响、去削波、超分、TSE，以及 speech / singing voice 两域。
- **适合做生成式基线**：可和 [[方向/AI语音/模型/GenSE]]、[[方向/AI语音/模型/SELM]]、[[方向/AI语音/模型/SenSE]]、[[方向/AI语音/模型/FlowSE]]、[[方向/AI语音/模型/DiT-Flow]] 对比“codec / masked / flow”路线差异。
- **不适合只看 PESQ / ESTOI**：生成式输出可能听感更好但与参考波形不严格对齐，应配合 MOS / DNSMOS / NISQA、[[方向/AI语音/评估/SpeechBERTScore（语音语义相似度）]]、WER / CER、[[方向/AI语音/评估/SpkSim]] 和人工听感。
- **论文版的 $t$ 不是连续采样 scheduler**：测试时应理解为 masked token refinement 的步数 / mask 状态；不能套用 DiT 的“输入随机噪声并设置 $t=0$”逻辑。
- **prompt 不是必需输入**：没有干净参考说话人音频时走 no-prompt 路径；有参考音频时再单独比较 prompt / no-prompt，不能把 prompt 版本的收益归因于模型本身的无条件增强能力。
- **工程复现要分清版本**：ModelScope `amphion/anyenhance` 当前更像权重 / 配置仓库，而不是完整代码仓库；它的 README 指向 `open-mmlab/Amphion/models/se/anyenhance/readme.md`，但 current main 该路径不可访问。GitHub `AnyEnhance-v1` 是 CCF-AATC 2025 challenge 的 lightweight / task-specific baseline，README 明确说它不同于原论文大模型，且未显式启用 prompt guidance 和 self-critic。

## 6. 相关对象

- [[方向/AI语音增强/README|AI 语音增强]]：AnyEnhance 属于 unified generative voice enhancement 路线。
- [[方向/AI语音/模型/MaskSR]]：masked acoustic token 语音恢复路线前作；AnyEnhance 可看作向 prompt guidance、self-critic 和 singing voice 继续扩展。
- [[方向/AI语音/模型/DAC（Descript Audio Codec）]]：论文版使用 44.1 kHz DAC 的 9 层 RVQ 生成 acoustic tokens，是最终 waveform 重建的关键上限。
- [[方向/AI语音/模型/GenSE]]：相邻 LM / token-based 生成式增强路线。
- [[方向/AI语音/模型/SenSE]]：semantic-guided flow matching 路线，常把 AnyEnhance 作为基线对照。
- [[方向/AI语音/模型/L3-SE]]：低幻觉 LM-based SE 路线，可对比内容保真风险。
- [[方向/AI语音/知识/基础概念/NAC（神经音频 Codec）]]：AnyEnhance 的 masked acoustic modeling 与 codec / token 表示相关。
- [[方向/AI语音/评估/语音增强评估指标体系]]：生成式增强需要多指标评估，不能只看听感分。
- [[方向/AI语音/知识/基础概念/TSE（目标说话人提取）]]：prompt guidance 让 AnyEnhance 覆盖 TSE。
- [[方向/AI语音/知识/基础概念/SR（语音恢复）]]：AnyEnhance 可视作统一语音 / 歌声恢复模型。
- [[方向/AI语音/知识/基础概念/Masked Generative Modeling（掩码生成建模）]]：AnyEnhance 的 masked acoustic generation 方法入口。

## 7. 来源

- [AnyEnhance arXiv](https://arxiv.org/abs/2501.15417)
  - 内容定位：原始论文页面和 v3 正文，记录标题、作者、v1/v3 时间、TASLP 接收状态、模型结构、离散 mask 过程、prompt-guidance、self-critic、训练数据和实验结果。
  - 用途：确认论文版机制、训练配置、指标口径和性能边界；论文中所称 open-source implementation 当前对应的是轻量 baseline 入口。
  - 核验日期：2026-09-18
- [AnyEnhance demo page](https://amphionspace.github.io/anyenhance/)
  - 内容定位：论文公开音频 demo 页面。
  - 用途：主观听样例和 speech / singing voice 恢复对比。
  - 核验日期：2026-09-18
- [AnyEnhance-v1 GitHub](https://github.com/viewfinder-annn/AnyEnhance-v1)
  - 内容定位：当前可访问的代码入口；README 说明它是 CCF-AATC 2025 的 lightweight task-specific baseline，与原论文大模型不同，且未显式启用 prompt guidance / self-critic。
  - 用途：工程复现、baseline 权重和版本边界；不能等同于完整 AnyEnhance 论文实现。
  - 核验日期：2026-09-18
- [amphion/anyenhance ModelScope](https://modelscope.cn/models/amphion/anyenhance)
  - 内容定位：AnyEnhance 模型权重 / 配置 / 模型卡入口；文件列表仅见 `model.pt`、DAC `weights.pth`、配置 JSON 和 README，未见 Python 代码。
  - 用途：确认预训练权重发布位置，而非完整复现代码入口。
  - 核验日期：2026-09-18
- [Amphion AnyEnhance recipe path](https://github.com/open-mmlab/Amphion/blob/main/models/se/anyenhance/readme.md)
  - 内容定位：ModelScope README 指向的 GitHub recipe 路径。
  - 用途：核验 current main 上该路径是否仍可访问；2026-09-18 核验为不可访问 / 路径缺失。
  - 核验日期：2026-09-18
- [open-mmlab/Amphion PR #386](https://github.com/open-mmlab/Amphion/pull/386)
  - 内容定位：AnyEnhance 曾从 `viewfinder-annn:anyenhance` 分支合入 Amphion 的历史线索。
  - 用途：后续追溯完整 recipe 是否仍存在于历史提交、fork、branch 或 tag。
  - 核验日期：2026-09-18

## 8. 待深挖与待实验

- **已收尾**：原论文版与 `AnyEnhance-v1` 的版本边界已在正文和来源中记录：前者是论文大模型，后者是 CCF-AATC 2025 的 lightweight task-specific baseline，不能把两者的参数、训练数据和功能混为一谈。
- **已收尾**：`Amphion` current main 的 `models/se/anyenhance` 路径已核验为不可访问；PR #386 只保留历史合入线索，暂不把它当作可恢复的完整 recipe。
- 论文版 masked-token 推理步数、critic 分数和公开 baseline 配置之间的对应关系。
- 你们数据中的失真链是否落在论文覆盖的 noise、reverb、clipping、bandwidth、other voice、vocal effect 分布内。
- prompt guidance 在中文、方言、多人会议和歌声场景下对 SpkSim / 内容保真的影响。
- self-critic 是否真的能降低内容幻觉，还是主要提升听感分和 token 可信度。
- 与 [[方向/AI语音/模型/SenSE]]、[[方向/AI语音/模型/L3-SE]]、[[方向/AI语音/模型/GenSE]]、[[方向/AI语音/模型/FlowSE]]、[[方向/AI语音/模型/DiT-Flow]] 在同一中文小样本集上的 WER / CER、[[方向/AI语音/评估/SpeechBERTScore（语音语义相似度）]]、[[方向/AI语音/评估/SpkSim]]、NISQA 子维度和 RTF。

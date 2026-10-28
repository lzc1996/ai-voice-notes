---
title: UniAudio
类型: 模型
参数量: 1B（论文口径）
发表时间: 2023-10-01
时间依据: arXiv v1 首次提交日；ICML 2024 / PMLR 于 2024-07-21 发布论文集版本
会议: ICML 2024
任务:
  - 音频生成
  - TTS
  - 声音转换
  - 歌声合成
  - 语音增强
  - 目标说话人提取
  - 文本到音效
  - 文本到音乐
  - 音频编辑
开放状态:
  - paper
  - code
  - weights
  - demo
aliases:
  - UniAudio 1.0
  - UniAudio 1.x
  - UniAudio (ICML 2024)
  - Open-UniAudio
  - "UniAudio: Towards Universal Audio Generation with Large Language Models"
  - "UniAudio: An Audio Foundation Model Toward Universal Audio Generation"
tags:
  - 类型/对象
  - 方向/AI语音
  - 任务/音频生成
  - 任务/TTS
  - 主题/音频tokenizer
---

# UniAudio

## 0. 背景

**问题现场**：TTS、voice conversion、语音增强、目标说话人提取、text-to-sound、text-to-music 等音频生成任务各由专门模型承担，希望用一个模型统一。

**UniAudio 的切入点**：把所有任务统一写成「source token + target audio token」的 next-token prediction 序列格式，目标音频统一表示为 RVQ neural codec tokens，用 global/local multi-scale Transformer 缓解长音频 token 序列。

## 1. 内容定位

`UniAudio` 是 Dongchao Yang 等在 ICML 2024 发表的统一音频生成模型。它把 speech、sound、music、singing voice 等任务统一成「source modality -> target audio」的 next-token prediction，用同一个 1B 参数 Transformer 生成神经音频 codec token。

边界：UniAudio 重点是**统一音频生成**，不是后续 [[方向/AI语音/模型/UniAudio 2.0|UniAudio 2.0]] 那种理解 + 生成一体的 audio LLM；也不是 [[方向/AI语音/模型/UniAudio-Token|UniAudio-Token]] 这种单码本 semantic audio tokenizer。

## 2. 核心信息

- **任务面**：论文口径统一 11 个音频生成任务，训练阶段覆盖 7 个 seen tasks，微调阶段展示 4 个 unseen tasks。
- **输入统一**：文本、音频、语音、音乐等条件都先被 tokenized，拼成 source-target 序列。
- **输出统一**：目标音频统一表示为 [[方向/AI语音/知识/基础概念/RVQ（残差向量量化）|RVQ]] neural codec tokens，最后由 codec decoder 还原 waveform。
- **主干结构**：global Transformer 负责长程语义/结构，local Transformer 负责一帧内多 codebook token 生成，用 multi-scale Transformer 缓解长音频 token 序列。
- **开放状态**：官方 GitHub、demo 和 checkpoint 已公开；更适合作为统一音频生成路线前身，而不是当前最佳生产模型。

## 3. 核心机制

### 3.1. 输入到输出链路

```text
task prompt / source text / source audio -> modality-specific tokenizer -> source token sequence
target audio -> neural codec encoder -> RVQ acoustic token sequence
source tokens + separator + target audio tokens -> global Transformer -> local Transformer -> next codec tokens
generated codec tokens -> neural codec decoder -> waveform
```mermaid

UniAudio 的核心设计是把不同任务都写成同一种序列格式：source token 放前面，target audio token 放后面；训练时只对 target audio token 做 next-token prediction。这样 TTS、voice conversion、text-to-sound、text-to-music、speech enhancement、target speech extraction 等任务可以共用一个建模接口。

### 3.2. 关键公式

统一任务序列：

$$
X=[\mathrm{BOS}, S_1,\ldots,S_N,\mathrm{SEP}, A_1,\ldots,A_M,\mathrm{EOS}]
$$

目标音频的自回归训练目标：

$$
\mathcal{L}_{\mathrm{audio}}=-\sum_{m=1}^{M}\log p_{\theta}(A_m\mid S_{1:N},A_{<m})
$$

RVQ codec tokenization：

$$
r_0=e_t,\quad c_{t,l}=\mathrm{VQ}_l(r_{l-1}),\quad r_l=r_{l-1}-c_{t,l},\quad \hat e_t=\sum_{l=1}^{L}c_{t,l}
$$

multi-scale factorization：

$$
p(A_t\mid A_{<t},S)=\prod_{l=1}^{L}p(c_{t,l}\mid c_{t,<l},A_{<t},S)
$$

波形重建：

$$
\hat x=\mathcal{D}_{\mathrm{codec}}(\hat e_{1:T})
$$

### 3.3. 机制要点

- **任务统一靠序列格式**：不是给每个任务做专门模型，而是把 source / target 显式拼接。
- **生成统一靠 codec token**：所有目标音频都变成同一套 discrete acoustic tokens。
- **multi-scale Transformer 是效率补丁**：长音频的 token 序列太长，因此用 global/local 两层拆分长程依赖和帧内 codebook 依赖。
- **泛化来自任务条件化**：unseen task 不是零成本魔法，依赖 source-target 格式和少量微调样例能否表达新任务。

### 3.4. 架构示意（概念级）

> [!note] 架构示意（概念级）
> 按本页已有输入—中间表示—输出链路整理，不替代论文结构图。

```
flowchart LR
  A["Text or audio prompt"] --> B["Unified audio codec-token LM"]
  B --> C["Task-specific token generation"]
  C --> D["Audio decoder"]
  D --> E["TTS / VC / SE / TSE / audio output"]
```

## 4. 使用判断

- 看**统一音频生成起点**：UniAudio 是从 AudioLM/codec LM 到统一 speech/sound/music generation 的关键早期节点。
- 看**和 UniAudio 2.0 的差异**：UniAudio 1.x 统一生成任务；[[方向/AI语音/模型/UniAudio 2.0|UniAudio 2.0]] 增加 ReasoningCodec，把理解 token 和重建 token 因子化。
- 看**工程复现**：适合复现多任务生成框架和 codec-token 训练流程；不适合直接作为实时语音助手底座。

## 5. 相关对象

- [[方向/AI语音/MOC - 音频大模型|MOC - 音频大模型]]：方向地图。
- [[方向/AI语音/模型/UniAudio 2.0|UniAudio 2.0]]：后续统一 audio LLM，扩展到理解 + 生成，并引入 ReasoningCodec。
- [[方向/AI语音/模型/UniAudio-Token|UniAudio-Token]]：同名但不同层级；UniAudio-Token 是 semantic audio tokenizer。
- [[方向/AI语音/模型/AudioLM|AudioLM]]：codec token language modeling 的早期代表。
- [[方向/AI语音/知识/基础概念/RVQ（残差向量量化）|RVQ（残差向量量化）]]：目标音频 codec token 的基础量化方式。
- [[方向/AI语音/知识/基础概念/NAC（神经音频 Codec）|NAC（神经音频 Codec）]]：神经音频 codec/tokenizer 概念入口。
- [[方向/AI语音/知识/技术路线/语音生成 tokenizer codec 技术路线|语音生成 tokenizer codec 技术路线]]：统一音频生成与 codec/token 路线对照。

## 6. 来源

- [UniAudio: Towards Universal Audio Generation with Large Language Models（ICML 2024 / PMLR）](https://proceedings.mlr.press/v235/yang24x.html)
  - 内容定位：ICML 2024 论文集版本，记录 1B 参数统一音频生成模型、11 个任务、7 seen + 4 unseen 任务设置和 PMLR 元信息。
  - 用途：确认会议、模型身份、任务范围和发表口径。
  - 发表日期：2024-07-21（PMLR proceedings）
  - 核验日期：2026-09-02
- [UniAudio arXiv](https://arxiv.org/abs/2310.00704)
  - 内容定位：arXiv 技术论文，记录 unified task formulation、sequence modeling、multi-scale Transformer 和任务实验。
  - 用途：确认核心机制和公式化建模方式。
  - 发表日期：2023-10-01（arXiv v1）
  - 核验日期：2026-09-02
- [yangdongchao/UniAudio（GitHub）](https://github.com/yangdongchao/UniAudio)
  - 内容定位：官方代码仓库，记录 demo、model zoo/checkpoints、环境、数据准备、训练与推理入口。
  - 用途：确认代码、checkpoint 和复现入口。
  - 核验日期：2026-09-02
- [UniAudio Demo](https://dongchaoyang.top/UniAudio_demo/)
  - 内容定位：官方 demo 页，展示 speech、sound、music、singing voice 等生成样例。
  - 用途：确认任务样例和项目归属。
  - 核验日期：2026-09-02

## 7. 基准性能与待深挖

以下结果整理自 [UniAudio arXiv 论文](https://arxiv.org/abs/2310.00704) Table 10、11、13、16、17。不同任务来自不同数据集，不能合并为单一总分。

#### 7.1.1. TTS / VC / SE / TSE

| 任务 | SIM↑ | WER↓ | PESQ↑ | VISQOL↑ | DNSMOS↑ | MOS↑ | SMOS↑ |
|---|---:|---:|---:|---:|---:|---:|---:|
| TTS | 0.708 | 2.0 | — | — | — | 3.81±0.07 | 3.56±0.10 |
| VC | 0.868 | 4.8 | — | — | — | 3.54±0.07 | 3.56±0.07 |
| Speech enhancement | — | — | 2.63 | 2.44 | 3.66 | 3.68±0.07 | — |
| Target speech extraction | — | — | 1.88 | 1.68 | 3.96 | 3.72±0.06 | — |
| SVS | — | — | — | — | — | 4.08±0.04 | 4.04±0.05 |

#### 7.1.2. Text-to-sound / Text-to-music

| 任务 | 训练时长 | FAD↓ | KL↓ | OVL↑ | REL↑ |
|---|---:|---:|---:|---:|---:|
| Text-to-sound | 7k h | 3.12 | 2.57 | 61.9±1.9 | 66.1±1.5 |
| Text-to-music | 8k h | 3.65 | 1.87 | 67.85±1.70 | 70.0±1.5 |

#### 7.1.3. 去混响与语音编辑

| 任务 / 设置 | PESQ↑ | DNSMOS↑ | MCD↓ | MOS↑ |
|---|---:|---:|---:|---:|
| Speech dereverberation：scratch | 1.23 | 3.18 | — | — |
| Speech dereverberation：tuning | 2.13 | 3.51 | — | — |
| Speech edit | — | — | 5.12 | 3.82±0.06 |

- checkpoint 与论文任务覆盖是否完全一致；不同任务是否需要额外微调权重。
- neural codec 的具体实现、codebook 数、帧率和与 EnCodec/SoundStream/MusicGen codec 的差异。
- 中文 TTS、低资源声学事件、长音乐生成上的第三方复测表现。
- **结构决策**：暂不把 multi-scale Transformer 拆成独立技术路线页；当前作为 UniAudio 的效率机制记录，等在其他 codec-LM 模型中出现可复用比较维度时再抽象。

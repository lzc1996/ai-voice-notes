---
title: SenSE
类型: 框架
发表时间: 2025-09-29
时间依据: arXiv 首次提交日
任务:
  - 语音增强
开放状态:
  - paper
  - code
  - weights
  - demo
aliases:
  - Semantic-Aware High-Fidelity Universal Speech Enhancement
  - SenSE speech enhancement
tags:
  - 类型/对象
  - 方向/AI语音
  - 任务/语音增强
---

# SenSE

## 0. 背景

**问题现场**：通用语音增强要面对噪声、混响、削波、带宽受限等多种严重退化，严重退化场景里容易出现语义歧义和声学不连续。

**SenSE 的切入点**：两阶段框架——SASLM 先从退化语音生成语义 token，再用语义条件指导 flow matching 生成增强语音。

## 1. 身份

SenSE 是一个 semantic-aware universal speech enhancement **框架**，全名是 *SenSE: Semantic-Aware High-Fidelity Universal Speech Enhancement*。它面向噪声、混响、削波、带宽受限等多种退化，把语言模型提取的语义 token 注入 flow-matching 语音增强过程，以减少严重退化场景里的语义歧义和声学不连续。

层级定位（按 vault 的模型/框架/系统约定）：框架层是"语义 token 指导 flow matching"的思想——SASLM 语义 token 和 flow-matching 后端都可替换；其官方实现（基于 [[方向/AI语音/模型/F5-TTS|F5-TTS]]、Hugging Face `ASLP-lab/SenSE` 权重）是该框架的**参考模型**，复现实验时用后者。

## 2. 用途

- 作为生成式/flow matching 语音增强路线的前沿样例。
- 在强噪声、混响、削波、带宽受限等严重退化场景下评估语义保持和听感质量。
- 对比 [[方向/AI语音/模型/UniSE（Unified Speech Enhancement）|UniSE]]：SenSE 用语义 token 指导 flow matching，UniSE 更偏 decoder-only LM 统一语音恢复。
- 研究参考音频 prompt guidance 对严重退化条件下 speaker similarity 的帮助。

## 3. 核心信息

- 两阶段结构：Semantic-Aware Speech Language Model（SASLM）先从 degraded speech 生成 semantic tokens，再用 semantic-guided flow matching 生成增强语音。
- 语音 tokenizer：论文使用 CosyVoice / SenseVoice 相关的 [[方向/AI语音/模型/S3 Tokenizer|supervised semantic token]] 路线。
- 生成后端：flow matching + DiT 风格模块，官方实现说明基于 [[方向/AI语音/模型/F5-TTS|F5-TTS]]。
- 模型变体：论文描述 `SenSE_base`、`SenSE_small`、`SenSE_tiny`；tiny 版本强调低计算预算。
- 评估关注：DNSMOS、[[方向/AI语音/评估/SpeechBERTScore（语音语义相似度）|SpeechBERTScore]]、speaker similarity、dWER 等，不能只看听感 MOS。
- 权重：Hugging Face 上提供 `ASLP-lab/SenSE`，仓库提示下载后放到 `ckpts/SenSE_Base/`。

## 4. 核心公式

**1. 语义引导的条件流匹配损失（FM 阶段）：**

$$\mathcal{L}_{\text{FM}} = \mathbb{E}_{t\sim\mathcal U(0,1),\,x_0\sim\mathcal N(0,I),\,x_1}\Big[\big\|v_\theta(x_t, c_{\text{sem}}, t) - (x_1 - x_0)\big\|_2^2\Big]$$

$x_t=(1-t)x_0+tx_1$ 为干净 mel $x_1$ 与高斯噪声 $x_0$ 的线性插值，$c_{\text{sem}}$ 为语义条件（与 mel 逐帧等长后沿特征维 concat），$v_\theta$ 为 DiT 风格的 flow matching 网络；与 F5-TTS 同款流匹配 MSE 目标（24 kHz、100 维 mel、hop 256）。

**2. 语义条件构建：filler token + ConvNeXt V2 隐式对齐：**

$$c_{\text{sem}} = \Phi_{\text{ConvNeXtV2}}\big(\text{Filler}([s_1,\dots,s_K])\big)\in\mathbb{R}^{T_{\text{mel}}\times d}$$

S³ 语义 token $s_k$ 为 50 Hz（共 $K$ 个），mel 帧率约 93.75 Hz（$T_{\text{mel}}$ 帧）；filler token 把序列补到 $T_{\text{mel}}$ 长，再由从零训练的可学习 ConvNeXt V2 模块 $\Phi$ 编码，靠卷积局部性把每个 token 的语义"摊"到正确时间跨度——隐式对齐，无 forced alignment。

**3. SASLM 自回归语义 token 生成（第一阶段）：**

$$\mathcal{L}_{\text{CE}} = -\mathbb{E}\Big[\sum_{t=1}^{K}\log p_\theta\big(s_t \mid s_{<t},\, h_{\text{degraded}}\big)\Big]$$

$h_{\text{degraded}}$ 为退化语音经冻结 Whisper 编码器提取的表示，$s_t$ 为 S³ 语义 token；训练先冻结编码器训 LM（前 550K 步），再冻结 LM 微调编码器。

**4. 推理级联（含训练/推理条件落差）：**

$$\hat x = \text{Vocoder}\Big(\text{FM-sample}\big(v_\theta,\, \Phi_{\text{ConvNeXtV2}}(\text{Filler}(\text{SASLM}(y)))\big)\Big)$$

推理时语义 token 由 SASLM 从受损语音 $y$ 净化得到；训练时 FM 的条件 token 来自干净语音直接提取，推理时换为 SASLM 输出，落差由 SASLM 净化质量与隐式对齐的鲁棒性吸收；最后 BigVGAN 合成 24 kHz 波形。

## 5. 测试基准与性能

**测试基准：** 4 个评测集（均 DNS/VCTK 系）：DNS Challenge no-reverb（官方测试集）、DNS Challenge HardSet（SNR 随机采自 [-5, 0] dB 重混）、DNS Challenge GSR（噪声+混响+削波+带宽限制模拟管线）、VCTK GSR（未见过噪声/RIR，共 167 样本）。训练模拟管线：噪声 p=0.9（SNR ∈ [-10, 10]）、混响 p=0.5、削波 p=0.25（阈值 ∈ [0.05, 0.90]）、带宽限制 p=0.5（{2, 4, 8, 16, 22.05} kHz）。采样率：SASLM 16 kHz、FM 24 kHz；所有模型输出统一重采样 16 kHz 评测。指标：DNSMOS OVRL（唯一感知主指标）、NISQA、SpeechBERTScore（HuBERT-base）、dWER（Whisper-large-v3）、SIM-o（WavLM-large）、PESQ（wideband）、ESTOI。基线：Voicefixer、TF-GridNet、MP-SENet、[[方向/AI语音/模型/CleanMel|CleanMel]]、PGUSE、SELM、[[方向/AI语音/模型/GenSE|GenSE]]、FlowSE、LLaSE-G1、[[方向/AI语音/模型/AnyEnhance]]。

**性能指标：**（arXiv 2509.24708 HTML 全文）

| 评测集 | DNSMOS | NISQA | S-BERT | dWER(%) | SIM-o | PESQ | ESTOI |
|---|---|---|---|---|---|---|---|
| DNS no-reverb | 3.374 | 4.788 | 0.942 | 3.82 | 0.920 | 2.799 | 0.924 |
| DNS HardSet | 3.408 | 4.874 | 0.916 | 8.91 | 0.837 | 2.070 | 0.854 |
| DNS GSR | 3.389 | 4.804 | 0.922 | 6.73 | 0.799 | 2.219 | 0.865 |
| VCTK GSR | 3.109 | 4.725 | 0.943 | 1.77 | 0.824 | — | — |

PESQ/ESTOI 为生成式模型对比表（VCTK GSR 未列入该表）。推理 NFE=8、CFG 强度 0.5、[[方向/AI语音/知识/基础概念/Sway Sampling（摇摆采样）|Sway Sampling]] 系数 −1；论文未报告 RTF / 参数量 / FLOPs（待核）。prompt guidance 消融（HardSet）：PESQ 2.071→2.218、ESTOI 0.854→0.859、SIM-o 0.837→0.883，dWER 8.91→9.30 略升。

（来源：arXiv 2509.24708 HTML，核验日期 2026-08-07）

## 6. 关键资源

- [SenSE paper](https://arxiv.org/abs/2509.24708)
  - 内容定位：论文提出用语言模型语义 token 指导 flow-matching 语音增强，覆盖方法、实验和消融。
  - 用途：理解架构、指标和与其他 generative USE 方法的区别。
  - 核验日期：2026-07-28
- [ASLP-lab/SenSE](https://github.com/ASLP-lab/SenSE)
  - 内容定位：官方代码仓库，包含安装、推理、训练命令和 MIT license。
  - 用途：本地复现实验和工程入口。
  - 核验日期：2026-07-28
- [ASLP-lab/SenSE - Hugging Face](https://huggingface.co/ASLP-lab/SenSE)
  - 内容定位：官方模型权重页，关联 arXiv 2509.24708，并给出 Transformers 下载入口和 checkpoint 放置说明。
  - 用途：权重下载和本地推理准备。
  - 核验日期：2026-07-28

## 7. 相关对象

- [[方向/AI语音增强/README|AI 语音增强]]：SenSE 属于 universal speech enhancement 前沿方法。
- [[方向/AI语音/知识/基础概念/Flow Matching（流匹配）|Flow Matching]]：SenSE 的生成后端属于 semantic-guided flow matching。
- [[方向/AI语音/知识/生成式语音增强/SE Generative Prior（语音增强生成先验）|SE Generative Prior]]：SenSE 属于高斯先验 + 强语义条件路线（A 类），先验选择动机见该笔记。
- [[方向/AI语音/模型/UniSE（Unified Speech Enhancement）|UniSE]]：同属生成式语音增强/恢复路线，适合比较“LM 直接生成”与“semantic-guided flow matching”。
- [[方向/AI语音/评估/OVRL_MOS|OVRL_MOS]]：听感质量评估入口，但 SenSE 还需要语义和说话人保持指标。
- [[方向/AI语音/评估/SpeechBERTScore（语音语义相似度）|SpeechBERTScore]]：参考依赖的语音语义/表示相似度指标。
- [[方向/AI语音/评估/CER（Character Error Rate）|CER]]：如果目标是 ASR 前端增强，还要看增强后 ASR 错误率变化。
- [[方向/AI语音/模型/S3 Tokenizer|S3 Tokenizer]]：CosyVoice / SenseVoice 相关 supervised semantic token 路线入口。
- [[方向/AI语音/知识/技术路线/语音生成 tokenizer codec 技术路线|语音生成 tokenizer codec 技术路线]]：SenSE 依赖 supervised semantic token 作为语义中间表示。

## 8. 架构与训练细节（论文精读）

### 8.1. 语义条件的注入：filler token + ConvNeXt V2

- 问题：S³ 语义 token 为 50Hz，mel（24kHz、hop 256）约 93.75Hz，帧率失配且无显式帧级对应；条件注入方式是沿特征维 concat，要求语义条件与 mel 逐帧等长。
- 方案（继承 F5-TTS）：filler token 把 token 序列补到 mel 长度（只负责"占位"），再经 ConvNeXt V2 模块编码，靠卷积的局部性/时间平移不变性把每个 token 的语义"摊"到正确的时间跨度——**隐式对齐**，无 forced alignment、无 duration predictor。
- ConvNeXt V2 模块**可学习、从零训练**，与 DiT 主干吃同一个流匹配 MSE 损失端到端联合优化；对齐行为没有显式监督，是"对齐得好则重建损失低"的间接压力塑造的。借用的只是模块结构（depthwise conv + GRN），并非视觉预训练权重。
- 冻结/训练口径：S³ Tokenizer、推理时 BigVGAN 冻结；SASLM 内部先冻结 Whisper 编码器训 LM（前 550K 步）、再冻 LM 微调编码器；第二阶段 DiT + ConvNeXt V2 完全联合训练。

### 8.2. 两阶段分开训练，且存在 teacher-forcing 落差

- SASLM（16kHz，Base 1.15M 步）与 FM 阶段（24kHz，Base 350K 步）先后独立训练，无梯度贯通（附录 B.1）。
- **关键细节**：FM 训练时的语义条件是 tokenizer 从**干净语音**直接提取的 token，不是 SASLM 生成的；推理时才换成 SASLM 从受损语音净化的 token。训练/推理存在 [[方向/大模型/训练/Teacher Forcing（教师强制）|teacher-forcing]] 式条件分布落差，由 SASLM 的净化质量 + FM 侧隐式对齐/degrad mask 的鲁棒性吸收。
- 解耦的工程收益：两阶段可用不同采样率、数据配比、时长分别调优；代价是误差单向传递（SASLM 的错 token，FM 只能照着错语义生成）。

### 8.3. 为什么不做端到端微调（论文未明说，结构性原因）

1. **离散接口阻断梯度**：SASLM 输出离散 token ID（argmax/采样不可微），FM 的 MSE 无法干净地反传；Gumbel 松弛 / STE 在长语音序列上不稳定。业界（CosyVoice、[[方向/AI语音/模型/GenSE|GenSE]]）同样因此分阶段。
2. **自回归无法塞进训练循环**：FM 需要完整 token 序列作条件，实时生成要逐步 AR 解码且无 [[方向/大模型/训练/Teacher Forcing（教师强制）|teacher forcing]]，吞吐不可行。
3. **优化性质差异大**：AR cross-entropy（离散、16kHz）vs 连续 MSE 回归（掩码补全、24kHz），联合训练有任务干扰风险——声学梯度可能损害 SASLM 的语义纯度。
4. 可行折中（后续空间）：用 SASLM 生成 token 微调 FM（scheduled sampling 式）、DPO/RL 式整管线后训练、或用连续语义 embedding 替代离散接口。

### 8.4. 采样率配置与评测口径

- SASLM 16kHz：跟随 Whisper-large-v3 / SenseVoice 的 ASR 生态，语义建模不需要高带宽，且压低 AR 序列长度。
- FM 24kHz：声学保真需要 8kHz 以上带宽；24kHz（12kHz 带宽）是质量/算力平衡，且是 **F5-TTS 标准配方**（24kHz、100 维 mel、hop 256），BigVGAN 官方权重同为 24kHz，整条链路免适配。
- **评测口径**：所有模型（含基线）的增强输出统一重采样到 **16kHz** 再算指标（PESQ wideband、DNSMOS、ESTOI 均为 16kHz 生态）——SenSE 的 24kHz 带宽优势在论文数字中被抹平，报告优势是在此保守口径下取得的。

### 8.5. 输入带宽：无显式限制

- 容器采样率统一 24kHz，有效带宽任意：训练/测试里带宽限制是失真的一种（随机降到 {2,4,8,16,22.05}kHz 再升回），DNS 集本身 ≤8kHz。
- 抗混叠降采样真正抹掉高频，mel 上表现为高频频段空缺——模型从训练中学会识别此模式并做带宽扩展（任意带宽 → 固定 24kHz 全带宽输出），无需显式带宽估计或失真类型标签。
- 高频补全依赖生成骨架（语义 token 提供内容、prompt 约束音色），对应 [[方向/AI语音/知识/生成式语音增强/SE Generative Prior（语音增强生成先验）|SE Generative Prior]] 中 A 类先验的动机。

## 9. 待验证

- Hugging Face 权重与 GitHub 推理命令的 checkpoint 命名是否完全一致。
- `SenSE_tiny` 的真实 RTF、显存和音质是否适合实时前端。
- 中文、方言、TTS 合成音频和通话链路上的 DNSMOS / [[方向/AI语音/评估/SpeechBERTScore（语音语义相似度）|SpeechBERTScore]] / dWER 是否和人工听感一致。
- 与 UniSE、[[方向/AI语音/模型/AnyEnhance]]、FlowSE、DeepFilterNet、RNNoise 在同一小样本集上的延迟和质量差异。
- RTF / 参数量 / FLOPs：论文未报告（NFE=8、CFG 0.5 已知），需自行实测。

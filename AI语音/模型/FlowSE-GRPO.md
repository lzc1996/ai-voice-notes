---
title: FlowSE-GRPO
类型: 模型
参数量: FM DiT 46.18M；LoRA 后训练 1.57M
发表时间: 2026-01-23
时间依据: arXiv 首次提交日
任务:
  - 语音增强
开放状态:
  - paper
aliases:
  - FlowSE-GRPD
  - Training Flow Matching Speech Enhancement via Online Reinforcement Learning
tags:
  - 类型/对象
  - 方向/AI语音
  - 任务/语音增强
---

# FlowSE-GRPO

## 0. 背景

**问题现场**：Flow Matching 生成式语音增强的预训练目标与感知质量、下游指标不对齐，后训练对齐手段缺失。

**前序路线的缺口**：此前生成式 SE 的对齐只有离线方法（如 DPO），所需训练步数多、收敛慢。

**FlowSE-GRPO 的切入点**：把图像生成领域的 Flow-GRPO 在线 RL 迁移到 FM 语音增强——ODE→SDE 提供采样随机性、窗口训练降开销、多指标奖励防 reward hacking，仅用 LoRA 后训练即超越 DPO。

## 1. 身份

FlowSE-GRPO 是**首个把在线 GRPO 后训练引入 Flow Matching 语音增强**的工作，全名 *FlowSE-GRPO: Training Flow Matching Speech Enhancement via Online Reinforcement Learning*（arXiv 2601.16483，2026-01）。作者一作 Haoxu Wang，团队与 ZipEnhancer（H. Wang, B. Tian）有重叠。

此前生成式 SE 的对齐只有离线方法（如 DPO 的 *Multi-metric preference alignment for generative speech restoration*）；本文把图像生成领域的 **Flow-GRPO**（arXiv 2505.05470）迁移到语音增强，证明 on-policy RL 能用远少于 DPO 的步数对齐感知与下游指标。

层级定位（按 vault 约定）：**模型**——有完整 backbone 配置与训练配方；其"ODE→SDE + 窗口训练 + 多指标奖励"的后训练配方可作为独立方法复用到其他 FM 生成式音频模型。

## 2. 核心结构

- **FM 增强基座：** mel 谱域条件 flow matching，骨干 DiT（hidden 512、12 层、8 头、FFN 1024，共 46.18M 参数），预测速度场 $v=x_1-x_0$（$x_1$ 为干净 mel、$x_0\sim\mathcal N(0,I)$），条件为带噪 mel 与 $x_t$ 通道拼接； vocoder 用 CosyVoice2 的预训练 HiFi-GAN。训练与推理均用 classifier-free guidance。
- **时间方向修正：** Flow-GRPO 原设定的去噪方向是 $t:1\to0$，而 FM-SE 是 $t:0\to1$，论文做了符号替换（$v=-v_{se}$、$t=1-t_{se}$ 等）使 Flow-GRPO 的 SDE 更新式可直接套用。
- **ODE→SDE：** 标准 FM 采样是确定性 ODE，无法产生 on-policy RL 所需的随机性；按 Flow-GRPO 把 ODE 转成等边际分布的 SDE，噪声强度 $\sigma_t=a\sqrt{(1-t)/t}$，超参 $a$ 控制探索范围。
- **窗口训练（window training）：** 借自 MixGRPO / Flow-GRPO-Fast，只对早期若干步做 SDE 采样与优化（$ws=2$，去噪步数采样自 [7,10]，窗口起点 $S_{min}$ 采样自 [1,3]），其余步用确定性 ODE，降低训练开销、加速收敛；推理固定 10 步。
- **GRPO 更新：** 每个 prompt 采 $G=10$ 个样本，组内归一化奖励得 advantage，带 clip 与对参考策略的 KL 惩罚；丢弃组内标准差为 0 的组。后训练只动 **LoRA（rank 32, α=64，1.57M 参数）**，LR 2e-4。

## 3. 核心公式

**1. 条件流匹配损失（预训练基座）：**

$$\mathcal{L}_{\text{CFM}} = \mathbb{E}_{t\sim\mathcal U(0,1),\,x_0\sim\mathcal N(0,I),\,x_1}\Big[\big\|v_\theta(x_t, c, t) - (x_1 - x_0)\big\|_2^2\Big]$$

$x_t=(1-t)x_0+tx_1$ 为线性插值路径，$x_1$ 为干净 mel、$x_0\sim\mathcal N(0,I)$ 为高斯起点，$c$ 为带噪 mel 条件（与 $x_t$ 通道拼接），$v_\theta$ 为 DiT 预测的速度场，目标速度 $v=x_1-x_0$。

**2. Classifier-free guidance（训练与推理均使用）：**

$$\tilde v_\theta(x_t, c, t) = v_\theta(x_t, \varnothing, t) + w\,\big(v_\theta(x_t, c, t) - v_\theta(x_t, \varnothing, t)\big)$$

训练时按概率随机丢弃条件 $c$（空条件记 $\varnothing$），推理时以引导强度 $w$ 组合条件与无条件速度场。

**3. ODE→SDE 转换（探索噪声，沿 Flow-GRPO）：**

$$\mathrm{d}x_t = \tilde v_\theta(x_t, c, t)\,\mathrm{d}t + \sigma_t\,\mathrm{d}W_t, \qquad \sigma_t = a\sqrt{\frac{1-t}{t}}$$

$W_t$ 为布朗运动，$\sigma_t$ 为时间相关噪声强度，超参 $a$ 控制探索范围（论文取 $a=0.4$）；确定性 ODE 加噪后才有 on-policy RL 所需的采样随机性。方向符号已按 FM-SE 约定替换（$t:0\to1$）。

**4. 组内归一化 advantage 与 GRPO 损失（后训练）：**

$$A_i = \frac{R_i - \bar R}{\sigma_R}, \qquad \mathcal{L}_{\text{GRPO}} = -\mathbb{E}\Big[\frac{1}{G}\sum_{i=1}^{G}\Big(\min\big(r_i(\theta)\,A_i,\ \operatorname{clip}(r_i(\theta),\,1\pm\epsilon)\,A_i\big) - \beta\,\mathrm{KL}\big[\pi_\theta\,\|\,\pi_{\text{ref}}\big]\Big)\Big]$$

每个 prompt（带噪 mel）采 $G=10$ 个样本，$R_i$ 为样本 $i$ 的奖励，$\bar R$、$\sigma_R$ 为组内均值与标准差（组内标准差为 0 的组丢弃）；$r_i(\theta)=\pi_\theta(o_i|c)/\pi_{\text{ref}}(o_i|c)$ 为相对参考策略 $\pi_{\text{ref}}$（预训练模型）的概率比，clip 约束更新幅度，$\beta\,\mathrm{KL}$ 惩罚策略漂移。

**5. 多指标奖励（SE 任务特有）：**

$$R_i = \lambda_1\,\frac{R_{\text{DNSMOS}}/4 - \mu_1}{\sigma_1} + \lambda_2\,\frac{R_{\text{Spk}} - \mu_2}{\sigma_2} + \lambda_3\,\frac{R_{\text{SBS}} - \mu_3}{\sigma_3}, \qquad (\lambda_1,\lambda_2,\lambda_3)=(0.6,1,1)$$

$R_{\text{DNSMOS}}$ 为 DNSMOS P.835 的 OVRL（16 kHz 重采样后除以 4），$R_{\text{Spk}}$ 为 ERes2Net 说话人 embedding 余弦相似度，$R_{\text{SBS}}$ 为 SpeechBERTScore；各指标用收集数据的均值 $\mu_k$、标准差 $\sigma_k$ 归一化后加权求和——单指标优化会 reward hacking。

**6. 窗口训练（window training）：**

$$N\sim\mathcal U\{7,10\}, \qquad S_{\min}\sim\mathcal U\{1,3\}, \qquad ws=2$$

$N$ 为总去噪步数，$S_{\min}$ 为优化窗口起点，仅对 $t\in[S_{\min},\,S_{\min}+ws]$ 内的步做 SDE 采样与 GRPO 更新，其余步走确定性 ODE；推理固定 10 步。

## 4. 测试基准与性能

**测试基准：** 评测为 DNS2020 测试集（No Reverb / With Reverb / 真实录音三个子集，详见「关键结果」）；预训练数据：干净语音 DNS2020、LibriTTS-960、VCTK、WSJ、EARS、mls_english（URGENT 2025 Track 2），噪声 DNS2020、WHAM!、DEMAND、fma_medium、FSD50K、仿真风噪（详见「训练数据与流程」）。推理固定 10 步；DNSMOS OVRL 按 16 kHz 重采样口径（见「奖励设计」）。

**性能指标：** 笔记「关键结果（DNS2020 测试集）」已含全部关键数字（OVRL / SpkSim / SBS 提升、vs DPO 对比、消融），此处不重复。指标口径：DNSMOS P.835 OVRL、ERes2Net SpkSim、SpeechBERTScore；PESQ / SI-SDR / ESTOI 等客观指标与 RTF 未见于笔记与 arXiv 摘要（待核）。

（来源：笔记正文「关键结果」「训练数据与流程」；arXiv 2601.16483 摘要仅定性描述）

## 5. 奖励设计（SE 任务特有）

- $R_{\text{DNSMOS}}/4$：DNSMOS P.835 的 OVRL（16 kHz 重采样）。
- $R_{\text{Spk}}$：CosyVoice2 同款 ERes2Net 提取说话人 embedding 的余弦相似度。
- $R_{\text{SpeechBERTScore}}$：自监督语音特征上的 BERTScore，衡量语义相似度。
- **多指标奖励：** 各指标按收集数据的标准差归一化后加权求和，$\lambda_1=0.6$（DNSMOS）、$\lambda_2=\lambda_3=1$。动机是**单指标优化会 reward hacking**——DNSMOS 冲到 3.59 但音频保真度主观变差；只优化 Spk 或 SBS 反而拉低 DNSMOS。

## 6. 训练数据与流程

两阶段：预训练（100k 步，LR 1e-4，4 GPU 动态 batch）→ GRPO 后训练。干净语音：DNS2020、LibriTTS-960、VCTK、WSJ、EARS、mls_english（URGENT 2025 Track 2）；噪声：DNS2020、WHAM!、DEMAND、fma_medium、FSD50K、仿真风噪。每次后训练迭代：6 条带噪 prompt × 重复 12 次 = 72 prompt，每条采 10 个样本共 720 候选打分，重组为 batch 12，做 4 次参数更新。

## 7. 关键结果（DNS2020 测试集）

- **多指标奖励 vs 无 RL 基座：** No Reverb 集 OVRL 3.373→3.549、SpkSim 88.88→90.43、SBS 86.35→86.72；With Reverb 集 OVRL 3.254→3.530；真实录音集 OVRL 3.115→3.356。
- **vs DPO：** GRPO 的 OVRL 提升 +0.176（No Reverb）/ +0.274（With Reverb），DPO 仅 +0.065 / +0.144；且 GRPO 只训 5k 步，DPO 需 20k 步。
- **消融：** 噪声水平 $a$ 从 0.2 提到 0.4 加快奖励上升但更易 hacking（多指标奖励取 $a=0.4$）；全步训练（Non-Fast）比早期窗口训练（Fast）奖励增长更慢。

## 8. 关键资源

- [FlowSE-GRPO 论文](https://arxiv.org/abs/2601.16483)
  - 内容定位：方法、奖励设计与全部实验的主来源。核验日期：2026-08-03
- [Flow-GRPO（图像生成的在线 RL 源头）](https://arxiv.org/abs/2505.05470)
  - 内容定位：ODE→SDE 转换与 MDP 形式化的直接来源。核验日期：2026-08-03
- [MixGRPO（混合 ODE-SDE 窗口训练）](https://arxiv.org/abs/2507.21802)
  - 内容定位：窗口训练策略的来源。核验日期：2026-08-03
- [FlowSE（FM 语音增强基座路线）](https://arxiv.org/abs/2505.19476)
  - 内容定位：本文基座所属的 FM-SE 路线（注意：本文 DiT+mel 基座为自训，非直接复用 FlowSE 权重）。核验日期：2026-08-03

## 9. 相关对象

- [[方向/AI语音增强/README|AI 语音增强]]
- [[方向/AI语音/知识/基础概念/Flow Matching（流匹配）|Flow Matching]]：基座的生成训练范式
- [[方向/大模型/训练/强化学习/GRPO|GRPO]]：后训练算法本体（LLM 语境下的原始形式）
- [[方向/AI语音/知识/基础概念/Flow-GRPO（流匹配模型在线强化学习）|Flow-GRPO]]：ODE→SDE 转换与 GRPO 迁移到 FM 模型的方法论源头
- [[方向/AI语音/知识/基础概念/ODE（常微分方程）|ODE]]：被改造为 SDE 的确定性采样器
- [[方向/AI语音/评估/DNS Challenge（深度噪声抑制挑战）|DNS Challenge]]：训练与评测数据来源（DNS2020）
- [[方向/AI语音/评估/OVRL_MOS|OVRL_MOS]]：DNSMOS OVRL 指标口径，主奖励来源
- [[方向/AI语音/评估/SpkSim|SpkSim]]：说话人相似度奖励
- [[方向/AI语音/评估/SpeechBERTScore（语音语义相似度）|SpeechBERTScore]]：语义相似度奖励
- [[方向/AI语音/评估/URGENT（通用语音增强挑战）|URGENT]]：预训练用了 URGENT 2025 Track 2 的 mls_english
- [[方向/AI语音/知识/基础概念/Vocoder（声码器）|Vocoder]]：mel→波形的 HiFi-GAN 环节
- [[方向/AI语音/知识/生成式语音增强/DiT 与语音增强（DiT-based Speech Enhancement）|DiT 与语音增强]]：所在技术路线全景
- [[方向/AI语音/模型/DiT-Flow|DiT-Flow]]：同为 DiT+FM 的 SE 模型，可对比基座设计

## 10. 待验证

- 多指标奖励权重（0.6/1/1）与噪声水平 $a$ 的耦合：论文承认权重需仔细调，是否存在更鲁棒的自适应策略。
- reward hacking 的检测口径：DNSMOS 虚高时哪些客观指标（PESQ、LSD、ESTOI）会同步劣化，论文主要靠主观听感说明。
- LoRA-only 后训练的天花板：全参数 GRPO 是否进一步提升，还是 LoRA 本身就是防 hacking 的正则。
- 该配方迁移到潜空间 FM 模型（如 DiT-Flow）或通用语音恢复（多失真）场景的效果。
- PESQ / SI-SDR / ESTOI 等客观指标与 RTF：论文是否报告了这些数字（arXiv 摘要未给出），需从全文核对。

---
title: UniSE（Unified Speech Enhancement）
类型: 框架
发表时间: 2025-10-23
时间依据: arXiv 首次提交日（v1，已被 Interspeech 2026 接收）
任务:
  - 语音增强
开放状态:
  - paper
  - code
  - demo
aliases:
  - UniSE
  - UniSE v1
  - UniSE v2
  - UniSE v3
tags:
  - 类型/对象
  - 方向/AI语音
  - 任务/语音增强
---

在人工智能和语音信号处理领域，**UniSE（Unified Speech Enhancement）** 是一个非常前沿的统一框架。它的核心创新在于：**打破了传统语音增强各任务之间的壁垒，首次验证了如何利用“仅解码器（Decoder-only）的自回归语言模型（AR LM）”来同时解决多种不同的语音处理任务。**

层级定位（按 vault 的模型/框架/系统约定）：UniSE 是**框架**——"WavLM 条件 + decoder-only LM + 离散 codec token"是可替换组件槽位的方法模板（换 codec、换 LLM 规模思路不变）；论文给出的具体实现是该框架的参考模型。

简单来说，UniSE 就像是语音增强界的大语言模型（如 GPT、LLaMA），用一套统一的架构和逻辑，去搞定各种复杂的音频修复和分离工作。

我们可以从以下几个维度来深入拆解 UniSE：

## 0. 背景

**问题现场**：传统语音增强中降噪/去混响、目标说话人提取、语音分离各需专门模型，希望用一个统一架构搞定多种音频修复与分离工作。

**前序路线的缺口**：传统语音增强是"连续信号"回归问题（调整波形或频谱），而大语言模型只能处理离散 token，两种范式难以直接打通。

**UniSE 的切入点**：首次验证 decoder-only 自回归语言模型统一 SR/TSE/SS——WavLM 跨层平均条件特征作 prompt，LLaMA 式 LM 自回归生成 BiCodec 离散语音 token 再解码为波形，靠改变提示条件在任务间切换。

## 1. 核心解决的三大语音任务

在传统方法中，处理不同的声音问题需要训练不同的模型。而 UniSE 将以下三种核心任务统一到了同一个模型中：

- **[[方向/AI语音/知识/基础概念/SR（语音恢复）|语音恢复]] (Speech Restoration, SR)：** 针对单人语音。去除背景噪音、消除房间混响、修复断断续续或失真的音频，让声音变干净、变清晰。
    
- **[[方向/AI语音/知识/基础概念/TSE（目标说话人提取）|目标说话人提取]] (Target Speaker Extraction, TSE)：** 针对多人混杂场景。给模型一段目标人的“声音密码”（参考音频），模型就能在嘈杂的、多人群聊的环境中，只把这个人的声音提取出来，过滤掉其他人的声音。
    
- **[[方向/AI语音/知识/基础概念/SS（语音分离）|语音分离]] (Speech Separation, SS)：** 针对多人混杂场景。在不需要参考音频的情况下，直接把混在一起的两个或多个人的声音“剥离”成各自独立的音频轨道。
    

## 2. 三大核心组件（它是如何工作的？）

UniSE 框架的设计非常精妙，它主要由三个部分组成：

```
[降质/混合音频] --> [条件特征提取器 ([[方向/AI语音/模型/WavLM|WavLM]])] \
                                              --> [Decoder-only LM (LLaMA架构)] --> [离散Token] --> [[方向/AI语音/模型/BiCodec|BiCodec解码器]] --> [清晰音频]
[参考音频(如果有)] -> [条件特征提取器 ([[方向/AI语音/模型/WavLM|WavLM]])] /
```

### 2.1. 条件特征提取器 (Conditional Feature Extractor)

为了让模型看懂输入的音频，UniSE 使用了预训练的 **[[方向/AI语音/模型/WavLM|WavLM]]** 模型。

- 在训练时，WavLM 的参数是被冻结（不改变）的。
    
- 模型会把 WavLM 所有 Transformer 层的特征进行平均，以同时获取丰富的**声学信息**（音色、音高）和**语义信息**（说了什么内容）。
    
    - 注意这里是**跨层平均**，不是层内（时间轴）平均：WavLM-base 共 12 层，每层输出同形状的帧级序列 $h^{(l)} \in \mathbb{R}^{T \times d}$，逐帧逐维取平均 $h_t = \frac{1}{L}\sum_{l=1}^{L} h_t^{(l)}$，输出仍为一条 $[T, d]$ 序列，帧数和时间分辨率完全保留。
    - 动机：低层偏声学细节（音色、音高），高层偏语义（内容），只取最后一层会丢声学信息；全层等权平均是最简单的"全都要"方案。论文未消融"等权平均 vs 只取某层 vs 可学习加权和"，SUPERB 等基准上可学习加权和（weighted sum）通常略优。
    - 与之相对：若在时间轴上把 $T$ 帧压成一个向量会丢掉全部时序信息，无法作为条件——所以语义上只能是跨层平均。
- 最后通过一个简单的线性适配器（Adapter），把这些特征转换为大语言模型（LM）能够理解的“语言空间”。
    

### 2.2. 离散 Token 编解码器 (Discrete Token Codec - [[方向/AI语音/模型/BiCodec|BiCodec]])

传统的语音增强是“连续信号”的回归问题（调整波形或频谱）。但大语言模型只能处理“离散的字词（Tokens）”。为了解决这个冲突，UniSE 引入了 **[[方向/AI语音/模型/BiCodec|BiCodec]]**：

- **全局特征 ($E_g$)：** 把目标语音编码为固定 32 个 Tokens，这里面主要包含说话人的个体特征（音色）。
    
- **语义特征 ($E_s$)：** 把语音内容编码为每秒 50 个 Tokens 的灵活长度，这里面主要包含说话的内容。
    
- 在推理时，模型预测出这些离散的 Tokens，再通过 [[方向/AI语音/模型/BiCodec|BiCodec]] 的解码器，就能把 Tokens 重新还原成高质量的连续语音波形。
    

### 2.3. 统一多任务的大模型底座 (Decoder-only LM Backbone)

这是 UniSE 的“大脑”，采用了类似 **LLaMA** 的大模型架构。

- 它将前面提取到的条件特征（环境噪音、混合声音、参考人声）作为输入 Prompt（提示词）。
    
- 以自回归（Autoregressive）的方式，像 ChatGPT 逐字生成文本一样，**逐个生成目标语音的离散 Tokens**。
    
- 通过改变输入的“提示条件”，模型就能在“降噪”、“提取特定人声”或“多声道分离”之间自由切换。
    

## 3. 版本线：v1 / v2 / v3

> [!note] 版本口径
> 官方 arXiv 目前明确有 v1（2025-10-23）和 v2（2026-07-02）；这里把后续以 UniSE 为 base 的 GSPO 感知奖励后训练记作 v3 线，核心是区分“基础框架”“DPO/PRL 对齐”“GSPO/多奖励后训练”三件不同事情。

| 版本 | 核心新增 | 解决的问题 |
| --- | --- | --- |
| v1 | 统一 decoder-only AR LM 框架：WavLM 条件、BiCodec 离散 token、LLaMA 式 LM；统一 SR / TSE / SS。 | 证明 SE 子任务可以被改写成同一套条件语音 token 生成问题。 |
| v2 | 渐进式强化学习微调（PRL）：先用 DNSMOS 做 DPO，再加入 WavLM 相似度做细化。 | 把优化目标从 token-level CE 推向感知质量，同时压住内容/音色漂移。 |
| v3 | GSPO 感知奖励后训练：用 DNSMOS、WER、UTMOS 等多指标 reward 直接做 on-policy 序列优化。 | 进一步绕开离线偏好对/代理奖励，直接优化不可微的感知与下游指标。 |

### 3.1. v2：渐进式强化学习微调 (Progressive RL / DPO)

传统语音增强用 SI-SNR 这类信号级损失做监督，但这些指标和人耳的主观感知并不总是一致的。UniSE v2 借鉴 LLM 领域的对齐思路，在预训练之后用 **DPO（Direct Preference Optimization）** 做感知质量微调：

- **角色设定：** 参考模型 $\pi_r$ = 预训练 UniSE（冻结）；策略模型 $\pi_\theta$ 从其初始化、实际被更新。
    
- **单步流程：** 条件 $c$（退化音频特征 $E_d$，TSE 时还有参考特征 $E_r$）→ 策略模型对同一 $c$ **采样生成两个候选 token 序列**（on-the-fly，采样随机性构成偏好对，无需人工标注）→ 候选经 [[方向/AI语音/模型/BiCodec|BiCodec]] 解码器还原波形 → 按当前阶段评判标准打分，分出“赢家 $y_w$”和“输家 $y_l$” → 计算 DPO 损失更新 $\pi_\theta$（$\pi_r$ 不动）。
    
    - 评判标准是**音频层面**的，所以候选必须先解码成波形再评分：S1 对波形跑 DNSMOS 取 SIG/BAK/OVRL 均值；S2 额外计算候选与真实目标语音的 WavLM 特征欧氏距离。
        
- **DPO 损失（序列级对数概率）：** $\mathcal{L}_{DPO} = -\mathbb{E}\log\sigma[\beta(\log\frac{\pi_\theta(y_w|c)}{\pi_r(y_w|c)} - \log\frac{\pi_\theta(y_l|c)}{\pi_r(y_l|c)})]$，直觉是让策略模型相对参考模型“更偏爱赢家、远离输家”，分母 $\pi_r$ 把更新锚定在预训练模型附近。
    
- 微调分两个渐进阶段，评判标准由粗到细逐步引入，避免异构偏好信号相互冲突：
    
    - **S1（感知质量）：** 用 **DNSMOS** 的三个子分数（SIG/BAK/OVRL）的平均值判定胜负，损失为 $\alpha\mathcal{L}_{CE}+\mathcal{L}_{DPO}^{DNSMOS}$。
        
    - **S2（相似度细化）：** 额外引入 **WavLM 特征相似度**（候选与目标语音的 WavLM 特征欧氏距离），优化语义和声学一致性，DNSMOS 与 WavLM 两个 DPO 损失各占 0.5 权重。
        
- 保留交叉熵损失项 $\alpha\mathcal{L}_{CE}$ 是为了防止模式崩塌：$\alpha$ 太低时 OVRL 极高但说话人相似度（SIM）严重恶化，作者最终取 $\alpha=0.4$ 平衡感知质量与音色保持。
    
- **超参：** $\alpha=0.4$，5k 步，batch size 32，学习率 5e-5（比预训练 1e-3 低两个量级，典型微调设置）。
    
- **与文本 DPO 的实质差别：** 偏好来源不同——文本 DPO 的胜负对来自人工标注或奖励模型，UniSE 由客观音频指标（DNSMOS / WavLM 距离）在线判定，省去训练奖励模型。
    
- 效果：PRL 微调让 SS 任务在 Libri2Mix 和 WSJ0-2mix 上的 OVRL 分别再提升 0.21 和 0.13；消融显示渐进引入标准优于单阶段联合优化。
    

### 3.2. v3：GSPO 感知奖励后训练

v3 线的重点不是改掉 UniSE 的基础架构，而是在 SE language model 预训练/监督训练之后，增加 **GSPO（Group Sequence Policy Optimization）** 这类面向感知指标的后训练阶段：

- **训练对象：** 仍以 UniSE 这类自回归 speech token LM 为 base model。
- **奖励信号：** 直接使用 DNSMOS、WER、UTMOS 等不可微信号做多指标 reward，而不是只靠 token-level CE 或离线偏好对。
- **相对 v2 的差异：** v2 是 DPO/PRL，核心是“采样两个候选 → 指标判赢家/输家 → 偏好优化”；v3 是 GSPO/on-policy RL，核心是“同一条件下生成一组候选 → 用多奖励直接优化序列策略”。
- **定位：** 更像 UniSE 的后训练升级线，解决感知质量、ASR 可懂度和单指标 reward hacking 的平衡问题；不改变 v1 的 WavLM + codec LM 主干。


## 4. 核心公式

**1. 预训练：token-level 交叉熵：**

$$\mathcal{L}_{\text{CE}} = -\mathbb{E}\Big[\sum_{t}\log \pi_\theta\big(a_t \mid a_{<t},\, c\big)\Big]$$

$c$ 为条件特征（退化/混合音频的 WavLM 跨层平均经线性适配器，TSE 时含参考音频特征），$a_t$ 为 BiCodec 离散 token（全局特征 $E_g$ 32 个 + 语义特征 $E_s$ 每秒 50 个）；decoder-only LM 自回归逐 token 预测，同一条件机制覆盖 SR / TSE / SS。

**2. v2：DPO 感知对齐：**

$$\mathcal{L}_{\text{DPO}} = -\mathbb{E}\log\sigma\Big[\beta\Big(\log\frac{\pi_\theta(y_w|c)}{\pi_r(y_w|c)} - \log\frac{\pi_\theta(y_l|c)}{\pi_r(y_l|c)}\Big)\Big]$$

同一条件 $c$ 下策略 $\pi_\theta$ 采样两个候选序列，解码成波形后按评判标准分出赢家 $y_w$、输家 $y_l$；$\pi_r$ 为冻结的参考模型（预训练 UniSE），$\beta$ 控制对参考的偏离锚定。

**3. 渐进两阶段目标（PRL）：**

$$\mathcal{L}_{S1} = \alpha\,\mathcal{L}_{\text{CE}} + \mathcal{L}_{\text{DPO}}^{\text{DNSMOS}}, \qquad \mathcal{L}_{S2} = 0.5\,\mathcal{L}_{\text{DPO}}^{\text{DNSMOS}} + 0.5\,\mathcal{L}_{\text{DPO}}^{\text{WavLM}}$$

S1 以 DNSMOS 三子分数（SIG/BAK/OVRL）均值为胜负标准；S2 再加入候选与目标语音的 WavLM 特征欧氏距离；保留 $\alpha\mathcal{L}_{\text{CE}}$ 防模式崩塌（$\alpha=0.4$）。

**4. v3：多指标感知奖励的 on-policy 组优化（GSPO 式）：**

$$R_i = \sum_k \lambda_k\, r_k(y_i), \qquad A_i = \frac{R_i - \bar R}{\sigma_R}, \qquad \nabla_\theta J \approx \frac{1}{G}\sum_{i=1}^{G} A_i\,\nabla_\theta\log\pi_\theta(y_i|c)$$

同一条件生成 $G$ 个候选序列，$r_k$ 为 DNSMOS / WER / UTMOS 等多指标 reward（$\lambda_k$ 为权重），组内归一化得 advantage $A_i$ 后做策略梯度更新，直接优化不可微的感知与下游指标。（GSPO 在原文中的具体目标形式（KL/clip 项等）待核，见待验证）

## 5. 测试基准与性能

**测试基准：** 三大任务统一评估：SR（语音恢复）、TSE（目标说话人提取）、SS（语音分离）；笔记已提及的评测集：SS 任务的 Libri2Mix 与 WSJ0-2mix；其余评测集清单（DNS 等）与采样率待核。

**性能指标：** 笔记正文已有：v2 PRL 微调后 SS 任务 OVRL 在 Libri2Mix / WSJ0-2mix 分别再提升 +0.21 / +0.13（见「版本线」）。绝对数字（PESQ、SI-SDR、DNSMOS、WER 等）待核——arXiv 2510.20441 摘要仅定性（"competitive performance compared to discriminative and generative baselines"），无数字。

（来源：笔记正文「版本线」；arXiv 2510.20441 摘要）

## 6. Backbone 结构归因实验：LLaMA-style vs Qwen3-0.6B

本地实验语境：以 UniSE 为基准框架，固定 WavLM 条件特征、BiCodec token 空间、数据、训练策略和解码参数，比较不同 decoder-only LLM backbone 对语音 token 自回归建模的影响。需要先区分两类实验：

- **架构实验**：用 LLaMA-style 或 Qwen3-style decoder 结构从零初始化训练，比较结构归纳偏置。
- **预训练实验**：加载 Qwen3 trunk 权重，但 UniSE 的 audio adapter、codec embedding 和 output head 仍按 UniSE token 空间训练；不要直接复用 Qwen3 文本 tokenizer / lm_head。
- **容量口径**：公平对比应统计 UniSE 实际参与训练/推理的参数量，不应把未使用的 Qwen3 文本 embedding / lm_head 算成有效容量。

当前 LLaMA-style 配置已把隐藏维度调到 `hidden_size=1024`，并用 `num_layers=32`、`num_attention_heads=32` 让整模型量级接近 Qwen3-0.6B。但这只是容量附近，不是结构对齐；最关键的结构差异仍然集中在 attention、FFN、RoPE 和归一化。

| 维度                          | LLaMA-style 0.6B 配置                                          | Qwen3-0.6B 结构口径                                      | UniSE 中的可能影响                                                   |
| --------------------------- | ------------------------------------------------------------ | ---------------------------------------------------- | -------------------------------------------------------------- |
| 层数                          | 32 层                                                         | 28 层                                                 | LLaMA-style 更深，可能提升长依赖组合能力，也增加优化难度和延迟。                         |
| hidden size                 | 1024                                                         | 1024                                                 | 主宽度已对齐，便于观察其他结构差异。                                             |
| attention heads / head dim  | 32 heads，约 32 dim/head                                       | 16 query heads，`head_dim=128`                        | 单头表征维度差异很大，可能影响长音频前缀、音色信息和语义 token 依赖建模。                       |
| KV heads                    | 若未显式配置，通常近似 MHA                                              | 8 KV heads，GQA                                       | GQA 降低 KV cache 和显存，也会改变条件前缀信息被压缩/复用的方式。                       |
| FFN intermediate            | 代码默认近似 `hidden_size * 4 = 4096`                              | `intermediate_size=3072`                             | LLaMA-style FFN 更宽，可能 train loss 更低但更容易过拟合 codec token 分布。     |
| QK-Norm                     | 通常无                                                          | 有                                                    | 可能稳定长序列 attention logits，减少 loss spike、重复生成或长样本崩坏。             |
| RoPE theta / position range | `max_position_embeddings=4096`，theta 取决于 LLaMAConfig 默认/显式设置 | `rope_theta=1000000`，`max_position_embeddings=40960` | 若 enroll + mix + semantic token 总长接近上限，Qwen3 的位置编码余量和频率分布可能更稳。 |
| dropout                     | `dropout_p=0.1`                                              | Qwen3 attention dropout 常见为 0.0                      | 小数据时 dropout 可能帮泛化，但会让结构对比不干净。                                 |
| 文本 embedding / lm_head      | UniSE 自定义 12291 token 输出空间                                   | Qwen3 文本 vocab 很大且 tied embedding                    | UniSE 任务不直接使用文本词表；文本 embedding 参数不应作为音频 token 建模能力的一部分。        |

最小归因顺序：

1. **先排除容量假象**：统计去掉文本 embedding / lm_head 后的实际 decoder trunk 参数量。
2. **优先做 attention ablation**：固定 `hidden=1024`，只改 `num_heads`、`num_key_value_heads`、`head_dim`、QK-Norm。
3. **再做 FFN ablation**：固定 attention 后，对比 `intermediate_size=3072` 与 `4096`。
4. **最后看 RoPE**：固定结构后对比 `rope_theta=1e4 / 1e6` 和最大位置长度；若实际序列远低于 4096，优先级下降。
5. **单独统计生成稳定性**：除 PESQ / STOI / SI-SDR / DNSMOS 外，记录 semantic token 重复率、提前 EOS、异常静音、音色漂移、长样本失败率。

实验结论解释模板：

- 若 Qwen3 更快但客观指标接近，优先归因到 **GQA / KV cache 效率**，不是文本语义能力。
- 若 Qwen3 长样本更稳，优先怀疑 **QK-Norm + RoPE theta + head_dim**。
- 若 LLaMA-style train loss 更低但 PESQ/STOI/SI-SDR 不升，优先怀疑 **FFN 更宽或层数更深导致过拟合 audio token 分布**。
- 若 TSE / RTSE 差异明显大于 SE，说明结构差异主要影响 **prefix conditioning / speaker reference 信息保留**，重点回看 attention。
- 若所有指标差异很小，UniSE 表现可能更多由 WavLM、BiCodec、训练数据和 decoder 容量决定，而不是 LLaMA/Qwen 名字本身。

建议保留 4 个主实验：

- **LLaMA-0.6B-current**：当前 32L / 1024H / 32 heads 容量基线。
- **Qwen3-random-arch**：Qwen3Config 从零初始化，只比较架构。
- **Qwen3-pretrained-trunk**：加载 Qwen3-0.6B trunk，重训 UniSE audio adapter / codec embedding / output head，观察预训练初始化是否有收益。
- **Qwen3-size-controlled**：去掉文本 embedding / lm_head 后重新估算参数量，调层数或 FFN，使 UniSE 有效参数量接近 LLaMA 版本。

相关结构笔记：[[方向/大模型/LLM/模型/Qwen3]]、[[方向/大模型/LLM/模型/LLaMA]]。

外部核验锚点：[Qwen3-0.6B config](https://huggingface.co/Qwen/Qwen3-0.6B/blob/main/config.json)、[Qwen3 Technical Report](https://arxiv.org/abs/2505.09388)、[UniSE 官方代码](https://github.com/alibaba/unified-audio/tree/main/QuarkAudio-UniSE)。

## 7. UniSE 的核心优势

- **真正的“大模型化”：** 证明了文本领域大火的 Decoder-only 架构在语音底层信号处理（非文本生成）上同样具备极强的泛化能力。
    
- **极高的灵活性：** 传统的模型“术业有专攻”，降噪模型做不了语音分离。而 UniSE 实现了一机多能，精简了AI落地时的模型部署成本。
    
- **高质量的音频重构：** 借助离散 Codec 技术，它生成的语音在保持原作者音色不失真、去除杂音方面表现出了非常惊艳的效果。
    

总结来说，**UniSE 是将大语言模型（LLM）的设计哲学成功引入语音增强领域的一次成功尝试**，它让语音控制、听力辅助设备、会议录音转写等场景下的音频净化变得更加智能和统一。

## 8. 相关对象

- [[方向/AI语音/知识/技术路线/LLM-SE Training Recipe（借鉴 NLP LLM 的语音增强训练配方）]]：可把 UniSE 视为这套 recipe 的强参考实现 / direct Stage 2 baseline。
- [[方向/AI语音/知识/技术路线/LLM-SE Stage 1（Clean Speech Token LM 预训练）]]：用于对比 UniSE-style direct conditional training 与 prior-first training。
- [[方向/AI语音/知识/技术路线/LLM-SE Stage 2（多退化条件重建）]]：对应 UniSE 的 WavLM condition + decoder-only LM + clean target token prediction 主体。

## 9. 关键资源

- [UniSE: A Unified Framework for Decoder-only Autoregressive LM-based Speech Enhancement](https://arxiv.org/abs/2510.20441)
  - 内容定位：UniSE v1/v2 主论文；v1 定义 decoder-only AR LM-based speech enhancement 框架，v2 增加 PRL/DPO 对齐。
  - 用途：确认框架发布时间、任务边界、核心机制和 v2 修订。
  - 核验日期：2026-07-30
- [alibaba/unified-audio](https://github.com/alibaba/unified-audio)
  - 内容定位：官方统一音频项目入口，记录 UniSE、UniSE-V2 等发布线索。
  - 用途：跟踪代码、模型和后续版本。
  - 核验日期：2026-07-30
- [Post-Training Speech Enhancement Language Models with Perceptual Rewards](https://arxiv.org/abs/2606.21458)
  - 内容定位：UniSE / [[方向/AI语音/模型/GenSE|GenSE]] 上的 GSPO 多奖励后训练；本文中作为 v3 线索。
  - 用途：区分 v2 的 DPO/PRL 与 v3 的 GSPO/on-policy perceptual reward 后训练。
  - 核验日期：2026-08-05

## 10. 待验证

- UniSE 官方是否会把 GSPO 后训练版本正式命名为 UniSE-V3；当前笔记按”v3 线 / 后训练升级”暂记。
- GSPO 在原文（arXiv 2606.21458）中的具体目标形式（是否含 KL 惩罚与 clip 项、组大小 G、奖励权重 $\lambda_k$）需从论文核对。
- 各任务评测集清单与绝对指标数字（PESQ/SI-SDR/DNSMOS/WER/OVRL 绝对值）需从论文全文核对（摘要无数字）。

## 11. 关键来源

- [UniSE: A Unified Framework for Decoder-Only Autoregressive LM-Based Speech Enhancement](https://arxiv.org/abs/2510.20441)
  - 内容定位：框架设计、三大任务（SR/TSE/SS）与全部实验的主来源；已被 Interspeech 2026 接收；v2（2026-07）新增渐进式强化学习（PRL/DPO）微调。核验日期：2026-07-30
- [UniSE 官方代码（GitHub: alibaba/unified-audio · QuarkAudio-UniSE）](https://github.com/alibaba/unified-audio/tree/main/QuarkAudio-UniSE)
  - 内容定位：v2 论文给出的官方代码与 Demo 地址。核验日期：2026-07-30
- [早期仓库（GitHub: hyyan2k/UniSE）](https://github.com/hyyan2k/UniSE)
  - 内容定位：v1 论文附的作者个人仓库。核验日期：2026-07-30
- [Post-Training Speech Enhancement Language Models with Perceptual Rewards](https://arxiv.org/abs/2606.21458)
  - 内容定位：GSPO + 多指标 perceptual reward 后训练，实验应用到 UniSE 和 [[方向/AI语音/模型/GenSE|GenSE]]；本文暂作 UniSE v3 线来源。核验日期：2026-08-05

---
title: LLM-SE Stage 3（声学保真）
类型: 技术路线
时间依据: 对话沉淀；非单一发表物
上级:
  - "[[方向/AI语音/知识/技术路线/LLM-SE Training Recipe（借鉴 NLP LLM 的语音增强训练配方）]]"
  - "[[方向/AI语音/知识/技术路线/LLM-SE Training Recipe v2（显式解耦训练配方）]]"
相关任务:
  - 语音增强
  - acoustic fidelity
  - flow matching latent generation
aliases:
  - 阶段 3：声学保真
  - acoustic fidelity training
  - FM-DiT acoustic latent generation
  - 阶段 3：Task-Specific SE Finetuning
  - task-specific SE / dereverb / BWE finetuning
  - 任务特化增强微调
tags:
  - 类型/对象
  - 方向/AI语音
  - 任务/语音增强
  - 主题/训练
  - 主题/语音表示
---

# LLM-SE Stage 3（声学保真）

## 1. 目标

v2 把 Stage 3 从"任务特化微调"重构为**声学保真**：训练 FM-DiT 生成连续 acoustic latent，把 Stage 2 恢复的内容渲染成忠实、好听的波形。

$$
p(a_{clean} \mid s,\ e_{degraded},\ spk,\ prosody)
$$

分工：Stage 2 解决"应该恢复成什么内容"（semantic token），Stage 3 解决"怎么说的"——韵律、情绪、音色细节、频谱纹理、相位和听感。这是 v2 非对称依赖链的最后一级生成：**evidence -> semantic -> acoustic latent -> waveform**，每级被上一级和 evidence 双重锚定。

## 2. 生成链路

```text
LLM hidden + speaker embedding + 预测 prosody + gated evidence
  -> FM-DiT（按 audio-step 分组迭代去噪，约 4 帧 latent ≈ 160 ms）
  -> acoustic latent（约 25 Hz × 64 d 连续，厚 latent）
  -> latent decoder（Stage 0 训练并冻结）-> 24 kHz 增强波形
```

要点：

- **semantic token 不直接解码成音频**。token 作为自回归上下文塑造 LLM hidden state，**hidden state 才是 DiT 的接口**；latent decoder（RedAE 式）只吃 latent，无 token 接口。
- **为什么走连续 latent 不走 codec token**（v2 设计决策）：绕开 codec 量化上限——"codec 丢细节 Stage 3 补不回来"；离散阵营普遍要挂后置保真修复（enhancement VAE / 超分 / FM refiner），说明裸 codec 路径有隐性成本。离散路线（RVQ / FSQ 多 codebook + MTP + ConvNet decoder + 后置修复）以完整形态作对照，属 v2 实验矩阵 B.2，方案成型后再加。
- **厚 latent 冗余含内容属预期，不是 bug**：解耦的含义是 semantic 不受 acoustic 影响（可独立训练 / 诊断 / 消融），acoustic 条件依赖 semantic（内容经 LLM hidden 流入 DiT），不是表示级信息彻底分离。
- **latent decoder 默认冻结**，可小额解冻联调；它的重建上限在 Stage 0 已验收（系统音质天花板）。

## 3. 条件接线

| 条件 | 来源 | 注入方式 |
|---|---|---|
| LLM hidden state | Stage 2 LM（内容经此流入 DiT） | 主条件，逐帧对齐 |
| speaker embedding | 冻结 SV encoder 从 y_degraded 提取（与 Stage 0 speaker 通道同一模型） | prefix / [[方向/AI语音/知识/基础概念/FiLM（特征级线性调制）\|FiLM]] |
| prosody（预测） | LLM 顶层 hidden 挂 MLP prosody 头逐帧输出 | 预测 bin 查 embedding 后**与同帧 LLM hidden 相加**（已定；AdaLN / FiLM、独立 cross-attention 备选） |
| gated evidence | evidence encoder 低层 STFT/mel | 门控后给 DiT，禁止无门控直通 |

**prosody 通道**（本方案自有设计，先例在 TTS / VC 侧：[[方向/AI语音/模型/FastSpeech|FastSpeech 2]] variance adaptor、VC F0 条件；FireRedAudio 等 omni 模型没有）：

- 结构：两层 MLP，逐帧三路输出——F0（log-F0 约 256 bin 分类，CE）+ V/UV（BCE）+ energy（回归）。
- 真值：RMVPE / CREPE 从 x_clean 提取，池化到 25 Hz（与 latent 同帧率，逐帧 1:1 对齐）。
- 预测而非提取：推理期从 degraded 输入提 F0 不可靠（倍频程错误、清浊误判），所以让 LLM 从证据 + 先验重建 clean prosody；预测结果与 token 同出一门、天然一致。
- 降级方案：prosody 头质量不行时，退回抗噪 tracker（CREPE）从 degraded 直接提取当条件，训练时随机混合"clean 预测 / degraded 提取"两种来源做域适应。

## 4. 真值与防污染

- **latent 真值**：x_clean -> Stage 0 冻结的 latent encoder（encoder 只在训练期存在，推理时 latent 由 FM-DiT 生成）。
- **真值只从质量过滤子集提取**：与 target 侧同尺约束——DNSMOS / SIGMOS 打分过滤后的头部子集才出 acoustic latent / prosody 真值。低质 clean 的声学细节不进入监督。
- **prosody 真值最脆**：真值质量受提取器和录音质量双重限制。分解来看：F0 相对抗造（周期性检测耐噪 + bin 量化吸收小误差）；**energy 最脆**（噪底直接抬高帧能量，静音 / 弱音帧失真最严重，失败模式是输出停顿处能量地板抬高）；V/UV 居中。缓解按性价比：质量过滤 -> tracker 逐帧 confidence 掩码 prosody loss -> log-F0 / energy 逐句归一化 -> clean 与增广版本提取一致性自检。细节见 [[方向/AI语音/知识/技术路线/LLM-SE Stage 0（表示空间准备）]] 2.4。
- 最终兜底是 Stage 4 感知 reward——把输出从训练集平均音质推向更高质量区域。

## 5. Loss 组合

```text
flow loss（主）
+ multi-resolution STFT loss
+ adversarial + discriminator feature-matching
+ speaker consistency（SV cosine，与 Stage 0 speaker 通道同一模型）
+ ASR / content consistency
+ F0 RMSE / energy 相关
```

token CE 已在 Stage 2 训完，Stage 3 的主战场是 acoustic。SE 的底线是内容、说话人、时间结构、频谱和相位保真，不应只追求听感指标。**loss 分项监控，不看总和**（STFT / speaker / ASR / prosody / emotion 各指标独立跟踪）。

## 6. 训练策略

- **新模块冻结旧骨干**：训 DiT 时冻结 Stage 2 LLM 与 latent decoder，渐进解冻；latent decoder 可小额解冻联调。
- **任务范围**：退化类型（denoise / dereverb / BWE / declipping / packet loss）由 Stage 2 的条件与数据 mixture 覆盖，Stage 3 不按任务分模型、不用 task token——保真目标统一，任务差异靠数据配比与退化桶表达。
- 分模块学习率：

```text
FM-DiT（新参数）: task-dependent, usually higher
LLM LoRA / adapter: 5e-5 ~ 2e-4
LLM full finetune: 5e-6 ~ 2e-5（谨慎，全量微调容易把 Stage 1/2 学到的 clean prior 拉向单一退化分布）
latent decoder 解冻: 小额、短程联调
```

## 7. 验收标准

v2 指标分工：S3 看**联合指标**。

- waveform / spectrum / speaker / content 联合指标：[[方向/AI语音/评估/PESQ]] / [[方向/AI语音/评估/STOI 与 ESTOI]] / DNSMOS / [[方向/AI语音/评估/SI-SDR]]，[[方向/AI语音/评估/WER（词错误率）]] / [[方向/AI语音/评估/CER（Character Error Rate）]] / [[方向/AI语音/评估/CAcc]]，speaker cosine drift，F0 RMSE / energy 相关；互相不牺牲。
- **无 LLM 的 acoustic encoder-decoder baseline**：跑一个直接 encode-decode 的声学 baseline 确认声学头上限，隔离 LLM 条件的增益。
- **解耦三测试**（v2 实验矩阵 A.5）：swap（acoustic 路径跨句交换，内容应不动）、probe（semantic token 应预测不出 speaker / 情绪）、路径 ablation（去 acoustic 路径，内容指标应基本不掉）。
- 时间对齐 drift 低；内容指标不恶化，尤其数字、专名、弱语音区域。
- 流式场景额外看 latency、chunk boundary artifact、causal constraint。

## 8. 主要风险

- STFT / waveform loss 过强，压制 LLM semantic prior，模型退回普通 encoder-decoder SE。
- DiT / decoder 太强且不看 LLM hidden，LLM branch 变成无效装饰。
- low-level evidence 无门控直通，噪声和混响泄漏到输出。
- prosody 真值污染导致韵律地板效应（energy 通道最脆，见 §4）。
- latent decoder 上限锁死整体音质——Stage 0 红线不过不进本阶段。
- clean target 音质分布被声学 loss 学进去（防线：真值只从过滤子集提 + Stage 4 偏好对齐）。
- LLM 解冻过快，paired 声学 loss 冲掉 Stage 1/2 的 clean prior。

## 9. 相关对象

- [[方向/AI语音/知识/技术路线/LLM-SE Training Recipe（借鉴 NLP LLM 的语音增强训练配方）]]
- [[方向/AI语音/知识/技术路线/LLM-SE Training Recipe v2（显式解耦训练配方）]]
- [[方向/AI语音/知识/技术路线/LLM-SE Stage 0（表示空间准备）]]
- [[方向/AI语音/知识/技术路线/LLM-SE Stage 2（多退化条件重建）]]
- [[方向/AI语音/知识/技术路线/LLM-SE Stage 4（感知与偏好对齐）]]
- [[方向/AI语音/模型/FireRedAudio]]
- [[方向/AI语音/模型/FastSpeech]]
- [[方向/AI语音/知识/基础概念/Flow Matching（流匹配）]]
- [[方向/AI语音/知识/基础概念/FiLM（特征级线性调制）]]
- [[方向/AI语音/知识/基础概念/Vocoder（声码器）]]
- [[方向/AI语音/评估/语音增强评估指标体系]]
- [[方向/AI语音/评估/PESQ]]
- [[方向/AI语音/评估/STOI 与 ESTOI]]
- [[方向/AI语音/评估/SI-SDR]]
- [[方向/AI语音/评估/CAcc]]

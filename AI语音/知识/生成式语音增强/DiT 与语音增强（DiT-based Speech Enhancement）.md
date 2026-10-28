---
title: DiT 与语音增强（DiT-based Speech Enhancement）
发表时间: 2025-04-13
时间依据: DiTSE arXiv 首次提交日（语音增强 DiT 代表工作）
相关任务:
  - 语音增强
相关模型:
  - "[[方向/AI语音/模型/DiT-Flow]]"
  - "[[方向/AI语音/模型/SenSE]]"
相关评估:
  - "[[方向/AI语音/评估/NFE（函数评估次数）]]"
  - "[[方向/AI语音/评估/OVRL_MOS]]"
aliases:
  - DiT-based Speech Enhancement（DiT 与语音增强）
  - DiT 与语音增强
  - DiT-based Speech Enhancement
  - DiT
tags:
  - 类型/对象
  - 方向/AI语音
  - 任务/语音增强
---

# DiT 与语音增强（DiT-based Speech Enhancement）

**[[方向/大模型/模型结构/DiT（Diffusion Transformer）|DiT（Diffusion Transformer）]]** 指用纯 Transformer 替代 U-Net 作为扩散/流模型骨干的架构范式（源自图像生成，Peebles & Xie 的 DiT 论文）。2025 年起它被系统地引入语音增强：把带噪语音当作"退化图像"，在潜空间（latent）或频谱空间用 Transformer 骨干学习干净语音的生成过程。它与 [[UniSE（Unified Speech Enhancement）|UniSE]] 的 codec LM 路线并列为生成式语音增强的两大前沿路线。

## 1. 为什么用 DiT 替代 U-Net

- **长程依赖：** 语音的谐波结构、混响尾巴、长句韵律都是长程模式，Transformer 的全局注意力比 U-Net 的局部卷积更适配。
- **可扩展性：** DiT 继承 LLM 式 scaling 特性，数据和参数增大时质量稳定提升；DiTSE 的 Base (335M) 明显优于 Tiny (112M) 验证了这一趋势。
- **条件注入灵活：** SSL 特征（WavLM 等）、文本、任务 embedding 都可以通过 cross-attention 自然注入，统一多任务、多条件。
- **代价：** 推理延迟高、训练贵（DiTSE 用 8×A100 训 400k 步），这正是 [[方向/AI语音/知识/基础概念/Flow Matching（流匹配）|Flow Matching]] 变体要解决的问题。

通用视觉 DiT 的更深启发见 [[方向/大模型/模型结构/DiT（Diffusion Transformer）]]：成功点不是“Transformer 魔法”，而是先把连续图像/视频变成 latent patch tokens，再用可扩展 Transformer 和训练 recipe 建模。映射到语音增强，codec / VAE latent、STFT/mel latent、SSL condition 和 vocoder/decoder 的质量会先决定上限。

## 2. 代表工作

| 工作               | 年份   | 骨干与空间                                    | 生成范式                    | 亮点                                                                     |
| ---------------- | ---- | ---------------------------------------- | ----------------------- | ---------------------------------------------------------------------- |
| **DiTSE**        | 2025 | DiT，[[方向/AI语音/模型/DAC（Descript Audio Codec）]] codec VAE 潜空间（48 kHz、64 维、40 Hz） | Latent Diffusion，32 步采样 | 首个达到与录音室干净音频不可区分（QMOS 4.34）的增强方法；WavLM 特征 cross-attention 条件           |
| **FlowSE**       | 2025 | 潜空间 DiT + mel 编码 + vocoder               | Flow Matching           | 10–20 步 ODE 采样，延迟比扩散降一个量级；可选文本条件；有开源代码                                 |
| **[[方向/AI语音/模型/DiT-Flow]]** | 2026 | 潜空间 uDiT（TF-GridNet VAE） | Flow Matching（CFM，50 步 ODE） | 复合失真（混响+噪声+codec）鲁棒；首个 LoRA+MoE 失真适配（4.9% 参数）；RTF 0.230 不到扩散基线一半；JHU Dehak 组，详见 [[方向/AI语音/模型/DiT-Flow]] 模型笔记 |
| **SpeechOp**     | 2025 | DiT + 专用音频编码器                            | 扩散                      | 单一 DiT 做多任务 speech-to-speech（增强、分离），靠可学习任务 embedding 切换                |
| **VoiceRestore** | 2025 | Transformer                              | 条件 Flow Matching        | 自监督、语言无关的统一修复（失真、混响）；显著提升下游 Whisper V3 的 ASR                           |
| **Stream.FM**    | 2025 | 帧因果流模型                                   | Flow Matching（流式）       | 32 ms 算法延迟，把增强/去混响/带宽扩展/相位恢复统一进实时流式生成                                  |

## 3. 技术要点拆解

### 3.1. 生成范式：扩散 → [[方向/AI语音/知识/基础概念/Flow Matching（流匹配）|Flow Matching]]

- **扩散（DiTSE）：** 随机 SDE 采样，步数多（32 步）、质量上限高，适合离线高保真修复。
- **[[方向/AI语音/知识/基础概念/Flow Matching（流匹配）|Flow Matching]]（FlowSE、DiT-Flow、Stream.FM）：** 学习带噪到干净的确定性 ODE 速度场，[[方向/AI语音/评估/NFE（函数评估次数）|NFE / 采样步数]] 降到 5–20 甚至单次前向，是走向实时的关键。这也是 [[方向/AI语音/模型/SenSE|SenSE]] 采用的范式。
- **推理 scheduler：** 测试时 `t` 由 scheduler / ODE solver 给出一串噪声水平，不是直接输入 `t=0`。语音增强通常从退化语音 latent 或中低噪声起点开始；起点太高会更像重新生成，增加改词、改说话人和改音色风险，起点太低又可能修不动噪声、混响和 codec 伪影。

### 3.2. 潜空间选择

- **Codec VAE 潜空间（DiTSE）：** 用 [[方向/AI语音/模型/DAC（Descript Audio Codec）]] 等神经 codec 的编码器压缩到 40 Hz 帧率，保真度高、码率低，与 codec LM 路线共享表示。
- **Mel 频谱 + vocoder（FlowSE）：** 更传统、工程成熟，但相位由 vocoder 重建，上限受 vocoder 制约。

### 3.3. 条件注入

- **SSL 特征（WavLM）经 cross-attention：** 同时提供声学与语义信息，鲁棒性强——即使输入严重退化，条件特征仍能引导生成"合理"的语音（与 UniSE 用 WavLM 做条件提取是同一思路）。
- **可学习任务 embedding（SpeechOp）/ LoRA+MoE（DiT-Flow）：** 解决一个模型适配多种失真、多个任务的问题。

### 3.4. 失真覆盖与混响

DiT 类方法的训练数据普遍包含 [[Reverberation Modeling（混响建模）|混响]]（RIR 卷积合成）+ 噪声 + codec 压缩伪影的混合退化；DiT-Flow 还专门构建了带真实房间几何、材质和遮挡的 StillSonicSet 合成集。去混响在这里不再单独建模，而是被"生成式恢复"统一吸收。

## 4. 与其他路线的关系

- **vs codec LM（UniSE）：** DiT/扩散路线在连续潜空间做生成，音质上限更高；codec LM 路线离散 token 化，天然适配 LLM 生态和多任务 prompt 切换。两者都用 WavLM 做条件/表示，正在互相靠拢。
- **vs 传统判别式（DeepFilterNet、频谱掩码）：** 判别式低延迟、无幻觉风险；DiT 类生成式在强退化下音质显著更好，但有"生成不存在的内容"的幻觉风险，实时性靠 flow matching + 因果化才刚达标（Stream.FM 32 ms）。
- **评估：** 主观 QMOS / [[方向/AI语音/评估/OVRL_MOS|OVRL_MOS]] 成为生成式方法的主指标，传统 PESQ/STOI 对生成式输出普遍失真（生成内容合理但与参考不完全一致时被打低分）。

## 5. 关键来源

- [DiTSE: High-Fidelity Generative Speech Enhancement via Latent Diffusion Transformers](https://arxiv.org/abs/2504.09381)
  - 潜空间 DiT 增强旗舰工作，QMOS 4.34 达录音室级。核验日期：2026-07-28
- [FlowSE: Efficient and High-Quality Speech Enhancement via Flow Matching](https://arxiv.org/abs/2505.19476)（Interspeech 2025，[代码](https://github.com/Honee-W/FlowSE)）
  - Flow matching + 潜空间 DiT，低步数采样，开源。核验日期：2026-07-28
- [DiT-Flow: Speech Enhancement Robust to Multiple Distortions via Flow Matching in Latent Space and Diffusion Transformers](https://arxiv.org/abs/2603.21608)
  - 多失真鲁棒 + LoRA/MoE 高效适配；详见 [[方向/AI语音/模型/DiT-Flow|DiT-Flow 模型笔记]]。核验日期：2026-07-28
- [VoiceRestore: Flow-Matching Transformers for Speech Recording Quality Restoration](https://arxiv.org/abs/2501.00794)
  - 自监督统一修复，验证对下游 ASR 的收益。核验日期：2026-07-28
- [Real-Time Streamable Generative Speech Restoration with Flow Matching (Stream.FM)](https://arxiv.org/abs/2512.19442)
  - 32 ms 延迟流式生成式修复，实时化标杆。核验日期：2026-07-28
- [Towards Real-Time Generative Speech Restoration with Flow-Matching](https://arxiv.org/html/2510.16997v1)
  - 20 ms 延迟、5 步采样的因果 FM 架构。核验日期：2026-07-28

## 6. 关联

- 方向：[[方向/AI语音增强/README|AI 语音增强]]
- 相邻笔记：[[方向/大模型/模型结构/DiT（Diffusion Transformer）|DiT]]（通用架构定义）、[[方向/AI语音/知识/技术路线/语音网络结构与模块|语音网络结构与模块]]（语音模型骨干和模块地图）、[[方向/AI语音/知识/基础概念/Flow Matching（流匹配）|Flow Matching]]（生成范式基础）、[[方向/AI语音/评估/NFE（函数评估次数）|NFE]]（生成式采样效率）、[[UniSE（Unified Speech Enhancement）]]（codec LM 对照路线）、[[方向/AI语音/模型/SenSE|SenSE]]（semantic-guided flow matching）、[[Reverberation Modeling（混响建模）]]（失真建模基础）
- 待深挖：DiT 类生成式增强的幻觉率如何量化；Stream.FM 类流式方案与 DeepFilterNet 在真实通话链路的延迟-质量 Pareto 对比；FlowSE 开源代码能否作为方向工程基线。

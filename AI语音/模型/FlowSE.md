---
title: FlowSE
类型: 模型
发表时间: 2025-05
时间依据: arXiv 首次提交日
任务:
  - 语音增强
开放状态:
  - paper
  - code
aliases:
  - FlowSE
  - flowse
  - "FlowSE: Efficient and High-Quality Speech Enhancement via Flow Matching"
  - Flow Matching-based Speech Enhancement
tags:
  - 类型/对象
  - 方向/AI语音
  - 任务/语音增强
  - 主题/生成式增强
  - 主题/流匹配
---

# FlowSE

## 0. 背景

**问题现场**：生成式语音增强质量高，但扩散方法采样步数多、推理慢（RTF > 3.0），难以走向低延迟应用。

**前序路线的缺口**：扩散基生成式增强 RTF 超过 3.0，比实时慢一个数量级以上。

**FlowSE 的切入点**：用 flow matching 学带噪 → 干净的确定性速度场，ODE 积分仅需 10–20 步即完成增强（RTF 0.31），并支持可选文本条件。

## 1. 身份

`FlowSE`（Efficient and High-Quality Speech Enhancement via Flow Matching）是 Interspeech 2025 的生成式增强模型（arXiv:2505.19476，韩国 IITP 资助，作者 Lee & Cheong）：用 [[方向/AI语音/知识/基础概念/Flow Matching（流匹配）|flow matching]] 学**带噪 → 干净的确定性速度场**，ODE 积分 10–20 步完成增强——把扩散方法的采样步数降一个量级，RTF 0.31 vs 扩散 >3.0。

边界：mel 域三阶段管线（相位由 vocoder 重建，音质上限受 vocoder 制约）；按 [[方向/AI语音/知识/生成式语音增强/SE Generative Prior（语音增强生成先验）|SE 生成先验]] 分类属 **A 类**（干净语音先验）——论文 Eq.(1) 虽写 $z_0 = y$，但 3.3.2 节与图 1 明确推理输入是高斯噪声 $M_0$ + 受损 mel 作条件；对比同路线：[[方向/AI语音/模型/DiT-Flow|DiT-Flow]]（换更强压缩器）、Stream.FM（流式）、MeanFlowSE / [[方向/AI语音/模型/MeCo|MeCo]]（一步化）。

## 2. 核心机制

```text
noisy waveform
  -> mel 编码器（STFT + mel filterbank，非神经编码器）
  -> 潜空间 DiT 流模型：预测 v_θ(z_t, t)（可选文本条件拼接）
  -> ODE 积分 10–20 步 -> 增强 mel
  -> vocoder -> enhanced waveform
```

- **速度场 ODE**：$\frac{dz_t}{dt} = v_\theta(z_t, t)$，$z_0$ = 带噪 $y$、$z_1$ = 干净 $x$；推理 $z_{t+\Delta t} = z_t + v_\theta(z_t,t)\Delta t$。
- **潜空间 DiT**：基于 latent Diffusion Transformer 的流模型，捕捉长程依赖。
- **训练**：输入带噪 mel $M_y$ + 插值 mel $M_t$（干净与高斯噪声的混合）+ 可选转录 $C$，重建干净 mel $M_x$。
- **可选文本条件**：transcript 经文本编码器与音频嵌入拼接——文本条件变体说话人相似度更高。

## 3. 结果口径

- **效率**：RTF **0.31**——比扩散方法（RTF > 3.0）快一个数量级以上。
- **质量**：DNSMOS 最高 **3.643**（Real Recordings）；文本条件时说话人相似度 **0.940**（无文本变体也具竞争力）。
- **可懂度**：WER ~8.8%（文本 8.79 / 无文本 8.81）。
- 两变体在全部测试条件下对扩散基线一致、显著改善；说话人特征保持好。
- 谱系定位：先于 E2-TTS（TTS）、FlowAVSE（音视频）、FlowSep（分离）等 FM 应用，是**音频纯 FM 增强的开创**。

## 4. 使用判断

- 适合：生成式增强的低延迟路线（10–20 步）、mel + vocoder 工程成熟管线、需要文本/语义条件注入的场景。
- 不适合：极低延迟实时端侧（仍有 10–20 步——流式见 Stream.FM）；相位敏感场景（vocoder 上限）。
- 风险：mel 域表示限制细节恢复；幻觉风险与低 SNR 行为需对照评测（见 [[方向/AI语音/模型/FlowSE-GRPO|FlowSE-GRPO]] 的 RL 后训练研究）。

## 5. 关键来源

- [FlowSE: Efficient and High-Quality Speech Enhancement via Flow Matching（arXiv:2505.19476）](https://arxiv.org/abs/2505.19476)
  - 内容定位：原始论文，Interspeech 2025。
  - 用途：速度场公式、三阶段架构与全部实验数据。
  - 核验日期：2026-08-10
- [论文 HTML 版（ar5iv）](https://ar5iv.labs.arxiv.org/html/2505.19476v1)
  - 内容定位：同论文可读 HTML 版本。
  - 用途：3.3.2 节推理输入口径（A 类归属依据）与细节。
  - 核验日期：2026-08-10
- [官方代码（GitHub: seongq/flowmse）](https://github.com/seongq/flowmse)
  - 内容定位：论文标注的开源代码仓库（含 FlowSE-GRPO / MeCo 生态复用）。
  - 用途：复现与工程基线。
  - 核验日期：2026-08-10

## 6. 相关对象

- [[方向/AI语音/模型/FlowSE-GRPO|FlowSE-GRPO]]：在线 GRPO 后训练后继（RL 配方迁移案例）。
- [[方向/AI语音/模型/DiT-Flow|DiT-Flow]]、[[方向/AI语音/模型/MeCo|MeCo]]：FM 系同路线（更强压缩器 / 一步校正）。
- [[方向/AI语音/模型/SenSE|SenSE]]：A 类先验的语义条件对照。
- [[方向/AI语音/模型/SGMSE+|SGMSE+]]：扩散对照（RTF 对比的数据出处）。
- [[方向/AI语音/知识/生成式语音增强/DiT 与语音增强（DiT-based Speech Enhancement）|DiT 与语音增强]]：路线笔记（DiTSE、FlowSE、DiT-Flow、Stream.FM）。
- [[方向/AI语音/知识/基础概念/Flow Matching（流匹配）|Flow Matching]]、[[方向/AI语音/知识/基础概念/Vocoder（声码器）|Vocoder]]：基础组件。

## 7. 待验证

- 代码仓库归属核对：论文页标注 `seongq/flowmse`，DiT 与语音增强笔记引 `github.com/Honee-W/FlowSE`——两者关系待核。
- arXiv:2508.06840（同名 "FlowSE: Flow Matching-based Speech Enhancement"，同仓库）与 2505.19476 的版本关系。
- 低 SNR 下的幻觉率与说话人一致性（对照 URGENT 类多失真基准）。

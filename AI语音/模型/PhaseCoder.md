---
title: PhaseCoder
类型: 模型
发表时间: 2026-01
时间依据: arXiv 首次提交日
任务:
  - 空间音频理解
  - 声源定位
  - 多模态对话
开放状态:
  - paper
aliases:
  - PhaseCoder
  - "PhaseCoder: Microphone Geometry-Agnostic Spatial Audio Understanding for Multimodal LLMs"
  - Spatial Audio Tokens
  - 空间音频 token（PhaseCoder）
tags:
  - 类型/对象
  - 方向/AI语音
  - 任务/空间音频理解
  - 任务/声源定位
  - 主题/空间音频
  - 主题/多模态大模型
---

# PhaseCoder

## 0. 背景

**问题现场**：多模态 LLM 需要空间音频理解与定向转写能力（如"左边的人说了什么？"），但现有输入表示不支持空间信息。

**前序路线的缺口**：现有多模态 LLM 只吃单声道、丢弃空间信息；现有空间音频模型绑定固定麦克风几何。

**PhaseCoder 的切入点**：transformer-only、麦克风几何无关——输入原始多通道音频 + 任意麦克风坐标，输出空间音频 token，前置拼接进多模态 LLM。

## 1. 身份

`PhaseCoder`（Microphone Geometry-Agnostic Spatial Audio Understanding for Multimodal LLMs）是 2026-01 的空间音频编码器（Dementyev、Zulfikar、Hersek、Getreuer、Kumar、Kumar，arXiv:2601.21124）：**transformer-only、麦克风几何无关**——输入原始多通道音频 + 任意麦克风坐标，输出"空间音频 token"，让多模态 LLM 具备空间推理与定向转写能力（如"左边的人说了什么？"）。

边界：解决两个缺口——现有多模态 LLM 只吃单声道（丢弃空间信息）、现有空间音频模型绑定固定麦克风几何。它**不是**波束形成 / 增强模型（不输出增强音频，输出的是空间表示）；假设自由悬浮[[方向/AI语音/知识/基础概念/Omni Mic（全向麦克风）|全向麦克风]]（无设备衍射建模）、窗口内静态声源、单一主导说话人。

## 2. 核心机制

```text
raw multichannel + arbitrary mic coordinates
  -> 每通道 STFT（16 kHz，256 窗 / 50% 重叠）
  -> 幅度 + 相位拼接（258 维 -> 投影 D=256）
  -> patch = 单麦单时帧；33 帧（250 ms）/ 麦 = 1 个空间音频 token
  -> 位置编码：序列（1D 正弦）+ 帧级 + 麦克风坐标球面编码（三角融合）
  -> ViT 编码器（5 个 transformer 块，4 头自注意力）+ [CLS]
  -> 方位 / 俯仰 / 距离分类头（或投影进 LLM token 序列）
```

- **幅度 + 相位特征**：显式利用相位信息（对比多数只吃幅度谱的增强 / 编码器）。
- **麦克风坐标球面编码**：任意阵列拓扑（7–18 cm 球内随机放置 3–8 麦）——几何无关的核心。
- **训练**：纯合成——LibriSpeech × 150 万模拟 RIR，两阶段（先干净语音、后加干扰/噪声）。
- **LLM 集成**：空间嵌入投影后**前置拼接**到微调 Gemma 3n 的 token 序列（LoRA + 课程学习，四任务：源定位 / 空间推理 / 空间转写 / 定向转写）——首次让 LLM 在任意阵列上做空间推理与定向转写。

## 3. 结果口径

- **LOCATA（8 麦）**：方位 MAE 7.44°、Acc@10° 86.96%——超此前 SOTA GI-DOAEnet（82.48%）。
- **RSL2019**：MAE 4.33°、Acc@10° 95.5%（略低于 GI-DOAEnet——归因于多任务 10° 分辨率设计）。
- **LLM 推理**：方位判断问答相对提升最高 +28%；空间推理任务 76.8%（基线 ~50%）。
- **定向转写**：WER 从 ~30% 降到 ~10%（相对降 >15 个百分点）。
- **局限**：距离估计不如角度定位准；自由场假设。

## 4. 使用判断

- 适合：多模态 LLM 的空间音频输入（机器人 / 具身 AI / 会议空间感知）；任意阵列几何的空间理解研究。
- 不适合：增强 / 分离任务（输出是空间表示不是音频）；需要设备级衍射建模的精确定位；多源同时说话场景。
- 风险：纯合成训练（真实阵列失配待验证）；单主导声源假设。

## 5. 关键来源

- [PhaseCoder: Microphone Geometry-Agnostic Spatial Audio Understanding for Multimodal LLMs（arXiv:2601.21124）](https://arxiv.org/abs/2601.21124)
  - 内容定位：原始论文。
  - 用途：特征与位置编码设计、训练配方与全部实验数据。
  - 核验日期：2026-08-10

## 6. 相关对象

- [[方向/AI语音/知识/基础概念/DOA（到达方向）|DOA]]：方位 / 俯仰分类头的任务本体。
- [[方向/AI语音/知识/基础概念/IPD（通道间相位差）|IPD]]：相位特征的频域基础（幅度 + 相位拼接）。
- [[方向/AI语音/知识/基础概念/Array Audio Signal（阵列音频信号）|Array Audio Signal]]：多通道输入与空间信息。
- [[方向/AI语音/知识/基础概念/Array vs Multi-Channel（阵列与多通道）|Array vs Multi-Channel]]：几何无关 vs 几何已知的辨析（PhaseCoder 属几何无关）。
- [[方向/AI语音/知识/基础概念/MIMO（多输入多输出）|MIMO]]：多通道输入处理的维度语境。
- [[方向/AI语音/模型/AudioLM|AudioLM]] / [[方向/AI语音/模型/GLM-4-Voice|GLM-4-Voice]]：音频 token 化进入 LLM 的相邻范式（PhaseCoder 是空间版）。

## 7. 待验证

- 官方代码 / 权重是否开放。
- 真实设备（眼镜 / 耳机 / 会议阵列）衍射与多源场景下的退化。
- 与增强前端（保向增强输出空间线索）的衔接——增强后的多通道能否直接喂 PhaseCoder。

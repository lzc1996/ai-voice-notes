---
title: SpkSim
类型: 概念
发表时间:
时间依据: 说话人相似度指标口径依赖嵌入模型；非单一发表物
aliases:
  - Speaker Similarity
  - 说话人相似度
  - Speaker Embedding Cosine Similarity
tags:
  - 类型/对象
  - 方向/AI语音
  - 任务/语音增强
  - 指标/说话人保持
---

# SpkSim

## 0. 背景

**问题现场**：增强/修复可能把声音修得更好听但不像本人（音色失真），听感指标无法捕捉；生成式增强尤其需要身份保持探针。

**切入点**：用说话人验证模型分别提取增强语音与干净参考的说话人嵌入，以余弦相似度度量身份保持。

## 1. 身份

`SpkSim`（Speaker Similarity）衡量增强后语音与干净参考之间**说话人身份的保持程度**：用说话人验证模型（ECAPA-TDNN、WavLM 系等）分别提取两者的说话人嵌入，计算余弦相似度。

- 范围通常 0–1，越高越好；>0.8 一般认为音色保持良好。

## 2. 用途

- 语音增强、语音修复的"音色失真"检测：降噪把声音修得再好，如果听起来不像本人就是失败。
- 生成式增强幻觉检测的重要维度——URGENT 2025 生成式冠军 SpkSim 仅 0.47（声音已经不太像原说话人），而 URGENT 2026 混合式冠军达 0.82。
- 与 [[CAcc]]（内容保持）并列，是"生成式是否胡说八道"的两大探针之一。

## 3. 计算口径

- 需要干净参考；嵌入模型选择（ECAPA-TDNN vs WavLM vs x-vector）会影响绝对分数，跨论文比较前需确认口径。
- 对短句（<2 s）不稳定，嵌入方差大。

设说话人嵌入模型为 $f_{spk}$：

$$
e_{ref}=f_{spk}(x_{ref}),\quad e_{test}=f_{spk}(x_{test})
$$

$$
\mathrm{SpkSim}=\cos(e_{ref},e_{test})=\frac{e_{ref}^{\top}e_{test}}{\lVert e_{ref}\rVert\lVert e_{test}\rVert}
$$

## 4. 使用注意

- 对变声、带宽变化敏感：窄带化的增强输出即使音色没变，嵌入也可能偏移。
- 音色保持好不代表内容正确，需与内容指标联合看。
- 见 [[语音增强评估指标体系]]。

## 5. 异常定位

当 CER / SpeechBERTScore 符合预期、但 SpkSim 明显偏低时，先排测试链路，再判断模型是否真的损伤说话人身份。

- **校准分布**：同时画 `clean-clean/same speaker`、`different speaker`、`noisy-clean`、`enhanced-clean` 四组 SpkSim 分布；如果 clean-clean 都不高，优先查评测链路或 speaker encoder 域不匹配。
- **identity pipeline 测试**：clean wav 不经过模型，只走 resample / save / load / VAD / metric pipeline，再和原 clean 算 SpkSim；若掉分明显，问题在测试链路。
- **配对检查**：核对 audio id、speaker id、文件排序、reference、采样率、声道、长度、VAD 裁剪、padding 和 loudness normalize。
- **noisy-clean 对照**：如果 noisy-clean 高而 enhanced-clean 低，说明增强模型可能损伤了 speaker cues；如果两者都低，优先怀疑数据、参考或 metric backend。
- **换 encoder 复测**：用 ECAPA-TDNN、WavLM、RawNet / x-vector 等 backend 复测；只有一个 backend 异常时，不直接定性为模型失败。

## 6. SPKSIM / VoxSim 模型选择

这里的 SPKSIM / VoxSim 是一个具体的 speaker similarity 评估实现，不等同于 SpkSim 这个指标概念。官方训练代码主要提供三类模型配置：

- **ECAPA-TDNN**：基于 VoxSim raw scores 训练，现成权重为 ecapa_tdnn.model，约 62.8 MB；适合作为轻量 baseline。
- **WavLM-ECAPA**：WavLM backbone + ECAPA-TDNN，基于 VoxSim mean scores 训练；现成权重为 voxsim_wavlm_ecapa.model，约 1.3 GB，适合 TTS / voice conversion 的 speaker similarity 评估。
- **WavLM-ECAPA-SV**：先用 VoxCeleb 做 speaker verification 预训练，再用 VoxSim mean scores 微调；主要是训练配置，不一定对应单独发布的公开 checkpoint。

**默认选择**：推理和 TTS / VC 评估优先使用 WavLM-ECAPA；需要低存储、快速批量评估或可复现实验 baseline 时使用 ECAPA-TDNN。在线 Demo 默认主要使用 WavLM-ECAPA 强模型，不能把 Demo 分数与其他 speaker encoder 的分数直接混比。

## 7. 相关对象

- [[方向/AI语音增强/README|AI 语音增强]]
- [[方向/AI语音/知识/基础概念/Timbre（音色）]]：SpkSim 是音色 / 说话人保持的代理指标，不等于完整的 timbre perception。
- [[语音增强评估指标体系]]、[[SE SOTA（语音增强模型表现）]]
- [[CAcc]]

## 8. 关键资源

- [SpeechBrain 说话人嵌入工具](https://github.com/speechbrain/speechbrain)
  - 内容定位：ECAPA-TDNN 等嵌入模型的常用开源实现。核验日期：2026-07-28
- [VoxSim / SPKSIM 官方训练仓库](https://github.com/kaistmm/voxsim_trainer)
  - 内容定位：ECAPA-TDNN、WavLM-ECAPA、WavLM-ECAPA-SV 的训练配置与 Quick Prediction 入口。核验日期：2026-09-22
- [VoxSim 模型权重](https://huggingface.co/junseok520/voxsim-models)
  - 内容定位：公开的 ECAPA-TDNN 与 WavLM-ECAPA checkpoint。核验日期：2026-09-22

## 9. 待验证

- 不同嵌入模型给出的 SpkSim 排名一致性；中文短语音上的稳定性。
- WavLM-ECAPA checkpoint 的具体 WavLM 版本、输入采样率、VAD / pooling 配置和跨语言稳定性。

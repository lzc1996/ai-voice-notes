---
title: RawNet3
类型: 模型
发表时间: 2022
时间依据: Interspeech 2022 论文与官方实现
任务:
  - 说话人验证
  - 说话人嵌入
  - speaker similarity
  - SpkSim backend
相关主题:
  - speaker verification
  - speaker embedding
  - raw waveform modeling
  - VoxCeleb
输入约束:
  - 16 kHz
  - 16-bit
  - mono
开放状态:
  - paper
  - code
  - pretrained-weights
aliases:
  - RawNet 3
  - RawNet3 encoder
  - Raw waveform speaker recognition
tags:
  - 类型/对象
  - 方向/AI语音
  - 主题/说话人表示
  - 任务/说话人验证
  - 任务/说话人相似度
---

# RawNet3

## 0. 背景

**问题现场**：说话人验证需要从语音中提取 speaker embedding，判断两段语音是否来自同一说话人。

**RawNet3 的切入点**：走 raw waveform 路线，直接从音频波形学习 speaker embedding，不依赖传统 MFCC 或 log-Mel 特征作为唯一输入。

## 1. 身份

RawNet3 是面向说话人识别与验证的 raw waveform 模型。它直接从音频波形学习 speaker embedding，不依赖传统 MFCC 或 log-Mel 特征作为唯一输入，主要用于判断两段语音是否来自同一说话人。

它不是 ASR、TTS、声码器或语音增强模型；在当前笔记库中，最直接的用途是作为 [[方向/AI语音/评估/SpkSim]] 的备用 speaker encoder。

## 2. 核心链路

语音波形
-> raw waveform encoder
-> 时序特征聚合
-> speaker representation
-> embedding 相似度或 speaker verification score

RawNet3 的重点是让网络从波形中学习对说话人身份有用的声学模式。最终的 embedding 可以用于余弦相似度、验证分数或下游说话人分类，而不是直接生成文本。

## 3. 官方实现与权重

- **官方仓库**：Jungjee Kim 的 RawNet 仓库同时包含 RawNet、RawNet2 和 RawNet3 的实现与推理说明。
- **官方 Hugging Face 权重**：jungjee/RawNet3。
- **ESPnet 权重**：espnet/voxcelebs12_rawnet3，可直接通过 ESPnet 的 Speech2Embedding 接口提取 embedding。
- **输入约束**：官方推理说明按 16 kHz、16-bit、单声道音频处理；实际部署仍应核对 checkpoint 的预处理和裁剪策略。

ESPnet 的 RawNet3Encoder 文档显示，具体实现默认使用 1024 维中间表示和 1536 维输出配置；这属于该实现的接口配置，不应自动视为所有 RawNet3 checkpoint 的统一维度。

## 4. 评估用途

- **SpkSim 备用 backend**：当 ECAPA-TDNN 或 WavLM backend 对某类音频给出异常分数时，可用 RawNet3 复测。
- **说话人保持检查**：比较 clean reference 与 enhanced / generated speech 的 embedding 相似度，观察增强或生成过程是否发生 speaker drift。
- **VoxCeleb 验证**：官方与 ESPnet 示例围绕 VoxCeleb speaker verification 评测；ESPnet 发布说明给出 Vox1-O EER 约 0.73%，具体结果依赖 checkpoint、切分、VAD 和评分配置。

## 5. 与其他 speaker encoder 的关系

- [[方向/AI语音/评估/SpkSim]]：RawNet3 是计算 SpkSim 的一种 backend，不是 SpkSim 指标本身。
- **ECAPA-TDNN**：通常更容易部署、社区工具更多；RawNet3 直接处理波形，适合作为结构不同的交叉验证 backend。
- [[方向/AI语音/模型/WavLM]]：WavLM 是通用语音表示 encoder；RawNet3 更专门面向 speaker embedding / verification。
- **x-vector / RawNet2**：RawNet3 属于 raw waveform speaker recognition 路线的后续版本，不能把不同模型的绝对相似度分数直接混比。

## 6. 使用边界

- 不能用 RawNet3 的 embedding 直接替代 ASR 的 WER / CER。
- 不能把 RawNet3 的高分解释为完整音色、情绪、韵律或高频细节都保持不变；speaker embedding 只覆盖身份相关的一部分信息。
- 跨模型比较时必须固定采样率、声道、VAD、片段长度、归一化、pooling 和 reference 配对，否则分数变化可能来自评测链路。

## 7. 关键来源

- [Pushing the limits of raw waveform speaker recognition](https://www.isca-archive.org/interspeech_2022/jung22_interspeech.html)
  - 内容定位：RawNet3 原始论文与 Interspeech 2022 出版信息。
  - 核验日期：2026-09-22
- [Jungjee/RawNet 官方仓库](https://github.com/Jungjee/RawNet)
  - 内容定位：RawNet 系列实现、RawNet3 推理说明和输入约束。
  - 核验日期：2026-09-22
- [jungjee/RawNet3 Hugging Face 权重](https://huggingface.co/jungjee/RawNet3)
  - 内容定位：官方 RawNet3 checkpoint。
  - 核验日期：2026-09-22
- [ESPnet RawNet3 speaker embedding](https://huggingface.co/espnet/voxcelebs12_rawnet3)
  - 内容定位：可直接提取 speaker embedding 的 ESPnet 预训练模型。
  - 核验日期：2026-09-22
- [ESPnet RawNet3Encoder 文档](https://espnet.github.io/espnet/guide/espnet2/spk/RawNet3Encoder.html)
  - 内容定位：ESPnet 接口维度与 encoder 配置。
  - 核验日期：2026-09-22

## 8. 待验证

- [ ] 固定项目采用官方 RawNet3 还是 ESPnet RawNet3 checkpoint。
- [ ] 记录实际采样率、VAD、片段长度、embedding 维度和 pooling 方式。
- [ ] 在中文短语音、噪声语音和增强输出上，与 ECAPA-TDNN、WavLM-ECAPA 做同链路 SpkSim 交叉验证。

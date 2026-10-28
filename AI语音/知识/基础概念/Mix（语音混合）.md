---
title: Mix（语音混合）
类型: 概念
发表时间:
时间依据: 音频数据增强/SSL 预训练通用概念；非单一发表物
相关主题:
  - 音频处理
  - 数据增强
相关模型:
  - "[[方向/AI语音/模型/FlowSE-GRPO]]"
  - "[[方向/AI语音/模型/WavLM]]"
aliases:
  - 语音混合（Mix）
  - Mix
  - 语音混合
  - mix
tags:
  - 类型/对象
  - 方向/AI语音
  - 主题/音频处理
  - 主题/数据增强
---

# Mix（语音混合）

## 1. 身份

在 AI 语音里，`Mix / mixing` 通常指把两路或多路音频按一定比例相加，构造带噪、多人重叠或复合失真的训练样本。

最小形式：

```text
mixture = target speech + interference
```

其中 `interference` 可以是噪声、另一位说话人、音乐、回声、混响后的语音，或它们的组合。

边界：这里的 Mix 不是音乐制作里的后期混音，也不是 [[方向/AI语音/模型/FlowSE-GRPO|MixGRPO]]；它主要是训练数据构造或自监督预训练里的音频混合操作。

## 2. 常见用途

- **噪声鲁棒训练**：clean speech + noise，按目标 SNR 混合，得到 noisy-clean paired data。
- **语音分离**：speaker A + speaker B，构造 mixture，再要求模型输出各自说话人。
- **目标说话人提取**：mixture + enrollment clue，要求只输出目标说话人。
- **自监督预训练**：如 [[方向/AI语音/模型/WavLM|WavLM]] 的 denoising / utterance mixing，让 encoder 学会在噪声和重叠说话中恢复目标语音表示。
- **多失真增强**：Mix 可和 [[方向/AI语音/知识/基础概念/Reverberation Modeling（混响建模）|RIR 卷积]]、codec simulation、packet loss 叠加，模拟真实语音链路。

## 3. 关键参数

- **SNR / SIR**：目标语音与噪声或干扰说话人的能量比。
- **混合位置**：干扰从整段开始，还是随机插入局部片段。
- **电平归一**：混合前后是否按 RMS / LUFS / peak 做归一。
- **通道与空间**：单通道直接相加；多通道要考虑每个声源的 RIR / [[方向/AI语音/知识/基础概念/DOA（到达方向）|DOA]]。
- **标签关系**：增强任务保留 clean target；分离任务保留每个 source；SSL 任务常保留 clean pseudo-label。

## 4. 和相邻概念的区别

- **Mix vs 加噪**：加噪是 Mix 的特例，干扰源是非语音噪声。
- **Mix vs overlap speech**：overlap speech 是 Mix 的特例，干扰源是另一段语音。
- **Mix vs RIR 卷积**：RIR 是空间/混响变换，常由 [[方向/AI语音/知识/基础概念/ISM（Image Source Method，镜像声源法）]] 或实测 RIR 得到；Mix 是多路音频相加。真实远场训练常先给每个声源卷积 RIR，再 mix。
- **Mix vs mixup**：mixup 通常还混合标签；语音增强/分离里的 Mix 更常保留明确 target/source 标签。

## 5. 相关对象

- [[方向/AI语音/模型/WavLM]]：预训练目标中使用 denoising / utterance mixing。
- [[方向/AI语音/知识/基础概念/音频数据预处理]]：Mix 属于数据增强和训练样本构造环节。
- [[方向/AI语音/知识/基础概念/SS（语音分离）]]：以 mixture 为输入，输出多个说话人源。
- [[方向/AI语音/知识/基础概念/TSE（目标说话人提取）]]：以 mixture + 目标说话人线索为输入。
- [[方向/AI语音/知识/基础概念/DOA（到达方向）|DOA]]：多通道混合时的声源方向标签。
- [[方向/AI语音/数据集/WHAM]]：典型带噪多人混合语音分离数据集。

## 6. 待验证

- 当前语音增强小样本评测是否需要统一一套 SNR/SIR、RIR 和 codec 的 mix 配方。
- WavLM 式 utterance mixing 与普通加噪增强在中文远场、漏音和多人场景中的收益差异。

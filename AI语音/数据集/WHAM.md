---
title: WHAM
类型: 数据集
发表时间: 2019-09-15
时间依据: WHAM! 论文发表于 Interspeech 2019（2019-09-15 会议开幕）
aliases:
  - WHAM!
  - WHAM 噪声
  - WHAM 噪声数据集
  - WHAM dataset
tags:
  - 类型/对象
  - 方向/AI语音
  - 任务/语音分离
  - 任务/语音增强
  - 资源/数据集
---

# WHAM

## 1. 身份

`WHAM!` 是带噪语音分离基准，由 Wichern 等人（MERL，三菱电机实验室）在 Interspeech 2019 发布（《WHAM!: Extending Speech Separation to Noisy Environments》）。它在 **wsj0-2mix** 的 2-speaker 混合基础上，混入一批**真实录制的城市环境噪声**，构成带噪的 2-speaker 分离任务。

边界：日常说"WHAM 噪声"时，指的通常是 WHAM! 发布的**噪声轨本身**（常被单独拿去当数据增强的噪声源）；说"WHAM! 任务"时，指的是 wsj0-2mix + 噪声的分离基准。[[方向/AI语音/知识/调研与地图/SE SOTA（语音增强模型表现）|SE SOTA]] 里出现的 EARS-WHAM_v2 也是把 WHAM 噪声混到 EARS 干净语音上。

## 2. 数据构成

- **语音**：沿用 wsj0-2mix（WSJ0 干净语音的 2-speaker 混合），保持与 wsj0-2mix 相同的说话人相对电平。
- **噪声**：在波士顿地区的咖啡馆、餐厅、酒吧、公园等真实公共环境录制；使用**双耳麦克风**（binaural），也包含平板/移动设备录音以模拟 ASR 场景。噪声含 babble（人群模糊说话声）、杯盘碰撞、背景音乐等，与语音频谱重叠多，比一般稳态噪声难处理。
- **混合 SNR**：从 **−6 ~ +3 dB** 均匀采样（对较响的那个说话人与噪声的 SNR）。该范围是按"同环境下真实对话的语音-噪声相对电平"估计确定的。
- **版本**：8 kHz / 16 kHz，max / min 两种时长裁切；训练 20,000 条、验证 5,000 条、测试 3,000 条。

## 3. 衍生版本

- **WHAMR!**（Maciejewski et al., ICASSP 2020）：WHAM! 加混响版本，每个干净源先卷积合成 RIR（T60 0.2–1.0 s，说话人距阵列 0.66–2.0 m），再混噪。任务升级为联合去混响 + 去噪 + 分离，[[方向/AI语音/模型/TF-GridNet|TF-GridNet]]、SpatialNet 等多通道分离工作在此报告结果。
- **EARS-WHAM_v2**：EARS 干净语音 + WHAM 噪声，常用作语音增强的**域外泛化**测试集。

## 4. 用途

- 带噪 [[方向/AI语音/知识/基础概念/SS（语音分离）|SS（语音分离）]] 的标准基准（Conv-TasNet 之后的分离工作普遍报告 WHAM! / WHAMR! 结果）。
- 语音增强、ASR 训练中的**噪声增强源**：WHAM 噪声比 MUSAN 噪声更"生活化"、更非稳态，适合模拟真实远场/公共空间场景。

## 5. 使用注意

- WHAM 噪声里本身含 babble（他人说话声），用于增强训练时要注意它本质上是"竞争性说话人"干扰，与纯环境噪声（如 DEMAND 的街道、车站）性质不同。
- 对比论文结果时确认版本：8 kHz 还是 16 kHz、min 还是 max、单通道还是双耳，以及目标是第一个说话人还是两个都估计。
- WHAM 噪声商用许可需注意：官方数据通过 MERL 网站申请，研究用途为主。

## 6. 相关对象

- [[方向/AI语音/知识/基础概念/SS（语音分离）|SS（语音分离）]]：WHAM! 定义的核心任务。
- [[方向/AI语音/数据集/WSJ0（华尔街日报语料库）|WSJ0]]：wsj0-2mix 的语音底料来源。
- [[方向/AI语音/数据集/VoiceBank-DEMAND|VoiceBank-DEMAND]]：语音增强经典基准，噪声性质可对照（DEMAND 为稳态环境噪声，WHAM 含 babble）。
- [[方向/AI语音/知识/调研与地图/SE SOTA（语音增强模型表现）|SE SOTA]]：记录 EARS-WHAM_v2 域外泛化基准上的表现。

## 7. 关键来源

- [WHAM!: Extending Speech Separation to Noisy Environments (Wichern et al., Interspeech 2019)](https://www.jonathanleroux.org/pdf/Wichern2019Interspeech09.pdf)
  - 内容定位：WHAM! 原始论文，定义噪声采集、SNR 混合流程和基准。
  - 用途：确认 SNR 范围（−6~+3 dB）、双耳录音方式、wsj0-2mix 对应关系。
  - 核验日期：2026-08-03
- [WHAM! official page (MERL)](http://wham.whisper.ai/)
  - 内容定位：官方数据下载和生成脚本入口。
  - 用途：获取噪声轨和混合脚本。
  - 核验日期：2026-08-03
- [WHAMR!: Noisy and Reverberant Single-Channel Speech Separation (Maciejewski et al., ICASSP 2020)](https://arxiv.org/abs/1910.10279)
  - 内容定位：WHAMR! 加混响版本的原始论文。
  - 用途：确认混响参数范围和数据规模。
  - 核验日期：2026-08-03

## 8. 待验证

- WHAM 噪声的商用许可具体条款（官方下载页许可文本）。
- WHAMR! 的 ICASSP 2020 正式发表页码与引用格式。

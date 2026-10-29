---
title: "Full-Band（全频带）"
类型: 概念
发表时间:
时间依据: 基础口径概念；非单篇模型、论文或产品发布
aliases:
  - 全频带
  - Full-Band
  - Full-Bandwidth
  - fullband
  - FB
  - Full-Band Speech
  - 全带
  - 全频带语音
tags:
  - 类型/对象
  - 方向/AI语音
  - 主题/信号处理
  - 主题/Codec
---

# Full-Band（全频带）

## 0. 背景

**该对象出现前的问题与替代方案**：数字语音通信四五十年被困在**窄带**（narrowband，300–3400 Hz）里——ITU-T G.711（1972）按老式模拟电话的传输口径定下 8 kHz 采样，"电话嗓音"的闷、薄、失真感正是 3400 Hz 以上高频被切掉的结果。1988 年 G.722 首次给出**宽带**（wideband，50–7000 Hz，"HD voice"）档位，2001 年后 AMR-WB（G.722.2）把宽带推进移动网络；但更宽的**超宽带/全频带**长期没有统一标准，各家自行其是。

**出现后的谱系**：2012 年 IETF Opus（RFC 6716）与 2014 年 3GPP EVS（TS 26.441）把**超宽带**（SWB，50–14000 Hz）与**全频带**（fullband，20–20000 Hz）一并标准化，VoLTE 与 WebRTC/OTT 通话随之具备全频带能力。语音处理界更晚跟进——学术 SE 主流停在 16 kHz（见 [[方向/AI语音/知识/基础概念/Sample Rate（采样率）|Sample Rate]]），直到近年全频带才成为实时前端与通用增强评测的正式口径：WebRTC AEC 全频带实时化、DeepFilterGAN 等 48 kHz 实时系统、URGENT 把**带宽限制**正式列为一类失真并要求跨 8–48 kHz 评测。

## 1. 身份

`Full-Band`（全频带，缩写 FB）是 ITU-T 口径下语音/音频带宽分档的最高一档：**20 Hz–20 kHz**，覆盖人耳可闻频段，工程上通常以 48 kHz 采样率承载。它描述的不是采样率本身，而是**系统实际处理/传输的有效带宽口径**——"全频带系统"意味着从拾音、处理到回放不再有人为设计的带宽截断。

ITU-T Q10/16 官方分档：

| 档位 | 有效带宽 | 采样率 | 代表 codec / 场景 |
|---|---|---|---|
| NB（窄带） | 300–3400 Hz | 8 kHz | G.711、G.729；传统 PSTN |
| WB（宽带） | 50–7000 Hz | 16 kHz | G.722（1988）、AMR-WB/G.722.2；HD voice |
| SWB（超宽带） | 50–14000 Hz | 32 kHz | EVS、Opus 的 SWB 模式 |
| **FB（全频带）** | **20–20000 Hz** | **48 kHz** | **EVS、Opus、WebRTC/OTT；现代实时前端** |

与 [[方向/AI语音/知识/基础概念/Sample Rate（采样率）|Sample Rate]] 的分工：采样率是**承载条件**（上限 = 采样率/2），带宽是**信息口径**（实际有效频段）。48 kHz 采样的信号若只含 4 kHz 有效带宽，仍是窄带内容——全频带身份同时要求两者。

## 2. 为什么语音处理近年才上全频带

- **长期停在 16 kHz 的原因**：语音信息集中在低频、算力/显存/序列长度按采样率线性涨、WavLM/HuBERT 等底座全是 16 kHz 预训练——三条理由互相锁死（详见 Sample Rate 页 §3）。
- **推动力**：① 消费硬件（TWS 耳机、智能音箱、助听器）与音乐/生成类任务要求 48 kHz；② VoLTE/OTT 通话链路（EVS/Opus）已全频带化，前端 16 kHz 处理反而成为瓶颈；③ URGENT 把带宽限制当作一类**可评测失真**，跨 8–48 kHz 的泛化能力成为正式指标轴（URGENT 2026 扩到 7 类失真 × 5 语言 × 8–48 kHz），把"全频带 SE"从工程选型变成 benchmark 问题。
- **当前形态**：实时前端线（WebRTC AEC3 全频带实时化、DeepFilterGAN 48 kHz / 40 ms 延迟 / 3.45M 参数）与通用增强线（URGENT 的跨带宽轴）并行推进。

## 3. 常见误读

- **48 kHz 采样 ≠ 全频带**：采样只是承载条件，有效带宽可能仍是 8/16 kHz；判断口径看频谱内容，不看文件属性。
- **FB ≠ Hi-Res**：FB 定义到 20 kHz 为止；>20 kHz 属 Hi-Res Audio 语义，语音口径一般不涉及。
- **宽带 ≠ 全频带**：7 kHz 以上的高频信息（摩擦音质感、sibilance、空气感）在 WB 口径下同样缺失，"HD voice"仍是带限语音。
- **带宽扩展（BWE）不是重采样**：8 kHz 升 48 kHz 的重采样不会凭空补高频；BWE 是生成式补全任务（UniSE 训练中模拟 2/4 kHz 带限让模型学会补高频），产物是**想象的高频**，不是恢复的高频。
- **16k 模型直推 48k ≠ 只加算力**：频谱结构、噪声/混响的频率分布、STFT 参数、相位敏感度都随带宽变化——URGENT 上跨带宽泛化正是判别式与生成式系统拉开差距的轴之一。

## 4. 关键来源

- [ITU-T SG16 Q10/16（官方任务页）](https://itu.int/en/ITU-T/studygroups/2013-2016/16/Pages/q10.aspx)
  - 内容定位：NB 300–3400 / WB 50–7000 / SWB 50–14000 / FB 20–20000 的官方分档原文。
  - 用途：四档定义的权威口径。
  - 核验日期：2026-10-28
- [G.711 vs G.722 vs AMR vs EVS（Fora Soft, 2026-10 更新）](https://www.forasoft.com/learn/audio-for-video/articles-audio/speech-codecs-g711-g722-amr-evs)
  - 内容定位：四代语音 codec 的带宽/采样率/比特率对照，含 IVAS（3GPP R18, 2024-06 批准）现状。
  - 用途：谱系与年份旁证（二手整理，标准号可回溯）。
  - 核验日期：2026-10-28
- [Simulating Conversations for the Prediction of Speech Quality（博士论文，d-nb.info）](https://d-nb.info/1274184487/34)
  - 内容定位：NB/WB/SWB/FB 与 PSTN/移动/OTT 三类网络、G.711/G.722/AMR-WB/EVS/Opus 的系统叙述。
  - 用途：EVS（3GPP 26.441, 2014）与 Opus（RFC 6716, 2012）SWB/FB 支持的学术旁证。
  - 核验日期：2026-10-28

## 5. 相关对象

- [[方向/AI语音/知识/基础概念/Sample Rate（采样率）|Sample Rate（采样率）]]：承载条件 vs 信息口径的分工，16 kHz 生态锁死的原因。
- [[方向/AI语音/评估/URGENT（通用语音增强挑战）|URGENT（通用语音增强挑战）]]：把带宽限制列为正式失真轴、要求 8–48 kHz 跨带宽评测的 benchmark。
- [[方向/AI语音/知识/基础概念/AEC（声学回声消除）|AEC（声学回声消除）]]：近年"全频带实时化"方向的背景页口径。
- [[方向/AI语音/知识/调研与地图/SE SOTA（语音增强模型表现）|SE SOTA]]：DeepFilterGAN 等 48 kHz 实时全频带系统的数字记录。
- [[方向/AI语音/知识/基础概念/NAC（神经音频 Codec）|NAC（神经音频 Codec）]]：现代神经 codec 转向 24/48 kHz 高保真重建的载体。

## 6. 待验证

- URGENT 带宽限制轴的具体档位设置（各档低通截点，如 4/8/16/24/48 kHz 的确切列表）——需回对 arXiv 2505.23212 与 2026 届任务页。
- WebRTC APM/AEC3 支持 48 kHz 处理的具体版本与口径（AEC 全频带实时化的时间线）。
- DeepFilterNet2/3 的 48 kHz 支持细节与 DeepFilterGAN 的关系（当前仅 SE SOTA 页一行记录）。
- EVS FB 档确切的音频带宽上限表述（20 kHz 口径 vs 各编码点位的实际带宽）。

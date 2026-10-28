---
title: AI语音评估
aliases:
  - AI语音评价指标
  - 语音评估指标
tags:
  - MOC
  - 类型/索引
  - 方向/AI语音
---

# AI语音评估

## 评估体系

- [[语音增强评估指标体系]]：语音增强指标地图、生成式幻觉和指标分裂。
- [[可控 TTS 与声音克隆评估框架]]：可控 TTS、voice cloning 和声音身份相关评估维度。

## 评测基准

- [[CHiME（语音分离与识别挑战赛）|CHiME]]：多通道 noisy / distant ASR、阵列前端和会话识别 benchmark 系列。
- [[NOTSOFAR-1（远场会议转写挑战）]]：CHiME-8 Task 2，真实办公室会议 + 已知几何单设备阵列转写 benchmark。
- [[DNS Challenge（深度噪声抑制挑战）]]：通信降噪 / deep noise suppression 挑战赛与 benchmark。
- [[方向/AI语音/评估/URGENT（通用语音增强挑战）|URGENT]]：universal speech enhancement 多语言、多失真挑战。
- [[SUPERB（语音处理通用性能基准）|SUPERB]]：SSL 语音表示通用评测（表示学习时代口径）。
- [[HEAR（音频表示整体评估）|HEAR]]：跨语音/环境声/音乐的通用音频表示评测。
- [[AudioBench（音频大模型通用基准）|AudioBench]]：音频大模型通用横评。
- [[MMAU（大规模多任务音频理解与推理基准）|MMAU]]：专家级多任务音频理解推理基准（含 MMAU-Pro）。
- [[MMAR（音频深度推理基准）|MMAR]]：speech/audio/music 及混合域深度推理基准。
- [[SAKURA（语音多跳推理基准）|SAKURA]]：感知→推理多跳对照基准。
- [[MMAU-Pro（音频通用智能基准）|MMAU-Pro]]：更难的音频通用智能基准（长音频/空间音频/多音频/开放题）。
- [[Dynamic-SUPERB（动态语音指令基准）|Dynamic-SUPERB]]：指令型语音模型 180 任务零样本评测。
- [[SpeechR（语音推理基准）|SpeechR]]：语音推理三维度×三格式基准（含声学特征版）。
- [[MMSU（口语理解推理基准）|MMSU]]：语言学分层的口语理解推理基准。
- [[音频大模型评测基准对比]]：上述基准的选用对照表。
- [[RealMAN 测试结果清单]]：RealMAN 上五类口径（多通道 PESQ / 单通道 DNSMOS / 原文基线 / 几何泛化 / ASR）的结果清单与不可横比边界。

## 单项指标

- [[CER（Character Error Rate）]]、[[CAcc]]：ASR / 内容保持指标。
- [[SpeechBERTScore（语音语义相似度）]]：参考依赖的语音语义/表示相似度指标。
- [[PESQ]]、[[STOI 与 ESTOI]]、[[SI-SDR]]（内含 SI-SDRi 增益口径）、[[SIR（信号干扰比）]]：有参考的质量、可懂度和波形保真指标。
- [[CSIG CBAK COVL（复合客观质量指标）]]：Hu-Loizou 三件套（信号失真 / 背景侵入 / 总体），PESQ 时代标配，与 PESQ 高度共线。
- [[OVRL_MOS]]、[[NISQA]]、[[UTMOS]]、[[SCOREQ]]：无参考 MOS / 听感预测指标。
- [[SpkSim]]：说话人相似度与身份保持指标。
- [[NFE（函数评估次数）]]：扩散 / Flow Matching 采样的效率与部署成本指标。
- [[RTF（实时率）]]：处理时长 / 音频时长；吞吐指标，不等于低延迟，口径四要素缺一不可横比。
- [[BSS_eval（盲源分离评估工具箱）]]：SDR / SIR / SAR / SNR 分解口径的原始工具箱与现代 Python 移植（mir_eval、fast_bss_eval）。

## 公式速查

| 指标 | 核心公式 / 计算口径 |
|---|---|
| [[CER（Character Error Rate）]] | $\mathrm{CER}=\frac{S+D+I}{N}$ |
| [[CAcc]] | $\mathrm{CAcc}=1-\mathrm{CER}=1-\frac{S+D+I}{N}$ |
| WER | $\mathrm{WER}=\frac{S_w+D_w+I_w}{N_w}$，词级口径 |
| [[SI-SDR]] | $10\log_{10}\frac{\lVert s_{target}\rVert^2}{\lVert e_{noise}\rVert^2}$；增益口径 SI-SDRi = 输出 − 输入，不可与绝对值同列 |
| [[SIR（信号干扰比）]] | $10\log_{10}\frac{\lVert s_{target}\rVert^2}{\lVert e_{interf}\rVert^2}$，只看干扰源泄漏 |
| [[SpkSim]] | $\cos(e_{ref},e_{test})=\frac{e_{ref}^{\top}e_{test}}{\lVert e_{ref}\rVert\lVert e_{test}\rVert}$ |
| [[SpeechBERTScore（语音语义相似度）]] | 帧级最大余弦匹配后算 $P/R/F1$ |
| [[STOI 与 ESTOI]] | 短时频谱包络归一化相关系数的均值 |
| [[PESQ]] | $f_{P.862}(x_{ref},x_{test})$，按官方实现输出 MOS-like 分数 |
| [[OVRL_MOS]] / [[NISQA]] / [[UTMOS]] | $\widehat{MOS}=f_\theta(x)$，无参考模型预测 |
| [[NFE（函数评估次数）]] | $\mathrm{NFE}=\sum_t k_t$，每步神经网络/目标函数调用次数求和 |
| [[CSIG CBAK COVL（复合客观质量指标）]] | $\mathrm{COVL}=1.594+0.805\,\mathrm{PESQ}-0.512\,\mathrm{LLR}-0.007\,\mathrm{WSS}$，clamp 到 [1,5] |
| [[RTF（实时率）]] | $\mathrm{RTF}=\frac{\text{推理耗时}}{\text{音频时长}}$，<1 仅表示吞吐快于实时 |

## 相关入口

- [[方向/AI语音/MOC - ASR|ASR]]
- [[方向/AI语音增强/README|AI 语音增强]]
- [[方向/AI语音/MOC - TTS|TTS]]

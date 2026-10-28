---
title: Step-Audio R1
类型: 模型
参数量: 33B（HF 模型卡口径；R1 / R1.1）
发表时间: 2025-11-26
时间依据: arXiv 首次提交日
任务:
  - 音频理解
  - 音频推理
开放状态:
  - paper
  - code
  - weights
aliases:
  - StepAudio R1
  - step-audio-r1
  - Step-Audio-R1
  - Step-Audio-R1.5
tags:
  - 类型/对象
  - 方向/AI语音
  - 主题/音频推理
---

# Step-Audio R1

## 0. 背景

**问题现场**：多数音频模型的长思维链是"想象转写文本"（Textual Surrogate Reasoning），未真正利用声学线索，导致 CoT 越长效果越差。

**Step-Audio R1 的切入点**：通过模态推理蒸馏把真实声学特征注入推理链，再用 RLVR 优化，使 test-time compute scaling 在音频模态首次带来正向收益。

## 1. 内容定位

Step-Audio R1 是阶跃星辰（StepFun）2025 年 11 月发布的音频推理模型，官方称首个真正「解锁」音频域推理能力的模型：让长思维链在音频任务上**首次带来正向收益**，证明了 test-time compute scaling 在音频模态可行。它是 [[方向/AI语音/知识/技术路线/Audio Reasoning（音频推理）|Audio Reasoning（音频推理）]] 路线的标志性工作。

## 2. 核心信息

- **问题诊断**：提出 Textual Surrogate Reasoning（文本替代推理）概念——多数音频模型的 CoT 是在「想象转写文本」而非利用音高、节奏、音色、背景声等声学线索，因此 CoT 越长越差。
- **方法**：通过 modality-grounded reasoning distillation（多轮「模态推理蒸馏」）把真实声学特征注入推理链，再用强化学习（RLVR）进一步优化；推理时显式区分思考过程与最终答案。
- **效果**：在多个音频理解与推理基准上超过 Gemini 2.5 Pro、整体接近 Gemini 3 Pro（官方口径）；长 CoT 由负收益转为正收益。
- **开源**：权重（HF `stepfun-ai/Step-Audio-R1`）、推理代码与技术报告同时放出。
- **后续版本**：Step-Audio-R1.5（arXiv:2604.25719，2026-04）引入 RLHF + rubric 引导的偏好奖励与解耦生成架构，修复 RLVR 只优化「答对」导致回答机械、情感扁平的问题，并开源 step_caption / step_spqa / step_dialogue_understanding 三个评测集。

## 3. 发展脉络

属阶跃星辰音频线的推理分支：[[方向/AI语音/模型/StepAudio 2.5|StepAudio 2.5]]（统一 ASR/TTS/实时交互）→ Step-Audio R1（推理专精）→ Step-Audio R1.5（推理+对话质量对齐）。与 [[方向/AI语音/评估/MMAU（大规模多任务音频理解与推理基准）|MMAU]]、[[方向/AI语音/评估/MMAR（音频深度推理基准）|MMAR]]、[[方向/AI语音/评估/SAKURA（语音多跳推理基准）|SAKURA]] 等推理基准互相成就。

## 4. 边界

- 专注**理解与推理**，不含语音生成/实时对话能力；对话交互看 StepAudio 2.5 线。
- 基准优势部分来自官方自测，第三方复测仍在积累。
- 「RL 收益可迁移到语音/音乐/环境声」的泛化边界仍在探索（见 Audio Reasoning 笔记）。

## 5. 相关对象

- [[方向/AI语音/模型/StepAudio 2.5|StepAudio 2.5]]：同门统一音频-语言模型。
- [[方向/AI语音/知识/技术路线/Audio Reasoning（音频推理）|Audio Reasoning（音频推理）]]：本模型所属路线。
- [[方向/AI语音/评估/MMAU（大规模多任务音频理解与推理基准）|MMAU]] / [[方向/AI语音/评估/MMAR（音频深度推理基准）|MMAR]] / [[方向/AI语音/评估/SAKURA（语音多跳推理基准）|SAKURA]]：主要评测标尺。
- [[方向/AI语音/模型/FlowSE-GRPO|FlowSE-GRPO]]：RL 后训练思想迁移到语音增强的案例。
- [[方向/AI语音/MOC - 音频大模型|MOC - 音频大模型]]：方向地图。

## 6. 来源

- [Step-Audio-R1 Technical Report（arXiv:2511.15848）](https://arxiv.org/abs/2511.15848)
  - 内容定位：技术报告，Textual Surrogate Reasoning 诊断、模态推理蒸馏 + RLVR 方法与基准结果。
  - 用途：方法与结论依据。
  - 核验日期：2026-08-07
- [stepfun-ai/Step-Audio-R1（GitHub）](https://github.com/stepfun-ai/Step-Audio-R1)
  - 内容定位：官方仓库，权重下载、推理代码与 R1.5 资料。
  - 用途：复现入口。
  - 核验日期：2026-08-07
- [Step-Audio-R1.5 Technical Report（arXiv:2604.25719）](https://arxiv.org/abs/2604.25719)
  - 内容定位：后续版本报告，RLHF 偏好对齐与对话质量修复。
  - 用途：版本演进判断。
  - 核验日期：2026-08-07

## 7. 待验证

- 第三方对 R1/R1.5 在 MMAU-Pro 等新版基准上的复测结果。

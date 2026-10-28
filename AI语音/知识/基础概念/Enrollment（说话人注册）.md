---
title: Enrollment（说话人注册）
类型: 概念
发表时间:
时间依据: 经典说话人识别/目标说话人提取流程；非单一发表物
相关任务:
  - 说话人识别
相关主题:
  - 说话人
相关模型:
  - "[[方向/AI语音/模型/WavLM]]"
相关评估:
  - "[[方向/AI语音/评估/SpkSim]]"
aliases:
  - 说话人注册（Enrollment）
  - Enrollment
  - 说话人注册
  - enrollment
tags:
  - 类型/对象
  - 方向/AI语音
  - 任务/说话人识别
  - 主题/说话人
---

# Enrollment（说话人注册）

## 1. 身份

在语音系统里，`enroll / enrollment` 通常指**说话人注册**：先采集一段目标说话人的参考语音，提取 speaker embedding / voiceprint / profile，后续再用它做说话人验证、目标说话人提取或声音克隆条件。

边界：这里的 enrollment 不是会议注册，也不是普通账号注册；它指“把某个人的声音特征登记成可匹配的参考模板”。

## 2. 基本流程

1. 录入一段或多段目标说话人的 enrollment utterance。
2. 做 VAD、降噪、响度归一、质量检查，去掉静音和明显污染段。
3. 用 speaker encoder 提取 embedding。
4. 多段 enrollment 时做平均、聚类或质量加权，形成 speaker profile。
5. 在推理时把该 profile 用作匹配模板或条件输入。

## 3. 用在哪

- **Speaker Verification**：判断测试语音是不是注册过的这个人。
- **[[方向/AI语音/知识/基础概念/TSE（目标说话人提取）|TSE]]**：用 enrollment utterance 抽 speaker embedding，引导模型从混合语音中只提取目标说话人。
- **Diarization / speaker labeling**：已有注册库时，可以把“Speaker 1/2/3”映射到真实身份。
- **[[方向/AI语音/知识/基础概念/Zero-shot Voice Cloning（零样本声音克隆）|Voice cloning / TTS]]**：用参考语音提取音色条件，但这时还要额外考虑授权和滥用风险。

## 4. 质量决定上限

- 参考语音太短，embedding 不稳。
- enrollment 含噪声、混响、其他说话人或播放漏音，会把污染也编码进 profile。
- 注册语音和测试语音通道差异太大（手机近讲 vs 会议远场），会降低匹配和提取效果。
- 文本相关系统要求注册和验证短语一致；文本无关系统则更依赖说话人特征鲁棒性。

## 5. 相关对象

- [[方向/AI语音/知识/基础概念/TSE（目标说话人提取）]]：enrollment 是最常见的目标说话人线索。
- [[方向/AI语音/知识/基础概念/Zero-shot Voice Cloning（零样本声音克隆）]]：enrollment 可以作为 TTS 声音克隆的参考音频条件。
- [[方向/AI语音/知识/基础概念/VAD（Voice Activity Detection）]]：注册前通常先切出有效语音段。
- [[方向/AI语音/模型/WavLM]]：可作为说话人/语音表示来源之一。
- [[方向/AI语音/知识/基础概念/SSL 编码器]]：speaker encoder 常建立在 SSL 表示或专门说话人模型上。
- [[方向/AI语音/评估/SpkSim]]：评估生成/增强语音是否保留注册说话人身份。

## 6. 待验证

- 当前本地语音链路是否需要独立建立 speaker verification / diarization 概念页。
- 中文远场会议场景里，enrollment 需要几秒音频才足够稳定。

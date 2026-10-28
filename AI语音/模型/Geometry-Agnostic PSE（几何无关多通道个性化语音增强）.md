---
title: Geometry-Agnostic PSE（几何无关多通道个性化语音增强）
类型: 模型
发表时间: 2021-10-20
时间依据: arXiv 首次提交日；comment 标注 Submitted to ICASSP 2022
任务:
  - 个性化语音增强
  - 多通道增强
开放状态:
  - paper
  - patent
aliases:
  - Geometry-Agnostic PSE
  - One model to enhance them all
  - array geometry agnostic multi-channel personalized speech enhancement
  - arXiv:2110.10330
相关模型:
  - "[[方向/AI语音/模型/VarArray]]"
tags:
  - 类型/对象
  - 方向/AI语音
  - 任务/语音增强
  - 任务/多通道增强
  - 主题/阵列无关
  - 主题/个性化增强
---

# Geometry-Agnostic PSE（几何无关多通道个性化语音增强）

## 0. 背景

**问题现场**：视频会议爆发后，"只保目标说话人、去掉干扰人声 + 环境噪声"的个性化语音增强（PSE）成为刚需；单通道 PSE 靠声纹注册区分本人，但对空间干扰的利用为零。

**前序路线的缺口**：多通道方法能利用阵列的空间信息，但**逐几何定制**——每换一种阵列几何就要单独训练/适配一个模型，设备族一多就不可扩展；这正是工业界"设备异构复用"动机（调研页 §2）的直接痛点。

**切入点**：把说话人 embedding（"增强谁"）与空间特征（"从哪来"）喂进一个**因果的、阵列几何无关**的多通道 PSE 模型，训练一次即可从任意麦克风几何生成高质量增强信号。

## 1. 身份

Geometry-Agnostic PSE（论文题《One model to enhance them all: array geometry agnostic multi-channel personalized speech enhancement》）是 Hassan Taherian、Sefik Emre Eskimez、Takuya Yoshioka、Huaming Wang、Zhuo Chen、Xuedong Huang（Microsoft）的工作（arXiv:2110.10330，2021-10-20，comment 标注 Submitted to ICASSP 2022），对应**美国专利 12,230,259**（2021 申请、2025 授权）。它是 Teams Voice Isolation（2024 GA，单通道个性化增强）背后的**多通道演进线**（调研页口径）。

边界：目标信号是**注册说话人**（PSE），不是无条件增强或分离；"几何无关"指单模型跨任意几何，不处理设备间时钟异步（异步约束由链条后续的 [[方向/AI语音/模型/Windowed Cross-Attention（窗口交叉注意力异步阵列增强）|WCA]] 承接）。

## 2. 核心机制

```text
多通道麦克风信号（任意几何）
  -> 空间特征（IPD 一类） + 说话人 embedding（声纹注册）
  -> 因果几何无关多通道网络
  -> 输出：目标说话人增强语音
```

- 论文的一个核心问题是**说话人 embedding 与空间特征的相对重要性**——两者都喂给模型，由实验回答谁主导（权重结论见待验证，未抓正文数字）。
- 与 [[方向/AI语音/模型/VarArray]]（同一时期、同一团队谱系）共享"训练一次跨几何部署"的思想：VarArray 把它搬进连续语音分离（TAC + Conformer），本文落在个性化增强。

## 3. 结果口径

- 几何无关模型在语音质量与 ASR 准确率上**优于按特定几何训练的模型**（摘要原文结论），且对未见几何有效。
- 未见正文具体数字表（DNSMOS/WER 值未抓取，见待验证）。

## 4. 使用判断

- 适合：工业"train once, deploy anywhere"阵列可变路线在 **PSE** 上的引用锚点；讨论"声纹 + 空间特征联合"的机制设计。
- 不适合：非个性化的通用增强；有严格异步要求的多设备场景；需要开源复现（未见代码）。
- 与本库复现线的对照价值：坐标条件化（Geo-DConv 派）在工业缺席（设备无标定坐标），本页代表工业界的替代答案——embedding + IPD 而非坐标。

## 5. 关键来源

- [One model to enhance them all: array geometry agnostic multi-channel personalized speech enhancement（arXiv:2110.10330）](https://arxiv.org/abs/2110.10330)
  - 内容定位：原始论文摘要页（v1 2021-10-20）；问题设定、说话人 embedding 与空间特征、几何无关结论。
  - 用途：对象身份与摘要级结论。
  - 核验日期：2026-10-28
- [美国专利 12,230,259](https://lexdana.ai/patent/12230259)
  - 内容定位：同方法的专利族（2021 申请、2025 授权），经调研页核验。
  - 用途：工业落地意图的证据。
  - 核验日期：2026-10-28（沿用调研页核验，未独立读专利全文）

## 6. 相关对象

- [[方向/AI语音/模型/VarArray]]：同思想（train once, deploy anywhere）在 CSS 上的姊妹工作。
- [[方向/AI语音/模型/Windowed Cross-Attention（窗口交叉注意力异步阵列增强）]]：链条 2025 节点，补上异步约束。
- [[方向/AI语音/团队/Microsoft Speech Group（微软语音组）]]：所属团队；Teams Voice Isolation 为其单通道产品线。
- [[方向/AI语音/知识/调研与地图/Array-Agnostic SE Industry（工业界阵列可变语音增强调研）]]：链条叙事与"坐标条件化在工业缺席"的镜像观察。
- [[方向/AI语音/知识/基础概念/IPD（通道间相位差）]]：空间特征的主要形态。
- [[方向/AI语音/知识/基础概念/Enrollment（说话人注册）]]：PSE 声纹 embedding 的前置环节。
- [[方向/AI语音/知识/基础概念/TAC（变换-平均-拼接）]]：VarArray 侧同谱系聚合模块（本页是否用 TAC 待核正文）。

## 7. 待验证

- 正文实验数字（数据集、指标表、embedding vs 空间特征的重要性结论）未抓取全文。
- comment 仅写 "Submitted to ICASSP 2022"，是否正式被接收待核（调研页记为 ICASSP 2022）。
- 与 Teams Voice Isolation 的工程承接关系为调研页口径，公开材料中两者的直接关联表述待查。
- 是否使用 TAC 或其他排列不变聚合模块、通道数泛化的具体机制，待读原文。

---
title: ECHI（助听对话增强）
类型: 评测基准
发表时间: 2025-07-01
时间依据: 挑战赛数据发布日
aliases:
  - ECHI
  - echi
  - ECHI Challenge
  - CHiME-9 Task 2
  - CHiME-9 ECHI
  - Enhancing Conversations to address Hearing Impairment
  - 助听对话增强
  - 助听场景对话增强
tags:
  - 类型/对象
  - 方向/AI语音
  - 任务/语音增强
  - 任务/目标说话人提取
  - 主题/助听
  - 主题/可穿戴设备
---

# ECHI（助听对话增强）

## 0. 背景

**问题现场**：WHO 预测 2050 年全球 25 亿人不同程度听力损失，助听器用户在餐厅等社交场合仍难以跟上对话；离线增强与阵列增强不适用于助听器/智能眼镜的穿戴硬件约束。

**切入点**：CHiME-9 Task 2 把助听对话增强定为硬实时任务——流式处理、算法延迟 ≤ 20 ms、抑制全部背景声源并保留对话伙伴语音，最终排名只看 MUSHRA 主观听测。

## 1. 身份

`ECHI`（Enhancing Conversations to address Hearing Impairment）是 **CHiME-9 Task 2**：为听力受损用户做**实时对话增强**——在嘈杂真实场景（模拟餐厅）中抑制全部背景声源（环境噪声 + 竞争对话 + 环境音效），同时保留对话伙伴的语音。动机：WHO 预测 2050 年全球 25 亿人不同程度听力损失，助听器用户在咖啡厅/餐厅等社交场合仍难以跟上对话。

边界：它不是离线增强或阵列增强指标榜——**硬约束是流式处理、算法延迟 ≤ 20 ms**，且**最终排名只看主观听测（MUSHRA）**，客观指标仅作参考；设备是助听器与智能眼镜两类穿戴硬件，不是固定会议阵列。

## 2. 任务口径

- 每场会话输出**每个对话伙伴一条单通道增强流**（每场 3 条），可重加和为增强后的整场对话；系统必须**独立处理两类设备**。
- **硬实时约束**：仅允许因果/流式处理，算法延迟上限 20 ms（会被验证并按延迟排序）。
- **注册式 TSE**：每个参与者有干净 "Rainbow Passage" 朗读，用于目标说话人注册（speaker enrollment）。
- 禁止使用 dev 集训练/调参；禁止非流式全局信息（说话人 ID / 离线 diarization）。

## 3. 数据口径

- **场景**：4 人围桌；14 个扬声器模拟最多 7 场两人竞争对话（LibriSpeech / EARS 自发语音）；另有餐厅音效（碰杯、咳嗽）+ 4 个角落扬声器放 WHAM! 环境噪声。
- **设备**：Meta Aria 智能眼镜（7 麦）；WSA 助听器外壳（4 麦，左右耳各前/后麦）。
- **附加数据**：贴身领夹麦（参考信号来源）、头部姿态追踪（250 Hz）、每人 Rainbow Passage 注册朗读。
- **规模**：49 场 × 36 分钟 ≈ 29 h，~190+ 说话人；train 30 场（18 h）/ dev 10 场（6 h）/ eval 9 场（5.5 h）；48 kHz；各 split 说话人、背景素材、噪声环境完全不相交；数据公开（DOI 10.57967/hf/5924）。
- **参考信号**：降噪领夹麦 + 延迟/同步校正（头跟踪距离测量、Aria 时钟漂移校正、互相关细对齐）构造。

## 4. 评测口径

- **客观（VERSA 工具包）**：有参考（STOI、PESQ、SDR、SI-SNR、FWSEGSNR 等）+ 无参考 DNN 指标（DNSMOS、NISQA、UTMOS、TorchAudio-Squim）；对**单条流**与**重加和流**分别计算。
- **主观**：MUSHRA 式听测评重加和会话的质量与可懂度；**最终名次仅由听测决定**。

## 5. 基线与结果

官方基线基于 [[方向/AI语音/模型/TF-GridNet|TF-GridNet]]：多通道输入编码器 + 说话人编码器（注册式 TSE）+ [[方向/AI语音/知识/基础概念/FiLM（特征级线性调制）|FiLM]] 注入说话人嵌入 + 因果化改造支持流式低延迟。dev 上重加和 FWSEGSNR 从直通 ~1.2–1.4 提升到 ~3.3（两设备一致）。

2026 系统报告（[ISCA 论文集](https://www.isca-archive.org/chime_2026/)）：

- **Zhao et al.**：三阶段系统——自干扰抑制 + 目标说话人提取 + 后处理。
- **Tu et al.**：低延迟多阶段 [[方向/AI语音/知识/基础概念/MIMO（多输入多输出）|MIMO]] + 跨波束交互（一作与 USTC-NERCSLIP MCoRec 报告重叠，**团队归属未确认**）。
- **Tsao 组**（Jhou/Chao et al.）：延迟可变的统一框架 + 因果 Mamba 核；多通道 band-split 循环实时说话人条件增强。
- **NTT（Hu et al.）**：相位/幅度对齐数据训练低延迟 TSE（Nakatani/Kamo/Ochiai/Makino）。
- **Haghbin & Vaughan**：强化学习多通道增强；**Sharma et al.**（Bochum）：感知驱动的低延迟 TSE。

## 6. 使用注意

- "≤20 ms + 因果"是架构分水岭：非因果/离线方法（含多数掩码 SOTA）不满足规则即不参与排名。
- 主观听测定榜意味着客观指标（PESQ/STOI 等）只能当参考，做系统对比要关注听测设置。
- 与 [[方向/AI语音/评估/MCoRec（多模态上下文识别）|MCoRec]] 是 CHiME-9 的两个极端：一个"识别为主、无独立前端"，一个"增强为主、20 ms 流式硬约束"。

## 7. 关键来源

- [CHiME-9 Task 2 ECHI 官网](https://www.chimechallenge.org/challenges/chime9/task2/)
  - 内容定位：任务定义、规则、数据与评测口径。
  - 用途：任务口径与硬约束确认。
  - 核验日期：2026-08-06
- [CHiME9-ECHI 基线与评测框架（GitHub）](https://github.com/CHiME9-ECHI/CHiME9-ECHI)
  - 内容定位：TF-GridNet 基线实现与 VERSA 评测流程。
  - 用途：基线机制、FWSEGSNR 数值与复现入口。
  - 核验日期：2026-08-06
- [任务描述（White Rose 库）](https://eprints.whiterose.ac.uk/id/eprint/241320/)
  - 内容定位：CHiME9 ECHI 挑战描述论文。
  - 用途：场景、设备、数据与参考信号构造细节。
  - 核验日期：2026-08-06

## 8. 相关对象

- [[方向/AI语音/评估/CHiME（语音分离与识别挑战赛）|CHiME]]：ECHI 是 CHiME-9 Task 2。
- [[方向/AI语音/评估/Clarity Enhancement Challenge（助听器语音增强挑战赛）|Clarity Enhancement Challenge]]：助听增强评测的前辈系列（CEC1/2/3）；Clarity-2025 workshop 明确"嘈杂对话"方向由 ECHI 接棒。
- [[方向/AI语音/评估/MCoRec（多模态上下文识别）|MCoRec]]：CHiME-9 Task 1，姊妹任务。
- [[方向/AI语音/知识/基础概念/TSE（目标说话人提取）|TSE]]：注册式说话人提取是任务核心。
- [[方向/AI语音/知识/基础概念/FiLM（特征级线性调制）|FiLM]]：官方基线中的说话人条件注入方式。
- [[方向/AI语音/模型/TF-GridNet|TF-GridNet]]：官方基线骨干。
- [[方向/AI语音/评估/语音增强评估指标体系|语音增强评估指标体系]]：VERSA 客观指标口径参照。
- [[方向/AI语音/知识/调研与地图/Array Speech Enhancement Frontier（阵列语音增强前沿调研）|阵列语音增强前沿调研]]：CHiME-9 调研条目。

## 9. 待验证

- 官方 eval 榜最终名次（主观听测排序，HSCMA&CHiME 2026 workshop 公布）。
- USTC-NERCSLIP / 讯飞是否参与 ECHI（Tu et al. MIMO 系统团队归属待核）。
- ECHI 数据与任务口径对中文助听场景的迁移性（主观听测、中文 TSE 注册）。

---
title: T-Grid Rollout（显式时间网格 Rollout）
类型: 概念
相关主题:
  - Flow Matching
  - GRPO
  - 后训练
aliases:
  - 显式时间网格 Rollout
  - t-grid rollout
  - t_grid rollout
  - Flow-SDE Rollout
tags:
  - 类型/对象
  - 方向/AI语音
  - 主题/强化学习
  - 主题/生成模型
---

# T-Grid Rollout（显式时间网格 Rollout）

## 1. 身份

T-Grid Rollout 指在**显式时间网格** $t_0<t_1<\dots<t_N$（代码中常记作 `t_grid`）上逐步执行 Flow-SDE 采样、并把每一步的 state / action / 转移 log-prob 显式记录下来的 rollout 方式，用于把 [[方向/AI语音/知识/基础概念/Flow Matching（流匹配）|Flow Matching]] 模型的确定性 ODE 采样改造成 on-policy RL（如 [[方向/大模型/训练/强化学习/GRPO|GRPO]]）可用的随机轨迹。

边界：它不是一个模型，也不是一种新采样器，而是「ODE→SDE + 显式网格 + 逐步记录」这一工程约定的统称；对立面是把轨迹藏进 `odeint` 等黑盒求解器、只返回端点的采样方式。

## 2. 名字解释

- **t_grid / 时间网格**：把 $[0,1]$ 的生成进度显式离散成一组递增时间点，每一步的 $t$ 与 $\mathrm{d}t$ 都可见、可记录、可与推理配置对齐，而不是由求解器内部自适应决定。
- **Rollout**：RL 术语，指从初始噪声出发、按当前策略完整走一遍生成过程得到一条轨迹；GRPO 需要多条独立噪声的轨迹做组内对比。

## 3. 为什么需要

- **确定性 ODE 没有探索**：标准 FM 采样是确定性的，同一噪声必然得到同一样本，无法提供 on-policy RL 所需的随机性与动作概率。
- **黑盒求解器藏掉轨迹**：`odeint` 类接口只给端点，拿不到中间 state 和转移概率，无法计算重要性比率 $r_i(\theta)=\pi_\theta/\pi_{\text{old}}$。
- **训练与推理口径要对齐**：显式 `t_grid` 保证 rollout 用的 [[方向/AI语音/评估/NFE（函数评估次数）|NFE]]、CFG 强度、[[方向/AI语音/知识/基础概念/Sway Sampling（摇摆采样）|sway 采样变形]]与线上推理完全一致，避免「训练一套网格、推理另一套网格」的分布偏移。

## 4. 核心机制

数据流：

```text
噪声 z0 + 条件 c
  -> 显式时间网格 t_grid（长度 N+1）
  -> 逐格推进：
       随机窗口（前若干格）: z_next = z + v*dt + sigma_t*sqrt(dt)*eps   [记录 state/action/log-prob]
       其余格（确定性 ODE）: z_next = z + v*dt                        [detach，不参与策略梯度]
  -> 末端样本 z1 -> 奖励打分 -> 组内归一化 advantage -> GRPO 更新
```

其中 $z$ 为 latent 状态，$v=v_\theta(z,t,c)$ 为模型（可带 CFG）预测的速度，$\mathrm{d}t=t_{k+1}-t_k$，$\sigma_t$ 为噪声强度 schedule，$\epsilon\sim\mathcal N(0,I)$。

随机窗口内的单步转移是**高斯策略**，其 log-prob 可解析计算：

$$
\log\pi_\theta(z_{k+1}\mid z_k)=\log\mathcal N\big(z_{k+1};\; z_k+v_\theta(z_k,t_k,c)\,\mathrm{d}t,\; \sigma_{t_k}^2\,\mathrm{d}t\, I\big)
$$

rollout 时记录 old-policy log-prob；更新阶段用当前策略在记录的 state 上重算均值（`no_grad` 外建图），得到重要性比率。这就是 Flow-GRPO 一脉的「ODE 转等边际 SDE」在离散网格上的落地形式，窗口化（只随机化前几步）对应 MixGRPO 的混合 ODE-SDE 思路，见 [[方向/AI语音/模型/FlowSE-GRPO|FlowSE-GRPO]]。

## 5. 关键设计选择

- **网格来源**：显式传入 `t_grid` 优先；否则由 `steps` 等距生成，再应用 [[方向/AI语音/知识/基础概念/Sway Sampling（摇摆采样）|Sway Sampling]] 变形 $t \leftarrow t + \kappa(\cos\frac{\pi}{2}t - 1 + t)$。网格必须严格递增。
- **$\sigma_t$ 约定**：schedule（constant / 线性等）、数值范围，以及 $\sigma_t$ 是否已含 $\sqrt{\mathrm{d}t}$ 因子必须写死——这是最常见的口径错误源；约定应随 rollout 元数据一起保存。
- **随机窗口位置与长度**：窗口落在高噪段（早期步）还是全程，决定探索作用于「全局结构」还是「细节」；窗口外状态必须 detach，否则显存与梯度范围失控。
- **组采样**：每个 prompt 采 $G$ 条轨迹，共享条件与输入、噪声各自独立，供组内归一化 advantage。
- **数值防护**：速度、状态必须逐步检查 finite，禁止 NaN/Inf 轨迹进入训练。

## 6. 实现参照（AuK 仓库）

AuK 本地实现（`D:/pycharm_projects/my/AuK/src/auk/model/cfm_edit.py` 的 `rollout_grpo` / `_sampling_grid`）是上述约定的一个具体实例：默认 32 NFE、CFG 2.0、[[方向/AI语音/知识/基础概念/Sway Sampling（摇摆采样）|sway]] −1.0，前 6 步 SDE 随机窗口、其后确定性 ODE，每 prompt $G=8$ 候选，constant $\sigma=0.05$（`sigma_includes_sqrt_dt` 显式标注约定），随机窗口每步记录 `state / action / t / dt / sigma_t / old_log_prob`，并把这些连同 `t_grid`、sway 系数写入 rollout 元数据。该配方对齐 AuK 论文的生成 RL 设置（Flow-GRPO + MixGRPO 低 SNR 区 6 步随机窗口，见 [[方向/AI语音/模型/AuK|AuK]]）。

## 7. 相关对象

- [[方向/AI语音/知识/基础概念/Flow Matching（流匹配）|Flow Matching]]：被改造的确定性 ODE 采样范式。
- [[方向/AI语音/知识/基础概念/Flow-GRPO（流匹配模型在线强化学习）|Flow-GRPO]]：方法论源头——ODE→SDE 等边际转换与 Denoising Reduction。
- [[方向/大模型/训练/强化学习/GRPO|GRPO]]：消费 rollout 轨迹与 log-prob 的后训练算法。
- [[方向/AI语音/模型/FlowSE-GRPO|FlowSE-GRPO]]：同一配方在语音增强上的公开参照（含窗口训练与多指标奖励）。
- [[方向/AI语音/模型/AuK|AuK]]：本地实现所属模型；论文中对应「生成 RL：Flow-GRPO + MixGRPO」。
- [[方向/AI语音/知识/基础概念/ODE（常微分方程）|ODE]]：被转为 SDE 的积分对象。
- [[方向/AI语音/评估/NFE（函数评估次数）|NFE]]：网格长度即采样步数，直接决定 rollout 成本。
- [[方向/AI语音/知识/基础概念/Sway Sampling（摇摆采样）|Sway Sampling]]：改变积分时间点的分布；rollout 应复用推理时的变换后网格。

## 8. 关键来源

- [Flow-GRPO: Training Flow Matching Models via Online RL](https://arxiv.org/abs/2505.05470)
  - 内容定位：ODE→SDE 转换与逐步 log-prob 形式化的方法源头。
  - 用途：解释随机窗口转移为何可当高斯策略处理。
  - 核验日期：2026-09-30
- [MixGRPO（混合 ODE-SDE 窗口训练）](https://arxiv.org/abs/2507.21802)
  - 内容定位：只对部分时间步做 SDE、其余走 ODE 的窗口化思路来源。
  - 用途：解释「随机窗口 + 确定性后缀」的设计。
  - 核验日期：2026-09-30
- 本地代码 `D:/pycharm_projects/my/AuK/src/auk/model/cfm_edit.py`、`D:/pycharm_projects/my/AuK/TODO.md`（第 2 节 Rollout）
  - 内容定位：本笔记第 5、6 节设计选择与默认数值的直接依据。
  - 用途：把概念页与工程实现对齐。
  - 核验日期：2026-09-30

## 9. 待验证

- $\sigma_t$ schedule 从 constant 改为随 $t$ 衰减（如 Flow-GRPO 的 $\sigma_t=a\sqrt{(1-t)/t}$）对探索/稳定性的影响。
- 随机窗口落在高噪段 vs 全程 SDE 的奖励效率对比（FlowSE-GRPO 报告窗口训练收敛更快，AuK 本地未消融）。
- 「零速度 + 固定噪声下 SDE 转移与 log-prob 可手算复现」的纯 Torch 自检（AuK TODO 中尚未完成项）。
- [[方向/AI语音/知识/基础概念/Sway Sampling（摇摆采样）|Sway Sampling]] 变形网格与等距网格下，rollout 分布与线上推理分布的一致性度量。

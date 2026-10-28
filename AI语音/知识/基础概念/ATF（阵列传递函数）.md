---
title: ATF（阵列传递函数）
类型: 概念
相关任务:
  - 语音增强
  - 语音分离
  - 去混响
相关主题:
  - 阵列信号
  - 多通道增强
  - 信道建模
aliases:
  - ATF
  - atf
  - Acoustic Transfer Function
  - acoustic transfer function
  - Array Transfer Function
  - array transfer function
  - 阵列传递函数
  - 声学传递函数
tags:
  - 类型/对象
  - 方向/AI语音
  - 主题/阵列信号
  - 主题/多通道增强
  - 主题/信道建模
---

# ATF（阵列传递函数）

## 0. 背景

- **出现前的问题**：早期阵列模型只有 [[方向/AI语音/知识/基础概念/steering vector（导向矢量）|steering vector]]——自由场、纯相位延迟、各麦等增益、只由方向决定。它把房间反射、麦克风频响差异、距离衰减、遮挡全部丢掉；混响一强，MVDR 的"无失真"约束就指向错误方向，目标被抵消。
- **替代方案的缺口**：mask-based 波束形成曾绕过传递函数（GEV/MVDR 只用 $\Phi_{xx}$、$\Phi_{nn}$ 两个 [[方向/AI语音/知识/基础概念/SCM（空间协方差矩阵）|SCM]]），但一旦要做"按源重建多通道观测""把输出对齐回参考通道""把物理退化算子写进生成模型"，就必须有显式的、每个源每个麦的传递函数——ATF 因此不可回避。
- **出现后的谱系**：steering vector（ATF 的自由场特例）→ ATF（含混响与器件响应）→ RTF（去掉公共滤波、从观测可辨识的比值形式）→ SCM（把 ATF 变成统计量 $\sigma_s^2\mathbf{h}\mathbf{h}^H$）→ 估计化（实测标定 → 盲估计 WPE/[[方向/AI语音/知识/基础概念/MCLP（多通道线性预测）|MCLP]]/FCP → 神经估计）→ 生成式时代成为"未知前向算子在采样过程中在线估"（ADEPS 的退化算子、Uni-ArrayDPS 的 FCP）。

## 1. 身份

`ATF`（Acoustic / Array Transfer Function，阵列传递函数）是**某个固定声源位置到阵列各麦克风的短时线性传递函数**，写成频域复向量：

$$
\mathbf{h}(\ell,f) = \big[\,h_1(\ell,f),\; h_2(\ell,f),\; \dots,\; h_M(\ell,f)\,\big]^{T} \in \mathbb{C}^{M}
$$

每个分量 $h_m$ 是一个复数，同时编码两件事——**幅度**（传播距离衰减 + 反射叠加后的强弱 + 麦克风/前端频响）与**相位**（直达声飞行时间 + 各反射路径延迟 + 器件相移）。观测模型：

$$
\mathbf{y}(\ell,f) = \sum_{k=1}^{K} \mathbf{h}^{k}(\ell,f)\, s^{k}(\ell,f) + \mathbf{n}(\ell,f)
$$

$s^k$ 是第 $k$ 个源的参考信号（"源在参考点处长什么样"），$\mathbf{h}^k$ 描述它如何被阵列听到。K 个源的 ATF 按列堆起来就是 $M\times K$ 的传递函数矩阵，ASM / AmbiDrop 里的 $\mathbf{V}(k)\in\mathbb{C}^{M\times Q}$（每列一个方向的 ATF）是它的方向网格版本。

边界：ATF 不是 [[方向/AI语音/知识/基础概念/Reverberation Modeling（混响建模）|RIR]]（RIR 是时域宽带冲激响应，ATF 是它的逐频点窄带副本，二者是傅里叶对）；不是 [[方向/AI语音/知识/基础概念/SCM（空间协方差矩阵）|SCM]]（二阶统计量，ATF 是它的一阶因子）；不是波束权重（响应 vs 滤波系数）。

## 2. 数学形式与分解

$$
h_m(\ell,f) \;=\; \underbrace{\frac{1}{4\pi r_m}e^{-j 2\pi f \tau_m}}_{\text{直达}} \;+\; \underbrace{\sum_{i} \frac{\rho_i}{4\pi r_{m,i}}e^{-j 2\pi f \tau_{m,i}}}_{\text{反射/混响}} \;\times\; \underbrace{G_m(f)}_{\text{器件响应}}
$$

- **直达项**：$r_m$ 是源到第 $m$ 个麦的距离，$\tau_m=r_m/c$。只保这一项 + 远场假设（$r_m$ 近似相等，去掉 $1/r_m$）= steering vector。
- **反射项**：把房间所有镜像源累加，就是 [[方向/AI语音/知识/基础概念/ISM（Image Source Method，镜像声源法）|image-source]] 仿真的产物；这一项让 $|h_m|$ 与相位都偏离几何预测，且随频率剧烈起伏（梳状）。
- **器件项**：麦克风频响、外壳散射、增益与前端滤波，见 [[方向/AI语音/知识/基础概念/Microphone Channel Modeling（麦克风信道建模）|Microphone Channel Modeling]]。

时域 ↔ 频域：对每个 (源, 麦) 对，$h_m(f)$ 就是该对 RIR 的 STFT 在某帧上的取值；短时不变假设（说话人不动、房间不动）是把 $h_m$ 当成"每帧一个复标量"的前提。

## 3. 与相邻概念的区别

| 概念 | 定义 | 依赖 | 能否从观测辨识 |
| --- | --- | --- | --- |
| [[方向/AI语音/知识/基础概念/steering vector（导向矢量）]] | 自由场平面波的理想复响应 | 几何 + DoA + 频率 | 不需要观测，纯模型 |
| ATF | 含混响与器件响应的真实传递函数 | 声源位置 + 房间 + 器件 | 只能辨识到"差一个公共滤波" |
| RTF | ATF 对参考通道的比值 | 同上（比值形式） | 可辨识（去掉公共滤波） |
| [[方向/AI语音/知识/基础概念/SCM（空间协方差矩阵）]] | 多通道二阶统计量 | 信号统计 + ATF | 可用时间平均估 |
| RIR | 时域冲激响应 | 房间 + 器件 | 可测（扫频/MLS 反卷积） |

一句话记法：**steering vector 是"应该长什么样"，ATF 是"实际长什么样"，RTF 是"实际长什么样但只剩通道间差别"，SCM 是"把 ATF 连同源功率压成一个矩阵"**。

## 4. 绝对尺度不可辨识与 RTF

观测里只出现乘积 $\mathbf{h}\,s$。对任意公共滤波 $g(f)$，令 $\mathbf{h}\to \mathbf{h}g$ 且 $s\to s/g$，观测完全不变——**ATF 的绝对尺度与公共相位在数学上不可辨识**。

因此文献里真正被估计的是**相对传递函数**（RTF）：

$$
\mathbf{h}^{\mathrm{rel}}(\ell,f) = \frac{\mathbf{h}(\ell,f)}{h_{\mathrm{ref}}(\ell,f)},\qquad h^{\mathrm{rel}}_{\mathrm{ref}}\equiv 1
$$

RTF 保留通道间幅度差与相位差（含混响），这正是 MVDR 需要的量：无失真约束只要求"输出等于参考麦听到的目标"，不要求知道目标的绝对声压。$\mathbf{w}=\Phi_{nn}^{-1}\mathbf{h}^{\mathrm{rel}}/(\mathbf{h}^{\mathrm{rel}H}\Phi_{nn}^{-1}\mathbf{h}^{\mathrm{rel}})$。

要用到**绝对** ATF 时必须另找锚点，工程上四种来源：

- **参考通道直达声**：把参考麦的直达声当 $s$，其余通道的传递函数就相对于它（RealMAN 的 `dp_speech` 就是这个口径）。
- **已知源信号**：近讲麦/耳内麦给出 $s$，远场阵列的 ATF 可解（[[方向/AI语音/模型/C2D Projection（近讲麦到远场投影）|C2D Projection]] 的做法）。
- **几何 + 仿真**：自由场或 image-source 直接算出 $\mathbf{h}$（AmbiDrop / ADEPS 的仿真训练与编码）。
- **阵列标定**：扫频实测（[[方向/AI语音/知识/基础概念/ESS（Exponential Sine Sweep）|ESS]] / [[方向/AI语音/知识/基础概念/TSP（Time-Stretched Pulse）|TSP]]），只对固定几何有效。

## 5. 在算法里的角色

- **波束形成**：MVDR / MPDR / GEV 的目标约束全部依赖 $\mathbf{h}$ 或 $\mathbf{h}^{\mathrm{rel}}$；ATF 误差直接转成目标失真（[[方向/AI语音/模型/BiTSE（AR 眼镜双耳目标说话人提取）|BiTSE]] 里 6 麦 MVDR 几乎无提升，作者归因于 ATF/DoA 失配）。
- **物理编码**：[[方向/AI语音/知识/基础概念/ASM（Ambisonics 信号匹配编码）|ASM]] / [[方向/AI语音/模型/AmbiDrop|AmbiDrop]] 用 $\mathbf{V}(k)$ 做球谐匹配，编码误差的分子里就含"ATF 拟合残差"；Aria 上改用模拟 ATF 后提升少了约 2 dB，是 ATF 误差进指标的直证。
- **生成式逆问题**：[[方向/AI语音/模型/ADEPS|ADEPS]] 的退化算子 $A(\cdot)$ 由 ATF/导向矩阵构成——它把 ATF 当"已知的物理条件"，先验则完全与阵列解耦。
- **DPS 里被在线估计**：[[方向/AI语音/模型/Uni-ArrayDPS|Uni-ArrayDPS]] 的 DPS 假设退化算子 $A(\cdot)$ 已知，这在真实数据上不成立，于是每一步用 **FCP** 从当前 $\hat{X}_0$ 与观测 $Y$ 估 $\hat{H}^k$：$N_H=13$ 帧抽头（岭正则 $\gamma=10^{-3}$）时它近似完整 ATF，用来把参考通道估计卷积回多通道混响语音、相减得噪声残差；$N_H=1$ 时退化成每频点一个复标量，等价于只估 RTF 型缩放，专用于把扩散样本对齐回参考通道。
- **统计建模**：单源时 $\Phi_{ss}=\sigma_s^2\mathbf{h}\mathbf{h}^H$ 秩 1，ATF 就是主特征向量——这也解释了为什么"只想白化噪声"时并不需要显式 ATF。

## 6. 估计路线与失效条件

| 路线 | 做法 | 主要失效 |
| --- | --- | --- |
| 实测标定 | 扫频/MLS 反卷积取 RIR | 换房间、换人、换器件即失效；成本高 |
| 几何仿真 | 自由场或 image-source 算 $\mathbf{h}$ | 坐标/朝向误差在高频被放大；材料系数未知 |
| 盲估计（线性预测） | [[方向/AI语音/知识/基础概念/WPE（加权预测误差）|WPE]] / [[方向/AI语音/知识/基础概念/MCLP（多通道线性预测）|MCLP]] 从观测里分离晚期混响 | 需较长的语音活动；双 talk 时退化 |
| 盲估计（前向卷积预测） | FCP：用参考通道信号前向卷积预测各通道，最小二乘解抽头 | 说话人移动、$N_H$ 截断、参考通道本身不干净 |
| 神经估计 | 直接回归 ATF/RTF，或回归虚拟麦信号（Neural-VME） | 未见阵列泛化；绝对尺度仍需锚 |

共同前提是**短时不变**：ATF 只能在一个短片段内当一个常数。转头、走动、多人轮流说话都会破坏它，这也是"逐帧重估 + 指数滑动平均"在 FCP 类方法里必须存在的原因。

## 7. 相关对象

- [[方向/AI语音/知识/基础概念/steering vector（导向矢量）|steering vector]]：ATF 的自由场、纯延迟、等增益特例。
- [[方向/AI语音/知识/基础概念/Array Steering Matrix（阵列导向矩阵）|Array Steering Matrix]]：多个方向的 steering vector 按列堆叠；ATF 矩阵是它的实测/含混响版本。
- [[方向/AI语音/知识/基础概念/SCM（空间协方差矩阵）|SCM]]：ATF 的二阶统计封装，$\Phi_{ss}=\sigma_s^2\mathbf{h}\mathbf{h}^H$。
- [[方向/AI语音/知识/基础概念/Microphone Channel Modeling（麦克风信道建模）|Microphone Channel Modeling]]：ATF 里"器件响应"那一项的来源。
- [[方向/AI语音/知识/基础概念/Reverberation Modeling（混响建模）|Reverberation Modeling]]：ATF 里"反射项"的建模口径。
- [[方向/AI语音/知识/基础概念/MVDR（最小方差无失真响应）|MVDR]]：以 RTF 为无失真约束的核心消费者。
- [[方向/AI语音/模型/Uni-ArrayDPS|Uni-ArrayDPS]]：DPS 采样中以 FCP 在线估 ATF 的代表。
- [[方向/AI语音/模型/AmbiDrop|AmbiDrop]] / [[方向/AI语音/模型/ADEPS|ADEPS]]：把 ATF 矩阵作为物理编码/退化算子。
- [[方向/AI语音/模型/C2D Projection（近讲麦到远场投影）|C2D Projection]]：借近讲参考信号解远场 ATF。

## 8. 关键来源

- [Unified Diffusion Refinement for Multi-Channel Speech Enhancement and Separation](https://arxiv.org/abs/2603.24810)
  - 内容定位：用 FCP 在扩散采样中在线估每个源的 ATF $\hat{H}^k$，再用它把参考通道估计卷积回多通道、相减得噪声残差。
  - 用途：确认"ATF 作为未知前向算子被在线估计"这一用法及其参数（$N_H=13$、$\gamma=10^{-3}$，对齐用 $N_H=1$）。
  - 核验日期：2026-10-27
- [AmbiDrop（扩展版）](https://arxiv.org/abs/2607.00548)
  - 内容定位：以 ATF 矩阵 $\mathbf{V}(k)$ 做球谐匹配编码，并给出含"ATF 拟合残差"的编码误差闭式。
  - 用途：支撑 ATF 误差直接进重建指标（Aria 上模拟 ATF 少约 2 dB）。
  - 核验日期：2026-10-27

## 9. 待验证

- FCP（forward convolutive prediction）的原始出处与标准式：本文只按 Uni-ArrayDPS 的实现口径记录，抽头数/正则项符号约定需回到原始论文核对。
- RTF 估计误差（余弦相似度）对下游 MVDR 与 DPS 精修的敏感性排序，是否与 [[方向/AI语音/知识/基础概念/SCM（空间协方差矩阵）|SCM]] 估计误差同量级。
- 是否需要再拆独立页：RTF 估计（协方差白化法 vs 最小二乘 FCP）与方法页的边界，等出现第二篇以 RTF 为主线的复现任务时再定。

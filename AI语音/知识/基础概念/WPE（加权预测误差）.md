---
title: WPE（加权预测误差）
类型: 概念
相关主题:
  - 阵列信号
  - 多通道增强
  - 去混响
aliases:
  - WPE
  - wpe
  - Weighted Prediction Error
  - weighted prediction error
  - 加权预测误差
  - WPE 去混响
  - 方差归一化延迟线性预测
  - Variance-Normalized Delayed Linear Prediction
tags:
  - 类型/对象
  - 方向/AI语音
  - 主题/阵列信号
  - 主题/多通道增强
  - 主题/去混响
---
# WPE（加权预测误差）

## 1. 身份

`WPE`（Weighted Prediction Error，加权预测误差）是 NTT（Nakatani 等，2010，IEEE TASLP）提出的**多通道去混响算法**：用延迟线性预测（delayed linear prediction）从语音信号里估计并减去**晚期混响**成分，是最经典的盲去混响方法。它是多通道语音前端的事实标准组件——CHiME 官方基线、ESPnet-SE 和绝大多数挑战赛系统里都有它的位置。

边界：WPE 处理混响（尤其晚期混响），不处理噪声——所以常与 [[方向/AI语音/知识/基础概念/MVDR（最小方差无失真响应）|MVDR]] / beamforming 串联（WPE 去混响 → 空间滤波 → post-filter）。它不是 DNN 方法，但可与神经前端叠加（DNN 估 PSD / mask 喂给 WPE，即 DNN-WPE）。

## 2. 核心机制

```text
多通道 STFT
  -> 用延迟后的历史帧线性预测当前混响成分
  -> 预测器系数按语音时变方差加权（避免强音时段主导）
  -> 从当前帧减去预测的混响
  -> 交替迭代：估预测器 <-> 估语音方差（EM 式）
```

## 3. 数学模型

### 3.1. 信号模型（STFT 子带域）

多通道时域信号经 STFT 分解后，第 $k$ 个频点、第 $n$ 帧、第 $m$ 个通道的观测为：

$$
x_m(k,n) = s_m(k,n) + d_m(k,n)
$$

其中 $s_m(k,n)$ 是**早期成分**（直达声 + 早期反射，一般 < 50 ms），是希望保留的目标；$d_m(k,n)$ 是**晚期混响**，其关键性质是：可以近似为过往多帧观测的线性函数。

### 3.2. 延迟多通道线性预测（[[方向/AI语音/知识/基础概念/MCLP（多通道线性预测）|MCLP]]）

定义**延迟观测向量**——把所有通道、$L$ 个滞后帧的观测按列堆叠：

$$
\tilde{\mathbf{x}}(k, n-\Delta) =
\left[\, x_1(k,n-\Delta),\, \ldots,\, x_1(k,n-\Delta-L+1),\;
\ldots,\; x_M(k,n-\Delta),\, \ldots,\, x_M(k,n-\Delta-L+1) \,\right]^T
\in \mathbb{C}^{ML}
$$

$\Delta$ 是**预测延迟**（典型 2–3 帧），$L$ 是**预测阶数 / tap 数**。第 $m$ 通道的晚期混响用该向量线性预测（每个通道一个滤波器 $\mathbf{g}_m(k) \in \mathbb{C}^{ML}$）：

$$
\hat{d}_m(k,n) = \mathbf{g}_m^H(k)\, \tilde{\mathbf{x}}(k, n-\Delta)
$$

**去混响输出 = 预测误差**：

$$
y_m(k,n) = x_m(k,n) - \mathbf{g}_m^H(k)\, \tilde{\mathbf{x}}(k, n-\Delta)
$$

### 3.3. 加权预测误差代价

滤波器由加权最小二乘求得——这就是 "Weighted Prediction Error" 这个名字的来源（预测误差按 $1/\lambda$ 加权）：

$$
J_m(k) = \sum_n \frac{\left|\, x_m(k,n) - \mathbf{g}_m^H(k)\, \tilde{\mathbf{x}}(k,n-\Delta) \,\right|^2}{\lambda(k,n)}
$$

其中 $\lambda(k,n) = E\left[\,|s_m(k,n)|^2\,\right]$ 是期望早期成分的**时变功率**（"方差归一化"中的方差，见 [[方向/AI语音/知识/基础概念/Time-Varying Variance（时变方差）|时变方差]]）。每个频点 $k$ 独立求解。

### 3.4. 闭式解（加权最小二乘正态方程）

对 $\mathbf{g}_m(k)$ 求导置零得到：

$$
\mathbf{R}(k) = \sum_n \frac{\tilde{\mathbf{x}}(k,n-\Delta)\,\tilde{\mathbf{x}}^H(k,n-\Delta)}{\lambda(k,n)},
\qquad
\mathbf{p}_m(k) = \sum_n \frac{\tilde{\mathbf{x}}(k,n-\Delta)\, x_m^*(k,n)}{\lambda(k,n)}
$$

$$
\mathbf{g}_m(k) = \mathbf{R}(k)^{-1}\, \mathbf{p}_m(k)
$$

关键性质：

- **$\mathbf{R}(k)$ 与通道 $m$ 无关**——所有通道共享同一次 $ML \times ML$ 矩阵求逆，每个频点只需求逆一次；$\mathbf{p}_m(k)$ 逐通道不同。
- 矩阵病态时加对角 loading：$\mathbf{R}(k) + \epsilon \mathbf{I}$。
- 加权后的 $\mathbf{R}$ 是 "weighted correlation"：方差归一化后各帧对统计的贡献同尺度。

### 3.5. EM 式交替估计

$\lambda(k,n)$ 未知，与 $\mathbf{g}_m(k)$ 互相依赖，用交替迭代（通常 2–3 轮）：

1. **初始化**：$\lambda^{(0)}(k,n)$ 取观测功率 $|x_m(k,n)|^2$（或 DNN 估计的功率谱，即 DNN-WPE）。
2. **E 步（估预测器）**：固定 $\lambda$，按第 4 节闭式解计算 $\mathbf{R}, \mathbf{p}_m, \mathbf{g}_m$。
3. **M 步（重估方差）**：计算去混响输出 $y_m(k,n)$，令 $\lambda(k,n) = |y_m(k,n)|^2$（可邻帧平滑，并加 floor 防除零）。
4. 重复步骤 2–3 至收敛。

统计视角：这等价于把早期成分建模为**零均值、时变方差 $\lambda(k,n)$ 的复高斯**，对 $\{\mathbf{g}_m, \lambda\}$ 做最大似然估计——**非平稳高斯假设正是 "加权" 的统计来源**。

### 3.6. 多通道预测的增益（MCLP vs SCLP）

为什么"用全部通道预测"比"只用自己的通道"（SCLP）更好：

- **共用混响源结构**：各通道的晚期混响是同一声源经不同 RIR 尾部的卷积——同一混响过程的多通道观测。MCLP 让预测器同时利用所有通道中的共同结构；SCLP 只能看到本通道的混响混叠。
- **参数空间更大**：MCLP 预测器每通道有 $ML$ 个系数，等效记忆更长，相同 $L$ 下残余混响更小。
- **理论性质**：MCLP 预测误差等价于**盲 MIMO 冲激响应缩短**（Yoshioka, Nakatani, Miyoshi, Okuno, *Generalization of Multi-Channel Linear Prediction Methods for Blind MIMO Impulse Response Shortening*, IEEE TASLP 19(2), 2011）——把目标成分之外的混响尾压缩；对单声源，输出更接近真实早期成分（innovation），语音损伤更小。
- **无失真性保持**：延迟 $\Delta$ 对所有通道统一生效，预测器都看不到当前帧的语音（子带内语音在 $\Delta$ 帧尺度上去相关），因此多通道参数空间增大不会引入语音消除。
- **计算共享**：$\mathbf{R}(k)$ 与输出通道无关——每频点一次 $ML \times ML$ 求逆服务全部 $M$ 个通道；SCLP 反而需 $M$ 次 $L \times L$ 求逆。MCLP 的主要代价是求逆维度 $O((ML)^3)$，实践中可接受。
- **实践结论**：原论文与后续均报告 SCLP 去混响不足，MCLP 是 WPE 的标准配置；CHiME 等系统前端全部使用多通道版本，低 SNR 下联合统计也更稳。

### 3.7. 两个关键设计（为什么延迟、为什么加权）

- **预测延迟 $\Delta$**：子带内语音自相关很长（窄带信号高度可预测），若从紧邻帧 $n-1, n-2, \ldots$ 直接预测，预测器会学会预测**语音本身**，把目标语音当混响消掉。延迟 $\Delta$ 帧后，预测器与当前语音去相关；而晚期混响跨更长时间仍可预测。$\Delta$ 太小 → 语音被挖空；$\Delta$ 太大 → 可预测的混响成分漏掉，去混响不充分。
- **方差归一化（加权）**：语音能量逐帧剧烈变化（浊音 / 清音 / 静音），若不加权，高能量帧会主导最小二乘解。除以 $\lambda(k,n)$ 把每帧贡献归一化到同一尺度，代价变为真正的"方差归一化预测误差"。

## 4. 参数口径

| 参数 | 典型值 | 影响 |
|---|---|---|
| 预测延迟 $\Delta$ | 2–3 帧（帧移 ~10 ms 时约 20–30 ms） | 去相关 vs 去混响能力的权衡 |
| 预测阶数 $L$ | 10–30 taps | 越大越能覆盖长混响尾，但求逆与过拟合风险上升 |
| 迭代次数 | 2–3 | 更多迭代收益递减 |
| 加权下界 | $\lambda$ 加 floor / 平滑 | 数值稳定关键，防除零 |
| 处理模式 | offline / block-online / frame-online | 延迟与质量权衡 |

## 5. 变体

- **MCLP vs SCLP**：原始 WPE 用全部通道联合预测（MCLP）；只用自己的通道预测（SCLP）效果明显更差——增益机制见第 6 节。
- **Online WPE**（`nara_wpe` 的 frame-online / block-online）：流式低延迟前端，代价是统计窗短、效果略降。
- **DNN-WPE**（NTT `dnn_wpe`）：用 DNN 估 $\lambda(k,n)$ 替代 EM 迭代，可流式、低 SNR 下更稳。
- **级联公式**：WPE 输出 $y_m(k,n)$ 再进 MVDR / GSC——CHiME 官方基线即 "WPE + beamforming"。

## 6. 为什么重要

- **挑战赛 / 工业前端标配**：CHiME-6 官方基线就是 WPE + beamforming；[[方向/AI语音/知识/基础概念/GSS（引导源分离）|GSS]] 系系统的常见组合是 WPE → GSS → beamforming → ASR。
- **去混响对下游收益明确**：混响（尤其晚期混响）是远场 ASR 的主要杀手之一，WPE 能在不依赖 DOA / 几何的前提下显著降 WER。
- **与神经方法正交**：WPE 是统计信号处理，可以自由叠加 DNN mask / neural beamformer / neural post-filter。

## 7. 使用注意

- **延迟与质量权衡**：WPE 需要较长预测窗，因果（online / block-online）版本延迟更大；低延迟场景要专门评估。
- **参数敏感**：预测阶数、延迟 tap 数、迭代次数、块长对结果影响明显，通常需按采样率和混响强度调。
- **强噪声下估计变差**：低 SNR 时语音方差和预测器估计会互相污染，先降噪或 DNN 辅助估计更稳。
- **开源实现**：Paderborn 的 `nara_wpe`（NumPy / TensorFlow，offline / block-online / frame-online）和 NTT 的 `dnn_wpe`（PyTorch，含 DNN-WPE）是两个主流选择。

## 8. 关键来源

- [NTT WPE 官方页（论文与 Matlab 实现）](https://www.rd.ntt/cs/team_project/media/signal/wpe/)
  - 内容定位：原始论文（Nakatani, Yoshioka, Kinoshita, Miyoshi, Juang, IEEE TASLP 18(7):1717–1731, 2010）的规范出处与官方实现。
  - 用途：算法机制、参数说明和离线 / block-online 处理参考。
  - 核验日期：2026-08-06
- [nara_wpe GitHub（Paderborn fgnt）](https://github.com/fgnt/nara_wpe)
  - 内容定位：Python 实现，offline / block-online / frame-online WPE，社区最常用。
  - 用途：复现与集成到前端的代码入口。
  - 核验日期：2026-08-06
- [dnn_wpe GitHub（NTT）](https://github.com/nttcslab-sp/dnn_wpe)
  - 内容定位：NTT 的 PyTorch 实现，含 DNN-WPE（DNN 估 PSD 的 online 变体）。
  - 用途：低延迟 / 在线场景的 DNN 增强版 WPE。
  - 核验日期：2026-08-06

## 9. 相关对象

- [[方向/AI语音/知识/基础概念/Time-Varying Variance（时变方差）|Time-Varying Variance]]：加权代价分母 λ 的统计模型，WPE "加权"的来源。
- [[方向/AI语音/知识/基础概念/Reverberation Modeling（混响建模）|Reverberation Modeling]]：混响主题的父级笔记，WPE 是去混响方法谱系的一员。
- [[方向/AI语音/知识/基础概念/MVDR（最小方差无失真响应）|MVDR]]：WPE 处理晚期混响、MVDR 处理空间噪声，两者常串联。
- [[方向/AI语音/知识/基础概念/Beamforming（波束形成）|Beamforming]]：WPE 常接在 beamforming 前后，处理反射声对方向性的破坏。
- [[方向/AI语音/知识/基础概念/GSS（引导源分离）|GSS]]：常见组合 WPE → GSS → beamforming → ASR。
- [[方向/AI语音/知识/基础概念/Array Audio Signal（阵列音频信号）|Array Audio Signal]]：多通道前端流程里的标准组件。
- [[方向/AI语音/模型/USDnet++|USDnet++]]：无监督 / 神经去混响的后续路线，可作对比。
- [[方向/AI语音/团队/NTT Speech Group（NTT 语音组）|NTT 语音组]]：WPE 的提出团队。

## 10. 待验证

- 实时语音 Agent 链路上，causal / block-online WPE 的延迟-质量权衡点在哪。
- WPE（+ DNN 辅助）与神经去混响（如 USDnet++）在真实会议场景的直接对比。
- 当前目标硬件上，`nara_wpe` 与 `dnn_wpe` 的算力与延迟差异。

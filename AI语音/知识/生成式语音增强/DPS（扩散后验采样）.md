---
title: DPS（扩散后验采样）
类型: 概念
相关主题:
  - 扩散模型
  - 生成式语音增强
  - 阵列信号
相关模型:
  - "[[方向/AI语音/模型/ArrayDPS-Refine]]"
  - "[[方向/AI语音/模型/Uni-ArrayDPS]]"
aliases:
  - DPS
  - Diffusion Posterior Sampling
  - diffusion posterior sampling
  - 扩散后验采样
  - 扩散后验采样引导
tags:
  - 类型/对象
  - 方向/AI语音
  - 主题/扩散模型
  - 主题/生成式语音增强
---
# DPS（扩散后验采样）

## 1. 身份

`DPS`（Diffusion Posterior Sampling，扩散后验采样）是 Chung、Sim、Ye（ICLR 2023，arXiv:2209.14687）提出的逆问题求解技术：用**预训练的无条件扩散先验**，通过**似然梯度引导**反向扩散过程，从后验 $p(x|y)$ 采样。它是 [[方向/AI语音/模型/ArrayDPS-Refine|ArrayDPS 家族]] 的机制核心——"扩散先验 + 引导"解决多通道盲逆问题的底座。

边界：DPS 不是扩散模型本身，而是**采样 / 引导技术**；它需要已知观测算子 $A$ 与测量噪声方差 $\sigma_y^2$（阵列场景里对应已知几何的空间混合算子 / 噪声协方差）；它也不是 CDiffuSE 式条件扩散（条件扩散把 $y$ 织进前向过程、需按任务训练，DPS 在推理时引导无条件先验、换任务不重训）。

起源在图像逆问题：超分辨率、去模糊、inpainting、CT 稀疏角度 / MRI 欠采样重建、相位恢复（$A = |\mathcal{F}(\cdot)|$ 非线性）；语音与阵列是其后的应用域。

## 2. 核心公式

**逆问题**：$y = A(x) + n$，$n \sim \mathcal{N}(0, \sigma_y^2 I)$，$A$ 为（可非线性）观测算子。

**后验 score 近似**（把先验 score 与似然梯度相加）：

$$
\nabla_{x_t} \log p_t(x_t | y) \approx s_\theta(x_t, t) + \nabla_{x_t} \log p_t(y | x_t)
$$

**[[方向/AI语音/知识/基础概念/Tweedie（Tweedie 公式）|Tweedie 一步估计]]**（由 score 网络反推干净估计）：

$$
\hat{x}_0(x_t) = \frac{x_t - \sqrt{1-\bar{\alpha}_t}\,\varepsilon_\theta(x_t, t)}{\sqrt{\bar{\alpha}_t}}
$$

**似然近似**（以 $\hat{x}_0$ 代替 $x_0$ 代入测量模型，并对 $x_t$ 微分——Jacobian 近似）：

$$
\nabla_{x_t} \log p(y | \hat{x}_0(x_t)) \approx -\frac{1}{\sigma_y^2}\, \nabla_{x_t} \left\| y - A(\hat{x}_0(x_t)) \right\|^2
$$

**反向更新**：每步反向扩散之后加一个引导项：

$$
x_{t-1} \leftarrow \text{reverse\_step}(x_t) \;-\; \zeta\, \nabla_{x_t} \left\| y - A(\hat{x}_0(x_t)) \right\|^2
$$

$\zeta$ 是引导步长（超参），$\sigma_y^2$ 控制似然置信度。

### 执行拓扑

- 反向采样是多步串行迭代：
  其中 $x_k$ 为第 $k$ 个反向采样状态，$y$ 为观测，$F_k$ 为第 $k$ 步更新算子，$K$ 为总采样步数。
  $$
  x_{k-1}=F_k\!\left(x_k,\nabla_x\log p(y\mid x_k)\right),\quad k=K,\ldots,1
  $$
- 每一步内部的网络前向可以并行处理 batch / 频点 / 通道，但采样步之间不能并行执行。
- 因此 DPS 的“生成式”不等于一次前向，也不等于严格自回归 token 生成。

## 3. 算法流程

1. 用 score 网络从当前 $x_t$ 预测噪声 $\varepsilon_\theta(x_t, t)$（无条件预测）。
2. [[方向/AI语音/知识/基础概念/Tweedie（Tweedie 公式）|Tweedie 公式]]一步反推干净估计 $\hat{x}_0(x_t)$。
3. 把 $\hat{x}_0$ 代入已知退化算子 $A$，算测量残差损失 $\mathcal{L} = \| y - A(\hat{x}_0) \|^2$。
4. 对 $x_t$ 自动微分求 $\nabla_{x_t} \mathcal{L}$（穿透 $\hat{x}_0$ 网络），按步长 $\zeta$ 校正 $x_t$。
5. 执行常规反向扩散步（DDIM / SDE）走向 $x_{t-1}$，重复至 $t=0$。

## 4. 关键性质

- **plug-and-play**：任意观测算子 $A$ 都可用，无需针对任务 / 阵列几何重训——先验只需在干净语音上无监督训练一次。
- **training-free 精修**：判别式输出作为初始 / 引导，DPS 把它推回干净语音先验支持的流形（ArrayDPS-Refine 的定位）。
- **不稳定性**：Jacobian 近似在扩散后期失真，引导步长 $\zeta$ 与 $\sigma_y$ 需要调；欠约束逆问题下容易"绕圈"或过拟合噪声。
- **代价**：每步需额外一次前向 + 对 $\hat{x}_0$ 的微分，采样成本高于纯条件扩散。

## 5. 与条件扩散（SGMSE+ 类）的对比

| 维度 | DPS | 条件扩散（[[方向/AI语音/模型/SGMSE+]] / CDiffuSE） |
|---|---|---|
| $y$ 的进入方式 | 推理时似然引导（无条件先验） | 训练时织进前向过程（条件先验） |
| 换任务 / 换观测算子 | 不重训（改 $A$ 与 $\sigma_y$） | 需按任务重训 |
| 需要知道 $A$ | 是（显式） | 否（隐式学进条件分布） |
| 采样成本 | 高（引导项 + 微分） | 中 |

## 6. 在语音增强 / 阵列里的应用

- **[[方向/AI语音/模型/ArrayDPS|ArrayDPS]]**（2025，无监督盲分离）：白噪声假设下的 DPS 初版（[arXiv:2505.05657](https://arxiv.org/abs/2505.05657)）。
- **[[方向/AI语音/模型/ArrayDPS-Refine|ArrayDPS-Refine]]**（2026）：估噪声 SCM 后代入 DPS 似然，training-free 精修判别式多通道增强输出。
- **[[方向/AI语音/模型/Uni-ArrayDPS|Uni-ArrayDPS]]**（2026）：噪声 SCM 显式建模（比白噪声假设更贴近彩色噪声环境），统一增强 + 分离。
- **Diffiner**（Sony，单通道）：同思路的单通道前驱之一（无独立笔记）。
- 语音里 $A$ 的常见形态：多通道空间混合（几何已知）、下采样 / 带宽限制、mask 化（inpainting）。

## 7. 相关对象

- [[方向/AI语音/模型/ArrayDPS-Refine|ArrayDPS-Refine]]：DPS 在"判别式输出精修"上的应用。
- [[方向/AI语音/模型/Uni-ArrayDPS|Uni-ArrayDPS]]：DPS + 噪声 SCM 似然的统一增强 / 分离。
- [[方向/AI语音/知识/生成式语音增强/SE Generative Prior（语音增强生成先验）|SE Generative Prior]]：扩散先验的分类框架（DPS 属于"干净语音先验 + 测量引导"路线）。
- [[方向/AI语音/知识/生成式语音增强/扩散模型与语音|扩散模型与语音]]：扩散谱系全景。
- [[方向/AI语音/模型/SGMSE+|SGMSE+]]：条件扩散对照路线。

## 8. 待验证

- $\zeta$ / $\sigma_y$ 对阵列失配（几何误差、噪声协方差估计误差）的稳健性。
- DPS 引导 vs 条件扩散在语音增强上的量化差距（质量 / 步数 / 幻觉率）。
- 低 SNR 下 DPS 的幻觉风险（似然过拟合噪声 vs 先验脑补）。
- 采样比无条件扩散慢 **2~3 倍**（Gemini 摘要的量化，需对语音场景复测）。
- "DDRM / PnP-ADMM 只能处理线性退化算子"（需查 DDRM 原文核实；相位恢复等非线性案例见 [Chung 2022 补充实验](https://arxiv.org/abs/2209.14687)）。

# 详细
**DPS（Diffusion Posterior Sampling，扩散后验采样）** 是近年来在计算机视觉与逆问题求解（Inverse Problems）领域极其重要的一项技术。

  

它巧妙地将**预训练好的无条件扩散模型（Diffusion Model）** 作为通用先验（Prior），在**无需重新训练或微调大模型**的前提下，仅通过**修改采样的导向梯度**，就能高质量地解决各类图像恢复与重建任务（如图像去噪、去模糊、超分辨率、修复缺失区域、CT/MRI 磁共振医学成像重建等）。

  

## 9. 问题背景：什么是逆问题与后验采样？

在许多实际场景中，我们无法直接获取清晰图像 $x$，只能观察到经过退化后的测量数据 $y$：

  

$$y = \mathcal{A}(x) + n$$

- $x$：我们想要恢复的原始清晰图像（未知的**真实信号**）。
    
      
    
- $\mathcal{A}(\cdot)$：退化测量算子（比如**下采样、高斯模糊、掩码遮挡**，甚至是复杂的**非线性投影**）。
    
      
    
- $n$：随机噪声（如高斯白噪声）。
    
      
    
- $y$：我们观测到的坏图或测量数据。
    
      
    

**求解逆问题的核心，就是从观测数据 $y$ 中推断出真实的 $x$。**

  

在贝叶斯统计框架下，这属于求**后验概率分布 $p(x\vert{}y)$**：

  

$$p(x\vert{}y) = \frac{p(y\vert{}x) p(x)}{p(y)} \propto \underbrace{p(y\vert{}x)}_{\text{似然项 (Likelihood)}} \cdot \underbrace{p(x)}_{\text{先验项 (Prior)}}$$

- **先验项 $p(x)$：** 图像应该长什么样？（即符合真实自然图像分布）。
    
      
    
- **似然项 $p(y\vert{}x)$：** 假设真实图像是 $x$，它经过 $\mathcal{A}(x)$ 后与观测值 $y$ 的吻合程度。
    
      
    

在扩散模型出现前，求解 $p(x\vert{}y)$ 非常困难；而 DPS 的出现，为后验采样提供了一个极具优雅性的数学解法。

  

## 10. DPS 的核心思想与数学逻辑

扩散模型（如 DDPM/DDIM）本质上是在学习自然图像的梯度场（Score Function） $\nabla_{x_t} \log p(x_t)$，它知道如何将噪声一步步变成清晰图像，这对应了**先验项 $p(x)$**。

  

如果要进行条件生成（即引入 $y$），根据贝叶斯法则，扩散模型每一步更新需要的Score为：

  

$$\nabla_{x_t} \log p(x_t\vert{}y) = \underbrace{\nabla_{x_t} \log p(x_t)}_{\text{无条件扩散模型评分 (Unconditional Score)}} + \underbrace{\nabla_{x_t} \log p(y\vert{}x_t)}_{\text{观测似然导向项 (Likelihood Score)}}$$

### 10.1. 难点在哪？

前一项 $\nabla_{x_t} \log p(x_t)$ 可以直接用预训练好的无条件扩散模型输出。

**真正的难点在后一项： $\nabla_{x_t} \log p(y\vert{}x_t)$！**

因为测量算子 $\mathcal{A}(x)$ 是建立在**清晰图像 $x$** 上的，而扩散过程中的 $x_t$ 是充满高斯噪声的破坏状态，我们**无法直接对带噪图 $x_t$ 计算似然 $\mathcal{A}(x_t)$**。

  

### 10.2. DPS 的关键破局点（近似估计 $\hat{x}_0$）

DPS 的作者（Chung et al., 2022）提出了一个极其优雅且高效的**一阶近似**方法：

  

1. **借助 Tweedie 公式估计清晰图像：**
    
    在扩散过程的第 $t$ 步，利用当前带噪图 $x_t$ 和网络预估的噪声 $\epsilon_\theta(x_t, t)$，可以直接**一步预测**出对应的清晰图像 $\hat{x}_0(x_t)$：
    
      
    
    $$\hat{x}_0(x_t) = \frac{1}{\sqrt{\bar{\alpha}_t}} \left( x_t - \sqrt{1 - \bar{\alpha}_t} \cdot \epsilon_\theta(x_t, t) \right)$$
    
2. **在估计的清晰图像上计算似然导向：**
    
    既然有了估计的清晰图 $\hat{x}_0$，就可以直接代入测量算子 $\mathcal{A}$，计算预测测量值与真实观测值 $y$ 之间的残差，并对 $x_t$ 求梯度：
    
      
    
    $$\log p(y\vert{}x_t) \approx -\frac{1}{2\sigma^2} \Vert{} y - \mathcal{A}(\hat{x}_0(x_t)) \Vert{}^2_2$$
    
    $$\nabla_{x_t} \log p(y\vert{}x_t) \approx -\zeta_t \cdot \nabla_{x_t} \Vert{} y - \mathcal{A}(\hat{x}_0(x_t)) \Vert{}^2_2$$
    

> **通俗理解：** 扩散模型在每一步噪声更新时，先“窥探”一眼按照当前方向生成出来的真实图 $\hat{x}_0$ 会长什么样；然后看这张 $\hat{x}_0$ 经过退化算子 $\mathcal{A}$ 后跟观测图 $y$ 差了多少，再利用**自动微分（Auto-Differentiation）** 反向求导，把这个偏差拉回到 $x_t$ 上，以此修正扩散的生成方向。
> 
>   

## 11. DPS 的采样算法流程

在实际采样迭代（如基于 DDNM / DDIM / SDE）的每一步中，DPS 做了如下操作：

  

**1.无条件预测 (Predict Unconditional Score)：**

将当前的带噪图像 $x_t$ 输入预训练好的扩散模型，预测当前步的噪声 $\epsilon_\theta(x_t, t)$。

  

**2.推导重建清晰图 (Estimate Clean Image)：**

利用 Tweedie 公式，根据 $x_t$ 和 $\epsilon_\theta(x_t, t)$ 计算出当前状态对应的预估清晰图像 $\hat{x}_0$。

  

**3.计算物理一致性损失 (Compute Measurement Loss)：**

将 $\hat{x}_0$ 输入已知物理/测量退化函数 $\mathcal{A}$，计算重构误差损失：

  

  

$$\mathcal{L} = \Vert{} y - \mathcal{A}(\hat{x}_0) \Vert{}_2^2$$

**4.求导并校正采样方向 (Backprop & Gradient Guidance)：**

对 $x_t$ 求损失 $\mathcal{L}$ 的梯度 $\nabla_{x_t} \mathcal{L}$，并用该梯度更新 $x_t$，将生成的轨迹拉向符合测量数据 $y$ 的方向：

  

  

$$x_t \leftarrow x_t - \zeta_t \cdot \nabla_{x_t} \mathcal{L}$$

**5.执行标准扩散退步 (Diffusion Step)：**

结合常规的扩散模型采样公式（如 DDIM），从 $x_t$ 走向 $x_{t-1}$，直到 $t=0$ 得到最终修复完好的图像 $x_0$。

  

## 12. DPS 的核心优势与局限性

|**优势 (Pros)**|**局限性 (Cons)**|
|---|---|
|**无需重新训练 (Plug-and-Play)：** 只要有一个通用的图像生成扩散模型，就可以解决**任意**已知算子 $\mathcal{A}$ 的逆问题。|**计算开销高 (Double Backprop)：** 算法每一步都需要计算 $\nabla_{x_t} \mathcal{A}(\hat{x}_0(x_t))$，这意味着在生成过程中需要穿透神经网络计算二阶导数/反向传播，推理速度比无条件采样慢 2~3 倍。|
|**支持非线性算子：** 之前的许多方法（如 PnP-ADMM、DDRM）只能处理线性矩阵退化（如线性模糊、下采样），而 DPS **天然支持非线性退化算子 $\mathcal{A}$**（如相干成像、相位恢复、非线性高斯模糊等）。|**步长参数 sensitive（$\zeta_t$ 敏感）：** 似然项梯度的缩放系数 $\zeta_t$ 需要仔细调参，否则容易出现过度校正（画面产生噪声纹理）或引导不足（不符合测量约束 $y$）。|
|**数据一致性强 (Data Consistency)：** 生成的图像不仅视觉逼真，且严格符合测量限制 $y$。||

## 13. 常见应用场景

DPS 及其衍生算法目前被广泛应用于：

  

1. **图像超分辨率 (Super-resolution) 与 去模糊 (Deblurring)：** 算子 $\mathcal{A}$ 为下采样或卷积核。
    
      
    
2. **图像补全 (Inpainting)：** 算子 $\mathcal{A}$ 为掩码像素遮挡矩阵。
    
      
    
3. **医学影像重建 (Medical Imaging Reconstruction)：** 例如在 **CT 稀疏角度重建**（$\mathcal{A}$ 为 Radon 变换）或 **MRI 快速成像**（$\mathcal{A}$ 为傅里叶欠采样）中，用极少量的射线暴露或扫描时间，恢复出清晰无伪影的医学图像。
    
      
    
4. **科学计算与相位恢复 (Phase Retrieval)：** 算子 $\mathcal{A}(x) = \vert{}\mathcal{F}(x)\vert{}$ 为非线性的傅里叶模值测量。
    
      
    

## 14. 总结

**DPS（Diffusion Posterior Sampling）** 的本质是：**利用预训练扩散模型作为“画师”（保障生成质量），同时利用已知退化过程 $\mathcal{A}$ 的反向梯度作为“监工”（保障符合测量约束 y）。** 通过将监工的反馈通过自动微分注入到画师的每一步描绘中，实现优雅且高质量的逆问题求解。

# 与DDPM等的区别
简单来说，**DDPM 和 DDIM 是“基础底座”（基础生成算法），而 DPS 是基于它们开发的“高级应用套件”（专用于解决图像恢复等逆问题）。**

  

它们之间的关系可以从 **定位与分类、继承与调用、底层机理** 三个层级来厘清：

  

### 14.1. 三者的定位与分类

|**算法名称**|**角色分类**|**核心目的**|**简要理解**|
|---|---|---|---|
|**DDPM**<br><br>  <br>  <br><br>_(Denoising Diffusion Probabilistic Models)_|**基础生成模型**<br><br>  <br>  <br><br>_(先驱/基石)_|**无条件生成**<br><br>  <br>  <br><br>（从纯高斯噪声凭空生成图像）|奠定了扩散模型的数学基础。通过 1000 步 Markov 链去噪，生成质量高，但**速度极慢**。|
|**DDIM**<br><br>  <br>  <br><br>_(Denoising Diffusion Implicit Models)_|**采样加速算法**<br><br>  <br>  <br><br>_(DDPM 的进阶版)_|**无条件生成**<br><br>  <br>  <br><br>（大幅加速生成过程）|改写了 DDPM 的采样概率推导，摒弃了 Markov 假设。可以使用相同训练好的模型，将采样步数从 **1000 步压缩到 20~50 步**，且支持确定性轨迹。|
|**DPS**<br><br>  <br>  <br><br>_(Diffusion Posterior Sampling)_|**条件引导算法**<br><br>  <br>  <br><br>_(基于扩散模型的应用算法)_|**求解逆问题 / 图像修复**<br><br>  <br>  <br><br>（如去模糊、超分、CT重建）|**并不重新训练模型**。它直接拿预训练好的 DDPM/DDIM 作为“底座”，在采样迭代过程中**注入额外的测量梯度**，引导生成符合特定条件（如破损图片 $y$）的结果。|

### 14.2. 代码与运行时的继承调用关系

在实际代码实现和运行过程中，它们是**组合嵌套**的关系：

  

```
                    ┌──────────────────────────────────────────────────┐
                    │                      DPS                         │
                    │         (Diffusion Posterior Sampling)           │
                    └────────────────────────┬─────────────────────────┘
                                             │
                          采样迭代过程中，调用底座模型预测噪声
                                             │
                                             ▼
                    ┌──────────────────────────────────────────────────┐
                    │               DDPM / DDIM 预训练模型             │
                    │        (负责提供基础的自然图像特征先验 p(x))          │
                    └──────────────────────────────────────────────────┘
```

1. **DPS 依靠 DDPM/DDIM 提供“画功”（先验分布）：**
    
    DPS 本身**不包含权重参数**，它只是一种“采样策略/导向算法”。没有预训练好的 DDPM 或 DDIM 提供图像去噪的能力，DPS 就完全无法工作。
    
      
    
2. **DPS 可以选择 DDPM 或 DDIM 作为底座采样器：**
    
      
    - 如果 DPS 搭配 **DDPM** 进行后验采样，生成质量高，但需要迭代几百到上千步，速度较慢。
        
          
        
    - 如果 DPS 搭配 **DDIM** 进行后验采样，可以在几十步内快速完成对破损图像/模糊图像的修复。
        
          
        

### 14.3. 数学与采样更新逻辑的关系

如果看每一步采样迭代的数学公式，DPS 是在 DDPM/DDIM 的更新步骤上**多加了一个“修正项”**：

  

#### 14.3.1. 🔹 纯 DDPM / DDIM 采样步骤：

$$x_{t-1} = \text{Sampler\_Step}(x_t, \epsilon_\theta(x_t, t))$$

> **逻辑：** 仅根据当前带噪图 $x_t$ 和网络预测的噪声 $\epsilon_\theta$，向着“变成一张任意的清晰图片”走一步。
> 
>   

#### 14.3.2. 🔹 DPS (结合 DDIM/DDPM) 采样步骤：

$$x_t' = x_t - \underbrace{\zeta_t \cdot \nabla_{x_t} \Vert{} y - \mathcal{A}(\hat{x}_0(x_t)) \Vert{}^2_2}_{\text{DPS 独有的测量梯度修正项}}$$

$$x_{t-1} = \text{Sampler\_Step}(x_t', \epsilon_\theta(x_t', t))$$

> **逻辑：**
> 
>   
> 
> 1. 先用 **DPS 的物理残差梯度** 把当前状态 $x_t$ 往“符合观察数据 $y$”的方向**拉一把**，变成 $x_t'$；
>     
>       
>     
> 2. 再把 $x_t'$ 送入 **DDPM/DDIM 的基础采样步骤** 中，正常去噪走一步。
>     
>       
>     

### 14.4. 总结比喻

- **DDPM** 就像**慢速、高画质的画画基本功**。
    
      
    
- **DDIM** 就像**快速、高效的画画基本功**（画得更快，技法更先进）。
    
      
    
- **DPS** 就像**一位客户给画家提出了定制要求**（“请帮我把这张残破的古画修好”）。画家（DDPM/DDIM）利用自己的基本功，一边画一边根据客户给的残画（DPS 的梯度导向）进行对比和修正，最终完成修复作品。

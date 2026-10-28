---
title: CI-Spatial
类型: 模型
发表时间: 2025-01
时间依据: arXiv 首次提交日（v1 2025-01-24）；期刊版 Scientific Reports 16:2255（2025-12）
任务:
  - 语音分离
方法范式:
  - 判别式
开放状态:
  - paper
  - code
aliases:
  - CI-Spatial
  - "Leveraging Spatial Cues from Cochlear Implant Microphones to Efficiently Enhance Speech Separation in Real-World Listening Scenes"
  - "Leveraging spatial cues from cochlear implant microphones to efficiently enhance speech separation in naturalistic listening scenes"
  - 人工耳蜗麦克风空间线索语音分离
  - CI 麦克风空间线索分离
tags:
  - 类型/对象
  - 方向/AI语音
  - 任务/语音分离
  - 主题/助听
  - 主题/双耳听觉
---

# CI-Spatial

## 0. 背景

**问题现场**：人工耳蜗（CI）用户面对真实嘈杂场景中的双说话人重叠，需要在低算力 CI 麦克风设备上做语音分离；CI 设备关心"值不值得上双耳、值不值得为显式线索付参数与延迟"的硬件取舍。

**CI-Spatial 的切入点**：不做阵列几何/波束形成，直接把 1–2 个 CI 麦克风通道送进多通道改编的 SuDoRM-RF 时域分离，并以隐式空间线索（波形自带）与显式 IPD（辅助输入）的成对配置，量化两类线索各自对分离的贡献。

## 1. 身份

`CI-Spatial`（*Leveraging Spatial Cues from Cochlear Implant Microphones to Efficiently Enhance Speech Separation in Real-World Listening Scenes*）是 Radboud University / Leiden UMC / Columbia Zuckerman Institute / TU Delft（Feyisayo Olalere、Kiki van der Heijden、Christiaan H. Stronks、Jeroen Briaire、Johan H. M. Frijns、Marcel van Gerven）提出的**人工耳蜗（CI）麦克风真实场景双说话人语音分离**方法（arXiv:2501.14610v1，2025-01-24，cs.SD 交叉 cs.AI / eess.AS；期刊版 *Scientific Reports* 16:2255，2025-12）；论文未给系统命名，`CI-Spatial` 是本 vault 的检索名。

它不做阵列几何 / 波束形成，直接把 1–2 个 CI 麦克风通道送进**多通道 SuDoRM-RF** 做时域分离，以**隐式空间线索**（波形自带、不显式提取）与**显式 IPD**（算好作辅助输入）的成对配置，量化两类线索各自对双说话人分离的贡献（机制见「核心机制」）。

边界：设备为 Advanced Bionics 耳背式（BTE）人工耳蜗，**每侧 3 麦**（Front / Back / T-mic）；同侧两麦仅隔数厘米、跨耳基线约头宽，不构成规则阵列，T-mic 贴近耳道口、线索更接近正常耳，而 BTE 前后麦更易受环境噪声影响；单侧（unilateral）与双耳（bilateral）是两种配置；它把线索当**输入**，与惩罚双耳增强输出破坏线索的 [[方向/AI语音/模型/Binaural Cue Preservation Loss（双耳线索保持损失）|Binaural Cue Preservation Loss]] 方向相反（区别见「相关对象」）；"real-world" 指仿真的空间化 + 混响声学场景，非真实录音；严格任务是**双说话人分离**（WSJ0-2mix 系）而非单通道增强，且无听损 / CI 用户主观可懂度验证。

## 2. 核心机制

```text
WSJ0-2mix 两条单人语音
  -> 自建空间化管线：Pyroomacoustics 仿真 RIR（500 房间）× CI-HRTF（KEMAR + Advanced Bionics CI）
  -> BRIR 与语音卷积后相加 -> 空间化、带混响的双说话人混合 y ∈ R^{C×T}（C = 1 或 2）
  -> [显式线索分支] STFT 后按双侧通道对算 IPD(t,f) = ∠( y_c1(t,f) / y_c2(t,f) )，均值归一化
  -> SuDoRM-RF（多通道改编）：Conv1D encoder -> 隐表征 R_l
        · 仅波形配置：separator 直接在 R_l 上学掩码 M
        · 加 IPD 配置：concat(IPD, R_l) 后学掩码 M
  -> M ⊙ R_l -> decoder -> 两条干净语音波形（训练目标 = dry，无混响）
```

### 2.1. 隐式空间线索（implicit）

论文措辞：隐式空间线索是"cues that are inherently present in the data and can be learned by the model, but which are not manually extracted as an auxiliary input feature"，例子即通道间电平差（ILD）与通道间相位差（IPD），它们可以从两个及以上麦克风通道的比较中提取。本页把它做成三档强度：

- **弱**：单通道（单侧一台 CI 的 T-mic）。通道内只剩两个说话人的电平/频谱差异，无法做通道间比较；论文明确说这是"weak implicit spatial cues"。
- **中**：单侧双通道（同一台 CI 的 T-mic + Back-mic），可做通道间比较，但两麦都在同一设备上。
- **强**：双耳双通道（左耳 CI 一通道 + 右耳 CI 一通道），通道间隔着头部，线索最强。

### 2.2. 显式空间线索（explicit = IPD）

论文措辞：显式空间线索是"manually calculated spatial features added as auxiliary input to the model"。本文只用了 **IPD** 一种：先做 STFT（hop = 8 samples、512 个频点、窗长 512 samples），按 [Chen et al. 2018] 的方式算 IPD，**均值归一化**后用 PyTorch 的 concat 拼到混合波形的编码隐表征上。论文写明 IPD 在**双侧通道**之间计算（左耳 CI 的一个通道 × 右耳 CI 的一个通道），由此得到"strong explicit spatial cues"。

### 2.3. 七个输入配置与对照隔离

论文用 7 个配置把两类线索拆开（Fig. 3B / Table I）：

- **隐式线索的净贡献**：固定声学场景与其余训练设置，只把波形通道数从 1（单侧）→ 2（单侧）→ 2（双耳）递增，比较 Table I 第 2–4 行；另设非空间干场景（第 1 行）作为能力上界参照。
- **显式线索的净贡献**：在每种波形配置上做"波形 vs 波形 + IPD"的成对比较（Table I 第 2–4 行 vs 第 5–7 行），三种波形配置各一对。
- 线索强度用颜色/饱和度编码（Fig. 3B）：蓝 = 仅隐式，绿 = 隐式 + 显式，饱和度越高线索越强；单通道干场景为 "None"。
- 代价同时被记录：加 IPD 使参数量 2.6M → 3.8M（+46%），且 IPD 需要 STFT，延迟上升——论文强调这正是 CI 这类设备关心的取舍。
- 另有两条操控变量用来验证"模型是否真的在用空间线索"：说话人**分离角**（0°/15°/30°/60°/90°）与**性别配对**（F-F / M-M / F-M）。

### 2.4. 模型与训练

- **骨干**：SuDoRM-RF（Tzinis et al. 2021），时域 encoder–separator–decoder，分离靠隐表征上的掩码；本工作把它改成双通道输入。配置沿用原实现：512 输入通道、128 输出通道、16 个 U-blocks、upsampling depth = 4、encoder kernel = 21、512 个编码基函数、全局层归一化（gLN）。
- **训练**：100 epochs、batch size 4、early stopping（patience = 10，minimum delta = 0.1）、Adam（lr 1e-3，每 50 epoch 衰减 0.2）、负 PIT 损失。
- **目标信号**：**dry（无混响）干净语音**——论文给的理由有两条：对听损 / CI 用户，干信号更有利于言语理解；且 dry target 是单通道分离文献的惯例，便于横向比较。
- **数据**：WSJ0-2mix（20k 训练 / 5k 验证 / 3k 测试）为底料，用自建管线做空间化（见第 5 节）。

## 3. 核心公式

**1. 显式空间线索（IPD，论文式 (1)）：**

$$\mathrm{IPD}(t,f) \coloneq \angle\left(\frac{y_{c_1}(t,f)}{y_{c_2}(t,f)}\right)$$

$y_{c_1}$、$y_{c_2}$ 为两个麦克风通道的 STFT（论文中取左耳 CI 与右耳 CI 各一通道），$\angle(\cdot)$ 取复比值的相位角；IPD 均值归一化后与混合波形的编码表征拼接。

**2. 训练损失（论文式 (2)，SI-SDR）：**

$$\mathrm{SI-SDR} \coloneq -10\log_{10}\frac{\lVert t_{\text{target}}\rVert_2^2}{\lVert e_{\text{noise}}\rVert_2^2},\qquad e_{\text{noise}} = \text{估计目标} - t_{\text{target}}$$

论文印刷形式如上（负号、无最优尺度项）；训练时用**负 PIT SI-SDR** 解排列问题，评测另取 SI-SDRi（相对未处理混合的 SI-SDR 提升）。印刷符号与 [Le Roux et al. 2019] 标准口径的关系见「9. 待验证」。

## 4. 结果口径

**Table I（7 个输入配置；8 kHz，2 说话人，训练目标为 dry）：**

| 声学场景 | 输入特征 | 空间信息 | 参数量 | SI-SDR | SI-SDRi | STOI | PESQ |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 非空间、干 | 单通道波形 | 无 | 2.6M | 12.96 | 12.96 | 0.89 | 2.97 |
| 空间、混响 | 单通道波形（单侧） | 隐式（弱） | 2.6M | 2.66 | 27.01 | 0.70 | 1.81 |
| 空间、混响 | 双通道（单侧） | 隐式（中） | 2.6M | 2.74 | 27.99 | 0.73 | 1.88 |
| 空间、混响 | 双通道（双耳） | 隐式（强） | 2.6M | 3.69 | 28.05 | 0.77 | 2.02 |
| 空间、混响 | 单通道 + IPD | 隐式 + 显式 | 3.8M | 2.74 | 27.09 | 0.74 | 1.92 |
| 空间、混响 | 双通道单侧 + IPD | 隐式 + 显式 | 3.8M | 4.16 | 29.41 | 0.78 | 2.09 |
| 空间、混响 | 双通道双耳 + IPD | 隐式 + 显式 | 3.8M | 4.36 | 28.72 | 0.78 | 2.12 |

- **真实场景的能力落差**：同一模型从干场景换到空间混响场景（同为单通道），SI-SDR 12.96 → 2.66，论文称下降 79.4%；两个场景的混合基线 SI-SDR 分别是 0 dB 与 −24.26 dB，这解释了 SI-SDRi（12.96 → 27.01）与 SI-SDR 反向的表象。
- **隐式线索**：单通道 → 单侧双通道 → 双耳双通道 = SI-SDR 2.66 → 2.74 → 3.69；论文口径"双耳 vs 单通道：+38.7% SI-SDR、+10% STOI、+11.6% PESQ"。
  - 口径注记：同句还写"双耳 vs 单侧双通道：+3.0% SI-SDR、+4.3% STOI、+3.9% PESQ"，但按 Table I 反算，这三个百分比对应的是**单侧双通道 vs 单通道**（2.66→2.74、0.70→0.73、1.81→1.88），而双耳 vs 单侧双通道实为 +34.7% SI-SDR。原文括号归属与表格数值不一致，引用时以 Table I 为准。
- **显式线索（IPD）增益，三对逐一比较**：
  - 单侧双通道：**+51.8% SI-SDR、+6.8% STOI、+11.1% PESQ**（2.74→4.16、0.73→0.78、1.88→2.09）——增益最大；
  - 双耳双通道：+18.2% SI-SDR、+1.3% STOI、+5.0% PESQ（3.69→4.36、0.77→0.78、2.02→2.12）；
  - 单通道：+3.0% SI-SDR、+5.7% STOI、+6.1% PESQ（2.66→2.74、0.70→0.74、1.81→1.92）——增益最小。
  - 即**隐式线索越弱，显式线索越有用**（论文的核心结论）；反过来，隐式线索已经很强时，多花的 46% 参数量主要买 STOI/PESQ 的小幅提升。
- **分离角效应（Table II，Kruskal-Wallis H，FDR 校正）**：分离角对 SI-SDR 有显著影响的配置 = 全部含 IPD 的配置 + 隐式线索强的双耳配置；隐式弱/中的两个配置不显著。

  | 输入配置 | χ²(4) | 显著性 |
  | --- | --- | --- |
  | 单通道波形 | 5.07 | 0.31 |
  | 双通道（单侧） | 4.82 | 0.31 |
  | 双通道（双耳） | 55.6 | 1.4e-8*** |
  | 单通道 + IPD | 11.9 | 0.03* |
  | 双通道单侧 + IPD | 28.8 | 1.7e-5*** |
  | 双通道双耳 + IPD | 43.1 | 3.0e-8*** |

  显著配置的事后两两比较显示 SI-SDR 随分离角增大而提高；单通道 + IPD 虽整体显著，但事后比较没有出现显著的两两差异（论文据此称其角度效应弱）。
- **空间重叠（0°）说话人也受益**：论文指出，只要训练数据里含空间线索，0° 重叠说话人的分离效果也相对无空间线索配置提升（Fig. 4 灰虚线对照）。论文自己没有定论，给出的解释是**假设**：模型在空间学习中同时学到了与频率相关的混响特性，从而强化了频谱线索。
- **性别配对（Table III，小角度 = 0°/15°，大角度 = 60°/90°）**：同性别配对（F-F / M-M）从大分离角得到的 SI-SDR 提升大于异性别（F-M）。

  | 配置 | 性别配对 | 小角度 SI-SDR | 大角度 SI-SDR | 提升 | χ²(1) | 显著性 |
  | --- | --- | --- | --- | --- | --- | --- |
  | 双通道（双耳） | F-F | 2.77 | 3.53 | 27.42% | 14.30 | 2.0e-4*** |
  | 双通道（双耳） | M-M | 3.50 | 4.13 | 18.00% | 24.93 | 1.8e-6*** |
  | 双通道（双耳） | F-M | 3.55 | 3.96 | 11.55% | 13.21 | 0.002** |
  | 双通道单侧 + IPD | F-F | 3.17 | 3.90 | 23.02% | 11.28 | 0.001** |
  | 双通道单侧 + IPD | M-M | 4.17 | 4.67 | 12.00% | 12.98 | 0.001** |
  | 双通道单侧 + IPD | F-M | 4.08 | 4.28 | 4.90% | 3.04 | 0.1 |
  | 双通道双耳 + IPD | F-F | 3.07 | 4.08 | 32.90% | 22.54 | 6.2e-6*** |
  | 双通道双耳 + IPD | M-M | 4.36 | 4.82 | 10.55% | 12.80 | 6.0e-4*** |
  | 双通道双耳 + IPD | F-M | 4.26 | 4.60 | 7.98% | 9.74 | 0.002** |

- **目标口径的副产品**：以 dry 为目标使模型同时被推向分离 + 去混响，但论文承认分离输出里**仍残留大量混响**，并指出需要更多"分离 + 去混响"联合方案的研究。

## 5. 测试基准与性能

**测试基准**（论文 §II–III，无公开 benchmark，全部为自建仿真数据）：

- **数据**：WSJ0-2mix（20k / 5k / 3k）作底料，vault 内对应的噪声/混响版本见 [[方向/AI语音/数据集/WHAM|WHAM]]（WHAM! / WHAMR!）。空间化管线：500 个鞋盒房间（4×4×2.5 m ~ 10×10×5 m，覆盖教室/会议室/餐厅尺度），T60 从 0.2–0.7 s 按房间尺寸相关采样（步长 0.01 s）再加 ±10 ms 随机偏移；听者位于距墙 1.4 m 的网格（间距 1 m，每房间随机取 5 个，最小房间 4 个），声源圆半径 1.4 m、24 个方位（15° 步长）、听者与声源高 1.25 m；共 59,688 条 RIR → 59,688 条 BRIR。说话人分离角 0°/15°/30°/60°/90°，占比 19.9% / 19.98% / 19.81% / 20.14% / 20.18%。混合 SNR 0–5 dB，片段 4 s（不足补零），均值-方差归一化后下采样到 8 kHz。
- **CI 相关声学**：CI-HRTF 由 Advanced Bionics 提供，KEMAR 假人头双侧佩戴 CI 测量（24 方位、15° 步长、0° 仰角），BRIR 由 Amengual et al. 的生成器（空间分解法）合成。
- **基线/参照**：没有外部模型基线，全部是**输入配置之间的自比**；参照点是干场景单通道结果（SI-SDRi 12.96 dB）与各配置未处理混合的 SI-SDR 基线。
- **指标**：SI-SDR、SI-SDRi（Asteroid）、STOI、PESQ（Torchaudio）；统计用 Kruskal-Wallis H 检验 + FDR 多重比较校正。
- **算力口径**：论文只给参数量（2.6M / 3.8M），未报告 RTF、延迟实测或推理硬件。

**性能指标**：全部绝对数值见「4. 结果口径」（Table I / II / III），此处不重复。要点：真实场景下 SI-SDR 2.66–4.36 dB、SI-SDRi 27.01–29.41 dB；最强配置为"双通道双耳 + IPD"（SI-SDR 4.36、STOI 0.78、PESQ 2.12），但相对"双通道单侧 + IPD"（4.16 / 0.78 / 2.09）的差距远小于隐式线索从单通道升到双通道的差距。

（来源：笔记正文「结果口径」，核验日期 2026-10-09）

## 6. 使用判断

- **适合**：助听 / CI 前端的硬件取舍决策——"值不值得上第二只 CI（双耳）"、"值不值得为 IPD 付 +46% 参数与 STFT 延迟"；低算力时域分离骨干在空间混响场景下的可行性验证；相似音色（同性别）说话人场景，此时空间线索收益最大。
- **不适合**：需要真实录音结论的产品验证（本页全为仿真）；指望模型顺带把混响也消掉（无去混响模块，输出残留大量混响）；单通道设备想靠显式线索翻盘（单通道下 IPD 只买到 +3.0% SI-SDR）。
- **风险**：音景与头部均为仿真（非个体化 CI-HRTF、KEMAR 单人），无听损 / CI 用户主观验证；骨干只有 2.6M，绝对指标低（SI-SDR 2.66–4.36 dB），论文自认弱于更大的分离模型，因此"线索收益"的方向性结论比绝对值更可迁移；IPD 的通道对与各配置输入通道的对应关系在原文有歧义（见「9. 待验证」）。

## 7. 关键来源

- [Leveraging Spatial Cues from Cochlear Implant Microphones to Efficiently Enhance Speech Separation in Real-World Listening Scenes（arXiv:2501.14610）](https://arxiv.org/abs/2501.14610)
  - 内容定位：原始论文 v1（2025-01-24，cs.SD；comments: 10 pages, 5 figures），本页全部机制的来源。
  - 用途：隐式/显式空间线索定义、7 个输入配置、Table I–III 与统计结果。
  - 核验日期：2026-10-09
- [论文 HTML 全文版（arXiv:2501.14610v1）](https://arxiv.org/html/2501.14610v1)
  - 内容定位：同论文 HTML 全文（式 (1) IPD、式 (2) SI-SDR、§II–IV 全文）。
  - 用途：公式与表格数值的逐项核对（本地纯文本抽取的公式与表格有串行错位）。
  - 核验日期：2026-10-09
- [期刊版：Scientific Reports 16:2255（DOI: 10.1038/s41598-025-31999-8）](https://doi.org/10.1038/s41598-025-31999-8)
  - 内容定位：论文的期刊版，题名改为 "...in naturalistic listening scenes"，作者与单位同上（Crossref 公布日期 2025-12-15）。
  - 用途：venue 与题名口径核验；期刊版相对 arXiv v1 的内容差异未核验（见「9. 待验证」）。
  - 核验日期：2026-10-09
- [官方代码与数据（GitHub: sayo20/Leveraging-Spatial-Cues-from-Cochlear-Implant-Microphones-to-Efficiently-Enhance-Speech-Separation-）](https://github.com/sayo20/Leveraging-Spatial-Cues-from-Cochlear-Implant-Microphones-to-Efficiently-Enhance-Speech-Separation-)
  - 内容定位：论文声明公开的"多通道改编版 SuDoRM-RF + 数据"（论文 §II-C 脚注 1）；仓库可访问（HTTP 200），内容未逐一检查。
  - 用途：复现入口。
  - 核验日期：2026-10-09

## 8. 相关对象

- [[方向/AI语音/知识/基础概念/IPD（通道间相位差）|IPD]] / [[方向/AI语音/知识/基础概念/ILD（双耳声级差）|ILD]] / [[方向/AI语音/知识/基础概念/ITD（耳间时间差）|ITD]]：本页两类线索的基础概念——隐式线索的典型形式是 ILD / IPD，显式线索本文只用了 IPD。
- [[方向/AI语音/模型/Binaural Cue Preservation Loss（双耳线索保持损失）|Binaural Cue Preservation Loss（双耳线索保持损失）]]：方向相反的双耳线索工作——它惩罚双耳增强**输出**被破坏的 ILD / IPD（保持定位线索），本页是拿空间线索当**输入**提升分离，且没有任何输出侧线索保持的约束或度量。
- [[方向/AI语音/模型/Listen-first（输出式增强）|Listen-first（输出式增强）]]：同属助听设备真实场景线；它用输出端可懂度选波束，本页用输入侧空间线索喂时域分离器。
- [[方向/AI语音/模型/HyBeam|HyBeam]] / [[方向/AI语音/模型/NICE-Beam|NICE-Beam]] / [[方向/AI语音/模型/Spatial-Magnifier|Spatial-Magnifier]]：穿戴设备上的阵列/波束路线——本页刻意不走波束形成，直接在 1–2 个 CI 麦通道上做时域分离，可作为"极简前端"的对照点。
- [[方向/AI语音/知识/技术路线/Spatial-Guided SE（空间引导与多模态增强）|Spatial-Guided SE]]：显式空间特征（IPD 作辅助输入）是该路线最经典的形式，本页给出了它在弱隐式线索下的收益量化。
- [[方向/AI语音/知识/技术路线/Real-Data Array SE（真实数据驱动阵列增强）|Real-Data Array SE]]：真实数据路线关注"真实录音难拿 clean target、仿真训练有 sim-to-real 落差"；本页正是"仿真空间化数据 + dry 目标"的一手证据，也正因此其结论仍停在仿真层。
- [[方向/AI语音/知识/技术路线/Array SE Roadmap（阵列语音增强技术路线优先级）|Array SE Roadmap]] / [[方向/AI语音/知识/调研与地图/Array Speech Enhancement Frontier（阵列语音增强前沿调研）|阵列语音增强前沿调研]]：本页可挂在"真实鲁棒 / 空间保真"评估矩阵行下，作为"低算力 + 助听设备麦克风"的实证条目。
- [[方向/AI语音/评估/SI-SDR|SI-SDR]] / [[方向/AI语音/评估/STOI 与 ESTOI|STOI]] / [[方向/AI语音/评估/PESQ|PESQ]]：本文全部评价指标。
- [[方向/AI语音/评估/ECHI（助听对话增强）|ECHI]]：助听对话增强挑战赛，代表产品级的低延迟/可懂度口径；本页的 CI 仿真与信号级指标离该口径还有距离。

## 9. 待验证

- **期刊版差异**：Scientific Reports 版题名改为 "...naturalistic listening scenes"，外部检索摘要提到期刊版含 CI 听力（vocoder）仿真实验，而本地 arXiv v1 全文**没有**该实验；期刊版是否另有新增实验 / 数值修订未核验（本页所有数字均出自 arXiv v1）。
- **IPD 的通道对**：论文写"For these input configurations, we calculated IPDs between the bilateral channels"（左耳 CI 通道 × 右耳 CI 通道），字面上也适用于"单通道波形 + IPD"与"双通道单侧 + IPD"两个配置——若如此，显式线索携带了模型波形输入之外的通道信息，会高估显式线索的独立增益；Fig. 3B 图内细节未能从文本确认。
- **原文百分比归属**："+3.0% SI-SDR, +4.3% STOI, +3.9% PESQ" 在原文被系于"双耳 vs 单侧双通道"，但按 Table I 反算对应"单侧双通道 vs 单通道"；以表格为准的结论本页已写明，原文措辞待再核。
- **SI-SDR 定义**：论文式 (2) 印为 $-10\log_{10}(\lVert t_{\text{target}}\rVert_2^2/\lVert e_{\text{noise}}\rVert_2^2)$，与 [Le Roux et al. 2019] 的标准 SI-SDR（正号、含最优尺度投影）不符；论文未写明是否做尺度投影，也未说明该负号是否排版错误（实验报告的是正值 dB）。
- **统计细节**：Table II / III 只给检验统计量与 p 值，无效应量、无置信区间、无事后检验的多重比较细节；Fig. 4 / 5 的绝对数值未随文本 / HTML 抽取出来（本页只写文字与表格能确认的数字）。
- **绝对性能偏低的原因**：SI-SDR 2.66–4.36 dB 的绝对值远低于同期多通道分离模型，论文归因于刻意选用小模型（2.6M）与不做静音裁剪，但没有与大模型 / 波束形成 / oracle 上界做直接对比，"线索有效"与"模型太小"的贡献未分离。
- **线索收益的产品化前提**：全部为仿真声学（非个体化 CI-HRTF、KEMAR 单一个体），无真实 CI 用户录音，无 CI 电刺激（vocoder）验证，无听损人群可懂度；双耳 CI 的收益是否能在真实植入者身上复现未验证。
- **干目标与残留混响**：论文自陈分离输出仍残留大量混响，需要"分离 + 去混响"联合方案，但未给残留混响的量化。
- **重叠说话人收益的机制**："0° 重叠也受益"的解释在原文明确标为假设（模型学到与频率相关的混响特性），未做验证实验。
- **算力口径**：只给参数量（2.6M → 3.8M，+46%）与 STFT 延迟的定性说明，无 RTF / 端到端延迟实测。

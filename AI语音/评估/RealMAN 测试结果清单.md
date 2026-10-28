---
title: RealMAN 测试结果清单
类型: 横评清单
发表时间: 2026-10-26
时间依据: 清单本身无发表日；收录口径截至 2026-10，最新一条为 Geo-DConv（2026-07）
相关任务:
  - 语音增强
  - 多通道增强
相关模型:
  - "[[方向/AI语音/模型/LABNet]]"
  - "[[方向/AI语音/模型/CaSNet]]"
  - "[[方向/AI语音/模型/Geo-DConv]]"
  - "[[方向/AI语音/模型/DiT-Flow]]"
  - "[[方向/AI语音/模型/SpatialNet]]"
  - "[[方向/AI语音/模型/TF-GridNet]]"
  - "[[方向/AI语音/模型/FaSNet（滤波求和网络）]]"
  - "[[方向/AI语音/模型/CleanMel]]"
相关评估:
  - "[[方向/AI语音/评估/PESQ]]"
  - "[[方向/AI语音/评估/STOI 与 ESTOI]]"
  - "[[方向/AI语音/评估/SI-SDR]]"
  - "[[方向/AI语音/评估/OVRL_MOS]]"
  - "[[方向/AI语音/评估/SpkSim]]"
  - "[[方向/AI语音/评估/CER（Character Error Rate）]]"
  - "[[方向/AI语音/知识/调研与地图/SE SOTA（语音增强模型表现）]]"
aliases:
  - RealMAN 榜单
  - RealMAN SOTA
  - RealMAN 测试结果清单
  - RealMAN Results Index
tags:
  - 类型/对象
  - 方向/AI语音
  - 任务/语音增强
  - 任务/多通道增强
  - 主题/阵列信号
  - 资源/数据集
---

# RealMAN 测试结果清单

[[方向/AI语音/数据集/RealMAN|RealMAN]] 没有官方 leaderboard，也没有统一评测协议；目前流传的"RealMAN SOTA"全部来自论文自报表，被 [SOTA2](https://www.sota2.com/dataset/realman)、WizWand（同源站点）这类聚合站按任务名切成多条榜（PESQ 榜 8 条、DNSMOS 榜 7 条）。**这些榜互相不可比**：训练集、麦克风数、参考信号、指标全不同。本页按口径分组收录，只保证**组内可比**。

一句话现状：多通道口径的第一名是 LABNet 2.34 PESQ，但那是 CaSNet 论文重测的值（LABNet 原文没在 RealMAN 上测过）；单通道真实录音口径的第一名是 DiT-Flow 2.911 SIG / 2.402 OVRL。

## 1. 口径总览

| 组 | 训练数据 | 麦克风 | 参考 / 指标 | 组内最好 |
|---|---|---|---|---|
| A | RealMAN 真实语音 + 真实噪声 | 6 麦（32 通道取子阵列） | 直达路径语音；PESQ / STOI / COVL | LABNet 2.34（CaSNet 重测） |
| B | StillSonicSet 或 WSJ0+Reverb（**非** RealMAN） | 1 麦 | 无参考；SIG / BAK / OVRL + SpkSim | DiT-Flow 2.911 / 2.402 |
| C | RealMAN 真实语音 + 真实噪声 | 9 麦子阵列、28 麦变阵列 | 直达路径语音；PESQ / SI-SDR / DNSMOS / CER | SpatialNet OVRL 2.71 |
| D | RealMAN 真实语音 + 真实噪声 | 训练 ≤4 麦、测试 1–4 麦随机（含拓扑随机） | 直达路径语音；SDR / SI-SDR / PESQ / STOI / OVRL | TF-GridNet-Geo 2.77 |
| E | RealMAN 真实语音 + 真实噪声 | 9 麦 | 转写文本；CER | CleanMel 14.4 |

## 2. A 组：多通道、RealMAN 自身数据训练（PESQ 系）

设置：真实 32 通道阵列取 6 麦，SNR ∈ [−5, 15] dB 混合，6 / 6 / 12 通道分别用于训练 / 验证 / 测试；指标为有参考系（PESQ / STOI / COVL）。来源：[[方向/AI语音/模型/CaSNet|CaSNet]] Table 1。

| 方法 | PESQ | STOI | COVL | 备注 |
|---|---|---|---|---|
| LABNet（未压缩） | 2.34 | 0.90 | 3.14 | 组内最高；**CaSNet 论文重测值**，非 LABNet 原文 |
| CaSNet（a=4） | 2.27 | 0.89 | 3.06 | 52k 参数、0.325G MACs、NSA 0.75（压缩传输） |
| EaBNet | 2.17 | 0.91 | 3.08 | 固定阵列 |
| McNet | 2.12 | 0.90 | 3.14 | 固定阵列；COVL 与 LABNet 并列 |
| FaSNet-TAC | 1.65 | 0.84 | 2.11 | ad-hoc 阵列老基线 |
| Oracle MVDR | 1.33 | 0.78 | 2.11 | 真实空间协方差，传统方法上界 |
| Noisy | 1.17 | 0.74 | 2.03 | 下界 |

口径要点：LABNet 原文（arXiv:2507.16190）只做 WSJ0+WHAM! 仿真，**没有 RealMAN 结果**；2.34 这一行是 CaSNet 复现其未压缩版本后报的。所以"A 组 SOTA"严格说是"被第三方复现到最好的模型"，不是该模型论文的主张。另：COVL 是 [[CSIG CBAK COVL（复合客观质量指标）|三件套]]里的总体分，按 $1.594+0.805\,\mathrm{PESQ}$ 换算而来，与 PESQ 近乎共线（本表 PESQ 排序与 COVL 排序仅在 EaBNet/McNet 处互换），只作辅助列。

## 3. B 组：单通道、真实录音作测试集（DNSMOS 系）

设置：模型在合成数据上训练，RealMAN 只当**零样本真实录音测试集**（取 9 个场景、1692 条，中文语音 + 跨语言）；指标为无参考 DNSMOS P.835（SIG / BAK / OVRL，1.0–5.0）+ 说话人相似度（WavLM-base-plus-sv 余弦，0–1）；采样率 8 kHz。来源：[[方向/AI语音/模型/DiT-Flow|DiT-Flow]] Table VI。

| 方法（训练集） | RTF | SIG | BAK | OVRL | Spk Sim |
|---|---|---|---|---|---|
| **DiT-Flow（StillSonicSet）** | **0.230** | **2.911** | **3.684** | **2.402** | **0.896** |
| SGMSE（StillSonicSet） | 0.565 | 2.829 | 3.623 | 2.324 | 0.883 |
| DiT-Flow（WSJ0+Reverb） | 0.230 | 2.754 | 3.413 | 2.184 | 0.885 |
| StoRM（StillSonicSet） | 0.494 | 2.661 | 3.662 | 2.154 | 0.886 |
| StoRM（WSJ0+Reverb） | 0.494 | 2.481 | 2.976 | 1.884 | 0.891 |
| SGMSE（WSJ0+Reverb） | 0.565 | 2.473 | 3.031 | 1.863 | 0.892 |
| Noisy（下界） | — | 1.970 | 2.204 | 1.417 | 0.860 |

口径要点：这一组是"跨数据集泛化"，不是"在 RealMAN 上训练"。数值已按原文 Table VI 逐格核对（2026-10-27）；聚合站把 Spk Sim 写成 89.6 是百分数制。RTF 一列只给一值、LibriCSS 与 RealMAN 共用，因为同一架构换训练集不改变计算图；它是整段离线吞吐（1 s 音频约 0.23 s 算完），不代表可实时通话，口径见 [[方向/AI语音/评估/RTF（实时率）|RTF]]。仍未写清的是：单通道模型取 32 通道中的哪一路、16 kHz 是否重采样到 8 kHz、static 与 moving 声源占比，见待验证。

## 4. C 组：RealMAN 原文基线（9 麦与变阵列）

来源：RealMAN 原文（NeurIPS 2024）Table 4 / Table 7，训练数据为 real speech + real noise，指标同时给有参考（WB-PESQ / SI-SDR）与无参考（DNSMOS 三项）+ CER。

### 4.1. 9 麦子阵列（Table 4）

| 方法 | 说话人 | WB-PESQ | SI-SDR | SIG | BAK | OVRL | CER |
|---|---|---|---|---|---|---|---|
| SpatialNet | 静止 | 2.16 | 7.3 | 3.23 | 3.43 | 2.71 | 14.5 |
| SpatialNet | 移动 | 1.97 | 4.3 | 3.15 | 3.40 | 2.63 | 18.6 |
| FaSNet-TAC | 静止 | 1.46 | 2.1 | 2.79 | 3.30 | 2.34 | 21.9 |
| FaSNet-TAC | 移动 | 1.39 | 1.2 | 2.73 | 3.20 | 2.26 | 25.6 |
| Unprocessed | 静止 | 1.14 | −9.9 | 2.01 | 1.73 | 1.52 | 20.1 |
| Unprocessed | 移动 | 1.10 | −9.0 | 1.80 | 1.54 | 1.37 | 23.7 |

### 4.2. 变阵列（Table 7，水平面 28 麦，FaSNet-TAC）

| 训练 / 测试阵列 | WB-PESQ | SI-SDR | SIG | BAK | OVRL | CER |
|---|---|---|---|---|---|---|
| Fixed-Array | 1.46 | 0.9 | 2.76 | 3.32 | 2.32 | 25.0 |
| Variable-Array | 1.40 | −0.0 | 2.70 | 3.20 | 2.22 | 27.4 |
| Unprocessed | 1.15 | −9.8 | 2.00 | 1.72 | 1.51 | 19.9 |

口径要点：原文明确指出有参考指标因"目标 clean 声由直达路径滤波器得到"而存在测量偏差，**只作参考**，推荐看 DNSMOS；这也是 C 组 OVRL 2.63–2.71 比 A 组"看起来高"的主要原因（9 麦 + 同源训练）。

## 5. D 组：几何泛化口径（Geo-DConv）

设置：Geometry-Invariant 档——训练与测试都随机取 1–4 麦、拓扑随机；同一批测试条件覆盖全部模型。来源：[[方向/AI语音/模型/Geo-DConv|Geo-DConv]] Table 1。

| 方法 | 参数量 | MACs (G/s) | SDR | SI-SDR | PESQ | STOI | OVRL |
|---|---|---|---|---|---|---|---|
| TF-GridNet-Geo-DConv | 8.3M | 73.12 | 9.05 | 3.90 | 2.59 | 0.87 | 2.77 |
| SpatialNet-Geo-DConv | 1.3M | 6.08 | 9.72 | 4.22 | 2.48 | 0.86 | 2.68 |
| USES2-comp | 2.5M | 70.26 | 8.62 | 4.17 | 2.52 | 0.86 | 2.56 |
| FaSNet-TAC | 2.7M | 9.76 | 5.76 | −0.81 | 1.74 | 0.73 | 2.05 |

固定阵列侧容量对齐参照（同表 Fixed-Array 档，同数据同训练预算，2026-10-28 补核）：

| 方法 | 参数量 | MACs (G/s) | SI-SDR | PESQ | SIG | BAK | OVRL |
|---|---|---|---|---|---|---|---|
| TF-GridNet（固定阵列上界） | 8.2M | 73.03 | **5.29** | **2.72** | 3.13 | 3.63 | 2.71 |
| SpatialNet（固定阵列上界） | 1.2M | 5.99 | **5.23** | 2.56 | 3.11 | 3.58 | 2.67 |
| BSRNN（单通道，容量锚） | 16.9M | 21.15 | −1.38 | 1.94 | 2.61 | 3.29 | 2.18 |
| No processing | — | — | −9.47 | 1.54 | 1.99 | 1.84 | 1.49 |

口径要点：这一组是**唯一能拿来比"跨阵列能力"的组**，但不在任何聚合榜上。与上方固定阵列档逐行对齐后可以看出：几何随机化让 **SI-SDR 掉 1.0–1.4 dB，但 SIG 与 OVRL 不降反略升**（SpatialNet 2.67→2.68、TF-GridNet 2.71→2.77）——不是方法退步，而是任务变难且代价集中在波形级相位。若做几何泛化横评，只能自建对照组。

## 6. E 组：ASR 口径（CleanMel）

| 系统 | 指标 | RealMAN static | 对照 |
|---|---|---|---|
| CleanMel-L-mask | CER | 14.4 | Unprocessed 20.1 |

口径要点：唯一用 CER 衡量 RealMAN 的收录条目，与 A–D 组的质量/保真指标不同源，仅作旁证（增强是否真的帮到下游）。

## 7. 只查到名称、没有数字（待补）

- **MCFLOW-SE**（Technion，IEEE SPL 2026, 33:1496–1500，DOI 10.1109/LSP.2026.3678470）：一步生成式多通道增强，用 RealMAN 作真实数据集，主打 ASR 与推理速度；正文数字在付费墙内。
- **OBFNet**（NUAA / 中科大 NERCSLIP，IEEE TASLP 2026，DOI 10.1109/TASLPRO.2026.3664168）：正交基函数时域神经波束形成，对标 [[方向/AI语音/模型/FaSNet（滤波求和网络）|FaSNet]]；RealMAN 结果未取到。
- **IPDnet2A**（IEEE SPL 2026，DOI 10.1109/LSP.2026.3732232）：任意阵列几何的直达路径 IPD 估计——属**定位**任务，非增强。
- **DySiME**（APSIPA ASC 2025，DOI 10.1109/APSIPAASC65261.2025.11249356）：只在仿真 4 麦圆阵上评测，RealMAN 仅作引用，**不构成 RealMAN 结果**。

补充：OpenAlex 记 RealMAN 被引 12 篇，但 Geo-DConv、DiT-Flow 这类 arXiv-only 工作不在其中，"谁在 RealMAN 上测过"目前只能靠组合检索，没有权威名单。

## 8. 数值普遍偏低的成因

1. **参考信号是直达路径语音，不是干净语音**。原论文明说 PESQ / SI-SDR 因此有偏、只作参考；A / C / D 三组的 PESQ 天花板被这套 reference 压住。
2. **真实噪声的空间相关性高度时变**，偏离弥散场假设；原文发现 SpatialNet 用"仿真语音 + 真实噪声"反而最差（SI-SDR −9.7），说明 sim-to-real 缺口不是均匀分布的。
3. **场景跨度大且含移动声源**：32 个场景（室内 / 室外 / 半室外 / 交通），移动档全线掉点（SpatialNet CER 14.5 → 18.6，OVRL 2.71 → 2.63）。
4. **麦克风位置标定误差**：原文确认理想坐标与真实位置存在轻微失配，学 RIR 的模型尤其敏感，扰动训练只能缓解一部分。
5. **口径混用**：8 kHz / 16 kHz、1 / 6 / 9 / 28 麦、训练集是 RealMAN 还是 StillSonicSet，四者交叉组合后绝对数值天然不可高。

标尺参照：DNSMOS OVRL 在 RealMAN 上 unprocessed ≈ 1.4–1.5、SpatialNet ≈ 2.6–2.7，因此 2.4–2.8 已是"从明显可听噪声到可用"的区间；PESQ 在 6–9 麦 + 直达声参考下达 2.3 属正常水平。

## 9. 横评注意事项

- **不可横比的组合**：A ↔ B（训练集不同、麦数不同、指标不同）、B ↔ C（8 kHz vs 16 kHz、单麦 vs 9 麦）、C ↔ D（阵列条件不同，D 含拓扑随机）、A ↔ D（D 的训练上限只有 4 麦）。
- **基线怎么选**：单阵列上限用 C 组 SpatialNet；多通道 SOTA 对标 A 组 LABNet / CaSNet；几何泛化只认 D 组；跨数据集真实录音泛化看 B 组。
- **报什么指标**：RealMAN 上只报 PESQ 会被 reference 偏差带偏，建议 PESQ + SI-SDR + DNSMOS OVRL 三件套同报，并注明 static / moving 是否分开、通道数、训练数据来源。
- **test 与 test_raw 要分开说**：RealMAN 的 test 是混合集、test_raw 是原始实录，两者难度不同；聚合站把两类混在同一榜名下。

## 10. 关键来源

- [RealMAN 论文（arXiv:2406.19959，NeurIPS 2024）](https://arxiv.org/abs/2406.19959)：Table 4（9 麦子阵列）、Table 7（变阵列）与"有参考指标只作参考"的口径声明。核验日期：2026-10-26。
- [CaSNet（arXiv:2601.17711，ICASSP 2026）](https://arxiv.org/abs/2601.17711)：A 组 Table 1 全部数值，含 LABNet 行的复现口径。核验日期：2026-08-10（见 [[方向/AI语音/模型/CaSNet|CaSNet]]）。
- [LABNet（arXiv:2507.16190）](https://arxiv.org/abs/2507.16190)：原文实验只含 WSJ0+WHAM!，为"2.34 非原文结果"的依据。核验日期：2026-10-26。
- [Geo-DConv（arXiv:2607.18658，Interspeech 2026）](https://arxiv.org/abs/2607.18658)：D 组 Table 1。核验日期：2026-10-15（见 [[方向/AI语音/模型/Geo-DConv|Geo-DConv]]）。
- [DiT-Flow（arXiv:2603.21608）](https://arxiv.org/abs/2603.21608)：B 组数值的原始出处（本页数值经聚合站转引，见待验证）。核验日期：2026-07-28。
- [CleanMel（arXiv:2502.20040，TASLP 2025）](https://arxiv.org/abs/2502.20040)：E 组 CER。核验日期：2026-07-28。
- 聚合站（二手，仅用于交叉检索，不作引用依据）。站内搜索 "realman" 会同时命中 5 个睿尔曼机器人数据集，语音这条的条目标题是 **RealMAN**（大小写不同），直达链接：
  - [RealMAN 数据集页](https://www.sota2.com/research/dataset/realman)：上半部分是机器人操作榜，语音的两条在 Speech Enhancement 行。
  - [Speech Enhancement on RealMAN（PESQ 榜，8 条）](https://www.sota2.com/research/sota/speech-enhancement-on-realman)
  - [Speech Enhancement on RealMAN (real-recorded)（SIG 榜，7 条）](https://www.sota2.com/research/sota/speech-enhancement-on-realman-real-recorded)
  - [WizWand 同源页面](https://www.wizwand.com/dataset/realman)（同一份数据，域名不同）

## 11. 相关对象

- [[方向/AI语音/数据集/RealMAN|RealMAN]]：数据集本体（构成、许可、几何元数据缺口）。
- [[方向/AI语音/知识/调研与地图/SE SOTA（语音增强模型表现）|SE SOTA]]：跨数据集的模型格局，本页是其 RealMAN 分支。
- [[方向/AI语音/知识/调研与地图/Array Speech Enhancement Frontier（阵列语音增强前沿调研）|阵列语音增强前沿调研]]："真实数据"与"阵列无关"两节的上位调研。
- [[工程/Geo-DConv 复现方案|Geo-DConv 复现方案]]：D 组即该方案的对照目标。
- [[方向/AI语音/评估/语音增强评估指标体系|语音增强评估指标体系]]：PESQ / DNSMOS / SI-SDR 的分工与生成式幻觉问题。

## 12. 待验证

- B 组（DiT-Flow）已核清的部分：9 个场景（Classroom2-3、LivingRoom2、4-5、OfficeRoom2-4、OfficeLobby）、1692 条、8 kHz 单通道模型、RealMAN 不参与训练。未核清：取 32 通道中的哪一路、RealMAN 原始 16 kHz 是否重采样、static / moving 声源占比、clean reference 是否即 `dp_speech`。
- A 组 LABNet 行是否在 LABNet 后续版本（v2 之后或 TASLP 扩展版）补过 RealMAN 结果。
- 付费墙 4 篇（MCFLOW-SE / OBFNet / IPDnet2A / DySiME）在 RealMAN 上的实际数值与设置。
- RealMAN 仓库是否提供官方评测脚本或 leaderboard（若有，本页应以官方协议为准重排）。
- 是否已有工作同时报告 A 组（固定 6 麦）与 D 组（1–4 麦随机）两档，可直接给出"跨阵列代价"的量化对照。

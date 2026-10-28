---
title: CSIG CBAK COVL（复合客观质量指标）
类型: 指标
aliases:
  - COVL
  - Covl
  - C_ovl
  - CSIG
  - CBAK
  - 复合指标
  - Composite Measures
  - Hu-Loizou composite measure
tags:
  - 类型/对象
  - 方向/AI语音
  - 指标/质量
  - 指标/有参考
---

# CSIG CBAK COVL（复合客观质量指标）

## 0. 背景

- **出现前的问题**：2000 年代中期做增强算法横评，手上只有两类指标——PESQ / STOI 这类"总体"分数，和 LLR / WSS / SNR 这类纯距离量。前者只给一个总数，看不出"语音被磨平"还是"噪声没压净"；后者与主观分不是线性关系（SNR 对增益、时延都敏感，WSS 只是谱斜率差）。而听测（P.835）恰恰是按"语音失真 / 背景侵入 / 总体"三个维度分开打分的，客观侧缺一套同构的代理。
- **替代方案的缺口**：单项指标无法拆分来源，也不便与主观三维度对齐；更麻烦的是各指标量纲不同（dB、距离、MOS），无法放进一张表比较。
- **出现后的谱系**：Hu & Loizou（2008）在 NOIZEUS（8 kHz、10 类噪声、多种增强算法）上做多元线性回归，把 PESQ + LLR + WSS + SSNR 拟合成三个 1–5 的分，语义上分别对齐 P.835 的 SIG / BAK / OVRL。此后 2008–2016 与 [[PESQ]]、[[STOI 与 ESTOI]] 捆绑成 VoiceBank-DEMAND 时代的"四件套"标准写法（PESQ / CSIG / CBAK / COVL / STOI），阵列与轻量模型论文至今沿袭（[[方向/AI语音/模型/LABNet|LABNet]]、[[方向/AI语音/模型/CaSNet|CaSNet]]、[[方向/AI语音/模型/SFB-NSE|SFB-NSE]]、[[方向/AI语音/模型/MSEN（特征束多阶编码器）|MSEN]]）。2018 年后无参考系（[[OVRL_MOS|DNSMOS]]）兴起，复合指标因依赖 clean reference、且对生成式模型的波形级错位敏感，逐渐退为辅助列。

## 1. 身份

三个量，一套回归，共用四个底层指标（PESQ / LLR / WSS / SSNR），输出都被截断到 **[1, 5]**：

| 指标 | 语义 | 对应主观维度 | 用到的分量 |
|---|---|---|---|
| **CSIG** | 语音信号本身的失真程度 | P.835 的 SIG（语音自然度） | PESQ、LLR、WSS |
| **CBAK** | 残余背景噪声的侵入程度 | P.835 的 BAK（背景干扰） | PESQ、WSS、SSNR |
| **COVL** | 总体质量 | P.835 的 OVRL（总评） | PESQ、LLR、WSS |

边界：**它们是"有参考"指标**，必须有 clean reference；也**不是听测**，只是对 8 kHz 电话带主观分的回归拟合，外推到 16 kHz、阵列、生成式模型属于域外使用（见 §5）。

## 2. 三式（Hu & Loizou 2008）

$$
\begin{aligned}
\mathrm{CSIG} &= 3.093 - 1.029\,\mathrm{LLR} + 0.603\,\mathrm{PESQ} - 0.009\,\mathrm{WSS} \\
\mathrm{CBAK} &= 1.634 + 0.478\,\mathrm{PESQ} - 0.007\,\mathrm{WSS} + 0.063\,\mathrm{SSNR} \\
\mathrm{COVL} &= 1.594 + 0.805\,\mathrm{PESQ} - 0.512\,\mathrm{LLR} - 0.007\,\mathrm{WSS}
\end{aligned}
$$

三式均 $\mathrm{clamp}(\cdot,1,5)$。系数即上式（与 CMGAN / pysepm 等主流实现一致，2026-10-27 逐行核对 `compute_metrics.py`）。

**读系数能读出三件事**：

1. **COVL 是 PESQ 的重标定版**：斜率 0.805、截距 1.594。PESQ 每涨 1，COVL 只涨 0.805，所以两者高度共线——COVL 不能当"独立于 PESQ 的第二个证据"。
2. **COVL 对噪声不敏感**：它不含 SSNR，只看 LLR / WSS（谱包络失真）。噪声残留要看 CBAK，这也是"COVL 高、BAK 低"的常见组合。
3. **CSIG 几乎由 LLR 主导**（系数 −1.029），即"LPC 谱包络被改了多少"；这是它对生成式模型不友好的根源——重生成的语音谱形对但细节不同，LLR 会罚。

## 3. 分量口径

| 分量 | 计算要点 | 陷阱 |
|---|---|---|
| PESQ | ITU-T P.862，回归时用的是 **8 kHz 窄带 MOS-LQO 映射** | 16 kHz 论文多半换成 `wb` PESQ 直接代入，与拟合时分布不同，常数项偏移 |
| LLR | LPC（fs<10 kHz 用 10 阶，否则 16 阶），30 ms 帧 / 7.5 ms 帧移，逐帧后取**最低 95% 的均值**（α=0.95） | 用全帧均值还是 α=0.95 截断，结果差一截 |
| WSS | 25 个临界带、Klatt 加权（Kmax=20、Klocmax=1），同样取最低 95% 均值 | 频带划分按 8 kHz 设计，16 kHz 需重采样到 8 kHz 再算 |
| SSNR | 30 ms 帧 / 7.5 ms 帧移，每帧 SNR 截断到 [−10, 35] dB 后平均 | 静音段占比高时被 SSNR 拉低 |

## 4. 怎么读

- **名义 1–5，实际上限约 4.5**：COVL 的顶点是 $1.594+0.805\times4.5\approx5.22$，会被 clip 到 5；但 PESQ 本身封顶 4.5，所以 4.2 以上已是"接近满分"的区间。
- **别把 COVL 与 PESQ 直接比大小**：同一系统 PESQ 2.34 对应 COVL 3.14，看起来"高了 0.8"，其实只是截距 + 斜率造成的换算。经验换算：$\mathrm{COVL}\approx 1.6+0.8\,\mathrm{PESQ}$ 再减 0.2–0.5 的失真罚分。
- **三件套要成组看**，典型模式：

| 组合 | 含义 |
|---|---|
| CSIG 高 / CBAK 低 | 语音保住了，噪声没压干净（轻量模型的常见短板） |
| CSIG 低 / CBAK 高 | 噪声压了但语音被磨（强降噪、窄带化） |
| CSIG、CBAK 都高 / COVL 也高 | 真正的全面提升，通常伴随 PESQ 一起涨 |
| COVL 高但 PESQ 不高 | 几乎不可能超过 0.8 倍换算关系，出现说明口径不一致（多半是 PESQ 用了不同模式） |

## 5. 常见误判

- **COVL 是"另一个维度的证据"**：错的。COVL 与 PESQ 的线性相关在各类榜单上都很高（同表内 rank 基本一致），报 COVL 不报 PESQ 等于换了刻度重复一遍。
- **COVL 高 = 背景干净**：错的。COVL 不含 SSNR，背景残留看 CBAK。
- **三家数字可以直接横比**：错。PESQ 用 nb 还是 wb、LLR/WSS 用 α=0.95 还是全帧均值、是否重采样到 8 kHz，任何一项不同都会让绝对分漂移 0.1–0.3。
- **1–5 就是 MOS**：错。是回归预测值，且训练域是 8 kHz NOIZEUS + 传统增强算法；生成式、48 kHz、真实阵列全在域外，绝对值不可信、只可同表内相对比较。
- **和 DNSMOS 的 SIG/BAK/OVRL 可以互换**：不可。一个是侵入式回归（需要 clean reference，8 kHz 域），一个是非侵入神经网络预测（16/48 kHz），同名不同物。
- **用 COVL 评价生成式模型**：不推荐。波形级错位会让 LLR/WSS 双罚，出现"听感很好、COVL 很低"——这正是 DiT-Flow 一类工作改用 DNSMOS 的原因（见 [[方向/AI语音/模型/DiT-Flow|DiT-Flow]] §5.3）。

## 6. 与 DNSMOS 的关系（同构，但不可换算）

一句话：**语义同构、口径不同源、数值不可互推**。两者都在猜"人耳会打几分"，但一个是 2008 年用 8 kHz NOISEUS 拟合出的固定线性公式（需要 clean reference），一个是 2018 年后用众包听测训出来的神经网络（不需要 reference）。

| 维度 | CSIG / CBAK / COVL（Hu-Loizou 2008） | DNSMOS P.835（[[OVRL_MOS]]） |
|---|---|---|
| 语义 | 信号失真 / 背景侵入 / 总体 | SIG / BAK / OVRL，三个维度同名同构 |
| 是否需要 reference | **需要**（侵入式） | 不需要（非侵入） |
| 实现 | 固定线性回归（4 个分量加权） | DNN 直接预测 |
| 主输入 | PESQ + LLR + WSS（+ SSNR） | 波形 / 频谱表示 |
| 频带 | 8 kHz 窄带（回归域） | 16 / 48 kHz |
| 标定数据 | NOIZEUS，10 类噪声，传统增强算法输出 | 众包 P.808 / P.835 听测（DNS Challenge 系列） |
| 输出分布 | 名义 1–5，实际常见 2.2–4.2 | 1–5，noisy ≈1.4、可用 ≈2.7、8 kHz 复合失真上好模型 2.4–3.0（OVRL） |
| 对生成式模型 | 系统性偏低（波形错位 → PESQ / LLR / WSS 三罚） | 相对宽容（只看感知，不做波形比对） |

三条硬结论：

1. **不能线性换算**。$1.6+0.8\,\mathrm{PESQ}$ 只说明 COVL 的骨架是 PESQ；DNSMOS 与 PESQ 之间没有稳定映射。[[方向/AI语音/模型/DiT-Flow|DiT-Flow]] 在域内复合失真上 PESQ 只有 1.389，而 RealMAN 上 DNSMOS 给出 OVRL 2.402 / SIG 2.911——同处 1–5 刻度，但两者不是同一件事，不能互相印证。
2. **失败模式相反**。生成式幻觉（内容被重写、听感自然）：DNSMOS 会给高分，COVL / CBAK 因谱与波形错位被压低。判别式过度降噪（语音被磨）：COVL 跟着 PESQ 掉，DNSMOS 的 BAK 反而很高。
3. **同表并排时不要合并结论**。一张表里 PESQ 1.4 + COVL 2.4 + OVRL 2.4 可以同时成立，读法是"有参考系偏低、无参考系中等"，不是矛盾。

实践口径：真实录音（无 clean reference）只能用 DNSMOS 一档；有参考时两套都报、各自分组。要做跨口径对照，唯一可行办法是在**同一批音频上同时跑两套指标**再拟合单调映射——本库目前没有这样的实验（见 §10）。

## 7. 本库已收录的数值

| 模型 / 数据 | PESQ | CSIG | CBAK | COVL | 备注 |
|---|---|---|---|---|---|
| LABNet / WSJ0-WHAM!（6 麦） | 2.92 | 4.42 | 3.24 | 3.70 | 原文 Table I |
| LABNet / 单麦 | 2.51 | — | — | 3.29 | 原文 Table II |
| LABNet（CaSNet 重测）/ RealMAN 6 麦 | 2.34 | — | — | 3.14 | 第三方复现值 |
| CaSNet / RealMAN | 2.27 | — | — | 3.06 | 52k 参数 |
| EaBNet / RealMAN | 2.17 | — | — | 3.08 | 固定阵列 |
| McNet / RealMAN | 2.12 | — | — | 3.14 | COVL 与 LABNet 并列 |
| [[方向/AI语音/模型/FRCRN|FRCRN]] / VoiceBank-DEMAND | 3.21 | 4.23 | 3.64 | 3.73 | 16 kHz wb PESQ 口径 |
| VoiceBank-DEMAND 头部模型 | ~3.0+ | >4.7 | — | ~4.1 | 见 [[SE SOTA（语音增强模型表现）]] |

注意：RealMAN 一组是 16 kHz 真实阵列数据，CaSNet 用哪种 PESQ 模式代入未在笔记中核实，见 §10。

## 8. 关键来源

- Hu, Y. & Loizou, P. C., *Evaluation of Objective Quality Measures for Speech Enhancement*, IEEE Trans. Audio, Speech, and Language Processing, 16(1): 229–238, 2008
  - 内容定位：三式原始出处；回归数据为 NOIZEUS（8 kHz、10 类噪声、多种增强算法）。核验日期：2026-10-27（公式经实现核对，原文 PDF 未逐页取）
- [CMGAN compute_metrics.py](https://github.com/ruizhecao96/CMGAN/blob/main/src/tools/compute_metrics.py)
  - 内容定位：三式与 LLR / WSS / SSNR 的现行实现，含 clamp 与 α=0.95 截断。核验日期：2026-10-27（逐行比对本机抓取文件）

## 9. 相关对象

- [[方向/AI语音/评估/PESQ|PESQ]]：三式的输入，COVL 与它高度共线。
- [[方向/AI语音/评估/STOI 与 ESTOI|STOI]]：常与三件套同表出现，但管可懂度不管音质。
- [[方向/AI语音/评估/OVRL_MOS|OVRL]]：无参考的 P.835 预测，语义与 COVL 对齐但口径完全不同。
- [[方向/AI语音/评估/语音增强评估指标体系|语音增强评估指标体系]]：三件套在指标地图里的位置。
- [[方向/AI语音/模型/CaSNet|CaSNet]]、[[方向/AI语音/模型/LABNet|LABNet]]：本库中 RealMAN / WSJ0-WHAM! 上 COVL 的主要来源。
- [[方向/AI语音/评估/RealMAN 测试结果清单|RealMAN 测试结果清单]]：A 组即 PESQ / STOI / COVL 口径。

## 10. 待验证

- CaSNet 在 RealMAN 上算 COVL 时用的是 nb（8 kHz）还是 wb（16 kHz）PESQ——直接影响与 LABNet 原文（16 kHz wb）的可比性。
- 各论文 LLR / WSS 是否都取 α=0.95 的最低帧均值，还是全帧均值；实现差异对 COVL 的具体影响幅度。
- Hu & Loizou 原文报告的三式与主观 MOS 相关系数（当前页内只有定性判断，未取到具体 r）。
- 生成式模型（DiT-Flow / FlowSE 系）上 COVL 与 DNSMOS 的相关性是否已经低到"不可用"，需要一组同表实验确认。
- 在同一批音频上同时跑 COVL 与 DNSMOS OVRL，拟合单调映射并量化 8 kHz / 16 kHz 两种口径下的漂移幅度——这是跨口径引用的唯一可靠校准方式。

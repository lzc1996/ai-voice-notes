---
title: WSJ0（华尔街日报语料库）
类型: 数据集
发表时间: 1993
时间依据: LDC 目录编号 LDC93S6A 与版权年份（© 1992, 1993 Trustees of the University of Pennsylvania）
aliases:
  - WSJ0
  - CSR-I
  - WSJ0 语料库
  - Wall Street Journal Corpus 0
tags:
  - 类型/对象
  - 方向/AI语音
  - 任务/语音分离
  - 任务/语音识别
  - 资源/数据集
---

# WSJ0（华尔街日报语料库）

## 1. 身份

`WSJ0`（官方名 **CSR-I**，LDC 目录号 **LDC93S6A**）是 NIST 在 DARPA Spoken Language Program 下于 1991 年起采集、1993 年经 LDC 发布的**英文大词汇连续朗读语音语料库**：123 名说话人（男女约各半）朗读《华尔街日报》文本，共约 141 小时。

边界：

- **≠ WSJ1（CSR-II）**：WSJ1 是其后发布的第二批 CSR 语料，规模更大；SMS-WSJ 等混合集同时使用 WSJ0+1。
- **≠ wsj0-2mix**：wsj0-2mix 是 2016 年 deep clustering 论文用 WSJ0 干净语音**二次合成的双人混合基准**，不是语料库本身（见「衍生数据集」；vault 暂无独立页，见「待验证」）。
- **≠ WSJCAM0**：WSJCAM0 是剑桥大学在英国重新录制的同源文本语料（REVERB Challenge 用），不是 WSJ0 本身。

## 2. 数据构成

- **录制**：SRI、TI、MIT 三地录制；每人双通道——近讲 Sennheiser HMD414 头戴麦 + 一支不固定的副麦克风，两通道分盘存放。
- **格式**：单通道、16 bit、16 kHz、NIST sphere 格式。
- **文本**：朗读文本选自 5,000 词或 20,000 词两个 WSJ 词汇子集；另含记者即兴口述（spontaneous dictation）部分。随盘附完整正字转写与 WSJ 文本 bigram 语言模型。
- **发行版本**：LDC93S6A Complete（双通道全量，约 141h）；LDC93S6B Sennheiser（近讲麦，约 80h）；LDC93S6C Other（副麦，约 84h）。
- **常用划分**（Kaldi 沿用并成为后续混合集的通用命名）：`si84` / `si284`（说话人独立训练集）、`dev93`（开发）、`eval92`（测试）；各划分的精确说话人数与时长见「待验证」。

## 3. 衍生数据集

WSJ0 在语音分离 / 增强领域的主要角色是**干净单人语音底料**，由此派生出整条 WSJ 系仿真基准：

- **wsj0-2mix**（Hershey et al., ICASSP 2016，arXiv:1508.04306）：WSJ0 干净语音合成的 2 说话人完全重叠混合，8 kHz，20k / 5k / 3k 训练 / 验证 / 测试，说话人相对电平 [−5, 5] dB；单通道无混响分离的奠基性基准（[[方向/AI语音/模型/TF-GridNet|TF-GridNet]] 等在此刷榜）。已知口径问题：训练说话人会出现在开发集（见 [[方向/AI语音/数据集/SMS-WSJ|SMS-WSJ]] 页）。
- **WSJ0-3mix / WSJ0-{2..5}mix**：同法扩展到 3–5 说话人（[[方向/AI语音/模型/REDnet|REDnet]] 用于未知人数分离）。
- **Spatialized WSJ0-2mix**：加 RIR 空间化的多通道版本（[[方向/AI语音/模型/SpatialNet|SpatialNet]]、[[方向/AI语音/模型/ArrayDPS|ArrayDPS]] 评测用）。
- **[[方向/AI语音/数据集/WHAM|WHAM]] / WHAMR!**：wsj0-2mix 叠加真实环境噪声（及加混响版）。
- **[[方向/AI语音/数据集/SMS-WSJ|SMS-WSJ]]**：用全部 WSJ0+1、说话人集合严格不相交的空间化双人混合库，修正了 wsj0-2mix 的划分缺陷。
- **WSJ0-CHiME3 / WSJ0-REVERB / WSJ0-WHAM!**：若干增强论文的自建配方（WSJ0 × CHiME3 噪声 / 仿真 RIR / WHAM 噪声），见 [[方向/AI语音/模型/SGMSE+|SGMSE+]]、[[方向/AI语音/模型/LABNet|LABNet]] 等页。

## 4. 用途

- **经典 ASR 基准**：DARPA CSR 评测体系的首个语料，`dev93` / `eval92` 是传统 ASR 论文的标准测试口径。
- **分离 / 增强仿真底料**：干净、单人、16 kHz、转写齐全，适合按需合成混合、加噪、加混响的训练与评测对。
- **划分兼容**：保留 Kaldi WSJ split 命名，可直接对接现成 ASR recipe（[[方向/AI语音/模型/ESPnet|ESPnet]] 等框架内置）。

## 5. 使用注意

- **LDC 付费授权**：非自由数据；生成任何衍生集（含 wsj0-2mix、SMS-WSJ）都需自备 WSJ0（+WSJ1）授权副本。
- **获取渠道**：
  - **机构 LDC 会员**：LDC 会员按年度制，1993 / 1996 会员年度的机构可免费获取 WSJ0（$0）；先查本校图书馆是否订了 LDC（国外高校如 Princeton / Cornell 走图书馆 linguistics 数据服务申请，国内部分高校与实验室有机构会员），或问所在课题组。
  - **非会员购买**：LDC93S6A 非会员价 $1,500，Reduced-License $750（LDC 目录页 View Fees 口径，2026-10-21 核验）。
  - **衍生集的依赖**：wsj0-2mix / SMS-WSJ 只发布生成脚本，运行时需填入已授权的 WSJ0 原始路径；网上流传的"现成混合文件"无合法授权，不要用。
  - **免费替代**：若目的只是要干净英文朗读语音底料，[[方向/AI语音/数据集/LibriSpeech|LibriSpeech]]（OpenSLR 12，免费）及其混合基准 Libri2Mix / LibriMix 是 WSJ0 / wsj0-2mix 的标准开源替代；只有要复现 WSJ 系论文数字时才必须拿 WSJ0。
- **横比先核口径**：WSJ 系衍生集之间采样率（8k vs 16k）、说话人不重叠性、混合规则、通道数各不相同，指标不能互比（详见 [[方向/AI语音/数据集/SMS-WSJ|SMS-WSJ]] 页「使用注意」）。
- **朗读语音局限**：干净、单人、播音式朗读，与真实会议 / 远场 / 自发语音差异大；仿真合成结果需真实录音二次验证。
- **双麦克风通道**：近讲麦与副麦音质不同，取用数据时确认用的是哪一路（多数衍生集用近讲 Sennheiser 通道）。

## 6. 相关对象

- [[方向/AI语音/数据集/SMS-WSJ|SMS-WSJ]]：WSJ0+1 的空间化双人混合衍生库，修正 wsj0-2mix 划分缺陷。
- [[方向/AI语音/数据集/WHAM|WHAM]]：wsj0-2mix 加真实噪声的衍生基准。
- [[方向/AI语音/评估/CHiME（语音分离与识别挑战赛）|CHiME]]：CHiME-3 任务基于 WSJ0 5k vocabulary 的 noisy ASR。
- [[方向/AI语音/知识/基础概念/SS（语音分离）|SS（语音分离）]]：wsj0-2mix 是该任务的奠基性基准。
- [[方向/AI语音/知识/基础概念/PIT（置换不变训练）|PIT]]：uPIT 在 WSJ0 混合上验证了深度分离的置换不变训练路线。
- [[方向/AI语音/模型/TF-GridNet|TF-GridNet]]：WSJ0-2mix 上的代表性强基线。
- [[方向/AI语音/知识/调研与地图/Array Speech Enhancement Frontier（阵列语音增强前沿调研）|阵列语音增强前沿调研]]：WSJ 系仿真集在经典评测集中的定位。

## 7. 关键来源

- [CSR-I (WSJ0) Complete（LDC93S6A 目录页）](https://catalog.ldc.upenn.edu/LDC93S6A)
  - 内容定位：官方身份与数据口径——NIST 开发、约 141h、123 说话人、16 kHz 16-bit sphere、双麦克风（Sennheiser HMD414 + 副麦）、SRI/TI/MIT 录制、5k/20k 词汇子集、附转写与 bigram 语言模型。
  - 用途：对象身份与数据构成。
  - 核验日期：2026-10-21
- [CSR-I (WSJ0) Sennheiser（LDC93S6B）](https://catalog.ldc.upenn.edu/LDC93S6B) 与 [CSR-I (WSJ0) Other（LDC93S6C）](https://catalog.ldc.upenn.edu/LDC93S6C)
  - 内容定位：单通道子集版本——Sennheiser 近讲麦约 80h，副麦约 84h。
  - 用途：发行版本区分。
  - 核验日期：2026-10-21
- [Deep Clustering: Discriminative embeddings for segmentation and separation（arXiv:1508.04306）](https://arxiv.org/abs/1508.04306)
  - 内容定位：Hershey et al.（ICASSP 2016），提出 deep clustering 并首次以 WSJ0 干净语音构建双说话人混合评测（即 wsj0-2mix 的出处）。
  - 用途：衍生基准的源头核验。
  - 核验日期：2026-10-21

## 8. 待验证

- Kaldi 各划分（si84 / si284 / dev93 / eval92）的精确说话人数、语句数与时长（LDC 目录页未给划分细节，vault 内仅 [[方向/AI语音/数据集/SMS-WSJ|SMS-WSJ]] 页转述命名）。
- **wsj0-2mix 是否值得建独立对象页**：vault 内 10+ 模型页引用该基准但无本体页；若补建，需核 30h 训练子集构成与 20k/5k/3k 生成脚本口径。
- LDC 授权对生成衍生混合集后再分发的具体限制条款。

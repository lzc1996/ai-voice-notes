---
title: Personalized SE（个性化语音分离产品线调研）
aliases:
  - 个性化语音分离
  - Personalized Speech Enhancement
  - Personalized SE
  - Voice Isolation
  - 语音隔离
  - 声纹注册
tags:
  - 方向/AI语音
  - 调研
created: 2026-10-28
---

# Personalized SE（个性化语音分离产品线调研）

## 1. 一句话结论

"个性化语音分离"已从学术 [[方向/AI语音/知识/基础概念/TSE（目标说话人提取）|TSE]] 变成三条成熟产品线——**会议软件声纹注册**（Teams / Zoom）、**TWS 助听与通话**（AirPods Pro 2）、**端侧说话人条件 VAD**（Google Personal VAD）——技术范式统一为"声纹注册 → 说话人 embedding → 条件化流式神经网络"，且全部因果、端侧运行、以 WAcc/主观分而非 PESQ 验收。

## 2. 产品清单（按部署形态）

| 产品（年份） | 个性化机制 | 技术要点 | 公开程度 |
|---|---|---|---|
| **Teams Voice Isolation**（2024-04 GA，Windows 客户端先行） | 30 s 朗读注册，25 语言生成 voice profile；可随时删除 | 只保留注册者声音并滤旁人说话；**2000+ h** 训练数据；显式产品化 over-suppression ↔ leakage 权衡：附近说话人检测→提示临时关闭；被抑制噪声指示器 | 官方博客 + 支持文档；模型架构未公开 |
| **Zoom Personalized Audio Isolation** | 声纹录制 ≥30 s（Smart recognition 体系，可更新/删除） | 同一思路：注册后只传注册者声音 | 支持文档可查；上线时间与底层自研/外采未明 |
| **Apple Voice Isolation**（iOS 15+ Mic Mode） | **无注册、非个性化**——系统级麦克风模式 | 与 Teams 同名不同物：通用降噪+拾音聚焦，不认人 | 官方文档 |
| **AirPods Pro 2 Hearing Aid**（FDA OTC 授权 2024-09，首发 2024-10） | **听力图注册**（5 min 纯音测试 → 个性化听力曲线，或导入医用心电图式 audiogram） | H2 芯片端侧 ML：个性化实时增益、Loud Sound Reduction 48k 次/秒、Conversation Boost（iOS 15 波束）；2019 年构想、等 H2 算力才落地（高管访谈） | 临床验证研究公开（iScience 2022、Apple 赞助 15 万人听力研究）；模型细节闭源 |
| **Google Personal VAD 1.0→2.0**（Odyssey 2020 → Interspeech 2022） | d-vector 注册 + **enrollment-less 泛化**训练 | 不是分离是**说话人条件 VAD**：FiLM 调制 d-vector、流式 Conformer、TFLite 量化端侧（复现模型 <1.4 MB 8-bit）——为 on-device ASR 省算力、防陌生人误唤醒 | 论文 + 开源库（personal-vad）；官方权重未放 |
| **Krisp**（SDK/独立 App） | **无注册**——对照项：通用双向降噪 | 跨 App 虚拟麦克风，端侧处理；"Cancel my/other's noise" | 商业闭源 |
| 智能音箱声纹（Alexa Voice ID / Google Voice Match / HomePod ≤6 人） | 声纹注册 | 只做个性化响应与唤醒，不做波形分离 | 无公开精度数字 |

## 3. 共同技术范式

注册端与运行端解耦，是所有产品的共同骨架：

```
[注册] 30–60 s 朗读 ──→ speaker embedding（d-vector / ECAPA / i-vector）
                                      │（或：纯音测试 ──→ 个性化听力图，Apple 特例）
[运行] 流式因果网络 ←── embedding 条件化（FiLM 调制 / 拼接 / 门控）
```

四个跨产品一致的工程决定：

1. **因果 + 流式**：Teams 的 over-suppression 问题在因果约束下才尖锐（Taherian 等 2022 明确指出 causal PSE 的 trade-off）；pVAD 2.0 直接为 streaming on-device ASR 设计。
2. **端侧部署**：Teams 出现"设备运行应用过多不支持语音隔离"的提示；Apple 依赖 H2 芯片（2019 构想困于算力，2022 H2 才落地）；pVAD 2.0 目标是 <1 MB 级量化模型。
3. **over-suppression ↔ leakage 的产品化**：学术上是 trade-off（cross-task knowledge distillation 用 pVAD 门控缓解），产品上是显式 UI——Teams 检测到附近有人→弹窗提示关闭语音隔离；检测到抑制→自视图噪声指示器。
4. **验收口径是下游可用性**：DNS 2022/2023 Personalized Track 用 WAcc + P.835 主观分，不用 PESQ；Apple 用临床验证与真人听测。与行业 leaderboard 的 WER 口径一脉相承。

## 4. 学术 ↔ 产品对应

| 学术工作 | 产品落点 | 关系 |
|---|---|---|
| DNS Challenge 2022/2023 **Personalized Track**（Microsoft，WAcc+P.835 口径，提供 enrollment clips） | Teams Voice Isolation | 同一公司同一条 PSE 线：挑战赛定义任务形态，产品给出部署答案 |
| [[方向/AI语音/模型/PATSE]] / SpeakerBeam / VoiceFilter（Google 2019） | TSE 产品化起点 | VoiceFilter 首次把 d-vector 条件化做成可部署形态 |
| Taherian et al. 2022（arXiv:2211.02944，cross-task KD + pVAD 门控） | Teams PSE 训练框架（推测） | 解决的正是 Teams 博客里 over-suppression/leakage 那对矛盾 |
| Personal VAD 2.0（Google 2022） | on-device ASR 个性化唤醒 | 学术→产品最完整：论文给出 FiLM、enrollment-less、量化三层方案 |

## 5. 与本库 TSE 概念页的关系

- 产品的"个性化"= [[方向/AI语音/知识/基础概念/TSE（目标说话人提取）|TSE]]（保目标、滤干扰人）+ **个性化增益**（Apple 听力图路线）两条支流；后者不挑"谁在说话"，只挑"你听得见多少"。
- TSE 页 §3 的线索分类（注册语音、声纹、方位）中，**产品线只用第一类**——声纹注册；方位线索留给阵列产品（MXA920 的 Coverage 瓣、BiTSE 类研究）。
- 学术 TSE 与产品的三处差距：注册时长（学术用整段 utterance，产品压到 30 s）、enrollment-less 退化（产品必须回退到普通 VAD/降噪）、因果流式（学术多离线）。

## 6. 对本库复现线的启示

1. **有现成 benchmark 可用**：DNS 2022/2023 Personalized Track 的 enrollment 测试集公开，WAcc + P.835 双口径——TSE 方向若要补"个性化"设定，不需要自建协议。
2. **over-suppression/leakage 是可量化的评测维度**：Taherian 的 KD 框架给了训练侧方案；横评时可加"目标静默期泄漏率"与"同性别干扰误杀率"两列——现有学术清单里都没有这两列。
3. **端侧约束比音质更能改变设计**：H2 才能跑助听、pVAD 压到 1 MB——任何"个性化 SE"方案如果不给 RTF/模型大小档位，就没有讨论价值（呼应 [[方向/AI语音/评估/RTF（实时率）]] 的口径四要素）。

## 7. 关键来源

- [Voice isolation in Microsoft Teams（官方博客 2024-03）](https://techcommunity.microsoft.com/blog/microsoftteamsblog/voice-isolation-in-microsoft-teams-enables-personalized-noise-suppression-for-ca/4096077)——注册流程、2000 h 数据、over-suppression/leakage 机制与指示器设计。核验 2026-10-28。
- [Zoom Personalized audio isolation 支持文档](https://support.zoom.com/hc/en/article?id=zm_kb&sysparm_article=KB0074698)——声纹录制/更新/删除流程。核验 2026-10-28。
- [Apple Newsroom：AirPods Pro 2 听力健康体验（2024-09）](https://www.apple.com/newsroom/2024/09/apple-introduces-airpods-4-and-a-hearing-health-experience-with-airpods-pro-2)与 [Audio Lab 研发过程（2024-10）](https://www.apple.com/sg/newsroom/2024/10/how-apple-developed-the-worlds-first-end-to-end-hearing-health-experience)。核验 2026-10-28。
- [Personal VAD 2.0（arXiv:2204.03793）](https://arxiv.org/abs/2204.03793)——FiLM 调制、enrollment-less、端侧优化三层设计；[开源复现权重](https://huggingface.co/wq2012/personal-vad-v2-conformer-film-dvector)（非官方）。核验 2026-10-28。
- Taherian, Eskimez, Yoshioka. *Breaking the trade-off in personalized speech enhancement with cross-task knowledge distillation*（[arXiv:2211.02944](https://arxiv.org/abs/2211.02944)）——over-suppression/leakage trade-off 与 pVAD 门控训练。
- ICASSP 2022/2023 DNS Challenge 技术报告（Personalized Track，WAcc+P.835 口径、enrollment clips 协议）。

## 8. 相关对象

- [[方向/AI语音/知识/基础概念/TSE（目标说话人提取）]]：本产品线的学术源头，§3 线索分类中产品只用声纹注册一类。
- [[方向/AI语音/团队/Microsoft Speech Group（微软语音组）]]：Teams Voice Isolation 所在的产品链条（DNS Challenge ↔ PSE ↔ 产品）。
- [[方向/AI语音/评估/DNS Challenge（深度噪声抑制挑战）]]：Personalized Track 的协议与口径。
- [[方向/AI语音/知识/调研与地图/Array Speech Enhancement Industry（阵列语音增强工业界方案）]]：硬件与产品形态侧的姊妹页（AirPods/会议硬件）。
- [[方向/AI语音/知识/调研与地图/Array-Agnostic SE Industry（工业界阵列可变语音增强调研）]]：同一批公司的另一条产品线（几何可变），两线在智能眼镜处交汇（ECHI-2）。

## 9. 待验证

- Teams Voice Isolation 是否端侧推理（博客只说 Windows 客户端 + 设备负载提示，未明说本地/云端）、模型架构与参数量（未公开）。
- Zoom Personalized audio isolation 的上线时间、底层自研还是外采（Krisp/自建 PSE）。
- Apple Voice Isolation（Mic Mode）与 Hearing Aid 的模型细节——闭源，无论文；HomePod 多通道处理那篇 ML 博客（2021）是目前唯一较深的官方技术材料，且是老产品。
- 国内会议软件（腾讯会议、飞书、钉钉）是否已有声纹注册式个性化降噪。
- Apple Hearing Aid 的个性化增益是否随助听功能动态自适应（如 Conversation Awareness 联动），公开信息只有产品描述。

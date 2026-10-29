---
markmap:
  initialExpandLevel: 2
  colorFreezeLevel: 2
---

# 阵列语音增强前沿调研（2024–2026）

## 1. 核心判断

### 1.1. 学界：转向空间泛化 + 系统接口
- 从什么转向什么
  - 旧：新架构竞赛
  - 新：空间泛化
    - 未知几何：array-agnostic
    - 已知几何：显式坐标条件化
    - 少麦设备：虚拟麦克风 / 空间上采样
  - 新：真实数据与系统接口
    - 真实数据 / 通用失真
    - AEC / full-duplex / 低延迟
- 不变的部分
  - MVDR / GSS 经典前端在挑战赛仍不可或缺

### 1.2. 工业界：拼端侧 DNN
- 前提
  - 阵列硬件已商品化
- 差异化转移到
  - 端侧 DNN 降噪 / 去混响 / 个性化分离
  - 与 ASR、摘要、助听等上层应用打包

### 1.3. 未来两年重点
- 多通道生成式增强
  - 扩散 / flow + 判别前端的两段式
- 增强与语音大模型
  - 表示级融合

### 1.4. 挑战赛风向
- 系统工程 > 单模型刷指标
  - 数据筛选
  - 级联架构
  - LLM 后处理
- 硬约束
  - 严格延迟（穿戴设备）
  - 主观评测权重上升

## 2. 技术全景：六大方向

### 2.1. 经典-神经混合（当前主流）
- 范式
  - DNN 估时频掩码 → 空间协方差矩阵 → MVDR / GSC 滤波
- 代表工作
  - CUSIDE-array（Interspeech 2024）
    - 流式掩码 MVDR，挑战赛 / 工业主流代表
  - Direction-Preserving MIMO（2026-04）
    - 保向 MIMO Wiener，保留空间线索
    - 算力约为 mask-based NICE 的 1/3
  - WNG-MVDR（2026-06）
    - 可学习白噪声增益，抗阵列失配 / 自噪声
  - Linearly Constrained Deep Beamformer（2026-05）
    - 无失真 + 干扰置零约束直接嵌入训练
  - Listen-first（2026-07，助听）
    - 按输出可懂度选波束配置，低 SNR 占优
- 趋势
  - 可学习协方差与可学习约束向经典框架渗透

### 2.2. 端到端与高效化
- 强基线
  - TF-GridNet、SpatialNet 双路径架构
- 代表工作
  - McNet / Mel-McNet（西湖大学，Interspeech 2025）
    - 多通道 STFT 压到 Mel 域，算力 −60%
    - 输出 enhanced LogMel 直连 ASR
  - Auto-Regressive Multi-Channel SE（Interspeech 2025）
    - 逐帧利用已增强历史帧的空间-时序信息
  - Loose Coupling（Paderborn + NTT，ICASSP 2026）
    - 动态会议 / 说话人移动下频谱与空间模型松耦合
- 技术趋势
  - 复数谱映射已成标配
  - 可学习空间滤波（跨通道 conv、帧级 DOA、GNN）取代手工 IPD / ILD
- 工程方向
  - 与 ASR 联合：串行 → 面向识别的目标函数
  - 轻量化：因果波束形成、chunk 级流式

### 2.3. 生成式多通道化（重点跟踪）
- 主流范式
  - 狭义 SE：判别式空间前端 + 生成式语音精修（两段式）
  - 相邻 SS：ArrayDPS / MeCo 提供扩散逆问题和一步校正范式
  - 直接多通道扩散仍在探索，不能简单说已被取代
- 代表工作
  - ArrayDPS 系列（UIUC × Z.-Q. Wang）
    - ArrayDPS：无监督盲语音分离，不是狭义 SE
    - ArrayDPS-Refine：多通道增强 refiner
    - Uni-ArrayDPS：增强 / 分离统一 refiner
  - MeCo（KAIST，Interspeech 2026，开源）
    - 多通道语音分离 corrector，不是狭义 SE
    - 条件 Mean Flow，单次前向（1 NFE）校正，免迭代 ODE
  - AMDM-SE（BGU，2026）
    - 直接多通道扩散增强
    - 扩散框架内跨通道时频注意力
    - CHiME-3 超单通道扩散基线与强判别式 DNN
- 效率路线
  - Flow Matching 替代扩散：少步、确定性轨迹、易蒸馏
  - Stream.FM：实时流式 flow matching 复原
- 融合方向
  - SELM / GenSE：WavLM 表示量化成 token
  - 与 SpeechLM 共享表示空间 → 增强-理解一体化
- 核心矛盾
  - 生成质量 vs 预测速度
  - 低 SNR 幻觉：编造语音内容，危害助听与 ASR

### 2.4. 阵列泛化 / 任意几何 / 少麦
- 问题
  - IPD 特征绑定固定几何，跨阵列泛化要先拆清几何是否已知
- 阵营 A：Ambisonics 规范空间
  - AmbiDrop（ICASSP 2026）
    - Ambisonics 域编码 + 通道 dropout
  - MSEN（ICASSP 2026）
    - 空间滤波器组投影到圆谐波 / eigenbeam 规范空间
    - 随机平面阵列全面超基线且算力更低
- 阵营 B：显式几何条件化
  - Geo-DConv（上交大，2026-07）
    - 坐标位置编码 + 拓扑感知坐标 Transformer
    - 改造 SpatialNet / TF-GridNet 为 array-invariant
    - RealMAN（32 通道 83.7h 真实数据）验证
- 少麦 / 穿戴路线（Meta）
  - HyBeam：低频原始信号 + 高频波束输出混合
  - Spatial-Magnifier：固定已知几何的少麦空间上采样，不是 array-agnostic

### 2.5. 分布式 / 异步阵列
- 场景
  - 手机 + 耳机 + 笔记本多设备协同拾音
- 关键问题
  - 采样率偏移 SRO
  - 时间偏移 STO
  - 设备动态位置
- 代表工作
  - SAMbA（2023）：分布式 ad-hoc 阵列奠基
  - 窗式交叉注意力（2025）：多设备 SRO / STO 动态对齐
  - CaSNet（ICASSP 2026）：SVD 压缩传输，省带宽 / 能耗
  - FlexIO（ICASSP 2026）：单模型兼容 1–5 麦 × 1–3 说话人

### 2.6. 空间引导 / 多模态
- 空间引导
  - DOA 引导端到端目标说话人提取（2025）
  - PATSE（2026）：长时多方对话按人输出，免显式 diarization
- 多模态
  - Spatial-VisualVoice + MAVE（2025）：可穿戴阵列 + 视觉，面向 AR / VR
  - MISP 2025：多通道远场音视频基准

## 3. 挑战赛风向（佐证）

### 3.1. CHiME 系列
- 定位
  - 偏远场多通道 ASR / diarization
  - 阵列增强是降低 WER 的前端手段
- CHiME-7/8 DASR
  - 远场多设备、任意阵列
  - 优胜套路：EEND-VC / TS-VAD 日志 → GSS 增强 → 多 ASR + LM 重打分
- CHiME-9（2025–2026）
  - MCoRec：360° 音视频多会话
    - 冠军 USTC-NERCSLIP + 讯飞（讯飞六连冠）
  - ECHI：助听 / 智能眼镜
    - 严格 20ms 延迟约束
- CHiME-10（2026-07 公布）
  - 三任务：ECHI-2、URGENT、SG-TSE（眼镜多通道 TSE）
  - 待核：URGENT 是否升级多通道

### 3.2. URGENT（通用失真）
- 任务设定
  - 单模型处理 7 类失真：噪声 / 混响 / 削波 / 带宽 / 编解码 / 丢包 / 风噪
- 2025 → 2026 演变
  - 2025：预测式多阶段架构占优
  - 2026：头部清一色生成 + 判别混合
- 胜负手
  - 数据筛选 [[方向/AI语音/实证研究/Less is More（语音增强数据筛选）|Less is More]]：2500h 精选 700h
- 短板
  - 多通道泛化仍薄弱

### 3.3. DNS Challenge
- 2023 第五届后停办
  - 实时低延迟定位由 URGENT / Clarity / ECHI 承接

## 4. 对我们的启示

### 4.1. 技术选型
- 优先两段式
  - 狭义 SE 优先判别前端 + 生成精修；直接多通道扩散继续观察
- 关注接口形态
  - 波形 / 复数谱 / latent / 是否传 noise SCM
  - training-free vs 联合训练

### 4.2. AEC / 全双工不可省
- 有播放参考的会议 / Agent / 助听链路先处理回声泄漏
- AEC 与 beamforming、VAD、barge-in、低延迟一起评估

### 4.3. 泛化是硬需求
- 判断
  - 未知几何才必须 array-agnostic；已知几何可走坐标条件化或少麦上采样
- 行动
  - 跟踪 Ambisonics / eigenbeam、显式几何、少麦虚拟通道三类路线
  - 评估引入 RealMAN 做评测

### 4.4. 数据即竞争力
- 原则
  - 筛选 > 堆量（URGENT 2026 验证）
- 组合路径
  - 弱监督：波束形成输出作标签
  - 无监督：USDnet++ 去混响
  - 真实数据：RealMAN

### 4.5. 警惕生成式幻觉
- 危害排序
  - 助听 > ASR > 听感
- 控制手段
  - 度量：SpeechBERTScore、下游 WER 反噬
  - 路线：语义 token 指导、双分支、数据筛选

### 4.6. 评测短板
- 空间保真度指标空白
  - ILD / IPD 误差
  - IACC / DOA 偏差
  - 空间 MOS
  - 双耳（binaural）指标
- 内容保真必须跟听感并列
  - WER / CER / CAcc
  - 数字 / 专名 / 弱语音分桶

## 5. 下一步计划

### 5.1. 深挖主题（按优先级）
- P1 两段式接口对比
  - ArrayDPS-Refine（SE refiner）/ Uni-ArrayDPS（SE+SS refiner）/ MeCo（SS corrector）/ PGUSE
  - 精修段修的是什么、接口传什么
- P2 生成式幻觉度量与控制
- P3 增强 → 大模型接口谱系
  - 波形 / LogMel / SSL 表示 / 离散 token 四档
- P4 数据工程方法论
- P5 空间保真度评估体系
- P6 空间泛化 / 少麦路线横评
  - AmbiDrop / Geo-DConv / MSEN / HyBeam / Spatial-Magnifier

### 5.2. 持续跟踪
- CHiME-10 赛制与数据
  - 重点：URGENT 通道配置
- 流式生成延迟-质量权衡
  - MeCo 1 NFE（SS corrector）vs ECHI 20ms 硬约束

### 5.3. 知识库建设
- 对象页已建，下一步补横评
  - AmbiDrop / Geo-DConv / MSEN / HyBeam / Spatial-Magnifier
- 2026-10-09 从 PDF 归档（阵列语音增强_2024-10至2026-10，80 篇）补建 15 页（P0–P2 高优先批）

- 2026-10-15 已补建剩余 40 个 P3–P6 对象页；`2503.09412_RTM-Separation` 为 P1，排除在本批之外；`Spatial-VisualVoice` 已补建独立页。
  - 模型：UniArray / SFB-NSE / REDnet / LABNet / WG-Auto-HOA / Adaptive Rotary Steering / VM-ArrayDPS / VM-UNSSOR / USD-DPS / C2D Projection / CI-Spatial
  - 论文页：Mask-based SE for Spatial Audio / Accurate Room-Acoustic Simulation / Joint Beamforming and SA-ASR
  - 数据集：DRES
  - 前沿调研页与 Array-Agnostic SE 路线页已同步回填；P3–P6 的 40 个对象页已于 2026-10-15 补建完成

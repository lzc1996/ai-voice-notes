---
title: Level（电平）
类型: 概念
发表时间:
时间依据: 音频与信号处理基础术语；非单一发表物
相关任务:
  - 音频数据预处理
  - 语音增强
  - VAD
相关主题:
  - 音频处理
  - 信号处理
  - 增益
aliases:
  - 电平
  - 音频电平
  - 信号电平
  - audio level
  - signal level
  - level
  - waveform level
tags:
  - 类型/对象
  - 方向/AI语音
  - 主题/音频处理
  - 主题/信号处理
  - 主题/增益
---

# Level（电平）

## 1. 身份

`Level`（电平）是信号“有多强”的工程说法。它通常不是一个裸数，而是**相对某个参考点的幅度、功率或声压大小**，常用 dB 表示。

边界：电平不是单独等于音量、响度或采样值。音频里必须先问“哪一种电平”：数字满刻度、声压、电压、RMS、peak，还是响度标准。

## 2. 基本公式

幅度类量（波形幅度、电压、声压）常用：

$$
L = 20\log_{10}\left(\frac{A}{A_{ref}}\right)
$$

功率/能量类量常用：

$$
L = 10\log_{10}\left(\frac{P}{P_{ref}}\right)
$$

所以“多少 dB”本质上是一个**比值**。不写参考点时，dB 只说明相对变化；写成 dBFS、dB SPL、dBV、dBu 时，参考点才固定。

## 3. 音频里的常见电平

| 口径 | 参考点 | 主要用途 |
|---|---|---|
| Peak level | 最大瞬时幅度 | 判断 clipping / headroom |
| RMS level | 均方根幅度 | 粗略衡量平均能量、静音检测、VAD baseline |
| [[方向/AI语音/知识/基础概念/dBFS（满刻度分贝）]] | 数字 full scale | 数字音频文件、PCM、DAW、模型输入 QA |
| [[方向/AI语音/知识/基础概念/SPL（声压级）]] | 空气声压 20 µPa | 声学测量、麦克风校准、噪声合规 |
| LUFS | 主观响度模型参考 | 广播、流媒体、音量一致性 |

## 4. 和相邻词的区别

- **电平 vs 幅度**：幅度是线性样本/电压/声压大小；电平通常是相对参考点后的 dB 表示。
- **电平 vs 增益**：电平描述信号当前有多强；增益描述系统把信号放大或衰减了多少。
- **电平 vs 音量**：音量常是用户/设备旋钮；电平是信号测量口径。
- **电平 vs 响度**：响度是人的主观感知，受频率、时长和听觉模型影响；电平是物理或数字域读数。
- **dBFS vs dB SPL**：前者是数字域满刻度，后者是空气声压；二者换算需要麦克风灵敏度、模拟/数字增益和校准。

## 5. 在 AI 语音里的用途

- **数据 QA**：检查 peak/RMS dBFS、静音、过载 clipping、过低电平和动态范围异常。
- **VAD / 静音裁剪**：低成本 baseline 常用短时 RMS 或 dBFS 阈值，但阈值不能跨设备裸迁移。
- **音量归一化**：训练或评测前统一 peak / RMS / LUFS，减少模型把录音增益当作任务线索。
- **麦克风校准**：用 [[方向/AI语音/知识/基础概念/SPL（声压级）]]、麦克风灵敏度和增益，把数字电平关联到真实声压。
- **增强评估**：语音增强不能只降低噪声，也要避免输出电平过低、过高、削波或 loudness 漂移。

## 6. 常见坑

- **只说“电平”不说参考点**：`-20 dBFS`、`60 dB SPL`、`-10 dBV` 是不同世界。
- **peak 和 RMS 混用**：peak 正常不代表平均能量正常；RMS 正常也不代表没有瞬时 clipping。
- **把 dBFS 当声压**：未经校准的数字电平不能说明真实环境有多吵。
- **把归一化当修复**：归一化只能改整体尺度，不能修复削波、噪声、混响和麦克风频响问题。
- **忽略前处理链路**：重采样、混声道、AGC、降噪和 codec 都可能改变电平读数。

## 7. 相关对象

- [[方向/AI语音/知识/基础概念/dBFS（满刻度分贝）]]：数字音频里最常用的电平参考。
- [[方向/AI语音/知识/基础概念/SPL（声压级）]]：声学空间里的绝对声压电平。
- [[方向/AI语音/知识/基础概念/PCM16（16-bit Pulse Code Modulation）]]：固定点 PCM 与 full scale / clipping 直接相关。
- [[方向/AI语音/知识/基础概念/音频数据预处理]]：格式统一、音量归一、clipping 检测都要明确电平口径。
- [[方向/AI语音/知识/基础概念/AGC（自动增益控制）]]：实时链路里动态改变电平的闭环模块，测量电平前需确认其开关状态。
- [[方向/AI语音/知识/基础概念/Energy-based VAD（基于能量的语音活动检测）]]：基于短时能量或 RMS 电平判断语音活动。

## 8. 关键来源

- [FADGI - Decibels relative to full scale](https://www.digitizationguidelines.gov/term.php?term=decibelsrelativetofullscale)
  - 内容定位：定义 dBFS 是数字系统中相对 full scale 的幅度电平单位。
  - 用途：确认数字电平和 full scale 参考点。
  - 核验日期：2026-09-17
- [librosa.amplitude_to_db 0.10.2](https://librosa.org/doc/0.10.2/generated/librosa.amplitude_to_db.html)
  - 内容定位：记录幅度谱转换为 dB 的工程公式、参考值 `ref` 和动态范围截断 `top_db`。
  - 用途：确认“电平是相对参考点的 dB 比值”这一工程口径。
  - 核验日期：2026-09-17
- [DPA Microphones: What is Sound Pressure Level?](https://www.dpamicrophones.com/mic-university/facts-about-sound/what-is-sound-pressure-level)
  - 内容定位：说明 SPL 使用 20 µPa 作为参考声压，并用 dB 表示声压级。
  - 用途：连接数字电平和声学声压电平的区别。
  - 核验日期：2026-09-17

## 9. 工程待决策

- **QA 字段**：固定记录 `peak dBFS / RMS dBFS / LUFS / clipping rate`；这组字段用于诊断电平、响度和削波，不再作为开放问题。
- **对象结构**：暂不拆 `LUFS`、`Gain`、`Clipping` 三个独立页；当前作为 Level 的相邻词已够用，等出现多条独立引用或实验口径再拆。
- **阈值**：近讲麦、会议麦、手机麦的 dBFS 阈值按设备 / 场景维护，不设一个跨设备默认值；具体阈值留给本地 QA 标定。

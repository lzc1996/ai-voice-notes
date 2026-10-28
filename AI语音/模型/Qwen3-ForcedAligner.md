---
title: Qwen3-ForcedAligner
类型: 模型
参数量: 0.6B
发表时间: 2026-01-29
时间依据: 官方 README 记录的原始发布日期
任务:
  - 强制对齐
  - 时间戳预测
开放状态:
  - paper
  - code
  - weights
aliases:
  - Qwen3-ForcedAligner-0.6B
  - Qwen3-ASR ForcedAligner
tags:
  - 类型/对象
  - 领域/AI语音
  - 任务/ASR
  - 主题/强制对齐
---

# Qwen3-ForcedAligner

## 0. 背景

**问题现场**：ASR 模型输出文本但不内置对齐，强制对齐任务需要在给定文本下输出合法的词级/字符级时间边界。

**前序路线的缺口**：自回归对齐器逐个生成边界，第 $i$ 个边界依赖前 $i-1$ 个，误差沿序列累积。

**Qwen3-ForcedAligner 的切入点**：非自回归（NAR）——所有 unit 的边界在一次前向中并行预测，条件只来自声学表示与文本嵌入，不依赖已预测边界。

## 1. 身份

`Qwen3-ForcedAligner-0.6B` 是 Qwen 团队随 Qwen3-ASR 同线发布的**非自回归（NAR）语音强制对齐模型**：输入音频 + 外部提供的转写文本，输出**词级或字符级**时间边界。官方 README 把它描述为 "a novel non-autoregressive speech forced-alignment model that can align text–speech pairs in 11 languages"，原始发布日期 2026-01-29。

边界：

- **它不是 ASR**。文本由外部提供，文本本身错了对齐同样被拖偏——这一点和 [[方向/AI语音/工具/MFA（强制对齐工具）|MFA]] 的约束一致。
- **不到音素级**。README 只声明 word / character level timestamps，**音素级未声明**。
- **只吃 Speech 音频**。ASR 侧覆盖的唱歌 / 带 BGM 歌曲不在它的 audio type 里。
- **与 `Qwen3-ASR` 是两个独立 checkpoint**。ASR 模型本身不内置对齐，要靠 `forced_aligner=` 参数外挂本模型才拿得到时间戳。

## 2. 核心信息

- **覆盖语言 11 种**：中文、英语、粤语、法语、德语、意大利语、日语、韩语、葡萄牙语、俄语、西班牙语。远少于 Qwen3-ASR 的 52 语言/方言。
- **单段上限 5 分钟**：README 措辞是 "timestamp prediction for arbitrary units within up to 5 minutes of speech"。长音频要自行分段——它的 Concat-300s 基准就是拼接后的口径。
- **推理模式 NAR**，与 Monotonic-Aligner / NFA / WhisperX 这类方案同题对比。
- **包形态**：`qwen_asr`（`pip install -U qwen-asr`），类名 `Qwen3ForcedAligner`，方法 `align()`。
- **权重渠道**：Hugging Face 与 ModelScope 同步；2026-06-26 补齐原生 Transformers 模型卡 `Qwen/Qwen3-ForcedAligner-0.6B-hf`。
- **许可 Apache-2.0**。
- **规模口径有出入**：HF 仓库 safetensors 记录约 917.7M 参数（BF16，架构 `Qwen3ASRForConditionalGeneration`，`model_type=qwen3_asr`），与名称里的 0.6B 对不上，见「待验证」。

## 3. 核心机制

```text
audio + text（外部转写）
  -> ASR encoder 得到声学表示 Z
  -> 文本侧编码为待对齐的 unit 序列（词 / 字符）
  -> NAR 一次前向并行预测每个 unit 的 (start, end)
  -> 单调约束下的时间边界序列
```

分步与公式（以下为该类模型的标准数学形式，Qwen3-ForcedAligner 未公开内部细节的部分已标注）：

- **对齐任务的约束**：给定音频 $X$（总长 $T$）与文本 $y = (y_1, \dots, y_N)$，输出每个 unit 的起止时间 $(s_i, e_i)$。相对 ASR 多出来的就是**单调性**——边界必须沿时间轴不倒退：

$$
\text{Align}(X, y) = \{(s_i, e_i)\}_{i=1}^{N}, \qquad 0 \le s_1 \le e_1 \le s_2 \le e_2 \le \cdots \le e_N \le T
$$

  这正是强制对齐区别于「拿 ASR 时间戳凑数」的地方：ASR 只需输出文本，对齐还要输出一组**合法**的边界。

- **NAR 并行预测**：自回归对齐器逐个生成边界，第 $i$ 个边界依赖前 $i-1$ 个，误差沿序列累积；NAR 让所有 unit 的边界在**一次前向**里同时预测，条件只来自声学表示 $\mathbf{Z}$ 与文本嵌入，不依赖已预测边界：

$$
\hat{\mathbf{y}} = f_\theta\big(\mathbf{Z},\, \mathbf{E}(y)\big) \in \mathbb{R}^{N \times 2}, \qquad \hat{\mathbf{y}}_i = (\hat{s}_i, \hat{e}_i)
$$

  代价是输出本身不保证落在上面那个单调锥内，需要靠训练目标或后处理把 $\hat{\mathbf{y}}$ 约束回合法边界序列。**README 未公开具体做法**（见「待验证」）。

- **评测用 AAS（ms↓）而非 WER**：对齐质量的度量对象就是上面对齐出来的 $\{(s_i, e_i)\}$ 与参考边界的偏差，与识别文本对不对无关。README 只给出 AAS 数值表，**没有给出 AAS 的展开定义**，所以本笔记不臆造公式。

## 4. 测试基准与性能

**Forced Alignment Benchmarks（AAS ms ↓，来源：官方 README）**

| 测试口径 | Qwen3-ForcedAligner-0.6B | Monotonic-Aligner | NFA | WhisperX |
| --- | --- | --- | --- | --- |
| MFA-Labeled Raw | 42.9 | 161.1 | 129.8 | 133.2 |
| MFA-Labeled Concat-300s | 52.9 | 1742.4 | 246.7 | 2708.4 |
| Human-Labeled | 32.4 | 141.3 | 101.2 | — |

**MFA-Labeled Raw 分语言（AAS ms ↓）**：中文 33.1、英语 37.5、法语 41.7、德语 46.5、意大利语 75.5、日语 42.2、韩语 37.2、葡萄牙语 38.4、俄语 40.2、西班牙语 36.8。意大利语明显最差。

**Human-Labeled 分场景**：Raw 27.8、Raw-Noisy 41.8、Concat-60s 25.3、Concat-300s 24.8、Concat-Cross-lingual 42.5。

关键读数：

- **长音频是拉开差距的地方**。Concat-300s 口径下 Qwen 52.9 ms，而 WhisperX 2708.4、Monotonic-Aligner 1742.4——基线的 AAS 涨了 10~50 倍，本模型只从 42.9 涨到 52.9。WhisperX 在意大利语上到 5719.4、西班牙语 4549.9。
- **噪声会拖**：Human-Labeled Raw → Raw-Noisy 是 27.8 → 41.8（+50%）。
- **跨语言拼接最难**：Concat-Cross-lingual 42.5，接近 Raw-Noisy 水平。
- README 表里**没有粤语行**，但语言列表含粤语。

## 5. 复现口径

```python
from qwen_asr import Qwen3ForcedAligner

model = Qwen3ForcedAligner.from_pretrained(
    "Qwen/Qwen3-ForcedAligner-0.6B", dtype=torch.bfloat16, device_map="cuda:0")
results = model.align(audio="asr_zh.wav", text=zh_text, language="Chinese")

print(results[0][0].text, results[0][0].start_time, results[0][0].end_time)
```

接在 ASR 上取时间戳：

```python
results = model.transcribe(audio=audio, language=None,
                          forced_aligner="Qwen/Qwen3-ForcedAligner-0.6B",
                          forced_aligner_kwargs={...},
                          return_time_stamps=True)
# 时间戳在 r.time_stamps[0]
```

- **输入形态**：local path / URL / base64 / `(np.ndarray, sr)`，支持 batch。
- **输出字段**：每个 unit 暴露 `.text`、`.start_time`、`.end_time`；无 JSON schema，无精度/取整约定说明。
- **流式拿不到时间戳**：README 明确写 streaming inference **不支持返回 timestamps**，也不支持 batch；且流式只在 vLLM 后端可用。实时字幕这条路要另想办法。
- **`language` 要显式传**（示例里是 `"Chinese"`），属于 11 种支持语言之内。

## 6. 相关对象

- [[方向/AI语音/模型/Qwen3-ASR|Qwen3-ASR]]：同线发布的 ASR 主线，通过 `forced_aligner=` 外挂本模型取时间戳。
- [[方向/AI语音/工具/MFA（强制对齐工具）|MFA（强制对齐工具）]]：同任务的经典工具路线，可到音素级，但需要发音词典 + 声学模型。
- [[方向/AI语音/工具/Audio Speech Analysis Toolchain（音频语音分析工具链）|音频语音分析工具链]]：WhisperX、pyannote.audio、MFA、Praat 等转写/对齐/说话人入口。
- [[方向/AI语音/MOC - ASR|MOC - ASR]]：本模型所属方向索引。
- [[方向/AI语音/选型/ASR 模型选型矩阵|ASR 模型选型矩阵]]：把 Qwen3-ForcedAligner 作为强制对齐首选的选型结论。
- [[方向/AI语音/选型/Qwen 语音模型技术路线图|Qwen 语音模型技术路线图]]：Qwen 语音线里 ASR 与 ForcedAligner 的技术分工。
- [[方向/AI语音/评估/WER（词错误率）|WER（词错误率）]]：ASR 侧指标；对齐质量看 AAS，不看 WER。
- [[方向/AI语音/模型/Whisper|Whisper]]：其 WhisperX 派生方案是 AAS 基准里的直接对照。

## 7. 关键来源

- [Qwen3-ASR README](https://github.com/QwenLM/Qwen3-ASR/blob/main/README.md)
  - 内容定位：官方开源仓库 README，记录模型族、11 种对齐语言、5 分钟上限、NAR 定位、`Qwen3ForcedAligner` 用法、AAS 评测表和流式限制。
  - 用途：模型身份、用法、评测数字和限制的一手依据。
  - 核验日期：2026-09-15
- [Qwen/Qwen3-ForcedAligner-0.6B](https://huggingface.co/Qwen/Qwen3-ForcedAligner-0.6B)
  - 内容定位：Hugging Face 模型仓库，标注 Apache-2.0、`qwen3_asr` 架构、参数量与文件清单。
  - 用途：确认权重开放、许可和规模口径。
  - 核验日期：2026-09-15
- [Qwen3-ASR Technical Report](https://arxiv.org/abs/2601.21337)
  - 内容定位：技术报告，记录 Qwen3-ASR 与强制对齐模型的设计和系统评测。
  - 用途：引用机制与评测结论时的论文依据。
  - 核验日期：2026-09-15

## 8. 待验证

- **AAS 的定义**：README 只给数值，没给展开公式；要对齐口径必须回技术报告确认。
- **参数规模矛盾**：名称 0.6B vs HF safetensors 记录的约 917.7M。需确认是命名惯例还是统计口径（含 embedding）差异。
- **粤语对齐是否实测**：语言列表含粤语，但对齐基准表没有粤语行。
- **NAR 输出如何保证单调**：训练目标里怎么约束边界不倒退，README 未公开。
- **超 5 分钟的分段策略**：分段点附近的边界质量，以及与 Concat-300s 基准口径的对应关系。
- **与 MFA 的正面比较**：本仓库基准只对比 Monotonic-Aligner / NFA / WhisperX，缺 MFA 本体，也缺中文方言。
- **流式场景的替代方案**：既然流式不支持时间戳，实时字幕的时间戳校准要走什么链路。

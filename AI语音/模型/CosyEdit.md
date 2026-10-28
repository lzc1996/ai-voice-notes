---
title: CosyEdit
类型: 模型
参数量: 约 400M
发表时间: 2026-01-08
时间依据: arXiv v1 首次提交日
任务:
  - 语音编辑
  - TTS
开放状态:
  - paper
  - code
  - weights
aliases:
  - Cosy Edit
  - "CosyEdit: Unlocking End-to-End Speech Editing Capability from Zero-Shot Text-to-Speech Models"
tags:
  - 类型/对象
  - 方向/AI语音
  - 任务/语音编辑
  - 任务/TTS
  - 主题/语音生成
---

# CosyEdit

## 0. 背景

**问题现场**：需要端到端的语音编辑能力，把“源语音 + 文本编辑指令”映射为编辑后的语音，重点处理多段内容的插入、删除和替换。

**CosyEdit 的切入点**：不新增复杂编辑架构，而是基于 CosyVoice zero-shot TTS 基座做 task-specific post-training，直接解锁编辑能力。

## 1. 内容定位

CosyEdit 是一个从 zero-shot TTS 模型解锁端到端语音编辑能力的模型，基于 [[方向/AI语音/模型/CosyVoice|CosyVoice]] 做 task-specific post-training。它把“源语音 + 文本编辑指令”映射为编辑后的语音，重点处理多段内容的插入、删除和替换。

边界：它不是通用音频大模型，也不是独立的声码器或 tokenizer；更适合放在「TTS 基座复用 + 语音编辑」路线下。官方代码同时保留原始 CosyVoice TTS 能力。

## 2. 核心信息

- **基座**：FunAudioLLM/CosyVoice-300M。
- **规模**：论文报告约 400M 参数。
- **训练**：论文报告使用约 250 小时有监督 GigaEdit 数据；模型卡将公开数据集入口标为 CJY/GigaEdit-S。
- **编辑任务**：支持一次推理中的多段 insertion / deletion / substitution，并尽量保持编辑前后语音一致性。
- **开放形态**：论文、GitHub 实现和 Hugging Face 权重均已公开；官方仓库与模型卡标注 Apache-2.0。

## 3. 核心机制

源语音 + 文本编辑指令 -> CosyVoice 语音生成链路 -> task-specific post-trained model -> 编辑后语音

当前可确认的关键点不是新增一套复杂编辑架构，而是通过任务特定的后训练，把原本面向 zero-shot TTS 的生成模型扩展到语音编辑。span 级编辑的对齐细节、训练配方和推理时长约束待进一步核对。

设 $a_{src}$ 为源语音，$r$ 为包含插入、删除或替换操作的文本编辑指令，$G_{\mathrm{base}}$ 为 CosyVoice 基座，$\Delta_{\phi}$ 为编辑任务后训练得到的参数增量，则编辑输出可抽象为：

$$
\hat{a}_{edit}=G_{\mathrm{base}+\Delta_{\phi}}(a_{src},r)
$$

其中 $\Delta_{\phi}$ 改变的是条件解析与语音生成行为；具体的 span 对齐和时长处理仍由实现决定。

### 3.1. 架构示意（概念级）

> [!note] 架构示意（概念级）
> 按本页已有输入—中间表示—输出链路整理，不替代论文结构图。

```mermaid
flowchart LR
  A["源语音 + 文本编辑指令"] --> B["CosyVoice-derived speech editing model"]
  B --> C["Insertion / deletion / substitution"]
  C --> D["编辑后语音"]
```

## 4. 使用判断

- 看**技术路线**：它是“先有高质量 zero-shot TTS，再用编辑数据做能力解锁”的直接案例。
- 看**编辑对比**：适合与 [[方向/AI语音/模型/Ming-UniAudio|Ming-UniAudio]]、[[方向/AI语音/模型/AuK|AuK]]、[[方向/AI语音/模型/SpeechX|SpeechX]] 对照，分别比较统一表示、生成/编辑一体化和 task-dependent prompting。
- 看**工程落地**：优先实测长文本、连续多段编辑、编辑边界自然度、说话人一致性、RTF 与显存；论文结果不能直接替代本地复测。

## 5. 相关对象

- [[方向/AI语音/MOC - 音频大模型|音频大模型]]：本页归属的方向地图。
- [[方向/AI语音/MOC - TTS|TTS]]：CosyEdit 的 TTS 基座和声音生成背景。
- [[方向/AI语音/模型/CosyVoice|CosyVoice]]：基座模型家族。
- [[方向/AI语音/模型/Ming-UniAudio|Ming-UniAudio]]：统一连续表示 + free-form speech editing 对照。
- [[方向/AI语音/模型/AuK|AuK]]：统一生成、编辑、增强与分离的近邻。
- [[方向/AI语音/模型/SpeechX|SpeechX]]：neural codec language model 的语音编辑对照。
- Step-Audio-EditX：同期编辑专用路线；当前未建立独立对象页。

## 6. 来源

- [CosyEdit: Unlocking End-to-End Speech Editing Capability from Zero-Shot Text-to-Speech Models](https://arxiv.org/abs/2601.05329)
  - 内容定位：官方论文，记录 CosyEdit 的模型身份、约 400M 参数、约 250 小时 GigaEdit 监督数据和端到端语音编辑定位。
  - 用途：确认核心机制与研究结论。
  - 核验日期：2026-09-22
- [CJY1018/CosyEdit](https://github.com/CJY1018/CosyEdit)
  - 内容定位：官方代码仓库，提供 CosyVoice 兼容实现、模型下载、推理和多段插入/删除/替换说明。
  - 用途：确认工程入口、开放状态和任务接口。
  - 核验日期：2026-09-22
- [CJY/CosyEdit](https://huggingface.co/CJY/CosyEdit)
  - 内容定位：官方模型卡，列出 CosyVoice-300M 基座、GigaEdit-S 数据集入口和 Apache-2.0 许可标注。
  - 用途：确认权重与数据集入口。
  - 核验日期：2026-09-22

## 7. 待验证

- 论文中 span 编辑的精确输入格式、对齐方式和多段编辑边界。
- 中文长文本、多说话人和连续多轮编辑的内容一致性与音色保持。
- 本地 GPU 上的首包延迟、RTF、显存占用和编辑长度上限。
- 公开权重、训练数据和下游商用场景的许可证兼容性。

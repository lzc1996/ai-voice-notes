---
title: SQUIM（语音质量无参考评估）
类型: 工具
发表时间:
时间依据: torchaudio 语音质量估计模型；非单一工具论文笔记
相关主题:
  - 语音增强评估
  - 无参考指标
  - MOS
aliases:
  - SQUIM
  - Speech Quality and Intelligibility Measures
  - 语音质量无参考评估
tags:
  - 类型/工具
  - 方向/AI语音
  - 主题/评估
---

# SQUIM（语音质量无参考评估）

## 1. 身份

`SQUIM` 是 torchaudio 里的语音质量 / 可懂度估计示例和模型入口，常用来做无参考或少参考的增强结果打分。

## 2. 什么时候用

- 没有 clean reference，但想估计增强语音的质量、可懂度或 MOS。
- 快速批量筛查模型输出，找明显坏样本。
- 和 [[方向/AI语音/评估/PESQ]]、[[方向/AI语音/评估/STOI 与 ESTOI]]、[[方向/AI语音/评估/SI-SDR]] 组成评估面板。

## 3. 边界

- 无参考指标不能替代人工听测，也不能保证内容没被生成式模型改写。
- 语音增强尤其要同时看 CAcc / ASR、说话人相似度和主观 MOS。

## 4. 安装方式

SQUIM 不需要单独安装，跟随 [[方向/AI语音/工具/torchaudio（PyTorch 音频工具库）]]：

```bash
python -m pip install torch torchaudio matplotlib
```

最小验证：

```python
from torchaudio.pipelines import SQUIM_OBJECTIVE, SQUIM_SUBJECTIVE
SQUIM_OBJECTIVE.get_model()
SQUIM_SUBJECTIVE.get_model()
```

## 5. 内网迁移

- 包：按 torchaudio 的 wheelhouse / conda-pack 方式迁移。
- 权重：联网机设置 `TORCH_HOME`，运行上面的验证代码触发 SQUIM 权重下载，然后把 `TORCH_HOME` 拷到内网。
- 内网验证：断网后重新运行 `SQUIM_OBJECTIVE.get_model()`，能加载才算缓存完整。

## 6. 外部入口

- [torchaudio SQUIM tutorial](https://pytorch.org/audio/stable/tutorials/squim_tutorial.html)

## 7. 相关对象

- [[方向/AI语音/工具/torchaudio（PyTorch 音频工具库）]]
- [[方向/AI语音/评估/语音增强评估指标体系]]
- [[方向/AI语音/评估/OVRL_MOS]]

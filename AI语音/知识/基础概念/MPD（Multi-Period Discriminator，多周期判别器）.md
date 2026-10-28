---
title: "MPD（Multi-Period Discriminator，多周期判别器）"
类型: 概念
相关任务:
  - vocoder
  - 语音合成
  - waveform synthesis
  - adversarial training
aliases:
  - HiFi-GAN MPD
  - HiFi-GAN Multi-Period Discriminator
  - Multi-Period Discriminator
  - Period Discriminator
  - 多周期判别器
  - 多周期判别网络
  - MPD
tags:
  - 类型/对象
  - 方向/AI语音
  - 任务/TTS
  - 主题/vocoder
  - 主题/生成对抗网络
---

# MPD（Multi-Period Discriminator，多周期判别器）

## 1. 身份

`MPD`（Multi-Period Discriminator）是 HiFi-GAN 中用于约束波形周期结构的判别器集合。它不是完整的 vocoder，也不是音高检测器；它接收真实或生成的 waveform，判断其是否具有自然的周期性、谐波和局部波形结构。

MPD 的核心做法是为多个采样点周期建立并行子判别器，把一维波形按不同周期重排成二维张量，再用二维卷积识别周期模式。

## 2. 核心机制

```text
waveform x
  -> for p in {2, 3, 5, 7, 11}: 补齐并按 p 重排为 [T / p, p]
  -> 2-D convolutional discriminator D_p
  -> 多个 period branch 的 adversarial / feature-matching 信号
```

对某个周期 $p$，可把波形片段写成近似的二维视图：

$$
x^{(p)} = \operatorname{reshape}(x, [T/p, p])
$$

不同的 $p$ 让判别器从不同的采样周期观察同一波形。并行分支共同覆盖基频、谐波和周期性瞬态；`{2, 3, 5, 7, 11}` 是 HiFi-GAN 的经典设置，但这些数字是**采样点周期**，不是固定的 Hz 音高。

## 3. 在 HiFi-GAN 训练中的作用

- **约束周期性**：对有声段的基频和谐波结构尤其敏感，减少过平滑、断裂和不自然振铃。
- **提供多视角梯度**：生成器同时面对多个 period branch，不能只在单一时间尺度上“骗过”判别器。
- **配合其他损失**：通常与 adversarial loss、discriminator feature matching，以及多尺度判别或频谱重建约束一起使用；MPD 单独不能覆盖所有噪声、瞬态和宽带结构。

## 4. 和邻近结构的区别

| 结构 | 观察方式 | 主要作用 |
|---|---|---|
| MPD | 按多个 period 重排同一 waveform，再做 2-D 判别 | 学习周期、基频和谐波结构 |
| Multi-Scale Discriminator（MSD） | 在不同时间分辨率/下采样尺度观察 waveform | 覆盖更宽的时间尺度和整体波形真实性 |
| Generator | 从 mel 或其他声学表示生成 waveform | 负责合成，不负责判别 |
| Multi-Resolution STFT loss | 显式比较多个 STFT 分辨率 | 提供频谱重建约束，不是 learned discriminator |

因此，MPD 是 `vocoder -> waveform` 训练链路中的判别侧组件，不能把它当成另一个声码器或后处理器。

## 5. 使用边界与待验证点

- 周期列表、补齐方式和卷积配置都是架构超参数；换采样率后，原来的采样点周期对应的物理频率覆盖会改变，不能直接假设等价。
- MPD 对有声周期结构很有用，但对清辅音、噪声、瞬态和非周期音效不充分，通常需要 MSD、频谱损失或其他判别器配合。
- 它不是显式的 F0 estimator；某个分支学到的是可判别的周期模式，不等于输出一个音高值。
- 需要在本地实现中核对各 period branch 的 padding、输出 shape、权重归一化和 loss 权重，再比较 MPD-only 与 MPD+MSD 的听感和稳定性。

## 6. 相关对象

- [[方向/AI语音/知识/基础概念/Vocoder（声码器）]]：MPD 是声码器训练中的判别侧组件。
- [[方向/AI语音/模型/BigVGAN]]：HiFi-GAN 风格 GAN vocoder 的后续对照；具体是否复用相同 MPD 配置应以实现为准。
- [[方向/AI语音/模型/AuK]]：其 VAE 训练配方明确使用 LS-GAN 与 MPD 周期集合 `{2, 3, 5, 7, 11}`。
- [[方向/AI语音/MOC - TTS]]：MPD 所在的 TTS waveform synthesis 输出链路。
- [[方向/AI语音/知识/技术路线/语音网络结构与模块]]：声码器及其训练模块的上层结构入口。

## 7. 关键来源

- [HiFi-GAN: Generative Adversarial Networks for Efficient and High Fidelity Speech Synthesis（arXiv:2010.05646）](https://arxiv.org/abs/2010.05646)
  - 内容定位：HiFi-GAN 原始论文，定义 MPD 的多周期重排思路、并行 period branches 及其与其他训练损失的关系。
  - 用途：确认 MPD 的模型身份和核心机制。
- [jik876/hifi-gan（GitHub）](https://github.com/jik876/hifi-gan)
  - 内容定位：官方实现与训练入口，可核对 `MultiPeriodDiscriminator`、period 列表、padding 和 feature matching 实现。
  - 用途：进行代码级结构和配置核验。

## 8. 待验证

- [ ] 在当前采样率和 segment length 下，`{2, 3, 5, 7, 11}` 对中文语音、方言和非语音音效的覆盖是否仍合适。
- [ ] 对比 MPD-only、MPD+MSD 和 MPD+multi-resolution STFT 的音质、稳定性与训练成本。
- [ ] 核对 HiFi-GAN 官方实现中的 padding、各层输出和 loss 权重，并记录可复现实验配置。

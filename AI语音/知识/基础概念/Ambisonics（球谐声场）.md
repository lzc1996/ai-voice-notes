---
title: Ambisonics（球谐声场）
类型: 概念
相关主题:
  - 阵列信号
  - 空间音频
aliases:
  - Ambisonics
  - ambisonics
  - Ambisonic
  - 全景声
  - 球谐声场
tags:
  - 类型/对象
  - 方向/AI语音
  - 主题/阵列信号
  - 主题/空间音频
---
# Ambisonics（球谐声场）

## 1. 身份

Ambisonics 是一种**场景中心（scene-based）的空间声场表示**：不记录"哪个麦克风收到什么"，而是把空间中某点的声场分解到球谐基上，用一组球谐系数通道描述该点的完整三维声场。

最小直觉：

```text
原始多通道波形（绑阵列几何）
  -> 编码：各通道 × 球谐基权重求和 -> 球谐系数通道（场景表示）
  -> 解码：球谐系数 × 目标重放几何 -> 任意扬声器布局 / 双耳信号
```

N 阶 Ambisonics 的表示是一个 $(N+1)^2$ 维的球谐系数向量：

$$\mathbf{a}_{nm}(f) = [a_{00},\, a_{1(-1)},\, a_{10},\, a_{11},\, \dots,\, a_{NN}]^T$$

其中一阶（FOA，First-Order Ambisonics）即经典的 **[[方向/AI语音/知识/基础概念/B-format（一阶 Ambisonics）|B-format]]**：W（全指向）+ X/Y/Z（三个正交 8 字形指向），共 4 通道；二阶 9 通道、三阶 16 通道。通道排序与归一化常用 **[[方向/AI语音/知识/基础概念/ACN（Ambisonics 通道编号）|ACN]]/SN3D** 约定（AmbiX），一阶的通道细节（FuMa / AmbiX）见该页。

边界：Ambisonics 不是[[方向/AI语音/知识/基础概念/Beamforming（波束形成）|波束形成]]，也不是最终的双耳渲染。它是一层**中间表示**：编码侧把任意阵列压成几何无关的规范声场；解码侧再把声场渲染到任意重放设备。

## 2. 常见类型

- **[[方向/AI语音/知识/基础概念/B-format（一阶 Ambisonics）|FOA / B-format]]**：一阶，4 通道（W/X/Y/Z）。空间分辨率低：仅靠一阶指向性无法区分上下、前后的精细方向差异，但计算便宜、稳健，录音设备（如 Soundfield 类麦克风）和消费级 360° 音频常用；FuMa 与 AmbiX 的通道顺序、归一化差异见该页。
- **[[方向/AI语音/知识/基础概念/Higher-Order Ambisonics（高阶 Ambisonics）|HOA（Higher-Order Ambisonics）]]**：通常指二阶及以上；完整三维展开到 $N$ 阶有 $(N+1)^2$ 个通道。阶数越高空间分辨率越高，但受空间混叠限制——有效阶数与 $kr$（波数 × 阵列/头部半径）相关，高频需要更多通道，实际系统常在 1–5 阶之间折中。
- **AmbiX / ACN+SN3D 等编码约定**：同一组球谐系数的通道排序与归一化方式，工程互通时必须声明。

## 3. 在语音系统里的位置

```text
multichannel waveform（任意阵列）
  -> 球谐编码 / eigenbeam 变换
  -> Ambisonics 系数（几何无关规范空间）
  -> 在此域做 SE / 分离 / 声源定位 / 事件检测
  -> 双耳解码 / 扬声器重放 / 下游单通道 SE
```

Ambisonics 在语音链路里的核心作用是**解耦阵列几何**：模型在球谐域训练后，换一个麦克风阵列只需重做编码器，主体网络不变。这正是 [[方向/AI语音/知识/技术路线/Array-Agnostic SE（阵列无关语音增强）]] 路线选它做规范空间的原因。

声学上，编码后的系数通道常做**三分解**：

$$\mathbf{a}_{nm}(f) = \mathbf{a}_{nm}^{dir}(f) + \mathbf{a}_{nm}^{rev}(f) + \mathbf{a}_{nm}^{noise}(f)$$

即直达声、混响声与噪声在球谐域可加分解（见 [[方向/AI语音/实证研究/Mask-based SE for Spatial Audio（掩蔽增强三域对比）]] §3.3 Eq.2）。最终双耳渲染：

$$b^{l/r}(f) = \tilde{\mathbf{h}}^{l/r}_{nm}(f)^{T}\,\mathbf{a}_{nm}(f), \qquad \tilde{h}_{nm} = (-1)^m\, h_{n(-m)}$$

其中 $\mathbf{h}_{nm}$ 为球谐域 HRIR（同上 Eq.11）。

## 4. 使用注意

- **关键性质：几何无关 / 旋转等变**。声场整体旋转对应球谐系数的一组线性变换（Wigner-D 矩阵），表示本身不含阵列几何信息——这是它在 array-agnostic 与可旋转声场任务里的根本价值。
- **分辨率受阶数硬约束**。一阶解不了上下前后；要更细的空间分辨必须升阶，通道数按 $(N+1)^2$ 增长，高频还受空间混叠（$kr$ 上限）约束。
- **编码依赖已知几何与标定**。从真实阵列编码到球谐域需要准确的麦克风位置、同步和增益；标定误差会直接污染所有系数通道。
- **是表示，不是增强**。Ambisonics 本身不去噪不分离，只是把信号换到规范空间；SE/分离模型仍需在系数上做文章。
- **通道约定要说清**。ACN/SN3D、FuMa 等约定混用会导致系数错位，复现论文或接外部工具时先核对约定。

## 5. 和相邻概念的区别

| 概念 | 表示中心 | 和 Ambisonics 的关系 |
| ---- | -------- | -------------------- |
| [[方向/AI语音/知识/基础概念/Array Audio Signal（阵列音频信号）]] | 麦克风中心 | 原始波形绑定阵列几何；Ambisonics 把它编码成几何无关表示 |
| [[方向/AI语音/知识/基础概念/Beamforming（波束形成）]] | 方向中心 | 波束输出绑定 look direction，是"听某个方向"；Ambisonics 保留整个声场，可事后解码任意方向 |
| 双耳信号（Binaural） | 听者中心 | 绑定听者 HRTF 与头朝向；Ambisonics 经 HRTF 解码才得到双耳信号 |

一句话：原始波形绑**设备**、波束绑**方向**、双耳绑**听者**——Ambisonics 是三者之间**场景中心**的中间层。

## 6. 关键来源

- [Ambisonics: A Practical 3D Audio Theory for Recording, Studio Production, Sound Reinforcement, and Virtual Reality — Zotter & Frank, SpringerOpen 2019](https://link.springer.com/book/10.1007/978-3-030-17207-7)
  - 内容定位：Ambisonics 实践导向的系统教材（Springer Topics in Signal Processing, vol. 19），覆盖球谐编码、阶数与分辨率、解码与双耳渲染。
  - 用途：本页球谐表示、$(N+1)^2$ 通道数、阶数-分辨率折中的主要依据；开放获取。
  - 核验日期：2026-10-15
- [Periphony: With-Height Sound Reproduction — M. A. Gerzon, JAES vol. 21, no. 1, pp. 2–10 (1973)](https://aes2.org/publications/elibrary-page/?id=2012)
  - 内容定位：Gerzon 提出含高度信息的环绕声（Periphony）原始论文，一阶 B-format 体系的源头。
  - 用途：术语史与 FOA 原始出处。
  - 核验日期：2026-10-15
- [Mask-based Speech Enhancement for Spatial Audio（arXiv:2609.18532）](https://arxiv.org/abs/2609.18532)
  - 内容定位：在 Ambisonics 球谐域做掩蔽式 SE，给出三分解（直达/混响/噪声）与双耳解码公式。
  - 用途：本页 §3 三分解公式与双耳解码公式的直接出处。
  - 核验日期：2026-10-15

## 7. 相关对象

- [[方向/AI语音/知识/基础概念/Array Audio Signal（阵列音频信号）|Array Audio Signal]]：编码到 Ambisonics 之前的原始输入。
- [[方向/AI语音/知识/基础概念/Spherical Harmonics（球谐函数）]]：HOA 球谐展开所用的角向正交基函数。
- [[方向/AI语音/知识/基础概念/Beamforming（波束形成）|Beamforming]]：同域常被混淆的方向中心方案；eigenbeam 即球谐域波束，与 Ambisonics 编码同构。
- [[方向/AI语音/知识/基础概念/ILD（双耳声级差）|ILD]]：双耳线索；Ambisonics 双耳解码后保留/重造这些线索。
- [[方向/AI语音/模型/AmbiDrop|AmbiDrop]]：在 Ambisonics 域做 dropout 训练以实现阵列鲁棒的模型。
- [[方向/AI语音/知识/基础概念/ASM（Ambisonics 信号匹配编码）|ASM]]：任意阵列编码进本域的信号无关线性编码器，AmbiDrop 的推理前端。
- [[方向/AI语音/模型/MSEN（特征束多阶编码器）|MSEN]]：多通道 SE 模型，其规范化表示选择与 Ambisonics 同路。
- [[方向/AI语音/知识/基础概念/Higher-Order Ambisonics（高阶 Ambisonics）|HOA（Higher-Order Ambisonics）]]：Ambisonics 中二阶及以上的展开形式。
- [[方向/AI语音/知识/基础概念/B-format（一阶 Ambisonics）|B-format]]：Ambisonics 的一阶通道格式（W/X/Y/Z），含 FuMa 与 AmbiX 编码约定。
- [[方向/AI语音/模型/WG-Auto-HOA|WG-Auto-HOA]]：在 HOA 域做空间音频任务的模型。
- [[方向/AI语音/实证研究/Mask-based SE for Spatial Audio（掩蔽增强三域对比）]]：球谐域掩蔽 SE 的论文页，本页公式出处。
- [[方向/AI语音/知识/技术路线/Array-Agnostic SE（阵列无关语音增强）]]：以 Ambisonics / eigenbeam 为几何无关规范空间的技术路线。

## 8. 词源与术语历史

**Ambisonic** 由拉丁语 *ambi-*（周围、四面八方）+ *sonic*（声音）构成，指"覆盖全方向的声音"。

- **1973**：英国数学家/声学家 **Michael Gerzon**（牛津）在 JAES 发表 *Periphony: With-Height Sound Reproduction*，提出含高度的全三维环绕声体系，奠定一阶 B-format（W/X/Y/Z 四通道）。
- **1970s–80s**：Gerzon 与 Soundfield 麦克风等录音硬件推动 FOA 商业化；"Ambisonics" 成为该体系名称。因生不逢时（与四声道立体声商业竞争失败）一度边缘化。
- **1990s–2000s**：学界将一阶体系推广到任意阶球谐表示，形成 [[方向/AI语音/知识/基础概念/Higher-Order Ambisonics（高阶 Ambisonics）|HOA（Higher-Order Ambisonics）]]；VR/360° 视频兴起后 Ambisonics 作为旋转等变的场景表示复兴，成为 VR 音频事实标准之一。

## 9. 待验证

- [ ] Gerzon 1973 论文页码与 JAES 卷期已按常见引用记录（vol. 21, no. 1, pp. 2–10），建议对照 AES E-Library 原文再核一次。
- [ ] Ambisonics 在四声道竞争中的商业史叙述来自二手综述，未查一手史料。
- B-format/FOA 已拆为独立页 [[方向/AI语音/知识/基础概念/B-format（一阶 Ambisonics）]]；ACN 排序约定已拆为独立页 [[方向/AI语音/知识/基础概念/ACN（Ambisonics 通道编号）]]；SN3D 归一化细节与 eigenbeam 编码仍合并在本页。

---
title: Praat（语音学分析工具）
类型: 工具
发表时间:
时间依据: 长期维护的语音学工具；非单一论文
相关主题:
  - 语音分析
  - 语音学
  - 声学特征
aliases:
  - Praat
  - 语音学分析工具
tags:
  - 类型/工具
  - 方向/AI语音
  - 主题/语音分析
---

# Praat（语音学分析工具）

## 1. 身份

`Praat` 是语音学里最常用的桌面分析工具之一，用来查看 waveform、[[方向/AI语音/知识/基础概念/Spectrogram（声谱图）]]、[[方向/AI语音/知识/基础概念/F0（基频）|pitch / F0]]、[[方向/AI语音/知识/基础概念/Formant（共振峰）]]、intensity，并做标注、切分和简单合成 / 变换。

## 2. 什么时候用

- 检查模型输出是否有喷麦、削波、振铃、尾音拖影、音高异常。
- 看 [[方向/AI语音/知识/基础概念/F0（基频）]]、[[方向/AI语音/知识/基础概念/Formant（共振峰）]]、intensity，分析发音、韵律和共振峰。
- 做少量人工标注或声学诊断，不适合大规模训练流水线。

## 3. 当前语音增强用途

- 对比 noisy / enhanced / clean 的声谱图和 [[方向/AI语音/知识/基础概念/F0（基频）|pitch track]]。
- 检查生成式增强是否改写音色或声调。
- 作为 [[方向/AI语音/工具/Audio Speech Analysis Toolchain（音频语音分析工具链）]] 里的人工听看入口。

## 4. 快速使用流程

1. 打开音频：`Praat Objects` 窗口中选择 `Open` -> `Read from file...`，导入 `.wav` / `.flac` 等音频。
2. 进入编辑视图：选中 `Sound` 对象，点击 `View & Edit`，进入 waveform + [[方向/AI语音/知识/基础概念/Spectrogram（声谱图）]] 编辑窗口。
3. 打开显示层：在编辑窗口中按需要开启 `Spectrum` -> `Show spectrogram`、`Pitch` -> `Show pitch`、`Formant` -> `Show formants`、`Intensity` -> `Show intensity`。
4. 选区听诊：拖选一段音频，反复播放选区；先听主观异常，再看频谱、[[方向/AI语音/知识/基础概念/F0（基频）]]、formant 和 intensity 是否对应。
5. 保存派生对象：需要导出分析结果时，在对象窗口生成 Pitch / Formant / Intensity / TextGrid 对象，再另存为文本或表格。

## 5. 常用任务

### 5.1. 看声谱图

- 适合检查：削波、宽带噪声、窄带电流声、混响尾巴、高频伪影、频带缺失。
- 起步设置：语音通常先看 `0-8000 Hz`；宽带 TTS / 48 kHz 音频可再看更高频段。
- 判断方式：clean / noisy / enhanced 三条音频对齐听看，重点看增强后是否新增不随语音同步的纹理或孤立频带；详细读图口径见 [[方向/AI语音/知识/基础概念/Spectrogram（声谱图）]]。

### 5.2. 看 Pitch / F0

- 适合检查：音高断裂、机械抖动、声调被改写、TTS 韵律不自然。
- 成人男声可先试 `75-300 Hz`，成人女声可先试 `100-500 Hz`，儿童 / 歌声需要更高上限。
- 读轴方式：蓝色 pitch 轨迹按右侧蓝色 pitch 轴读，红色 formant 点按左侧 spectrogram 频率轴读；蓝线视觉上高于最低红点线，不等于 F0 高于 `F1`。
- 如果右侧 pitch 轴是 `50-800 Hz`，蓝线对应约 `90 Hz`，这就是约 `90 Hz` 的 F0，不是左侧频谱轴上的 1 kHz。
- 不要把 pitch track 断开直接等同于错误；清音、弱音、噪声段本来可能没有稳定 [[方向/AI语音/知识/基础概念/F0（基频）]]。详细概念见 [[方向/AI语音/知识/基础概念/F0（基频）]]。
- 注意：`Pitch` 的蓝色轨迹才是 F0；`Formant` 的红色 `F1-F5` 不包含 F0。

### 5.3. 看 Formant

- 适合检查：[[方向/AI语音/知识/基础概念/Vowel（元音）]] 是否被改写、音色是否漂移、声码器是否把语音做闷或做尖。
- 起步设置：成人语音可先用 `5 formants`、`Max formant 5000-5500 Hz`、`Window length 0.025 s`；女声、儿童、歌声按需提高 `Max formant`。
- 核对原则：红色 formant 轨迹要贴合 spectrogram 上较宽的暗色频带；如果红点跳到谐波细线或噪声峰上，参数通常不可信。
- 看元音开口度：在稳定元音核心看 `F1`；`F1` 越高通常开口越大 / 舌位越低，`F1` 越低通常口腔更闭 / 舌位越高。`F2` 主要看舌位前后和圆唇，不是开口度。
- `F3` 通常不单独决定普通元音类别，但对卷舌、儿化、英语 /r/ 色彩和说话人音色细节有用。
- 详细概念见 [[方向/AI语音/知识/基础概念/Formant（共振峰）]]。

#### 5.3.1. Formant 详细操作

1. **打开显示**：在 `View & Edit` 窗口里先开 `Spectrum` -> `Show spectrogram`，再开 `Formant` -> `Show formants`。Praat 默认用红点 / 红线显示 formant 估计。
2. **先找稳定元音段**：不要在爆破音、[[方向/AI语音/知识/基础概念/Fricative（擦音）]]、鼻音尾或音素过渡边界上读值；先选 [[方向/AI语音/知识/基础概念/Vowel（元音）]] 中间最稳定的几十毫秒。
3. **看红点是否贴暗带**：`F1` 是最低的一条主要红点轨迹，`F2` 在其上方，`F3` 再往上。可信轨迹应该贴着声谱图里的宽暗色频带，而不是贴一根根细谐波。
4. **读数方式**：鼠标点到目标时间附近；需要精确值时，在 Objects 窗口把 `Sound` 转成 `Formant` 对象，再用 `Query` 读取某个时间点的 `F1/F2/F3`。
5. **记录口径**：记录 formant 值时同时记下性别 / 年龄、采样率、`Max formant`、`Number of formants`、`Window length`，否则不同批次很难比较。

补充：同一时刻按频率编号时应满足 `F1 < F2 < F3`。如果看起来 `F2` 跑到 `F3` 上方，通常不是正常发音结构，而是红点未标号导致误读、跨时间点比较、自动 tracking 换轨，或参数 / 噪声 / 高 F0 造成的估计错误。

#### 5.3.2. 参数怎么调

- **入口**：在编辑窗口点 `Formant` -> `Formant settings...`，主要调 `Number of formants`、`Maximum formant`、`Window length`。
- **男声起点**：`Number of formants = 5`，`Max formant = 5000 Hz`，`Window length = 0.025 s`。
- **女声起点**：`Number of formants = 5`，`Max formant = 5500 Hz`。
- **儿童 / 高 F0 / 歌声**：尝试 `Max formant = 6000-8000 Hz`，并人工核对红点是否仍贴宽暗带。
- **轨迹乱跳**：先小幅调整 `Max formant`，再调整 `Number of formants`；不要一上来改很多参数。
- **F1/F2 被挤错**：`Max formant` 过高时，Praat 可能把谐波当成 formant；`Max formant` 过低时，高频 formant 会被漏掉。

#### 5.3.3. 判断是否可信

- **可信**：红点连续、贴合宽暗带、在稳定元音段内不剧烈跳变，且 `F1/F2` 位置符合元音直觉。
- **不可信**：红点跳到细谐波线上、突然翻倍 / 减半、在清音或强噪声段仍给出整齐轨迹、或和听感明显矛盾。
- **F2/F3 贴近或反穿**：先看是否发生在稳定元音核心；如果只在边界 / 儿化 / 卷舌附近短暂靠近，可能是真实过渡；如果看起来 `F2` 高于 `F3`、整段乱跳或互换，优先怀疑读图或自动估计。
- **宽暗带**：不是一根细线，而是一条较厚、略模糊、连续的横向 / 弯曲能量带；多个相邻谐波在这个频段被声道共振放大，红点应落在带的中心附近。
- **细谐波线**：很多窄、平行、间距均匀的横线，像梳齿；相邻间距约等于 F0。红点如果一路贴着某一根细线走，通常可疑。
- **高 F0 难点**：[[方向/AI语音/知识/基础概念/F0（基频）]] 高时谐波间距大，谱包络采样稀疏，formant 自动估计更容易错。
- **增强任务难点**：noisy 和 enhanced 的 formant 估计可能同时受噪声 / 模型伪影影响；不要只看红点，必须同时听音频和看声谱图暗带。

#### 5.3.4. 增强前后怎么看

- **内容保持**：同一句 clean / enhanced 的 `F1/F2` 轨迹应大体一致，尤其是元音核心段。
- **音色漂移**：如果 enhanced 的 formant 系统性上移 / 下移，可能是声道长度或音色被模型改了。
- **发闷**：高频 formant 或擦音被抹掉，声谱图会更平、更暗，听感像被盖住。
- **假清晰**：高频被模型补得过亮，但 formant 结构和原始语音不一致，可能是生成式 hallucination。

#### 5.3.5. 最小工作流

```text
导入 wav
  -> View & Edit
  -> Show spectrogram + Show formants
  -> 找稳定元音核心段
  -> 调 Max formant / Number of formants
  -> 核对红点贴不贴宽暗带
  -> 记录 F1/F2/F3 + 参数
```

### 5.4. 看 Intensity

- `Intensity` 是 Praat 里表示声音局部强弱 / 能量的时间曲线，通常显示为 dB；它不是 [[方向/AI语音/知识/基础概念/F0（基频）|pitch / F0]]，也不是频率。
- 计算直觉：Praat 基于声压波形的平方平均来估计强度，更接近局部 RMS 能量；如果录音链路没有声学校准，绝对 dB 不要当真实 [[方向/AI语音/知识/基础概念/SPL（声压级）|dB SPL]] 使用，更适合同一录音条件内相对比较。
- 适合检查：响度突变、重音、静音裁剪是否过狠、增强后尾音是否被吞、句尾是否异常衰减。
- 操作入口：`View & Edit` 窗口中用 `Intensity` -> `Show intensity` 查看叠加曲线；需要对象级分析时，在 Objects 窗口把 `Sound` 转成 `Intensity` 对象，再用 `Query` 读某个时间点或选区的值。
- 参数注意：`Sound: To Intensity...` 里的 `Pitch floor` 会影响平滑窗口；设太高会让曲线跟基频同步抖动，设太低会把短时变化抹平。
- 对比不同文件前先确认采样率、位深和归一化方式；否则 intensity 差异可能只是工程预处理差异。

### 5.5. 用 Picture 窗口出图

- `Picture` 窗口是 Praat 的出图画布：从 Objects 窗口选中 `Sound`、`Pitch`、`Spectrogram`、`Formant` 或 `Intensity` 对象，把图画到当前选中的 viewport，再导出成 PDF / PNG / EPS。
- 最小流程：`Edit` -> `Erase all` 清空画布，鼠标拖出粉色绘图区域，回 Objects 窗口选对象并执行 `Draw...` / `Paint...` / `Speckle...`，最后用 `File` -> `Save as PDF file...` 或 `Save as PNG file...` 导出。
- 精确排版：用 `Select` -> `Select outer viewport...` 输入画布区域；多图排版时先划好不同 viewport，再分别画 waveform、spectrogram、pitch、formant 或 intensity。
- 标题和坐标：用 Picture 窗口的 `Margins` 菜单加 `Draw inner box`、`Text top...`、`Text bottom...`、`Text left...` 和刻度；这些命令通常作用于最近画出的图。
- 脚本口径：常见命令是 `Erase all`、`Select outer viewport: 0, 6, 0, 4`、`Draw inner box`、`Text top: "yes", "Title"`，适合复现论文图或批量导出诊断图。

### 5.6. 做 TextGrid 标注

- 创建标注：选中 `Sound`，用 `Annotate` -> `To TextGrid...` 创建 tier，例如 `words`、`phones`、`events`。
- 编辑标注：同时选中 `Sound` 和 `TextGrid`，点击 `View & Edit`，在时间轴上切分 interval 并填入标签。
- 保存标注：把 `.TextGrid` 和原音频放在同一目录，保持同名或相近命名，方便后续 [[方向/AI语音/工具/MFA（强制对齐工具）]] / Python 脚本读取。

## 6. 语音增强检查清单

- **先听再看**：先盲听 noisy / enhanced / clean，再用 Praat 解释听到的问题。
- **看内容保持**：formant、[[方向/AI语音/知识/基础概念/F0（基频）]]、爆破音、[[方向/AI语音/知识/基础概念/Fricative（擦音）]] 和句尾弱音不要被生成式增强改写。
- **看伪影**：增强后如果出现固定频带、音乐噪声、金属感、周期性纹理，通常能在 spectrogram 上看到。
- **看边界**：切块增强常在 chunk 边缘留下 discontinuity，要放大查看拼接点附近的 waveform 和 spectrogram。
- **看静音段**：静音中不应有明显语音残影；语音段也不应被 VAD / denoising 过度截断。

## 7. 使用注意

- Praat 是人工诊断工具，不替代批量指标；大规模实验仍要配合 [[方向/AI语音/评估/PESQ]]、[[方向/AI语音/评估/STOI 与 ESTOI]]、[[方向/AI语音/评估/SI-SDR]] 和 MOS / AB 听测。
- 自动 formant / pitch 轨迹只是估计结果，强噪声、混响、高 [[方向/AI语音/知识/基础概念/F0（基频）]]、歌声、儿童语音都需要人工核对。
- 不要只凭一张 spectrogram 判断模型好坏；同一个伪影可能主观不可闻，也可能对 ASR / 说话人相似度影响很大。

## 8. 安装方式

- Windows：从官网下载对应 CPU 架构的 `.zip`，解压后直接运行 `Praat.exe`，不需要管理员安装。
- Linux：Ubuntu / Debian 可用 `sudo apt install praat`，但版本可能偏旧；要最新版就下载官方 `.tar.gz`，解压后运行 `./praat`。
- Linux 服务器：无 GUI / 无声卡时选官方 `barren` 版，用于命令行脚本。

## 9. 内网迁移

- Windows：联网机下载 `praat*_win-*.zip`，拷到内网机，解压到任意目录即可运行。
- Linux：联网机下载匹配架构的 `praat*_linux-*.tar.gz`，拷到内网机后 `tar -xzf`；如果缺 GTK / ALSA / PulseAudio 等系统库，需要另行准备对应 `.deb` / `.rpm`。
- 字体：需要国际音标显示时，把 Charis / Doulos SIL 字体包一起拷过去安装。

## 10. 外部入口

- [Praat official site](https://www.fon.hum.uva.nl/praat/)
- [Praat 中文教程](https://hangang96.github.io/PraatEN/%E6%95%99%E7%A8%8B.html)
- [Praat Manual - Intensity](https://praat.org/manual/Intensity.html)
- [Praat Manual - Sound: To Intensity...](https://praat.org/manual/Sound__To_Intensity___.html)
- [Praat Manual - Picture window](https://praat.org/manual/Picture_window.html)
- [Praat Manual - Margins](https://praat.org/manual/Margins.html)

## 11. 相关对象

- [[方向/AI语音/知识/基础概念/Spectrogram（声谱图）]]
- [[方向/AI语音/知识/基础概念/F0（基频）]]
- [[方向/AI语音/知识/基础概念/Spectral Envelope（频谱包络）]]
- [[方向/AI语音/知识/基础概念/Formant（共振峰）]]
- [[方向/AI语音/知识/基础概念/Fricative（擦音）]]
- [[方向/AI语音/知识/基础概念/SE（语音增强）导论]]

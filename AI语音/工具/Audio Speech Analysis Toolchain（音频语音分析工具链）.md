---
title: Audio Speech Analysis Toolchain（音频语音分析工具链）
类型: 工具链
发表时间:
时间依据: 工程工具组合；非单一发表物
相关主题:
  - 音频分析
  - 语音分析
  - 语音增强评估
aliases:
  - 音频语音分析工具链
  - 音频分析工具
  - 语音分析工具
tags:
  - 类型/工具链
  - 方向/AI语音
  - 主题/音频处理
  - 主题/工具链
---

# Audio Speech Analysis Toolchain（音频语音分析工具链）

## 1. 身份

这页沉淀一套最小可用的音频 / 语音分析工具链：先用桌面工具听和看，再用 Python 批处理特征与指标，最后按任务接入转写、说话人分割、强制对齐或完整研究框架。

针对 [[方向/AI语音/模型/UniSE（Unified Speech Enhancement）]]、[[方向/AI语音/模型/WavLM]]、[[方向/AI语音/模型/BiCodec]] 这类语音增强 / codec LM 论文，优先把 **WavLM 特征、频谱检查、听感评估、PESQ / STOI / SI-SDR / MOS 口径** 跑通。

## 2. 最小栈

- [[方向/AI语音/工具/Praat（语音学分析工具）]]：看 F0、formant、intensity、声谱图和发音细节。
- [[方向/AI语音/工具/Audacity（音频编辑与频谱查看）]]：快速听、剪、导出、粗看频谱。
- [[方向/AI语音/工具/librosa（Python 音频分析库）]]：批量提 STFT、mel、MFCC 和基础音频特征。
- [[方向/AI语音/工具/torchaudio（PyTorch 音频工具库）]]：接 PyTorch、WavLM / wav2vec2、SQUIM 和训练流水线。
- [[方向/AI语音/工具/WhisperX（长音频转写与对齐）]] + [[方向/AI语音/工具/pyannote.audio（说话人分割工具库）]]：长音频转写、词级时间戳和 diarization。

## 3. 按任务选型

- **看一个样本哪里坏了**：[[方向/AI语音/工具/Audacity（音频编辑与频谱查看）]]、[[方向/AI语音/工具/Sonic Visualiser（音频可视化分析）]]、[[方向/AI语音/工具/Praat（语音学分析工具）]]。
- **批量研究特征**：[[方向/AI语音/工具/librosa（Python 音频分析库）]]、[[方向/AI语音/工具/torchaudio（PyTorch 音频工具库）]]、[[方向/AI语音/工具/openSMILE（声学特征提取工具）]]。
- **语音增强评估**：[[方向/AI语音/工具/SQUIM（语音质量无参考评估）]]、[[方向/AI语音/评估/PESQ]]、[[方向/AI语音/评估/STOI 与 ESTOI]]、[[方向/AI语音/评估/SI-SDR]]。
- **会议 / 多人语音**：[[方向/AI语音/工具/WhisperX（长音频转写与对齐）]]、[[方向/AI语音/工具/pyannote.audio（说话人分割工具库）]]。
- **语音学和标注语料**：[[方向/AI语音/工具/Praat（语音学分析工具）]]、[[方向/AI语音/工具/MFA（强制对齐工具）]]、[[方向/AI语音/工具/ELAN（多层语音视频标注工具）]]。
- **完整模型实验**：[[方向/AI语音/工具/SpeechBrain（语音研究工具包）]]、[[方向/AI语音/模型/ESPnet]]、[[方向/AI语音/工具/NeMo（NVIDIA 语音 AI 框架）]]。

## 4. 使用顺序

1. 先用 Audacity / Praat 手工检查 5-10 个代表样本。
2. 再用 librosa / torchaudio 写批处理，统一采样率、响度、切块和特征。
3. 对增强结果同时跑侵入式指标、无参考指标和人工听测。
4. 只有需要 ASR / diarization / alignment 时，再接 WhisperX、pyannote.audio、MFA。

## 5. 安装方式

- 桌面分析工具：按系统下载官方安装包或便携包，Windows 用 `.exe` / `.msi` / `.zip`，Linux 优先用 `.AppImage` / `.tar.gz`。
- Python 分析工具：先建独立环境，再按工具页安装 `librosa`、`torchaudio`、`opensmile`、`whisperx`、`pyannote.audio`、`speechbrain` 等包。
- 重型框架：ESPnet、NeMo、MFA 优先用 conda / Docker / WSL2，不建议在裸 Windows 上硬装完整研究栈。
- 模型权重：Hugging Face、PyTorch、MFA、NeMo 的模型缓存和软件包分开管理，避免只装了包但内网无法下载权重。

## 6. 内网迁移总原则

桌面 GUI 工具优先走“下载安装包 -> 拷贝 -> 本地安装 / 解压运行”：Windows 选 `.exe` / `.msi` / `.zip`，Linux 优先选 `.AppImage` / `.tar.gz`，只有目标机能离线装依赖时才选 `.deb`。

Python 工具优先走三种方式，按稳定性排序：

1. **conda-pack 整包迁移**：联网机和内网机必须同 OS / 架构；Windows 打包给 Windows，Linux 打包给 Linux。

```bash
conda install -c conda-forge conda-pack
conda pack -n speech -o speech-env.tar.gz

# 内网 Linux
mkdir -p speech-env
tar -xzf speech-env.tar.gz -C speech-env
source speech-env/bin/activate
conda-unpack
```

2. **pip wheelhouse**：适合纯 pip 包；联网机按目标机 OS、Python、CUDA 下载轮子，内网机用 `--no-index` 安装。

```bash
python -m pip download -d wheelhouse -r requirements.txt
python -m pip install --no-index --find-links wheelhouse -r requirements.txt
```

3. **Docker 镜像迁移**：适合 Linux 服务器、NeMo、ESPnet、CUDA 工具链。

```bash
docker save -o speech-stack.tar repo/image:tag
docker load -i speech-stack.tar
```

模型权重和缓存单独拷：Hugging Face 设 `HF_HOME`，PyTorch / torchaudio 设 `TORCH_HOME`，MFA 设 `MFA_ROOT_DIR`。先在联网机跑一次最小推理触发下载，再把缓存目录整体拷进内网。

推荐离线包目录：

```text
offline-audio-tools/
  desktop-win/        # Praat, Audacity, Sonic Visualiser, ELAN installers / zip
  desktop-linux/      # AppImage, tar.gz, deb plus dependencies if needed
  wheelhouse-win/     # Windows Python wheels, same Python version
  wheelhouse-linux/   # Linux Python wheels, same Python/CUDA/arch
  conda-pack/         # MFA / ESPnet / NeMo / heavy env tarballs
  docker-images/      # nemo.tar, espnet.tar, other Linux images
  models/             # HF_HOME, TORCH_HOME, MFA_ROOT_DIR, .nemo files
  verify/             # smoke-test scripts and sample wav
```

最小 Python `requirements.txt` 可从轻到重拆开：

```text
librosa
opensmile
torch
torchaudio
whisperx
pyannote.audio
speechbrain
```

NeMo、ESPnet、MFA 不建议塞进同一个轻量 wheelhouse；用 conda-pack 或 Docker 单独迁移更稳。

## 7. 相关对象

- [[方向/AI语音/知识/基础概念/音频数据预处理]]：工具链的上游数据处理流程。
- [[方向/AI语音/知识/基础概念/SSL 编码器]]：WavLM / HuBERT / wav2vec2 特征的表示层。
- [[方向/AI语音/评估/语音增强评估指标体系]]：增强任务的指标组合。

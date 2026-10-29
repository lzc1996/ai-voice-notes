#!/bin/bash
# 从 Obsidian vault 同步 AI语音 笔记到本仓库
# 用法: bash sync-from-vault.sh  （在本仓库根目录执行，或任意目录执行均可）
set -e

SRC="C:/Users/m1780/Documents/Obsidian Vault/方向/AI语音"
DST="$(cd "$(dirname "$0")" && pwd)/AI语音"

# 镜像语义：先清空目标目录再复制，保证源中已删除/改名的文件在目标中同步消失
rm -rf "$DST"
mkdir -p "$DST"
cp -r "$SRC/." "$DST/"

cd "$DST/.."
if git diff --quiet && [ -z "$(git ls-files --others --exclude-standard)" ]; then
    echo "无变更，跳过提交"
else
    git add -A
    git commit -m "sync from vault: $(date +%F\ %H:%M)"
    git push
    echo "已同步并推送"
fi

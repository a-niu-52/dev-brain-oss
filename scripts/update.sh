#!/bin/sh
set -eu

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$ROOT"

if [ -n "$(git status --porcelain)" ]; then
  echo '更新停止：Dev Brain 工作区存在未提交修改。' >&2
  git status --short >&2
  exit 1
fi

if ! git pull --ff-only; then
  echo '更新失败，保留现场。' >&2
  echo "当前分支: $(git branch --show-current)" >&2
  git status --short >&2
  echo '未推送提交:' >&2
  git log --oneline '@{upstream}..HEAD' >&2 || true
  echo '远程地址:' >&2
  git remote -v >&2
  exit 1
fi

sh "$ROOT/scripts/validate.sh"
sh "$ROOT/scripts/install.sh"
echo 'Dev Brain 更新完成'

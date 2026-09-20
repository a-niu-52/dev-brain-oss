#!/bin/sh
set -eu

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
HOME_DIR=${DEV_BRAIN_HOME_DIR:-$HOME}
START='<!-- DEV-BRAIN:START -->'
END='<!-- DEV-BRAIN:END -->'
BACKUP_DIR=""

fail() {
  echo "卸载失败: $*" >&2
  exit 1
}

ensure_backup_dir() {
  [ -n "$BACKUP_DIR" ] && return
  base="$HOME_DIR/.dev-brain/backups/$(date +%Y%m%d%H%M%S)-uninstall"
  BACKUP_DIR=$base
  suffix=0
  while [ -e "$BACKUP_DIR" ]; do
    suffix=$((suffix + 1))
    BACKUP_DIR="${base}-${suffix}"
  done
  mkdir -p "$BACKUP_DIR"
}

remove_link() {
  source=$1
  target=$2
  if [ -L "$target" ]; then
    same=$(readlink "$target")
    if [ "$same" = "$source" ]; then
      rm -f "$target"
      echo "已移除链接: $target"
    else
      fail "链接来源不一致，未删除: $target"
    fi
  elif [ -e "$target" ]; then
    fail "目标不是 Dev Brain 创建的链接: $target"
  fi
}

remove_managed_block() {
  target=$1
  [ -e "$target" ] || return
  [ -L "$target" ] && fail "规则文件不能是符号链接: $target"
  [ -f "$target" ] || fail "规则目标不是普通文件: $target"

  starts=$(grep -cF "$START" "$target" || true)
  ends=$(grep -cF "$END" "$target" || true)
  [ "$starts" -eq 0 ] && [ "$ends" -eq 0 ] && return
  [ "$starts" -eq 1 ] && [ "$ends" -eq 1 ] || fail "受管区块标记不完整或重复: $target"

  ensure_backup_dir
  cp "$target" "$BACKUP_DIR/$(basename "$target").before-uninstall"
  tmp=$(mktemp "$(dirname "$target")/.dev-brain-uninstall.XXXXXX")
  awk -v start="$START" -v end="$END" '
    $0 == start { in_block = 1; next }
    $0 == end { in_block = 0; next }
    !in_block { print }
  ' "$target" > "$tmp"
  if [ -s "$tmp" ]; then
    mv "$tmp" "$target"
  else
    rm -f "$tmp" "$target"
  fi
  echo "已移除受管区块: $target"
}

remove_managed_block "$HOME_DIR/.codex/AGENTS.md"
remove_link "$ROOT/adapters/cursor/dev-brain.mdc" "$HOME_DIR/.cursor/rules/dev-brain.mdc"
remove_managed_block "$HOME_DIR/.claude/CLAUDE.md"
for skill in code-review debugging git-delivery project-onboarding extract-project-knowledge targeted-verification cross-platform-contract; do
  remove_link "$ROOT/skills/$skill" "$HOME_DIR/.agents/skills/$skill"
done
remove_link "$ROOT" "$HOME_DIR/.dev-brain/repo"

echo 'Dev Brain 卸载完成；备份仍保留在 ~/.dev-brain/backups/'

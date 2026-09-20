#!/bin/sh
set -eu

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
HOME_DIR=${DEV_BRAIN_HOME_DIR:-$HOME}
DRY_RUN=0
TEST_FAIL_AFTER=${DEV_BRAIN_TEST_FAIL_AFTER:-}
ACTION_COUNT=0
JOURNAL=$(mktemp "${TMPDIR:-/tmp}/dev-brain-install.XXXXXX")
BACKUP_DIR=""

START='<!-- DEV-BRAIN:START -->'
END='<!-- DEV-BRAIN:END -->'

cleanup() {
  status=$?
  if [ "$status" -ne 0 ]; then
    while IFS='|' read -r action target backup; do
      [ -n "${action:-}" ] || continue
      case "$action" in
        LINK)
          if [ -L "$target" ]; then
            rm -f "$target"
          fi
          ;;
        MERGE)
          if [ -n "${backup:-}" ] && [ -f "$backup" ]; then
            cp "$backup" "$target"
          elif [ -f "$target" ]; then
            rm -f "$target"
          fi
          ;;
        CREATE)
          if [ -f "$target" ]; then
            rm -f "$target"
          fi
          ;;
      esac
    done < "$JOURNAL"
  fi
  rm -f "$JOURNAL"
  exit "$status"
}
trap cleanup EXIT HUP INT TERM

fail() {
  echo "安装失败: $*" >&2
  exit 1
}

usage() {
  echo "用法: sh scripts/install.sh [--dry-run]" >&2
  exit 2
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --dry-run) DRY_RUN=1 ;;
    *) usage ;;
  esac
  shift
done

[ -f "$ROOT/adapters/codex/AGENTS.md" ] || fail '缺少 Codex 适配入口'
[ -f "$ROOT/adapters/claude/CLAUDE.md" ] || fail '缺少 Claude 适配入口'
[ -f "$ROOT/adapters/cursor/dev-brain.mdc" ] || fail '缺少 Cursor 适配入口'

same_link() {
  [ -L "$2" ] && [ "$(readlink "$2")" = "$1" ]
}

check_link_target() {
  source=$1
  target=$2
  if [ -e "$target" ] || [ -L "$target" ]; then
    same_link "$source" "$target" || fail "目标存在且来源不一致: $target"
  fi
}

check_merge_target() {
  target=$1
  if [ -L "$target" ]; then
    fail "规则文件不能是符号链接: $target"
  fi
  if [ -e "$target" ] && [ ! -f "$target" ]; then
    fail "规则目标不是普通文件: $target"
  fi
  if [ -f "$target" ]; then
    starts=$(grep -cF "$START" "$target" || true)
    ends=$(grep -cF "$END" "$target" || true)
    if [ "$starts" -gt 1 ] || [ "$ends" -gt 1 ] || [ "$starts" -ne "$ends" ]; then
      fail "受管区块标记不完整或重复: $target"
    fi
  fi
}

record_action() {
  ACTION_COUNT=$((ACTION_COUNT + 1))
  if [ -n "$TEST_FAIL_AFTER" ] && [ "$ACTION_COUNT" -ge "$TEST_FAIL_AFTER" ]; then
    fail "测试注入的安装失败"
  fi
}

link_one() {
  source=$1
  target=$2
  if same_link "$source" "$target"; then
    echo "已存在: $target"
    return
  fi
  if [ "$DRY_RUN" -eq 1 ]; then
    echo "将创建链接: $target -> $source"
    return
  fi
  mkdir -p "$(dirname "$target")"
  ln -s "$source" "$target"
  printf 'LINK|%s|\n' "$target" >> "$JOURNAL"
  record_action
}

ensure_backup_dir() {
  [ -n "$BACKUP_DIR" ] && return
  base="$HOME_DIR/.dev-brain/backups/$(date +%Y%m%d%H%M%S)"
  BACKUP_DIR=$base
  suffix=0
  while [ -e "$BACKUP_DIR" ]; do
    suffix=$((suffix + 1))
    BACKUP_DIR="${base}-${suffix}"
  done
  mkdir -p "$BACKUP_DIR"
}

merge_managed_block() {
  source=$1
  target=$2
  mode=$3
  if [ "$DRY_RUN" -eq 1 ]; then
    echo "将合并受管区块: $target"
    return
  fi

  target_dir=$(dirname "$target")
  mkdir -p "$target_dir"
  backup=""
  if [ -f "$target" ]; then
    ensure_backup_dir
    backup="$BACKUP_DIR/$(basename "$target").orig"
    cp "$target" "$backup"
  fi

  tmp=$(mktemp "$target_dir/.dev-brain.XXXXXX")
  if [ -f "$target" ]; then
    awk -v start="$START" -v end="$END" '
      $0 == start { in_block = 1; next }
      $0 == end { in_block = 0; next }
      !in_block { print }
    ' "$target" > "$tmp"
  fi
  if [ -s "$tmp" ]; then
    printf '\n' >> "$tmp"
  fi
  printf '%s\n' "$START" >> "$tmp"
  if [ "$mode" = codex ]; then
    cat "$source" >> "$tmp"
  else
    printf '%s\n' '@~/.dev-brain/repo/adapters/claude/CLAUDE.md' >> "$tmp"
  fi
  printf '%s\n' "$END" >> "$tmp"
  mv "$tmp" "$target"

  if [ -n "$backup" ]; then
    printf 'MERGE|%s|%s\n' "$target" "$backup" >> "$JOURNAL"
  else
    printf 'CREATE|%s|\n' "$target" >> "$JOURNAL"
  fi
  record_action
}

# Preflight all exclusive targets before changing any user path.
check_link_target "$ROOT" "$HOME_DIR/.dev-brain/repo"
check_merge_target "$HOME_DIR/.codex/AGENTS.md"
check_link_target "$ROOT/adapters/cursor/dev-brain.mdc" "$HOME_DIR/.cursor/rules/dev-brain.mdc"
check_merge_target "$HOME_DIR/.claude/CLAUDE.md"
for skill in code-review debugging git-delivery project-onboarding extract-project-knowledge targeted-verification cross-platform-contract; do
  check_link_target "$ROOT/skills/$skill" "$HOME_DIR/.agents/skills/$skill"
done

[ "$DRY_RUN" -eq 1 ] && echo 'dry-run：未修改用户目录'
link_one "$ROOT" "$HOME_DIR/.dev-brain/repo"
merge_managed_block "$ROOT/adapters/codex/AGENTS.md" "$HOME_DIR/.codex/AGENTS.md" codex
link_one "$ROOT/adapters/cursor/dev-brain.mdc" "$HOME_DIR/.cursor/rules/dev-brain.mdc"
merge_managed_block "$ROOT/adapters/claude/CLAUDE.md" "$HOME_DIR/.claude/CLAUDE.md" claude
for skill in code-review debugging git-delivery project-onboarding extract-project-knowledge targeted-verification cross-platform-contract; do
  link_one "$ROOT/skills/$skill" "$HOME_DIR/.agents/skills/$skill"
done

echo 'Dev Brain 安装完成'

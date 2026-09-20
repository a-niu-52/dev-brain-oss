#!/bin/sh
set -eu

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
FAKE_HOME=$(mktemp -d)
ROLLBACK_HOME=$(mktemp -d)
trap 'rm -rf "$FAKE_HOME" "$ROLLBACK_HOME"' EXIT

mkdir -p "$FAKE_HOME/.codex" "$FAKE_HOME/.claude" "$FAKE_HOME/.cursor/rules"
printf '用户原有 Codex 规则\n' > "$FAKE_HOME/.codex/AGENTS.md"
printf '用户原有 Claude 规则\n' > "$FAKE_HOME/.claude/CLAUDE.md"

DEV_BRAIN_HOME_DIR="$FAKE_HOME" "$ROOT/scripts/install.sh" --dry-run
grep -q '用户原有 Codex 规则' "$FAKE_HOME/.codex/AGENTS.md"
! grep -q '<!-- DEV-BRAIN:START -->' "$FAKE_HOME/.codex/AGENTS.md"

DEV_BRAIN_HOME_DIR="$FAKE_HOME" "$ROOT/scripts/install.sh"
test -L "$FAKE_HOME/.dev-brain/repo"
test -f "$FAKE_HOME/.codex/AGENTS.md"
grep -q '用户原有 Codex 规则' "$FAKE_HOME/.codex/AGENTS.md"
test "$(grep -c '<!-- DEV-BRAIN:START -->' "$FAKE_HOME/.codex/AGENTS.md")" -eq 1
test -L "$FAKE_HOME/.cursor/rules/dev-brain.mdc"
test -f "$FAKE_HOME/.claude/CLAUDE.md"
grep -q '用户原有 Claude 规则' "$FAKE_HOME/.claude/CLAUDE.md"
grep -q '@~/.dev-brain/repo/adapters/claude/CLAUDE.md' "$FAKE_HOME/.claude/CLAUDE.md"
for skill in code-review debugging git-delivery project-onboarding extract-project-knowledge targeted-verification cross-platform-contract; do
  test -L "$FAKE_HOME/.agents/skills/$skill"
done
find "$FAKE_HOME/.dev-brain/backups" -type f | grep -q .

DEV_BRAIN_HOME_DIR="$FAKE_HOME" "$ROOT/scripts/install.sh"
test "$(grep -c '<!-- DEV-BRAIN:START -->' "$FAKE_HOME/.codex/AGENTS.md")" -eq 1
test "$(grep -c '<!-- DEV-BRAIN:START -->' "$FAKE_HOME/.claude/CLAUDE.md")" -eq 1
DEV_BRAIN_HOME_DIR="$FAKE_HOME" "$ROOT/scripts/uninstall.sh"
grep -q '用户原有 Codex 规则' "$FAKE_HOME/.codex/AGENTS.md"
! grep -q '<!-- DEV-BRAIN:START -->' "$FAKE_HOME/.codex/AGENTS.md"
grep -q '用户原有 Claude 规则' "$FAKE_HOME/.claude/CLAUDE.md"
! grep -q '<!-- DEV-BRAIN:START -->' "$FAKE_HOME/.claude/CLAUDE.md"
test ! -e "$FAKE_HOME/.agents/skills/code-review"

printf '用户原有 Cursor 规则\n' > "$FAKE_HOME/.cursor/rules/dev-brain.mdc"
if DEV_BRAIN_HOME_DIR="$FAKE_HOME" "$ROOT/scripts/install.sh"; then
  echo '冲突文件未阻止安装' >&2
  exit 1
fi
grep -q '用户原有 Cursor 规则' "$FAKE_HOME/.cursor/rules/dev-brain.mdc"

mkdir -p "$ROLLBACK_HOME/.codex" "$ROLLBACK_HOME/.claude"
printf '回滚前 Codex 规则\n' > "$ROLLBACK_HOME/.codex/AGENTS.md"
printf '回滚前 Claude 规则\n' > "$ROLLBACK_HOME/.claude/CLAUDE.md"
if DEV_BRAIN_HOME_DIR="$ROLLBACK_HOME" DEV_BRAIN_TEST_FAIL_AFTER=3 "$ROOT/scripts/install.sh"; then
  echo '模拟失败未返回非零' >&2
  exit 1
fi
grep -q '回滚前 Codex 规则' "$ROLLBACK_HOME/.codex/AGENTS.md"
! grep -q '<!-- DEV-BRAIN:START -->' "$ROLLBACK_HOME/.codex/AGENTS.md"
grep -q '回滚前 Claude 规则' "$ROLLBACK_HOME/.claude/CLAUDE.md"
test ! -e "$ROLLBACK_HOME/.dev-brain/repo"

echo 'macOS 安装测试通过'

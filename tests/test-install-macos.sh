#!/bin/sh
set -eu

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
FAKE_HOME=$(mktemp -d)
ROLLBACK_HOME=$(mktemp -d)
trap 'rm -rf "$FAKE_HOME" "$ROLLBACK_HOME"' EXIT

mkdir -p "$FAKE_HOME/.codex"
printf '用户原有 Codex 规则\n' > "$FAKE_HOME/.codex/AGENTS.md"

DEV_BRAIN_HOME_DIR="$FAKE_HOME" "$ROOT/scripts/install.sh" --dry-run
grep -q '用户原有 Codex 规则' "$FAKE_HOME/.codex/AGENTS.md"
! grep -q '<!-- DEV-BRAIN:START -->' "$FAKE_HOME/.codex/AGENTS.md"

DEV_BRAIN_HOME_DIR="$FAKE_HOME" "$ROOT/scripts/install.sh"
test -L "$FAKE_HOME/.dev-brain/repo"
test -f "$FAKE_HOME/.codex/AGENTS.md"
grep -q '用户原有 Codex 规则' "$FAKE_HOME/.codex/AGENTS.md"
test "$(grep -c '<!-- DEV-BRAIN:START -->' "$FAKE_HOME/.codex/AGENTS.md")" -eq 1
for skill in code-review debugging git-delivery project-onboarding extract-project-knowledge targeted-verification cross-platform-contract; do
  test -L "$FAKE_HOME/.agents/skills/$skill"
done
test ! -e "$FAKE_HOME/.cursor"
test ! -e "$FAKE_HOME/.claude"
find "$FAKE_HOME/.dev-brain/backups" -type f | grep -q .

before_doctor=$(shasum -a 256 "$FAKE_HOME/.codex/AGENTS.md" | awk '{print $1}')
DEV_BRAIN_HOME_DIR="$FAKE_HOME" sh "$ROOT/scripts/doctor.sh"
after_doctor=$(shasum -a 256 "$FAKE_HOME/.codex/AGENTS.md" | awk '{print $1}')
test "$before_doctor" = "$after_doctor"
rm "$FAKE_HOME/.agents/skills/debugging"
if DEV_BRAIN_HOME_DIR="$FAKE_HOME" sh "$ROOT/scripts/doctor.sh"; then
  echo 'doctor 未发现缺失的 Skill 链接' >&2
  exit 1
fi
DEV_BRAIN_HOME_DIR="$FAKE_HOME" "$ROOT/scripts/install.sh"
DEV_BRAIN_HOME_DIR="$FAKE_HOME" sh "$ROOT/scripts/doctor.sh"

DEV_BRAIN_HOME_DIR="$FAKE_HOME" "$ROOT/scripts/install.sh"
test "$(grep -c '<!-- DEV-BRAIN:START -->' "$FAKE_HOME/.codex/AGENTS.md")" -eq 1
DEV_BRAIN_HOME_DIR="$FAKE_HOME" "$ROOT/scripts/uninstall.sh"
grep -q '用户原有 Codex 规则' "$FAKE_HOME/.codex/AGENTS.md"
! grep -q '<!-- DEV-BRAIN:START -->' "$FAKE_HOME/.codex/AGENTS.md"
test ! -e "$FAKE_HOME/.agents/skills/code-review"

DEV_BRAIN_HOME_DIR="$FAKE_HOME" "$ROOT/scripts/install.sh"

mkdir -p "$ROLLBACK_HOME/.codex"
printf '回滚前 Codex 规则\n' > "$ROLLBACK_HOME/.codex/AGENTS.md"
if DEV_BRAIN_HOME_DIR="$ROLLBACK_HOME" DEV_BRAIN_TEST_FAIL_AFTER=3 "$ROOT/scripts/install.sh"; then
  echo '模拟失败未返回非零' >&2
  exit 1
fi
grep -q '回滚前 Codex 规则' "$ROLLBACK_HOME/.codex/AGENTS.md"
! grep -q '<!-- DEV-BRAIN:START -->' "$ROLLBACK_HOME/.codex/AGENTS.md"
test ! -e "$ROLLBACK_HOME/.dev-brain/repo"

echo 'macOS 安装测试通过'

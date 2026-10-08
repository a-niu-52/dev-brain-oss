#!/bin/sh
set -eu

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
HOME_DIR=${DEV_BRAIN_HOME_DIR:-$HOME}
AGENTS="$HOME_DIR/.codex/AGENTS.md"

fail() {
  echo "诊断失败: $*" >&2
  exit 1
}

expect_link() {
  source=$1
  target=$2
  [ -L "$target" ] || fail "缺少符号链接: $target"
  actual=$(readlink "$target")
  [ "$actual" = "$source" ] || fail "链接目标不匹配: $target -> $actual"
}

expect_link "$ROOT" "$HOME_DIR/.dev-brain/repo"
[ -f "$AGENTS" ] || fail "缺少 Codex 全局规则: $AGENTS"
[ ! -L "$AGENTS" ] || fail "Codex 全局规则不能是符号链接: $AGENTS"
starts=$(grep -cF '<!-- DEV-BRAIN:START -->' "$AGENTS" || true)
ends=$(grep -cF '<!-- DEV-BRAIN:END -->' "$AGENTS" || true)
[ "$starts" -eq 1 ] && [ "$ends" -eq 1 ] || fail 'Codex 全局规则中的 Dev Brain 受管标记缺失或重复'
grep -q 'task-routing.md' "$AGENTS" || fail 'Codex 入口未指向任务路由'

for skill in code-review debugging git-delivery project-onboarding extract-project-knowledge targeted-verification cross-platform-contract; do
  expect_link "$ROOT/skills/$skill" "$HOME_DIR/.agents/skills/$skill"
  [ -f "$HOME_DIR/.agents/skills/$skill/SKILL.md" ] || fail "Skill 内容缺失: $skill"
done

echo 'Dev Brain Codex 安装正常（只读诊断）'

#!/bin/sh
set -eu

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)

required_playbooks='answer-question
start-new-project
fix-bug
deliver-feature
review-change
extract-project-knowledge
full-development-lifecycle'

printf '%s\n' "$required_playbooks" | while IFS= read -r name; do
  test -f "$ROOT/playbooks/$name.md" || { echo "缺少 Playbook: $name" >&2; exit 1; }
done

for file in answer-question start-new-project fix-bug deliver-feature review-change extract-project-knowledge full-development-lifecycle; do
  test -s "$ROOT/playbooks/$file.md"
done

grep -q '准备 → 理解 → 接手 → 方案 → 实施 → 验证 → 审查 → 交付 → 沉淀' "$ROOT/playbooks/full-development-lifecycle.md"
grep -q 'Small' "$ROOT/playbooks/full-development-lifecycle.md"
grep -q 'Medium' "$ROOT/playbooks/full-development-lifecycle.md"
grep -q 'Large' "$ROOT/playbooks/full-development-lifecycle.md"
grep -q 'templates/requirement-card.md' "$ROOT/playbooks/full-development-lifecycle.md"
grep -q 'templates/verification-report.md' "$ROOT/playbooks/full-development-lifecycle.md"
grep -q 'templates/session-handoff.md' "$ROOT/playbooks/full-development-lifecycle.md"

for skill in project-onboarding debugging code-review git-delivery targeted-verification extract-project-knowledge; do
  grep -q "\`$skill\`" "$ROOT/playbooks/full-development-lifecycle.md"
done

grep -q '不自动创建' "$ROOT/playbooks/full-development-lifecycle.md"
grep -q '未经用户明确确认，不执行.*git push' "$ROOT/playbooks/full-development-lifecycle.md"

echo '工作流闭环检查通过'

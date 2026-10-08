#!/bin/sh
set -eu

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)

required='core/task-routing.md
references/skill-index.md
references/tool-capabilities.md
tests/fixtures/routing-cases.md
templates/requirement-card.md
templates/change-design.md
templates/task-plan.md
templates/verification-report.md
templates/session-handoff.md
playbooks/answer-question.md
playbooks/review-change.md
playbooks/full-development-lifecycle.md'

printf '%s\n' "$required" | while IFS= read -r file; do
  test -f "$ROOT/$file" || { echo "缺少路由文件: $file" >&2; exit 1; }
done

grep -q 'intent' "$ROOT/core/task-routing.md"
grep -q 'risk' "$ROOT/core/task-routing.md"
grep -q 'operation' "$ROOT/core/task-routing.md"
grep -q 'Codex' "$ROOT/core/task-routing.md"
grep -q '不承诺' "$ROOT/core/task-routing.md"
grep -q '不创建' "$ROOT/core/task-routing.md"

for skill in project-onboarding debugging code-review git-delivery targeted-verification extract-project-knowledge cross-platform-contract; do
  grep -q "\`$skill\`" "$ROOT/references/skill-index.md"
  test -f "$ROOT/skills/$skill/SKILL.md"
done

for intent in consult onboarding bug feature review delivery knowledge; do
  grep -q "| $intent |" "$ROOT/references/skill-index.md"
done

for sample in R1 R2 R3 R4 R5 R6 R7 R8 R9 R10 R11; do
  grep -q "| $sample |" "$ROOT/tests/fixtures/routing-cases.md"
done
grep -q '自动测试不能替代' "$ROOT/tests/fixtures/routing-cases.md"

for template in requirement-card change-design task-plan verification-report session-handoff; do
  grep -q "templates/$template.md" "$ROOT/core/task-routing.md" "$ROOT/references/skill-index.md"
done

grep -q '^## 按需需求压力测试$' "$ROOT/core/task-routing.md"
grep -q 'Small 且目标明确时不启动' "$ROOT/core/task-routing.md"
grep -q '用户明确要求压力测试时不受 Small 跳过规则限制' "$ROOT/core/task-routing.md"
grep -q '先由代理使用当前可用工具查证事实' "$ROOT/core/task-routing.md"
grep -q '一次只问一个会影响实现、风险或验收的关键问题' "$ROOT/core/task-routing.md"
grep -q '给出推荐默认方案和影响' "$ROOT/core/task-routing.md"
grep -q '记录为待验证假设或转为小型原型' "$ROOT/core/task-routing.md"
grep -q '关键选择已明确，或剩余未知已写成有边界的假设' "$ROOT/core/task-routing.md"
grep -q '范围、验收标准可验证、风险与验证方式已说明' "$ROOT/core/task-routing.md"
grep -q '不要求穷尽所有可能分支' "$ROOT/core/task-routing.md"
grep -q '用户已授权实施且无需新增高风险、破坏性或外部操作授权时' "$ROOT/core/task-routing.md"
grep -q '不重复索要同一授权' "$ROOT/core/task-routing.md"
grep -q '不依赖外部 `grill-me` 或 `grilling`' "$ROOT/core/task-routing.md"
grep -q '需求压力测试' "$ROOT/references/skill-index.md"
grep -q '需求压力测试' "$ROOT/playbooks/full-development-lifecycle.md"
grep -q '用户明确要求深入把关时，小而明确的任务也进入压力测试' "$ROOT/playbooks/full-development-lifecycle.md"
grep -q '只在关键设计或高影响未知项需要用户决定时暂停' "$ROOT/prompts/feature-development.md"
grep -Fq '对应 Playbook：`full-development-lifecycle.md`' "$ROOT/prompts/feature-development.md"
grep -q '需求、方案、设计或技术选型' "$ROOT/core/task-routing.md"
grep -q '保留原任务意图和授权边界' "$ROOT/core/task-routing.md"
grep -q '明确要求对需求/方案/设计进行压力测试' "$ROOT/references/skill-index.md"
grep -q '保持咨询只读' "$ROOT/playbooks/answer-question.md"
grep -q 'R11' "$ROOT/tests/fixtures/routing-cases.md"

if grep -R -n 'capability-routing' "$ROOT/core" "$ROOT/references" "$ROOT/adapters/codex"; then
  echo '基础路由必须通过始终可读的索引触发，不得依赖 capability-routing Skill' >&2
  exit 1
fi

echo '任务路由检查通过'

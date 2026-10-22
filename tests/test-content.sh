#!/bin/sh
set -eu

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)

required_files='README.md
README.zh-CN.md
context/README.md
context/collaboration-preferences.md
context/working-style.md
core/development-principles.md
core/coding-style.md
core/naming-conventions.md
core/git-workflow.md
core/testing-rules.md
core/security-boundaries.md
core/task-routing.md
profiles/vue-typescript.md
profiles/flutter.md
profiles/java-spring-maven.md
profiles/multi-platform-bridge.md
projects/README.md
projects/project-template.md
projects/mobile-web.md
projects/java-multimodule-backend.md
projects/multiplatform-container.md
projects/warehouse-flutter.md
projects/saas-flutter.md
prompts/README.md
prompts/project-onboarding.md
prompts/feature-development.md
prompts/bug-diagnosis.md
prompts/code-review.md
prompts/knowledge-extraction.md
prompts/git-delivery.md
references/README.md
references/project-patterns.md
references/common-configurations.md
references/tool-loading.md
references/skill-index.md
references/tool-capabilities.md
archive/README.md
adapters/codex/AGENTS.md
inbox/README.md
templates/project-AGENTS.md
templates/requirement-card.md
templates/large-task-record.md
templates/change-design.md
templates/task-plan.md
templates/verification-report.md
templates/session-handoff.md
security/secret-scan-allowlist.txt'

printf '%s\n' "$required_files" | while IFS= read -r file; do
  test -f "$ROOT/$file" || { echo "缺少文件: $file" >&2; exit 1; }
done

grep -q '未经用户明确确认，不执行.*git push' "$ROOT/core/git-workflow.md"
grep -q '不保存密码、Token、Cookie、证书或私钥' "$ROOT/core/security-boundaries.md"
grep -q '项目规则优先决定目标分支' "$ROOT/core/git-workflow.md"
grep -q 'flutter analyze' "$ROOT/profiles/flutter.md"
grep -q 'vue-tsc --noEmit' "$ROOT/profiles/vue-typescript.md"
grep -q 'mvn test -pl' "$ROOT/profiles/java-spring-maven.md"
grep -q '桥接协议矩阵' "$ROOT/profiles/multi-platform-bridge.md"
grep -q '默认语言' "$ROOT/context/collaboration-preferences.md"
grep -q 'skill-index.md' "$ROOT/adapters/codex/AGENTS.md"
grep -q 'core/task-routing.md' "$ROOT/adapters/codex/AGENTS.md"
grep -q 'The first release supports Codex only' "$ROOT/README.md"
grep -q '第一版只支持 Codex' "$ROOT/README.zh-CN.md"
test -f "$ROOT/scripts/doctor.sh"
test -f "$ROOT/scripts/doctor.ps1"
grep -q 'doctor.sh' "$ROOT/scripts/update.sh"
grep -q 'doctor.ps1' "$ROOT/scripts/update.ps1"
for project in mobile-web java-multimodule-backend multiplatform-container warehouse-flutter saas-flutter; do
  grep -q '最后核验日期' "$ROOT/projects/$project.md"
  grep -q '脱敏状态：已脱敏' "$ROOT/projects/$project.md"
  grep -q '文档同步触发器' "$ROOT/projects/$project.md"
done
for prompt in project-onboarding feature-development bug-diagnosis code-review knowledge-extraction git-delivery; do
  grep -q '对应 Skill' "$ROOT/prompts/$prompt.md"
  grep -q '对应 Playbook' "$ROOT/prompts/$prompt.md"
  grep -q '可复制提示词' "$ROOT/prompts/$prompt.md"
done
grep -q '归档原因' "$ROOT/archive/README.md"
grep -Fq 'if ($skillText -notmatch "(?m)^name: $([regex]::Escape($skill))\r?$")' "$ROOT/scripts/validate.ps1" || {
  echo 'Windows Skill 名称校验必须兼容 CRLF' >&2
  exit 1
}
for skill in code-review debugging git-delivery project-onboarding extract-project-knowledge targeted-verification cross-platform-contract; do
  file="$ROOT/skills/$skill/SKILL.md"
  test -f "$file" || { echo "缺少 Skill: $skill" >&2; exit 1; }
  head -n 1 "$file" | grep -q '^---$'
  grep -q "^name: $skill$" "$file"
  grep -q '^description: .\+' "$file"
done

for playbook in answer-question start-new-project fix-bug deliver-feature review-change extract-project-knowledge full-development-lifecycle; do
  test -f "$ROOT/playbooks/$playbook.md" || { echo "缺少 Playbook: $playbook" >&2; exit 1; }
done

sh "$ROOT/tests/test-routing.sh"
sh "$ROOT/tests/test-workflow-contract.sh"

if grep -R 'archive/' "$ROOT/adapters/codex" "$ROOT/profiles" "$ROOT/skills"; then
  echo '自动加载入口不得引用 archive/' >&2
  exit 1
fi

echo '内容契约检查通过'

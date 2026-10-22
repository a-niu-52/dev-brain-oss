[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$Root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$ScanRoot = if ($env:DEV_BRAIN_SCAN_ROOT) { [IO.Path]::GetFullPath($env:DEV_BRAIN_SCAN_ROOT) } else { $Root }
$Allowlist = if ($env:DEV_BRAIN_ALLOWLIST_FILE) { $env:DEV_BRAIN_ALLOWLIST_FILE } else { Join-Path $Root 'security/secret-scan-allowlist.txt' }
$privateKeyPattern = 'BEGIN PRIVATE' + ' KEY'
$required = @(
  'README.md','README.zh-CN.md','context/README.md','context/collaboration-preferences.md','context/working-style.md',
  'core/development-principles.md','core/coding-style.md','core/naming-conventions.md','core/git-workflow.md','core/testing-rules.md','core/security-boundaries.md','core/task-routing.md',
  'profiles/vue-typescript.md','profiles/flutter.md','profiles/java-spring-maven.md','profiles/multi-platform-bridge.md',
  'projects/README.md','projects/project-template.md','projects/mobile-web.md','projects/java-multimodule-backend.md','projects/multiplatform-container.md','projects/warehouse-flutter.md','projects/saas-flutter.md',
  'prompts/README.md','prompts/project-onboarding.md','prompts/feature-development.md','prompts/bug-diagnosis.md','prompts/code-review.md','prompts/knowledge-extraction.md','prompts/git-delivery.md',
  'references/README.md','references/project-patterns.md','references/common-configurations.md','references/tool-loading.md','references/skill-index.md','references/tool-capabilities.md',
  'archive/README.md','adapters/codex/AGENTS.md','inbox/README.md','templates/project-AGENTS.md','templates/requirement-card.md','templates/change-design.md','templates/task-plan.md','templates/verification-report.md','templates/session-handoff.md','security/secret-scan-allowlist.txt','scripts/doctor.sh','scripts/doctor.ps1',
  'playbooks/answer-question.md','playbooks/review-change.md','playbooks/full-development-lifecycle.md','tests/fixtures/routing-cases.md'
)

function Fail([string]$Message) { throw "校验失败: $Message" }
function Get-Hash([string]$Path) { return (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash.ToLowerInvariant() }
function Relative-Path([string]$Path, [string]$Base) {
  return $Path.Substring($Base.TrimEnd('\','/').Length).TrimStart('\','/').Replace('\','/')
}
function Read-Allowlist {
  if (-not (Test-Path -LiteralPath $Allowlist -PathType Leaf)) { return @{} }
  $rules = @{}
  foreach ($line in Get-Content -LiteralPath $Allowlist) {
    if ([string]::IsNullOrWhiteSpace($line) -or $line.TrimStart().StartsWith('#')) { continue }
    $parts = $line -split '\s+', 4
    if ($parts.Count -ne 3 -or $parts[0] -ne 'sha256' -or $parts[1] -notmatch '^[0-9a-fA-F]{64}$' -or $parts[2] -match '[*?]') { Fail "白名单格式无效: $line" }
    $rules[$parts[2].Replace('\','/')] = $parts[1].ToLowerInvariant()
  }
  return $rules
}
function Test-Allowlisted([string]$File, [string]$Relative, $Rules) {
  if (-not $Rules.ContainsKey($Relative)) { return $false }
  return $Rules[$Relative] -eq (Get-Hash $File)
}
function Report-Match([string]$File, [string]$Relative, [string]$Reason, $Rules) {
  if (Test-Allowlisted $File $Relative $Rules) { return $false }
  Write-Error "敏感信息或本机信息命中: $Relative ($Reason)" -ErrorAction Continue
  return $true
}

foreach ($path in $required) { if (-not (Test-Path -LiteralPath (Join-Path $Root $path) -PathType Leaf)) { Fail "缺少文件: $path" } }
if ((Get-Content (Join-Path $Root 'core/git-workflow.md') -Raw) -notmatch '未经用户明确确认，不执行.*git push') { Fail 'Git 推送规则缺失' }
if ((Get-Content (Join-Path $Root 'core/security-boundaries.md') -Raw) -notmatch '不保存密码、Token、Cookie、证书或私钥') { Fail '安全规则缺失' }
$routing = Get-Content (Join-Path $Root 'core/task-routing.md') -Raw
$index = Get-Content (Join-Path $Root 'references/skill-index.md') -Raw
foreach ($token in @('intent','risk','operation','不承诺','不创建','Codex')) { if ($routing -notmatch [regex]::Escape($token)) { Fail "任务路由缺少字段或边界: $token" } }
foreach ($intent in @('consult','onboarding','bug','feature','review','delivery','knowledge')) { if ($index -notmatch "\| $intent \|") { Fail "路由索引缺少任务类型: $intent" } }
$routeCases = Get-Content (Join-Path $Root 'tests/fixtures/routing-cases.md') -Raw
foreach ($sample in @('R1','R2','R3','R4','R5','R6','R7','R8','R9','R10')) { if ($routeCases -notmatch "\| $sample \|") { Fail "缺少路由评估样例: $sample" } }
foreach ($skill in @('project-onboarding','debugging','code-review','git-delivery','targeted-verification','extract-project-knowledge','cross-platform-contract')) {
  $skillPath = Join-Path $Root "skills/$skill/SKILL.md"
  if (-not (Test-Path -LiteralPath $skillPath -PathType Leaf)) { Fail "路由指向的 Skill 不存在: $skill" }
  if ($index -notmatch [regex]::Escape("``$skill``")) { Fail "技能索引缺少 Skill: $skill" }
}
foreach ($template in @('requirement-card','change-design','task-plan','verification-report','session-handoff')) {
  $templatePath = Join-Path $Root "templates/$template.md"
  if (-not (Test-Path -LiteralPath $templatePath -PathType Leaf)) { Fail "缺少模板: $template" }
  if ($routing -notmatch [regex]::Escape("templates/$template.md") -and $index -notmatch [regex]::Escape("templates/$template.md")) { Fail "路由未指向模板: $template" }
}
if ($routing -match 'capability-routing' -or $index -match 'capability-routing') { Fail '基础路由不能依赖按需 capability-routing Skill' }
foreach ($playbook in @('answer-question','start-new-project','fix-bug','deliver-feature','review-change','extract-project-knowledge','full-development-lifecycle')) {
  if (-not (Test-Path -LiteralPath (Join-Path $Root "playbooks/$playbook.md") -PathType Leaf)) { Fail "缺少 Playbook: $playbook" }
}
$skills = @('code-review','debugging','git-delivery','project-onboarding','extract-project-knowledge','targeted-verification','cross-platform-contract')
foreach ($skill in $skills) {
  $skillFile = Join-Path $Root "skills/$skill/SKILL.md"
  $skillText = Get-Content -LiteralPath $skillFile -Raw
  if ($skillText -notmatch '(?m)^---\s*\r?\n') { Fail "Skill 缺少 YAML 元数据: $skill" }
  if ($skillText -notmatch "(?m)^name: $([regex]::Escape($skill))\r?$") { Fail "Skill 名称与目录不一致: $skill" }
  if ($skillText -notmatch '(?m)^description: .+') { Fail "Skill 缺少触发描述: $skill" }
}
foreach ($prompt in @('project-onboarding','feature-development','bug-diagnosis','code-review','knowledge-extraction','git-delivery')) {
  $promptText = Get-Content -LiteralPath (Join-Path $Root "prompts/$prompt.md") -Raw
  foreach ($label in @('对应 Skill','对应 Playbook','可复制提示词')) { if ($promptText -notmatch [regex]::Escape($label)) { Fail "Prompt $prompt 缺少字段: $label" } }
}
$lifecycle = Get-Content -LiteralPath (Join-Path $Root 'playbooks/full-development-lifecycle.md') -Raw
foreach ($token in @('Small','Medium','Large','templates/requirement-card.md','templates/verification-report.md','templates/session-handoff.md','未经用户明确确认，不执行')) { if ($lifecycle -notmatch [regex]::Escape($token)) { Fail "完整工作流缺少环节或边界: $token" } }
foreach ($activePath in @((Join-Path $Root 'adapters/codex'),(Join-Path $Root 'profiles'),(Join-Path $Root 'skills'))) {
  $archivedReference = Get-ChildItem -LiteralPath $activePath -File -Recurse | Select-String -Pattern 'archive/' -SimpleMatch
  if ($archivedReference) { Fail '自动加载入口不得引用 archive/' }
}
if ((Get-Content (Join-Path $Root 'adapters/codex/AGENTS.md') -Raw) -notmatch 'core/task-routing.md' -or
    (Get-Content (Join-Path $Root 'adapters/codex/AGENTS.md') -Raw) -notmatch 'skill-index.md') { Fail 'Codex 入口未直接指向路由与 Skill 索引' }

$rules = Read-Allowlist
$files = if ((Resolve-Path $ScanRoot).Path -eq (Resolve-Path $Root).Path) {
  @(git -C $Root ls-files --cached --others --exclude-standard | ForEach-Object { Join-Path $Root $_ })
} else {
  @(Get-ChildItem -LiteralPath $ScanRoot -File -Recurse | ForEach-Object FullName)
}
$failed = $false
foreach ($file in $files) {
  if (-not (Test-Path -LiteralPath $file -PathType Leaf)) { continue }
  $relative = Relative-Path $file $ScanRoot
  $name = Split-Path -Leaf $file
  if ($name -match '^\.env($|\.)' -and $name -ne '.env.example') { Write-Error "环境文件不应进入知识库: $relative" -ErrorAction Continue; $failed = $true; continue }
  $text = Get-Content -LiteralPath $file -Raw -ErrorAction SilentlyContinue
  if ($null -eq $text) { continue }
  if ($text -match $privateKeyPattern) { if (Report-Match $file $relative 'private-key' $rules) { $failed = $true } }
  if ($text -match 'ghp_[A-Za-z0-9]{20,}|github_pat_[A-Za-z0-9_]{20,}|xox[baprs]-[A-Za-z0-9-]{20,}|AKIA[0-9A-Z]{16}') { if (Report-Match $file $relative 'token' $rules) { $failed = $true } }
  if ($text -match '/Users/[A-Za-z0-9._-]+/|C:\\Users\\[A-Za-z0-9._-]+\\') { Write-Error "本机绝对路径不应进入知识库: $relative" -ErrorAction Continue; $failed = $true }
}
if ($failed) { exit 1 }
Write-Output 'Windows 内容和敏感信息校验通过'

[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$Root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$ScanRoot = if ($env:DEV_BRAIN_SCAN_ROOT) { [IO.Path]::GetFullPath($env:DEV_BRAIN_SCAN_ROOT) } else { $Root }
$Allowlist = if ($env:DEV_BRAIN_ALLOWLIST_FILE) { $env:DEV_BRAIN_ALLOWLIST_FILE } else { Join-Path $Root 'security/secret-scan-allowlist.txt' }
$privateKeyPattern = 'BEGIN PRIVATE' + ' KEY'
$required = @(
  'README.md','context/README.md','context/collaboration-preferences.md','context/working-style.md',
  'core/development-principles.md','core/coding-style.md','core/naming-conventions.md','core/git-workflow.md','core/testing-rules.md','core/security-boundaries.md',
  'profiles/vue-typescript.md','profiles/flutter.md','profiles/java-spring-maven.md','profiles/multi-platform-bridge.md',
  'projects/README.md','projects/project-template.md','projects/mobile-web.md','projects/java-multimodule-backend.md','projects/multiplatform-container.md','projects/warehouse-flutter.md','projects/saas-flutter.md',
  'prompts/README.md','prompts/project-onboarding.md','prompts/feature-development.md','prompts/bug-diagnosis.md','prompts/code-review.md','prompts/knowledge-extraction.md','prompts/git-delivery.md',
  'references/README.md','references/project-patterns.md','references/common-configurations.md','references/tool-loading.md',
  'archive/README.md','adapters/codex/AGENTS.md','adapters/cursor/dev-brain.mdc','adapters/claude/CLAUDE.md','inbox/README.md','templates/project-AGENTS.md','security/secret-scan-allowlist.txt'
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
if ((Get-Content (Join-Path $Root 'adapters/cursor/dev-brain.mdc') -Raw) -notmatch '(?m)^alwaysApply: true$') { Fail 'Cursor 规则入口缺失' }

$rules = Read-Allowlist
$files = if ((Resolve-Path $ScanRoot).Path -eq (Resolve-Path $Root).Path) {
  @(git -C $Root ls-files | ForEach-Object { Join-Path $Root $_ })
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

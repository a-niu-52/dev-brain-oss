$ErrorActionPreference = 'Stop'
$Root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$FakeHome = Join-Path ([IO.Path]::GetTempPath()) ('dev-brain-' + [guid]::NewGuid())
$RollbackHome = Join-Path ([IO.Path]::GetTempPath()) ('dev-brain-rollback-' + [guid]::NewGuid())

function Assert-Fails([scriptblock]$Action, [string]$Message) {
  $failed = $false
  try { & $Action } catch { $failed = $true }
  if (-not $failed) { throw $Message }
}

New-Item -ItemType Directory -Path $FakeHome, $RollbackHome | Out-Null
try {
  $env:DEV_BRAIN_HOME_DIR = $FakeHome
  New-Item -ItemType Directory -Path "$FakeHome/.codex", "$FakeHome/.claude", "$FakeHome/.cursor/rules" -Force | Out-Null
  Set-Content -LiteralPath "$FakeHome/.codex/AGENTS.md" -Value '用户原有 Codex 规则'
  Set-Content -LiteralPath "$FakeHome/.claude/CLAUDE.md" -Value '用户原有 Claude 规则'
  & "$Root/scripts/install.ps1" -DryRun
  if ((Get-Content "$FakeHome/.codex/AGENTS.md" -Raw) -match 'DEV-BRAIN:START') { throw 'DryRun 修改了文件' }
  & "$Root/scripts/install.ps1"
  @(
    "$FakeHome/.dev-brain/repo",
    "$FakeHome/.codex/AGENTS.md",
    "$FakeHome/.cursor/rules/dev-brain.mdc",
    "$FakeHome/.claude/CLAUDE.md"
  ) | ForEach-Object { if (-not (Test-Path -LiteralPath $_)) { throw "缺少安装目标: $_" } }
  @('code-review', 'debugging', 'git-delivery', 'project-onboarding', 'extract-project-knowledge', 'targeted-verification', 'cross-platform-contract') |
    ForEach-Object { if (-not (Test-Path -LiteralPath "$FakeHome/.agents/skills/$_")) { throw "缺少 Skill: $_" } }
  if ((Get-Content "$FakeHome/.codex/AGENTS.md" -Raw) -notmatch '用户原有 Codex 规则') { throw '覆盖了 Codex 原有规则' }
  if ((Get-Content "$FakeHome/.claude/CLAUDE.md" -Raw) -notmatch '用户原有 Claude 规则') { throw '覆盖了 Claude 原有规则' }
  if (-not (Get-ChildItem "$FakeHome/.dev-brain/backups" -File -Recurse)) { throw '未生成规则备份' }
  & "$Root/scripts/install.ps1"
  $CodexMarkers = @((Select-String -Path "$FakeHome/.codex/AGENTS.md" -Pattern '<!-- DEV-BRAIN:START -->')).Count
  $ClaudeMarkers = @((Select-String -Path "$FakeHome/.claude/CLAUDE.md" -Pattern '<!-- DEV-BRAIN:START -->')).Count
  if ($CodexMarkers -ne 1) { throw '重复写入 Codex 受管区块' }
  if ($ClaudeMarkers -ne 1) { throw '重复写入 Claude 受管区块' }
  & "$Root/scripts/uninstall.ps1"
  if ((Get-Content "$FakeHome/.codex/AGENTS.md" -Raw) -notmatch '用户原有 Codex 规则') { throw '卸载删除了 Codex 原有规则' }
  if ((Get-Content "$FakeHome/.codex/AGENTS.md" -Raw) -match 'DEV-BRAIN:START') { throw '卸载未清理 Codex 受管区块' }
  if ((Get-Content "$FakeHome/.claude/CLAUDE.md" -Raw) -notmatch '用户原有 Claude 规则') { throw '卸载删除了 Claude 原有规则' }
  if ((Get-Content "$FakeHome/.claude/CLAUDE.md" -Raw) -match 'DEV-BRAIN:START') { throw '卸载未清理 Claude 受管区块' }

  Set-Content -LiteralPath "$FakeHome/.cursor/rules/dev-brain.mdc" -Value '用户原有 Cursor 规则'
  Assert-Fails { & "$Root/scripts/install.ps1" } '未知 Cursor 冲突未阻止安装'
  if ((Get-Content "$FakeHome/.cursor/rules/dev-brain.mdc" -Raw) -notmatch '用户原有 Cursor 规则') { throw '冲突文件被覆盖' }

  New-Item -ItemType Directory -Path "$RollbackHome/.codex", "$RollbackHome/.claude" -Force | Out-Null
  Set-Content -LiteralPath "$RollbackHome/.codex/AGENTS.md" -Value '回滚前 Codex 规则'
  Set-Content -LiteralPath "$RollbackHome/.claude/CLAUDE.md" -Value '回滚前 Claude 规则'
  $env:DEV_BRAIN_HOME_DIR = $RollbackHome
  $env:DEV_BRAIN_TEST_FAIL_AFTER = '3'
  Assert-Fails { & "$Root/scripts/install.ps1" } '模拟失败未返回非零'
  if ((Get-Content "$RollbackHome/.codex/AGENTS.md" -Raw) -notmatch '回滚前 Codex 规则') { throw 'Codex 回滚失败' }
  if ((Get-Content "$RollbackHome/.claude/CLAUDE.md" -Raw) -notmatch '回滚前 Claude 规则') { throw 'Claude 回滚失败' }
  if (Test-Path -LiteralPath "$RollbackHome/.dev-brain/repo") { throw '回滚后仍残留仓库链接' }
  Write-Output 'Windows 安装测试通过'
} finally {
  Remove-Item -LiteralPath $FakeHome -Recurse -Force -ErrorAction SilentlyContinue
  Remove-Item -LiteralPath $RollbackHome -Recurse -Force -ErrorAction SilentlyContinue
  Remove-Item Env:DEV_BRAIN_HOME_DIR -ErrorAction SilentlyContinue
  Remove-Item Env:DEV_BRAIN_TEST_FAIL_AFTER -ErrorAction SilentlyContinue
}

$ErrorActionPreference = 'Stop'
$Root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$FakeHome = Join-Path ([IO.Path]::GetTempPath()) ('dev-brain-' + [guid]::NewGuid())
$RollbackHome = Join-Path ([IO.Path]::GetTempPath()) ('dev-brain-rollback-' + [guid]::NewGuid())
$ConflictHome = Join-Path ([IO.Path]::GetTempPath()) ('dev-brain-conflict-' + [guid]::NewGuid())
$SourceCopy = Join-Path ([IO.Path]::GetTempPath()) ('dev-brain-source-' + [guid]::NewGuid())

function Assert-Fails([scriptblock]$Action, [string]$Message) {
  $failed = $false
  try { & $Action } catch { $failed = $true }
  if (-not $failed) { throw $Message }
}

New-Item -ItemType Directory -Path $FakeHome, $RollbackHome, $ConflictHome, $SourceCopy | Out-Null
try {
  New-Item -ItemType Directory -Path "$SourceCopy/scripts", "$SourceCopy/adapters/codex", "$SourceCopy/skills" -Force | Out-Null
  Copy-Item -LiteralPath "$Root/scripts/install.ps1" -Destination "$SourceCopy/scripts/install.ps1"
  Copy-Item -LiteralPath "$Root/scripts/uninstall.ps1" -Destination "$SourceCopy/scripts/uninstall.ps1"
  Copy-Item -LiteralPath "$Root/scripts/doctor.ps1" -Destination "$SourceCopy/scripts/doctor.ps1"
  Copy-Item -LiteralPath "$Root/adapters/codex/AGENTS.md" -Destination "$SourceCopy/adapters/codex/AGENTS.md"
  foreach ($skillDir in (Get-ChildItem -LiteralPath "$Root/skills" -Directory)) {
    Copy-Item -LiteralPath $skillDir.FullName -Destination "$SourceCopy/skills" -Recurse
  }
  $env:DEV_BRAIN_HOME_DIR = $FakeHome
  $env:DEV_BRAIN_FORCE_COPY = '1'
  New-Item -ItemType Directory -Path "$FakeHome/.codex" -Force | Out-Null
  Set-Content -LiteralPath "$FakeHome/.codex/AGENTS.md" -Value '用户原有 Codex 规则'
  & "$SourceCopy/scripts/install.ps1" -DryRun
  if ((Get-Content "$FakeHome/.codex/AGENTS.md" -Raw) -match 'DEV-BRAIN:START') { throw 'DryRun 修改了文件' }
  & "$SourceCopy/scripts/install.ps1"
  @(
    "$FakeHome/.dev-brain/repo",
    "$FakeHome/.codex/AGENTS.md"
  ) | ForEach-Object { if (-not (Test-Path -LiteralPath $_)) { throw "缺少安装目标: $_" } }
  @('code-review', 'debugging', 'git-delivery', 'project-onboarding', 'extract-project-knowledge', 'targeted-verification', 'cross-platform-contract') |
    ForEach-Object { if (-not (Test-Path -LiteralPath "$FakeHome/.agents/skills/$_")) { throw "缺少 Skill: $_" } }
  if ((Get-Content "$FakeHome/.codex/AGENTS.md" -Raw) -notmatch '用户原有 Codex 规则') { throw '覆盖了 Codex 原有规则' }
  if ((Test-Path "$FakeHome/.cursor") -or (Test-Path "$FakeHome/.claude")) { throw '仅 Codex 版本不应修改其他客户端' }
  if (-not (Get-ChildItem "$FakeHome/.dev-brain/backups" -File -Recurse)) { throw '未生成规则备份' }
  $agentsPath = "$FakeHome/.codex/AGENTS.md"
  $agentsText = [IO.File]::ReadAllText($agentsPath).Replace("`r`n", "`n").Replace("`n", "`r`n")
  [IO.File]::WriteAllText($agentsPath, $agentsText, (New-Object Text.UTF8Encoding($false)))
  & "$SourceCopy/scripts/doctor.ps1"
  Remove-Item -LiteralPath "$FakeHome/.agents/skills/debugging" -Recurse -Force
  Assert-Fails { & "$SourceCopy/scripts/doctor.ps1" } 'doctor 未发现缺失的 Skill'
  & "$SourceCopy/scripts/install.ps1"
  & "$SourceCopy/scripts/doctor.ps1"
  & "$SourceCopy/scripts/install.ps1"
  $agentsText = [IO.File]::ReadAllText($agentsPath)
  $startMarkers = [regex]::Matches($agentsText, '(?m)^<!-- DEV-BRAIN:START -->\r?$').Count
  $endMarkers = [regex]::Matches($agentsText, '(?m)^<!-- DEV-BRAIN:END -->\r?$').Count
  if ($startMarkers -ne 1 -or $endMarkers -ne 1) { throw "受管区块标记数量错误: START=$startMarkers END=$endMarkers" }
  & "$SourceCopy/scripts/doctor.ps1"
  $manifest = @(Get-Content -LiteralPath "$FakeHome/.dev-brain/install-manifest.json" -Raw | ConvertFrom-Json)
  if (-not $manifest[0].sourceHash -or -not $manifest[0].installedHash) { throw '复制清单缺少来源和安装哈希' }
  $installedSkill = "$FakeHome/.agents/skills/debugging/SKILL.md"
  $sourceSkill = "$SourceCopy/skills/debugging/SKILL.md"
  Add-Content -LiteralPath $sourceSkill -Value "`n<!-- source refresh test -->"
  & "$SourceCopy/scripts/install.ps1"
  if ((Get-Content -LiteralPath $installedSkill -Raw) -notmatch 'source refresh test') { throw '未刷新未被用户修改的旧副本' }
  $manifest = @(Get-Content -LiteralPath "$FakeHome/.dev-brain/install-manifest.json" -Raw | ConvertFrom-Json)
  $debugTarget = "$FakeHome/.agents/skills/debugging"
  $debugEntry = $manifest | Where-Object { ([string]$_.target).Replace('\','/') -eq $debugTarget.Replace('\','/') } | Select-Object -First 1
  if (-not $debugEntry.sourceHash -or -not $debugEntry.installedHash) { throw '更新后的清单缺少哈希' }
  & "$SourceCopy/scripts/uninstall.ps1"
  if ((Get-Content "$FakeHome/.codex/AGENTS.md" -Raw) -notmatch '用户原有 Codex 规则') { throw '卸载删除了 Codex 原有规则' }
  if ((Get-Content "$FakeHome/.codex/AGENTS.md" -Raw) -match 'DEV-BRAIN:START') { throw '卸载未清理 Codex 受管区块' }

  $env:DEV_BRAIN_HOME_DIR = $ConflictHome
  & "$SourceCopy/scripts/install.ps1"
  $conflictSkill = "$ConflictHome/.agents/skills/debugging/SKILL.md"
  Add-Content -LiteralPath $conflictSkill -Value "`n<!-- user's local edit -->"
  Add-Content -LiteralPath $sourceSkill -Value "`n<!-- second source refresh test -->"
  Assert-Fails { & "$SourceCopy/scripts/install.ps1" } '用户修改过的副本没有阻止覆盖'
  if ((Get-Content -LiteralPath $conflictSkill -Raw) -notmatch "user's local edit") { throw '冲突检测覆盖了用户修改' }
  Assert-Fails { & "$SourceCopy/scripts/uninstall.ps1" } '卸载删除了用户修改过的副本'
  if ((Get-Content -LiteralPath $conflictSkill -Raw) -notmatch "user's local edit") { throw '卸载覆盖了用户修改' }

  New-Item -ItemType Directory -Path "$RollbackHome/.codex" -Force | Out-Null
  Set-Content -LiteralPath "$RollbackHome/.codex/AGENTS.md" -Value '回滚前 Codex 规则'
  $env:DEV_BRAIN_HOME_DIR = $RollbackHome
  $env:DEV_BRAIN_TEST_FAIL_AFTER = '3'
  Assert-Fails { & "$SourceCopy/scripts/install.ps1" } '模拟失败未返回非零'
  if ((Get-Content "$RollbackHome/.codex/AGENTS.md" -Raw) -notmatch '回滚前 Codex 规则') { throw 'Codex 回滚失败' }
  if (Test-Path -LiteralPath "$RollbackHome/.dev-brain/repo") { throw '回滚后仍残留仓库链接' }
  Write-Output 'Windows 安装测试通过'
} finally {
  foreach ($path in @($FakeHome, $RollbackHome, $ConflictHome, $SourceCopy)) { Remove-Item -LiteralPath $path -Recurse -Force -ErrorAction SilentlyContinue }
  Remove-Item Env:DEV_BRAIN_HOME_DIR -ErrorAction SilentlyContinue
  Remove-Item Env:DEV_BRAIN_TEST_FAIL_AFTER -ErrorAction SilentlyContinue
  Remove-Item Env:DEV_BRAIN_FORCE_COPY -ErrorAction SilentlyContinue
}

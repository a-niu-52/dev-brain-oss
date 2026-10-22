[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$Root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$HomeDir = if ($env:DEV_BRAIN_HOME_DIR) { [IO.Path]::GetFullPath($env:DEV_BRAIN_HOME_DIR) } else { [Environment]::GetFolderPath('UserProfile') }
$ManifestPath = Join-Path $HomeDir '.dev-brain/install-manifest.json'

function Fail([string]$Message) { throw "诊断失败: $Message" }
function Test-AnyPath([string]$Path) { return $null -ne (Get-Item -LiteralPath $Path -Force -ErrorAction SilentlyContinue) }
function Resolve-ComparablePath([string]$Path) { return [IO.Path]::GetFullPath($Path).TrimEnd('\','/') }
function Test-SameLink([string]$Source, [string]$Target) {
  $item = Get-Item -LiteralPath $Target -Force -ErrorAction SilentlyContinue
  if ($null -eq $item -or $null -eq $item.LinkType) { return $false }
  foreach ($candidate in @($item.Target)) {
    if ($candidate -and (Resolve-ComparablePath ([string]$candidate)) -eq (Resolve-ComparablePath $Source)) { return $true }
  }
  return $false
}
function Get-PathHash([string]$Path) {
  $item = Get-Item -LiteralPath $Path -Force -ErrorAction SilentlyContinue
  if ($null -eq $item) { return $null }
  if (-not $item.PSIsContainer) { return (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash.ToLowerInvariant() }
  $sha = [Security.Cryptography.SHA256]::Create()
  try {
    $builder = New-Object Text.StringBuilder
    foreach ($file in (Get-ChildItem -LiteralPath $Path -File -Recurse | Sort-Object FullName)) {
      $relative = $file.FullName.Substring($Path.TrimEnd('\','/').Length).TrimStart('\','/').Replace('\','/')
      [void]$builder.Append($relative)
      [void]$builder.Append(':')
      [void]$builder.Append((Get-FileHash -LiteralPath $file.FullName -Algorithm SHA256).Hash.ToLowerInvariant())
      [void]$builder.Append("`n")
    }
    return ([BitConverter]::ToString($sha.ComputeHash([Text.Encoding]::UTF8.GetBytes($builder.ToString())))).Replace('-','').ToLowerInvariant()
  } finally { $sha.Dispose() }
}
function Get-ManifestEntries {
  if (-not (Test-Path -LiteralPath $ManifestPath -PathType Leaf)) { return @() }
  $raw = Get-Content -LiteralPath $ManifestPath -Raw
  if ([string]::IsNullOrWhiteSpace($raw)) { return @() }
  return @($raw | ConvertFrom-Json)
}
function Test-InstalledSkill([string]$Skill, $Manifest) {
  $source = Join-Path $Root "skills/$Skill"
  $target = Join-Path $HomeDir ".agents/skills/$Skill"
  if (-not (Test-AnyPath $target)) { Fail "缺少 Skill: $target" }
  if (Test-SameLink $source $target) { Write-Output "Skill 正常（链接）: $Skill"; return }

  $entry = $Manifest | Where-Object {
    $_.source -and $_.target -and
    (Resolve-ComparablePath ([string]$_.source)) -eq (Resolve-ComparablePath $source) -and
    (Resolve-ComparablePath ([string]$_.target)) -eq (Resolve-ComparablePath $target)
  } | Select-Object -First 1
  if ($null -eq $entry -or $entry.mode -ne 'copy') { Fail "Skill 不是预期链接或受管副本: $target" }

  $expectedInstalledHash = if ($entry.installedHash) { [string]$entry.installedHash } else { [string]$entry.hash }
  if (-not $expectedInstalledHash -or (Get-PathHash $target) -ne $expectedInstalledHash.ToLowerInvariant()) { Fail "本机副本已被修改: $target" }
  if ($entry.sourceHash -and (Get-PathHash $source) -ne ([string]$entry.sourceHash).ToLowerInvariant()) { Fail "Skill 来源已更新，请运行安装器刷新: $Skill" }
  Write-Output "Skill 正常（受管副本）: $Skill"
}

$repoLink = Join-Path $HomeDir '.dev-brain/repo'
if (-not (Test-SameLink $Root $repoLink)) { Fail "Dev Brain 仓库链接缺失或目标不匹配: $repoLink" }
$agents = Join-Path $HomeDir '.codex/AGENTS.md'
if (-not (Test-Path -LiteralPath $agents -PathType Leaf)) { Fail "缺少 Codex 全局规则: $agents" }
$text = Get-Content -LiteralPath $agents -Raw
$starts = [regex]::Matches($text, '(?m)^<!-- DEV-BRAIN:START -->\r?$').Count
$ends = [regex]::Matches($text, '(?m)^<!-- DEV-BRAIN:END -->\r?$').Count
if ($starts -ne 1 -or $ends -ne 1) { Fail 'Codex 全局规则中的 Dev Brain 受管标记缺失或重复' }
if ($text -notmatch 'task-routing\.md') { Fail 'Codex 入口未指向任务路由' }
$manifest = Get-ManifestEntries
foreach ($skill in @('code-review','debugging','git-delivery','project-onboarding','extract-project-knowledge','targeted-verification','cross-platform-contract')) {
  Test-InstalledSkill $skill $manifest
  if (-not (Test-Path -LiteralPath (Join-Path $HomeDir ".agents/skills/$skill/SKILL.md") -PathType Leaf)) { Fail "Skill 内容缺失: $skill" }
}
Write-Output 'Dev Brain Codex 安装正常（只读诊断）'

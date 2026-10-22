[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$Root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$HomeDir = if ($env:DEV_BRAIN_HOME_DIR) { $env:DEV_BRAIN_HOME_DIR } else { [Environment]::GetFolderPath('UserProfile') }
$HomeDir = [IO.Path]::GetFullPath($HomeDir)
$Start = '<!-- DEV-BRAIN:START -->'
$End = '<!-- DEV-BRAIN:END -->'
$BackupDir = $null
$ManifestPath = Join-Path $HomeDir '.dev-brain/install-manifest.json'

function Fail([string]$Message) { throw "卸载失败: $Message" }
function Test-AnyPath([string]$Path) { return $null -ne (Get-Item -LiteralPath $Path -Force -ErrorAction SilentlyContinue) }
function Get-ItemSafe([string]$Path) { return Get-Item -LiteralPath $Path -Force -ErrorAction SilentlyContinue }
function Resolve-ComparablePath([string]$Path) { try { return [IO.Path]::GetFullPath($Path).TrimEnd('\','/') } catch { return $Path.TrimEnd('\','/') } }
function Test-SameLink([string]$Source, [string]$Target) {
  $item = Get-ItemSafe $Target
  if ($null -eq $item -or $null -eq $item.LinkType) { return $false }
  foreach ($candidate in @($item.Target)) {
    if ($candidate -and (Resolve-ComparablePath ([string]$candidate)) -eq (Resolve-ComparablePath $Source)) { return $true }
  }
  return $false
}
function Ensure-BackupDir {
  if ($null -ne $script:BackupDir) { return }
  $base = Join-Path $HomeDir ('.dev-brain/backups/' + (Get-Date -Format 'yyyyMMddHHmmss') + '-uninstall')
  $candidate = $base
  $suffix = 0
  while (Test-AnyPath $candidate) { $suffix++; $candidate = "$base-$suffix" }
  New-Item -ItemType Directory -Path $candidate -Force | Out-Null
  $script:BackupDir = $candidate
}
function Write-AtomicText([string]$Target, [string]$Text) {
  $directory = Split-Path -Parent $Target
  $tmp = Join-Path $directory ('.dev-brain-uninstall-' + [guid]::NewGuid().ToString('N') + '.tmp')
  try {
    [IO.File]::WriteAllText($tmp, $Text, (New-Object Text.UTF8Encoding($false)))
    Move-Item -LiteralPath $tmp -Destination $Target -Force
  } finally { if (Test-AnyPath $tmp) { Remove-Item -LiteralPath $tmp -Force } }
}
function Get-PathHash([string]$Path) {
  $item = Get-ItemSafe $Path
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
  $parsed = $raw | ConvertFrom-Json
  if ($parsed -is [System.Array]) { return @($parsed) }
  return @($parsed)
}
function Remove-ManagedBlock([string]$Target) {
  if (-not (Test-AnyPath $Target)) { return }
  $item = Get-ItemSafe $Target
  if ($item.LinkType) { Fail "规则文件不能是符号链接: $Target" }
  if ($item.PSIsContainer) { Fail "规则目标不是普通文件: $Target" }
  $text = Get-Content -LiteralPath $Target -Raw
  $lines = $text -split "`r?`n"
  $output = New-Object 'System.Collections.Generic.List[string]'
  $inside = $false
  $starts = 0
  $ends = 0
  foreach ($line in $lines) {
    if ($line -ceq $Start) { $starts++; if ($inside) { Fail "受管区块标记不完整或重复: $Target" }; $inside = $true; continue }
    if ($line -ceq $End) { $ends++; if (-not $inside) { Fail "受管区块标记不完整或重复: $Target" }; $inside = $false; continue }
    if (-not $inside) { [void]$output.Add($line) }
  }
  if ($inside -or $starts -gt 1 -or $ends -gt 1 -or $starts -ne $ends) { Fail "受管区块标记不完整或重复: $Target" }
  if ($starts -eq 0) { return }
  Ensure-BackupDir
  Copy-Item -LiteralPath $Target -Destination (Join-Path $BackupDir ((Split-Path -Leaf $Target) + '.before-uninstall')) -Force
  $newText = [string]::Join("`n", $output).TrimEnd("`r", "`n")
  if ($newText.Length -eq 0) { Remove-Item -LiteralPath $Target -Force } else { Write-AtomicText $Target ($newText + "`n") }
  Write-Output "已移除受管区块: $Target"
}
function Remove-Exclusive([string]$Source, [string]$Target, $ManifestEntries) {
  if (-not (Test-AnyPath $Target)) { return $false }
  if (Test-SameLink $Source $Target) {
    Remove-Item -LiteralPath $Target -Recurse -Force
    Write-Output "已移除链接: $Target"
    return $true
  }
  $entry = $ManifestEntries | Where-Object { $_.target -and (Resolve-ComparablePath ([string]$_.target)) -eq (Resolve-ComparablePath $Target) -and $_.source -and (Resolve-ComparablePath ([string]$_.source)) -eq (Resolve-ComparablePath $Source) } | Select-Object -First 1
  if ($null -ne $entry) {
    $installedHash = if ($entry.installedHash) { [string]$entry.installedHash } else { [string]$entry.hash }
    if (-not $installedHash -or (Get-PathHash $Target) -ne $installedHash.ToLowerInvariant()) { Fail "复制目标已被修改或哈希缺失，未删除: $Target" }
    Remove-Item -LiteralPath $Target -Recurse -Force
    Write-Output "已移除复制项: $Target"
    return $true
  }
  Fail "目标不是 Dev Brain 创建的链接: $Target"
}

$manifestEntries = Get-ManifestEntries
$skills = @('code-review','debugging','git-delivery','project-onboarding','extract-project-knowledge','targeted-verification','cross-platform-contract')
Remove-ManagedBlock (Join-Path $HomeDir '.codex/AGENTS.md')
$removed = New-Object 'System.Collections.Generic.List[string]'
if (Remove-Exclusive (Join-Path $Root 'adapters/cursor/dev-brain.mdc') (Join-Path $HomeDir '.cursor/rules/dev-brain.mdc') $manifestEntries) { [void]$removed.Add((Resolve-ComparablePath (Join-Path $HomeDir '.cursor/rules/dev-brain.mdc'))) }
Remove-ManagedBlock (Join-Path $HomeDir '.claude/CLAUDE.md')
foreach ($skill in $skills) {
  $target = Join-Path $HomeDir ".agents/skills/$skill"
  if (Remove-Exclusive (Join-Path $Root "skills/$skill") $target $manifestEntries) { [void]$removed.Add((Resolve-ComparablePath $target)) }
}
if (Remove-Exclusive $Root (Join-Path $HomeDir '.dev-brain/repo') $manifestEntries) { [void]$removed.Add((Resolve-ComparablePath (Join-Path $HomeDir '.dev-brain/repo'))) }

if (Test-Path -LiteralPath $ManifestPath -PathType Leaf) {
  $remaining = @($manifestEntries | Where-Object { $removed -notcontains (Resolve-ComparablePath ([string]$_.target)) })
  if ($remaining.Count -eq 0) { Remove-Item -LiteralPath $ManifestPath -Force } else { Write-AtomicText $ManifestPath (($remaining | ConvertTo-Json -Depth 5) + "`n") }
}
Write-Output 'Dev Brain 卸载完成；备份仍保留在 ~/.dev-brain/backups/'

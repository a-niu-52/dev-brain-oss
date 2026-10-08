[CmdletBinding()]
param(
  [switch]$DryRun
)

$ErrorActionPreference = 'Stop'
$Root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$HomeDir = if ($env:DEV_BRAIN_HOME_DIR) { $env:DEV_BRAIN_HOME_DIR } else { [Environment]::GetFolderPath('UserProfile') }
$HomeDir = [IO.Path]::GetFullPath($HomeDir)
$TestFailAfter = if ($env:DEV_BRAIN_TEST_FAIL_AFTER) { [int]$env:DEV_BRAIN_TEST_FAIL_AFTER } else { 0 }
$ActionCount = 0
$Journal = New-Object 'System.Collections.Generic.List[object]'
$PendingManifest = New-Object 'System.Collections.Generic.List[object]'
$BackupDir = $null
$Start = '<!-- DEV-BRAIN:START -->'
$End = '<!-- DEV-BRAIN:END -->'
$ManifestPath = Join-Path $HomeDir '.dev-brain/install-manifest.json'

function Fail([string]$Message) {
  throw "安装失败: $Message"
}

function Test-AnyPath([string]$Path) {
  return $null -ne (Get-Item -LiteralPath $Path -Force -ErrorAction SilentlyContinue)
}

function Get-ItemSafe([string]$Path) {
  return Get-Item -LiteralPath $Path -Force -ErrorAction SilentlyContinue
}

function Resolve-ComparablePath([string]$Path) {
  try { return [IO.Path]::GetFullPath($Path).TrimEnd('\','/') } catch { return $Path.TrimEnd('\','/') }
}

function Test-SameLink([string]$Source, [string]$Target) {
  $item = Get-ItemSafe $Target
  if ($null -eq $item -or $null -eq $item.LinkType) { return $false }
  $sourcePath = Resolve-ComparablePath $Source
  foreach ($candidate in @($item.Target)) {
    if ($candidate -and (Resolve-ComparablePath ([string]$candidate)) -eq $sourcePath) { return $true }
  }
  return $false
}

function Get-ManifestEntries {
  if (-not (Test-Path -LiteralPath $ManifestPath -PathType Leaf)) { return @() }
  $raw = Get-Content -LiteralPath $ManifestPath -Raw
  if ([string]::IsNullOrWhiteSpace($raw)) { return @() }
  $parsed = $raw | ConvertFrom-Json
  if ($parsed -is [System.Array]) { return @($parsed) }
  return @($parsed)
}

$ManifestEntries = Get-ManifestEntries

function Find-ManifestEntry([string]$Target, [string]$Source) {
  $targetPath = Resolve-ComparablePath $Target
  foreach ($entry in $ManifestEntries) {
    if ($entry.target -and (Resolve-ComparablePath ([string]$entry.target)) -eq $targetPath -and
        $entry.source -and (Resolve-ComparablePath ([string]$entry.source)) -eq (Resolve-ComparablePath $Source)) {
      return $entry
    }
  }
  return $null
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
    $bytes = [Text.Encoding]::UTF8.GetBytes($builder.ToString())
    return ([BitConverter]::ToString($sha.ComputeHash($bytes))).Replace('-','').ToLowerInvariant()
  } finally { $sha.Dispose() }
}

function Test-ManagedCopy([string]$Source, [string]$Target) {
  $entry = Find-ManifestEntry $Target $Source
  if ($null -eq $entry -or -not (Test-AnyPath $Target)) { return $false }
  $installedHash = if ($entry.installedHash) { [string]$entry.installedHash } else { [string]$entry.hash }
  if ($installedHash -and (Get-PathHash $Target) -ne $installedHash.ToLowerInvariant()) {
    return $false
  }
  return [bool]$installedHash
}

function Check-ExclusiveTarget([string]$Source, [string]$Target) {
  if (-not (Test-AnyPath $Target)) { return }
  if (Test-SameLink $Source $Target -or (Test-ManagedCopy $Source $Target)) { return }
  Fail "目标存在且来源不一致: $Target"
}

function Check-MergeTarget([string]$Target) {
  $item = Get-ItemSafe $Target
  if ($null -eq $item) { return }
  if ($item.LinkType) { Fail "规则文件不能是符号链接: $Target" }
  if ($item.PSIsContainer) { Fail "规则目标不是普通文件: $Target" }
  $lines = Get-Content -LiteralPath $Target
  $starts = @($lines | Where-Object { $_ -ceq $Start }).Count
  $ends = @($lines | Where-Object { $_ -ceq $End }).Count
  if ($starts -gt 1 -or $ends -gt 1 -or $starts -ne $ends) { Fail "受管区块标记不完整或重复: $Target" }
}

function Register-Action {
  $script:ActionCount++
  if ($TestFailAfter -gt 0 -and $script:ActionCount -ge $TestFailAfter) { Fail '测试注入的安装失败' }
}

function Ensure-BackupDir {
  if ($null -ne $script:BackupDir) { return }
  $base = Join-Path $HomeDir ('.dev-brain/backups/' + (Get-Date -Format 'yyyyMMddHHmmss'))
  $candidate = $base
  $suffix = 0
  while (Test-AnyPath $candidate) { $suffix++; $candidate = "$base-$suffix" }
  New-Item -ItemType Directory -Path $candidate -Force | Out-Null
  $script:BackupDir = $candidate
}

function Add-Journal([string]$Kind, [string]$Target, [string]$Backup) {
  $script:Journal.Add([pscustomobject]@{ Kind = $Kind; Target = $Target; Backup = $Backup })
}

function Write-AtomicText([string]$Target, [string]$Text) {
  $directory = Split-Path -Parent $Target
  New-Item -ItemType Directory -Path $directory -Force | Out-Null
  $tmp = Join-Path $directory ('.dev-brain-' + [guid]::NewGuid().ToString('N') + '.tmp')
  try {
    [IO.File]::WriteAllText($tmp, $Text, (New-Object Text.UTF8Encoding($false)))
    Move-Item -LiteralPath $tmp -Destination $Target -Force
  } finally {
    if (Test-AnyPath $tmp) { Remove-Item -LiteralPath $tmp -Force }
  }
}

function Remove-ManagedBlockText([string]$Text, [string]$Target) {
  $lines = $Text -split "`r?`n", -1
  $output = New-Object 'System.Collections.Generic.List[string]'
  $inside = $false
  $starts = 0
  $ends = 0
  foreach ($line in $lines) {
    if ($line -ceq $Start) {
      $starts++
      if ($inside) { Fail "受管区块标记不完整或重复: $Target" }
      $inside = $true
      continue
    }
    if ($line -ceq $End) {
      $ends++
      if (-not $inside) { Fail "受管区块标记不完整或重复: $Target" }
      $inside = $false
      continue
    }
    if (-not $inside) { [void]$output.Add($line) }
  }
  if ($inside -or $starts -gt 1 -or $ends -gt 1 -or $starts -ne $ends) { Fail "受管区块标记不完整或重复: $Target" }
  return [pscustomobject]@{ Text = [string]::Join("`n", $output); Count = $starts }
}

function Merge-ManagedBlock([string]$Source, [string]$Target) {
  if ($DryRun) { Write-Output "将合并受管区块: $Target"; return }
  $existing = if (Test-Path -LiteralPath $Target -PathType Leaf) { Get-Content -LiteralPath $Target -Raw } else { '' }
  $backup = $null
  if (Test-Path -LiteralPath $Target -PathType Leaf) {
    Ensure-BackupDir
    $backup = Join-Path $BackupDir ((Split-Path -Leaf $Target) + '.orig')
    Copy-Item -LiteralPath $Target -Destination $backup -Force
  }
  $clean = Remove-ManagedBlockText $existing $Target
  $base = $clean.Text.TrimEnd("`r", "`n")
  $content = Get-Content -LiteralPath $Source -Raw
  $newText = if ($base.Length -gt 0) { $base + "`n`n" + $Start + "`n" + $content.TrimEnd("`r", "`n") + "`n" + $End + "`n" } else { $Start + "`n" + $content.TrimEnd("`r", "`n") + "`n" + $End + "`n" }
  Write-AtomicText $Target $newText
  Add-Journal $(if ($null -eq $backup) { 'CREATE' } else { 'MERGE' }) $Target $backup
  Register-Action
}

function Install-Exclusive([string]$Source, [string]$Target, [ValidateSet('junction','symlink','copy')][string]$Mode) {
  if (Test-SameLink $Source $Target) { Write-Output "已存在: $Target"; return }
  $isManagedCopy = Test-ManagedCopy $Source $Target
  if ((Test-AnyPath $Target) -and -not $isManagedCopy) { Fail "目标存在且来源不一致或本机副本已修改: $Target" }
  if ($DryRun) {
    if ($isManagedCopy) { Write-Output "将检查并按需刷新副本: $Target" }
    else { Write-Output "将创建链接: $Target -> $Source" }
    return
  }

  New-Item -ItemType Directory -Path (Split-Path -Parent $Target) -Force | Out-Null
  $forceCopy = ($env:DEV_BRAIN_FORCE_COPY -eq '1') -and ($Mode -ne 'junction')
  $sourceHash = Get-PathHash $Source

  if ($isManagedCopy) {
    $entry = Find-ManifestEntry $Target $Source
    $installedHash = if ($entry.installedHash) { [string]$entry.installedHash } else { [string]$entry.hash }
    if ($installedHash -and (Get-PathHash $Target) -ne $installedHash.ToLowerInvariant()) { Fail "复制目标已被本机修改，未覆盖: $Target" }
    if ($entry.sourceHash -and ([string]$entry.sourceHash).ToLowerInvariant() -eq $sourceHash) {
      $script:PendingManifest.Add([pscustomobject]@{ target = $Target; source = $Source; mode = 'copy'; sourceHash = $sourceHash; installedHash = $installedHash.ToLowerInvariant() })
      Write-Output "已是最新: $Target"
      return
    }

    $staged = $Target + '.dev-brain-stage-' + [guid]::NewGuid().ToString('N')
    $backup = $Target + '.dev-brain-backup-' + [guid]::NewGuid().ToString('N')
    try {
      if ((Get-Item -LiteralPath $Source).PSIsContainer) { Copy-Item -LiteralPath $Source -Destination $staged -Recurse -Force } else { Copy-Item -LiteralPath $Source -Destination $staged -Force }
      $stagedHash = Get-PathHash $staged
      if ($stagedHash -ne $sourceHash) { Fail "复制后哈希不一致: $Target" }
      Move-Item -LiteralPath $Target -Destination $backup
      try { Move-Item -LiteralPath $staged -Destination $Target }
      catch { Move-Item -LiteralPath $backup -Destination $Target; throw }
      Add-Journal 'REFRESH' $Target $backup
      Register-Action
      $script:PendingManifest.Add([pscustomobject]@{ target = $Target; source = $Source; mode = 'copy'; sourceHash = $sourceHash; installedHash = $stagedHash })
      Write-Output "已刷新副本: $Target"
    } finally {
      if (Test-AnyPath $staged) { Remove-Item -LiteralPath $staged -Recurse -Force }
    }
    return
  }

  $copyFallback = $false
  if ($Mode -eq 'junction') {
    New-Item -ItemType Junction -Path $Target -Target $Source | Out-Null
  } elseif (-not $forceCopy) {
    try { New-Item -ItemType SymbolicLink -Path $Target -Target $Source | Out-Null }
    catch {
      if (Test-AnyPath $Target) { Remove-Item -LiteralPath $Target -Recurse -Force }
      $copyFallback = $true
    }
  } else { $copyFallback = $true }

  if ($copyFallback) {
    if ((Get-Item -LiteralPath $Source).PSIsContainer) { Copy-Item -LiteralPath $Source -Destination $Target -Recurse -Force } else { Copy-Item -LiteralPath $Source -Destination $Target -Force }
    $installedHash = Get-PathHash $Target
    if ($installedHash -ne $sourceHash) { Fail "复制后哈希不一致: $Target" }
    Add-Journal 'COPY' $Target $null
    $script:PendingManifest.Add([pscustomobject]@{ target = $Target; source = $Source; mode = 'copy'; sourceHash = $sourceHash; installedHash = $installedHash })
  } else {
    Add-Journal 'LINK' $Target $null
  }
  Register-Action
}

function Save-Manifest {
  if ($PendingManifest.Count -eq 0) { return }
  $pendingTargets = @($PendingManifest | ForEach-Object { Resolve-ComparablePath ([string]$_.target) })
  $all = @($ManifestEntries | Where-Object { $pendingTargets -notcontains (Resolve-ComparablePath ([string]$_.target)) }) + @($PendingManifest)
  Write-AtomicText $ManifestPath (($all | ConvertTo-Json -Depth 5) + "`n")
}

function Rollback {
  for ($i = $Journal.Count - 1; $i -ge 0; $i--) {
    $entry = $Journal[$i]
    try {
      if ($entry.Kind -eq 'LINK' -or $entry.Kind -eq 'COPY') {
        if (Test-AnyPath $entry.Target) { Remove-Item -LiteralPath $entry.Target -Recurse -Force }
      } elseif ($entry.Kind -eq 'REFRESH' -and $entry.Backup) {
        if (Test-AnyPath $entry.Target) { Remove-Item -LiteralPath $entry.Target -Recurse -Force }
        if (Test-AnyPath $entry.Backup) { Move-Item -LiteralPath $entry.Backup -Destination $entry.Target }
      } elseif ($entry.Kind -eq 'MERGE' -and $entry.Backup) {
        Copy-Item -LiteralPath $entry.Backup -Destination $entry.Target -Force
      } elseif ($entry.Kind -eq 'CREATE') {
        if (Test-AnyPath $entry.Target) { Remove-Item -LiteralPath $entry.Target -Force }
      }
    } catch { Write-Warning "回滚失败，需保留现场检查: $($entry.Target)" }
  }
}

if (-not (Test-Path -LiteralPath (Join-Path $Root 'adapters/codex/AGENTS.md') -PathType Leaf)) { Fail '缺少 Codex 适配入口' }

$skills = @('code-review','debugging','git-delivery','project-onboarding','extract-project-knowledge','targeted-verification','cross-platform-contract')
Check-ExclusiveTarget $Root (Join-Path $HomeDir '.dev-brain/repo')
Check-MergeTarget (Join-Path $HomeDir '.codex/AGENTS.md')
foreach ($skill in $skills) { Check-ExclusiveTarget (Join-Path $Root "skills/$skill") (Join-Path $HomeDir ".agents/skills/$skill") }

try {
  if ($DryRun) { Write-Output 'dry-run：未修改用户目录' }
  Install-Exclusive $Root (Join-Path $HomeDir '.dev-brain/repo') junction
  Merge-ManagedBlock (Join-Path $Root 'adapters/codex/AGENTS.md') (Join-Path $HomeDir '.codex/AGENTS.md')
  foreach ($skill in $skills) { Install-Exclusive (Join-Path $Root "skills/$skill") (Join-Path $HomeDir ".agents/skills/$skill") symlink }
  Save-Manifest
  foreach ($entry in $Journal | Where-Object { $_.Kind -eq 'REFRESH' -and $_.Backup }) {
    try { if (Test-AnyPath $entry.Backup) { Remove-Item -LiteralPath $entry.Backup -Recurse -Force } }
    catch { Write-Warning "已完成副本更新，但临时备份仍保留: $($entry.Backup)" }
  }
  if ($DryRun) { Write-Output 'dry-run 完成：未安装或修改用户目录' }
  else { Write-Output 'Dev Brain Codex 安装完成' }
} catch {
  Rollback
  throw
}

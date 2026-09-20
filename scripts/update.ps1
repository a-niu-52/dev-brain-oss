[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$Root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
Set-Location $Root

$status = @(git status --porcelain)
if ($status.Count -gt 0) {
  Write-Error '更新停止：Dev Brain 工作区存在未提交修改。' -ErrorAction Continue
  $status | ForEach-Object { Write-Error $_ -ErrorAction Continue }
  exit 1
}

& git pull --ff-only
if ($LASTEXITCODE -ne 0) {
  Write-Error '更新失败，保留现场。' -ErrorAction Continue
  Write-Error "当前分支: $((git branch --show-current).Trim())" -ErrorAction Continue
  git status --short | ForEach-Object { Write-Error $_ -ErrorAction Continue }
  Write-Error '未推送提交:' -ErrorAction Continue
  git log --oneline '@{upstream}..HEAD' 2>$null | ForEach-Object { Write-Error $_ -ErrorAction Continue }
  Write-Error '远程地址:' -ErrorAction Continue
  git remote -v | ForEach-Object { Write-Error $_ -ErrorAction Continue }
  exit 1
}

& (Join-Path $PSScriptRoot 'validate.ps1')
& (Join-Path $PSScriptRoot 'install.ps1')
Write-Output 'Dev Brain 更新完成'

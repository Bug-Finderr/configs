param([int] $IntervalDays = 7)

$ErrorActionPreference = 'Stop'

$lastRun = Join-Path $env:LOCALAPPDATA 'ConfigsMaintenance\last-run.txt'
$dedup = Join-Path $PSScriptRoot 'powershell\Optimize-PSReadlineHistory\Optimize-PSReadlineHistory.ps1'

if ((Test-Path $lastRun) -and ((Get-Date) - (Get-Item $lastRun).LastWriteTime).TotalDays -lt $IntervalDays) {
    return
}

& $dedup -SkipRunningPowerShellCheck -TrimLeadingWhitespace -MinimumCommandLength 5

New-Item -ItemType Directory -Path (Split-Path $lastRun) -Force | Out-Null
New-Item -ItemType File -Path $lastRun -Force | Out-Null

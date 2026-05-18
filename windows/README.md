# Windows Configs

## PowerShell Profile

Both profile files source the same tracked profile:

- PowerShell 7: `~/Documents/PowerShell/Microsoft.PowerShell_profile.ps1`
- Windows PowerShell 5.1: `~/Documents/WindowsPowerShell/Microsoft.PowerShell_profile.ps1`
- Shared file: `windows/powershell/Microsoft.PowerShell_profile.ps1`

The Documents profiles only dot-source the shared file, so edits stay in this repo.

Put this in both Documents profile files:

```powershell
$ConfigProfile = "D:\Files\Dev\configs\windows\powershell\Microsoft.PowerShell_profile.ps1"

if (Test-Path -LiteralPath $ConfigProfile) {
	. $ConfigProfile
}
```

## PSReadLine History Cleanup

`Invoke-WindowsMaintenance.ps1` runs `Optimize-PSReadlineHistory` at most once every 7 days:

```powershell
Optimize-PSReadlineHistory -SkipRunningPowerShellCheck -TrimLeadingWhitespace -MinimumCommandLength 5
```

One-time admin registration:

```powershell
$script = 'D:\Files\Dev\configs\windows\Invoke-WindowsMaintenance.ps1'
$action = New-ScheduledTaskAction -Execute (Get-Command pwsh).Source -Argument "-ExecutionPolicy Bypass -File `"$script`""
$triggers = @(New-ScheduledTaskTrigger -Weekly -DaysOfWeek Sunday -At 9am; New-ScheduledTaskTrigger -AtStartup)
Register-ScheduledTask -TaskName 'Configs Windows Maintenance' -Action $action -Trigger $triggers -User "$env:USERDOMAIN\$env:USERNAME" -RunLevel Highest -Force
```

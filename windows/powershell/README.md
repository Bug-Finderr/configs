# PowerShell

- `Microsoft.PowerShell_profile.ps1` - shared profile for PowerShell 7 and
  Windows PowerShell 5.1.
- `GitHubAccountRouting.ps1` - routes `gh` to the work or personal account by
  directory.
- `Invoke-WindowsMaintenance.ps1` - throttles PSReadLine history cleanup to
  once per interval.
- `Optimize-PSReadlineHistory/` - history-optimizer Git submodule.

The shared profile configures fnm, oh-my-posh, editors, PSReadLine, aliases, and
GitHub account routing. Initialize the optimizer after cloning:

```powershell
git submodule update --init --recursive
```

## Profile activation

Put this launcher in both profile files:

- `~/Documents/PowerShell/Microsoft.PowerShell_profile.ps1`
- `~/Documents/WindowsPowerShell/Microsoft.PowerShell_profile.ps1`

```powershell
$ConfigProfile = 'D:\Files\Dev\configs\windows\powershell\Microsoft.PowerShell_profile.ps1'

if (Test-Path -LiteralPath $ConfigProfile) {
    . $ConfigProfile
}
```

## Scheduled maintenance

Register the history cleanup once from an elevated session:

```powershell
$script = 'D:\Files\Dev\configs\windows\powershell\Invoke-WindowsMaintenance.ps1'
$pwsh = "$env:LOCALAPPDATA\Microsoft\WindowsApps\pwsh.exe"
$action = New-ScheduledTaskAction -Execute $pwsh `
    -Argument "-ExecutionPolicy Bypass -File `"$script`""
$triggers = @(
    New-ScheduledTaskTrigger -Weekly -DaysOfWeek Sunday -At 9am
    New-ScheduledTaskTrigger -AtStartup
)
Register-ScheduledTask -TaskName 'Configs Windows Maintenance' `
    -Action $action -Trigger $triggers `
    -User "$env:USERDOMAIN\$env:USERNAME" -RunLevel Highest -Force
```

The stable WindowsApps alias avoids versioned Store paths. Successful runs
update `%LOCALAPPDATA%\ConfigsMaintenance\last-run.txt`.

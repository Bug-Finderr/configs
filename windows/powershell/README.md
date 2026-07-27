# PowerShell

- `Microsoft.PowerShell_profile.ps1` - shared profile for PowerShell 7 and
  Windows PowerShell 5.1.
- `GitHubAccountRouting.ps1` - routes `gh` to the work or personal account by
  directory.
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

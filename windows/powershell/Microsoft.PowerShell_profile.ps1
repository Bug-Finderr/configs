fnm env --use-on-cd --shell powershell | Out-String | Invoke-Expression

& ([ScriptBlock]::Create((oh-my-posh init pwsh --config jblab_2021 --print) -join "`n"))

$env:VISUAL = 'zed --wait'
$env:EDITOR = $env:VISUAL
$env:CLAUDE_CODE_USE_POWERSHELL_TOOL=1

$psReadLineOptions = (Get-Command Set-PSReadLineOption).Parameters
$canUsePrediction = [Environment]::UserInteractive -and -not [Console]::IsOutputRedirected

if ($canUsePrediction -and $psReadLineOptions.ContainsKey('PredictionSource')) { Set-PSReadLineOption -PredictionSource History }
if ($canUsePrediction -and $psReadLineOptions.ContainsKey('PredictionViewStyle')) { Set-PSReadLineOption -PredictionViewStyle ListView }

Set-PSReadLineOption -HistoryNoDuplicates:$True
Set-PSReadlineKeyHandler -Key Tab -Function MenuComplete

# Aliases
Set-Alias c clear
Set-Alias avenv .\.venv\Scripts\Activate.ps1
Set-Alias lg lazygit

# Alias functions
function e { exit }
function cx { c; codex --yolo @args }
function cc { claude --dangerously-skip-permissions @args }
function ccx { & 'D:/Files/Dev/ccx/ccx.ps1' @args }
function kp { netstat -ano | findstr ":$($args[0])" | ForEach-Object { ($_ -split '\s+')[-1] } | Sort-Object -Unique | ForEach-Object { taskkill /PID $_ /F } }
. "$PSScriptRoot/GitHubAccountRouting.ps1"

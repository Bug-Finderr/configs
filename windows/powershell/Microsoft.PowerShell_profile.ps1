fnm env --use-on-cd --shell powershell | Out-String | Invoke-Expression

& ([ScriptBlock]::Create((oh-my-posh init pwsh --config jblab_2021 --print) -join "`n"))

$psReadLineOptions = (Get-Command Set-PSReadLineOption).Parameters

if ($psReadLineOptions.ContainsKey('PredictionSource')) { Set-PSReadLineOption -PredictionSource History }
if ($psReadLineOptions.ContainsKey('PredictionViewStyle')) { Set-PSReadLineOption -PredictionViewStyle ListView }

Set-PSReadLineOption -HistoryNoDuplicates:$True
Set-PSReadlineKeyHandler -Key Tab -Function MenuComplete

# Aliases
Set-Alias c clear
Set-Alias avenv .\.venv\Scripts\Activate.ps1

# Alias functions
function e { exit }
function cx { c; codex --yolo @args }

function cvenv {
	python -m venv .venv
	avenv
	python.exe -m pip install --upgrade pip
}

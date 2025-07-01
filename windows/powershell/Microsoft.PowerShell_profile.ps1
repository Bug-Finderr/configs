& ([ScriptBlock]::Create((oh-my-posh init pwsh --config "$env:POSH_THEMES_PATH\jblab_2021.omp.json" --print) -join "`n"))
Set-PSReadLineOption -PredictionSource History
Set-PSReadLineOption -PredictionViewStyle ListView
Set-PSReadLineOption -HistoryNoDuplicates:$True
Set-PSReadlineKeyHandler -Key Tab -Function MenuComplete


# Import the Chocolatey Profile that contains the necessary code to enable
# tab-completions to function for `choco`.
# Be aware that if you are missing these lines from your profile, tab completion
# for `choco` will not function.
# See https://ch0.co/tab-completion for details.
$ChocolateyProfile = "$env:ChocolateyInstall\helpers\chocolateyProfile.psm1"
if (Test-Path($ChocolateyProfile)) {
  Import-Module "$ChocolateyProfile"
}

# Aliases
Set-Alias c clear
Set-Alias avenv .\venv\Scripts\Activate.ps1

# Alias functions
function e { exit }

function cf {
	Set-Location "D:\Files\Dev\companion-frontend\"
	yarn dev
}

function cb {
    param([switch]$build)
    
    docker desktop start
    do { Start-Sleep 1 } while (!(docker info 2>$null))
    Get-Process "Docker Desktop" -ErrorAction SilentlyContinue | % { $_.CloseMainWindow() } | Out-Null
    
    Set-Location "D:\Files\Dev\companion-backend\"
    $cmd = @("-f", "deploy/docker-compose.yml", "-f", "deploy/docker-compose.dev.yml", "--project-directory", ".", "up")
    if ($build) { $cmd += "--build" }
    docker-compose @cmd
}

function cvenv {
	python -m venv venv
	avenv
	python.exe -m pip install --upgrade pip
}

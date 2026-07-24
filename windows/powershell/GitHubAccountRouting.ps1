function gh {
	$ghExe = (Get-Command gh.exe -CommandType Application -ErrorAction Stop).Source

	if ($args[0] -eq 'auth' -or $env:GH_TOKEN -or $env:GITHUB_TOKEN) {
		& $ghExe @args
		return
	}

	$workRoot = 'D:\Files\Dev\aistudio'
	$currentPath = (Get-Location).Path
	$isWork = $currentPath -eq $workRoot -or
		$currentPath.StartsWith("$workRoot\", [StringComparison]::OrdinalIgnoreCase)
	$account = if ($isWork) { 'sudharsan-aistudio' } else { 'Bug-Finderr' }

	try {
		$token = "$(& $ghExe auth token --hostname github.com --user $account)".Trim()
		if ($LASTEXITCODE -ne 0 -or -not $token) { throw "No stored GitHub CLI token found for $account." }

		$env:GH_TOKEN = $token
		& $ghExe @args
		$exitCode = $LASTEXITCODE
	}
	finally {
		Remove-Item Env:GH_TOKEN -ErrorAction SilentlyContinue
	}

	$global:LASTEXITCODE = $exitCode
}

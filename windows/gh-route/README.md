# gh-route

A `gh.exe` shim. Inside `D:\Files\Dev\work-folder` it runs the real GitHub CLI as `work-account`; anywhere else as `personal-account`. It passes the account's stored token in `GH_TOKEN` per run, so the globally active account never changes and both trees work at the same time. It works in every shell and in programs that start `gh` themselves, with or without a profile.

`gh auth ...` and runs with `GH_TOKEN` or `GITHUB_TOKEN` already set go straight to the real CLI. Both accounts must be logged in (`gh auth status`).

## Install

From an elevated PowerShell:

```powershell
cargo build --release
New-Item -ItemType Directory -Force 'C:\Program Files\gh-route' | Out-Null
Copy-Item -Force target\release\gh.exe 'C:\Program Files\gh-route\gh.exe'
```

Then add `C:\Program Files\gh-route` to the Machine PATH directly before `C:\Program Files\GitHub CLI\`. The User PATH comes after the Machine PATH, so an entry there loses to the real `gh`. Edit the raw value (`GetValue('Path', $null, 'DoNotExpandEnvironmentNames')`, written back as `ExpandString`); `setx` truncates long paths. Restart terminals and editors afterwards.

## Check

```powershell
(Get-Command gh).Source                                  # C:\Program Files\gh-route\gh.exe
Set-Location D:\Files\Dev\work-folder; gh api user --jq .login   # work-account
Set-Location D:\Files\Dev; gh api user --jq .login            # personal-account
```

Rebuild and recopy after changing the work root or account names in `src/main.rs`.

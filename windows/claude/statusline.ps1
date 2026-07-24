# Claude Code status line - ".bread" theme (Catppuccin, plain style).
# Reads Claude Code session JSON on stdin, prints minimal colored text to stdout as UTF-8.
# Linked from C:\Users\Sudharsan\.claude\statusline.ps1 (stub), like the pwsh profile.
# Invoked via powershell.exe 5.1 (settings.json), not pwsh: 5.1 spawns ~165ms faster warm - don't "modernize".
# Layout:
#   {green (venv)}{pink path}  {lavender  branch}{gray gone up/down}{peach +a ~m -d}{green staged}{gray stash}
#     {gray >}  {blue model} {gray 1M}  · {pill bar} {pct%}  · {effort}

$ErrorActionPreference = 'SilentlyContinue'

# Console codepage here is OEM (CP850), not UTF-8: decode stdin and git output as UTF-8
# explicitly, or non-ASCII paths/branches mojibake and a mangled path kills the git segment.
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# ---- read session JSON from stdin (raw UTF-8; stub must not consume stdin first) ----
try {
    $raw = (New-Object System.IO.StreamReader([Console]::OpenStandardInput(), [System.Text.Encoding]::UTF8)).ReadToEnd()
    $j = $raw | ConvertFrom-Json
} catch { $j = $null }

# ---- glyphs (built from code points to avoid file-encoding issues) ----
$e      = [char]27
$GBR    = [char]0xE725   # git branch icon
$CLOSER = [char]0xF105   # angle-right (bread closer)
$STG    = [char]0xF046   # staging (check-square)
$FLAG   = [char]0x2691   # stash flag
$UP     = [char]0x2191   # ahead
$DN     = [char]0x2193   # behind
$GONE   = [char]0x2262   # upstream gone (not-identical)
$MIDDOT = [char]0x00B7   # separator dot
$PILF   = [char]0x25B0   # filled pill (bar)
$PILE   = [char]0x25B1   # empty pill (bar track)
$BLANK  = [char]0x2800   # braille blank: non-whitespace spacer row

# ---- Catppuccin palette (from .bread.omp.json) ----
$PINK     = @(245,194,231)  # path
$LAVENDER = @(180,190,254)  # branch
$GREEN    = @(166,227,161)  # venv / staged / low ctx
$RED      = @(255,85,85)    # high ctx
$YELLOW   = @(249,226,175)  # mid ctx
$PEACH    = @(250,179,135)  # working-tree changes
$OSGRAY   = @(172,176,190)  # closer
$BLUE     = @(137,180,250)  # model
$GRAY     = @(108,112,134)  # separators / effort / meta / bar track

function Fg($c) { "$e[38;2;$($c[0]);$($c[1]);$($c[2])m" }
function Sep()  { ' ' + (Fg $GRAY) + $MIDDOT + ' ' }
function Out-Utf8($text) {
    $bytes = [System.Text.Encoding]::UTF8.GetBytes($text)
    $stdout = [Console]::OpenStandardOutput()
    $stdout.Write($bytes, 0, $bytes.Length); $stdout.Flush()
}

# Claude Code invokes subagentStatusLine once with every visible task. Render the
# resolved model ID it supplies instead of inferring a model from the task name.
if ($j -and $j.tasks) {
    $rows = @($j.tasks | ForEach-Object {
        if (-not $_.id -or -not $_.model) { return }
        $name = if ($_.label) { $_.label } elseif ($_.name) { $_.name } else { $_.type }
        $content = if ($name) {
            (Fg $LAVENDER) + $name + (Sep) + (Fg $BLUE) + $_.model + "$e[0m"
        } else {
            (Fg $BLUE) + $_.model + "$e[0m"
        }
        [ordered]@{ id = [string]$_.id; content = $content } | ConvertTo-Json -Compress
    })
    if ($rows.Count) { Out-Utf8 (($rows -join "`n") + "`n") }
    exit
}

# ---- gather data ----
$model = $null
if ($j) { $model = $j.model.display_name; if (-not $model) { $model = $j.model.id } }
if (-not $model) { $model = 'Claude' }

$cwd = $null
if ($j) { $cwd = $j.workspace.current_dir; if (-not $cwd) { $cwd = $j.cwd } }
if (-not $cwd) { $cwd = (Get-Location).Path }
$gitDir = $cwd   # git target = displayed dir, captured before the ~ rewrite

$homeDir = $HOME
if ($homeDir -and $cwd.StartsWith($homeDir, [System.StringComparison]::OrdinalIgnoreCase) -and
    ($cwd.Length -eq $homeDir.Length -or $cwd[$homeDir.Length] -in '\','/')) {
    $cwd = '~' + $cwd.Substring($homeDir.Length)
}
$parts = $cwd -split '[\\/]' | Where-Object { $_ -ne '' }
if ($parts.Count -gt 2) { $path = '.../' + ($parts[-2..-1] -join '/') }
else { $path = ($parts -join '/') }
if (-not $path) { $path = $cwd }

# git: branch, upstream state, working/staged counts, stash - one git call.
# --no-optional-locks: never take index.lock from the statusline.
# Untracked walk kept (default -unormal): '?' lines feed the working +count.
$branch = $null; $oid = $null; $upstream = $false; $hasAb = $false
$ahead = 0; $behind = 0; $staged = 0; $wAdd = 0; $wMod = 0; $wDel = 0; $stash = 0
foreach ($line in (& git -C $gitDir --no-optional-locks status --porcelain=v2 --branch --show-stash 2>$null)) {
    if ($line.Length -lt 3) { continue }
    $c = $line[0]
    if ($c -eq '#') {
        if     ($line.StartsWith('# branch.head '))     { $branch = $line.Substring(14) }
        elseif ($line.StartsWith('# branch.upstream ')) { $upstream = $true }
        elseif ($line.StartsWith('# branch.ab '))       { $hasAb = $true; $t = $line.Substring(12) -split ' '; $ahead = [int]$t[0].Substring(1); $behind = [int]$t[1].Substring(1) }
        elseif ($line.StartsWith('# stash '))           { $stash = [int]$line.Substring(8) }
        elseif ($line.StartsWith('# branch.oid '))      { $oid = $line.Substring(13) }
    }
    elseif ($c -eq '?') { $wAdd++ }
    elseif ($c -eq '1' -or $c -eq '2' -or $c -eq 'u') {
        if ($line[2] -ne '.') { $staged++ }
        $y = $line[3]
        if ($y -eq 'M' -or $y -eq 'T') { $wMod++ }
        elseif ($y -eq 'D') { $wDel++ }
        elseif ($y -eq 'A') { $wAdd++ }
    }
}
if ($branch -eq '(detached)' -and $oid) { $branch = $oid.Substring(0, 7) }

# context window %
$pct = $null
if ($j -and $j.context_window -and $j.context_window.used_percentage -ne $null) {
    $pct = [int][math]::Floor([double]$j.context_window.used_percentage)
}

# reasoning effort
$eff = $null
if ($j -and $j.effort -and $j.effort.level) { $eff = ([string]$j.effort.level).ToLower() }

function Ctx-Color($p) { if ($p -ge 80) { $RED } elseif ($p -ge 60) { $YELLOW } else { $GREEN } }
function Ctx-Bar($p) {
    $w = 10
    $f = [int][math]::Round($p * $w / 100.0)
    if ($f -gt $w) { $f = $w } elseif ($f -lt 0) { $f = 0 }
    (Fg (Ctx-Color $p)) + [string]::new($PILF, $f) + (Fg $GRAY) + [string]::new($PILE, ($w - $f))
}

# ---- render (plain colored text, no backgrounds) ----
$sb = New-Object System.Text.StringBuilder
if ($env:VIRTUAL_ENV) { [void]$sb.Append((Fg $GREEN) + '(venv) ') }
[void]$sb.Append((Fg $PINK) + $path)

if ($branch) {
    [void]$sb.Append(' ' + (Fg $LAVENDER) + $GBR + ' ' + $branch)
    if ($upstream -and -not $hasAb) { [void]$sb.Append(' ' + (Fg $GRAY) + $GONE) }
    if ($ahead -gt 0)  { [void]$sb.Append(' ' + (Fg $GRAY)  + "$UP$ahead") }
    if ($behind -gt 0) { [void]$sb.Append(' ' + (Fg $GRAY)  + "$DN$behind") }
    $w = @()
    if ($wAdd -gt 0) { $w += "+$wAdd" }
    if ($wMod -gt 0) { $w += "~$wMod" }
    if ($wDel -gt 0) { $w += "-$wDel" }
    if ($w.Count) { [void]$sb.Append(' ' + (Fg $PEACH) + ($w -join ' ')) }
    if ($staged -gt 0) { [void]$sb.Append(' ' + (Fg $GREEN) + "$STG $staged") }
    if ($stash -gt 0)  { [void]$sb.Append(' ' + (Fg $GRAY)  + "$FLAG$stash") }
}

[void]$sb.Append('  ' + (Fg $OSGRAY) + $CLOSER + ' ' + (Fg $BLUE) + $model)
if ($j -and $j.context_window.context_window_size -gt 200000) { [void]$sb.Append(' ' + (Fg $GRAY) + '1M') }

if ($pct -ne $null) {
    [void]$sb.Append((Sep) + (Ctx-Bar $pct) + ' ' + (Fg (Ctx-Color $pct)) + "$pct%")
}
if ($eff) { [void]$sb.Append((Sep) + (Fg $GRAY) + $eff) }

[void]$sb.Append("$e[0m")
[void]$sb.Append("`n$BLANK")

# ---- emit as raw UTF-8 (survives any console codepage) ----
Out-Utf8 $sb.ToString()

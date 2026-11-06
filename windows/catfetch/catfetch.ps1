#!/usr/bin/env pwsh
#requires -version 7

[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$sourceImage = Join-Path $PSScriptRoot 'cat.png'
$configPath = Join-Path $PSScriptRoot 'catfetch.jsonc'
$sixelPath = Join-Path $PSScriptRoot 'catfetch.sixel'

$config = Get-Content -Raw -LiteralPath $configPath | ConvertFrom-Json
$inputs = Get-Item -LiteralPath $sourceImage, $configPath, $PSCommandPath
$cache = Get-Item -LiteralPath $sixelPath -ErrorAction Ignore

if (-not $cache -or ($inputs | Where-Object LastWriteTimeUtc -gt $cache.LastWriteTimeUtc)) {
    $size = "$($config.logo.width)x$($config.logo.height)"
    $sixel = chafa.exe --format sixels --colors full --size $size --animate off --bg black --polite on $sourceImage
    if ($LASTEXITCODE -ne 0 -or -not $sixel) {
        throw "Chafa could not convert the image (exit code $LASTEXITCODE)."
    }
    [System.IO.File]::WriteAllText($sixelPath, ($sixel -join "`n"), [System.Text.Encoding]::ASCII)
}

fastfetch.exe --config $configPath --raw $sixelPath --pipe false
if ($LASTEXITCODE -ne 0) {
    throw "Fastfetch failed (exit code $LASTEXITCODE)."
}

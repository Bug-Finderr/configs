#!/usr/bin/env pwsh
#requires -version 7

[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$fastfetch = (Get-Command fastfetch.exe -CommandType Application -ErrorAction Stop).Source
$chafa = (Get-Command chafa.exe -CommandType Application -ErrorAction Stop).Source
$sourceImage = Join-Path $PSScriptRoot 'cat.png'
$configPath = Join-Path $PSScriptRoot 'catfetch.jsonc'
$sixelPath = Join-Path $PSScriptRoot 'catfetch.sixel'

foreach ($path in @($sourceImage, $configPath)) {
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
        throw "Missing required file: $path"
    }
}

$regenerate = -not (Test-Path -LiteralPath $sixelPath -PathType Leaf)
if (-not $regenerate) {
    $cacheTime = (Get-Item -LiteralPath $sixelPath).LastWriteTimeUtc
    $regenerate = (Get-Item -LiteralPath $sourceImage).LastWriteTimeUtc -gt $cacheTime -or
        (Get-Item -LiteralPath $PSCommandPath).LastWriteTimeUtc -gt $cacheTime
}

if ($regenerate) {
    $sixel = & $chafa --format sixels --colors full --size 34x17 --animate off --bg black --polite on $sourceImage
    if ($LASTEXITCODE -ne 0 -or -not $sixel) {
        throw "Chafa could not convert the image (exit code $LASTEXITCODE)."
    }
    [System.IO.File]::WriteAllText($sixelPath, ($sixel -join "`n"), [System.Text.Encoding]::ASCII)
}

& $fastfetch --config $configPath --raw $sixelPath --pipe false
if ($LASTEXITCODE -ne 0) {
    throw "Fastfetch failed (exit code $LASTEXITCODE)."
}

param(
    [string]$ImagePath,
    [string]$PalettePath = (Join-Path $PSScriptRoot "palette.css"),
    [string]$SettingsPath = (Join-Path $PSScriptRoot "theme-settings.json"),
    [string]$BackgroundOverride,
    [string]$TextOverride,
    [switch]$Preview,
    [switch]$Force,
    [switch]$NoReload
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function ConvertTo-HexColor {
    param([double]$Red, [double]$Green, [double]$Blue)

    $r = [Math]::Min(255, [Math]::Max(0, [Math]::Round($Red)))
    $g = [Math]::Min(255, [Math]::Max(0, [Math]::Round($Green)))
    $b = [Math]::Min(255, [Math]::Max(0, [Math]::Round($Blue)))
    return "#{0:X2}{1:X2}{2:X2}" -f [int]$r, [int]$g, [int]$b
}

function ConvertFrom-Hsv {
    param([double]$Hue, [double]$Saturation, [double]$Value)

    $chroma = $Value * $Saturation
    $sector = (($Hue % 360) + 360) % 360 / 60
    $x = $chroma * (1 - [Math]::Abs(($sector % 2) - 1))
    $red = 0.0
    $green = 0.0
    $blue = 0.0
    switch ([int][Math]::Floor($sector)) {
        0 { $red = $chroma; $green = $x; break }
        1 { $red = $x; $green = $chroma; break }
        2 { $green = $chroma; $blue = $x; break }
        3 { $green = $x; $blue = $chroma; break }
        4 { $red = $x; $blue = $chroma; break }
        default { $red = $chroma; $blue = $x }
    }
    $m = $Value - $chroma
    return @(
        ($red + $m) * 255
        ($green + $m) * 255
        ($blue + $m) * 255
    )
}

function Get-ColorMetrics {
    param([double]$Red, [double]$Green, [double]$Blue)

    $r = $Red / 255
    $g = $Green / 255
    $b = $Blue / 255
    $max = [Math]::Max($r, [Math]::Max($g, $b))
    $min = [Math]::Min($r, [Math]::Min($g, $b))
    $delta = $max - $min
    $saturation = if ($max -eq 0) { 0 } else { $delta / $max }
    $hue = 0
    if ($delta -ne 0) {
        if ($max -eq $r) {
            $hue = 60 * ((($g - $b) / $delta) % 6)
        } elseif ($max -eq $g) {
            $hue = 60 * ((($b - $r) / $delta) + 2)
        } else {
            $hue = 60 * ((($r - $g) / $delta) + 4)
        }
        if ($hue -lt 0) { $hue += 360 }
    }
    return [pscustomobject]@{ Hue = $hue; Saturation = $saturation; Value = $max }
}

function Get-RelativeLuminance {
    param([string]$Color)

    $channels = @(1, 3, 5) | ForEach-Object {
        $value = [Convert]::ToInt32($Color.Substring($_, 2), 16) / 255
        if ($value -le 0.04045) { $value / 12.92 } else { [Math]::Pow(($value + 0.055) / 1.055, 2.4) }
    }
    return (0.2126 * $channels[0]) + (0.7152 * $channels[1]) + (0.0722 * $channels[2])
}

function Get-ContrastRatio {
    param([string]$First, [string]$Second)

    $a = Get-RelativeLuminance $First
    $b = Get-RelativeLuminance $Second
    return ([Math]::Max($a, $b) + 0.05) / ([Math]::Min($a, $b) + 0.05)
}

function Get-WallpaperAccent {
    param([string]$Path, [string]$Background, [string]$Text)

    Add-Type -AssemblyName System.Drawing
    $source = [System.Drawing.Bitmap]::new($Path)
    $sample = [System.Drawing.Bitmap]::new(64, 64)
    $graphics = [System.Drawing.Graphics]::FromImage($sample)
    try {
        $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBilinear
        $graphics.DrawImage($source, 0, 0, 64, 64)
    } finally {
        $graphics.Dispose()
        $source.Dispose()
    }

    $bins = @{}
    $fallback = [ordered]@{ Red = 0.0; Green = 0.0; Blue = 0.0; Weight = 0.0 }
    try {
        for ($y = 0; $y -lt $sample.Height; $y++) {
            for ($x = 0; $x -lt $sample.Width; $x++) {
                $pixel = $sample.GetPixel($x, $y)
                if ($pixel.A -lt 180) { continue }
                $metrics = Get-ColorMetrics $pixel.R $pixel.G $pixel.B
                if ($metrics.Value -gt 0.1) {
                    $fallback.Red += $pixel.R
                    $fallback.Green += $pixel.G
                    $fallback.Blue += $pixel.B
                    $fallback.Weight++
                }
                if ($metrics.Saturation -lt 0.16 -or $metrics.Value -lt 0.14 -or $metrics.Value -gt 0.98) { continue }

                $bucket = [int][Math]::Floor($metrics.Hue / 15)
                if (-not $bins.ContainsKey($bucket)) {
                    $bins[$bucket] = [ordered]@{ Red = 0.0; Green = 0.0; Blue = 0.0; Weight = 0.0; Score = 0.0 }
                }
                $weight = (0.2 + [Math]::Pow($metrics.Saturation, 1.7)) * (0.7 + (0.3 * $metrics.Value))
                $bins[$bucket].Red += $pixel.R * $weight
                $bins[$bucket].Green += $pixel.G * $weight
                $bins[$bucket].Blue += $pixel.B * $weight
                $bins[$bucket].Weight += $weight
                $bins[$bucket].Score += $weight
            }
        }
    } finally {
        $sample.Dispose()
    }

    if ($bins.Count -gt 0) {
        $winner = $bins.GetEnumerator() | Sort-Object { $_.Value.Score } -Descending | Select-Object -First 1
        $red = $winner.Value.Red / $winner.Value.Weight
        $green = $winner.Value.Green / $winner.Value.Weight
        $blue = $winner.Value.Blue / $winner.Value.Weight
    } elseif ($fallback.Weight -gt 0) {
        $red = $fallback.Red / $fallback.Weight
        $green = $fallback.Green / $fallback.Weight
        $blue = $fallback.Blue / $fallback.Weight
    } else {
        throw "The wallpaper did not contain usable pixels."
    }

    $chosen = Get-ColorMetrics $red $green $blue
    $targetSaturation = [Math]::Min(0.78, [Math]::Max(0.58, $chosen.Saturation))
    $targetValue = [Math]::Min(0.90, [Math]::Max(0.78, $chosen.Value))
    $rgb = ConvertFrom-Hsv $chosen.Hue $targetSaturation $targetValue
    $accent = ConvertTo-HexColor $rgb[0] $rgb[1] $rgb[2]

    $contrastCandidates = @($Background, $Text, "#FFFFFF", "#000000") | ForEach-Object {
        [pscustomobject]@{ Color = $_; Ratio = Get-ContrastRatio $accent $_ }
    }
    $bestContrast = $contrastCandidates | Sort-Object Ratio -Descending | Select-Object -First 1

    return [pscustomobject]@{
        Accent = $accent
        AccentText = $bestContrast.Color
        Source = [System.IO.Path]::GetFullPath($Path)
        Contrast = [Math]::Round($bestContrast.Ratio, 2)
    }
}

if (-not $ImagePath) {
    $ImagePath = (Get-ItemProperty -LiteralPath "HKCU:\Control Panel\Desktop" -Name WallPaper).WallPaper
}
if (-not (Test-Path -LiteralPath $ImagePath -PathType Leaf)) {
    throw "Wallpaper does not exist: $ImagePath"
}
if (-not (Test-Path -LiteralPath $PalettePath -PathType Leaf)) {
    throw "Palette does not exist: $PalettePath"
}

$palette = [System.IO.File]::ReadAllText($PalettePath)
if ($palette -notmatch '--background:\s*(#[0-9A-Fa-f]{6})\s*;') { throw "Palette is missing --background." }
$background = if ($BackgroundOverride) { $BackgroundOverride } else { $matches[1] }
if ($palette -notmatch '--text:\s*(#[0-9A-Fa-f]{6})\s*;') { throw "Palette is missing --text." }
$text = if ($TextOverride) { $TextOverride } else { $matches[1] }
$result = Get-WallpaperAccent -Path $ImagePath -Background $background -Text $text

if ($Preview) {
    $result
    exit 0
}

if (-not $Force) {
    if (-not (Test-Path -LiteralPath $SettingsPath -PathType Leaf)) { exit 0 }
    $settings = [System.IO.File]::ReadAllText($SettingsPath) | ConvertFrom-Json
    if ($settings.accentSource -ne "wallpaper") { exit 0 }
}

$updated = $palette
foreach ($token in @("accent", "yasb-accent")) {
    $pattern = "--${token}:\s*#[0-9A-Fa-f]{6}\s*;"
    if ($updated -notmatch $pattern) { throw "Palette is missing --$token." }
    $updated = [regex]::Replace($updated, $pattern, "--${token}: $($result.Accent);", 1)
}
$accentTextPattern = '--accentText:\s*#[0-9A-Fa-f]{6}\s*;'
if ($updated -notmatch $accentTextPattern) { throw "Palette is missing --accentText." }
$updated = [regex]::Replace($updated, $accentTextPattern, "--accentText: $($result.AccentText);", 1)

[System.IO.File]::WriteAllText($PalettePath, $updated, [System.Text.UTF8Encoding]::new($false))

if (-not $NoReload) {
    $stylesheetPath = Join-Path (Split-Path -Parent $PalettePath) "styles.css"
    if (Test-Path -LiteralPath $stylesheetPath) {
        [System.IO.File]::SetLastWriteTime($stylesheetPath, [DateTime]::Now)
    }
}

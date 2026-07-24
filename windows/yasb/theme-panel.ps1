param(
    [string]$PalettePath = (Join-Path $PSScriptRoot "palette.css"),
    [string]$ApplyPreset,
    [ValidateSet("preset", "wallpaper")]
    [string]$AccentSource,
    [switch]$RestoreBackup,
    [switch]$NoReload,
    [switch]$ValidateOnly
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName PresentationCore
Add-Type -AssemblyName WindowsBase
Add-Type -TypeDefinition @'
using System;
using System.Runtime.InteropServices;

public static class ThemePanelNative {
    [DllImport("kernel32.dll")]
    private static extern IntPtr GetConsoleWindow();

    [DllImport("user32.dll")]
    private static extern bool ShowWindow(IntPtr hwnd, int command);

    [DllImport("dwmapi.dll")]
    private static extern int DwmSetWindowAttribute(IntPtr hwnd, int attribute, ref int value, int size);

    public static void HideConsole() {
        IntPtr hwnd = GetConsoleWindow();
        if (hwnd != IntPtr.Zero) {
            ShowWindow(hwnd, 0);
        }
    }

    public static void EnableDarkTitleBar(IntPtr hwnd) {
        int enabled = 1;
        if (DwmSetWindowAttribute(hwnd, 20, ref enabled, sizeof(int)) != 0) {
            DwmSetWindowAttribute(hwnd, 19, ref enabled, sizeof(int));
        }
    }
}
'@

$presets = [ordered]@{
    "Fluent Graphite" = [ordered]@{
        Description = "Recommended - neutral Windows surface with a crisp cyan accent"
        Background = "#181A1B"; Background2 = "#25282A"; MutedBG = "#111314"; Border = "#383D40"
        Text = "#F0F3F4"; Subtext = "#A8B0B4"; Accent = "#60CDFF"; AccentText = "#062633"
    }
    "Cold Slate" = [ordered]@{
        Description = "Cool counterweight to vivid red wallpapers"
        Background = "#15181E"; Background2 = "#1F242D"; MutedBG = "#0E1014"; Border = "#2A303C"
        Text = "#DDE2EA"; Subtext = "#8B93A3"; Accent = "#7AA2F7"; AccentText = "#15181E"
    }
    "Crimson Ash" = [ordered]@{
        Description = "Neutral charcoal with a restrained wallpaper echo"
        Background = "#1A1A1E"; Background2 = "#26262B"; MutedBG = "#121214"; Border = "#303036"
        Text = "#E9E7E4"; Subtext = "#A09DA5"; Accent = "#E34F5F"; AccentText = "#1A1A1E"
    }
    "Everforest" = [ordered]@{
        Description = "Muted green contrast for long sessions"
        Background = "#1E2326"; Background2 = "#2D353B"; MutedBG = "#171B1D"; Border = "#475258"
        Text = "#D3C6AA"; Subtext = "#9DA9A0"; Accent = "#A7C080"; AccentText = "#172018"
    }
    "Ink Mono" = [ordered]@{
        Description = "Near-black and achromatic - lets the wallpaper lead"
        Background = "#0F0F11"; Background2 = "#1C1C20"; MutedBG = "#08080A"; Border = "#27272C"
        Text = "#E4E4E6"; Subtext = "#8E8E95"; Accent = "#C9C9CF"; AccentText = "#0F0F11"
    }
}

$settingsPath = Join-Path (Split-Path -Parent $PalettePath) "theme-settings.json"
$accentScriptPath = Join-Path (Split-Path -Parent $PalettePath) "wallpaper-accent.ps1"

function Get-ThemeSettings {
    if (-not (Test-Path -LiteralPath $settingsPath -PathType Leaf)) {
        return [pscustomobject]@{ activePalette = "Custom"; accentSource = "preset" }
    }
    return [System.IO.File]::ReadAllText($settingsPath) | ConvertFrom-Json
}

function Write-ThemeSettings {
    param([string]$PaletteName, [string]$Source)

    $settings = [ordered]@{ activePalette = $PaletteName; accentSource = $Source }
    $json = $settings | ConvertTo-Json
    [System.IO.File]::WriteAllText($settingsPath, $json + [Environment]::NewLine, [System.Text.UTF8Encoding]::new($false))
}

function Get-EffectivePalette {
    param([System.Collections.IDictionary]$Palette, [string]$Source)

    $effective = [ordered]@{}
    foreach ($key in $Palette.Keys) { $effective[$key] = $Palette[$key] }
    if ($Source -ne "wallpaper") { return $effective }
    if (-not (Test-Path -LiteralPath $accentScriptPath -PathType Leaf)) {
        throw "Wallpaper accent script does not exist: $accentScriptPath"
    }
    $wallpaper = (Get-ItemProperty -LiteralPath "HKCU:\Control Panel\Desktop" -Name WallPaper).WallPaper
    $derived = & $accentScriptPath -ImagePath $wallpaper -PalettePath $PalettePath -BackgroundOverride $Palette.Background -TextOverride $Palette.Text -Preview
    $effective.Accent = $derived.Accent
    $effective.AccentText = $derived.AccentText
    return $effective
}

function ConvertTo-RgbaColor {
    param([string]$Color, [string]$Alpha)

    if ($Color -notmatch '^#[0-9A-Fa-f]{6}$') {
        throw "Invalid RGB color: $Color"
    }
    $red = [Convert]::ToInt32($Color.Substring(1, 2), 16)
    $green = [Convert]::ToInt32($Color.Substring(3, 2), 16)
    $blue = [Convert]::ToInt32($Color.Substring(5, 2), 16)
    return "rgba($red, $green, $blue, $Alpha)"
}

function ConvertTo-PaletteCss {
    param([string]$Name, [System.Collections.IDictionary]$Palette)

    $barSurface = ConvertTo-RgbaColor -Color $Palette.Background -Alpha "0.80"
    $barSurface2 = ConvertTo-RgbaColor -Color $Palette.Background2 -Alpha "0.82"
    return @"
/* YASB palette: $Name. Managed by theme-panel.ps1. */
:root {
	--background: $($Palette.Background);
	--background2: $($Palette.Background2);
	--bar-surface: $barSurface;
	--bar-surface2: $barSurface2;
	--mutedBG: $($Palette.MutedBG);
	--border: $($Palette.Border);
	--text: $($Palette.Text);
	--subtext: $($Palette.Subtext);
	--accent: $($Palette.Accent);
	--accentText: $($Palette.AccentText);
	--hover: $($Palette.Background2);
	--yasb-icon-fg: $($Palette.Text);
	--yasb-accent: $($Palette.Accent);
}
"@
}

function Write-Palette {
    param([string]$Content)

    $directory = Split-Path -Parent $PalettePath
    if (-not (Test-Path -LiteralPath $directory)) {
        throw "Palette directory does not exist: $directory"
    }

    [System.IO.File]::WriteAllText($PalettePath, $Content, [System.Text.UTF8Encoding]::new($false))
    if (-not $NoReload) {
        $stylesheetPath = Join-Path (Split-Path -Parent $PalettePath) "styles.css"
        if (Test-Path -LiteralPath $stylesheetPath) {
            [System.IO.File]::SetLastWriteTime($stylesheetPath, [DateTime]::Now)
        } else {
            throw "Stylesheet does not exist: $stylesheetPath"
        }
    }
}

function Get-Brush {
    param([string]$Color)
    return [System.Windows.Media.BrushConverter]::new().ConvertFromString($Color)
}

function Get-PaletteFromCss {
    param([string]$Content)

    $palette = [ordered]@{}
    $mapping = [ordered]@{
        Background = "background"; Background2 = "background2"; MutedBG = "mutedBG"; Border = "border"
        Text = "text"; Subtext = "subtext"; Accent = "accent"; AccentText = "accentText"
    }
    foreach ($entry in $mapping.GetEnumerator()) {
        if ($Content -notmatch "--$($entry.Value):\s*(#[0-9A-Fa-f]{6})\s*;") {
            return $null
        }
        $palette[$entry.Key] = $matches[1]
    }
    return $palette
}

$xaml = @'
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="YASB Palette Lab" Width="920" Height="800" MinWidth="760" MinHeight="650"
        WindowStartupLocation="CenterScreen" Background="#111315" Foreground="#F0F3F4"
        FontFamily="Segoe UI Variable Text" ResizeMode="CanResizeWithGrip" Topmost="True">
    <Window.Resources>
        <Style TargetType="Button">
            <Setter Property="Background" Value="#25282A"/>
            <Setter Property="Foreground" Value="#F0F3F4"/>
            <Setter Property="BorderBrush" Value="#383D40"/>
            <Setter Property="BorderThickness" Value="1"/>
            <Setter Property="Padding" Value="14,8"/>
            <Setter Property="Cursor" Value="Hand"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="Button">
                        <Border x:Name="Shell" Background="{TemplateBinding Background}"
                                BorderBrush="{TemplateBinding BorderBrush}" BorderThickness="{TemplateBinding BorderThickness}"
                                CornerRadius="6" Padding="{TemplateBinding Padding}">
                            <ContentPresenter HorizontalAlignment="{TemplateBinding HorizontalContentAlignment}"
                                              VerticalAlignment="{TemplateBinding VerticalContentAlignment}"/>
                        </Border>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsMouseOver" Value="True">
                                <Setter TargetName="Shell" Property="Background" Value="#303438"/>
                            </Trigger>
                            <Trigger Property="IsPressed" Value="True">
                                <Setter TargetName="Shell" Property="Opacity" Value="0.78"/>
                            </Trigger>
                            <Trigger Property="IsEnabled" Value="False">
                                <Setter TargetName="Shell" Property="Opacity" Value="0.45"/>
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>
    </Window.Resources>
    <Grid Margin="24">
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="*"/>
            <RowDefinition Height="Auto"/>
        </Grid.RowDefinitions>

        <StackPanel Grid.Row="0" Margin="0,0,0,18">
            <TextBlock Text="YASB Palette Lab" FontSize="25" FontWeight="SemiBold"/>
            <TextBlock Text="Choose colors without replacing your widgets, spacing, or behavior."
                       Foreground="#A8B0B4" FontSize="13" Margin="0,5,0,0"/>
        </StackPanel>

        <Border Grid.Row="1" x:Name="PreviewBand" Background="#181A1B" BorderBrush="#383D40"
                BorderThickness="1" CornerRadius="8" Padding="12" Margin="0,0,0,18">
            <Grid Height="44">
                <StackPanel Orientation="Horizontal" HorizontalAlignment="Left" VerticalAlignment="Center">
                    <Border x:Name="ProfilePill" Width="30" Height="30" CornerRadius="15" Background="#25282A" Margin="0,0,7,0">
                        <TextBlock x:Name="ProfileDot" Text="●" HorizontalAlignment="Center" VerticalAlignment="Center" Foreground="#60CDFF" FontSize="12"/>
                    </Border>
                    <Border x:Name="DesktopPill" Height="30" CornerRadius="7" Background="#25282A" Padding="12,0" Margin="0,0,7,0">
                        <TextBlock x:Name="DesktopText" Text="•  ▬  •" VerticalAlignment="Center" Foreground="#F0F3F4"/>
                    </Border>
                    <Border x:Name="WindowPill" Height="30" CornerRadius="7" Background="#25282A" Padding="12,0">
                        <TextBlock x:Name="WindowText" Text="Explorer" VerticalAlignment="Center" Foreground="#F0F3F4"/>
                    </Border>
                </StackPanel>
                <Border x:Name="ClockPill" Height="30" CornerRadius="7" Background="#60CDFF"
                        Padding="14,0" HorizontalAlignment="Center" VerticalAlignment="Center">
                    <TextBlock x:Name="ClockText" Text="Sat, 11 Jul 16:42" VerticalAlignment="Center" Foreground="#062633"/>
                </Border>
                <StackPanel Orientation="Horizontal" HorizontalAlignment="Right" VerticalAlignment="Center">
                    <Border x:Name="AudioPill" Height="30" CornerRadius="7" Background="#25282A" Padding="11,0" Margin="0,0,7,0">
                        <TextBlock x:Name="AudioText" Text="CAVA" VerticalAlignment="Center" Foreground="#F0F3F4"/>
                    </Border>
                    <Border x:Name="ToolsPill" Height="30" CornerRadius="7" Background="#25282A" Padding="12,0">
                        <TextBlock x:Name="ToolsText" Text="•••  ↓12.4 ↑1.2  CPU RAM" VerticalAlignment="Center" Foreground="#F0F3F4"/>
                    </Border>
                </StackPanel>
            </Grid>
        </Border>

        <Border Grid.Row="2" Background="#181A1B" BorderBrush="#383D40" BorderThickness="1"
                CornerRadius="8" Padding="14,10" Margin="0,0,0,18">
            <Grid>
                <Grid.ColumnDefinitions>
                    <ColumnDefinition Width="*"/>
                    <ColumnDefinition Width="Auto"/>
                </Grid.ColumnDefinitions>
                <StackPanel>
                    <CheckBox x:Name="WallpaperAccentToggle" Content="Derive accent from the active wallpaper"
                              Foreground="#F0F3F4" FontWeight="SemiBold" Cursor="Hand"/>
                    <TextBlock x:Name="AccentSourceHint" Text="The base palette stays intact; only active and selected states change."
                               Foreground="#A8B0B4" FontSize="12" Margin="20,4,0,0"/>
                </StackPanel>
                <StackPanel Grid.Column="1" Orientation="Horizontal" VerticalAlignment="Center">
                    <Border x:Name="AccentSwatch" Width="22" Height="22" CornerRadius="4" Background="#60CDFF"
                            BorderBrush="#50555A" BorderThickness="1" Margin="0,0,8,0"/>
                    <TextBlock x:Name="AccentValue" Text="#60CDFF" Foreground="#A8B0B4" VerticalAlignment="Center"/>
                </StackPanel>
            </Grid>
        </Border>

        <ScrollViewer Grid.Row="3" VerticalScrollBarVisibility="Auto" HorizontalScrollBarVisibility="Disabled">
            <UniformGrid x:Name="PaletteGrid" Columns="2" Margin="-6"/>
        </ScrollViewer>

        <Grid Grid.Row="4" Margin="0,18,0,0">
            <Grid.ColumnDefinitions>
                <ColumnDefinition Width="*"/>
                <ColumnDefinition Width="Auto"/>
            </Grid.ColumnDefinitions>
            <TextBlock x:Name="StatusText" Text="Select a palette to preview it." Foreground="#A8B0B4"
                       VerticalAlignment="Center" TextTrimming="CharacterEllipsis" Margin="0,0,18,0"/>
            <StackPanel Grid.Column="1" Orientation="Horizontal">
                <Button x:Name="CommunityButton" Content="Community themes" Margin="0,0,8,0"/>
                <Button x:Name="RestoreButton" Content="Undo session" IsEnabled="False" Margin="0,0,8,0"/>
                <Button x:Name="ApplyButton" Content="Apply to YASB" Background="#60CDFF" Foreground="#062633"
                        BorderBrush="#60CDFF" FontWeight="SemiBold" IsEnabled="False" Margin="0,0,8,0"/>
                <Button x:Name="CloseButton" Content="Close"/>
            </StackPanel>
        </Grid>
    </Grid>
</Window>
'@

foreach ($entry in $presets.GetEnumerator()) {
    foreach ($key in @("Background", "Background2", "MutedBG", "Border", "Text", "Subtext", "Accent", "AccentText")) {
        if ($entry.Value[$key] -notmatch '^#[0-9A-Fa-f]{6}$') {
            throw "Invalid color in $($entry.Key): $key"
        }
    }
}

$window = [Windows.Markup.XamlReader]::Parse($xaml)
if ($ValidateOnly) {
    $sampleCss = ConvertTo-PaletteCss -Name "Validation" -Palette $presets["Cold Slate"]
    if ($sampleCss -notmatch '--bar-surface:\s*rgba\(21, 24, 30, 0\.80\);') {
        throw "Palette panel did not generate the expected glass surface."
    }
    "Palette panel valid: $($presets.Count) presets"
    exit 0
}

if ($ApplyPreset) {
    $match = $presets.Keys | Where-Object { $_ -ieq $ApplyPreset } | Select-Object -First 1
    if (-not $match) {
        throw "Unknown preset '$ApplyPreset'. Available: $($presets.Keys -join ', ')"
    }
    $source = if ($AccentSource) { $AccentSource } else { (Get-ThemeSettings).accentSource }
    $effective = Get-EffectivePalette -Palette $presets[$match] -Source $source
    Write-Palette (ConvertTo-PaletteCss -Name $match -Palette $effective)
    Write-ThemeSettings -PaletteName $match -Source $source
    "Applied palette: $match ($source accent)"
    exit 0
}

if ($RestoreBackup) {
    $backupPath = "$PalettePath.bak"
    if (-not (Test-Path -LiteralPath $backupPath)) {
        throw "Palette backup does not exist: $backupPath"
    }
    Write-Palette ([System.IO.File]::ReadAllText($backupPath))
    "Restored palette backup"
    exit 0
}

if (-not (Test-Path -LiteralPath $PalettePath)) {
    throw "Palette file does not exist: $PalettePath"
}

[ThemePanelNative]::HideConsole()

$launchCss = [System.IO.File]::ReadAllText($PalettePath)
$launchSettings = if (Test-Path -LiteralPath $settingsPath) { [System.IO.File]::ReadAllText($settingsPath) } else { $null }
$currentSettings = Get-ThemeSettings
$backupPath = "$PalettePath.bak"
$backupCreated = $false
$selectedName = $null
$cards = @{}

$paletteGrid = $window.FindName("PaletteGrid")
$previewBand = $window.FindName("PreviewBand")
$profilePill = $window.FindName("ProfilePill")
$desktopPill = $window.FindName("DesktopPill")
$windowPill = $window.FindName("WindowPill")
$clockPill = $window.FindName("ClockPill")
$clockText = $window.FindName("ClockText")
$profileDot = $window.FindName("ProfileDot")
$desktopText = $window.FindName("DesktopText")
$windowText = $window.FindName("WindowText")
$audioText = $window.FindName("AudioText")
$toolsText = $window.FindName("ToolsText")
$audioPill = $window.FindName("AudioPill")
$toolsPill = $window.FindName("ToolsPill")
$wallpaperAccentToggle = $window.FindName("WallpaperAccentToggle")
$accentSourceHint = $window.FindName("AccentSourceHint")
$accentSwatch = $window.FindName("AccentSwatch")
$accentValue = $window.FindName("AccentValue")
$statusText = $window.FindName("StatusText")
$applyButton = $window.FindName("ApplyButton")
$restoreButton = $window.FindName("RestoreButton")
$communityButton = $window.FindName("CommunityButton")
$closeButton = $window.FindName("CloseButton")
$wallpaperAccentToggle.IsChecked = $currentSettings.accentSource -eq "wallpaper"
$accentSourceHint.Text = if ($wallpaperAccentToggle.IsChecked) {
    "The base palette stays intact; active and selected states follow the wallpaper."
} else {
    "The selected preset supplies both the base palette and its accent."
}

function Show-Preview {
    param([System.Collections.IDictionary]$Palette)

    $previewBand.Background = Get-Brush $Palette.Background
    $previewBand.BorderBrush = Get-Brush $Palette.Border
    foreach ($pill in @($profilePill, $desktopPill, $windowPill, $audioPill, $toolsPill)) {
        $pill.Background = Get-Brush $Palette.Background2
    }
    $clockPill.Background = Get-Brush $Palette.Accent
    $clockText.Foreground = Get-Brush $Palette.AccentText
    $profileDot.Foreground = Get-Brush $Palette.Accent
    $accentSwatch.Background = Get-Brush $Palette.Accent
    $accentValue.Text = $Palette.Accent
    foreach ($label in @($desktopText, $windowText, $audioText, $toolsText)) {
        $label.Foreground = Get-Brush $Palette.Text
    }
}

foreach ($entry in $presets.GetEnumerator()) {
    $name = $entry.Key
    $palette = $entry.Value
    $card = [System.Windows.Controls.Button]::new()
    $card.Tag = $name
    $card.Margin = [System.Windows.Thickness]::new(6)
    $card.Padding = [System.Windows.Thickness]::new(14)
    $card.HorizontalContentAlignment = "Stretch"
    $card.VerticalContentAlignment = "Stretch"

    $content = [System.Windows.Controls.StackPanel]::new()
    $title = [System.Windows.Controls.TextBlock]::new()
    $title.Text = $name
    $title.FontSize = 16
    $title.FontWeight = "SemiBold"
    $content.Children.Add($title) | Out-Null

    $description = [System.Windows.Controls.TextBlock]::new()
    $description.Text = $palette.Description
    $description.Foreground = Get-Brush "#A8B0B4"
    $description.Margin = [System.Windows.Thickness]::new(0, 4, 0, 12)
    $description.TextWrapping = "Wrap"
    $content.Children.Add($description) | Out-Null

    $miniBar = [System.Windows.Controls.Border]::new()
    $miniBar.Height = 30
    $miniBar.Background = Get-Brush $palette.Background
    $miniBar.BorderBrush = Get-Brush $palette.Border
    $miniBar.BorderThickness = [System.Windows.Thickness]::new(1)
    $miniBar.CornerRadius = [System.Windows.CornerRadius]::new(6)
    $miniBar.Margin = [System.Windows.Thickness]::new(0, 0, 0, 12)
    $miniRow = [System.Windows.Controls.StackPanel]::new()
    $miniRow.Orientation = "Horizontal"
    $miniRow.HorizontalAlignment = "Center"
    $miniRow.VerticalAlignment = "Center"
    foreach ($width in @(28, 56, 38, 72)) {
        $pill = [System.Windows.Controls.Border]::new()
        $pill.Width = $width
        $pill.Height = 16
        $pill.CornerRadius = [System.Windows.CornerRadius]::new(4)
        $pill.Background = Get-Brush $palette.Background2
        $pill.Margin = [System.Windows.Thickness]::new(3, 0, 3, 0)
        $miniRow.Children.Add($pill) | Out-Null
    }
    $miniRow.Children[2].Background = Get-Brush $palette.Accent
    $miniBar.Child = $miniRow
    $content.Children.Add($miniBar) | Out-Null

    $swatches = [System.Windows.Controls.StackPanel]::new()
    $swatches.Orientation = "Horizontal"
    foreach ($key in @("Background", "Background2", "MutedBG", "Border", "Text", "Subtext", "Accent", "AccentText")) {
        $swatch = [System.Windows.Controls.Border]::new()
        $swatch.Width = 30
        $swatch.Height = 18
        $swatch.Background = Get-Brush $palette[$key]
        $swatch.BorderBrush = Get-Brush "#50555A"
        $swatch.BorderThickness = [System.Windows.Thickness]::new(1)
        $swatch.CornerRadius = [System.Windows.CornerRadius]::new(3)
        $swatch.Margin = [System.Windows.Thickness]::new(0, 0, 6, 0)
        $swatches.Children.Add($swatch) | Out-Null
    }
    $content.Children.Add($swatches) | Out-Null
    $card.Content = $content

    $card.Add_Click({
        param($sender, $eventArgs)
        $script:selectedName = [string]$sender.Tag
        foreach ($item in $script:cards.Values) {
            $item.BorderBrush = Get-Brush "#383D40"
            $item.BorderThickness = [System.Windows.Thickness]::new(1)
        }
        $source = if ($script:wallpaperAccentToggle.IsChecked) { "wallpaper" } else { "preset" }
        $effective = Get-EffectivePalette -Palette $script:presets[$script:selectedName] -Source $source
        $sender.BorderBrush = Get-Brush $effective.Accent
        $sender.BorderThickness = [System.Windows.Thickness]::new(2)
        Show-Preview $effective
        $script:applyButton.IsEnabled = $true
        $script:statusText.Text = "$script:selectedName selected with a $source accent."
    })

    $cards[$name] = $card
    $paletteGrid.Children.Add($card) | Out-Null
}

$wallpaperAccentToggle.Add_Checked({
    $script:accentSourceHint.Text = "The base palette stays intact; active and selected states follow the wallpaper."
    if ($script:selectedName) {
        Show-Preview (Get-EffectivePalette -Palette $script:presets[$script:selectedName] -Source "wallpaper")
        $script:statusText.Text = "Wallpaper accent previewed. Apply to persist it."
    } else {
        $script:statusText.Text = "Select a base palette before applying the wallpaper accent."
    }
})

$wallpaperAccentToggle.Add_Unchecked({
    $script:accentSourceHint.Text = "The selected preset supplies both the base palette and its accent."
    if ($script:selectedName) {
        Show-Preview $script:presets[$script:selectedName]
        $script:statusText.Text = "Preset accent previewed. Apply to persist it."
    } else {
        $script:statusText.Text = "Select a base palette before changing the accent source."
    }
})

$applyButton.Add_Click({
    if (-not $script:selectedName) { return }
    if (-not $script:backupCreated) {
        [System.IO.File]::WriteAllText($script:backupPath, $script:launchCss, [System.Text.UTF8Encoding]::new($false))
        $script:backupCreated = $true
        $script:restoreButton.IsEnabled = $true
    }
    $source = if ($script:wallpaperAccentToggle.IsChecked) { "wallpaper" } else { "preset" }
    $effective = Get-EffectivePalette -Palette $script:presets[$script:selectedName] -Source $source
    Write-Palette (ConvertTo-PaletteCss -Name $script:selectedName -Palette $effective)
    Write-ThemeSettings -PaletteName $script:selectedName -Source $source
    $script:statusText.Text = "$script:selectedName applied with a $source accent. Undo restores the launch palette."
})

$restoreButton.Add_Click({
    if (-not $script:backupCreated) { return }
    Write-Palette $script:launchCss
    if ($null -ne $script:launchSettings) {
        [System.IO.File]::WriteAllText($script:settingsPath, $script:launchSettings, [System.Text.UTF8Encoding]::new($false))
        $restoredSettings = $script:launchSettings | ConvertFrom-Json
        $script:wallpaperAccentToggle.IsChecked = $restoredSettings.accentSource -eq "wallpaper"
    }
    $script:statusText.Text = "Launch palette restored."
    $script:restoreButton.IsEnabled = $false
    $script:backupCreated = $false
})

$communityButton.Add_Click({
    $themesManager = "C:\Program Files\YASB\yasb_themes.exe"
    if (Test-Path -LiteralPath $themesManager) {
        Start-Process -FilePath $themesManager
        $script:statusText.Text = "Opened YASB Themes Manager. Installing a theme can replace the full config."
    } else {
        $script:statusText.Text = "YASB Themes Manager was not found."
    }
})

$closeButton.Add_Click({ $script:window.Close() })
$window.Add_SourceInitialized({
    $handle = [System.Windows.Interop.WindowInteropHelper]::new($script:window).Handle
    [ThemePanelNative]::EnableDarkTitleBar($handle)
})

$launchPalette = Get-PaletteFromCss $launchCss
if ($launchPalette) {
    Show-Preview $launchPalette
    $statusText.Text = "Showing the palette active when this panel opened."
}
$window.ShowDialog() | Out-Null

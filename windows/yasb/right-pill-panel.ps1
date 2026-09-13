param([string]$RenderPreview, [switch]$SelfTest, [switch]$ApplySaved)
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase
$cssPath = Join-Path $PSScriptRoot 'right-pill.css'
$settingsPath = Join-Path $PSScriptRoot 'right-pill.json'
$script:committedCss = [IO.File]::ReadAllText($cssPath)
$script:previewActive = $false
$palette = [IO.File]::ReadAllText((Join-Path $PSScriptRoot 'palette.css'))
$colors = @{}
foreach ($m in [regex]::Matches($palette,'--([\w-]+):\s*(#[\da-fA-F]{6})')) { $colors[$m.Groups[1].Value] = $m.Groups[2].Value }
$definitions = @(
    @('traffic-widget','Download',0xf063,'252 KB/s',14,76,5,0,500),
    @('cpu-widget','CPU',0xf4bc,'8%',13,0,5,4,600),
    @('memory-widget','Memory',0xefc5,'84%',13,0,5,4,600),
    @('wallpapers-widget','Wallpaper',0xf03e,'',13,0,5,0,600),
    @('taskbar-toggle','Taskbar',0xf2d0,'',13,0,5,0,600),
    @('brightness-widget','Brightness',0xf185,'',15,0,5,0,600),
    @('volume-widget','Volume',0xf028,'',13,0,5,0,600),
    @('battery-widget','Battery',0xf240,'98%',13,0,5,4,600)
)
$icons = [ordered]@{'Native'='';'Arrow down'=[string][char]0xf063;'Chevron down'=[string][char]0xeab4;'CPU'=[string][char]0xf4bc;'Memory'=[string][char]0xefc5;'Image'=[string][char]0xf03e;'Window'=[string][char]0xf2d0;'Sun'=[string][char]0xf185;'Speaker'=[string][char]0xf028;'Battery'=[string][char]0xf240}
[xml]$xaml = @'
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
 Title="YASB right pill" Width="1010" Height="630" MinWidth="1010" MinHeight="630" WindowStartupLocation="CenterScreen"
 Background="#15181E" Foreground="#DDE2EA" FontFamily="Segoe UI">
 <Window.Resources>
  <Style TargetType="Button"><Setter Property="Padding" Value="14,7"/><Setter Property="Margin" Value="6,0,0,0"/></Style>
  <Style TargetType="TextBox"><Setter Property="Background" Value="#1F242D"/><Setter Property="Foreground" Value="#DDE2EA"/><Setter Property="BorderBrush" Value="#3A404C"/><Setter Property="Padding" Value="5"/></Style>
 </Window.Resources>
 <Grid x:Name="Root" Margin="20" Background="#15181E">
  <Grid.RowDefinitions><RowDefinition Height="Auto"/><RowDefinition Height="76"/><RowDefinition Height="Auto"/><RowDefinition Height="*"/><RowDefinition Height="Auto"/></Grid.RowDefinitions>
  <TextBlock Text="Right pill" FontSize="20" FontWeight="SemiBold"/>
  <ScrollViewer Grid.Row="1" HorizontalScrollBarVisibility="Auto" VerticalScrollBarVisibility="Disabled" VerticalAlignment="Center">
   <Border x:Name="Pill" HorizontalAlignment="Left" Background="#1F242D" CornerRadius="8" Padding="4,0" Height="34">
    <StackPanel x:Name="PreviewRow" Orientation="Horizontal" VerticalAlignment="Center"/>
   </Border>
  </ScrollViewer>
  <StackPanel Grid.Row="2" Orientation="Horizontal" Margin="0,0,0,20">
   <TextBlock Text="Opacity" VerticalAlignment="Center"/><Slider x:Name="Opacity" Minimum="30" Maximum="100" Value="80" Width="130" Margin="10,0,4,0"/><TextBlock x:Name="OpacityValue" Width="40" VerticalAlignment="Center"/>
   <TextBlock Text="Corners" VerticalAlignment="Center" Margin="20,0,8,0"/><TextBox x:Name="Radius" Text="8" Width="44"/>
   <TextBlock Text="Outer padding" VerticalAlignment="Center" Margin="20,0,8,0"/><TextBox x:Name="OuterPadding" Text="4" Width="44"/>
  </StackPanel>
  <ScrollViewer Grid.Row="3" VerticalScrollBarVisibility="Auto" HorizontalScrollBarVisibility="Disabled"><StackPanel x:Name="Rows"/></ScrollViewer>
  <DockPanel Grid.Row="4" Margin="0,16,0,0">
   <StackPanel DockPanel.Dock="Right" Orientation="Horizontal"><Button x:Name="Revert" Content="Revert"/><Button x:Name="Preview" Content="Preview on bar"/><Button x:Name="Apply" Content="Apply"/><Button x:Name="Close" Content="Close"/></StackPanel>
   <TextBlock x:Name="Status" VerticalAlignment="Center" TextWrapping="Wrap"/>
  </DockPanel>
 </Grid>
</Window>
'@
$window = [Windows.Markup.XamlReader]::Load([Xml.XmlNodeReader]::new($xaml))
$rows = $window.FindName('Rows')
$previewRow = $window.FindName('PreviewRow')
$pill = $window.FindName('Pill')
$status = $window.FindName('Status')
$opacity = $window.FindName('Opacity')
$radius = $window.FindName('Radius')
$outerPadding = $window.FindName('OuterPadding')
$script:controls = @()
$saved = if(Test-Path $settingsPath){Get-Content $settingsPath -Raw | ConvertFrom-Json}else{$null}
function New-RowGrid {
    $g = [Windows.Controls.Grid]::new()
    foreach($w in @(95,120,60,80,74,70,80,80,80)) {
        $col=[Windows.Controls.ColumnDefinition]::new(); $col.Width=$w; $g.ColumnDefinitions.Add($col)
    }
    $g.Margin='0,0,0,9'
    return $g
}
$header=New-RowGrid
$headings=@('Item','Icon','Glyph','Icon px','Text px','Width','Padding','Icon gap','Weight')
for($i=0;$i -lt $headings.Count;$i++){
    $t=[Windows.Controls.TextBlock]::new();$t.Text=$headings[$i];$t.Foreground='#8B93A3';[Windows.Controls.Grid]::SetColumn($t,$i);$header.Children.Add($t)|Out-Null
}
$rows.Children.Add($header)|Out-Null
foreach($d in $definitions){
    $g=New-RowGrid
    $title=[Windows.Controls.TextBlock]::new();$title.Text=$d[1];$title.VerticalAlignment='Center';$g.Children.Add($title)|Out-Null
    $choice=[Windows.Controls.ComboBox]::new();$choice.Margin='0,0,8,0'
    foreach($k in $icons.Keys){$choice.Items.Add($k)|Out-Null};$choice.SelectedIndex=0
    [Windows.Controls.Grid]::SetColumn($choice,1);$g.Children.Add($choice)|Out-Null
    $fields=@{}; $values=@('', $d[4],11,$d[5],$d[6],$d[7],$d[8]);$keys=@('glyph','iconSize','textSize','width','padding','gap','weight')
    for($i=0;$i -lt $keys.Count;$i++){
        $box=[Windows.Controls.TextBox]::new();$box.Text=[string]$values[$i];$box.Margin='0,0,8,0'
        $box.ToolTip=if($keys[$i] -eq 'width'){'0 = automatic'}elseif($keys[$i] -eq 'glyph'){'Custom glyph; leave empty for native icon'}else{$keys[$i]}
        [Windows.Controls.Grid]::SetColumn($box,$i+2);$g.Children.Add($box)|Out-Null;$fields[$keys[$i]]=$box
    }
    $c=@{id=$d[0];definition=$d;choice=$choice;fields=$fields}
    if($saved){$entry=$saved.items | Where-Object id -EQ $d[0];if($entry){foreach($k in $keys){$fields[$k].Text=[string]$entry.$k}}}
    $choice.Tag=$fields.glyph
    $choice.Add_SelectionChanged({ $this.Tag.Text=$icons[[string]$this.SelectedItem] })
    $script:controls += $c
    $rows.Children.Add($g)|Out-Null
}
if($saved){$opacity.Value=$saved.opacity;$radius.Text=[string]$saved.radius;$outerPadding.Text=[string]$saved.padding}
function Read-State {
    $items=@()
    foreach($c in $script:controls){
        $item=[ordered]@{id=$c.id;glyph=$c.fields.glyph.Text}
        foreach($k in @('iconSize','textSize','width','padding','gap','weight')){
            $number=0
            if(-not [int]::TryParse($c.fields[$k].Text,[ref]$number)){throw "$($c.definition[1]): $k must be a whole number."}
            $range=switch($k){iconSize{@(8,24)} textSize{@(8,18)} width{@(0,220)} weight{@(400,700)} default{@(0,20)}}
            if($number -lt $range[0] -or $number -gt $range[1]){throw "$($c.definition[1]): $k must be $($range[0]) to $($range[1])."}
            $item[$k]=$number
        }
        $items += [pscustomobject]$item
    }
    $r=0;$p=0
    if(-not [int]::TryParse($radius.Text,[ref]$r) -or $r -lt 0 -or $r -gt 18){throw 'Corners must be 0 to 18.'}
    if(-not [int]::TryParse($outerPadding.Text,[ref]$p) -or $p -lt 0 -or $p -gt 20){throw 'Outer padding must be 0 to 20.'}
    [pscustomobject]@{opacity=[int]$opacity.Value;radius=$r;padding=$p;items=$items}
}
function Update-Preview {
    try {
        $s=Read-State
        $null=Build-Css $s
        $previewRow.Children.Clear();$pill.CornerRadius=$s.radius;$pill.Padding=[Windows.Thickness]::new($s.padding,0,$s.padding,0)
        $pill.Background=[Windows.Media.BrushConverter]::new().ConvertFromString($colors.background)
        $pill.Background.Opacity=$s.opacity/100
        $window.FindName('OpacityValue').Text="$($s.opacity)%"
        foreach($item in $s.items){
            $d=($script:controls | Where-Object id -EQ $item.id).definition
            $stack=[Windows.Controls.StackPanel]::new();$stack.Orientation='Horizontal';$stack.Margin=[Windows.Thickness]::new($item.padding,0,$item.padding,0);$stack.ClipToBounds=$true
            if($item.width -gt 0){$stack.Width=$item.width}
            $icon=[Windows.Controls.TextBlock]::new();$icon.Text=if($item.glyph){$item.glyph}else{[string][char]$d[2]}
            $icon.FontFamily='FiraCode Nerd Font Propo';$icon.FontSize=$item.iconSize;$icon.Foreground=$colors.text;$icon.Margin=[Windows.Thickness]::new(0,0,$item.gap,0);$icon.VerticalAlignment='Center'
            if($item.glyph -or $item.id -eq 'brightness-widget'){
                $glyph=if($item.glyph){$item.glyph}else{[string][char]0x2600}
                $key="fit2|$glyph|$($item.iconSize)|$($colors.text)"
                $hash=[Convert]::ToHexString([Security.Cryptography.SHA256]::HashData([Text.Encoding]::UTF8.GetBytes($key))).Substring(0,16)
                $icon=[Windows.Controls.Image]::new();$icon.Source=Join-Path $PSScriptRoot "assets\right-icon-$hash.png";$icon.Width=$item.iconSize;$icon.Height=$item.iconSize;$icon.Margin=[Windows.Thickness]::new(0,0,$item.gap,0);$icon.VerticalAlignment='Center'
            }
            $stack.Children.Add($icon)|Out-Null
            $label=[Windows.Controls.TextBlock]::new();$label.Text=$d[3];$label.FontSize=$item.textSize;$label.FontWeight=[Windows.FontWeight]::FromOpenTypeWeight($item.weight);$label.VerticalAlignment='Center'
            $stack.Children.Add($label)|Out-Null;$previewRow.Children.Add($stack)|Out-Null
        }
        $status.Text=''
    }catch{$status.Text=$_.Exception.Message}
}
function Build-Css($s) {
    $a=($s.opacity/100).ToString('0.00',[Globalization.CultureInfo]::InvariantCulture)
    $css="/* Right pill editor */`n.yasb-bar .system-status {background-color:rgba(var(--background-rgb),$a);border-radius:$($s.radius)px;padding:0 $($s.padding)px;}`n"
    foreach($i in $s.items){
        $sel=".yasb-bar .system-status .widget.$($i.id)"
        $max=if($i.width -eq 0){16777215}else{$i.width}
        $css+="$sel {padding:0 $($i.padding)px;min-width:$($i.width)px;max-width:${max}px;}`n"
        $css+="$sel .label {font-size:$($i.textSize)px;font-weight:$($i.weight);}`n"
        $css+="$sel .icon {font-size:$($i.iconSize)px;min-width:$($i.iconSize)px;max-width:16777215px;min-height:20px;max-height:20px;margin:0;padding:0 $($i.gap)px 0 0;qproperty-alignment:AlignCenter;}`n"
        if($i.glyph -or $i.id -eq 'brightness-widget'){
            $glyph=if($i.glyph){$i.glyph}else{[string][char]0x2600}
            $key="fit2|$glyph|$($i.iconSize)|$($colors.text)"
            $hash=[Convert]::ToHexString([Security.Cryptography.SHA256]::HashData([Text.Encoding]::UTF8.GetBytes($key))).Substring(0,16)
            $filename="right-icon-$hash.png";$path=Join-Path $PSScriptRoot "assets\$filename"
            if(-not (Test-Path $path)){
                $size=$i.iconSize
                $visual=[Windows.Media.DrawingVisual]::new();$dc=$visual.RenderOpen()
                if(-not $i.glyph -and $i.id -eq 'brightness-widget'){
                    $brush=[Windows.Media.BrushConverter]::new().ConvertFromString($colors.text)
                    $dc.DrawEllipse($brush,$null,[Windows.Point]::new($size/2,$size/2),$size*0.19,$size*0.19)
                    $pen=[Windows.Media.Pen]::new($brush,1)
                    for($j=0;$j -lt 8;$j++){$angle=$j*[Math]::PI/4;$x=[Math]::Cos($angle);$y=[Math]::Sin($angle);$dc.DrawLine($pen,[Windows.Point]::new($size/2+$x*$size*0.33,$size/2+$y*$size*0.33),[Windows.Point]::new($size/2+$x*$size*0.46,$size/2+$y*$size*0.46))}
                }else{
                    $text=[Windows.Media.FormattedText]::new($glyph,[Globalization.CultureInfo]::InvariantCulture,[Windows.FlowDirection]::LeftToRight,[Windows.Media.Typeface]::new('FiraCode Nerd Font Propo'),$size,[Windows.Media.BrushConverter]::new().ConvertFromString($colors.text),1.0)
                    $geometry=$text.BuildGeometry([Windows.Point]::new(0,0))
                    $bounds=$geometry.Bounds
                    if(-not $bounds.IsEmpty -and $bounds.Width -gt 0 -and $bounds.Height -gt 0){
                        $scale=($size-2)/[Math]::Max($bounds.Width,$bounds.Height)
                        $matrix=[Windows.Media.Matrix]::new($scale,0,0,$scale,($size-$bounds.Width*$scale)/2-$bounds.X*$scale,($size-$bounds.Height*$scale)/2-$bounds.Y*$scale)
                        $geometry.Transform=[Windows.Media.MatrixTransform]::new($matrix)
                        $dc.DrawGeometry([Windows.Media.BrushConverter]::new().ConvertFromString($colors.text),$null,$geometry)
                    }
                }
                $dc.Close();$bitmap=[Windows.Media.Imaging.RenderTargetBitmap]::new($size,$size,96,96,[Windows.Media.PixelFormats]::Pbgra32);$bitmap.Render($visual)
                $encoder=[Windows.Media.Imaging.PngBitmapEncoder]::new();$encoder.Frames.Add([Windows.Media.Imaging.BitmapFrame]::Create($bitmap));$stream=[IO.File]::Create($path);try{$encoder.Save($stream)}finally{$stream.Dispose()}
            }
            $css+="$sel .icon {font-size:1px;max-width:$($i.iconSize)px;color:transparent;background-image:url('assets/$filename');background-position:left center;background-repeat:no-repeat;}`n"
        }
    }
    return $css
}
function Write-Styles([string]$css) {
    [IO.File]::WriteAllText($cssPath,$css,[Text.UTF8Encoding]::new($false))
    [IO.File]::SetLastWriteTime((Join-Path $PSScriptRoot 'styles.css'),[DateTime]::Now)
}
foreach($c in $script:controls){foreach($box in $c.fields.Values){$box.Add_TextChanged({Update-Preview})}}
$opacity.Add_ValueChanged({Update-Preview});$radius.Add_TextChanged({Update-Preview});$outerPadding.Add_TextChanged({Update-Preview})
$window.FindName('Preview').Add_Click({try{$s=Read-State;Write-Styles (Build-Css $s);$script:previewActive=$true;$status.Text='Live preview'}catch{$status.Text=$_.Exception.Message}})
$window.FindName('Apply').Add_Click({try{$s=Read-State;$css=Build-Css $s;Write-Styles $css;$s|ConvertTo-Json -Depth 5|Set-Content $settingsPath;$script:committedCss=$css;$script:previewActive=$false;$status.Text='Applied'}catch{$status.Text=$_.Exception.Message}})
$window.FindName('Revert').Add_Click({Write-Styles $script:committedCss;$script:previewActive=$false;$status.Text='Live bar restored'})
$window.FindName('Close').Add_Click({$window.Close()})
$window.Add_Closing({if($script:previewActive){Write-Styles $script:committedCss}})
Update-Preview
if($ApplySaved){Write-Styles (Build-Css (Read-State)); return}
if($SelfTest){
    $s=Read-State;$css=Build-Css $s
    if($s.items.Count -ne 8 -or $css -notmatch 'battery-widget'){throw 'Incomplete editor state'}
    $original=$script:controls[0].fields.width.Text;$script:controls[0].fields.width.Text='invalid'
    $rejected=$false;try{Read-State|Out-Null}catch{$rejected=$true};$script:controls[0].fields.width.Text=$original
    if(-not $rejected){throw 'Invalid width accepted'}
    $baseline=[IO.File]::ReadAllText($cssPath)
    try {
        $window.FindName('Preview').RaiseEvent([Windows.RoutedEventArgs]::new([Windows.Controls.Button]::ClickEvent))
        if(-not $script:previewActive -or [IO.File]::ReadAllText($cssPath) -ne $css){throw 'Live preview write failed'}
        $window.FindName('Revert').RaiseEvent([Windows.RoutedEventArgs]::new([Windows.Controls.Button]::ClickEvent))
        if($script:previewActive -or [IO.File]::ReadAllText($cssPath) -ne $baseline){throw 'Revert failed'}
    }finally{Write-Styles $baseline;$script:previewActive=$false}
    'Eight widgets, stylesheet generation, invalid input, live preview write, and revert passed.'
}
if($RenderPreview){
    $root=$window.FindName('Root');$root.Measure([Windows.Size]::new(970,550));$root.Arrange([Windows.Rect]::new(0,0,970,550));$root.UpdateLayout()
    $bitmap=[Windows.Media.Imaging.RenderTargetBitmap]::new(970,550,96,96,[Windows.Media.PixelFormats]::Pbgra32);$bitmap.Render($root)
    $encoder=[Windows.Media.Imaging.PngBitmapEncoder]::new();$encoder.Frames.Add([Windows.Media.Imaging.BitmapFrame]::Create($bitmap));$stream=[IO.File]::Create($RenderPreview);try{$encoder.Save($stream)}finally{$stream.Dispose()}
}elseif(-not $SelfTest){[void]$window.ShowDialog()}

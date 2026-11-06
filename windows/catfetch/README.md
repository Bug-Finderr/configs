# Catfetch

Shows the original cat image beside system details in Windows Terminal.
Chafa turns the image into Sixel (a format for drawing images in a terminal),
then Fastfetch prints the image and system details together.

Use PowerShell 7 in a Windows Terminal version that supports Sixel images.

## Setup

Install the two tools:

```powershell
winget install --id Fastfetch-cli.Fastfetch --exact
winget install --id hpjansson.Chafa --exact
```

Open a new PowerShell tab in Windows Terminal, then run this from the repo root:

```powershell
.\windows\catfetch\catfetch.ps1
```

To make `catfetch` available by name, add a function to your PowerShell profile.
Replace the example folder with your clone's location:

```powershell
function catfetch {
    & 'D:\path\to\configs\windows\catfetch\catfetch.ps1'
}
```

## Files

- `cat.png`: original image, with the full scene preserved.
- `catfetch.jsonc`: colors, spacing, and system details to show.
- `catfetch.ps1`: finds the tools and runs the saved setup.
- `catfetch.sixel`: generated on first run, then reused. Git ignores this file.

The image is rebuilt when `cat.png`, the settings, or the script changes.
Set `logo.width` and `logo.height` in `catfetch.jsonc` to change both image size
and text spacing. Delete `catfetch.sixel` to rebuild it after changing the
terminal font or zoom level.

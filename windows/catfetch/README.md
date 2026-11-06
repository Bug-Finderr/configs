# Catfetch

Shows the original cat image beside system details in Windows Terminal.
Chafa turns the image into Sixel (a format for drawing images in a terminal),
then Fastfetch prints the image and system details together.

The image and layout were checked in Windows Terminal 1.24.11321.0 with
Fastfetch 2.64.2 and Chafa 1.18.2. Use PowerShell 7.

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

Replacing `cat.png` or editing the script causes the image to be rebuilt on the
next run. The saved image uses the tested 34-column by 17-row size. A different
terminal font or zoom level may need a new image size and matching layout values.

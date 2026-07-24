# Windows Configs

- [`claude/`](./claude/) - Claude Code settings, status line, and toast
  notifications.
- [`powershell/`](./powershell/) - shared profile, GitHub account routing, and
  scheduled maintenance.
- `windhawk/` - exports for the taskbar, Start menu, notification center, and
  window corners.
- `yasb/` - YASB bar, styles, theme helpers, and audio controls.

## YASB

Point YASB at the tracked directory:

```powershell
[Environment]::SetEnvironmentVariable(
    'YASB_CONFIG_HOME',
    'D:\Files\Dev\configs\windows\yasb',
    'User'
)
```

![Current YASB bar](./yasb/preview.png)

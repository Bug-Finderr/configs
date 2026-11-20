# Windows Configs

- [`catfetch/`](./catfetch/) - cat image and system details for Windows Terminal.
- [`claude/`](./claude/) - Claude Code settings, status line, and toast notifications.
- [`codex/`](./codex/) - Codex settings, global `AGENTS.md`, browser settings, and saved command approvals; the same files in `~/.codex` are symbolic links to these.
- [`gh-route/`](./gh-route/) - `gh.exe` shim that picks the GitHub account by folder.
- [`powershell/`](./powershell/) - shared profile and scheduled maintenance.
- [`windhawk/`](./windhawk/) - exports for the taskbar, Start menu, notification center, and window corners.
- [`yasb/`](./yasb/) - YASB bar, styles, theme helpers, and audio controls.

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

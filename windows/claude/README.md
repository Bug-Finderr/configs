# Claude Code

## Settings

`settings.json` is the tracked source for `~/.claude/settings.json`, which is a
symbolic link to it. Changes through either path update the same file.

## Status line

`statusline.ps1` renders the current path, Git state, model, context use, effort,
and subagent models. `settings.json` invokes the tracked script directly.

## Toast notifications

`~/.claude/settings.json` runs `notify.ps1` asynchronously for:

- approval, idle, or agent input requests;
- tool permission requests;
- completed responses.

Each toast shows its full working directory as bounded attribution text, so long
paths wrap or clip inside the notification rather than expanding it.
Headless CLI and Agent SDK sessions do not produce toasts.

Manual test:

```powershell
$payload = '{"hook_event_name":"PermissionRequest","tool_name":"Test","cwd":"D:\\Files\\Dev"}'
$payload | powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass `
    -File D:\Files\Dev\configs\windows\claude\notify.ps1
```

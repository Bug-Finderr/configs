# Claude Code

## Settings

`settings.json` is the tracked source for `~/.claude/settings.json`, which is a
symbolic link to it. Changes through either path update the same file.

## Status line

`statusline.ps1` renders the current path, Git state, model, context use and
effort. `settings.json` invokes the tracked script directly.

Subagent rows (label and model, same colors) come from the `mods/agent-rows` mod,
which `settings.json` loads through `CLAUDE_CODE_PLUGIN_DIRS`. Run its test with
`claude plugin test mods/agent-rows`.

## Skills

My own skills (`raise-pr`, `ui-pass`, `codex-usage`) live in `~/.claude/skills`
and are published at [Bug-Finderr/skills](https://github.com/Bug-Finderr/skills),
which also has install steps for other machines and agents.

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

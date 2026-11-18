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

`notify.ps1` shows a Windows toast for the interactive CLI's main thread only:

- `Stop`: the turn finished.
- `Notification` with `permission_prompt`: a permission prompt has waited a few
  seconds unanswered.

It exits without a toast unless `CLAUDE_CODE_ENTRYPOINT` is `cli`, which the
interactive CLI sets for its hooks. T3 Code (`t3-code`), `claude -p` (`sdk-cli`)
and other SDK hosts handle their own notifications. Subagent events carry
`agent_id` and are skipped too. `PermissionRequest` and `idle_prompt` are not
hooked: each repeats a toast the two above already give.

Manual test (Windows PowerShell 5.1):

```powershell
$env:CLAUDE_CODE_ENTRYPOINT = 'cli'
'{"hook_event_name":"Stop","cwd":"D:/Files/Dev"}' | powershell.exe -NoProfile `
    -NonInteractive -ExecutionPolicy Bypass -File D:\Files\Dev\configs\windows\claude\notify.ps1
```

// PreToolUse hook: block shell commands that call find, grep, sed or du and point Claude at fd, rg, sd or dust.
// One Bun process instead of bash + jq + sd + rg: each spawn costs ~0.1-0.3s on Windows and this runs before every command.
const input = JSON.parse(await Bun.stdin.text())
// Quoted text is blanked first so search patterns like "a|grep" don't count as commands.
const cmd = String(input.tool_input?.command ?? "")
  .replace(/'[^']*'/g, "''")
  .replace(/"[^"]*"/g, '""')
// A command word sits at the start of a line, after a separator or pipe, after $( or a backtick, or after xargs or fd -x/-X.
// [^\S\n] keeps whitespace matches on one line, as rg did.
const banned =
  /(^|[|;&(`\n]|\$\(|(xargs|[^\S\n]-[xX]|--exec(-batch)?)([^\S\n]+-\S+)*)[^\S\n]*(sudo[^\S\n]+)?(find|e?grep|fgrep|sed|du)([^\S\n]|$)/m
if (banned.test(cmd)) {
  console.error(
    "Blocked: use fd instead of find, rg instead of grep, sd instead of sed, dust instead of du (global rules). Rewrite the command with those tools.",
  )
  process.exit(2)
}

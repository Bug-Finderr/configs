# Mac Setup

New Mac? Run [setup.sh](setup.sh) to install everything and link configs automatically.

## Apps & Brew formulae

See [tools.md](tools.md) for full list with links.

`Brewfile` - reproducible install. Restore with `brew bundle --file=Brewfile`.

## Shell (.zshrc)

Latest backup in [backup_zshrc/actual_backups](backup_zshrc/actual_backups/).

**Plugins** (via Homebrew):
- `zsh-autosuggestions` - history ghost text, accept with `→`
- `zsh-syntax-highlighting` - colors commands as you type
- `zoxide` - smart `cd` that learns frequent dirs
- `fzf` - fuzzy history search with `ctrl+r` (Catppuccin colors via `FZF_DEFAULT_OPTS`)
- `direnv` - auto-loads `.env` files per project directory

**Aliases:**
| Alias | Command | |
|-------|---------|---|
| `cat` | `bat` | syntax-highlighted file viewer |
| `ls` | `eza --icons` | modern ls with icons |
| `ll` | `eza -la --icons --git` | detailed list with git status |
| `lt` | `eza -T --icons --level=2` | tree view |
| `man` | `tldr` | concise command examples |
| `cd` | `z` (zoxide) | frecency-based directory jump |
| `find` | `fd` | fast, user-friendly find |
| `top` | `btop` | modern system monitor |
| `lg` | `lazygit` | terminal git UI |
| `vim` | `nvim` | |
| `kp <port>` | kill process on port | |
| `st` | shelltime benchmark | |

**Auto venv:** activates `./venv` on shell open, cleans stale `$VIRTUAL_ENV`.

**compinit caching:** only does a full completion scan once per hour, uses cached dump otherwise. Cuts ~300ms off startup.

## Git ([.gitconfig](.gitconfig))

**Pager:** `delta` with line numbers, zdiff3 conflict style.

**Aliases:** git shortcuts

## Ripgrep ([.ripgreprc](ripgrep/.ripgreprc))

Smart-case, searches hidden files, skips `.git/`, `node_modules/`, `venv/`, `__pycache__/`. Set via `RIPGREP_CONFIG_PATH` in `.zshrc`.

## Ghostty ([config](ghostty/config))

Catppuccin Mocha, Fira Code iScript (fallback: FiraCode Nerd Font Mono), 14pt, transparency with blur, bar cursor, copy-on-select.

## Prompt - oh-my-posh ([.bread.omp.json](.bread.omp.json))

Catppuccin Mocha palette.
- Left: `(venv)` path `git-branch +status`
- Right: battery, time, execution time (>500ms)

## Catppuccin Mocha (everywhere)

| Tool | Config | Destination |
|------|--------|-------------|
| oh-my-posh | [.bread.omp.json](.bread.omp.json) | referenced from `.zshrc` |
| eza | [eza/theme.yml](eza/theme.yml) | `~/Library/Application Support/eza/` |
| bat | [bat/config](bat/config) | `~/.config/bat/` |
| lazygit | [lazygit/config.yml](lazygit/config.yml) | `~/Library/Application Support/lazygit/` |
| btop | [btop/catppuccin_mocha.theme](btop/catppuccin_mocha.theme) | `~/.config/btop/themes/` |
| ghostty | [ghostty/config](ghostty/config) | `~/Library/Application Support/com.mitchellh.ghostty/` |
| fzf | `.zshrc` `FZF_DEFAULT_OPTS` | env var |
| yazi | [yazi/theme.toml](yazi/theme.toml) | `~/.config/yazi/` |
| delta | [.gitconfig](.gitconfig) | `syntax-theme` setting |

## macOS defaults

See [setup.sh](setup.sh) for all `defaults write` commands (key repeat, Finder, Dock, .DS_Store).

## Scripts

| Script | Purpose |
|--------|---------|
| [welcome](welcome) | Shell open: memory, CPU, battery, startup time |
| [shelltime](shelltime) | Benchmark shell startup (n iterations, progress bar) |
| [common](common) | Shared Catppuccin color constants |
| [load_nvm](load_nvm) | Lazy nvm with path cache (in `.zprofile`) |

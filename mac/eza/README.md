# eza theme — Catppuccin Mocha (muted)

Toned-down Catppuccin Mocha. Filenames and git status pop, metadata fades.

## Install

```sh
brew install eza
mkdir -p ~/Library/Application\ Support/eza
cp theme.yml ~/Library/Application\ Support/eza/theme.yml
```

## Aliases (.zshrc)

```sh
alias ls="eza --icons"
alias ll="eza -la --icons --git"
alias lt="eza -T --icons --level=2"
```

Unset `EZA_COLORS` and `LS_COLORS` if present — they override the theme file.

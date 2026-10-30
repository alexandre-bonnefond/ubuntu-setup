# ubuntu-setup

My Ubuntu 24.04 desktop: i3, i3blocks, rofi, tmux, bash, kitty, vim, ranger and btop, with one
dark/light switch for all of them. Plain config files linked into `$HOME` with GNU stow.

## Install

```bash
git clone https://github.com/alexandre-bonnefond/ubuntu-setup ~/git/ubuntu-setup
cd ~/git/ubuntu-setup
./install.sh            # apt packages, i3blocks 1.5 from source, links every config
./install.sh tmux kitty # only those configs
./install.sh --dry-run  # show the links, change nothing
```

`--no-apt` skips the packages. Existing files are never overwritten: stow lists them and changes
nothing, move them away and run it again. The bash config is added to `~/.bashrc` with one
`source` line.

## Principles

- Only what I use, every file readable.
- Plain files linked into place, no templating, no hidden caches, no wrapper redeploying configs.
- Dark/light switch by swapping small palette files that each tool includes.
- Standalone tools live in their own repos and are hooked in with one line:
  [netscan](https://github.com/alexandre-bonnefond/netscan) (`Super+N`, bar icon) and
  [cmdvault](https://github.com/alexandre-bonnefond/cmdvault).

## What's inside

All shortcuts are in the cheatsheet (`Super+/` or `?` on the bar), with tabs for menus, windows,
workspaces, the bar, tmux, bash and vim.

- **i3**: modes (resize, gaps, mouse, pass-through), workspaces, gaps.
- **i3blocks bar**: CPU, RAM, volume, disk, Tailscale (menu), netscan, bandwidth, power profile
  (menu), battery, keyboard layout, clock, break reminder, cheatsheet, screen layouts, power
  menu, tray (nm-applet and blueman, icons following the colorscheme).
- **rofi**: launcher (`Alt+D`) and menus sharing one theme (tiles, list and strip layouts):
  power (lock, logout, suspend, reboot, shutdown), screen layouts (arandr), colorscheme,
  clipboard history (CopyQ), Tailscale, power profile, break reminder, cheatsheet.
- **tmux**: starts in every kitty window, prefix `Ctrl+A`, vim-aware pane navigation
  (`Ctrl+H/J/K/L`), splits in the current folder, copy to the clipboard, session list, menus to
  mount and unmount drives.
- **bash**: git aliases, `auto-retry` / `ssh-auto-retry`, small helpers.
- **vim**: no plugins, a few mappings (`jk` to leave insert mode, splits and tabs navigation,
  replace helpers, `:w!!` to save with sudo).
- **kitty**, **ranger** and **btop** (TTY theme, follows the terminal colors).

## Dark / light

`Super+C` or `colorscheme dark|light|toggle`. `~/.config/ubuntu-setup/palette` links to
`palettes/dark` or `palettes/light`, and each config includes its file from there. Switching
relinks it and reloads i3, tmux, kitty and running vims.

## Layout

- `install.sh`, `packages.txt`: apt packages and stow links.
- `home/<tool>/`: one stow package per tool, mirroring `$HOME`. Terminal scripts are in
  `home/bin/.local/bin/`, the i3 menus in `home/i3/.config/i3/scripts/`, the bar blocks in
  `home/i3blocks/.config/i3blocks/blocks/`.
- `palettes/{dark,light}/`: one small file per tool (`i3.conf`, `rofi.rasi`, `tmux.conf`,
  `kitty.conf`, `vim.vim`, `colors.sh` for the scripts and bar blocks). For i3 the palette is
  the parent: `~/.config/i3/config` includes it, and it sets the color variables then includes
  `main.conf` (i3 variables set in an included file are not visible outside of it).

## Credits and license

Started from [klaxalk/linux-setup](https://github.com/klaxalk/linux-setup): the ported parts are
under its MIT License (Copyright (c) 2016 Tomáš Báča, see `LICENSE.linux-setup`). Files taken from
other projects (git-forest, i3blocks-contrib blocks) keep their own license headers. The rest is
under the GPLv3 (`LICENSE`).

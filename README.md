# ubuntu-setup

My Ubuntu 26.04 desktop: sway, i3blocks, rofi, tmux, bash, kitty, vim, ranger and btop, with one
dark/light switch for all of them. Plain config files linked into `$HOME` with GNU stow.

sway is i3 for Wayland: same keys, modes and bar. The i3 (Xorg) version for Ubuntu 24.04 is on the
`main` branch.

## Install

```bash
git clone https://github.com/alexandre-bonnefond/ubuntu-setup ~/git/ubuntu-setup
cd ~/git/ubuntu-setup
./install.sh            # apt packages, links every config
./install.sh tmux kitty # only those configs
./install.sh --dry-run  # show the links, change nothing
```

`--no-apt` skips the packages. Existing files are never overwritten: stow lists them and changes
nothing, move them away and run it again. The bash config is added to `~/.bashrc` with one
`source` line.

Then log out and pick **Sway** with the gear icon of the login screen. With the proprietary NVIDIA
driver loaded (hybrid laptops), pick **Sway (no NVIDIA)** instead, added by `install.sh`: sway
does not start next to that driver without `--unsupported-gpu`, and this entry also keeps sway on
the integrated GPU so the NVIDIA one can power off when idle (`session/sway-session`).

The keyboard layouts and the switch key come from `/etc/default/keyboard`
(`sudo dpkg-reconfigure keyboard-configuration`), e.g. `XKBLAYOUT="us,fr"` and
`XKBOPTIONS="grp:rctrl_rshift_toggle"`.

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

- **sway**: modes (resize, gaps, mouse, pass-through), workspaces, gaps, tap to click, screen
  locked before suspend (swaylock, swayidle), region screenshot (grim, slurp, swappy).
- **i3blocks bar**: CPU, RAM, volume, disk, temperatures and fans, Tailscale (menu), netscan, Docker (running
  containers, click opens [lazydocker](https://github.com/jesseduffield/lazydocker), not
  installed by `install.sh`, right click a shell in a container), bandwidth, power profile
  (menu), battery, keyboard layout, clock, break reminder, cheatsheet, screen layouts, power
  menu, tray (nm-applet and blueman, icons following the colorscheme).
- **rofi**: launcher (`Alt+D`) and menus sharing one theme (tiles, list and strip layouts):
  power (lock, logout, suspend, reboot, shutdown), screen layouts (switch, save the current one,
  arrange with wdisplays), colorscheme, clipboard history (cliphist), Tailscale, power profile,
  break reminder, cheatsheet.
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
relinks it and reloads sway, tmux, kitty and running vims.

## Layout

- `install.sh`, `packages.txt`: apt packages and stow links.
- `home/<tool>/`: one stow package per tool, mirroring `$HOME`. Terminal scripts are in
  `home/bin/.local/bin/`, the sway menus in `home/sway/.config/sway/scripts/`, the bar blocks in
  `home/i3blocks/.config/i3blocks/blocks/`.
- `palettes/{dark,light}/`: one small file per tool (`sway.conf`, `rofi.rasi`, `tmux.conf`,
  `kitty.conf`, `vim.vim`, `colors.sh` for the scripts and bar blocks). `~/.config/sway/config`
  includes the palette's color variables, then `main.conf`.

## Credits and license

Started from [klaxalk/linux-setup](https://github.com/klaxalk/linux-setup): the ported parts are
under its MIT License (Copyright (c) 2016 Tomáš Báča, see `LICENSE.linux-setup`). Files taken from
other projects (git-forest, i3blocks-contrib blocks) keep their own license headers. The rest is
under the GPLv3 (`LICENSE`).

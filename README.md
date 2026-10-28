# ubuntu-setup

My personal Ubuntu 24.04 setup (i3, i3blocks, rofi, tmux, bash, kitty, vim), replacing
[klaxalk/linux-setup](https://github.com/klaxalk/linux-setup), from which it keeps only what I use.

Status: **planning**, linux-setup (`~/git/linux-setup`, branch `alex_rofi_lenovo_setup`)
stays installed as the reference and safety net until everything is migrated.

## Principles

- Only what I use, every file understandable.
- Plain files linked into place by `install.sh` (e.g. GNU stow), no templating.
- Dark/light switch (`Super+C`) by swapping small palette files that each tool includes
  (i3, i3blocks, rofi, tmux, kitty, vim), instead of linux-setup's epigen profiles.
- No surprises: no `git` wrapper that redeploys configs, no hidden caches.
- Standalone tools stay in their own repos (e.g. `~/git/cmdvault`), hooked in with one line.

## Inventory

### Keep

- **i3**: all current shortcuts (see the cheatsheet), modes (resize, gaps, mouse,
  pass-through), workspaces, gaps.
- **i3blocks bar**: CPU %, RAM %, volume, disk, Tailscale (logo, menu), bandwidth,
  power profile (menu), battery (orange <= 30 %, red <= 15 %), keyboard layout, clock,
  break reminder (menu, `~/.config/i3-break.conf`), cheatsheet `?`, screen layouts,
  power menu, tray (nm-applet / blueman with icons matching the colorscheme).
- **rofi**: Alt+D launcher, shared menu theme (tiles / list / strip templates),
  neutral dark and light palettes.
- **Scripts**: power menu (lock with grab diagnostics, logout, suspend, reboot, shutdown),
  screen layouts (arandr `~/.screenlayout`, i3 restart), colorscheme, clipboard history
  (CopyQ), Tailscale menu, power profile menu, break reminder, cheatsheet, brightness
  through logind, tray watchdog, layout manager.
- **tmux**: everything
  - auto-start in every terminal, prefix `Ctrl+A`
  - `Ctrl+T` new window, `Alt+U/I` and `Shift+arrows` next/previous, `Ctrl+Shift+arrows` move
  - `Ctrl+9` / `Ctrl+0` splits in the current folder
  - `Ctrl+H/J/K/L` and `Alt+arrows` pane navigation (vim-aware), prefix + `Ctrl+H/J/K/L` resize
  - `F2` copy mode, `v` / `y` to the clipboard, prefix + `p` paste
  - prefix + `k` kill session, `:qa` quit session, prefix + `r` reload, prefix + `s` sessions
  - prefix + `m` / `u` / `e` mount / unmount / end experiment scripts, `Ctrl+P` vim file search
- **bash**: everything from `dotbashrc` / `shell/commons.sh` except `catkin`
  - `sb`, `gs`, `glog`, `flog`, `gppl`, `gppo`, `gcmp`, `gr`, `git2ssh`, `git2https`,
    `killp`, `:q`, `ranger` / `ra`, `auto-retry`, `ssh-auto-retry`, `papis`, `slack`,
    `octave`, `demangle`, `getVideoThumbnail`, `indie`
  - keep sourcing `~/git/mrs_uav_development/shell_additions/shell_additions.sh` (ROS 2, MRS)
- **vim**: minimal config, no plugins, basic editing only
  - `jk` to leave insert mode, `H` / `L` line start/end, `Ctrl+H/J/K/L` splits,
    `Shift+J/K` tabs, `,g` reindent + trim, `,d` delete without yank, `,fr` / `,frl`
    replace, `*` without jumping, visual `//` search, `:w!!` sudo save,
    `,r` / `,p` / `,a` toggles (leader `,` and Space)
- **ranger**: config from linux-setup.
- **kitty** replaces urxvt (Alt+Return), with dark/light palettes.
- **btop** replaces htop.

### Drop

zsh, catkin (ROS 1), zathura, urxvt / `.Xresources`, htop config, the 44 vim plugins
(coc, telescope, nerdtree, vimtex, vimwiki, ...), LaTeX, papis-vim, pdfpc, epigen
profiles and the other users' sections (Tomas, Matous, Pavel, ...), linux-setup's
`git` wrapper, unused submodules.

## Plan

1. Skeleton: `install.sh` (stow links, apt packages), palette system, repo layout.
2. i3 + i3blocks + scripts + rofi (port from linux-setup, drop the profile blocks).
3. tmux, bash, vim, kitty, ranger, btop.
4. Switch over piece by piece on this laptop, then remove the linux-setup links.
5. Test a fresh install (VM or container).

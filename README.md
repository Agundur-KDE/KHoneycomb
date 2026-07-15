# KHoneycomb

Draggable hexagonal desktop launcher icons for KDE Plasma 6 — inspired by
[this r/kde thread](https://www.reddit.com/r/kde/) where a Rainmeter-style
GTK/Cairo hack didn't survive the move from Cinnamon to Plasma.

**Status: early prototype.** One hexagon = one plasmoid instance (add
several via "Add Widgets", drag each freely on the desktop like Sticky
Notes) — no cluster-wide config UI yet, settings are set by hand in
`~/.config/plasma-org.kde.plasma.desktop-appletsrc` for now.

## What works

- Crisp, anti-aliased pointy-top hexagon (`QtQuick.Shapes` + `MultiEffect`
  mask), no panel background/chrome
- Config dialog (right-click → Configure): icon image picker, command,
  size
- Click launches the configured command
- Free desktop placement/resizing via Plasma's own edit mode (no custom
  drag code needed)

## Not built yet

- "Decluster" / reset-all-to-a-row action across instances (needs a shared
  config file, same pattern as [KClaude](https://github.com/Agundur-KDE/KClaude)'s `sessions.json`)
- Right-click context menu beyond Plasma's default (kill/refresh actions
  from the original Mint version)

## Try it

```bash
git clone git@github.com:Agundur-KDE/KHoneycomb.git
kpackagetool6 --type Plasma/Applet --install KHoneycomb/package/
plasmoidviewer -a de.agundur.khoneycomb -f planar -s 140x160
```

Right-click the hexagon → Configure to set the icon image and launch
command, or add multiple instances via "Add Widgets" for a real cluster.

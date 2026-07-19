# KHoneycomb

<p align="center"><img src="assets/logo.jpg" alt="KHoneycomb — honeycomb of honey-yellow hexagon tiles" width="600" /></p>

Draggable hexagonal desktop launcher icons for KDE Plasma 6 — inspired by
[this r/kde thread](https://www.reddit.com/r/kde/) where a Rainmeter-style
GTK/Cairo hack didn't survive the move from Cinnamon to Plasma.

**Status: early prototype.** One hexagon = one plasmoid instance (add
several via "Add Widgets", drag each freely on the desktop like Sticky
Notes) — no cluster-wide config UI yet.

## What works

- Crisp, anti-aliased regular hexagon (`QtQuick.Shapes` + `MultiEffect`
  mask), no panel background/chrome — flat-top or pointy-top, your choice
- Config dialog (right-click → Configure): icon image picker, command,
  size, orientation (flat-top/pointy-top), placeholder color
- Click launches the configured command
- Free desktop placement/resizing via Plasma's own edit mode (no custom
  drag code needed)

## Languages

UI translated into German, Spanish, French, and Russian (English is the
fallback). Further translations are welcome — the strings live in
`translate/<lang>/*.po`, standard gettext format.

## Not built yet

- "Decluster" / reset-all-to-a-row action across instances (needs a shared
  config file, same pattern as [KClaude](https://github.com/Agundur-KDE/KClaude)'s `sessions.json`)
- Right-click context menu beyond Plasma's default (kill/refresh actions
  from the original Mint version)

## Try it

```bash
git clone https://github.com/Agundur-KDE/KHoneycomb.git
kpackagetool6 --type Plasma/Applet --install KHoneycomb/package/
plasmoidviewer -a de.agundur.khoneycomb -f planar -s 140x160
```

Right-click the hexagon → Configure to set the icon image and launch
command, or add multiple instances via "Add Widgets" for a real cluster.

# KHoneycomb

<p align="center">
  <img src="assets/screenshot1.png" alt="Honeycomb of hexagon launcher icons on the KDE Plasma desktop" width="600" /><br />
  <img src="assets/screenshot2.png" alt="Close-up of the bevelled hexagon launcher icons" width="600" />
</p>

**KHiveLaunch** is a KDE Plasma 6 widget that launches apps from a
honeycomb of hexagon tiles in a single widget, instead of a plain icon
grid or taskbar row — inspired by [this r/kde thread](https://www.reddit.com/r/kde/)
where a Rainmeter-style GTK/Cairo hex launcher didn't survive the move
from Cinnamon to Plasma.

## Features

- One widget, whole grid — auto-fitting columns/rows, or a fixed column
  count; flat-top or pointy-top hexagons
- Per-slot config: icon image, launch command, zoom (crop into icons with
  a lot of transparent padding), custom tile color
- Optional background image behind the grid (fill/fit/stretch + darken
  slider)
- Adjustable neumorphism — one signed 3D bevel slider from deeply sunken
  (-150) through flat (0) to raised (+150), not just on/off
- Grid padding — pixel gap between the honeycomb and the widget edge
- Hover tooltip shows the clean app name, even for slots whose launch
  command carries arguments (`thunderbird --profile ...` → "Thunderbird")
- Drag-to-reorder hexagons, right-click a tile for a quick icon/command
  editor without opening the full config dialog

## Languages

🇬🇧 English (fallback) · 🇩🇪 German · 🇪🇸 Spanish · 🇫🇷 French · 🇷🇺 Russian

More translations are very welcome! The strings live in
`translate/<lang>/plasma_applet_de.agundur.khivelaunch.po`, standard
gettext format — copy an existing file as a starting point and open a PR.

## Not built yet

- "Decluster" / reset-slot-order action
- Custom per-slot drop shadows independent of the bevel setting

## Try it

```bash
git clone https://github.com/Agundur-KDE/KHoneycomb.git
kpackagetool6 --type Plasma/Applet --install KHoneycomb/hive-package/
plasmoidviewer -a de.agundur.khivelaunch -s 700x400
```

Right-click a hexagon → Configure to add slots (icon image + launch
command), or use the full config dialog for background image, bevel
strength, and grid padding.

Can also be built and installed system-wide via CMake:

```bash
cmake -B build && cmake --build build && sudo cmake --install build
```

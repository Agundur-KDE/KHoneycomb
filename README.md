# KHoneycomb

<p align="center">
  <img src="assets/screenshot1.png" alt="Honeycomb of hexagon launcher icons on the KDE Plasma desktop" width="600" /><br />
  <img src="assets/screenshot2.png" alt="Close-up of the bevelled hexagon launcher icons" width="600" />
</p>

**KHoneycomb** is a KDE Plasma 6 widget collection for launching apps from
a honeycomb of hexagon tiles instead of a plain icon grid or taskbar row —
inspired by [this r/kde thread](https://www.reddit.com/r/kde/) where a
Rainmeter-style GTK/Cairo hex launcher didn't survive the move from
Cinnamon to Plasma.

**KHiveLaunch** (`de.agundur.khivelaunch`) is the main plasmoid: one widget
holds a whole configurable grid of launcher hexagons, tiled edge-to-edge —
no need to place and align one plasmoid per icon. The repo also still
ships the original **KHoneycomb** plasmoid (`de.agundur.khoneycomb`, one
hexagon per instance, drag each freely like Sticky Notes) for anyone who
prefers that.

## KHiveLaunch features

- One widget, whole grid — auto-fitting columns/rows, or a fixed column
  count; flat-top or pointy-top hexagons
- Per-slot config: icon image, launch command, zoom (crop into icons with
  a lot of transparent padding), custom tile color
- Optional background image behind the grid (fill/fit/stretch + darken
  slider)
- Adjustable 3D look — one signed slider from deeply sunken (-150) through
  flat (0) to raised (+150), not just on/off
- Grid padding — pixel gap between the honeycomb and the widget edge
- Hover tooltip shows the clean app name, even for slots whose launch
  command carries arguments (`thunderbird --profile ...` → "Thunderbird")
- Drag-to-reorder hexagons, right-click a tile for a quick icon/command
  editor without opening the full config dialog

## Languages

🇬🇧 English (fallback) · 🇩🇪 German · 🇪🇸 Spanish · 🇫🇷 French · 🇷🇺 Russian —
both plasmoids, KHiveLaunch included.

More translations are very welcome! The strings live in
`translate/<lang>/*.po`, standard gettext format — one `.po` file per
plasmoid per language (`plasma_applet_de.agundur.khivelaunch.po` and
`plasma_applet_de.agundur.khoneycomb.po`). Copy an existing file as a
starting point and open a PR.

## Not built yet

- KHiveLaunch: "decluster" / reset-slot-order action, custom per-slot
  drop shadows independent of the bevel setting
- Original KHoneycomb: not under active development — KHiveLaunch covers
  the same use case in a single widget, but the plasmoid stays in the
  repo and installs fine

## Try it

```bash
git clone https://github.com/Agundur-KDE/KHoneycomb.git
kpackagetool6 --type Plasma/Applet --install KHoneycomb/hive-package/
plasmoidviewer -a de.agundur.khivelaunch -s 700x400
```

Right-click a hexagon → Configure to add slots (icon image + launch
command), or use the full config dialog for background image, bevel
strength, and grid padding.

Both plasmoids can also be built and installed system-wide via CMake:

```bash
cmake -B build && cmake --build build && sudo cmake --install build
```

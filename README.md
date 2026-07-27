# KHoneycomb

<p align="center">
  <img src="assets/screenshot1.png" alt="Honeycomb of hexagon launcher icons on the KDE Plasma desktop" width="600" /><br />
  <img src="assets/screenshot2.png" alt="Close-up of the bevelled hexagon launcher icons" width="600" />
</p>

**KHoneycomb** is a KDE Plasma 6 application launcher widget — a
honeycomb of glowing hexagon tiles instead of a plain icon grid or
taskbar row, made for ricing your desktop into something worth a
screenshot.

## Features

- Real eye candy, not just an icon grid — a honeycomb of hexagons with
  adjustable neumorphism: one signed 3D bevel slider takes every tile
  from deeply sunken through flat to raised, not just an on/off effect
- Your own background image behind the grid, with a darken slider so
  icons stay readable over busy wallpaper
- Auto-fitting honeycomb layout — flat-top or pointy-top hexagons,
  columns adapt to however you resize the widget
- Drag a tile to reorder it, right-click for a quick icon/command editor
  without opening the full config dialog
- Per-tile control: icon image, launch command, zoom to crop into icons
  with a lot of transparent padding, custom tile color
- Grid padding and hover tooltips round out the polish

## Languages

🇬🇧 English (fallback) · 🇩🇪 German · 🇪🇸 Spanish · 🇫🇷 French · 🇷🇺 Russian

More translations are very welcome! The strings live in
`translate/<lang>/plasma_applet_de.agundur.khoneycomb.po`, standard
gettext format — copy an existing file as a starting point and open a PR.

## Try it

```bash
git clone https://github.com/Agundur-KDE/KHoneycomb.git
kpackagetool6 --type Plasma/Applet --install KHoneycomb/package/
plasmoidviewer -a de.agundur.khoneycomb -s 700x400
```

Right-click a hexagon → Configure to add slots (icon image + launch
command), or use the full config dialog for background image, bevel
strength, and grid padding.

Can also be built and installed system-wide via CMake:

```bash
cmake -B build && cmake --build build && sudo cmake --install build
```

<div align="center">
  <img src="package/contents/icons/khoneycomb_128x128.png" width="80" alt="KHoneycomb logo">
  <h1>KHoneycomb</h1>
</div>

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

## Install

### Quick install, no package manager

```bash
git clone https://github.com/Agundur-KDE/KHoneycomb.git
kpackagetool6 --type Plasma/Applet --install KHoneycomb/package/
```

Then right-click your desktop → **Enter Edit Mode** → **Add or Manage
Widgets...** (on a panel it's a direct context-menu entry, no edit mode
needed), search for "KHoneycomb", and drag it into place.

### openSUSE Tumbleweed

Via the Open Build Service:

```bash
sudo zypper ar -f https://download.opensuse.org/repositories/home:/Agundur/openSUSE_Tumbleweed/home:Agundur.repo
sudo zypper --gpg-auto-import-keys ref
sudo zypper ref
sudo zypper in khoneycomb
```

### Debian / Ubuntu

Direct download from the [latest release](https://github.com/Agundur-KDE/KHoneycomb/releases/latest):

```bash
sudo apt install ./khoneycomb_*.deb
```

### System-wide via CMake

```bash
cmake -B build && cmake --build build && sudo cmake --install build
```

Right-click a hexagon → Configure to add slots (icon image + launch
command), or use the full config dialog for background image, bevel
strength, and grid padding.

## Show us your rice

Got KHoneycomb set up on your desktop? Post a screenshot in
[Show and tell](https://github.com/Agundur-KDE/KHoneycomb/discussions/categories/show-and-tell) —
background image, bevel setting, hexagon layout, whatever you landed on.

Complete your KDE setup — with a pick from our ever-growing [wallpaper collection](https://github.com/Agundur-KDE/Wallpapers).

<a href="https://github.com/Agundur-KDE/Wallpapers">
  <img src="https://raw.githubusercontent.com/Agundur-KDE/Wallpapers/main/previews/anime-tux-4k-preview.jpg" alt="anime-tux wallpaper: stylized Tux character with a purple aura in front of a night city skyline" width="300" />
</a>

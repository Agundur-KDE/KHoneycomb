%ifarch aarch64
%undefine source_date_epoch_from_changelog
%endif

Name:           khoneycomb
Version:        0.2.0
Release:        1%{?dist}
Summary:        KDE Plasma 6 application launcher widget, a honeycomb of hexagons

License:        GPL-3.0-or-later
URL:            https://github.com/Agundur-KDE/KHoneycomb


BuildRequires:  cmake
BuildRequires:  gcc-c++
BuildRequires:  gettext
BuildRequires:  qt6-base-devel
BuildRequires:  qt6-declarative-devel
BuildRequires:  kf6-extra-cmake-modules
BuildRequires:  kf6-ki18n-devel


Requires:       plasma6-workspace
Requires:       python3

%description
KHoneycomb fills one KDE Plasma 6 widget with a whole configurable grid
of hexagon launcher tiles, tiled edge-to-edge. Adjustable neumorphic 3D
bevel, optional background image, per-tile icon/command/zoom/color, and
drag-to-reorder. Translated into German, Spanish, French and Russian.

Source0: _service

%prep

rm -rf ./*

shopt -s nullglob
picked=""
for d in %{_sourcedir}/KHoneycomb-* %{_sourcedir}/khoneycomb-* %{_sourcedir}/KHoneycomb ; do
  if [ -d "$d" ] && [ -f "$d/CMakeLists.txt" ]; then
    picked="$d"
    break
  fi
done

if [ -n "$picked" ]; then
  cp -a "$picked"/. .
else
  for f in %{_sourcedir}/* ; do
    base="$(basename "$f")"
    case "$base" in
      *.spec|*.dsc|*.changes|*.obsinfo|_service|service_attic|screenshot|*.patch)
        continue ;;
    esac
    cp -a "$f" .
  done
fi

%build
%cmake \
  -DCMAKE_BUILD_TYPE=RelWithDebInfo \
  -DCMAKE_INSTALL_PREFIX=%{_prefix}
%cmake_build

%install
%cmake_install


%files
%license LICENSE
%doc README.md
# Recursive, matching CMakeLists.txt's own `install(DIRECTORY package/ ...)`
# — that installs the whole package/ tree wholesale, so any file added
# there (icons, a new compact representation, whatever comes next) is
# covered automatically instead of needing a matching new line here every
# time. Enumerating individual files was the actual cause of the first
# OBS build failure: the app-icon feature added contents/icons/* without
# anyone remembering to add it to this list too.
%{_datadir}/plasma/plasmoids/de.agundur.khoneycomb/
%{_datadir}/icons/hicolor/*/apps/khoneycomb.png
%{_datadir}/locale/*/LC_MESSAGES/plasma_applet_de.agundur.khoneycomb.mo

%changelog
* Mon Jul 27 2026 Alec <info@agundur.de> - 0.2.0
- First automated .deb/.rpm/.plasmoid release via GitHub Actions
- Renamed the plasmoid from the internal working name KHiveLaunch to
  KHoneycomb, matching the repo — the old single-hexagon-per-instance
  KHoneycomb plasmoid is retired, this is now the one and only widget
- Configurable background image, adjustable neumorphic 3D bevel, grid
  padding, hover tooltips, drag-to-reorder
- Category corrected to "Application Launchers"

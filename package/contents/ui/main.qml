/*
 * SPDX-FileCopyrightText: 2026 Agundur <info@agundur.de>
 *
 * SPDX-License-Identifier: GPL-2.0-only OR GPL-3.0-only OR LicenseRef-KDE-Accepted-GPL
 */

import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasmoid

PlasmoidItem {
    id: root

    Plasmoid.title: i18n("KHoneycomb")
    Plasmoid.status: PlasmaCore.Types.ActiveStatus
    Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground
    toolTipMainText: Plasmoid.title

    fullRepresentation: FullRepresentation {
        id: full

        Layout.minimumWidth: full.gridWidth
        Layout.minimumHeight: full.gridHeight
    }

    // No preferredRepresentation override — the honeycomb grid needs real
    // space to read as hexagons rather than a squished mess, so a panel
    // gets the compact icon (click to pop the full grid open) while the
    // desktop gets the full grid directly, same as any other Plasma applet.
    compactRepresentation: Item {
        id: compactView

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.expanded = !root.expanded
        }

        Kirigami.Icon {
            anchors.fill: parent
            source: "khoneycomb"
        }
    }
}

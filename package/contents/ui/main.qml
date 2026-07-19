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

    preferredRepresentation: fullRepresentation
    Plasmoid.title: i18n("KHoneycomb")
    Plasmoid.status: PlasmaCore.Types.ActiveStatus
    // No panel chrome — the hexagon mask below is the entire visual.
    Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground
    toolTipMainText: Plasmoid.title

    fullRepresentation: FullRepresentation {
        id: full

        // Fixed to the configured size, not full.hexWidth/hexHeight — those
        // now track the live (resized) box, and feeding them back into the
        // resize constraint itself would risk a binding loop.
        Layout.minimumWidth: full.pointyTop
            ? Math.round(Plasmoid.configuration.hexSize * full.hexRatio)
            : Plasmoid.configuration.hexSize
        Layout.minimumHeight: full.pointyTop
            ? Plasmoid.configuration.hexSize
            : Math.round(Plasmoid.configuration.hexSize * full.hexRatio)
    }

    compactRepresentation: MouseArea {
        implicitWidth: Kirigami.Units.iconSizes.medium
        implicitHeight: Kirigami.Units.iconSizes.medium
    }
}

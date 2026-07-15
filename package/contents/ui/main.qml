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

        Layout.minimumWidth: full.hexWidth
        Layout.minimumHeight: Plasmoid.configuration.hexSize
    }

    compactRepresentation: MouseArea {
        implicitWidth: Kirigami.Units.iconSizes.medium
        implicitHeight: Kirigami.Units.iconSizes.medium
    }
}

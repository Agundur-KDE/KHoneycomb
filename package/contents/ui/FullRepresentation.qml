/*
 * SPDX-FileCopyrightText: 2026 Agundur <info@agundur.de>
 *
 * SPDX-License-Identifier: GPL-2.0-only OR GPL-3.0-only OR LicenseRef-KDE-Accepted-GPL
 */

import QtQuick
import QtQuick.Shapes
import QtQuick.Effects
import org.kde.plasma.plasmoid
import org.kde.plasma.plasma5support as Plasma5Support

Item {
    id: full

    readonly property int hexHeight: Plasmoid.configuration.hexSize
    // Pointy-top hexagon: width/height ratio of a regular hexagon is sqrt(3)/2.
    readonly property int hexWidth: Math.round(hexHeight * 0.8660254)

    implicitWidth: hexWidth
    implicitHeight: hexHeight

    // Six vertices of a pointy-top regular hexagon, scaled to hexWidth x hexHeight.
    function hexPoints(w, h) {
        const cx = w / 2, cy = h / 2, r = h / 2
        const pts = []
        for (let i = 0; i < 6; i++) {
            const angle = (Math.PI / 180) * (60 * i - 90)
            pts.push(Qt.point(cx + r * Math.cos(angle) * (w / h), cy + r * Math.sin(angle)))
        }
        return pts
    }

    // MultiEffect below still needs these actually rendered (opacity:0, not
    // visible:false) to grab them as a texture — same Qt quirk as
    // KPictureFrame's ambient-glow effect.
    Image {
        id: icon

        anchors.fill: parent
        fillMode: Image.PreserveAspectCrop
        source: Plasmoid.configuration.imagePath
        smooth: true
        mipmap: true
        opacity: 0
        asynchronous: true
    }

    // Fallback so the shape is visible even without a configured image yet.
    Rectangle {
        id: placeholder

        anchors.fill: parent
        color: "#3daee9"
        opacity: 0
    }

    Shape {
        id: hexMask

        anchors.fill: parent
        opacity: 0
        layer.enabled: true
        layer.smooth: true
        ShapePath {
            fillColor: "white"
            strokeColor: "transparent"
            startX: full.hexPoints(full.hexWidth, full.hexHeight)[0].x
            startY: full.hexPoints(full.hexWidth, full.hexHeight)[0].y
            PathPolyline {
                path: full.hexPoints(full.hexWidth, full.hexHeight)
            }
        }
    }

    MultiEffect {
        anchors.fill: parent
        source: icon.status === Image.Ready ? icon : placeholder
        maskEnabled: true
        maskSource: hexMask
        maskThresholdMin: 0.5
        maskSpreadAtMin: 1.0
    }

    Plasma5Support.DataSource {
        id: executable
        engine: "executable"
        connectedSources: []
        onNewData: (sourceName, data) => disconnectSource(sourceName)
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            if (Plasmoid.configuration.command)
                executable.connectSource(Plasmoid.configuration.command)
        }
    }
}

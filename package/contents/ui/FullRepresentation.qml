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

    // Flat-top hexagon (the classic honeycomb-cell look): height/width
    // ratio of a regular hexagon is sqrt(3)/2 — wider than tall.
    readonly property real hexRatio: 0.8660254

    // Largest correctly-proportioned hexagon that fits the actual box Plasma
    // gives us. Desktop free-resize (right-click > Resize) sets width/height
    // directly without preserving the ratio, so this must track the live
    // size, not just the configured one — otherwise the mask and the resized
    // box drift apart (missing corners, image not following the resize).
    readonly property int hexWidth: width > 0 && height > 0
        ? (height / hexRatio <= width ? Math.round(height / hexRatio) : width)
        : Plasmoid.configuration.hexSize
    readonly property int hexHeight: Math.round(hexWidth * hexRatio)
    readonly property real hexOffsetX: (width - hexWidth) / 2
    readonly property real hexOffsetY: (height - hexHeight) / 2

    implicitWidth: Plasmoid.configuration.hexSize
    implicitHeight: Math.round(Plasmoid.configuration.hexSize * hexRatio)

    // Six vertices of a flat-top regular hexagon, scaled to w x h and
    // offset by (ox, oy) to stay centered when it doesn't fill the box.
    function hexPoints(w, h, ox, oy) {
        const cx = ox + w / 2, cy = oy + h / 2, r = w / 2
        const pts = []
        for (let i = 0; i < 6; i++) {
            const angle = (Math.PI / 180) * (60 * i)
            pts.push(Qt.point(cx + r * Math.cos(angle), cy + r * Math.sin(angle) * (h / w)))
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
            startX: full.hexPoints(full.hexWidth, full.hexHeight, full.hexOffsetX, full.hexOffsetY)[0].x
            startY: full.hexPoints(full.hexWidth, full.hexHeight, full.hexOffsetX, full.hexOffsetY)[0].y
            PathPolyline {
                path: full.hexPoints(full.hexWidth, full.hexHeight, full.hexOffsetX, full.hexOffsetY)
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

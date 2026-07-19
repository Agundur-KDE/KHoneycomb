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

    // Ratio of the short side to the long side of a regular hexagon's
    // bounding box is sqrt(3)/2 — flat-top is wider than tall, pointy-top
    // is taller than wide, by exactly this factor either way.
    readonly property real hexRatio: 0.8660254
    readonly property bool pointyTop: Plasmoid.configuration.orientation === "pointy"

    // Largest correctly-proportioned hexagon that fits the actual box Plasma
    // gives us. Desktop free-resize (right-click > Resize) sets width/height
    // directly without preserving the ratio, so this must track the live
    // size, not just the configured one — otherwise the mask and the resized
    // box drift apart (missing corners, image not following the resize).
    readonly property int hexWidth: width > 0 && height > 0
        ? (pointyTop
            ? Math.round(Math.min(width, height * hexRatio))
            : Math.min(Math.round(height / hexRatio), width))
        : (pointyTop ? Math.round(Plasmoid.configuration.hexSize * hexRatio) : Plasmoid.configuration.hexSize)
    readonly property int hexHeight: pointyTop
        ? Math.round(hexWidth / hexRatio)
        : Math.round(hexWidth * hexRatio)
    readonly property real hexOffsetX: (width - hexWidth) / 2
    readonly property real hexOffsetY: (height - hexHeight) / 2

    implicitWidth: pointyTop ? Math.round(Plasmoid.configuration.hexSize * hexRatio) : Plasmoid.configuration.hexSize
    implicitHeight: pointyTop ? Plasmoid.configuration.hexSize : Math.round(Plasmoid.configuration.hexSize * hexRatio)

    // Six vertices of a regular hexagon, offset by (ox, oy) to stay centered
    // when it doesn't fill the box. w/h are always already in the correct
    // hexRatio proportion (see hexHeight above), so placing vertices on a
    // plain circle at 60° steps already yields equal-length sides — no extra
    // axis-scaling needed (that would distort it). Flat-top starts the first
    // vertex at 0° (pointing right); pointy-top starts at -90° (pointing up).
    function hexPoints(w, h, ox, oy) {
        const cx = ox + w / 2, cy = oy + h / 2, r = pointyTop ? h / 2 : w / 2
        const startAngle = pointyTop ? -90 : 0
        const pts = []
        for (let i = 0; i < 6; i++) {
            const angle = (Math.PI / 180) * (startAngle + 60 * i)
            pts.push(Qt.point(cx + r * Math.cos(angle), cy + r * Math.sin(angle)))
        }
        return pts
    }

    // 3D-bevel prototype: a light stroke along the upper three edges and a
    // dark stroke along the lower three approximates a raised rim (light
    // from above). Which vertex indices count as "upper" rotates with the
    // orientation's startAngle, so the two chains are looked up per case
    // rather than computed generically — there are only ever two.
    readonly property var bevelUpperIdx: pointyTop ? [5, 0, 1, 2] : [3, 4, 5, 0]
    readonly property var bevelLowerIdx: pointyTop ? [2, 3, 4, 5] : [0, 1, 2, 3]

    function bevelChain(idx) {
        const pts = full.hexPoints(full.hexWidth, full.hexHeight, full.hexOffsetX, full.hexOffsetY)
        return idx.map(i => pts[i])
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
        color: Plasmoid.configuration.placeholderColor
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

        shadowEnabled: true
        shadowColor: Qt.rgba(0, 0, 0, 0.55)
        shadowBlur: 0.6
        shadowVerticalOffset: 4
        shadowHorizontalOffset: 0
    }

    // Raised-bead prototype (Weg A): two half-outline strokes, not masked to
    // the hex interior on purpose — the stroke straddles the true silhouette
    // edge, which is what sells the "bulge over the background" look. Kept
    // invisible itself (opacity: 0) — only the blurred MultiEffect copy
    // below is actually shown, so the hard double-line reads as a soft
    // rounded ridge instead of a second polygon outline.
    Shape {
        id: bevel
        anchors.fill: parent
        opacity: 0
        layer.enabled: true
        layer.smooth: true

        ShapePath {
            fillColor: "transparent"
            strokeColor: Qt.rgba(1, 1, 1, 0.55)
            strokeWidth: 5
            capStyle: ShapePath.RoundCap
            joinStyle: ShapePath.RoundJoin
            startX: full.bevelChain(full.bevelUpperIdx)[0].x
            startY: full.bevelChain(full.bevelUpperIdx)[0].y
            PathPolyline { path: full.bevelChain(full.bevelUpperIdx) }
        }
        ShapePath {
            fillColor: "transparent"
            strokeColor: Qt.rgba(0, 0, 0, 0.45)
            strokeWidth: 5
            capStyle: ShapePath.RoundCap
            joinStyle: ShapePath.RoundJoin
            startX: full.bevelChain(full.bevelLowerIdx)[0].x
            startY: full.bevelChain(full.bevelLowerIdx)[0].y
            PathPolyline { path: full.bevelChain(full.bevelLowerIdx) }
        }
    }

    MultiEffect {
        anchors.fill: parent
        source: bevel
        blurEnabled: true
        blur: 0.15
        blurMax: 6
        autoPaddingEnabled: true
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

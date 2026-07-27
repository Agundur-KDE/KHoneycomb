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

    // Split into two MultiEffects on purpose: maskEnabled + shadowEnabled
    // together on the same MultiEffect silently breaks the mask (falls back
    // to the full rectangular bounds) — a Qt6 MultiEffect limitation, not
    // our geometry. Masking happens here only; the shadow effect below reads
    // this already-hex-shaped alpha, so it doesn't need its own mask.
    MultiEffect {
        id: maskedIcon
        anchors.fill: parent
        opacity: 0
        layer.enabled: true
        layer.smooth: true
        source: icon.status === Image.Ready ? icon : placeholder
        maskEnabled: true
        maskSource: hexMask
        maskThresholdMin: 0.5
        maskSpreadAtMin: 1.0
    }

    // Raised-bead, Weg B: a single analytic hexagon signed-distance-field
    // shades color continuously near the edge (light from upper-left, dark
    // lower-right) — flat interior, bevel only in a thin band near the rim.
    // Only ever touches color, never alpha, so it can sit safely between the
    // mask stage and the shadow stage without reintroducing the mask bug.
    ShaderEffect {
        id: bevelShaded
        anchors.fill: parent
        opacity: 0
        layer.enabled: true
        layer.smooth: true
        property variant source: maskedIcon
        property size uItemSize: Qt.size(full.width, full.height)
        property point uHexCenter: Qt.point(full.hexOffsetX + full.hexWidth / 2, full.hexOffsetY + full.hexHeight / 2)
        property real uHexR: full.pointyTop ? full.hexHeight / 2 : full.hexWidth / 2
        property real uPointyTop: full.pointyTop ? 1.0 : 0.0
        property real uBevelWidth: Math.max(4, full.hexWidth * 0.08)
        property real uStrength: 0.35
        property point uLightDir: Qt.point(-0.4472, -0.8944)

        fragmentShader: "../shaders/bevel.frag.qsb"
    }

    MultiEffect {
        anchors.fill: parent
        source: bevelShaded

        shadowEnabled: true
        shadowColor: Qt.rgba(0, 0, 0, 0.55)
        shadowBlur: 0.6
        shadowVerticalOffset: 4
        shadowHorizontalOffset: 0
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

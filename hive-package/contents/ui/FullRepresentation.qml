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

    // Same ratio/orientation/vertex math as KHoneycomb's FullRepresentation —
    // kept as a plain copy here on purpose (see ideen.md KHiveLaunch notes):
    // the two plasmoids have different enough surrounding code (grid layout
    // vs. single icon) that sharing this handful of lines isn't worth the
    // packaging complexity of a common QML module.
    readonly property real hexRatio: 0.8660254
    readonly property bool pointyTop: Plasmoid.configuration.orientation === "pointy"
    readonly property int hexSize: Plasmoid.configuration.hexSize
    readonly property int hexW: pointyTop ? Math.round(hexSize * hexRatio) : hexSize
    readonly property int hexH: pointyTop ? hexSize : Math.round(hexSize * hexRatio)
    readonly property int columns: Math.max(1, Plasmoid.configuration.columns)

    property var slotList: []

    function reloadSlots() {
        try {
            slotList = JSON.parse(Plasmoid.configuration.slots || "[]")
        } catch (e) {
            slotList = []
        }
    }
    Component.onCompleted: reloadSlots()
    Connections {
        target: Plasmoid.configuration
        function onSlotsChanged() { full.reloadSlots() }
    }

    // Flat-top offset-grid formulas (dx = 0.75 * width, dy = height, odd
    // columns dropped by half a row) expressed via the circumradius R so the
    // same formula works for pointy-top after an axis swap — pointy-top is
    // exactly this grid rotated 90°, same as a single hexagon's own vertices.
    // spacing just widens both step distances by a flat pixel amount — not
    // a geometrically exact uniform gap in all six directions, but close
    // enough to see/feel and cheap; 0 reproduces the old flush tiling.
    function slotPos(index) {
        const spacing = Plasmoid.configuration.spacing
        const r = hexSize / 2
        const col = index % columns
        const row = Math.floor(index / columns)
        const colStep = 1.5 * r + spacing
        const rowStep = hexRatio * hexSize + spacing
        const lx = col * colStep
        const ly = row * rowStep + (col % 2 === 1 ? rowStep / 2 : 0)
        return pointyTop ? Qt.point(ly, lx) : Qt.point(lx, ly)
    }

    readonly property int gridWidth: {
        let maxX = 0
        for (let i = 0; i < slotList.length; i++)
            maxX = Math.max(maxX, slotPos(i).x + hexW)
        return Math.max(hexW, Math.round(maxX))
    }
    readonly property int gridHeight: {
        let maxY = 0
        for (let i = 0; i < slotList.length; i++)
            maxY = Math.max(maxY, slotPos(i).y + hexH)
        return Math.max(hexH, Math.round(maxY))
    }

    implicitWidth: gridWidth
    implicitHeight: gridHeight

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

    Plasma5Support.DataSource {
        id: executable
        engine: "executable"
        connectedSources: []
        onNewData: (sourceName, data) => disconnectSource(sourceName)
    }

    Repeater {
        model: full.slotList

        Item {
            id: slot

            required property var modelData
            required property int index

            readonly property point pos: full.slotPos(index)
            x: pos.x
            y: pos.y
            width: full.hexW
            height: full.hexH

            Image {
                id: icon
                anchors.fill: parent
                fillMode: Image.PreserveAspectCrop
                source: slot.modelData.image || ""
                smooth: true
                mipmap: true
                opacity: 0
                asynchronous: true
            }

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
                    startX: full.hexPoints(slot.width, slot.height, 0, 0)[0].x
                    startY: full.hexPoints(slot.width, slot.height, 0, 0)[0].y
                    PathPolyline {
                        path: full.hexPoints(slot.width, slot.height, 0, 0)
                    }
                }
            }

            // Mask-only stage (see KHoneycomb: maskEnabled + shadowEnabled on
            // the same MultiEffect breaks the mask, a Qt6 limitation) — no
            // shadow stage here at all, unlike KHoneycomb: cells sit flush
            // against their neighbors, so a drop shadow would just darken
            // the touching edge of the next cell over. The bevel alone gives
            // each cell a raised-wax-wall look without that side effect.
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

            ShaderEffect {
                anchors.fill: parent
                property variant source: maskedIcon
                property size uItemSize: Qt.size(slot.width, slot.height)
                property point uHexCenter: Qt.point(slot.width / 2, slot.height / 2)
                property real uHexR: full.pointyTop ? slot.height / 2 : slot.width / 2
                property real uPointyTop: full.pointyTop ? 1.0 : 0.0
                property real uBevelWidth: Math.max(6, full.hexW * 0.12)
                property real uStrength: 0.5
                property point uLightDir: Qt.point(-0.4472, -0.8944)
                fragmentShader: "../shaders/bevel.frag.qsb"
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    if (slot.modelData.command)
                        executable.connectSource(slot.modelData.command)
                }
            }
        }
    }
}

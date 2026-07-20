/*
 * SPDX-FileCopyrightText: 2026 Agundur <info@agundur.de>
 *
 * SPDX-License-Identifier: GPL-2.0-only OR GPL-3.0-only OR LicenseRef-KDE-Accepted-GPL
 */

import QtQuick
import QtQuick.Controls as QtControls
import QtQuick.Dialogs
import QtQuick.Layouts
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

    // Desktop free-resize sets width/height directly (no ratio kept), so the
    // whole honeycomb is scaled up/down to fill whatever box we're given —
    // same idea as KHoneycomb's own live-resize tracking, just done as one
    // uniform transform on the grid wrapper instead of recomputing every
    // cell's geometry.
    readonly property real renderScale: (width > 0 && height > 0 && gridWidth > 0 && gridHeight > 0)
        ? Math.min(width / gridWidth, height / gridHeight)
        : 1

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

    // Right-click editor for a single slot's icon/command — a structural
    // edit (removing/reordering slots) stays in the full config dialog,
    // this is just the quick "change what this one cell launches" path.
    function openSlotEditor(index) {
        const s = full.slotList[index] || { image: "", command: "" }
        slotEditPopup.targetIndex = index
        slotEditImage.text = s.image || ""
        slotEditCommand.text = s.command || ""
        slotEditPopup.open()
    }

    function writeSlot(index, image, command) {
        const arr = JSON.parse(JSON.stringify(full.slotList))
        if (index < 0 || index >= arr.length)
            return
        arr[index] = { image: image, command: command }
        Plasmoid.configuration.slots = JSON.stringify(arr)
    }

    QtControls.Popup {
        id: slotEditPopup
        property int targetIndex: -1
        modal: true
        focus: true
        x: (full.width - width) / 2
        y: (full.height - height) / 2

        ColumnLayout {
            RowLayout {
                QtControls.TextField {
                    id: slotEditImage
                    Layout.preferredWidth: 220
                    placeholderText: i18n("Icon image")
                }
                QtControls.Button {
                    icon.name: "document-open"
                    onClicked: slotEditImageDialog.open()
                }
            }
            QtControls.TextField {
                id: slotEditCommand
                Layout.fillWidth: true
                placeholderText: i18n("Command")
            }
            RowLayout {
                QtControls.Button {
                    text: i18n("Save")
                    onClicked: {
                        full.writeSlot(slotEditPopup.targetIndex, slotEditImage.text, slotEditCommand.text)
                        slotEditPopup.close()
                    }
                }
                QtControls.Button {
                    text: i18n("Clear")
                    onClicked: {
                        full.writeSlot(slotEditPopup.targetIndex, "", "")
                        slotEditPopup.close()
                    }
                }
                QtControls.Button {
                    text: i18n("Cancel")
                    onClicked: slotEditPopup.close()
                }
            }
        }

        FileDialog {
            id: slotEditImageDialog
            title: i18n("Choose an icon image")
            nameFilters: [i18n("Images (*.png *.jpg *.jpeg *.webp *.svg)")]
            onAccepted: slotEditImage.text = selectedFile.toString().replace("file://", "")
        }
    }

    Item {
        id: grid
        width: full.gridWidth
        height: full.gridHeight
        scale: full.renderScale
        transformOrigin: Item.TopLeft

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

                // Mask-only stage (see KHoneycomb: maskEnabled + shadowEnabled
                // on the same MultiEffect breaks the mask, a Qt6 limitation)
                // — no shadow stage here at all, unlike KHoneycomb: cells sit
                // flush against their neighbors, so a drop shadow would just
                // darken the touching edge of the next cell over. The bevel
                // alone gives each cell a raised-wax-wall look without that
                // side effect.
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
                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                    onClicked: (mouse) => {
                        if (mouse.button === Qt.RightButton) {
                            full.openSlotEditor(slot.index)
                        } else if (slot.modelData.command) {
                            executable.connectSource(slot.modelData.command)
                        }
                    }
                }
            }
        }
    }
}

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
import org.kde.kirigami as Kirigami

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
    // columns setting: 0 = auto (pick whatever column count best matches
    // the widget's current width/height ratio, so dragging wide -> more
    // columns/fewer rows and dragging tall -> fewer columns/more rows),
    // >0 = fixed override, same as before.
    readonly property int columns: Plasmoid.configuration.columns > 0
        ? Plasmoid.configuration.columns
        : full.bestColumns()

    property var slotList: []

    // Same offset-grid extent math as gridWidth/gridHeight below, but for
    // a hypothetical column count c instead of the live full.columns -
    // used to score candidates in bestColumns() without a binding loop.
    function gridExtentFor(c) {
        const spacing = Plasmoid.configuration.spacing
        const r = hexSize / 2
        const colStep = 1.5 * r + spacing
        const rowStep = hexRatio * hexSize + spacing
        let maxX = 0, maxY = 0
        for (let i = 0; i < slotList.length; i++) {
            const col = i % c
            const row = Math.floor(i / c)
            const lx = col * colStep
            const ly = row * rowStep + (col % 2 === 1 ? rowStep / 2 : 0)
            maxX = Math.max(maxX, lx + hexW)
            maxY = Math.max(maxY, ly + hexH)
        }
        const w = Math.max(hexW, Math.round(maxX))
        const h = Math.max(hexH, Math.round(maxY))
        return pointyTop ? Qt.point(h, w) : Qt.point(w, h)
    }

    function bestColumns() {
        const n = slotList.length
        if (n <= 1) return 1
        // No live size yet (not placed/resized): fall back to a roughly
        // square arrangement instead of reading full.width/height, which
        // would still be 0 at this point.
        if (full.width <= 0 || full.height <= 0) return Math.max(1, Math.round(Math.sqrt(n)))
        const targetRatio = full.width / full.height
        let bestC = 1, bestDiff = Infinity
        for (let c = 1; c <= n; c++) {
            const ext = full.gridExtentFor(c)
            const diff = Math.abs(ext.x / ext.y - targetRatio)
            if (diff < bestDiff) { bestDiff = diff; bestC = c }
        }
        return bestC
    }

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

    // Fallback label when a slot has a command but no icon image — first
    // word of the command, path stripped, capitalized.
    function labelFor(command) {
        if (!command)
            return ""
        let first = command.trim().split(/\s+/)[0]
        first = first.split("/").pop()
        return first.length ? first.charAt(0).toUpperCase() + first.slice(1) : ""
    }

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
        const s = full.slotList[index] || { image: "", command: "", zoom: 100, color: "" }
        slotEditPopup.targetIndex = index
        slotEditImage.text = s.image || ""
        slotEditCommand.text = s.command || ""
        slotEditZoom.value = s.zoom || 100
        slotEditPopup.slotColor = s.color || ""
        slotEditPopup.open()
    }

    function writeSlot(index, image, command, zoom, color) {
        const arr = JSON.parse(JSON.stringify(full.slotList))
        if (index < 0 || index >= arr.length)
            return
        arr[index] = { image: image, command: command, zoom: zoom || 100, color: color || "" }
        Plasmoid.configuration.slots = JSON.stringify(arr)
    }

    // Drag-to-reorder: dropX/dropY are the dragged cell's raw position in
    // grid-local coordinates (same space slotPos() works in) at release —
    // find whichever slot's normal position is closest to that point and
    // move the dragged slot there (list move, not a straight swap, so the
    // rest shift over like reordering a list). Writing back to
    // configuration.slots reassigns slotList, which the Repeater treats as
    // a fresh model, so every delegate (including the dragged one) gets its
    // x/y binding re-established automatically — no manual Qt.binding()
    // restore needed after the imperative drag.
    function dropSlot(fromIndex, dropX, dropY) {
        const dc = Qt.point(dropX + full.hexW / 2, dropY + full.hexH / 2)
        let nearest = fromIndex, nearestDist = Infinity
        for (let i = 0; i < full.slotList.length; i++) {
            const p = full.slotPos(i)
            const dx = p.x + full.hexW / 2 - dc.x
            const dy = p.y + full.hexH / 2 - dc.y
            const dist = dx * dx + dy * dy
            if (dist < nearestDist) { nearestDist = dist; nearest = i }
        }
        if (nearest === fromIndex)
            return
        const arr = JSON.parse(JSON.stringify(full.slotList))
        const moved = arr.splice(fromIndex, 1)[0]
        arr.splice(nearest, 0, moved)
        Plasmoid.configuration.slots = JSON.stringify(arr)
    }

    QtControls.Popup {
        id: slotEditPopup
        property int targetIndex: -1
        property string slotColor: ""
        modal: true
        focus: true
        x: (full.width - width) / 2
        y: (full.height - height) / 2

        ColumnLayout {
            // Drag handle: popup starts centered on the clicked hex, but
            // stays wherever you drag it to — including across edits of
            // other slots — so it doesn't have to be moved out of the way
            // over and over while working through several cells.
            MouseArea {
                Layout.fillWidth: true
                Layout.preferredHeight: dragLabel.implicitHeight
                cursorShape: Qt.SizeAllCursor
                property point startMouse
                property point startPopup
                onPressed: (mouse) => {
                    startMouse = Qt.point(mouse.x, mouse.y)
                    startPopup = Qt.point(slotEditPopup.x, slotEditPopup.y)
                }
                onPositionChanged: (mouse) => {
                    if (pressed) {
                        slotEditPopup.x = startPopup.x + (mouse.x - startMouse.x)
                        slotEditPopup.y = startPopup.y + (mouse.y - startMouse.y)
                    }
                }
                QtControls.Label {
                    id: dragLabel
                    anchors.centerIn: parent
                    text: "⠿ " + i18n("Edit hexagon") + " ⠿"
                    opacity: 0.7
                }
            }
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
                QtControls.Label { text: i18n("Zoom:") }
                QtControls.Slider {
                    id: slotEditZoom
                    Layout.fillWidth: true
                    from: 100
                    to: 300
                    stepSize: 10
                }
                QtControls.Label { text: Math.round(slotEditZoom.value) + "%" }
            }
            RowLayout {
                QtControls.Label { text: i18n("Color:") }
                Rectangle {
                    width: Kirigami.Units.gridUnit * 1.5
                    height: Kirigami.Units.gridUnit * 1.5
                    radius: 4
                    color: slotEditPopup.slotColor || Plasmoid.configuration.placeholderColor
                    border.color: "#80808080"
                    border.width: 1
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: slotEditColorDialog.open()
                    }
                }
                QtControls.Button {
                    text: i18n("Transparent")
                    onClicked: slotEditPopup.slotColor = "#00000000"
                }
                QtControls.Button {
                    text: i18n("Default")
                    onClicked: slotEditPopup.slotColor = ""
                }
            }
            RowLayout {
                QtControls.Button {
                    text: i18n("Save")
                    onClicked: full.writeSlot(slotEditPopup.targetIndex, slotEditImage.text, slotEditCommand.text, slotEditZoom.value, slotEditPopup.slotColor)
                }
                QtControls.Button {
                    text: i18n("Clear")
                    onClicked: full.writeSlot(slotEditPopup.targetIndex, "", "", 100, "")
                }
                QtControls.Button {
                    text: i18n("Close")
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

        ColorDialog {
            id: slotEditColorDialog
            selectedColor: slotEditPopup.slotColor || Plasmoid.configuration.placeholderColor
            options: ColorDialog.ShowAlphaChannel
            onAccepted: slotEditPopup.slotColor = selectedColor.toString()
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

                // Placeholder color always sits behind the icon (not just
                // when there's no image) so an image's transparent parts —
                // corners left over after zoom, round logos, etc — show the
                // configured color instead of raw desktop background. Pick
                // an alpha-0 color in the config to turn this off.
                Item {
                    id: iconContent
                    anchors.fill: parent
                    opacity: 0

                    Rectangle {
                        id: placeholder
                        anchors.fill: parent
                        color: slot.modelData.color || Plasmoid.configuration.placeholderColor
                    }

                    Text {
                        anchors.fill: parent
                        anchors.margins: full.hexW * 0.12
                        visible: slot.modelData.image === "" && slot.modelData.command !== ""
                        text: full.labelFor(slot.modelData.command)
                        color: Plasmoid.configuration.textColor
                        font.pixelSize: Plasmoid.configuration.textSize
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        wrapMode: Text.WordWrap
                        elide: Text.ElideRight
                    }

                    // Zoom lets an image with a lot of transparent padding
                    // around the actual artwork (typical for 512x512 system
                    // icons) be cropped in on its center to fill the hex —
                    // the outer Item stays fixed size and clips, so the
                    // Image can be scaled up past it without spilling into
                    // neighbors.
                    Item {
                        id: iconClip
                        anchors.fill: parent
                        clip: true
                        visible: slot.modelData.image !== ""

                        Image {
                            id: icon
                            anchors.fill: parent
                            fillMode: Image.PreserveAspectCrop
                            source: slot.modelData.image || ""
                            smooth: true
                            mipmap: true
                            asynchronous: true
                            scale: (slot.modelData.zoom || 100) / 100
                        }
                    }
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
                    source: iconContent
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
                    drag.axis: Drag.XAndYAxis
                    // Only left-button presses drag — a right-press never
                    // sets a drag.target, so right-click still opens the
                    // editor untouched. QtQuick already skips onClicked
                    // when a real drag happened, so left-click-to-launch
                    // and drag-to-reorder don't fight over the same button.
                    onPressed: (mouse) => {
                        drag.target = mouse.button === Qt.LeftButton ? slot : null
                    }
                    onReleased: {
                        if (drag.active)
                            full.dropSlot(slot.index, slot.x, slot.y)
                        drag.target = null
                    }
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

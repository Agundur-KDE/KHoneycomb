/*
 * SPDX-FileCopyrightText: 2026 Agundur <info@agundur.de>
 *
 * SPDX-License-Identifier: GPL-2.0-only OR GPL-3.0-only OR LicenseRef-KDE-Accepted-GPL
 */

import QtQuick
import QtQuick.Window
import QtQuick.Controls as QtControls
import QtQuick.Dialogs
import QtQuick.Layouts
import QtQuick.Shapes
import QtQuick.Effects
import org.kde.plasma.plasmoid
import org.kde.plasma.plasma5support as Plasma5Support
import org.kde.kirigami as Kirigami
import org.kde.iconthemes as KIconThemes

Item {
    id: full

    readonly property real hexRatio: 0.8660254
    readonly property bool pointyTop: Plasmoid.configuration.orientation === "pointy"
    readonly property int hexSize: Plasmoid.configuration.hexSize
    readonly property int hexW: pointyTop ? Math.round(hexSize * hexRatio) : hexSize
    readonly property int hexH: pointyTop ? hexSize : Math.round(hexSize * hexRatio)
    readonly property real bevelStrength: Plasmoid.configuration.bevelStrength / 100
    // columns setting: 0 = auto (pick whatever column count best matches
    // the widget's current width/height ratio, so dragging wide -> more
    // columns/fewer rows and dragging tall -> fewer columns/more rows),
    // >0 = fixed override, same as before.
    readonly property int columns: Plasmoid.configuration.columns > 0
        ? Plasmoid.configuration.columns
        : full.bestColumns()

    property var slotList: []

    // Trash counts as one more slot for every layout calculation (column
    // balancing AND position) when enabled, so it always lands at a
    // consistent, non-overlapping "next" tessellation spot instead of the
    // column-count math being optimized for N real hexes while positions
    // get computed for N+1 (that mismatch was the actual cause of an
    // earlier overlap bug — the fix is keeping both in sync, not avoiding
    // the shared position formula).
    readonly property int layoutSlotCount: slotList.length + (Plasmoid.configuration.showTrash ? 1 : 0)

    // Same offset-grid extent math as gridWidth/gridHeight below, but for
    // a hypothetical column count c instead of the live full.columns -
    // used to score candidates in bestColumns() without a binding loop.
    function gridExtentFor(c) {
        const spacing = Plasmoid.configuration.spacing
        const r = hexSize / 2
        const colStep = 1.5 * r + spacing
        const rowStep = hexRatio * hexSize + spacing
        let maxX = 0, maxY = 0
        for (let i = 0; i < layoutSlotCount; i++) {
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
        const n = layoutSlotCount
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

    // Trash's own position is just the next slot in the same tessellation
    // real hexes use — consistent now that layoutSlotCount (above) keeps
    // column-balancing and position math in sync.
    readonly property point trashPos: slotPos(slotList.length)

    readonly property int gridWidth: {
        let maxX = 0
        for (let i = 0; i < layoutSlotCount; i++)
            maxX = Math.max(maxX, slotPos(i).x + hexW)
        return Math.max(hexW, Math.round(maxX))
    }
    readonly property int gridHeight: {
        let maxY = 0
        for (let i = 0; i < layoutSlotCount; i++)
            maxY = Math.max(maxY, slotPos(i).y + hexH)
        return Math.max(hexH, Math.round(maxY))
    }

    implicitWidth: gridWidth + Plasmoid.configuration.gridPadding * 2
    implicitHeight: gridHeight + Plasmoid.configuration.gridPadding * 2
    // A freshly-placed desktop widget otherwise defaults to a small fixed
    // icon-grid cell (~96x96) regardless of implicitWidth/Height, squashing
    // everything down until the user manually resizes it once — give the
    // containment an explicit size hint so it starts at the right size.
    Layout.preferredWidth: gridWidth + Plasmoid.configuration.gridPadding * 2
    Layout.preferredHeight: gridHeight + Plasmoid.configuration.gridPadding * 2

    // Desktop free-resize sets width/height directly (no ratio kept), so the
    // whole honeycomb is scaled up/down to fill whatever box we're given —
    // same idea as KHoneycomb's own live-resize tracking, just done as one
    // uniform transform on the grid wrapper instead of recomputing every
    // cell's geometry. gridPadding shrinks the box the grid scales into on
    // both sides, leaving it as empty space around the honeycomb instead.
    readonly property real renderScale: (width > 0 && height > 0 && gridWidth > 0 && gridHeight > 0)
        ? Math.max(0.05, Math.min((width - Plasmoid.configuration.gridPadding * 2) / gridWidth, (height - Plasmoid.configuration.gridPadding * 2) / gridHeight))
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

    // Resolves a bare icon-theme name (e.g. "okular", as returned by
    // KIconThemes.IconDialog for a theme pick rather than a custom file)
    // to an actual file path via kiconfinder6 — the same lookup KDE's own
    // apps use, more reliable than guessing at a QML image-provider URL
    // scheme (image://icontheme/... confirmed NOT to resolve here).
    Plasma5Support.DataSource {
        id: iconResolver
        engine: "executable"
        connectedSources: []
        onNewData: (sourceName, data) => {
            disconnectSource(sourceName)
            const out = (data["stdout"] || "").trim()
            if (out)
                slotEditImage.text = out
        }
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
        slotEditPopup.origImage = s.image || ""
        slotEditPopup.origCommand = s.command || ""
        slotEditPopup.origZoom = s.zoom || 100
        slotEditPopup.origColor = s.color || ""
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
        property string origImage: ""
        property string origCommand: ""
        property real origZoom: 100
        property string origColor: ""
        property bool hasChanges: false
        modal: true
        focus: true
        x: (full.width - width) / 2
        y: (full.height - height) / 2

        // Polled instead of a live binding on slotEditImage.text/slotEditCommand.text:
        // pasting via the native Qt text-field context menu doesn't reliably fire
        // textChanged in this environment (confirmed — Save stayed disabled after a
        // paste, only the next keypress picked up the already-pasted value), so a
        // pure dependency-tracked binding can miss it. Polling re-reads the actual
        // current text every tick regardless of whether a notify signal fired.
        Timer {
            interval: 300
            running: slotEditPopup.opened
            repeat: true
            triggeredOnStart: true
            onTriggered: slotEditPopup.hasChanges = slotEditImage.text !== slotEditPopup.origImage
                || slotEditCommand.text !== slotEditPopup.origCommand
                || slotEditZoom.value !== slotEditPopup.origZoom
                || slotEditPopup.slotColor !== slotEditPopup.origColor
        }

        function doSave() {
            if (!hasChanges)
                return
            full.writeSlot(targetIndex, slotEditImage.text, slotEditCommand.text, slotEditZoom.value, slotColor)
            origImage = slotEditImage.text
            origCommand = slotEditCommand.text
            origZoom = slotEditZoom.value
            origColor = slotColor
            hasChanges = false
        }
        Keys.onReturnPressed: doSave()
        Keys.onEnterPressed: doSave()

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
                    onAccepted: slotEditPopup.doSave()
                }
                QtControls.Button {
                    icon.name: "document-open"
                    onClicked: slotEditIconDialog.open()
                }
            }
            QtControls.TextField {
                id: slotEditCommand
                Layout.fillWidth: true
                placeholderText: i18n("Command")
                onAccepted: slotEditPopup.doSave()
            }
            RowLayout {
                QtControls.Label { text: i18n("Zoom:") }
                QtControls.Slider {
                    id: slotEditZoom
                    Layout.fillWidth: true
                    from: 40
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
                    highlighted: true
                    enabled: slotEditPopup.hasChanges
                    onClicked: slotEditPopup.doSave()
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

        // KIconThemes' picker instead of a plain file dialog — browse by
        // category/search through installed theme icons, with a "Browse…"
        // button of its own for a custom file, so this covers both cases
        // the old plain FileDialog handled plus proper icon browsing.
        KIconThemes.IconDialog {
            id: slotEditIconDialog
            // Picking a theme icon (as opposed to "Browse…" for a custom
            // file) returns a bare name like "okular", not a path — Image
            // can't load that directly, needs resolving to a real file
            // first (see iconResolver above). A custom-file pick already
            // comes back as an absolute path, nothing to resolve.
            onIconNameChanged: {
                if (iconName.startsWith("/"))
                    slotEditImage.text = iconName
                else
                    iconResolver.connectSource("kiconfinder6 '" + iconName + "'")
            }
        }

        ColorDialog {
            id: slotEditColorDialog
            selectedColor: slotEditPopup.slotColor || Plasmoid.configuration.placeholderColor
            options: ColorDialog.ShowAlphaChannel
            onAccepted: slotEditPopup.slotColor = selectedColor.toString()
        }
    }

    Image {
        anchors.fill: parent
        visible: Plasmoid.configuration.backgroundImage !== ""
        source: Plasmoid.configuration.backgroundImage
        fillMode: Plasmoid.configuration.backgroundFillMode === "fit" ? Image.PreserveAspectFit
            : Plasmoid.configuration.backgroundFillMode === "stretch" ? Image.Stretch
            : Image.PreserveAspectCrop
        asynchronous: true
        smooth: true
    }

    Rectangle {
        anchors.fill: parent
        visible: Plasmoid.configuration.backgroundImage !== "" && Plasmoid.configuration.backgroundDim > 0
        color: "black"
        opacity: Plasmoid.configuration.backgroundDim / 100
    }

    Item {
        id: grid
        x: Plasmoid.configuration.gridPadding
        y: Plasmoid.configuration.gridPadding
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

                // Raised look (positive bevelStrength): two outer shadows,
                // dark down-right + light up-left, both zero-opacity when
                // sunken/flat. Not needed for sunken, which uses the inset
                // bevel band below instead.
                Loader {
                    id: shadowLoader
                    anchors.fill: parent
                    visible: full.bevelStrength > 0
                    sourceComponent: shadowComponent

                    Connections {
                        target: full
                        function onBevelStrengthChanged() {
                            shadowLoader.active = false
                            shadowLoader.active = true
                        }
                        function onRenderScaleChanged() {
                            shadowLoader.active = false
                            shadowLoader.active = true
                        }
                    }
                }

                Component {
                    id: shadowComponent
                    Item {
                        anchors.fill: parent

                        Shape {
                            id: shadowShape
                            width: parent.width
                            height: parent.height
                            // Floats higher (bigger gap) the stronger the
                            // setting — offset and blur spread grow together
                            // with strength, not just opacity, so it reads
                            // as "further from the surface", not just "darker".
                            x: Math.max(3, full.hexW * (0.04 + 0.08 * Math.max(0, full.bevelStrength)))
                            y: Math.max(4, full.hexH * (0.05 + 0.1 * Math.max(0, full.bevelStrength)))
                            layer.enabled: true
                            layer.smooth: true
                            layer.textureSize: Qt.size(Math.round(width * full.renderScale * Screen.devicePixelRatio), Math.round(height * full.renderScale * Screen.devicePixelRatio))
                            ShapePath {
                                fillColor: "black"
                                strokeColor: "transparent"
                                startX: full.hexPoints(slot.width, slot.height, 0, 0)[0].x
                                startY: full.hexPoints(slot.width, slot.height, 0, 0)[0].y
                                PathPolyline {
                                    path: full.hexPoints(slot.width, slot.height, 0, 0)
                                }
                            }
                        }

                        MultiEffect {
                            anchors.fill: shadowShape
                            visible: full.bevelStrength > 0
                            opacity: full.bevelStrength > 0 ? 0.45 : 0
                            source: shadowShape
                            blurEnabled: true
                            blur: 0.35
                            blurMax: 16 + 20 * Math.max(0, full.bevelStrength)
                        }
                    }
                }

                Loader {
                    id: highlightLoader
                    anchors.fill: parent
                    visible: full.bevelStrength > 0
                    sourceComponent: highlightComponent

                    Connections {
                        target: full
                        function onBevelStrengthChanged() {
                            highlightLoader.active = false
                            highlightLoader.active = true
                        }
                        function onRenderScaleChanged() {
                            highlightLoader.active = false
                            highlightLoader.active = true
                        }
                    }
                }

                Component {
                    id: highlightComponent
                    Item {
                        anchors.fill: parent

                        Shape {
                            id: highlightShape
                            width: parent.width
                            height: parent.height
                            x: -Math.max(3, full.hexW * (0.04 + 0.08 * Math.max(0, full.bevelStrength)))
                            y: -Math.max(4, full.hexH * (0.05 + 0.1 * Math.max(0, full.bevelStrength)))
                            layer.enabled: true
                            layer.smooth: true
                            layer.textureSize: Qt.size(Math.round(width * full.renderScale * Screen.devicePixelRatio), Math.round(height * full.renderScale * Screen.devicePixelRatio))
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

                        MultiEffect {
                            anchors.fill: highlightShape
                            source: highlightShape
                            visible: full.bevelStrength > 0
                            opacity: full.bevelStrength > 0 ? 0.07 : 0
                            blurEnabled: true
                            blur: 0.95
                            blurMax: 24 + 20 * Math.max(0, full.bevelStrength)
                        }

                        MultiEffect {
                            anchors.fill: highlightShape
                            source: highlightShape
                            visible: full.bevelStrength > 0
                            opacity: full.bevelStrength > 0 ? 0.15 : 0
                            blurEnabled: true
                            blur: 0.8
                            blurMax: 16 + 12 * Math.max(0, full.bevelStrength)
                        }
                    }
                }

                // icon/mask stack is Loader-wrapped and fully recreated on
                // renderScale change instead of just toggling layer.enabled
                // in place — toggling wasn't reliable here (confirmed: the
                // handler fires correctly per diagnostic logging, but the
                // mask stayed stale/unmasked, plain white hex, until some
                // unrelated repaint like dragging a slot). Full recreation
                // is the same, already-proven-reliable fix used below for
                // the bevel ShaderEffect.
                Loader {
                    id: iconMaskLoader
                    anchors.fill: parent
                    sourceComponent: iconMaskComponent

                    Connections {
                        target: full
                        function onRenderScaleChanged() {
                            iconMaskLoader.active = false
                            iconMaskLoader.active = true
                        }
                    }
                }

                Component {
                    id: iconMaskComponent
                    Item {
                        anchors.fill: parent
                        // maskedIcon's own id isn't reachable from outside
                        // this Loader-instantiated Component (confirmed:
                        // "maskedIcon is not defined" from the bevel
                        // ShaderEffect below) — expose it explicitly instead.
                        property alias maskedIconRef: maskedIcon

                        // Placeholder color always sits behind the icon (not
                        // just when there's no image) so an image's
                        // transparent parts — corners left over after zoom,
                        // round logos, etc — show the configured color
                        // instead of raw desktop background. Pick an alpha-0
                        // color in the config to turn this off.
                        Item {
                            id: iconContent
                            anchors.fill: parent
                            opacity: 0
                            // without its own layer here, MultiEffect's
                            // source: capture below happens at this Item's
                            // native small size — throwing away all the
                            // extra resolution the Image inside rasterizes
                            // at via its own sourceSize
                            layer.enabled: true
                            layer.smooth: true
                            layer.textureSize: Qt.size(Math.round(width * full.renderScale * Screen.devicePixelRatio), Math.round(height * full.renderScale * Screen.devicePixelRatio))

                            Rectangle {
                                id: placeholder
                                anchors.fill: parent
                                visible: color.a > 0
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

                            // Zoom lets an image with a lot of transparent
                            // padding around the actual artwork (typical for
                            // 512x512 system icons) be cropped in on its
                            // center to fill the hex — the outer Item stays
                            // fixed size and clips, so the Image can be
                            // scaled up past it without spilling into
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
                                    // without this, SVG icons rasterize at a
                                    // small default size and get blurrily
                                    // upscaled from there — before
                                    // renderScale/textureSize below even
                                    // come into play
                                    sourceSize: Qt.size(Math.round(width * full.renderScale * Screen.devicePixelRatio * scale), Math.round(height * full.renderScale * Screen.devicePixelRatio * scale))
                                }
                            }
                        }

                        Shape {
                            id: hexMask
                            anchors.fill: parent
                            opacity: 0
                            layer.enabled: true
                            layer.smooth: true
                            // layer textures snapshot at this item's native
                            // pixel size; the whole grid gets scaled up
                            // afterwards by renderScale (see gridWrapper),
                            // so without this the mask/bevel/icon textures
                            // get blurrily stretched right along with it.
                            layer.textureSize: Qt.size(Math.round(width * full.renderScale * Screen.devicePixelRatio), Math.round(height * full.renderScale * Screen.devicePixelRatio))
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

                        // Mask-only stage (see KHoneycomb: maskEnabled +
                        // shadowEnabled on the same MultiEffect breaks the
                        // mask, a Qt6 limitation) — no shadow stage here at
                        // all, unlike KHoneycomb: cells sit flush against
                        // their neighbors, so a drop shadow would just
                        // darken the touching edge of the next cell over.
                        // The bevel alone gives each cell a raised-wax-wall
                        // look without that side effect.
                        MultiEffect {
                            id: maskedIcon
                            anchors.fill: parent
                            opacity: 0
                            layer.enabled: true
                            layer.smooth: true
                            layer.textureSize: Qt.size(Math.round(width * full.renderScale * Screen.devicePixelRatio), Math.round(height * full.renderScale * Screen.devicePixelRatio))
                            source: iconContent
                            maskEnabled: true
                            maskSource: hexMask
                            maskThresholdMin: 0.5
                            maskSpreadAtMin: 1.0
                        }
                    }
                }

                // A plain ShaderEffect here never repaints when only
                // uStrength changes (confirmed with a guaranteed-fresh
                // plasmoidviewer load, config-change signal firing correctly
                // per diagnostic logging, zero visual update regardless) —
                // forcing a full reload via Loader.active sidesteps whatever
                // dirty-tracking is failing, since it recreates the item
                // from scratch instead of hoping it repaints in place.
                Loader {
                    id: bevelLoader
                    anchors.fill: parent
                    sourceComponent: bevelComponent

                    Connections {
                        target: full
                        function onBevelStrengthChanged() {
                            bevelLoader.active = false
                            bevelLoader.active = true
                        }
                        function onRenderScaleChanged() {
                            bevelLoader.active = false
                            bevelLoader.active = true
                        }
                    }
                }

                Component {
                    id: bevelComponent
                    ShaderEffect {
                        anchors.fill: parent
                        property variant source: iconMaskLoader.item ? iconMaskLoader.item.maskedIconRef : null
                        property size uItemSize: Qt.size(slot.width, slot.height)
                        property point uHexCenter: Qt.point(slot.width / 2, slot.height / 2)
                        property real uHexR: full.pointyTop ? slot.height / 2 : slot.width / 2
                        property real uPointyTop: full.pointyTop ? 1.0 : 0.0
                        // Sign of bevelStrength picks direction (negative =
                        // sunken/inset, wide band + light-bottom-right/dark-
                        // top-left; positive = raised, narrower band + the
                        // opposite light direction), magnitude picks how
                        // strong either look is. 0 = flat either way.
                        // Sunken band grows with strength (small = tight/
                        // dark near the edge, large = wide/soft toward the
                        // center), same "size grows, not just darkness"
                        // idea as the raised shadow's offset.
                        property real uBevelWidth: full.bevelStrength < 0 ? Math.max(6, full.hexW * Math.min(0.25, 0.1 + 0.15 * Math.abs(full.bevelStrength))) : Math.max(6, full.hexW * 0.12)
                        property real uStrength: full.bevelStrength < 0 ? Math.min(1.8, 0.5 + Math.abs(full.bevelStrength) * 2) : full.bevelStrength * 3
                        property point uLightDir: full.bevelStrength < 0 ? Qt.point(0.4472, 0.8944) : Qt.point(-0.4472, -0.8944)
                        fragmentShader: "../shaders/bevel.frag.qsb"
                    }
                }

                // Thin rim stroke in the slot's own color, right at the true
                // hex edge — without it, the wide sunken bevel band fades to
                // near-black right up to the boundary between two hexes,
                // losing the crisp edge definition between them.
                Shape {
                    anchors.fill: parent
                    antialiasing: true
                    visible: full.bevelStrength < 0 && Qt.color(slot.modelData.color || Plasmoid.configuration.placeholderColor).a > 0
                    opacity: full.bevelStrength < 0 ? 1 : 0
                    ShapePath {
                        fillColor: "transparent"
                        strokeColor: slot.modelData.color || Plasmoid.configuration.placeholderColor
                        strokeWidth: Math.max(1, full.hexW * 0.015)
                        startX: full.hexPoints(slot.width, slot.height, 0, 0)[0].x
                        startY: full.hexPoints(slot.width, slot.height, 0, 0)[0].y
                        PathPolyline {
                            path: full.hexPoints(slot.width, slot.height, 0, 0).concat([full.hexPoints(slot.width, slot.height, 0, 0)[0]])
                        }
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                    drag.axis: Drag.XAndYAxis
                    hoverEnabled: true
                    QtControls.ToolTip.visible: containsMouse && slot.modelData.command
                    QtControls.ToolTip.text: full.labelFor(slot.modelData.command)
                    QtControls.ToolTip.delay: Kirigami.Units.toolTipDelay
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

        // Trash rendered as one more hex-grid citizen, at slotPos(slotList
        // .length) — the exact next tessellation position, same
        // spacing/offset math as every real hex, inside the same `grid`
        // Item so it's subject to the identical scale transform. No
        // separately reserved block: gridWidth/gridHeight already account
        // for this position via slotCountForLayout above, so it just folds
        // into the natural honeycomb shape instead of adding a rectangular
        // strip. The actual feature is the DropArea below: real external
        // drag-and-drop (files dragged in from Dolphin), unrelated to the
        // hexagons' own internal drag.target-based reorder mechanism.
        Item {
            id: trashSlot
            visible: Plasmoid.configuration.showTrash
            readonly property point pos: full.trashPos
            x: pos.x
            y: pos.y
            width: full.hexW
            height: full.hexH

            Rectangle {
                anchors.fill: parent
                radius: width * 0.15
                color: trashDrop.containsDrag ? "#40ffffff" : "#20000000"
                border.color: trashDrop.containsDrag ? "#ffffff" : "transparent"
                border.width: 2
            }

            Kirigami.Icon {
                anchors.fill: parent
                anchors.margins: parent.width * 0.2
                source: "user-trash"
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                hoverEnabled: true
                QtControls.ToolTip.visible: containsMouse
                QtControls.ToolTip.text: i18n("Open trash · drop files here to delete them")
                QtControls.ToolTip.delay: Kirigami.Units.toolTipDelay
                onClicked: executable.connectSource("dolphin trash:/")
            }

            DropArea {
                id: trashDrop
                anchors.fill: parent
                onDropped: (drop) => {
                    if (drop.hasUrls) {
                        const quoted = drop.urls.map(u => "'" + String(u).replace(/'/g, "'\\''") + "'").join(" ")
                        executable.connectSource("kioclient5 move " + quoted + " trash:/")
                    }
                    drop.accept()
                }
            }
        }
    }
}

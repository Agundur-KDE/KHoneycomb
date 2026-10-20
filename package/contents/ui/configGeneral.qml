/*
 * SPDX-FileCopyrightText: 2026 Agundur <info@agundur.de>
 *
 * SPDX-License-Identifier: GPL-2.0-only OR GPL-3.0-only OR LicenseRef-KDE-Accepted-GPL
 */

import QtQuick
import QtCore
import QtQuick.Controls as QtControls
import QtQuick.Dialogs
import QtQuick.Layouts
import org.kde.kcmutils as KCM
import org.kde.kirigami as Kirigami
import org.kde.plasma.plasma5support as Plasma5Support

KCM.SimpleKCM {
    id: page

    property int cfg_hexSize
    property int cfg_columns
    property int cfg_spacing
    property string cfg_orientation
    property color cfg_placeholderColor
    property string cfg_backgroundImage
    property string cfg_backgroundFillMode
    property int cfg_backgroundDim
    property int cfg_bevelStrength
    property int cfg_gridPadding
    property color cfg_textColor
    property int cfg_textSize
    property string cfg_slots
    property bool backupBusy: false
    property string backupOperation: ""
    property string backupMessage: ""
    property bool backupError: false
    property string pendingBackup: ""
    property string pendingDigest: ""
    property int pendingCount: 0

    readonly property var backupKeys: ["hexSize", "columns", "spacing", "orientation",
        "placeholderColor", "backgroundImage", "backgroundFillMode", "backgroundDim",
        "bevelStrength", "gridPadding", "textColor", "textSize", "slots"]

    function shellQuote(value) {
        return "'" + String(value).replace(/'/g, "'\\''") + "'"
    }

    function runBackup(operation, file, argument) {
        backupMessage = ""
        backupBusy = true
        backupOperation = operation
        const helper = decodeURIComponent(Qt.resolvedUrl("../tools/backup.py").toString().replace(/^file:\/\//, ""))
        let command = "python3 " + shellQuote(helper) + " " + shellQuote(operation) + " " + shellQuote(file)
        if (argument !== undefined)
            command += " " + shellQuote(argument)
        // Linux limits each command argument, including the shell's command string.
        if (encodeURIComponent(command).length > 100000) {
            backupBusy = false
            backupError = true
            backupMessage = i18n("The configuration is too large to export.")
            return
        }
        backupProcess.connectSource(command)
    }

    function exportConfiguration(file) {
        const settings = {}
        for (const key of backupKeys)
            settings[key] = key === "slots" ? JSON.parse(cfg_slots || "[]") : page["cfg_" + key]
        settings.placeholderColor = cfg_placeholderColor.toString()
        settings.textColor = cfg_textColor.toString()
        runBackup("export", file, JSON.stringify(settings))
    }

    Plasma5Support.DataSource {
        id: backupProcess
        engine: "executable"
        connectedSources: []
        onNewData: (sourceName, data) => {
            disconnectSource(sourceName)
            page.backupBusy = false
            try {
                const result = JSON.parse(data.stdout)
                if (!result.ok)
                    throw new Error(result.error)
                page.backupError = false
                if (page.backupOperation === "inspect") {
                    page.pendingCount = result.count
                    page.pendingDigest = result.digest
                    importConfirmation.open()
                } else if (page.backupOperation === "import") {
                    for (const key of page.backupKeys)
                        page["cfg_" + key] = key === "slots" ? JSON.stringify(result.settings.slots) : result.settings[key]
                    page.load()
                    page.backupMessage = i18n("Configuration loaded. Click Apply or OK to keep it.")
                } else {
                    page.backupMessage = i18n("Configuration exported successfully.")
                }
            } catch (error) {
                page.backupError = true
                page.backupMessage = i18n("Backup failed: %1", data.stdout ? error.message : (data.stderr || i18n("Could not start Python 3.")))
            }
        }
    }

    // Slot list is edited via this model, then serialized back to
    // cfg_slots (JSON) on every change — cfg_slots itself is only ever
    // read once, at load, to avoid clobbering in-progress edits.
    ListModel { id: slotModel }

    function load() {
        let parsed = []
        try {
            parsed = JSON.parse(cfg_slots || "[]")
        } catch (e) {
            parsed = []
        }
        slotModel.clear()
        for (const s of parsed)
            slotModel.append({ image: s.image || "", command: s.command || "", zoom: s.zoom || 100, color: s.color || "" })
    }
    Component.onCompleted: load()

    function save() {
        const arr = []
        for (let i = 0; i < slotModel.count; i++) {
            const item = slotModel.get(i)
            arr.push({ image: item.image, command: item.command, zoom: item.zoom, color: item.color })
        }
        cfg_slots = JSON.stringify(arr)
    }

    Kirigami.FormLayout {
        enabled: !page.backupBusy
        QtControls.SpinBox {
            Kirigami.FormData.label: i18n("Hexagon size:")
            from: 40
            to: 400
            stepSize: 10
            value: cfg_hexSize
            onValueModified: cfg_hexSize = value
        }

        QtControls.SpinBox {
            Kirigami.FormData.label: i18n("Columns:")
            from: 0
            to: 20
            value: cfg_columns
            onValueModified: cfg_columns = value
            QtControls.ToolTip.visible: hovered
            QtControls.ToolTip.text: i18n("0 = automatic, fits the widget's current shape")
        }

        QtControls.SpinBox {
            Kirigami.FormData.label: i18n("Spacing:")
            from: 0
            to: 60
            value: cfg_spacing
            onValueModified: cfg_spacing = value
        }

        QtControls.ComboBox {
            Kirigami.FormData.label: i18n("Orientation:")
            model: [i18n("Flat-top"), i18n("Pointy-top")]
            currentIndex: cfg_orientation === "pointy" ? 1 : 0
            onActivated: cfg_orientation = currentIndex === 1 ? "pointy" : "flat"
        }

        RowLayout {
            Kirigami.FormData.label: i18n("Background image:")
            QtControls.TextField {
                Layout.preferredWidth: Kirigami.Units.gridUnit * 12
                placeholderText: i18n("Optional, fills the whole widget behind the hexagons")
                text: cfg_backgroundImage
                onEditingFinished: cfg_backgroundImage = text
            }
            QtControls.Button {
                icon.name: "document-open"
                onClicked: backgroundImageDialog.open()
            }
            QtControls.Button {
                icon.name: "edit-clear"
                onClicked: cfg_backgroundImage = ""
            }
        }

        QtControls.ComboBox {
            Kirigami.FormData.label: i18n("Background fit:")
            model: [i18n("Scale to fill (crop)"), i18n("Scale to fit (letterbox)"), i18n("Stretch")]
            currentIndex: cfg_backgroundFillMode === "fit" ? 1 : cfg_backgroundFillMode === "stretch" ? 2 : 0
            onActivated: cfg_backgroundFillMode = ["fill", "fit", "stretch"][currentIndex]
        }

        QtControls.SpinBox {
            Kirigami.FormData.label: i18n("Darken background:")
            from: 0
            to: 100
            value: cfg_backgroundDim
            onValueModified: cfg_backgroundDim = value
            textFromValue: (value) => value + "%"
            valueFromText: (text) => parseInt(text)
        }

        QtControls.SpinBox {
            Kirigami.FormData.label: i18n("3D bevel strength:")
            from: -150
            to: 150
            value: cfg_bevelStrength
            onValueModified: cfg_bevelStrength = value
            textFromValue: (value) => value + "%"
            valueFromText: (text) => parseInt(text)
            QtControls.ToolTip.visible: hovered
            QtControls.ToolTip.text: i18n("Negative = sunken/inset, 0 = flat, positive = raised")
        }

        QtControls.SpinBox {
            Kirigami.FormData.label: i18n("Grid padding:")
            from: 0
            to: 60
            value: cfg_gridPadding
            onValueModified: cfg_gridPadding = value
            QtControls.ToolTip.visible: hovered
            QtControls.ToolTip.text: i18n("Empty space between the honeycomb and the widget edge")
        }

        RowLayout {
            Kirigami.FormData.label: i18n("Placeholder color:")
            Rectangle {
                width: Kirigami.Units.gridUnit * 1.5
                height: Kirigami.Units.gridUnit * 1.5
                radius: 4
                color: cfg_placeholderColor
                border.color: Kirigami.Theme.disabledTextColor
                border.width: 1
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: colorDialog.open()
                }
            }
            QtControls.Button {
                text: i18n("Choose…")
                onClicked: colorDialog.open()
            }
        }

        QtControls.SpinBox {
            Kirigami.FormData.label: i18n("Fallback text size:")
            from: 6
            to: 60
            value: cfg_textSize
            onValueModified: cfg_textSize = value
            QtControls.ToolTip.visible: hovered
            QtControls.ToolTip.text: i18n("Used for slots with a command but no icon image")
        }

        RowLayout {
            Kirigami.FormData.label: i18n("Fallback text color:")
            Rectangle {
                width: Kirigami.Units.gridUnit * 1.5
                height: Kirigami.Units.gridUnit * 1.5
                radius: 4
                color: cfg_textColor
                border.color: Kirigami.Theme.disabledTextColor
                border.width: 1
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: textColorDialog.open()
                }
            }
            QtControls.Button {
                text: i18n("Choose…")
                onClicked: textColorDialog.open()
            }
        }

        Kirigami.Separator {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: i18n("Slots")
        }

        ColumnLayout {
            Layout.fillWidth: true

            Repeater {
                model: slotModel

                RowLayout {
                    id: slotRow
                    required property int index
                    required property string image
                    required property string command
                    required property int zoom
                    required property string color

                    Layout.fillWidth: true

                    QtControls.TextField {
                        Layout.preferredWidth: Kirigami.Units.gridUnit * 12
                        placeholderText: i18n("Icon image")
                        text: image
                        onEditingFinished: { slotModel.setProperty(index, "image", text); page.save() }
                    }
                    QtControls.Button {
                        icon.name: "document-open"
                        onClicked: {
                            imageDialog.targetIndex = index
                            imageDialog.open()
                        }
                    }
                    QtControls.TextField {
                        Layout.fillWidth: true
                        placeholderText: i18n("Command")
                        text: command
                        onEditingFinished: { slotModel.setProperty(index, "command", text); page.save() }
                    }
                    QtControls.SpinBox {
                        from: 40
                        to: 300
                        stepSize: 10
                        value: zoom
                        onValueModified: { slotModel.setProperty(index, "zoom", value); page.save() }
                        QtControls.ToolTip.visible: hovered
                        QtControls.ToolTip.text: i18n("Zoom %, crops in on images with a lot of transparent padding, or shrinks below 100% for images with none")
                    }
                    Rectangle {
                        width: Kirigami.Units.gridUnit * 1.2
                        height: Kirigami.Units.gridUnit * 1.2
                        radius: 4
                        color: slotRow.color ? slotRow.color : cfg_placeholderColor
                        border.color: Kirigami.Theme.disabledTextColor
                        border.width: 1
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                slotColorDialog.targetIndex = slotRow.index
                                slotColorDialog.selectedColor = slotRow.color ? slotRow.color : cfg_placeholderColor
                                slotColorDialog.open()
                            }
                        }
                    }
                    QtControls.Button {
                        icon.name: "go-up"
                        enabled: index > 0
                        onClicked: { slotModel.move(index, index - 1, 1); page.save() }
                    }
                    QtControls.Button {
                        icon.name: "go-down"
                        enabled: index < slotModel.count - 1
                        onClicked: { slotModel.move(index, index + 1, 1); page.save() }
                    }
                    QtControls.Button {
                        icon.name: "list-remove"
                        onClicked: {
                            const cfgPage = page
                            slotModel.remove(index)
                            cfgPage.save()
                        }
                    }
                }
            }

            RowLayout {
                QtControls.SpinBox {
                    id: addCountSpin
                    from: 1
                    to: 10
                    value: 1
                }
                QtControls.Button {
                    text: i18n("Add %1 slot(s)", addCountSpin.value)
                    icon.name: "list-add"
                    onClicked: {
                        for (let i = 0; i < addCountSpin.value; i++)
                            slotModel.append({ image: "", command: "", zoom: 100, color: "" })
                        page.save()
                    }
                }
            }
        }
        Kirigami.Separator {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: i18n("Configuration backup")
        }

        RowLayout {
            QtControls.Button {
                text: i18n("Export…")
                icon.name: "document-export"
                onClicked: exportDialog.open()
            }
            QtControls.Button {
                text: i18n("Import…")
                icon.name: "document-import"
                onClicked: importDialog.open()
            }
        }

        QtControls.Label {
            Layout.fillWidth: true
            text: i18n("Back up this widget's settings, icons and background image. Applications must be installed separately.")
            wrapMode: Text.WordWrap
        }

        Kirigami.InlineMessage {
            Layout.fillWidth: true
            visible: page.backupMessage !== ""
            text: page.backupMessage
            type: page.backupError ? Kirigami.MessageType.Error : Kirigami.MessageType.Positive
        }
    }

    FileDialog {
        id: exportDialog
        title: i18n("Export KHoneycomb configuration")
        fileMode: FileDialog.SaveFile
        defaultSuffix: "khoneycomb"
        nameFilters: [i18n("KHoneycomb backup (*.khoneycomb)")]
        onAccepted: page.exportConfiguration(selectedFile.toString())
    }

    FileDialog {
        id: importDialog
        title: i18n("Import KHoneycomb configuration")
        nameFilters: [i18n("KHoneycomb backup (*.khoneycomb)")]
        onAccepted: {
            page.pendingBackup = selectedFile.toString()
            page.runBackup("inspect", page.pendingBackup)
        }
    }

    QtControls.Dialog {
        id: importConfirmation
        objectName: "importConfirmation"
        parent: QtControls.Overlay.overlay
        anchors.centerIn: parent
        modal: true
        title: i18n("Replace configuration?")
        standardButtons: QtControls.Dialog.Ok | QtControls.Dialog.Cancel
        width: Math.min(Kirigami.Units.gridUnit * 28, page.width)
        contentItem: QtControls.Label {
            text: i18n("Replace the current configuration with %1 hexagon(s) with the backup containing %2 hexagon(s)? Only import backups you trust: they contain application launch commands. Nothing is launched during import.", slotModel.count, page.pendingCount)
            wrapMode: Text.WordWrap
        }
        onAccepted: page.runBackup("import", page.pendingBackup, page.pendingDigest)
    }

    ColorDialog {
        id: colorDialog
        selectedColor: cfg_placeholderColor
        options: ColorDialog.ShowAlphaChannel
        onAccepted: cfg_placeholderColor = selectedColor
    }

    ColorDialog {
        id: textColorDialog
        selectedColor: cfg_textColor
        onAccepted: cfg_textColor = selectedColor
    }

    ColorDialog {
        id: slotColorDialog
        property int targetIndex: -1
        options: ColorDialog.ShowAlphaChannel
        onAccepted: {
            if (targetIndex >= 0) {
                slotModel.setProperty(targetIndex, "color", selectedColor.toString())
                page.save()
            }
        }
    }

    FileDialog {
        id: backgroundImageDialog
        currentFolder: StandardPaths.standardLocations(StandardPaths.GenericDataLocation)[0] + "/wallpapers"
        title: i18n("Choose a background image")
        nameFilters: [i18n("Images (*.png *.jpg *.jpeg *.webp *.svg)")]
        onAccepted: cfg_backgroundImage = selectedFile.toString().replace("file://", "")
    }

    FileDialog {
        id: imageDialog
        property int targetIndex: -1
        title: i18n("Choose an icon image")
        nameFilters: [i18n("Images (*.png *.jpg *.jpeg *.webp *.svg)")]
        onAccepted: {
            const path = selectedFile.toString().replace("file://", "")
            if (targetIndex >= 0) {
                slotModel.setProperty(targetIndex, "image", path)
                page.save()
            }
        }
    }
}

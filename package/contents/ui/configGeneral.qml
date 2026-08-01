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
    property bool cfg_showTrash
    property color cfg_textColor
    property int cfg_textSize
    property string cfg_slots

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

        QtControls.CheckBox {
            Kirigami.FormData.label: i18n("Trash:")
            text: i18n("Show trash icon")
            checked: cfg_showTrash
            onToggled: cfg_showTrash = checked
            QtControls.ToolTip.visible: hovered
            QtControls.ToolTip.text: i18n("Drag a hexagon onto it to clear that slot; click it to open the real trash")
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

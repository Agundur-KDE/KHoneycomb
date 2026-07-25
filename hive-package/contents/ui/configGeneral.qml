/*
 * SPDX-FileCopyrightText: 2026 Agundur <info@agundur.de>
 *
 * SPDX-License-Identifier: GPL-2.0-only OR GPL-3.0-only OR LicenseRef-KDE-Accepted-GPL
 */

import QtQuick
import QtQuick.Controls as QtControls
import QtQuick.Dialogs
import QtQuick.Layouts
import org.kde.kcmutils as KCM
import org.kde.kirigami as Kirigami

KCM.SimpleKCM {
    id: root

    property int cfg_hexSize
    property int cfg_columns
    property int cfg_spacing
    property string cfg_orientation
    property color cfg_placeholderColor
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
            slotModel.append({ image: s.image || "", command: s.command || "", zoom: s.zoom || 100 })
    }
    Component.onCompleted: load()

    function save() {
        const arr = []
        for (let i = 0; i < slotModel.count; i++) {
            const item = slotModel.get(i)
            arr.push({ image: item.image, command: item.command, zoom: item.zoom })
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

        Kirigami.Separator {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: i18n("Slots")
        }

        ColumnLayout {
            Layout.fillWidth: true

            Repeater {
                model: slotModel

                RowLayout {
                    required property int index
                    required property string image
                    required property string command
                    required property int zoom

                    Layout.fillWidth: true

                    QtControls.TextField {
                        Layout.preferredWidth: Kirigami.Units.gridUnit * 12
                        placeholderText: i18n("Icon image")
                        text: image
                        onEditingFinished: { slotModel.setProperty(index, "image", text); root.save() }
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
                        onEditingFinished: { slotModel.setProperty(index, "command", text); root.save() }
                    }
                    QtControls.SpinBox {
                        from: 100
                        to: 300
                        stepSize: 10
                        value: zoom
                        onValueModified: { slotModel.setProperty(index, "zoom", value); root.save() }
                        QtControls.ToolTip.visible: hovered
                        QtControls.ToolTip.text: i18n("Zoom %, crops in on images with a lot of transparent padding")
                    }
                    QtControls.Button {
                        icon.name: "go-up"
                        enabled: index > 0
                        onClicked: { slotModel.move(index, index - 1, 1); root.save() }
                    }
                    QtControls.Button {
                        icon.name: "go-down"
                        enabled: index < slotModel.count - 1
                        onClicked: { slotModel.move(index, index + 1, 1); root.save() }
                    }
                    QtControls.Button {
                        icon.name: "list-remove"
                        onClicked: { slotModel.remove(index); root.save() }
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
                            slotModel.append({ image: "", command: "", zoom: 100 })
                        root.save()
                    }
                }
            }
        }
    }

    ColorDialog {
        id: colorDialog
        selectedColor: cfg_placeholderColor
        onAccepted: cfg_placeholderColor = selectedColor
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
                root.save()
            }
        }
    }
}

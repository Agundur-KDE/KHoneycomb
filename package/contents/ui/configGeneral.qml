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
    property string cfg_imagePath
    property string cfg_command
    property int cfg_hexSize
    property string cfg_orientation

    Kirigami.FormLayout {
        RowLayout {
            Kirigami.FormData.label: i18n("Icon image:")
            QtControls.TextField {
                id: imagePathField
                Layout.fillWidth: true
                text: cfg_imagePath
                onEditingFinished: cfg_imagePath = text
            }
            QtControls.Button {
                icon.name: "document-open"
                onClicked: imageDialog.open()
            }
        }

        QtControls.TextField {
            Kirigami.FormData.label: i18n("Command:")
            Layout.fillWidth: true
            placeholderText: i18n("e.g. firefox, or steam steam://open/main")
            text: cfg_command
            onEditingFinished: cfg_command = text
        }

        QtControls.SpinBox {
            Kirigami.FormData.label: i18n("Size:")
            from: 40
            to: 400
            stepSize: 10
            value: cfg_hexSize
            onValueModified: cfg_hexSize = value
        }

        QtControls.ComboBox {
            Kirigami.FormData.label: i18n("Orientation:")
            model: [i18n("Flat-top"), i18n("Pointy-top")]
            currentIndex: cfg_orientation === "pointy" ? 1 : 0
            onActivated: cfg_orientation = currentIndex === 1 ? "pointy" : "flat"
        }
    }

    FileDialog {
        id: imageDialog
        title: i18n("Choose an icon image")
        nameFilters: [i18n("Images (*.png *.jpg *.jpeg *.webp *.svg)")]
        onAccepted: {
            const path = selectedFile.toString().replace("file://", "")
            imagePathField.text = path
            cfg_imagePath = path
        }
    }
}

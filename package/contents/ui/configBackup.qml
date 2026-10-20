/*
 * SPDX-FileCopyrightText: 2026 Agundur <info@agundur.de>
 *
 * SPDX-License-Identifier: GPL-2.0-only OR GPL-3.0-only OR LicenseRef-KDE-Accepted-GPL
 */

import QtQuick
import QtQuick.Controls as QtControls
import QtQuick.Dialogs
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.plasma5support as Plasma5Support

SettingsPage {
    id: page

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

    Kirigami.FormLayout {
        enabled: !page.backupBusy
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
            text: i18n("Replace the current configuration with %1 hexagon(s) with the backup containing %2 hexagon(s)? Only import backups you trust: they contain application launch commands. Nothing is launched during import.", JSON.parse(page.cfg_slots || "[]").length, page.pendingCount)
            wrapMode: Text.WordWrap
        }
        onAccepted: page.runBackup("import", page.pendingBackup, page.pendingDigest)
    }

}

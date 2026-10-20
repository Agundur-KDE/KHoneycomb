import QtQuick
import QtTest

TestCase {
    id: testCase
    name: "ConfigurationBackup"
    when: windowShown
    width: 900
    height: 800

    function createSettings(source = "configBackup.qml") {
        const component = Qt.createComponent("../package/contents/ui/" + source)
        verify(component.status === Component.Ready, component.errorString())
        return createTemporaryObject(component, testCase, {
            width: 900, height: 800,
            cfg_hexSize: 90, cfg_columns: 0, cfg_spacing: 5,
            cfg_orientation: "flat", cfg_placeholderColor: "#ffd021",
            cfg_backgroundImage: Qt.resolvedUrl("../package/contents/icons/khoneycomb.png").toString(),
            cfg_backgroundFillMode: "fill", cfg_backgroundDim: 40,
            cfg_bevelStrength: -50, cfg_gridPadding: 0,
            cfg_textColor: "#000000", cfg_textSize: 14,
            cfg_slots: '[{"image":"","command":"test-command","zoom":100,"color":""}]'
        })
    }

    function test_export_confirm_cancel_import() {
        const page = createSettings()
        verify(page !== null)
        const path = "file://" + backupTestDirectory + "/config ' ü.khoneycomb"
        page.exportConfiguration(path)
        tryCompare(page, "backupBusy", false, 10000)
        verify(!page.backupError, page.backupMessage)
        verify(page.backupMessage.length > 0)

        page.cfg_hexSize = 120
        page.cfg_slots = "[]"
        page.pendingBackup = path
        page.runBackup("inspect", path)
        tryCompare(page, "backupBusy", false, 10000)
        verify(!page.backupError, page.backupMessage)
        compare(page.pendingCount, 1)
        const confirmation = findChild(page, "importConfirmation")
        verify(confirmation !== null)
        tryCompare(confirmation, "visible", true)
        confirmation.reject()
        compare(page.cfg_hexSize, 120)
        compare(page.cfg_slots, "[]")

        page.runBackup("inspect", path)
        tryCompare(page, "backupBusy", false, 10000)
        tryCompare(confirmation, "visible", true)
        confirmation.accept()
        tryCompare(page, "backupBusy", false, 10000)
        verify(!page.backupError, page.backupMessage)
        compare(page.cfg_hexSize, 90)
        compare(JSON.parse(page.cfg_slots)[0].command, "test-command")
        verify(page.cfg_backgroundImage.indexOf("khoneycomb/imported/") >= 0)
    }

    function test_invalid_import_preserves_configuration() {
        const page = createSettings()
        const original = page.cfg_slots
        page.runBackup("inspect", "file://" + backupTestDirectory + "/missing.khoneycomb")
        tryCompare(page, "backupBusy", false, 10000)
        verify(page.backupError)
        compare(page.cfg_slots, original)
        compare(page.cfg_hexSize, 90)
    }

    function test_shell_quoting() {
        const page = createSettings()
        compare(page.shellQuote("a'b $(touch no)"), "'a'\\''b $(touch no)'")
    }

    function test_separate_category_and_shared_configuration() {
        const component = Qt.createComponent("../package/contents/config/config.qml")
        verify(component.status === Component.Ready, component.errorString())
        const categories = createTemporaryObject(component, testCase)
        compare(categories.count, 2)
        compare(categories.get(1).source, "configBackup.qml")

        const general = createSettings("configGeneral.qml")
        const backup = createSettings()
        verify(general.backupBusy === undefined)
        // Plasma's Apply logic uses hasOwnProperty, including inherited QML properties.
        for (const key of backup.backupKeys) {
            verify(general.hasOwnProperty("cfg_" + key), key)
            verify(backup.hasOwnProperty("cfg_" + key), key)
            verify(general.hasOwnProperty("cfg_" + key + "Default"), key)
        }
    }

    function test_theme_icon_export_and_import() {
        const page = createSettings()
        page.cfg_slots = '[{"image":"document-open","command":"test-command","zoom":100,"color":""}]'
        const path = "file://" + backupTestDirectory + "/theme.khoneycomb"
        page.exportConfiguration(path)
        tryCompare(page, "backupBusy", false, 10000)
        verify(!page.backupError, page.backupMessage)
        page.cfg_slots = "[]"
        page.pendingBackup = path
        page.runBackup("inspect", path)
        tryCompare(page, "backupBusy", false, 10000)
        verify(!page.backupError, page.backupMessage)
        const confirmation = findChild(page, "importConfirmation")
        tryCompare(confirmation, "visible", true)
        confirmation.accept()
        tryCompare(page, "backupBusy", false, 10000)
        verify(!page.backupError, page.backupMessage)
        compare(JSON.parse(page.cfg_slots)[0].image, "document-open")
    }
}

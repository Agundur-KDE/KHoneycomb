import QtQuick
import QtTest
import "../package/contents/ui" as Widget

TestCase {
    name: "SlotIcon"
    when: windowShown
    visible: true
    width: 100
    height: 100

    Component {
        id: iconComponent
        Widget.SlotIcon { width: 90; height: 90 }
    }

    function test_theme_name_without_external_resolver() {
        const icon = createTemporaryObject(iconComponent, this, {source: "document-open"})
        verify(icon.themeIcon)
        const theme = findChild(icon, "themeIcon")
        verify(theme.visible)
        tryCompare(theme, "valid", true)
        compare(findChild(icon, "fileIcon").source.toString(), "")
    }

    function test_custom_file_and_switching() {
        const file = Qt.resolvedUrl("../package/contents/icons/khoneycomb.png").toString()
        const icon = createTemporaryObject(iconComponent, this, {source: file})
        verify(!icon.themeIcon)
        const image = findChild(icon, "fileIcon")
        tryCompare(image, "status", Image.Ready)
        compare(image.fillMode, Image.PreserveAspectCrop)
        icon.source = "document-save"
        verify(icon.themeIcon)
        tryCompare(findChild(icon, "themeIcon"), "valid", true)
        icon.source = file.replace("file://", "")
        verify(!icon.themeIcon)
        tryCompare(image, "status", Image.Ready)
    }

    function test_empty_source() {
        const icon = createTemporaryObject(iconComponent, this)
        verify(!icon.themeIcon)
        compare(findChild(icon, "fileIcon").status, Image.Null)
        verify(!findChild(icon, "themeIcon").visible)
    }
}

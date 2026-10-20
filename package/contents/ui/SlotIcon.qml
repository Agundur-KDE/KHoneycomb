/* SPDX-License-Identifier: GPL-2.0-only OR GPL-3.0-only OR LicenseRef-KDE-Accepted-GPL */
import QtQuick
import org.kde.kirigami as Kirigami

Item {
    id: root
    property string source: ""
    property size sourceSize: Qt.size(width, height)
    readonly property bool themeIcon: source !== "" && source.indexOf("/") === -1 && source.indexOf(":") === -1

    // Preserve the existing crop/zoom behavior for custom image files.
    Image {
        objectName: "fileIcon"
        anchors.fill: parent
        visible: !root.themeIcon
        source: root.themeIcon ? "" : root.source
        sourceSize: root.sourceSize
        fillMode: Image.PreserveAspectCrop
        smooth: true
        mipmap: true
        asynchronous: true
    }

    // Resolve names in-process using the desktop's current icon theme.
    Kirigami.Icon {
        objectName: "themeIcon"
        anchors.fill: parent
        visible: root.themeIcon
        source: root.themeIcon ? root.source : ""
        animated: false
        roundToIconSize: false
    }
}

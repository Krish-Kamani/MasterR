import QtQuick
import Quickshell

Item {
    id: row

    required property var entry
    property bool selected: false

    signal activated()
    signal entered()

    implicitHeight: 50

    readonly property color cream: "#e6d6cb"
    readonly property color white: "#fff6f0"
    readonly property color dim2: "#565e6a"

    readonly property string secondary: {
        if (entry.genericName && entry.genericName.length > 0) return entry.genericName;
        if (entry.categories && entry.categories.length > 0) {
            var first = String(entry.categories).split(";")[0].trim();
            if (first.length > 0) return first;
        }
        return "";
    }

    Rectangle {
        id: selBg
        anchors.fill: parent
        radius: 14
        gradient: Gradient {
            GradientStop { position: 0.0; color: "#c0442b" }
            GradientStop { position: 1.0; color: "#a3371f" }
        }
        opacity: row.selected ? 1.0 : (mouseArea.containsMouse ? 0.30 : 0.0)
        scale: row.selected ? 1.0 : (mouseArea.pressed ? 0.95 : (mouseArea.containsMouse ? 0.99 : 0.96))

        Behavior on opacity { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
        Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutBack } }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        onEntered: row.entered()
        onClicked: row.activated()
    }

    Item {
        anchors.fill: parent
        anchors.leftMargin: 15
        anchors.rightMargin: 15

        Rectangle {
            id: iconBox
            anchors.verticalCenter: parent.verticalCenter
            width: 26
            height: 26
            radius: 6
            color: Qt.rgba(1, 1, 1, 0.05)
            visible: !(icon.status === Image.Ready && icon.source !== "")
        }

        Image {
            id: icon
            anchors.fill: iconBox
            sourceSize.width: 52
            sourceSize.height: 52
            fillMode: Image.PreserveAspectFit
            asynchronous: true
            visible: status === Image.Ready && source !== ""
            source: {
                if (!row.entry.icon || row.entry.icon.length === 0) {
                    return Quickshell.iconPath("application-x-executable", true) || "";
                }
                if (row.entry.icon.startsWith("/") || row.entry.icon.startsWith("file://")) {
                    return row.entry.icon.startsWith("file://") ? row.entry.icon : ("file://" + row.entry.icon);
                }
                var p = Quickshell.iconPath(row.entry.icon, true);
                return (p && p.length > 0) ? p : (Quickshell.iconPath("application-x-executable", true) || "");
            }
        }

        Text {
            id: titleText
            anchors.verticalCenter: parent.verticalCenter
            anchors.left: icon.right
            anchors.leftMargin: 12
            text: row.entry.name
            color: row.selected ? row.white : row.cream
            font.family: "Inter"
            font.pixelSize: 15
            font.weight: row.selected ? Font.DemiBold : Font.Normal
            elide: Text.ElideRight
            width: Math.min(implicitWidth, parent.width - icon.width - 12 - secondary.width - enter.width - 18)

            Behavior on color { ColorAnimation { duration: 140 } }
        }

        Text {
            id: enter
            anchors.verticalCenter: parent.verticalCenter
            anchors.right: parent.right
            text: "↵"
            color: row.white
            font.family: "Inter"
            font.pixelSize: 13
            opacity: row.selected ? 1.0 : 0.0
            width: row.selected ? implicitWidth + 7 : 0
            horizontalAlignment: Text.AlignRight

            Behavior on opacity { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }
            Behavior on width { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }
        }

        Text {
            id: secondary
            anchors.verticalCenter: parent.verticalCenter
            anchors.right: enter.left
            text: row.secondary
            color: row.selected ? Qt.rgba(1, 0.965, 0.941, 0.72) : row.dim2
            font.family: "Inter"
            font.pixelSize: 12
            horizontalAlignment: Text.AlignRight

            Behavior on color { ColorAnimation { duration: 140 } }
        }
    }
}

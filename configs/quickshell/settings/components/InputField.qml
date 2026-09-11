import QtQuick
import "../Singletons"

Item {
    id: root

    property string label: ""
    property string placeholder: ""
    property alias text: input.text
    property bool isMonospace: false

    width: parent ? parent.width : 300
    height: (label.length > 0 ? 22 : 0) + 38

    Column {
        anchors.fill: parent
        spacing: 4

        Text {
            visible: root.label.length > 0
            text: root.label
            font.family: Theme.fontUI
            font.pixelSize: 12
            font.weight: Font.DemiBold
            color: Theme.bright
        }

        Rectangle {
            width: parent.width
            height: 38
            radius: 8
            color: Qt.rgba(255, 255, 255, 0.06)
            border.color: input.activeFocus ? Theme.onGlow : Qt.rgba(255, 255, 255, 0.12)
            border.width: input.activeFocus ? 1.5 : 1

            Behavior on border.color { ColorAnimation { duration: 120 } }

            TextInput {
                id: input
                anchors.fill: parent
                anchors.leftMargin: 12
                anchors.rightMargin: 12
                verticalAlignment: TextInput.AlignVCenter
                font.family: root.isMonospace ? Theme.fontMono : Theme.fontUI
                font.pixelSize: 12
                color: Theme.bright
                clip: true
                selectByMouse: true

                Text {
                    visible: input.text.length === 0
                    anchors.fill: parent
                    verticalAlignment: Text.AlignVCenter
                    text: root.placeholder
                    font.family: root.isMonospace ? Theme.fontMono : Theme.fontUI
                    font.pixelSize: 12
                    color: Theme.faint
                }
            }
        }
    }
}

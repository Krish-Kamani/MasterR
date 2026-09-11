import QtQuick
import "../Singletons"

/**
 * Modern Liquid Glass header banner for MasterR settings pages.
 */
Row {
    id: root

    property string title: ""
    property string subtitle: ""
    property string glyph: ""
    property string icon: ""
    property string badgeText: ""

    width: parent ? parent.width : 600
    height: Math.max(54, textCol.implicitHeight + 6)
    spacing: 16

    // Glowing Badge Squircle
    Rectangle {
        width: 48
        height: 48
        radius: 14
        anchors.verticalCenter: parent.verticalCenter
        color: Qt.rgba(Theme.onGlow.r, Theme.onGlow.g, Theme.onGlow.b, 0.18)
        border.color: Qt.rgba(Theme.onGlow.r, Theme.onGlow.g, Theme.onGlow.b, 0.45)
        border.width: 1.5

        // Specular top highlight
        Rectangle {
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.margins: 4
            height: 1
            color: Qt.rgba(255, 255, 255, 0.3)
        }

        Text {
            visible: root.glyph.length > 0
            anchors.centerIn: parent
            text: root.glyph
            font.family: Theme.fontJp
            font.pixelSize: 20
            font.weight: Font.Bold
            color: Theme.onGlow
        }

        GlyphIcon {
            visible: root.glyph.length === 0 && root.icon.length > 0
            anchors.centerIn: parent
            width: 22
            height: 22
            name: root.icon
            color: Theme.onGlow
            stroke: 2.0
        }
    }

    Column {
        id: textCol
        width: parent.width - 64
        anchors.verticalCenter: parent.verticalCenter
        spacing: 3

        Row {
            spacing: 10

            Text {
                text: root.title
                font.family: Theme.fontUI
                font.pixelSize: 19
                font.weight: Font.Bold
                color: Theme.bright
            }

            Rectangle {
                visible: root.badgeText.length > 0
                height: 18
                width: badgeLabel.implicitWidth + 12
                radius: 9
                anchors.verticalCenter: parent.verticalCenter
                color: Qt.rgba(Theme.onGlow.r, Theme.onGlow.g, Theme.onGlow.b, 0.2)
                border.color: Theme.onGlow
                border.width: 1

                Text {
                    id: badgeLabel
                    anchors.centerIn: parent
                    text: root.badgeText
                    font.family: Theme.fontUI
                    font.pixelSize: 9
                    font.weight: Font.Bold
                    color: Theme.onGlow
                }
            }
        }

        Text {
            width: parent.width
            visible: root.subtitle.length > 0
            text: root.subtitle
            font.family: Theme.fontUI
            font.pixelSize: 12
            color: Theme.dim
            wrapMode: Text.WordWrap
            lineHeight: 1.15
        }
    }
}

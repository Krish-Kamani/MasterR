import QtQuick
import "../Singletons"
import "../components"

Flickable {
    id: root

    contentHeight: contentCol.implicitHeight + 40
    clip: true

    Column {
        id: contentCol
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: 24
        spacing: 20

        PageHeader {
            glyph: "空"
            title: "Workspaces & Scratchpads"
            subtitle: "Sequential smooth scrolling, scratchpad workspaces, and full-screen overview."
        }

        // Smooth Sequential Scrolling
        Card {
            title: "Cinematic Workspace Navigation"
            subtitle: "Smooth sequential horizontal traversal between non-adjacent workspaces"
            icon: "layers"

            Switch {
                label: "Sequential Smooth Workspace Scrolling"
                description: "Traverse intermediate workspaces (e.g. 1 -> 2 -> 3 -> 4 -> 5) when jumping between desks"
                checked: Flags.smoothWorkspaceScroll !== false
                icon: "waves"
                onToggled: (st) => Flags.smoothWorkspaceScroll = st
            }
        }

        // Special Workspaces & Scratchpads
        Card {
            title: "Special Workspaces (Scratchpads)"
            subtitle: "Isolated workspaces for confidential browsing, temporary utilities, and minimized apps"
            icon: "grid"

            Rectangle {
                width: parent.width
                height: 60
                radius: 10
                color: Qt.rgba(Theme.border.r, Theme.border.g, Theme.border.b, 0.2)
                border.color: Theme.border
                border.width: 1

                Row {
                    anchors.fill: parent
                    anchors.margins: 14
                    spacing: 14

                    Rectangle {
                        width: 32
                        height: 32
                        radius: 8
                        color: Qt.rgba(Theme.onGlow.r, Theme.onGlow.g, Theme.onGlow.b, 0.15)
                        Text { anchors.centerIn: parent; text: "P"; font.weight: Font.Bold; color: Theme.onGlow }
                    }

                    Column {
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 2
                        Text { text: "Private Workspace (SUPER + P)"; font.family: Theme.fontUI; font.pixelSize: 13; font.weight: Font.Bold; color: Theme.bright }
                        Text { text: "Isolated workspace for sensitive tasks, private browsing, and confidential documents"; font.family: Theme.fontUI; font.pixelSize: 11; color: Theme.dim }
                    }
                }
            }

            Rectangle {
                width: parent.width
                height: 60
                radius: 10
                color: Qt.rgba(Theme.border.r, Theme.border.g, Theme.border.b, 0.2)
                border.color: Theme.border
                border.width: 1

                Row {
                    anchors.fill: parent
                    anchors.margins: 14
                    spacing: 14

                    Rectangle {
                        width: 32
                        height: 32
                        radius: 8
                        color: Qt.rgba(Theme.onGlow.r, Theme.onGlow.g, Theme.onGlow.b, 0.15)
                        Text { anchors.centerIn: parent; text: "S"; font.weight: Font.Bold; color: Theme.onGlow }
                    }

                    Column {
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 2
                        Text { text: "Stash Scratchpad (SUPER + S)"; font.family: Theme.fontUI; font.pixelSize: 13; font.weight: Font.Bold; color: Theme.bright }
                        Text { text: "Tuck away terminal scratchpads, quick notes, and auxiliary utilities"; font.family: Theme.fontUI; font.pixelSize: 11; color: Theme.dim }
                    }
                }
            }

            Rectangle {
                width: parent.width
                height: 60
                radius: 10
                color: Qt.rgba(Theme.border.r, Theme.border.g, Theme.border.b, 0.2)
                border.color: Theme.border
                border.width: 1

                Row {
                    anchors.fill: parent
                    anchors.margins: 14
                    spacing: 14

                    Rectangle {
                        width: 32
                        height: 32
                        radius: 8
                        color: Qt.rgba(Theme.onGlow.r, Theme.onGlow.g, Theme.onGlow.b, 0.15)
                        Text { anchors.centerIn: parent; text: "M"; font.weight: Font.Bold; color: Theme.onGlow }
                    }

                    Column {
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 2
                        Text { text: "Minimized Window Tray (SUPER + M)"; font.family: Theme.fontUI; font.pixelSize: 13; font.weight: Font.Bold; color: Theme.bright }
                        Text { text: "Minimize background windows directly into the Quickshell smart dock tray"; font.family: Theme.fontUI; font.pixelSize: 11; color: Theme.dim }
                    }
                }
            }
        }
    }
}

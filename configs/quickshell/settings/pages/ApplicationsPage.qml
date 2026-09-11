import QtQuick
import Quickshell
import Quickshell.Io
import "../Singletons"
import "../components"

Flickable {
    id: root

    contentHeight: contentCol.implicitHeight + 40
    clip: true

    Process {
        id: cmdProc
        command: ["true"]
    }

    Column {
        id: contentCol
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: 24
        spacing: 20

        PageHeader {
            glyph: "応"
            title: "Applications & App Depot"
            subtitle: "Curated application stack, default system handlers, package manager, and icon fixer."
        }

        // Curated Default Applications
        Card {
            title: "Default Core Applications"
            subtitle: "Curated high-performance tools integrated into MasterR keybindings"
            icon: "grid"

            Rectangle {
                width: parent.width
                height: 52
                radius: 8
                color: Qt.rgba(Theme.border.r, Theme.border.g, Theme.border.b, 0.2)

                Row {
                    anchors.fill: parent
                    anchors.margins: 14
                    spacing: 12
                    GlyphIcon { width: 16; height: 16; anchors.verticalCenter: parent.verticalCenter; name: "app-window"; color: Theme.onGlow }
                    Column {
                        anchors.verticalCenter: parent.verticalCenter
                        Text { text: "Web Browser: Zen Browser (Gecko / Vertical Tabs)"; font.family: Theme.fontUI; font.pixelSize: 12; font.weight: Font.Bold; color: Theme.bright }
                        Text { text: "Launched via SUPER + B with discrete GPU offloading (prime-run zen-browser)"; font.family: Theme.fontUI; font.pixelSize: 10; color: Theme.dim }
                    }
                }
            }

            Rectangle {
                width: parent.width
                height: 52
                radius: 8
                color: Qt.rgba(Theme.border.r, Theme.border.g, Theme.border.b, 0.2)

                Row {
                    anchors.fill: parent
                    anchors.margins: 14
                    spacing: 12
                    GlyphIcon { width: 16; height: 16; anchors.verticalCenter: parent.verticalCenter; name: "keyboard"; color: Theme.onGlow }
                    Column {
                        anchors.verticalCenter: parent.verticalCenter
                        Text { text: "Terminal: Ghostty (GPU-Accelerated Wayland)"; font.family: Theme.fontUI; font.pixelSize: 12; font.weight: Font.Bold; color: Theme.bright }
                        Text { text: "Launched via SUPER + Return with live DBus color palette retheming"; font.family: Theme.fontUI; font.pixelSize: 10; color: Theme.dim }
                    }
                }
            }

            Rectangle {
                width: parent.width
                height: 52
                radius: 8
                color: Qt.rgba(Theme.border.r, Theme.border.g, Theme.border.b, 0.2)

                Row {
                    anchors.fill: parent
                    anchors.margins: 14
                    spacing: 12
                    GlyphIcon { width: 16; height: 16; anchors.verticalCenter: parent.verticalCenter; name: "folder"; color: Theme.onGlow }
                    Column {
                        anchors.verticalCenter: parent.verticalCenter
                        Text { text: "File Manager: Dolphin (KDE)"; font.family: Theme.fontUI; font.pixelSize: 12; font.weight: Font.Bold; color: Theme.bright }
                        Text { text: "Launched via SUPER + E styled with MasterR dark Material You colors"; font.family: Theme.fontUI; font.pixelSize: 10; color: Theme.dim }
                    }
                }
            }
        }

        // Package Store & App Depot
        Card {
            title: "Visual Package Store & App Depot"
            subtitle: "Browse Arch/AUR packages with automated root cause diagnosis and install AppImages"
            icon: "download"

            Row {
                width: parent.width
                spacing: 12

                Button {
                    text: "Open Visual Package Store (SUPER + SHIFT + Enter)"
                    icon: "download"
                    variant: "primary"
                    onClicked: {
                        cmdProc.command = [Quickshell.env("HOME") + "/.config/hypr/scripts/open-surface.sh", "packages"];
                        cmdProc.running = true;
                    }
                }

                Button {
                    text: "Open ~/Applications Depot"
                    icon: "folder"
                    variant: "secondary"
                    onClicked: {
                        cmdProc.command = ["dolphin", Quickshell.env("HOME") + "/Applications"];
                        cmdProc.running = true;
                    }
                }
            }
        }

        // Auto App Icon Fixer
        Card {
            title: "Automatic Desktop App Icon Fixer"
            subtitle: "Scan all XDG desktop entries for broken icons and resolve official vector logos"
            icon: "sparkles"

            Row {
                width: parent.width
                spacing: 12

                Button {
                    text: "Scan & Fix Broken Desktop Icons Now"
                    icon: "sparkles"
                    variant: "secondary"
                    onClicked: {
                        cmdProc.command = ["ghostty", "--class=masterr-floating", "-e", Quickshell.env("HOME") + "/.local/bin/auto-app-icon-fixer", "--auto"];
                        cmdProc.running = true;
                    }
                }
            }
        }
    }
}

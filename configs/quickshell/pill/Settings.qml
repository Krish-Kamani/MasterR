pragma ComponentBehavior: Bound

import QtQuick
import Quickshell.Io
import "Singletons"

/**
 * 設 SETTINGS index: a short list of categories. Each row carries its kanji,
 * name and caption, and morphs the pill into that category's sub-surface.
 * Arrow keys move the focused row with the glowing seam and Return opens it.
 */
SettingsSurface {
    id: root

    implicitHeight: content.implicitHeight

    Process {
        id: launchSettingsProc
        command: ["masterr-settings"]
    }

    rows: [
        { item: appearanceRow, kind: "nav", surface: "appearance" },
        { item: lookRow, kind: "nav", surface: "look" },
        { item: dockRow, kind: "nav", surface: "docksettings" },
        { item: displayRow, kind: "nav", surface: "display" },
        { item: inputRow, kind: "nav", surface: "input" },
        { item: animationRow, kind: "nav", surface: "animation" },
        { item: keybindsRow, kind: "nav", surface: "keybinds" },
        { item: workspacesRow, kind: "nav", surface: "workspaces" },
        { item: idleRow, kind: "nav", surface: "idlelock" },
        { item: updatesRow, kind: "nav", surface: "updates" }
    ]

    Column {
        id: content
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        spacing: 0

        SettingsHeader {
            s: root.s
            glyph: "設"
            title: "SETTINGS"
        }

        Rectangle {
            width: parent.width - 24 * root.s
            height: 36 * root.s
            anchors.horizontalCenter: parent.horizontalCenter
            radius: 8 * root.s
            color: fullBtnMouse.containsMouse ? Qt.rgba(Theme.onGlow.r, Theme.onGlow.g, Theme.onGlow.b, 0.22) : Qt.rgba(Theme.onGlow.r, Theme.onGlow.g, Theme.onGlow.b, 0.10)
            border.color: fullBtnMouse.containsMouse ? Theme.onGlow : Qt.rgba(Theme.onGlow.r, Theme.onGlow.g, Theme.onGlow.b, 0.28)
            border.width: 1

            Row {
                anchors.centerIn: parent
                spacing: 8 * root.s

                GlyphIcon {
                    width: 14 * root.s
                    height: 14 * root.s
                    anchors.verticalCenter: parent.verticalCenter
                    name: "cog"
                    color: Theme.bright
                    stroke: 2.0
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "Open Full Settings App (SUPER + I)"
                    font.family: Flags.uiFont || "Inter"
                    font.pixelSize: 11 * root.s
                    font.weight: Font.DemiBold
                    color: Theme.bright
                }
            }

            MouseArea {
                id: fullBtnMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: launchSettingsProc.running = true
            }
        }

        Item { width: parent.width; height: 6 * root.s }

        SettingsRow {
            id: appearanceRow
            surface: root
            captionOnFocus: true
            icon: "sparkles"
            name: "Appearance"
            sub: "Clock, glyphs, accent palette"

            GlyphIcon {
                width: 16 * root.s
                height: 16 * root.s
                name: "chevron-right"
                color: root.focusRowItem === appearanceRow ? Theme.cream : Theme.iconDim
                stroke: 2.2
            }
        }

        SettingsRow {
            id: lookRow
            surface: root
            captionOnFocus: true
            icon: "app-window"
            name: "Look"
            sub: "Gaps, rounding, blur, opacity"

            GlyphIcon {
                width: 16 * root.s
                height: 16 * root.s
                name: "chevron-right"
                color: root.focusRowItem === lookRow ? Theme.cream : Theme.iconDim
                stroke: 2.2
            }
        }

        SettingsRow {
            id: dockRow
            surface: root
            captionOnFocus: true
            icon: "apps"
            name: "Dock"
            sub: "Pin mode, height, hover reveal, apps"

            GlyphIcon {
                width: 16 * root.s
                height: 16 * root.s
                name: "chevron-right"
                color: root.focusRowItem === dockRow ? Theme.cream : Theme.iconDim
                stroke: 2.2
            }
        }

        SettingsRow {
            id: displayRow
            surface: root
            captionOnFocus: true
            icon: "monitor"
            name: "Display"
            sub: "Resolution, refresh, scale"

            GlyphIcon {
                width: 16 * root.s
                height: 16 * root.s
                name: "chevron-right"
                color: root.focusRowItem === displayRow ? Theme.cream : Theme.iconDim
                stroke: 2.2
            }
        }

        SettingsRow {
            id: inputRow
            surface: root
            captionOnFocus: true
            icon: "mouse"
            name: "Input"
            sub: "Pointer, keyboard, cursor"

            GlyphIcon {
                width: 16 * root.s
                height: 16 * root.s
                name: "chevron-right"
                color: root.focusRowItem === inputRow ? Theme.cream : Theme.iconDim
                stroke: 2.2
            }
        }

        SettingsRow {
            id: animationRow
            surface: root
            captionOnFocus: true
            icon: "waves"
            name: "Animation"
            sub: "Speed, motion curve, enable"

            GlyphIcon {
                width: 16 * root.s
                height: 16 * root.s
                name: "chevron-right"
                color: root.focusRowItem === animationRow ? Theme.cream : Theme.iconDim
                stroke: 2.2
            }
        }

        SettingsRow {
            id: keybindsRow
            surface: root
            captionOnFocus: true
            icon: "keyboard"
            name: "Keybinds"
            sub: "Rebind, add, set commands"

            GlyphIcon {
                width: 16 * root.s
                height: 16 * root.s
                name: "chevron-right"
                color: root.focusRowItem === keybindsRow ? Theme.cream : Theme.iconDim
                stroke: 2.2
            }
        }

        SettingsRow {
            id: workspacesRow
            surface: root
            captionOnFocus: true
            icon: "layers"
            name: "Workspaces"
            sub: "Special spaces and their keys"

            GlyphIcon {
                width: 16 * root.s
                height: 16 * root.s
                name: "chevron-right"
                color: root.focusRowItem === workspacesRow ? Theme.cream : Theme.iconDim
                stroke: 2.2
            }
        }

        SettingsRow {
            id: idleRow
            surface: root
            captionOnFocus: true
            icon: "lock"
            name: "Idle / Lock"
            sub: "Auto-lock, screen off, suspend"

            GlyphIcon {
                width: 16 * root.s
                height: 16 * root.s
                name: "chevron-right"
                color: root.focusRowItem === idleRow ? Theme.cream : Theme.iconDim
                stroke: 2.2
            }
        }

        SettingsRow {
            id: updatesRow
            surface: root
            captionOnFocus: true
            icon: "download"
            name: "Updates"
            sub: "Version and check for updates"
            last: true

            GlyphIcon {
                width: 16 * root.s
                height: 16 * root.s
                name: "chevron-right"
                color: root.focusRowItem === updatesRow ? Theme.cream : Theme.iconDim
                stroke: 2.2
            }
        }
    }
}

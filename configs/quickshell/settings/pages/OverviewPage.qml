import QtQuick
import Quickshell
import Quickshell.Io
import "../Singletons"
import "../components"

Flickable {
    id: root

    contentHeight: contentCol.implicitHeight + 80
    clip: true

    property string uptimeStr: "Calculating..."
    property string memStr: "Loading..."
    property real memPercent: 0.28
    property string cpuStr: "Active"
    property string kernelStr: "Linux"

    Process {
        id: cmdProc
        command: ["true"]
    }

    // Fast telemetry read with escaped bash vars
    Process {
        id: telemetryProc
        command: ["sh", "-c", "uptime -p 2>/dev/null || echo Up; uname -r; free -m | awk '/Mem:/ { printf \"%.1f GB / %.1f GB (%.0f%%)\", $3/1024, $2/1024, ($3/$2)*100 }'"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                var lines = this.text.trim().split("\n");
                if (lines.length >= 1) root.uptimeStr = lines[0].replace("up ", "");
                if (lines.length >= 2) root.kernelStr = lines[1];
                if (lines.length >= 3) {
                    root.memStr = lines[2];
                    var m = lines[2].match(/\((\d+)%\)/);
                    if (m) root.memPercent = parseInt(m[1]) / 100;
                }
            }
        }
    }

    Timer {
        interval: 5000
        running: true
        repeat: true
        onTriggered: telemetryProc.running = true
    }

    Column {
        id: contentCol
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: 24
        spacing: 20

        PageHeader {
            glyph: "統"
            title: "System & Overview"
            subtitle: "Overall system status, real-time hardware telemetry, shell daemons, and system-wide controls."
            badgeText: "ONLINE"
        }

        // Hero System Status Telemetry Card
        Rectangle {
            width: parent.width
            height: 114
            radius: 16
            color: Qt.rgba(Theme.cardBot.r, Theme.cardBot.g, Theme.cardBot.b, 0.72)
            border.color: Qt.rgba(255, 255, 255, 0.09)
            border.width: 1

            // Specular highlight
            Rectangle {
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.margins: 16
                height: 1
                color: Qt.rgba(255, 255, 255, 0.22)
            }

            Row {
                anchors.fill: parent
                anchors.margins: 18
                spacing: 20

                // Host branding badge
                Rectangle {
                    width: 76
                    height: 76
                    radius: 16
                    gradient: Gradient {
                        GradientStop { position: 0.0; color: Theme.onGlow }
                        GradientStop { position: 1.0; color: Theme.vermDeep }
                    }
                    border.color: Qt.rgba(255, 255, 255, 0.35)
                    border.width: 1

                    Column {
                        anchors.centerIn: parent
                        spacing: 2

                        GlyphIcon {
                            anchors.horizontalCenter: parent.horizontalCenter
                            width: 28
                            height: 28
                            name: "cpu"
                            color: "#ffffff"
                            stroke: 2.2
                        }

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: "MasterR"
                            font.family: Theme.fontUI
                            font.pixelSize: 10
                            font.weight: Font.Bold
                            color: "#ffffff"
                        }
                    }
                }

                // System Info Summary
                Column {
                    width: parent.width - 96 - 290
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 4

                    Row {
                        spacing: 8
                        Text {
                            text: "Arch Linux"
                            font.family: Theme.fontUI
                            font.pixelSize: 17
                            font.weight: Font.Bold
                            color: Theme.bright
                        }
                        Rectangle {
                            height: 18
                            width: rollingBadge.implicitWidth + 10
                            radius: 4
                            color: Qt.rgba(Theme.onGlow.r, Theme.onGlow.g, Theme.onGlow.b, 0.2)
                            border.color: Theme.onGlow
                            border.width: 1

                            Text {
                                id: rollingBadge
                                anchors.centerIn: parent
                                text: "Hyprland Wayland"
                                font.family: Theme.fontUI
                                font.pixelSize: 9
                                font.weight: Font.Bold
                                color: Theme.onGlow
                            }
                        }
                    }

                    Text {
                        text: "Kernel " + root.kernelStr + " • Uptime: " + root.uptimeStr
                        font.family: Theme.fontUI
                        font.pixelSize: 12
                        color: Theme.dim
                    }

                    Text {
                        text: "Liquid Glass Architecture • Matugen Synchronized Palette"
                        font.family: Theme.fontUI
                        font.pixelSize: 11
                        color: Theme.faint
                    }
                }

                // Live Memory & System Gauge
                Column {
                    width: 260
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 6

                    Item {
                        width: parent.width
                        height: 16

                        Text {
                            anchors.left: parent.left
                            anchors.verticalCenter: parent.verticalCenter
                            text: "System Memory (RAM)"
                            font.family: Theme.fontUI
                            font.pixelSize: 12
                            font.weight: Font.DemiBold
                            color: Theme.bright
                        }

                        Text {
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            text: root.memStr
                            font.family: Theme.fontMono
                            font.pixelSize: 11
                            color: Theme.onGlow
                        }
                    }

                    // Memory progress track
                    Rectangle {
                        width: parent.width
                        height: 8
                        radius: 4
                        color: Qt.rgba(255, 255, 255, 0.08)

                        Rectangle {
                            anchors.top: parent.top
                            anchors.bottom: parent.bottom
                            anchors.left: parent.left
                            width: Math.max(8, Math.min(parent.width, parent.width * root.memPercent))
                            radius: 4
                            gradient: Gradient {
                                orientation: Gradient.Horizontal
                                GradientStop { position: 0.0; color: Theme.onGlow }
                                GradientStop { position: 1.0; color: Theme.vermLit }
                            }
                        }
                    }

                    Row {
                        spacing: 14
                        Text {
                            text: "● Pill Daemon: Active"
                            font.family: Theme.fontUI
                            font.pixelSize: 10
                            color: "#4ade80"
                        }
                        Text {
                            text: "● Compositor: 60+ FPS"
                            font.family: Theme.fontUI
                            font.pixelSize: 10
                            color: Theme.dim
                        }
                    }
                }
            }
        }

        // Master Control Center Tiles (2x2 Grid)
        Card {
            title: "Quick Master Controls"
            subtitle: "Instant desktop mode overrides that take effect immediately across all monitors"
            icon: "bolt"

            Grid {
                width: parent.width
                columns: 2
                spacing: 12

                // Tile 1: Liquid Glass
                Rectangle {
                    width: (parent.width - 12) / 2
                    height: 74
                    radius: 12
                    color: Flags.pillBlur ? Qt.rgba(Theme.onGlow.r, Theme.onGlow.g, Theme.onGlow.b, 0.12) : Qt.rgba(Theme.border.r, Theme.border.g, Theme.border.b, 0.2)
                    border.color: Flags.pillBlur ? Theme.onGlow : Qt.rgba(255, 255, 255, 0.08)
                    border.width: 1

                    Row {
                        anchors.fill: parent
                        anchors.margins: 14
                        spacing: 12

                        Rectangle {
                            width: 44
                            height: 44
                            radius: 10
                            anchors.verticalCenter: parent.verticalCenter
                            color: Flags.pillBlur ? Theme.onGlow : Qt.rgba(255, 255, 255, 0.08)

                            GlyphIcon {
                                anchors.centerIn: parent
                                width: 22
                                height: 22
                                name: "sparkles"
                                color: Flags.pillBlur ? Theme.tileBg : Theme.dim
                                stroke: 2.0
                            }
                        }

                        Column {
                            width: parent.width - 44 - 44 - 24
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 2

                            Text {
                                text: "Liquid Glass"
                                font.family: Theme.fontUI
                                font.pixelSize: 13
                                font.weight: Font.DemiBold
                                color: Theme.bright
                            }

                            Text {
                                text: Flags.pillBlur ? "Translucent & Blur Active" : "Disabled"
                                font.family: Theme.fontUI
                                font.pixelSize: 11
                                color: Theme.dim
                            }
                        }

                        Switch {
                            anchors.verticalCenter: parent.verticalCenter
                            checked: Flags.pillBlur || false
                            onToggled: (st) => {
                                cmdProc.command = [Quickshell.env("HOME") + "/.config/hypr/scripts/liquid-glass.sh", st ? "on" : "off"];
                                cmdProc.running = true;
                            }
                        }
                    }
                }

                // Tile 2: Do Not Disturb
                Rectangle {
                    width: (parent.width - 12) / 2
                    height: 74
                    radius: 12
                    color: Flags.dnd ? Qt.rgba(Theme.onGlow.r, Theme.onGlow.g, Theme.onGlow.b, 0.12) : Qt.rgba(Theme.border.r, Theme.border.g, Theme.border.b, 0.2)
                    border.color: Flags.dnd ? Theme.onGlow : Qt.rgba(255, 255, 255, 0.08)
                    border.width: 1

                    Row {
                        anchors.fill: parent
                        anchors.margins: 14
                        spacing: 12

                        Rectangle {
                            width: 44
                            height: 44
                            radius: 10
                            anchors.verticalCenter: parent.verticalCenter
                            color: Flags.dnd ? Theme.onGlow : Qt.rgba(255, 255, 255, 0.08)

                            GlyphIcon {
                                anchors.centerIn: parent
                                width: 22
                                height: 22
                                name: "dnd"
                                color: Flags.dnd ? Theme.tileBg : Theme.dim
                                stroke: 2.0
                            }
                        }

                        Column {
                            width: parent.width - 44 - 44 - 24
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 2

                            Text {
                                text: "Do Not Disturb"
                                font.family: Theme.fontUI
                                font.pixelSize: 13
                                font.weight: Font.DemiBold
                                color: Theme.bright
                            }

                            Text {
                                text: Flags.dnd ? "Banners Silenced" : "Normal Notifications"
                                font.family: Theme.fontUI
                                font.pixelSize: 11
                                color: Theme.dim
                            }
                        }

                        Switch {
                            anchors.verticalCenter: parent.verticalCenter
                            checked: Flags.dnd
                            onToggled: (st) => Flags.dnd = st
                        }
                    }
                }

                // Tile 3: Keep-Awake
                Rectangle {
                    width: (parent.width - 12) / 2
                    height: 74
                    radius: 12
                    color: Flags.keepAwake ? Qt.rgba(Theme.onGlow.r, Theme.onGlow.g, Theme.onGlow.b, 0.12) : Qt.rgba(Theme.border.r, Theme.border.g, Theme.border.b, 0.2)
                    border.color: Flags.keepAwake ? Theme.onGlow : Qt.rgba(255, 255, 255, 0.08)
                    border.width: 1

                    Row {
                        anchors.fill: parent
                        anchors.margins: 14
                        spacing: 12

                        Rectangle {
                            width: 44
                            height: 44
                            radius: 10
                            anchors.verticalCenter: parent.verticalCenter
                            color: Flags.keepAwake ? Theme.onGlow : Qt.rgba(255, 255, 255, 0.08)

                            GlyphIcon {
                                anchors.centerIn: parent
                                width: 22
                                height: 22
                                name: "awake"
                                color: Flags.keepAwake ? Theme.tileBg : Theme.dim
                                stroke: 2.0
                            }
                        }

                        Column {
                            width: parent.width - 44 - 44 - 24
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 2

                            Text {
                                text: "Keep-Awake"
                                font.family: Theme.fontUI
                                font.pixelSize: 13
                                font.weight: Font.DemiBold
                                color: Theme.bright
                            }

                            Text {
                                text: Flags.keepAwake ? "Sleep Inhibited" : "Normal Sleep"
                                font.family: Theme.fontUI
                                font.pixelSize: 11
                                color: Theme.dim
                            }
                        }

                        Switch {
                            anchors.verticalCenter: parent.verticalCenter
                            checked: Flags.keepAwake
                            onToggled: (st) => Flags.keepAwake = st
                        }
                    }
                }

                // Tile 4: Game Mode
                Rectangle {
                    width: (parent.width - 12) / 2
                    height: 74
                    radius: 12
                    color: Flags.gameMode ? Qt.rgba(Theme.onGlow.r, Theme.onGlow.g, Theme.onGlow.b, 0.12) : Qt.rgba(Theme.border.r, Theme.border.g, Theme.border.b, 0.2)
                    border.color: Flags.gameMode ? Theme.onGlow : Qt.rgba(255, 255, 255, 0.08)
                    border.width: 1

                    Row {
                        anchors.fill: parent
                        anchors.margins: 14
                        spacing: 12

                        Rectangle {
                            width: 44
                            height: 44
                            radius: 10
                            anchors.verticalCenter: parent.verticalCenter
                            color: Flags.gameMode ? Theme.onGlow : Qt.rgba(255, 255, 255, 0.08)

                            GlyphIcon {
                                anchors.centerIn: parent
                                width: 22
                                height: 22
                                name: "gamepad"
                                color: Flags.gameMode ? Theme.tileBg : Theme.dim
                                stroke: 2.0
                            }
                        }

                        Column {
                            width: parent.width - 44 - 44 - 24
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 2

                            Text {
                                text: "Zero-Flicker Game Mode"
                                font.family: Theme.fontUI
                                font.pixelSize: 13
                                font.weight: Font.DemiBold
                                color: Theme.bright
                            }

                            Text {
                                text: Flags.gameMode ? "Max FPS • No Effects" : "Full Compositing"
                                font.family: Theme.fontUI
                                font.pixelSize: 11
                                color: Theme.dim
                            }
                        }

                        Switch {
                            anchors.verticalCenter: parent.verticalCenter
                            checked: Flags.gameMode
                            onToggled: (st) => {
                                cmdProc.command = [Quickshell.env("HOME") + "/.config/hypr/scripts/gamemode.sh"];
                                cmdProc.running = true;
                            }
                        }
                    }
                }
            }
        }

        // Shell Services & Daemons Card
        Card {
            title: "MasterR Shell Daemons & Health"
            subtitle: "Manage running Quickshell watchdogs, daemons, and compositor processes"
            icon: "cog"

            Grid {
                width: parent.width
                columns: 2
                spacing: 10

                Button {
                    width: (parent.width - 10) / 2
                    text: "Restart Pill Bar"
                    icon: "rotate-ccw"
                    variant: "secondary"
                    onClicked: {
                        cmdProc.command = ["bash", "-c", "pkill -f 'quickshell.*pill' || true; qs -c pill &"];
                        cmdProc.running = true;
                    }
                }

                Button {
                    width: (parent.width - 10) / 2
                    text: "Restart Lockscreen"
                    icon: "lock"
                    variant: "secondary"
                    onClicked: {
                        cmdProc.command = ["bash", "-c", "pkill -f 'quickshell.*lock' || true; qs -c lock &"];
                        cmdProc.running = true;
                    }
                }

                Button {
                    width: (parent.width - 10) / 2
                    text: "Reload Hyprland Config"
                    icon: "refresh-cw"
                    variant: "secondary"
                    onClicked: {
                        cmdProc.command = ["hyprctl", "reload"];
                        cmdProc.running = true;
                    }
                }

                Button {
                    width: (parent.width - 10) / 2
                    text: "Restart All Surfaces"
                    icon: "zap"
                    variant: "primary"
                    onClicked: {
                        cmdProc.command = [Quickshell.env("HOME") + "/.config/hypr/scripts/masterr", "restart"];
                        cmdProc.running = true;
                    }
                }
            }
        }

        // Backup & Snapshot Card
        Card {
            title: "Configuration Backup & Snapshots"
            subtitle: "Create timestamped archives of your configs and restore with one click"
            icon: "save"

            Row {
                width: parent.width
                spacing: 12

                Button {
                    width: (parent.width - 12) / 2
                    text: "Create Instant Backup"
                    icon: "download"
                    variant: "primary"
                    onClicked: {
                        cmdProc.command = ["bash", Quickshell.env("HOME") + "/.config/hypr/scripts/backup-restore.sh", "backup"];
                        cmdProc.running = true;
                    }
                }

                Button {
                    width: (parent.width - 12) / 2
                    text: "Restore Last Backup"
                    icon: "upload"
                    variant: "secondary"
                    onClicked: {
                        cmdProc.command = ["bash", Quickshell.env("HOME") + "/.config/hypr/scripts/backup-restore.sh", "restore"];
                        cmdProc.running = true;
                    }
                }
            }
        }
    }
}

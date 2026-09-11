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
            glyph: "電"
            title: "Power, Battery & Fans"
            subtitle: "ACPI power profiles, laptop fan curves, battery telemetry, and hypridle sleep timers."
        }

        // ACPI Power Profile
        Card {
            title: "System Power Profile"
            subtitle: "Balance energy efficiency against processor performance"
            icon: "bolt"

            SegmentedBar {
                label: "Active Power Profile"
                model: [
                    { label: "🌱 Power-Saver", value: "power-saver" },
                    { label: "⚖️ Balanced", value: "balanced" },
                    { label: "🚀 Performance", value: "performance" }
                ]
                currentIndex: Flags.powerProfile === "performance" ? 2 : (Flags.powerProfile === "power-saver" ? 0 : 1)
                onSelected: (idx, val) => {
                    Flags.powerProfile = val;
                    cmdProc.command = ["powerprofilesctl", "set", val];
                    cmdProc.running = true;
                }
            }
        }

        // Laptop Fan Controller
        Card {
            title: "Laptop Fan Speed Controller"
            subtitle: "ACPI thermal cooling modes for Lenovo Legion / LOQ / IdeaPad and ASUS laptops"
            icon: "fan"

            SegmentedBar {
                label: "Fan Mode Profile"
                model: [
                    { label: "🤖 Auto (BIOS)", value: "auto" },
                    { label: "🤫 Quiet", value: "quiet" },
                    { label: "⚖️ Balanced", value: "balanced" },
                    { label: "💨 Maximum", value: "performance" }
                ]
                currentIndex: Flags.fanSpeed === "quiet" ? 1 : (Flags.fanSpeed === "performance" ? 3 : (Flags.fanSpeed === "balanced" ? 2 : 0))
                onSelected: (idx, val) => {
                    Flags.fanSpeed = val;
                    cmdProc.command = [Quickshell.env("HOME") + "/.config/hypr/scripts/fan-speed.sh", val];
                    cmdProc.running = true;
                }
            }
        }

        // Hypridle Sleep & Lock Timers
        Card {
            title: "Idle, Lock & Sleep Timers (hypridle)"
            subtitle: "Configure automatic screen locking, monitor power-down, and system suspend"
            icon: "clock"

            Slider {
                label: "Auto-Lock Timeout"
                description: "Minutes of inactivity before the screen locks with audio visualizer"
                from: 1
                to: 30
                value: Flags.idleLockMin || 5
                stepSize: 1
                unit: " min"
                onMoved: (v) => Flags.idleLockMin = Math.round(v)
            }

            Rectangle { width: parent.width; height: 1; color: Theme.hair }

            Slider {
                label: "Screen Power Off (DPMS)"
                description: "Minutes before monitors power down to save electricity"
                from: 1
                to: 45
                value: Flags.idleScreenOffMin || 6
                stepSize: 1
                unit: " min"
                onMoved: (v) => Flags.idleScreenOffMin = Math.round(v)
            }

            Rectangle { width: parent.width; height: 1; color: Theme.hair }

            Slider {
                label: "System Suspend Timeout"
                description: "Minutes before system enters low-power sleep (0 = disabled)"
                from: 0
                to: 120
                value: Flags.idleSuspendMin || 0
                stepSize: 5
                unit: " min"
                onMoved: (v) => Flags.idleSuspendMin = Math.round(v)
            }
        }
    }
}

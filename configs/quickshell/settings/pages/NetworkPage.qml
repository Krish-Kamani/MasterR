import QtQuick
import Quickshell.Io
import "../Singletons"
import "../components"

Flickable {
    id: root

    contentHeight: contentCol.implicitHeight + 40
    clip: true

    property bool wifiEnabled: true
    property bool btEnabled: true

    Process {
        id: cmdProc
        command: ["true"]
    }

    Process {
        id: getNetProc
        command: ["python3", "-c", "import subprocess, json\nw = False\ntry:\n    out = subprocess.check_output(['nmcli', 'radio', 'wifi'], text=True)\n    w = 'enabled' in out\nexcept:\n    pass\nb = False\ntry:\n    out = subprocess.check_output(['bluetoothctl', 'show'], text=True)\n    b = 'Powered: yes' in out\nexcept:\n    pass\nprint(json.dumps({'wifi': w, 'bt': b}))"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    var data = JSON.parse(this.text);
                    if (data.wifi !== undefined) root.wifiEnabled = data.wifi;
                    if (data.bt !== undefined) root.btEnabled = data.bt;
                } catch (e) {}
            }
        }
    }

    Column {
        id: contentCol
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: 24
        spacing: 20

        PageHeader {
            glyph: "接"
            title: "Wi-Fi & Bluetooth"
            subtitle: "Manage wireless radios, network connections, and Bluetooth peripheral devices."
        }

        // Wi-Fi Management
        Card {
            title: "Wi-Fi Wireless Networking"
            subtitle: "NetworkManager 802.11 wireless connectivity"
            icon: "wifi"

            Switch {
                label: "Wi-Fi Radio Power"
                description: "Enable or disable wireless network hardware"
                checked: root.wifiEnabled
                icon: "wifi"
                onToggled: (st) => {
                    root.wifiEnabled = st;
                    cmdProc.command = ["nmcli", "radio", "wifi", st ? "on" : "off"];
                    cmdProc.running = true;
                }
            }

            Rectangle { width: parent.width; height: 1; color: Theme.hair }

            Row {
                width: parent.width
                spacing: 12

                Button {
                    text: "Scan Available Wi-Fi Networks"
                    icon: "rotate-ccw"
                    variant: "primary"
                    onClicked: {
                        cmdProc.command = ["nmcli", "dev", "wifi", "rescan"];
                        cmdProc.running = true;
                    }
                }

                Button {
                    text: "Open Network Connections..."
                    icon: "cog"
                    variant: "secondary"
                    onClicked: {
                        cmdProc.command = ["nm-connection-editor"];
                        cmdProc.running = true;
                    }
                }
            }
        }

        // Bluetooth Management
        Card {
            title: "Bluetooth Wireless Adapter"
            subtitle: "BlueZ controller, audio headphones, mice, keyboards, and controllers"
            icon: "bluetooth"

            Switch {
                label: "Bluetooth Radio Power"
                description: "Enable or disable the local Bluetooth adapter"
                checked: root.btEnabled
                icon: "bluetooth"
                onToggled: (st) => {
                    root.btEnabled = st;
                    cmdProc.command = ["bluetoothctl", "power", st ? "on" : "off"];
                    cmdProc.running = true;
                }
            }

            Rectangle { width: parent.width; height: 1; color: Theme.hair }

            Row {
                width: parent.width
                spacing: 12

                Button {
                    text: "Scan for Bluetooth Devices"
                    icon: "rotate-ccw"
                    variant: "primary"
                    onClicked: {
                        cmdProc.command = ["bluetoothctl", "--timeout", "10", "scan", "on"];
                        cmdProc.running = true;
                    }
                }

                Button {
                    text: "Open Bluetooth Terminal..."
                    icon: "cog"
                    variant: "secondary"
                    onClicked: {
                        cmdProc.command = ["ghostty", "--class=masterr-floating", "-e", "bluetoothctl"];
                        cmdProc.running = true;
                    }
                }
            }
        }
    }
}

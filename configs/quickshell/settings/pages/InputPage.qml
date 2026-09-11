import QtQuick
import Quickshell
import Quickshell.Io
import "../Singletons"
import "../components"

Flickable {
    id: root

    contentHeight: contentCol.implicitHeight + 40
    clip: true

    property real sens: 0.0
    property int accelIdx: 1
    property bool natScroll: true
    property bool leftHand: false
    property bool tapClick: true
    property bool tapDrag: true
    property bool dwt: true
    property int repRate: 40
    property int repDelay: 400

    Process {
        id: cmdProc
        command: ["true"]
    }

    Process {
        id: getInputProc
        command: ["python3", Quickshell.env("HOME") + "/.config/hypr/scripts/hypr-config.py", "get-input"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    var data = JSON.parse(this.text);
                    root.sens = data.sensitivity !== undefined ? data.sensitivity : 0.0;
                    root.accelIdx = (data.accel_profile === "adaptive") ? 0 : 1;
                    root.natScroll = data.natural_scroll !== undefined ? data.natural_scroll : true;
                    root.leftHand = data.left_handed !== undefined ? data.left_handed : false;
                    root.tapClick = data.tap_to_click !== undefined ? data.tap_to_click : true;
                    root.tapDrag = data.tap_and_drag !== undefined ? data.tap_and_drag : true;
                    root.dwt = data.disable_while_typing !== undefined ? data.disable_while_typing : true;
                    root.repRate = data.repeat_rate || 40;
                    root.repDelay = data.repeat_delay || 400;
                } catch (e) {}
            }
        }
    }

    function applyHypr(key, val) {
        cmdProc.command = ["python3", Quickshell.env("HOME") + "/.config/hypr/scripts/hypr-config.py", "set-input", key, val.toString()];
        cmdProc.running = true;
    }

    Column {
        id: contentCol
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: 24
        spacing: 20

        PageHeader {
            glyph: "入"
            title: "Input & Gestures"
            subtitle: "Pointer speed, natural scrolling, touchpad tap-to-click, keyboard repeat rates, and gestures."
        }

        // Mouse & Pointer
        Card {
            title: "Mouse & Pointer Tracking"
            subtitle: "Cursor sensitivity and acceleration profiles"
            icon: "cursor"

            Slider {
                label: "Cursor Sensitivity"
                description: "Pointer tracking speed factor (-1.0 to 1.0)"
                from: -1.0
                to: 1.0
                value: root.sens
                stepSize: 0.05
                decimals: 2
                onMoved: (v) => {
                    root.sens = v;
                    applyHypr("sensitivity", v);
                }
            }

            Rectangle { width: parent.width; height: 1; color: Theme.hair }

            SegmentedBar {
                label: "Acceleration Profile"
                model: [
                    { label: "⚡ Adaptive (Dynamic Speed)", value: "adaptive" },
                    { label: "🎯 Flat (Raw 1:1 Sensor Input)", value: "flat" }
                ]
                currentIndex: root.accelIdx
                onSelected: (idx, val) => {
                    root.accelIdx = idx;
                    applyHypr("accel_profile", val);
                }
            }

            Rectangle { width: parent.width; height: 1; color: Theme.hair }

            Switch {
                label: "Natural Scrolling (Inverted)"
                description: "Scroll content in the direction of your finger swipe"
                checked: root.natScroll
                onToggled: (st) => {
                    root.natScroll = st;
                    applyHypr("natural_scroll", st ? "true" : "false");
                }
            }

            Rectangle { width: parent.width; height: 1; color: Theme.hair }

            Switch {
                label: "Left-Handed Mouse Mode"
                description: "Swap primary left and secondary right click mouse buttons"
                checked: root.leftHand
                onToggled: (st) => {
                    root.leftHand = st;
                    applyHypr("left_handed", st ? "true" : "false");
                }
            }
        }

        // Touchpad Controls
        Card {
            title: "Touchpad & Gestures"
            subtitle: "Multi-touch gestures, tapping behaviors, and scroll physics"
            icon: "mouse"

            Switch {
                label: "Tap-to-Click"
                description: "Tap touchpad surface with one finger for left click"
                checked: root.tapClick
                onToggled: (st) => {
                    root.tapClick = st;
                    applyHypr("tap_to_click", st ? "true" : "false");
                }
            }

            Rectangle { width: parent.width; height: 1; color: Theme.hair }

            Switch {
                label: "Tap-and-Drag"
                description: "Double tap and hold to drag windows or select text"
                checked: root.tapDrag
                onToggled: (st) => {
                    root.tapDrag = st;
                    applyHypr("tap_and_drag", st ? "true" : "false");
                }
            }

            Rectangle { width: parent.width; height: 1; color: Theme.hair }

            Switch {
                label: "Disable Touchpad While Typing"
                description: "Prevent palm accidental touches from moving cursor while typing"
                checked: root.dwt
                onToggled: (st) => {
                    root.dwt = st;
                    applyHypr("disable_while_typing", st ? "true" : "false");
                }
            }
        }

        // Keyboard Settings
        Card {
            title: "Keyboard & Repeat Timing"
            subtitle: "Keyboard layout, key repeat delay, and auto-repeat speed"
            icon: "keyboard"

            Slider {
                label: "Key Repeat Rate"
                description: "Characters per second when a key is held down"
                from: 15
                to: 60
                value: root.repRate
                stepSize: 5
                unit: " Hz"
                onMoved: (v) => {
                    root.repRate = Math.round(v);
                    applyHypr("repeat_rate", Math.round(v));
                }
            }

            Rectangle { width: parent.width; height: 1; color: Theme.hair }

            Slider {
                label: "Key Repeat Delay"
                description: "Milliseconds to wait before character auto-repeat initiates"
                from: 150
                to: 600
                value: root.repDelay
                stepSize: 25
                unit: " ms"
                onMoved: (v) => {
                    root.repDelay = Math.round(v);
                    applyHypr("repeat_delay", Math.round(v));
                }
            }
        }
    }
}

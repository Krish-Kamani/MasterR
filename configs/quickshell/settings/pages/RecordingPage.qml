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
            glyph: "録"
            title: "Capture & Screen Recording"
            subtitle: "GPU hardware screen recording (gpu-screen-recorder), audio sources, FPS, and screenshots."
        }

        // Screen Recorder Settings
        Card {
            title: "GPU Hardware Screen Recorder"
            subtitle: "NVENC / VAAPI accelerated zero-latency video recording"
            icon: "record"

            SegmentedBar {
                label: "Target Recording Framerate"
                model: [
                    { label: "30 FPS", value: 30 },
                    { label: "60 FPS (Default)", value: 60 },
                    { label: "120 FPS (High-Refresh)", value: 120 }
                ]
                currentIndex: Flags.recordFps === 120 ? 2 : (Flags.recordFps === 30 ? 0 : 1)
                onSelected: (idx, val) => Flags.recordFps = val
            }

            Rectangle { width: parent.width; height: 1; color: Theme.hair }

            SegmentedBar {
                label: "Video Encoding Quality"
                model: [
                    { label: "Medium", value: "medium" },
                    { label: "High (Recommended)", value: "high" },
                    { label: "Ultra", value: "ultra" }
                ]
                currentIndex: Flags.recordQuality === "ultra" ? 2 : (Flags.recordQuality === "medium" ? 0 : 1)
                onSelected: (idx, val) => Flags.recordQuality = val
            }

            Rectangle { width: parent.width; height: 1; color: Theme.hair }

            Switch {
                label: "Capture Mouse Pointer"
                description: "Render visible mouse cursor in the output video recording"
                checked: Flags.recordCursor !== false
                icon: "cursor"
                onToggled: (st) => Flags.recordCursor = st
            }

            Rectangle { width: parent.width; height: 1; color: Theme.hair }

            Switch {
                label: "Record System Desktop Audio"
                description: "Include application audio, music, and game sounds"
                checked: Flags.recordDesktop !== false
                icon: "speaker"
                onToggled: (st) => Flags.recordDesktop = st
            }

            Rectangle { width: parent.width; height: 1; color: Theme.hair }

            Switch {
                label: "Record Microphone Voice Audio"
                description: "Mix microphone input commentary into the recording"
                checked: Flags.recordMic !== false
                icon: "mic"
                onToggled: (st) => Flags.recordMic = st
            }

            Rectangle { width: parent.width; height: 1; color: Theme.hair }

            Slider {
                label: "Start Countdown Timer"
                description: "Seconds to delay before recording begins"
                from: 0
                to: 10
                value: Flags.recordCountdown || 5
                stepSize: 1
                unit: " s"
                onMoved: (v) => Flags.recordCountdown = Math.round(v)
            }
        }

        // Screenshots Suite
        Card {
            title: "Screenshots & Satty Annotation"
            subtitle: "RiShot Wayland tool and styled screenshot editor matching your rice theme"
            icon: "sparkles"

            Row {
                width: parent.width
                spacing: 12

                Button {
                    text: "Open Screenshots Folder"
                    icon: "folder"
                    variant: "primary"
                    onClicked: {
                        cmdProc.command = ["dolphin", Quickshell.env("HOME") + "/Pictures/Screenshots"];
                        cmdProc.running = true;
                    }
                }

                Button {
                    text: "Open Recordings Folder"
                    icon: "folder"
                    variant: "secondary"
                    onClicked: {
                        cmdProc.command = ["dolphin", Flags.recordDir || (Quickshell.env("HOME") + "/Videos")];
                        cmdProc.running = true;
                    }
                }
            }
        }
    }
}

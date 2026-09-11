import QtQuick
import Quickshell.Io
import "../Singletons"
import "../components"

Flickable {
    id: root

    contentHeight: contentCol.implicitHeight + 40
    clip: true

    property int sinkVol: 65
    property bool sinkMuted: false
    property int sourceVol: 80
    property bool sourceMuted: false

    Process {
        id: cmdProc
        command: ["true"]
    }

    Process {
        id: getAudioProc
        command: ["python3", "-c", "import subprocess, json, re\ndef get_v(t):\n    try:\n        out = subprocess.check_output(['wpctl', 'get-volume', t], text=True)\n        m = re.search(r'Volume:\\s*([\\d\\.]+)', out)\n        v = int(round(float(m.group(1)) * 100)) if m else 50\n        return {'vol': v, 'muted': '[MUTED]' in out}\n    except Exception:\n        return {'vol': 50, 'muted': False}\nprint(json.dumps({'sink': get_v('@DEFAULT_AUDIO_SINK@'), 'source': get_v('@DEFAULT_AUDIO_SOURCE@')}))"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    var data = JSON.parse(this.text);
                    if (data.sink) {
                        root.sinkVol = data.sink.vol;
                        root.sinkMuted = data.sink.muted;
                    }
                    if (data.source) {
                        root.sourceVol = data.source.vol;
                        root.sourceMuted = data.source.muted;
                    }
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
            glyph: "音"
            title: "Sound & Audio Mixer"
            subtitle: "PipeWire output devices, microphone inputs, volume faders, and audio visualizers."
        }

        // Master Output Volume
        Card {
            title: "Master Audio Output"
            subtitle: "System default audio playback sink and volume level"
            icon: "speaker"

            Slider {
                label: "Output Master Volume"
                description: "PipeWire master volume level"
                from: 0
                to: 100
                value: root.sinkVol
                stepSize: 1
                unit: "%"
                onMoved: (v) => {
                    root.sinkVol = Math.round(v);
                    cmdProc.command = ["wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@", (v / 100).toFixed(2)];
                    cmdProc.running = true;
                }
            }

            Rectangle { width: parent.width; height: 1; color: Theme.hair }

            Switch {
                label: "Mute Output Audio"
                description: "Silence all audio playback from default sink"
                checked: root.sinkMuted
                icon: "speaker-off"
                onToggled: (st) => {
                    root.sinkMuted = st;
                    cmdProc.command = ["wpctl", "set-mute", "@DEFAULT_AUDIO_SINK@", st ? "1" : "0"];
                    cmdProc.running = true;
                }
            }
        }

        // Microphone & Input
        Card {
            title: "Microphone Input & Capture"
            subtitle: "Default audio input source and recording gain"
            icon: "mic"

            Slider {
                label: "Microphone Input Gain"
                description: "Input recording gain for voice calls and recording"
                from: 0
                to: 100
                value: root.sourceVol
                stepSize: 1
                unit: "%"
                onMoved: (v) => {
                    root.sourceVol = Math.round(v);
                    cmdProc.command = ["wpctl", "set-volume", "@DEFAULT_AUDIO_SOURCE@", (v / 100).toFixed(2)];
                    cmdProc.running = true;
                }
            }

            Rectangle { width: parent.width; height: 1; color: Theme.hair }

            Switch {
                label: "Mute Microphone"
                description: "Block all microphone audio capture hardware-wide"
                checked: root.sourceMuted
                icon: "mic-off"
                onToggled: (st) => {
                    root.sourceMuted = st;
                    cmdProc.command = ["wpctl", "set-mute", "@DEFAULT_AUDIO_SOURCE@", st ? "1" : "0"];
                    cmdProc.running = true;
                }
            }
        }

        // Cava Audio Visualizer
        Card {
            title: "Cava Real-Time Spectrum Visualizer"
            subtitle: "Audio-reactive spectrum bars dancing to your music in the Pill and Lockscreen"
            icon: "music"

            Switch {
                label: "Enable Music Spectrum Visualizer"
                description: "Render live dancing Cava visualizer bars when audio is playing"
                checked: Flags.musicViz !== false
                icon: "music"
                onToggled: (st) => Flags.musicViz = st
            }
        }
    }
}

import QtQuick
import Quickshell
import Quickshell.Io
import "../Singletons"
import "../components"

Flickable {
    id: root

    contentHeight: contentCol.implicitHeight + 60
    clip: true

    property real activeOpacity: 0.90
    property real inactiveOpacity: 0.65
    property int rounding: 16
    property int borderSize: 2
    property int gapsIn: 8
    property int gapsOut: 16
    property string layout: "dwindle"
    property bool blurEnabled: true
    property int blurSize: 5
    property int blurPasses: 2
    property bool shadowEnabled: true
    property int shadowRange: 24

    property bool isLoaded: false

    Process {
        id: cmdProc
        command: ["true"]
    }

    // Read current live settings on load
    Process {
        id: getSettingsProc
        command: ["python3", Quickshell.env("HOME") + "/.config/hypr/scripts/hypr-config.py", "get"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    var cfg = JSON.parse(this.text);
                    if (cfg.active_opacity !== undefined) root.activeOpacity = cfg.active_opacity;
                    if (cfg.inactive_opacity !== undefined) root.inactiveOpacity = cfg.inactive_opacity;
                    if (cfg.rounding !== undefined) root.rounding = cfg.rounding;
                    if (cfg.border_size !== undefined) root.borderSize = cfg.border_size;
                    if (cfg.gaps_in !== undefined) root.gapsIn = cfg.gaps_in;
                    if (cfg.gaps_out !== undefined) root.gapsOut = cfg.gaps_out;
                    if (cfg.layout !== undefined) root.layout = cfg.layout;
                    if (cfg.blur_enabled !== undefined) root.blurEnabled = cfg.blur_enabled;
                    if (cfg.blur_size !== undefined) root.blurSize = cfg.blur_size;
                    if (cfg.blur_passes !== undefined) root.blurPasses = cfg.blur_passes;
                    if (cfg.shadow_enabled !== undefined) root.shadowEnabled = cfg.shadow_enabled;
                    if (cfg.shadow_range !== undefined) root.shadowRange = cfg.shadow_range;
                    root.isLoaded = true;
                } catch (e) {
                    root.isLoaded = true;
                }
            }
        }
    }

    function applySetting(key, val) {
        var script = Quickshell.env("HOME") + "/.config/hypr/scripts/hypr-config.py";
        cmdProc.command = ["python3", script, "set", key, val.toString()];
        cmdProc.running = true;
    }

    function applyPreset(name) {
        if (name === "liquid") {
            root.activeOpacity = 0.90; applySetting("active_opacity", 0.90);
            root.inactiveOpacity = 0.65; applySetting("inactive_opacity", 0.65);
            root.rounding = 16; applySetting("rounding", 16);
            root.borderSize = 2; applySetting("border_size", 2);
            root.gapsIn = 8; applySetting("gaps_in", 8);
            root.gapsOut = 16; applySetting("gaps_out", 16);
            root.blurEnabled = true; applySetting("blur_enabled", true);
            root.blurSize = 5; applySetting("blur_size", 5);
            root.blurPasses = 2; applySetting("blur_passes", 2);
            root.shadowEnabled = true; applySetting("shadow_enabled", true);
            root.shadowRange = 24; applySetting("shadow_range", 24);
        } else if (name === "translucent") {
            root.activeOpacity = 0.78; applySetting("active_opacity", 0.78);
            root.inactiveOpacity = 0.45; applySetting("inactive_opacity", 0.45);
            root.rounding = 20; applySetting("rounding", 20);
            root.borderSize = 2; applySetting("border_size", 2);
            root.gapsIn = 12; applySetting("gaps_in", 12);
            root.gapsOut = 24; applySetting("gaps_out", 24);
            root.blurEnabled = true; applySetting("blur_enabled", true);
            root.blurSize = 8; applySetting("blur_size", 8);
            root.blurPasses = 3; applySetting("blur_passes", 3);
            root.shadowEnabled = true; applySetting("shadow_enabled", true);
            root.shadowRange = 32; applySetting("shadow_range", 32);
        } else if (name === "opaque") {
            root.activeOpacity = 1.00; applySetting("active_opacity", 1.00);
            root.inactiveOpacity = 0.95; applySetting("inactive_opacity", 0.95);
            root.rounding = 12; applySetting("rounding", 12);
            root.borderSize = 1; applySetting("border_size", 1);
            root.gapsIn = 6; applySetting("gaps_in", 6);
            root.gapsOut = 12; applySetting("gaps_out", 12);
            root.blurEnabled = false; applySetting("blur_enabled", false);
            root.shadowEnabled = true; applySetting("shadow_enabled", true);
            root.shadowRange = 16; applySetting("shadow_range", 16);
        } else if (name === "borderless") {
            root.activeOpacity = 0.95; applySetting("active_opacity", 0.95);
            root.inactiveOpacity = 0.75; applySetting("inactive_opacity", 0.75);
            root.rounding = 0; applySetting("rounding", 0);
            root.borderSize = 0; applySetting("border_size", 0);
            root.gapsIn = 0; applySetting("gaps_in", 0);
            root.gapsOut = 0; applySetting("gaps_out", 0);
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
            glyph: "窓"
            title: "Windows & Hyprland"
            subtitle: "Fine-tune window translucency, specular borders, corner curvature, gaps, and dual-pass blur."
            badgeText: "REALTIME EVAL"
        }

        // Live Interactive Window Preview Canvas Card
        Rectangle {
            width: parent.width
            height: 150
            radius: 16
            color: Qt.rgba(Theme.cardBot.r, Theme.cardBot.g, Theme.cardBot.b, 0.72)
            border.color: Qt.rgba(255, 255, 255, 0.09)
            border.width: 1
            clip: true

            // Specular highlight
            Rectangle {
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.margins: 16
                height: 1
                color: Qt.rgba(255, 255, 255, 0.22)
            }

            // Simulated desktop monitor preview
            Rectangle {
                anchors.fill: parent
                anchors.margins: 12
                radius: 12
                color: "#181210"
                clip: true

                // Wallpaper gradient simulation
                Rectangle {
                    anchors.fill: parent
                    gradient: Gradient {
                        GradientStop { position: 0.0; color: Theme.vermDeep }
                        GradientStop { position: 0.5; color: "#1a120e" }
                        GradientStop { position: 1.0; color: Theme.cardBot }
                    }
                }

                // Simulated Windows Layout Container
                Row {
                    anchors.centerIn: parent
                    spacing: Math.max(4, root.gapsIn * 0.6)

                    // Window 1: Active Focused Window
                    Rectangle {
                        width: 240
                        height: 104
                        radius: Math.max(2, root.rounding * 0.4)
                        color: Qt.rgba(Theme.cardTop.r, Theme.cardTop.g, Theme.cardTop.b, root.activeOpacity)
                        border.color: Theme.onGlow
                        border.width: Math.max(1, root.borderSize)

                        Behavior on radius { NumberAnimation { duration: 120 } }
                        Behavior on color { ColorAnimation { duration: 120 } }
                        Behavior on border.width { NumberAnimation { duration: 120 } }

                        Column {
                            anchors.fill: parent
                            anchors.margins: 8
                            spacing: 6

                            // Titlebar
                            Row {
                                width: parent.width
                                spacing: 5

                                Rectangle { width: 8; height: 8; radius: 4; color: "#ef4444" }
                                Rectangle { width: 8; height: 8; radius: 4; color: "#eab308" }
                                Rectangle { width: 8; height: 8; radius: 4; color: "#22c55e" }

                                Text {
                                    text: "Focused Active Window"
                                    font.family: Theme.fontUI
                                    font.pixelSize: 9
                                    font.weight: Font.Bold
                                    color: Theme.bright
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                            }

                            Rectangle {
                                width: parent.width
                                height: 1
                                color: Qt.rgba(255, 255, 255, 0.1)
                            }

                            Text {
                                text: "Opacity: " + (root.activeOpacity * 100).toFixed(0) + "% • Radius: " + root.rounding + "px"
                                font.family: Theme.fontMono
                                font.pixelSize: 9
                                color: Theme.onGlow
                            }
                        }
                    }

                    // Window 2: Inactive Window
                    Rectangle {
                        width: 180
                        height: 104
                        radius: Math.max(2, root.rounding * 0.4)
                        color: Qt.rgba(Theme.cardBot.r, Theme.cardBot.g, Theme.cardBot.b, root.inactiveOpacity)
                        border.color: Qt.rgba(255, 255, 255, 0.15)
                        border.width: Math.max(1, root.borderSize)

                        Behavior on radius { NumberAnimation { duration: 120 } }
                        Behavior on color { ColorAnimation { duration: 120 } }

                        Column {
                            anchors.fill: parent
                            anchors.margins: 8
                            spacing: 6

                            Row {
                                width: parent.width
                                spacing: 5

                                Rectangle { width: 8; height: 8; radius: 4; color: Qt.rgba(255, 255, 255, 0.2) }
                                Rectangle { width: 8; height: 8; radius: 4; color: Qt.rgba(255, 255, 255, 0.2) }
                                Rectangle { width: 8; height: 8; radius: 4; color: Qt.rgba(255, 255, 255, 0.2) }

                                Text {
                                    text: "Background Window"
                                    font.family: Theme.fontUI
                                    font.pixelSize: 9
                                    color: Theme.dim
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                            }

                            Rectangle {
                                width: parent.width
                                height: 1
                                color: Qt.rgba(255, 255, 255, 0.08)
                            }

                            Text {
                                text: "Opacity: " + (root.inactiveOpacity * 100).toFixed(0) + "%"
                                font.family: Theme.fontMono
                                font.pixelSize: 9
                                color: Theme.dim
                            }
                        }
                    }
                }

                // Tag on bottom right of preview
                Rectangle {
                    anchors.bottom: parent.bottom
                    anchors.right: parent.right
                    anchors.margins: 8
                    height: 20
                    width: prevTag.implicitWidth + 12
                    radius: 5
                    color: Qt.rgba(0, 0, 0, 0.65)
                    border.color: Qt.rgba(255, 255, 255, 0.15)
                    border.width: 1

                    Text {
                        id: prevTag
                        anchors.centerIn: parent
                        text: "LIVE GEOMETRY PREVIEW"
                        font.family: Theme.fontUI
                        font.pixelSize: 8
                        font.weight: Font.Bold
                        color: Theme.onGlow
                    }
                }
            }
        }

        // Quick Preset Profiles Card
        Card {
            title: "Window Style Presets"
            subtitle: "1-Click aesthetic geometry and transparency profiles applied live"
            icon: "sparkles"

            Row {
                width: parent.width
                spacing: 12

                Button {
                    text: "💧 Liquid Glass (Default)"
                    variant: "primary"
                    onClicked: root.applyPreset("liquid")
                }

                Button {
                    text: "✨ Ultra Translucent"
                    variant: "secondary"
                    onClicked: root.applyPreset("translucent")
                }

                Button {
                    text: "⬛ Crisp Solid"
                    variant: "secondary"
                    onClicked: root.applyPreset("opaque")
                }

                Button {
                    text: "📐 Edge-to-Edge"
                    variant: "secondary"
                    onClicked: root.applyPreset("borderless")
                }
            }
        }

        // Opacity & Curvature Card
        Card {
            title: "Window Opacity & Curvature"
            subtitle: "Controls window background transparency and rounded corner geometry"
            icon: "app-window"

            Slider {
                label: "Active Window Opacity"
                description: "Opacity of the currently focused window"
                from: 0.2
                to: 1.0
                value: root.activeOpacity
                stepSize: 0.02
                decimals: 2
                onMoved: (v) => {
                    root.activeOpacity = v;
                    root.applySetting("active_opacity", v);
                }
            }

            Rectangle { width: parent.width; height: 1; color: Theme.hair }

            Slider {
                label: "Inactive Window Opacity"
                description: "Opacity of unfocused background windows"
                from: 0.2
                to: 1.0
                value: root.inactiveOpacity
                stepSize: 0.02
                decimals: 2
                onMoved: (v) => {
                    root.inactiveOpacity = v;
                    root.applySetting("inactive_opacity", v);
                }
            }

            Rectangle { width: parent.width; height: 1; color: Theme.hair }

            Slider {
                label: "Window Corner Radius"
                description: "Corner curvature radius in pixels"
                from: 0
                to: 36
                value: root.rounding
                stepSize: 1
                unit: "px"
                onMoved: (v) => {
                    root.rounding = Math.round(v);
                    root.applySetting("rounding", Math.round(v));
                }
            }

            Rectangle { width: parent.width; height: 1; color: Theme.hair }

            Slider {
                label: "Window Border Thickness"
                description: "Width of specular glass borders around windows"
                from: 0
                to: 8
                value: root.borderSize
                stepSize: 1
                unit: "px"
                onMoved: (v) => {
                    root.borderSize = Math.round(v);
                    root.applySetting("border_size", Math.round(v));
                }
            }
        }

        // Window Gaps & Padding Card
        Card {
            title: "Window Gaps & Spacing"
            subtitle: "Spacing between adjacent tiled windows and outer screen margins"
            icon: "grid"

            Slider {
                label: "Inner Gaps (Between Windows)"
                description: "Gap spacing between adjacent tiled windows"
                from: 0
                to: 32
                value: root.gapsIn
                stepSize: 1
                unit: "px"
                onMoved: (v) => {
                    root.gapsIn = Math.round(v);
                    root.applySetting("gaps_in", Math.round(v));
                }
            }

            Rectangle { width: parent.width; height: 1; color: Theme.hair }

            Slider {
                label: "Outer Gaps (Screen Margins)"
                description: "Margin between windows and the display edges"
                from: 0
                to: 48
                value: root.gapsOut
                stepSize: 1
                unit: "px"
                onMoved: (v) => {
                    root.gapsOut = Math.round(v);
                    root.applySetting("gaps_out", Math.round(v));
                }
            }

            Rectangle { width: parent.width; height: 1; color: Theme.hair }

            SegmentedBar {
                label: "Tiling Layout Engine"
                model: [
                    { label: "🌀 Dwindle (Dynamic Spiral BSP)", value: "dwindle" },
                    { label: "📚 Master (Master & Stacked Slaves)", value: "master" }
                ]
                currentIndex: root.layout === "master" ? 1 : 0
                onSelected: (idx, val) => {
                    root.layout = val;
                    root.applySetting("layout", val);
                }
            }
        }

        // Dual-Pass Blur & Frosted Glass Card
        Card {
            title: "Dual-Pass Kawase Blur & Translucency"
            subtitle: "GPU accelerated frosted glass refraction behind transparent surfaces"
            icon: "waves"

            Switch {
                label: "Enable Background Blur"
                description: "Applies dual-pass Kawase blur beneath all translucent windows and overlays"
                checked: root.blurEnabled
                onToggled: (st) => {
                    root.blurEnabled = st;
                    root.applySetting("blur_enabled", st);
                }
            }

            Rectangle { width: parent.width; height: 1; color: Theme.hair }

            Slider {
                label: "Blur Radius (Kernel Size)"
                description: "Spread size of the Gaussian / Kawase blur kernel"
                from: 1
                to: 16
                value: root.blurSize
                stepSize: 1
                unit: "px"
                enabled: root.blurEnabled
                onMoved: (v) => {
                    root.blurSize = Math.round(v);
                    root.applySetting("blur_size", Math.round(v));
                }
            }

            Rectangle { width: parent.width; height: 1; color: Theme.hair }

            Slider {
                label: "Blur Quality Passes"
                description: "Number of recursive blur convolution iterations"
                from: 1
                to: 5
                value: root.blurPasses
                stepSize: 1
                enabled: root.blurEnabled
                onMoved: (v) => {
                    root.blurPasses = Math.round(v);
                    root.applySetting("blur_passes", Math.round(v));
                }
            }
        }

        // Shadows & Depth Card
        Card {
            title: "Window Drop Shadows & Elevation"
            subtitle: "Simulated light projection and elevation depth behind floating and tiled windows"
            icon: "sun"

            Switch {
                label: "Enable Window Drop Shadows"
                description: "Renders soft directional shadows beneath active and inactive windows"
                checked: root.shadowEnabled
                onToggled: (st) => {
                    root.shadowEnabled = st;
                    root.applySetting("shadow_enabled", st);
                }
            }

            Rectangle { width: parent.width; height: 1; color: Theme.hair }

            Slider {
                label: "Shadow Spread Range"
                description: "Distance reach of the shadow falloff in pixels"
                from: 4
                to: 64
                value: root.shadowRange
                stepSize: 2
                unit: "px"
                enabled: root.shadowEnabled
                onMoved: (v) => {
                    root.shadowRange = Math.round(v);
                    root.applySetting("shadow_range", Math.round(v));
                }
            }
        }
    }
}

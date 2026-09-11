import QtQuick
import "../Singletons"

/**
 * Modern macOS / VisionOS inspired Liquid Glass Sidebar for MasterR Settings.
 */
Rectangle {
    id: root

    property string currentCategory: Nav.currentCategory
    property string filterText: ""

    signal categorySelected(string catId)

    width: 270
    color: Qt.rgba(Theme.cardBot.r, Theme.cardBot.g, Theme.cardBot.b, 0.65)
    border.color: "transparent"

    // Right subtle separator hairline
    Rectangle {
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.right: parent.right
        width: 1
        color: Qt.rgba(255, 255, 255, 0.08)
    }

    readonly property var sections: [
        {
            title: "ESSENTIALS",
            items: [
                { id: "overview",       name: "System & Overview", glyph: "統", icon: "cpu", color1: "#3b82f6", color2: "#1d4ed8" },
                { id: "appearance",     name: "Appearance & Theme", glyph: "外", icon: "sparkles", color1: "#a855f7", color2: "#7e22ce" },
                { id: "wallpapers",     name: "Wallpapers & Video", glyph: "壁", icon: "video", color1: "#06b6d4", color2: "#0e7490" },
                { id: "windows",        name: "Windows & Hyprland", glyph: "窓", icon: "app-window", color1: "#0ea5e9", color2: "#0369a1" },
                { id: "animations",     name: "Motion & Physics",   glyph: "動", icon: "waves", color1: "#f59e0b", color2: "#d97706" }
            ]
        },
        {
            title: "DESKTOP & SHELL",
            items: [
                { id: "pill",           name: "Pill Top Bar",       glyph: "丸", icon: "clock", color1: "#10b981", color2: "#059669" },
                { id: "dock",           name: "Smart Dock",         glyph: "桟", icon: "apps", color1: "#8b5cf6", color2: "#6d28d9" },
                { id: "displays",       name: "Displays & Night",   glyph: "画", icon: "monitor", color1: "#eab308", color2: "#ca8a04" },
                { id: "workspaces",     name: "Workspaces",         glyph: "空", icon: "layers", color1: "#38bdf8", color2: "#0284c7" }
            ]
        },
        {
            title: "INPUT & HARDWARE",
            items: [
                { id: "input",          name: "Input & Gestures",   glyph: "入", icon: "mouse", color1: "#f43f5e", color2: "#be123c" },
                { id: "keybinds",       name: "Keybindings & Hotkeys", glyph: "鍵", icon: "keyboard", color1: "#f97316", color2: "#c2410c" },
                { id: "audio",          name: "Sound & Audio",      glyph: "音", icon: "speaker", color1: "#ec4899", color2: "#be185d" },
                { id: "network",        name: "Wi-Fi & Bluetooth",  glyph: "接", icon: "wifi", color1: "#22c55e", color2: "#15803d" },
                { id: "power",          name: "Power & Fans",       glyph: "電", icon: "bolt", color1: "#f59e0b", color2: "#b45309" }
            ]
        },
        {
            title: "EXTRAS & SYSTEM",
            items: [
                { id: "lockscreen",     name: "Lockscreen",         glyph: "鎖", icon: "lock", color1: "#ef4444", color2: "#b91c1c" },
                { id: "ai",             name: "AI Assistant",       glyph: "知", icon: "bot", color1: "#c084fc", color2: "#9333ea" },
                { id: "recording",      name: "Capture & Record",   glyph: "録", icon: "record", color1: "#dc2626", color2: "#991b1b" },
                { id: "applications",   name: "Applications",       glyph: "応", icon: "grid", color1: "#6366f1", color2: "#4338ca" },
                { id: "about",          name: "About & Health",     glyph: "情", icon: "cog", color1: "#64748b", color2: "#334155" }
            ]
        }
    ]

    readonly property var allCategories: {
        var list = [];
        for (var s = 0; s < sections.length; s++) {
            for (var i = 0; i < sections[s].items.length; i++) {
                list.push(sections[s].items[i]);
            }
        }
        return list;
    }

    Column {
        anchors.fill: parent
        anchors.margins: 14
        spacing: 12

        // Top App Header
        Row {
            width: parent.width
            spacing: 12

            Rectangle {
                width: 38
                height: 38
                radius: 11
                gradient: Gradient {
                    GradientStop { position: 0.0; color: Theme.flameCore }
                    GradientStop { position: 1.0; color: Theme.onGlow }
                }
                border.color: Qt.rgba(255, 255, 255, 0.4)
                border.width: 1

                GlyphIcon {
                    anchors.centerIn: parent
                    width: 20
                    height: 20
                    name: "cog"
                    color: Theme.tileBg
                    stroke: 2.2
                }
            }

            Column {
                anchors.verticalCenter: parent.verticalCenter
                spacing: 1

                Text {
                    text: "MasterR Settings"
                    font.family: Theme.fontUI
                    font.pixelSize: 15
                    font.weight: Font.Bold
                    color: Theme.bright
                }

                Text {
                    text: "Hyprland • Liquid Glass"
                    font.family: Theme.fontUI
                    font.pixelSize: 10
                    color: Theme.dim
                }
            }
        }

        // Search in sidebar
        SearchBar {
            width: parent.width
            placeholder: "Search settings..."
            onSearchChanged: (query) => root.filterText = query
        }

        // Sectioned / Filtered Categories List
        Flickable {
            id: sideScroll
            width: parent.width
            height: parent.height - 146
            contentHeight: sideCol.implicitHeight + 16
            clip: true

            Column {
                id: sideCol
                width: parent.width
                spacing: 14

                Repeater {
                    model: root.sections

                    Column {
                        width: sideCol.width
                        spacing: 4

                        readonly property var visibleItems: {
                            if (!root.filterText || root.filterText.trim().length === 0) return modelData.items;
                            var q = root.filterText.toLowerCase().trim();
                            return modelData.items.filter(it => it.name.toLowerCase().includes(q) || it.id.toLowerCase().includes(q));
                        }

                        visible: visibleItems.length > 0

                        // Section Header
                        Text {
                            anchors.left: parent.left
                            anchors.leftMargin: 10
                            text: modelData.title
                            font.family: Theme.fontUI
                            font.pixelSize: 10
                            font.weight: Font.Bold
                            color: Theme.faint
                        }

                        // Section Item Delegates
                        Repeater {
                            model: visibleItems

                            Rectangle {
                                id: itemRect
                                width: sideCol.width
                                height: 38
                                radius: 9
                                readonly property bool active: root.currentCategory === modelData.id
                                color: active ? Qt.rgba(Theme.onGlow.r, Theme.onGlow.g, Theme.onGlow.b, 0.16) : (itemMouse.containsMouse ? Qt.rgba(255, 255, 255, 0.05) : "transparent")
                                border.color: active ? Qt.rgba(Theme.onGlow.r, Theme.onGlow.g, Theme.onGlow.b, 0.35) : "transparent"
                                border.width: 1

                                Behavior on color { ColorAnimation { duration: 120 } }
                                Behavior on border.color { ColorAnimation { duration: 120 } }

                                // Active accent pill on left
                                Rectangle {
                                    visible: itemRect.active
                                    anchors.left: parent.left
                                    anchors.leftMargin: 3
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: 3.5
                                    height: 18
                                    radius: 2
                                    color: Theme.onGlow
                                }

                                Row {
                                    anchors.fill: parent
                                    anchors.leftMargin: 10
                                    anchors.rightMargin: 10
                                    spacing: 10

                                    // Colorful Squircle Icon Badge
                                    Rectangle {
                                        width: 24
                                        height: 24
                                        radius: 7
                                        anchors.verticalCenter: parent.verticalCenter
                                        gradient: Gradient {
                                            GradientStop { position: 0.0; color: modelData.color1 }
                                            GradientStop { position: 1.0; color: modelData.color2 }
                                        }

                                        GlyphIcon {
                                            anchors.centerIn: parent
                                            width: 13
                                            height: 13
                                            name: modelData.icon
                                            color: "#ffffff"
                                            stroke: 2.0
                                        }
                                    }

                                    // Category Name
                                    Text {
                                        width: parent.width - 64
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: modelData.name
                                        font.family: Theme.fontUI
                                        font.pixelSize: 12
                                        font.weight: itemRect.active ? Font.DemiBold : Font.Normal
                                        color: itemRect.active ? Theme.bright : Theme.subtle
                                        elide: Text.ElideRight
                                    }

                                    // Subtle Right Indicator
                                    Text {
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: "›"
                                        font.family: Theme.fontUI
                                        font.pixelSize: 14
                                        font.weight: Font.Bold
                                        color: itemRect.active ? Theme.onGlow : Theme.faint
                                        opacity: itemRect.active ? 1.0 : 0.4
                                    }
                                }

                                MouseArea {
                                    id: itemMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        Nav.currentCategory = modelData.id;
                                        root.currentCategory = modelData.id;
                                        root.categorySelected(modelData.id);
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        // Bottom Footer
        Rectangle {
            width: parent.width
            height: 32
            radius: 8
            color: Qt.rgba(Theme.border.r, Theme.border.g, Theme.border.b, 0.25)
            border.color: Qt.rgba(255, 255, 255, 0.06)
            border.width: 1

            Row {
                anchors.centerIn: parent
                spacing: 8

                Rectangle {
                    width: 7
                    height: 7
                    radius: 3.5
                    anchors.verticalCenter: parent.verticalCenter
                    color: Theme.onGlow

                    SequentialAnimation on opacity {
                        loops: Animation.Infinite
                        NumberAnimation { from: 0.5; to: 1.0; duration: 1200; easing.type: Easing.InOutQuad }
                        NumberAnimation { from: 1.0; to: 0.5; duration: 1200; easing.type: Easing.InOutQuad }
                    }
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "Liquid Engine Active"
                    font.family: Theme.fontUI
                    font.pixelSize: 10
                    font.weight: Font.Medium
                    color: Theme.dim
                }
            }
        }
    }
}

import QtQuick
import "../Singletons"
import "../components"

Flickable {
    id: root

    contentHeight: contentCol.implicitHeight + 40
    clip: true

    Column {
        id: contentCol
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: 24
        spacing: 20

        PageHeader {
            glyph: "桟"
            title: "Floating Smart Dock"
            subtitle: "Dock pinning behaviors, monochrome icon theming, dimensions, and pinned apps."
        }

        // Master Switch & Pin Mode
        Card {
            title: "Dock Visibility & Pinning"
            subtitle: "Choose when the dock reveals itself on the screen"
            icon: "apps"

            Switch {
                label: "Enable Floating Dock"
                description: "Show the bottom application dock and minimized window tray"
                checked: Flags.dockEnable !== false
                icon: "apps"
                onToggled: (st) => Flags.dockEnable = st
            }

            Rectangle { width: parent.width; height: 1; color: Theme.hair }

            SegmentedBar {
                label: "Dock Pinning Behavior"
                model: [
                    { label: "📌 Always Pinned", value: "always" },
                    { label: "🖥️ Smart Pin (Empty Desktop)", value: "desktop" },
                    { label: "👻 Auto-Hide (Hover Edge)", value: "autohide" }
                ]
                currentIndex: Flags.dockPinMode === "always" ? 0 : (Flags.dockPinMode === "autohide" ? 2 : 1)
                onSelected: (idx, val) => Flags.dockPinMode = val
            }

            Rectangle { width: parent.width; height: 1; color: Theme.hair }

            Switch {
                label: "Hover Bottom Edge to Reveal"
                description: "Un-hide the dock when mouse pointer touches the bottom screen margin"
                checked: Flags.dockHoverToReveal !== false
                onToggled: (st) => Flags.dockHoverToReveal = st
            }
        }

        // Visual Theming
        Card {
            title: "Dock Aesthetics & Icons"
            subtitle: "Material You monochrome app icons and sizing"
            icon: "sparkles"

            Switch {
                label: "Monochrome Material You App Icons"
                description: "Force all pinned and running apps to use dynamic single-tint Material You icons"
                checked: Flags.dockMonochromeIcons || false
                icon: "palette"
                onToggled: (st) => Flags.dockMonochromeIcons = st
            }

            Rectangle { width: parent.width; height: 1; color: Theme.hair }

            Slider {
                label: "Dock Bar Height"
                description: "Vertical thickness of the dock pill"
                from: 42
                to: 72
                value: Flags.dockHeight || 52
                stepSize: 2
                unit: "px"
                onMoved: (v) => Flags.dockHeight = Math.round(v)
            }

            Rectangle { width: parent.width; height: 1; color: Theme.hair }

            Slider {
                label: "Bottom Screen Margin"
                description: "Spacing between the dock and bottom screen border"
                from: 0
                to: 24
                value: Flags.dockBottomGap || 8
                stepSize: 1
                unit: "px"
                onMoved: (v) => Flags.dockBottomGap = Math.round(v)
            }
        }

        // Pinned Applications Manager
        Card {
            title: "Pinned Dock Applications"
            subtitle: "Apps currently pinned to your dock. Click to remove or add custom entries."
            icon: "pin"

            Flow {
                width: parent.width
                spacing: 8

                Repeater {
                    model: Flags.dockPinnedApps || ["org.kde.dolphin", "ghostty", "zen"]

                    Rectangle {
                        width: tagText.implicitWidth + 32
                        height: 28
                        radius: 14
                        color: Qt.rgba(Theme.border.r, Theme.border.g, Theme.border.b, 0.3)
                        border.color: Theme.border
                        border.width: 1

                        Row {
                            anchors.centerIn: parent
                            spacing: 6

                            Text {
                                id: tagText
                                text: modelData
                                font.family: Theme.fontUI
                                font.pixelSize: 11
                                font.weight: Font.Medium
                                color: Theme.bright
                            }

                            MouseArea {
                                width: 12
                                height: 12
                                anchors.verticalCenter: parent.verticalCenter
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    var current = (Flags.dockPinnedApps || []).slice();
                                    current.splice(index, 1);
                                    Flags.dockPinnedApps = current;
                                }

                                GlyphIcon {
                                    anchors.fill: parent
                                    name: "close"
                                    color: Theme.dim
                                    stroke: 2.0
                                }
                            }
                        }
                    }
                }
            }

            Rectangle { width: parent.width; height: 1; color: Theme.hair }

            Row {
                width: parent.width
                spacing: 12

                SearchBar {
                    id: pinInput
                    width: 260
                    placeholder: "App desktop ID (e.g. spotify, firefox)..."
                }

                Button {
                    text: "Pin App"
                    icon: "plus"
                    variant: "secondary"
                    onClicked: {
                        var val = pinInput.text.trim();
                        if (val.length > 0) {
                            var current = (Flags.dockPinnedApps || []).slice();
                            if (current.indexOf(val) === -1) {
                                current.push(val);
                                Flags.dockPinnedApps = current;
                                pinInput.text = "";
                            }
                        }
                    }
                }
            }
        }
    }
}

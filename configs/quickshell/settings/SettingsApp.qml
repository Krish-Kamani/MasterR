import QtQuick
import "Singletons"
import "components"
import "pages"

Rectangle {
    id: root

    property string currentCategory: Nav.currentCategory
    signal closeRequested()

    Connections {
        target: Nav
        function onCurrentCategoryChanged() {
            root.currentCategory = Nav.currentCategory;
            pageLoader.opacity = 0;
            pageLoader.y = 8;
            fadeInAnim.restart();
            slideInAnim.restart();
        }
    }

    implicitWidth: 1140
    implicitHeight: 760
    radius: 20
    color: Qt.rgba(Theme.tileBg.r, Theme.tileBg.g, Theme.tileBg.b, 0.82)
    border.color: Qt.rgba(255, 255, 255, 0.16)
    border.width: 1
    clip: true

    // Specular Top Perimeter Bevel Line
    Rectangle {
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: 1
        color: Qt.rgba(255, 255, 255, 0.28)
        z: 10
    }

    // Window Outer Frame
    Row {
        anchors.fill: parent

        // Left Category Sidebar
        Sidebar {
            id: sidebar
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            currentCategory: Nav.currentCategory
            onCategorySelected: (catId) => {
                Nav.currentCategory = catId;
                root.currentCategory = catId;
            }
        }

        // Right Main Content Pane
        Item {
            id: mainPane
            width: parent.width - sidebar.width
            anchors.top: parent.top
            anchors.bottom: parent.bottom

            // Top Window Header & Breadcrumb Bar
            Rectangle {
                id: topBar
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                height: 52
                color: Qt.rgba(Theme.cardBot.r, Theme.cardBot.g, Theme.cardBot.b, 0.45)
                border.color: "transparent"

                // Bottom separator hairline
                Rectangle {
                    anchors.bottom: parent.bottom
                    anchors.left: parent.left
                    anchors.right: parent.right
                    height: 1
                    color: Qt.rgba(255, 255, 255, 0.08)
                }

                // Category Breadcrumb
                Row {
                    id: breadcrumbRow
                    anchors.left: parent.left
                    anchors.leftMargin: 22
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 10

                    readonly property var currentObj: {
                        var cats = sidebar.allCategories || [];
                        for (var i = 0; i < cats.length; i++) {
                            if (cats[i] && cats[i].id === root.currentCategory)
                                return cats[i];
                        }
                        return { name: "System & Overview", icon: "cpu", color1: "#3b82f6", color2: "#1d4ed8" };
                    }

                    Rectangle {
                        width: 26
                        height: 26
                        radius: 7
                        anchors.verticalCenter: parent.verticalCenter
                        gradient: Gradient {
                            GradientStop { position: 0.0; color: (breadcrumbRow.currentObj && breadcrumbRow.currentObj.color1) ? breadcrumbRow.currentObj.color1 : Theme.onGlow }
                            GradientStop { position: 1.0; color: (breadcrumbRow.currentObj && breadcrumbRow.currentObj.color2) ? breadcrumbRow.currentObj.color2 : Theme.vermLit }
                        }

                        GlyphIcon {
                            anchors.centerIn: parent
                            width: 14
                            height: 14
                            name: (breadcrumbRow.currentObj && breadcrumbRow.currentObj.icon) ? breadcrumbRow.currentObj.icon : "cog"
                            color: "#ffffff"
                            stroke: 2.0
                        }
                    }

                    Text {
                        text: "Settings"
                        font.family: Theme.fontUI
                        font.pixelSize: 13
                        font.weight: Font.DemiBold
                        color: Theme.dim
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Text {
                        text: "›"
                        font.family: Theme.fontUI
                        font.pixelSize: 15
                        color: Theme.faint
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Text {
                        text: (breadcrumbRow.currentObj && breadcrumbRow.currentObj.name) ? breadcrumbRow.currentObj.name : "System & Overview"
                        font.family: Theme.fontUI
                        font.pixelSize: 13
                        font.weight: Font.Bold
                        color: Theme.bright
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }

                // Window Control Buttons
                Row {
                    anchors.right: parent.right
                    anchors.rightMargin: 18
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 8

                    // Close Button
                    Rectangle {
                        width: 28
                        height: 28
                        radius: 8
                        color: closeMouse.containsMouse ? "#d83820" : Qt.rgba(255, 255, 255, 0.07)
                        border.color: closeMouse.containsMouse ? "#e84830" : Qt.rgba(255, 255, 255, 0.12)
                        border.width: 1

                        Behavior on color { ColorAnimation { duration: 120 } }

                        GlyphIcon {
                            anchors.centerIn: parent
                            width: 12
                            height: 12
                            name: "close"
                            color: closeMouse.containsMouse ? "#ffffff" : Theme.iconDim
                            stroke: 2.2
                        }

                        MouseArea {
                            id: closeMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.closeRequested()
                        }
                    }
                }
            }

            // Page Content Area with Smooth Transitions
            Item {
                id: pageContainer
                anchors.top: topBar.bottom
                anchors.bottom: parent.bottom
                anchors.left: parent.left
                anchors.right: parent.right

                Loader {
                    id: pageLoader
                    anchors.fill: parent
                    opacity: 1.0

                    NumberAnimation on opacity {
                        id: fadeInAnim
                        from: 0.0
                        to: 1.0
                        duration: 180
                        easing.type: Easing.OutCubic
                    }

                    NumberAnimation on y {
                        id: slideInAnim
                        from: 8
                        to: 0
                        duration: 200
                        easing.type: Easing.OutCubic
                    }

                    sourceComponent: {
                        switch (root.currentCategory) {
                            case "overview":     return overviewComp;
                            case "appearance":   return appearanceComp;
                            case "wallpapers":   return wallpapersComp;
                            case "windows":      return windowsComp;
                            case "animations":   return animationsComp;
                            case "pill":         return pillComp;
                            case "dock":         return dockComp;
                            case "displays":     return displaysComp;
                            case "input":        return inputComp;
                            case "keybinds":     return keybindsComp;
                            case "workspaces":   return workspacesComp;
                            case "audio":        return audioComp;
                            case "network":      return networkComp;
                            case "power":        return powerComp;
                            case "lockscreen":   return lockscreenComp;
                            case "ai":           return aiComp;
                            case "recording":    return recordingComp;
                            case "applications": return applicationsComp;
                            case "about":        return aboutComp;
                            default:             return overviewComp;
                        }
                    }
                }

                Component { id: overviewComp; OverviewPage {} }
                Component { id: appearanceComp; AppearancePage {} }
                Component { id: wallpapersComp; WallpapersPage {} }
                Component { id: windowsComp; WindowsPage {} }
                Component { id: animationsComp; AnimationsPage {} }
                Component { id: pillComp; PillBarPage {} }
                Component { id: dockComp; DockPage {} }
                Component { id: displaysComp; DisplaysPage {} }
                Component { id: inputComp; InputPage {} }
                Component { id: keybindsComp; KeybindsPage {} }
                Component { id: workspacesComp; WorkspacesPage {} }
                Component { id: audioComp; AudioPage {} }
                Component { id: networkComp; NetworkPage {} }
                Component { id: powerComp; PowerHardwarePage {} }
                Component { id: lockscreenComp; LockscreenPage {} }
                Component { id: aiComp; AIAssistantPage {} }
                Component { id: recordingComp; RecordingPage {} }
                Component { id: applicationsComp; ApplicationsPage {} }
                Component { id: aboutComp; AboutPage {} }
            }

            // Feedback Toast
            Toast {
                id: toast
                anchors.bottom: parent.bottom
                anchors.right: parent.right
                anchors.margins: 20
            }
        }
    }
}

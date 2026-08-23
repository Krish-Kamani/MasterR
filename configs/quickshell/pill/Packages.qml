pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import "Singletons"

/**
 * Packages surface: search across Official Arch Repositories (OAR) and Arch User
 * Repository (AUR) with instant source indicator and interactive installer launch.
 */
PillSurface {
    id: root

    mTop: 15
    mLeft: 11
    mRight: 11
    mBottom: 14

    property string query: ""
    property int selectedIndex: 0
    property var results: []

    readonly property string searchScript: Quickshell.env("HOME") + "/.config/hypr/scripts/find-packages.py"
    readonly property string launchScript: Quickshell.env("HOME") + "/.config/hypr/scripts/package-install-launch.sh"

    property point lastPointer: Qt.point(-1, -1)

    readonly property point caretPoint: {
        void root.width;
        void root.height;
        void search.input.width;
        return search.input.mapToItem(root,
            search.input.cursorRectangle.x + search.input.cursorRectangle.width / 2,
            search.input.cursorRectangle.y + search.input.cursorRectangle.height / 2);
    }
    readonly property real caretX: caretPoint.x
    readonly property real caretY: caretPoint.y

    ameForm: "caret"
    amePoint: Qt.point(caretX, caretY)

    function focusField() { search.input.forceActiveFocus(); }

    function move(delta) {
        if (results.length === 0)
            return;
        selectedIndex = Math.max(0, Math.min(results.length - 1, selectedIndex + delta));
        list.positionViewAtIndex(selectedIndex, ListView.Contain);
    }

    function activate() {
        if (results.length === 0 || selectedIndex < 0 || selectedIndex >= results.length)
            return;
        var entry = results[selectedIndex];
        if (entry && entry.name) {
            Quickshell.execDetached(["bash", root.launchScript, entry.name, entry.source || "OAR", entry.version || ""]);
        }
        root.requestClose();
    }

    function runSearch() {
        if (searchProc.running)
            searchProc.running = false;
        searchProc.command = [root.searchScript, root.query];
        searchProc.running = true;
    }

    Timer {
        id: debounceTimer
        interval: 80
        repeat: false
        onTriggered: root.runSearch()
    }

    Process {
        id: searchProc
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    var parsed = JSON.parse(this.text);
                    root.results = parsed || [];
                } catch (e) {
                    root.results = [];
                }
            }
        }
    }

    onActiveChanged: {
        if (active) {
            query = "";
            search.text = "";
            selectedIndex = 0;
            results = [];
            runSearch();
            Qt.callLater(root.focusField);
        }
    }

    onResultsChanged: {
        if (selectedIndex >= results.length)
            selectedIndex = 0;
    }

    SearchField {
        id: search
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        s: root.s
        kanji: "包"
        placeholder: "Search packages (OAR & AUR)..."
        counterText: root.results.length + (root.results.length === 1 ? " package" : " packages")
        onTextChanged: {
            root.query = text;
            root.selectedIndex = 0;
            debounceTimer.restart();
        }
        onMoved: (d) => root.move(d)
        onAccepted: root.activate()
        onDismissed: root.requestClose()
    }

    Rectangle {
        id: divider
        anchors.top: search.bottom
        anchors.topMargin: 8 * root.s
        anchors.left: parent.left
        anchors.right: parent.right
        height: 1
        color: Theme.hair
    }

    Text {
        anchors.centerIn: list
        visible: root.results.length === 0 && !searchProc.running
        text: root.query.length ? "No packages found in OAR or AUR" : "Searching packages..."
        color: Theme.faint
        font.family: Theme.font
        font.pixelSize: 10.5 * root.s
    }

    ListView {
        id: list
        anchors.top: divider.bottom
        anchors.topMargin: 6 * root.s
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        spacing: 5 * root.s
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        model: root.results.length

        delegate: Item {
            id: pkgRow
            required property int index
            width: list.width
            height: 42 * root.s

            readonly property var entry: root.results[index]
            readonly property bool selected: index === root.selectedIndex
            readonly property bool isAur: entry ? entry.source === "AUR" : false
            readonly property bool isInstalled: entry ? !!entry.installed : false

            Rectangle {
                anchors.fill: parent
                radius: 9 * root.s
                visible: pkgRow.selected || rowArea.containsMouse
                color: pkgRow.selected ? Theme.frameBg : Qt.rgba(0.94, 0.88, 0.84, 0.03)
                border.width: pkgRow.selected ? 1 : 0
                border.color: Theme.frameBorder
            }

            MouseArea {
                id: rowArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onPositionChanged: (m) => {
                    var g = rowArea.mapToItem(null, m.x, m.y);
                    if (g.x !== root.lastPointer.x || g.y !== root.lastPointer.y) {
                        root.lastPointer = Qt.point(g.x, g.y);
                        root.selectedIndex = pkgRow.index;
                    }
                }
                onClicked: {
                    root.selectedIndex = pkgRow.index;
                    root.activate();
                }
            }

            Item {
                anchors.fill: parent
                anchors.leftMargin: 11 * root.s
                anchors.rightMargin: 11 * root.s

                Rectangle {
                    id: iconBg
                    anchors.verticalCenter: parent.verticalCenter
                    width: 24 * root.s
                    height: 24 * root.s
                    radius: 6 * root.s
                    color: pkgRow.isAur ? Qt.rgba(0.98, 0.6, 0.39, 0.15) : Qt.rgba(0.46, 0.72, 0.28, 0.15)

                    GlyphIcon {
                        anchors.centerIn: parent
                        width: 14 * root.s
                        height: 14 * root.s
                        name: pkgRow.isInstalled ? "check" : (pkgRow.isAur ? "download" : "apps")
                        color: pkgRow.isInstalled ? "#76b947" : (pkgRow.isAur ? Theme.vermLit : Theme.cream)
                        stroke: 1.8
                    }
                }

                TextMetrics {
                    id: retMetrics
                    font.family: Theme.font
                    font.pixelSize: 12 * root.s
                    text: "↵ install"
                }
                Text {
                    id: ret
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.right: parent.right
                    text: retMetrics.text
                    color: Theme.vermLit
                    font.family: Theme.font
                    font.pixelSize: 11 * root.s
                    visible: pkgRow.selected
                    width: visible ? retMetrics.advanceWidth + 6 * root.s : 0
                    horizontalAlignment: Text.AlignRight
                }

                Column {
                    anchors.left: iconBg.right
                    anchors.leftMargin: 10 * root.s
                    anchors.right: ret.left
                    anchors.rightMargin: 8 * root.s
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 2 * root.s

                    // Row 1: Package Name, Version, Installed badge
                    Row {
                        width: parent.width
                        spacing: 6 * root.s

                        Text {
                            id: nameText
                            text: pkgRow.entry ? pkgRow.entry.name : ""
                            color: Theme.cream
                            font.family: Theme.font
                            font.pixelSize: 13 * root.s
                            font.weight: pkgRow.selected ? Font.DemiBold : Font.Normal
                            elide: Text.ElideRight
                            maximumLineCount: 1
                            width: Math.min(implicitWidth, parent.width - (instBadge.visible ? instBadge.width + 6 * root.s : 0) - (verText.visible ? verText.implicitWidth + 6 * root.s : 0))
                        }

                        Text {
                            id: verText
                            anchors.verticalCenter: parent.verticalCenter
                            visible: pkgRow.entry && pkgRow.entry.version && pkgRow.entry.version.length > 0
                            text: pkgRow.entry ? pkgRow.entry.version : ""
                            color: Theme.faint
                            font.family: Theme.font
                            font.pixelSize: 10 * root.s
                            elide: Text.ElideRight
                        }

                        Rectangle {
                            id: instBadge
                            anchors.verticalCenter: parent.verticalCenter
                            visible: pkgRow.isInstalled
                            width: instText.implicitWidth + 8 * root.s
                            height: 14 * root.s
                            radius: 3 * root.s
                            color: Qt.rgba(0.46, 0.72, 0.28, 0.15)

                            Text {
                                id: instText
                                anchors.centerIn: parent
                                text: "INSTALLED"
                                color: "#76b947"
                                font.family: Theme.font
                                font.pixelSize: 8 * root.s
                                font.weight: Font.DemiBold
                            }
                        }
                    }

                    // Row 2: Source badge (OAR or AUR) directly below package name + description
                    Row {
                        width: parent.width
                        spacing: 6 * root.s

                        Rectangle {
                            id: srcBadge
                            anchors.verticalCenter: parent.verticalCenter
                            width: srcText.implicitWidth + 8 * root.s
                            height: 14 * root.s
                            radius: 3 * root.s
                            color: pkgRow.isAur ? Qt.rgba(0.98, 0.6, 0.39, 0.18) : Qt.rgba(0.46, 0.72, 0.28, 0.18)

                            Text {
                                id: srcText
                                anchors.centerIn: parent
                                text: pkgRow.isAur ? "AUR" : (pkgRow.entry && pkgRow.entry.repo ? "OAR [" + pkgRow.entry.repo + "]" : "OAR")
                                color: pkgRow.isAur ? Theme.vermLit : "#76b947"
                                font.family: Theme.font
                                font.pixelSize: 8 * root.s
                                font.weight: Font.Bold
                            }
                        }

                        Text {
                            id: descText
                            anchors.verticalCenter: parent.verticalCenter
                            width: parent.width - srcBadge.width - 6 * root.s
                            text: pkgRow.entry ? pkgRow.entry.desc : ""
                            color: pkgRow.selected ? Theme.dim : Theme.faint
                            font.family: Theme.font
                            font.pixelSize: 10.5 * root.s
                            elide: Text.ElideRight
                        }
                    }
                }
            }
        }
    }

    WheelScroller {
        anchors.fill: list
        s: root.s
        flick: list
    }
}

import QtQuick
import QtQuick.Window
import QtQuick.Effects
import QtMultimedia

Item {
    id: root
    width: 1920
    height: 1080

    readonly property bool hasScreens: (typeof primaryScreen !== "undefined")
    readonly property bool onPrimary: !hasScreens || (primaryScreen === true)
    readonly property bool hasSddm: typeof sddm !== "undefined"
    readonly property bool hasConfig: typeof config !== "undefined"

    function cfg(key, fallback) {
        if (!hasConfig) return fallback
        var v = config[key]
        return (v === undefined || v === null || ("" + v).length === 0) ? fallback : v
    }

    readonly property real userScale: parseFloat(cfg("scale", "1.0")) || 1.0
    readonly property real s: (root.height > 0 ? root.height / 1080 : 1) * userScale

    // Theme Palette (Matching colors.json)
    readonly property color surfaceDark: "#0d1123"
    readonly property color accent: cfg("accent", "#748cf1")
    readonly property color accentLight: "#cbd1eb"
    readonly property color cream: "#e4e5e7"
    readonly property color brightWhite: "#f7f7f8"
    readonly property color dim: "#838591"
    readonly property color faint: "#6b6d76"
    readonly property color glassBg: Qt.rgba(16 / 255, 21 / 255, 43 / 255, 0.65)
    readonly property color glassBorder: Qt.rgba(255 / 255, 255 / 255, 255 / 255, 0.18)

    property int currentUserIndex: hasSddm ? Math.max(0, userProbe.lastIndex) : 0
    property int currentSessionIndex: hasSddm ? Math.max(0, sessionProbe.lastIndex) : 0

    readonly property string currentUserName: {
        if (!hasSddm) return "krish_kamani"
        var n = userProbe.fieldAt(currentUserIndex, "name")
        return n.length > 0 ? n : "krish_kamani"
    }
    readonly property string currentUserRealName: {
        if (!hasSddm) return "Krish Kamani"
        var rn = userProbe.fieldAt(currentUserIndex, "realName")
        return rn.length > 0 ? rn : currentUserName
    }
    readonly property url currentUserIcon: hasSddm ? userProbe.iconAt(currentUserIndex) : ""

    readonly property string currentSessionName: {
        if (!hasSddm) return "Hyprland (Wayland)"
        var n = sessionProbe.fieldAt(currentSessionIndex, "name")
        return n.length > 0 ? n : "Session"
    }

    function submit() {
        if (passwordInput.text.length === 0) {
            passwordInput.forceActiveFocus()
            return
        }
        showError = false
        if (hasSddm) {
            sddm.login(currentUserName, passwordInput.text, currentSessionIndex)
        }
    }

    function clearPassword() {
        passwordInput.text = ""
        passwordInput.forceActiveFocus()
    }

    property bool showError: false
    property bool reveal: false

    ModelProbe {
        id: userProbe
        sourceModel: hasSddm ? userModel : null
        lastIndex: hasSddm ? userModel.lastIndex : 0
    }

    ModelProbe {
        id: sessionProbe
        sourceModel: hasSddm ? sessionModel : null
        lastIndex: hasSddm ? sessionModel.lastIndex : 0
    }

    component ModelProbe: Item {
        id: probe
        property var sourceModel: null
        property int lastIndex: 0
        readonly property int count: rep.count
        property int version: 0
        property var rows: ({})

        function record(row, field, value) {
            probe.rows[row + ":" + field] = (value === undefined || value === null) ? "" : value
            probe.version++
        }
        function fieldAt(row, field) {
            void probe.version
            var v = probe.rows[row + ":" + field]
            return (v === undefined || v === null) ? "" : "" + v
        }
        function iconAt(row) {
            void probe.version
            var v = probe.rows[row + ":icon"]
            return (v === undefined || v === null) ? "" : v
        }

        Repeater {
            id: rep
            model: probe.sourceModel
            delegate: Item {
                required property int index
                required property var model
                Component.onCompleted: {
                    probe.record(index, "name", model.name)
                    probe.record(index, "realName", model.realName)
                    probe.record(index, "icon", model.icon)
                }
            }
        }
    }

    // -------------------------------------------------------------
    // BACKGROUND & VIGNETTE
    // -------------------------------------------------------------
    Rectangle {
        anchors.fill: parent
        color: root.surfaceDark
        z: -2000
    }

    Image {
        id: bgImage
        anchors.fill: parent
        source: {
            var dynamicBg = cfg("background", "/var/cache/masterr/current_wallpaper.png")
            var fallback = Qt.resolvedUrl(cfg("fallback_background", "assets/background.png"))
            return dynamicBg.length > 0 ? ("file://" + dynamicBg) : fallback
        }
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        cache: false
        z: -1500
        onStatusChanged: {
            if (bgImage.status === Image.Error) {
                bgImage.source = Qt.resolvedUrl(cfg("fallback_background", "assets/background.png"))
            }
        }
    }

    Rectangle {
        anchors.fill: parent
        z: -1000
        gradient: Gradient {
            GradientStop { position: 0.0; color: Qt.rgba(13 / 255, 17 / 255, 35 / 255, 0.40) }
            GradientStop { position: 0.5; color: Qt.rgba(10 / 255, 14 / 255, 28 / 255, 0.65) }
            GradientStop { position: 1.0; color: Qt.rgba(10 / 255, 14 / 255, 28 / 255, 0.85) }
        }
    }

    // -------------------------------------------------------------
    // TOP STATUS BAR
    // -------------------------------------------------------------
    Item {
        id: topBar
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: 48 * root.s
        height: 48 * root.s
        z: 10

        Text {
            id: dateText
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            text: {
                var d = new Date()
                var days = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
                var months = ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"]
                return days[d.getDay()] + " · " + months[d.getMonth()] + " " + d.getDate()
            }
            color: root.cream
            font.family: "Inter"
            font.weight: 700
            font.pixelSize: 13 * root.s
            font.letterSpacing: 3.5 * root.s
            font.capitalization: Font.AllUppercase
            opacity: 0.95
        }

        Rectangle {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            height: 38 * root.s
            width: statusRow.width + 32 * root.s
            radius: 19 * root.s
            color: root.glassBg
            border.width: 1
            border.color: root.glassBorder

            Row {
                id: statusRow
                anchors.centerIn: parent
                spacing: 16 * root.s

                Row {
                    spacing: 6 * root.s
                    anchors.verticalCenter: parent.verticalCenter
                    Text { text: "󰌌"; color: root.accent; font.pixelSize: 14 * root.s; font.family: "JetBrainsMono Nerd Font" }
                    Text { text: typeof keyboard !== "undefined" && keyboard.currentLayout >= 0 && keyboard.layouts && keyboard.layouts.length > keyboard.currentLayout ? keyboard.layouts[keyboard.currentLayout].shortName.toUpperCase() : "US"; color: root.accentLight; font.pixelSize: 12 * root.s; font.family: "JetBrainsMono Nerd Font"; font.weight: 600 }
                }

                Row {
                    spacing: 6 * root.s
                    anchors.verticalCenter: parent.verticalCenter
                    Text { text: "󰤨"; color: root.accent; font.pixelSize: 14 * root.s; font.family: "JetBrainsMono Nerd Font" }
                    Text { text: "100%"; color: root.accentLight; font.pixelSize: 12 * root.s; font.family: "JetBrainsMono Nerd Font"; font.weight: 600 }
                }

                Row {
                    spacing: 6 * root.s
                    anchors.verticalCenter: parent.verticalCenter
                    Text { text: "󰂂"; color: root.accent; font.pixelSize: 14 * root.s; font.family: "JetBrainsMono Nerd Font" }
                    Text { text: "100%"; color: root.accentLight; font.pixelSize: 12 * root.s; font.family: "JetBrainsMono Nerd Font"; font.weight: 600 }
                }
            }
        }
    }

    // -------------------------------------------------------------
    // CENTER CLOCK & AUTH CARD
    // -------------------------------------------------------------
    Column {
        id: centerGroup
        anchors.centerIn: parent
        anchors.verticalCenterOffset: -20 * root.s
        spacing: 28 * root.s
        z: 10

        // Big Clock
        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 12 * root.s

            Text {
                id: clockText
                text: {
                    var d = new Date()
                    var h = d.getHours() % 12
                    if (h === 0) h = 12
                    var m = d.getMinutes()
                    return (h < 10 ? "0" : "") + h + ":" + (m < 10 ? "0" : "") + m
                }
                color: root.brightWhite
                font.family: "Inter"
                font.weight: 300
                font.pixelSize: 130 * root.s
                font.letterSpacing: -2 * root.s
            }

            Text {
                anchors.baseline: clockText.baseline
                text: {
                    var d = new Date()
                    return d.getHours() >= 12 ? "PM" : "AM"
                }
                color: root.accent
                font.family: "Inter"
                font.weight: 700
                font.pixelSize: 28 * root.s
                font.letterSpacing: 2 * root.s
            }
        }

        // Avatar
        Rectangle {
            id: avatarRing
            anchors.horizontalCenter: parent.horizontalCenter
            width: 86 * root.s
            height: 86 * root.s
            radius: 43 * root.s
            color: Qt.rgba(16 / 255, 21 / 255, 43 / 255, 0.85)
            border.width: 2 * root.s
            border.color: root.accent

            Image {
                anchors.fill: parent
                anchors.margins: 4 * root.s
                source: root.currentUserIcon
                fillMode: Image.PreserveAspectCrop
                visible: root.currentUserIcon !== "" && status === Image.Ready
            }

            Text {
                anchors.centerIn: parent
                visible: !avatarRing.children[0].visible
                text: root.currentUserRealName.length > 0 ? root.currentUserRealName.charAt(0).toUpperCase() : "U"
                color: root.brightWhite
                font.family: "Inter"
                font.weight: 700
                font.pixelSize: 34 * root.s
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: userProbe.count > 1 ? Qt.PointingHandCursor : Qt.ArrowCursor
                onClicked: if (userProbe.count > 1) userPopup.opened = !userPopup.opened
            }
        }

        // User Name Meta
        Column {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 4 * root.s

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: root.currentUserRealName
                color: root.brightWhite
                font.family: "Inter"
                font.weight: 600
                font.pixelSize: 19 * root.s
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: root.currentUserName + "@arch"
                color: root.accent
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 13 * root.s
                opacity: 0.9
            }
        }

        // Liquid Glass Capsule Password Input
        Item {
            id: capsuleWrap
            anchors.horizontalCenter: parent.horizontalCenter
            width: 380 * root.s
            height: 52 * root.s

            transform: Translate { id: capsuleShift }

            SequentialAnimation {
                id: shakeAnim
                NumberAnimation { target: capsuleShift; property: "x"; to: 10 * root.s; duration: 45 }
                NumberAnimation { target: capsuleShift; property: "x"; to: -10 * root.s; duration: 45 }
                NumberAnimation { target: capsuleShift; property: "x"; to: 7 * root.s; duration: 45 }
                NumberAnimation { target: capsuleShift; property: "x"; to: -7 * root.s; duration: 45 }
                NumberAnimation { target: capsuleShift; property: "x"; to: 0; duration: 45 }
            }

            Rectangle {
                anchors.fill: parent
                radius: 26 * root.s
                color: Qt.rgba(247 / 255, 247 / 255, 248 / 255, 0.08)
                border.width: 1.2 * root.s
                border.color: root.showError ? "#f87171" : Qt.rgba(228 / 255, 229 / 255, 231 / 255, 0.3)

                TextInput {
                    id: passwordInput
                    anchors.fill: parent
                    anchors.leftMargin: 24 * root.s
                    anchors.rightMargin: 56 * root.s
                    verticalAlignment: TextInput.AlignVCenter
                    horizontalAlignment: TextInput.AlignHCenter
                    echoMode: root.reveal ? TextInput.Normal : TextInput.NoEcho
                    color: root.reveal ? root.brightWhite : "transparent"
                    font.family: "Inter"
                    font.pixelSize: 15 * root.s
                    clip: true
                    focus: true
                    onAccepted: root.submit()
                    onTextChanged: {
                        root.showError = false
                        while (beadModel.count < text.length) beadModel.append({})
                        while (beadModel.count > text.length) beadModel.remove(beadModel.count - 1)
                    }
                }

                // Placeholder text
                Text {
                    anchors.centerIn: parent
                    visible: passwordInput.text.length === 0
                    text: root.showError ? "Incorrect Password" : "Password"
                    color: root.showError ? "#f87171" : root.dim
                    font.family: "Inter"
                    font.pixelSize: 14 * root.s
                    font.letterSpacing: 1 * root.s
                }

                // Ember Beads (Quickshell Matching)
                ListModel { id: beadModel }

                Row {
                    anchors.centerIn: parent
                    spacing: 9 * root.s
                    visible: !root.reveal && passwordInput.text.length > 0

                    Repeater {
                        model: beadModel
                        delegate: Rectangle {
                            id: bead
                            required property int index
                            width: 7.5 * root.s
                            height: 7.5 * root.s
                            radius: width / 2
                            color: bead.index === passwordInput.text.length - 1 ? root.cream : root.accent
                        }
                    }
                }

                // Submit Button
                Rectangle {
                    id: submitBtn
                    anchors.right: parent.right
                    anchors.rightMargin: 7 * root.s
                    anchors.verticalCenter: parent.verticalCenter
                    width: 38 * root.s
                    height: 38 * root.s
                    radius: 19 * root.s
                    color: root.accent

                    Text {
                        anchors.centerIn: parent
                        text: "➔"
                        color: "#ffffff"
                        font.pixelSize: 15 * root.s
                        font.weight: 700
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.submit()
                    }
                }
            }
        }
    }

    // -------------------------------------------------------------
    // BOTTOM CONTROLS
    // -------------------------------------------------------------
    Item {
        id: bottomBar
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: 48 * root.s
        height: 52 * root.s
        z: 10

        // Session Selector Pill
        Rectangle {
            id: sessionPill
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            height: 44 * root.s
            width: sessionRow.width + 36 * root.s
            radius: 22 * root.s
            color: root.glassBg
            border.width: 1
            border.color: root.glassBorder

            Row {
                id: sessionRow
                anchors.centerIn: parent
                spacing: 10 * root.s

                Text {
                    text: "󰣇"
                    color: root.accent
                    font.pixelSize: 16 * root.s
                    font.family: "JetBrainsMono Nerd Font"
                    anchors.verticalCenter: parent.verticalCenter
                }

                Text {
                    text: root.currentSessionName
                    color: root.brightWhite
                    font.family: "Inter"
                    font.weight: 500
                    font.pixelSize: 13.5 * root.s
                    anchors.verticalCenter: parent.verticalCenter
                }

                Text {
                    text: "▼"
                    color: root.dim
                    font.pixelSize: 9 * root.s
                    anchors.verticalCenter: parent.verticalCenter
                }
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: sessionProbe.count > 1 ? Qt.PointingHandCursor : Qt.ArrowCursor
                onClicked: if (sessionProbe.count > 1) sessionPopup.opened = !sessionPopup.opened
            }
        }

        // Power Controls
        Row {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            spacing: 12 * root.s

            // Suspend
            Rectangle {
                width: 44 * root.s
                height: 44 * root.s
                radius: 22 * root.s
                color: root.glassBg
                border.width: 1
                border.color: root.glassBorder
                visible: root.hasSddm ? sddm.canSuspend : true

                Text {
                    anchors.centerIn: parent
                    text: "󰤄"
                    color: root.dim
                    font.pixelSize: 16 * root.s
                    font.family: "JetBrainsMono Nerd Font"
                }

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onEntered: parent.color = Qt.rgba(116 / 255, 140 / 255, 241 / 255, 0.25)
                    onExited: parent.color = root.glassBg
                    onClicked: if (root.hasSddm) sddm.suspend()
                }
            }

            // Reboot
            Rectangle {
                width: 44 * root.s
                height: 44 * root.s
                radius: 22 * root.s
                color: root.glassBg
                border.width: 1
                border.color: root.glassBorder
                visible: root.hasSddm ? sddm.canReboot : true

                Text {
                    anchors.centerIn: parent
                    text: "󰜉"
                    color: root.dim
                    font.pixelSize: 16 * root.s
                    font.family: "JetBrainsMono Nerd Font"
                }

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onEntered: parent.color = Qt.rgba(116 / 255, 140 / 255, 241 / 255, 0.25)
                    onExited: parent.color = root.glassBg
                    onClicked: if (root.hasSddm) sddm.reboot()
                }
            }

            // Power Off
            Rectangle {
                width: 44 * root.s
                height: 44 * root.s
                radius: 22 * root.s
                color: root.glassBg
                border.width: 1
                border.color: root.glassBorder
                visible: root.hasSddm ? sddm.canPowerOff : true

                Text {
                    anchors.centerIn: parent
                    text: "󰐥"
                    color: root.dim
                    font.pixelSize: 16 * root.s
                    font.family: "JetBrainsMono Nerd Font"
                }

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onEntered: parent.color = Qt.rgba(248 / 255, 113 / 255, 113 / 255, 0.3)
                    onExited: parent.color = root.glassBg
                    onClicked: if (root.hasSddm) sddm.powerOff()
                }
            }
        }
    }

    // -------------------------------------------------------------
    // DROPDOWN POPUPS
    // -------------------------------------------------------------
    component SelectPanel: Rectangle {
        id: panel
        property bool opened: false
        property int activeIndex: 0
        property var entries: []
        signal picked(int index)

        visible: opened
        z: 50
        width: 240 * root.s
        height: Math.min(300 * root.s, entries.length * 40 * root.s + 16 * root.s)
        radius: 16 * root.s
        color: Qt.rgba(16 / 255, 21 / 255, 43 / 255, 0.92)
        border.width: 1
        border.color: root.glassBorder

        ListView {
            anchors.fill: parent
            anchors.margins: 8 * root.s
            model: panel.entries
            clip: true
            delegate: Rectangle {
                required property int index
                required property var modelData
                width: parent.width
                height: 36 * root.s
                radius: 8 * root.s
                color: rowArea.containsMouse ? Qt.rgba(116 / 255, 140 / 255, 241 / 255, 0.2) : "transparent"

                Text {
                    anchors.left: parent.left
                    anchors.leftMargin: 12 * root.s
                    anchors.verticalCenter: parent.verticalCenter
                    text: modelData
                    color: index === panel.activeIndex ? root.brightWhite : root.cream
                    font.family: "Inter"
                    font.weight: index === panel.activeIndex ? 600 : 400
                    font.pixelSize: 13 * root.s
                }

                MouseArea {
                    id: rowArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        panel.picked(index)
                        panel.opened = false
                    }
                }
            }
        }
    }

    SelectPanel {
        id: sessionPopup
        anchors.left: bottomBar.left
        anchors.bottom: bottomBar.top
        anchors.bottomMargin: 8 * root.s
        activeIndex: root.currentSessionIndex
        entries: {
            var list = []
            if (!root.hasSddm) return ["Hyprland (Wayland)"]
            for (var i = 0; i < sessionProbe.count; i++) {
                var nm = sessionProbe.fieldAt(i, "name")
                list.push(nm.length > 0 ? nm : "Session " + i)
            }
            return list
        }
        onPicked: function(idx) { root.currentSessionIndex = idx }
    }

    SelectPanel {
        id: userPopup
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: centerGroup.top
        activeIndex: root.currentUserIndex
        entries: {
            var list = []
            if (!root.hasSddm) return ["krish_kamani"]
            for (var i = 0; i < userProbe.count; i++) {
                var nm = userProbe.fieldAt(i, "realName")
                if (nm.length === 0) nm = userProbe.fieldAt(i, "name")
                list.push(nm.length > 0 ? nm : "user" + i)
            }
            return list
        }
        onPicked: function(idx) {
            root.currentUserIndex = idx
            root.clearPassword()
        }
    }

    // Close popups on click outside
    MouseArea {
        anchors.fill: parent
        z: 40
        visible: userPopup.opened || sessionPopup.opened
        onClicked: {
            userPopup.opened = false
            sessionPopup.opened = false
        }
    }

    // Focus grabber & Connections
    Connections {
        target: root.hasSddm ? sddm : null
        ignoreUnknownSignals: true
        function onLoginFailed() {
            root.showError = true
            shakeAnim.restart()
            root.clearPassword()
        }
        function onLoginSucceeded() {
            root.showError = false
        }
    }

    Timer {
        id: focusGrab
        property int ticks: 0
        interval: 350
        running: root.onPrimary
        repeat: true
        onTriggered: {
            var w = root.Window.window
            if (w) w.requestActivate()
            passwordInput.forceActiveFocus()
            ticks++
            if (ticks >= 5) focusGrab.stop()
        }
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: {
            var d = new Date()
            var h = d.getHours() % 12
            if (h === 0) h = 12
            var m = d.getMinutes()
            clockText.text = (h < 10 ? "0" : "") + h + ":" + (m < 10 ? "0" : "") + m
        }
    }
}

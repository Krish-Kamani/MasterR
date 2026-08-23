pragma ComponentBehavior: Bound

import QtQuick
import "Singletons"

/**
 * 蓄 BATTERY surface: a typographic read-out for the laptop battery. The
 * percentage is the hero, set over a time-to-empty/full subline, with a thin
 * charge meter and an adaptive stat list (Rate / Health / Capacity) beneath a
 * hairline. Health drops when UPower can't report it and the time line drops
 * when no estimate exists; on AC-full the subline reads "Plugged in". Charging
 * warms the percentage, subline and meter to the flame tones. Exposes
 * `implicitHeight` from its content and docks Ame as a seam at the charge head.
 */
PillSurface {
    id: root

    mTop: 16
    mLeft: 19
    mRight: 19
    mBottom: 16

    implicitHeight: content.implicitHeight

    /**
     * Where the seam docks: the head of the charge meter, mirroring the
     * seek-stroke head on the media card. Sits clear of the hero number and
     * tracks the charge level. mapToItem isn't reactive, so the void reads
     * force re-eval across the morph and on charge changes.
     */
    readonly property point chargeHead: {
        void root.width;
        void root.height;
        void Battery.frac;
        void meter.width;
        return meter.mapToItem(root, meter.width * Battery.frac, meter.height / 2);
    }

    ameForm: "seam"
    amePoint: chargeHead

    onOpenChanged: if (open) Battery.refreshPowerProfile()

    Column {
        id: content
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        spacing: 0

        Item {
            width: parent.width
            height: 22 * root.s

            Row {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                spacing: 8 * root.s

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    visible: Flags.showGlyphs
                    text: "蓄"
                    color: Theme.cream
                    font.family: Theme.fontJp
                    font.weight: Font.Medium
                    font.pixelSize: 16 * root.s
                }
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "BATTERY"
                    color: Theme.subtle
                    font.family: Theme.font
                    font.pixelSize: 10 * root.s
                    font.weight: Font.DemiBold
                    font.capitalization: Font.AllUppercase
                    font.letterSpacing: 1.6 * root.s
                }
            }

            Text {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                text: Battery.stateLabel
                color: Battery.charging ? Theme.flameGlow : Theme.dim
                font.family: Theme.font
                font.pixelSize: 9.5 * root.s
                font.weight: Font.Bold
                font.capitalization: Font.AllUppercase
                font.letterSpacing: 1.1 * root.s
            }
        }

        Row {
            id: heroRow
            width: parent.width
            topPadding: 14 * root.s
            bottomPadding: 16 * root.s
            spacing: 14 * root.s

            Column {
                id: pctCol
                width: 104 * root.s
                anchors.verticalCenter: parent.verticalCenter
                spacing: 6 * root.s

                Text {
                    id: pctText
                    text: Battery.pct + "%"
                    color: Battery.low ? Theme.vermLit : (Battery.charging ? Theme.flameGlow : Theme.cream)
                    font.family: Theme.font
                    font.pixelSize: 42 * root.s
                    font.weight: Font.Bold
                    font.letterSpacing: -1 * root.s
                    font.features: { "tnum": 1 }
                }

                Text {
                    readonly property string body: Battery.full
                        ? "Plugged in"
                        : (Battery.hasTime
                            ? Battery.timeStr + (Battery.charging ? " to full" : " remaining")
                            : (Battery.discharging ? "Discharging" : "On AC"))
                    visible: body.length > 0
                    text: body
                    color: Battery.charging ? Theme.flameCore : Theme.subtle
                    font.family: Theme.font
                    font.pixelSize: 10.5 * root.s
                    font.weight: Font.DemiBold
                    wrapMode: Text.WordWrap
                    width: parent.width
                }
            }

            Rectangle {
                width: 1
                height: Math.max(pctCol.implicitHeight, controlsCol.implicitHeight) - 6 * root.s
                anchors.verticalCenter: parent.verticalCenter
                color: Theme.hairSoft
            }

            Column {
                id: controlsCol
                width: parent.width - pctCol.width - 1 - heroRow.spacing * 2
                anchors.verticalCenter: parent.verticalCenter
                spacing: 8 * root.s

                Column {
                    width: parent.width
                    spacing: 4 * root.s

                    Item {
                        width: parent.width
                        height: 14 * root.s

                        Text {
                            anchors.left: parent.left
                            anchors.verticalCenter: parent.verticalCenter
                            text: "PROFILE"
                            color: Theme.faint
                            font.family: Theme.font
                            font.pixelSize: 8.5 * root.s
                            font.weight: Font.Bold
                            font.capitalization: Font.AllUppercase
                            font.letterSpacing: 1.0 * root.s
                        }

                        Text {
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            text: Battery.powerProfileLabel
                            color: Theme.flameGlow
                            font.family: Theme.font
                            font.pixelSize: 9 * root.s
                            font.weight: Font.SemiBold
                        }
                    }

                    Row {
                        id: powerSeg
                        width: parent.width
                        spacing: 3 * root.s

                        readonly property var options: [
                            { label: "Saving", value: "power-saving" },
                            { label: "Balanced", value: "balanced" },
                            { label: "Ultimate", value: "ultimate" }
                        ]

                        Repeater {
                            model: powerSeg.options

                            Rectangle {
                                id: pOpt
                                required property var modelData
                                required property int index
                                readonly property bool current: Battery.powerProfile === modelData.value
                                property bool hovered: false

                                width: (powerSeg.width - 2 * powerSeg.spacing) / 3
                                height: 21 * root.s
                                radius: 5.5 * root.s
                                scale: pOpt.current ? 1.0 : (pOpt.hovered ? 1.04 : 0.98)
                                color: pOpt.current
                                    ? Qt.alpha(Theme.onGlow, 0.18)
                                    : (pOpt.hovered ? Theme.frameBg : Qt.alpha(Theme.cream, 0.035))
                                border.width: 1
                                border.color: pOpt.current
                                    ? Qt.alpha(Theme.onGlow, 0.45)
                                    : (pOpt.hovered ? Theme.frameBorder : Theme.hairSoft)
                                Behavior on color { ColorAnimation { duration: Motion.fast } }
                                Behavior on border.color { ColorAnimation { duration: Motion.fast } }
                                Behavior on scale { NumberAnimation { duration: Motion.fast; easing.type: Easing.OutBack } }

                                Text {
                                    anchors.centerIn: parent
                                    text: pOpt.modelData.label
                                    color: pOpt.current ? Theme.cream : (pOpt.hovered ? Theme.bright : Theme.subtle)
                                    font.family: Theme.font
                                    font.pixelSize: 9 * root.s
                                    font.weight: pOpt.current ? Font.Bold : Font.Medium
                                    font.letterSpacing: 0.2 * root.s

                                    Behavior on color { ColorAnimation { duration: Motion.fast } }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onEntered: pOpt.hovered = true
                                    onExited: pOpt.hovered = false
                                    onClicked: Battery.setPowerProfile(pOpt.modelData.value)
                                }
                            }
                        }
                    }
                }

                Column {
                    width: parent.width
                    spacing: 4 * root.s

                    Item {
                        width: parent.width
                        height: 14 * root.s

                        Text {
                            anchors.left: parent.left
                            anchors.verticalCenter: parent.verticalCenter
                            text: "FAN SPEED"
                            color: Theme.faint
                            font.family: Theme.font
                            font.pixelSize: 8.5 * root.s
                            font.weight: Font.Bold
                            font.capitalization: Font.AllUppercase
                            font.letterSpacing: 1.0 * root.s
                        }

                        Text {
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            text: Battery.fanSpeedLabel
                            color: Theme.flameGlow
                            font.family: Theme.font
                            font.pixelSize: 9 * root.s
                            font.weight: Font.SemiBold
                        }
                    }

                    Row {
                        id: fanSeg
                        width: parent.width
                        spacing: 3 * root.s

                        readonly property var options: [
                            { label: "Auto", value: "auto", isInfinity: false },
                            { label: "Quiet", value: "quiet", isInfinity: false },
                            { label: "Balanced", value: "balanced", isInfinity: false },
                            { label: "", value: "performance", isInfinity: true }
                        ]

                        Repeater {
                            model: fanSeg.options

                            Rectangle {
                                id: fOpt
                                required property var modelData
                                required property int index
                                readonly property bool current: Battery.fanSpeed === modelData.value
                                property bool hovered: false

                                width: (fanSeg.width - 3 * fanSeg.spacing) / 4
                                height: 21 * root.s
                                radius: 5.5 * root.s
                                color: fOpt.current
                                    ? Qt.alpha(Theme.onGlow, 0.18)
                                    : (fOpt.hovered ? Theme.frameBg : Qt.alpha(Theme.cream, 0.035))
                                border.width: 1
                                border.color: fOpt.current
                                    ? Qt.alpha(Theme.onGlow, 0.45)
                                    : (fOpt.hovered ? Theme.frameBorder : Theme.hairSoft)
                                Behavior on color { ColorAnimation { duration: Motion.fast } }
                                Behavior on border.color { ColorAnimation { duration: Motion.fast } }

                                Text {
                                    anchors.centerIn: parent
                                    visible: !fOpt.modelData.isInfinity
                                    text: fOpt.modelData.label
                                    color: fOpt.current ? Theme.cream : (fOpt.hovered ? Theme.bright : Theme.subtle)
                                    font.family: Theme.font
                                    font.pixelSize: 8.5 * root.s
                                    font.weight: fOpt.current ? Font.Bold : Font.Medium
                                    font.letterSpacing: 0.2 * root.s
                                }

                                GlyphIcon {
                                    anchors.centerIn: parent
                                    visible: fOpt.modelData.isInfinity
                                    name: "infinity"
                                    width: 14 * root.s
                                    height: 14 * root.s
                                    color: fOpt.current ? Theme.cream : (fOpt.hovered ? Theme.bright : Theme.subtle)
                                    stroke: 2.0
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onEntered: fOpt.hovered = true
                                    onExited: fOpt.hovered = false
                                    onClicked: Battery.setFanSpeed(fOpt.modelData.value)
                                }
                            }
                        }
                    }
                }
            }
        }

        Rectangle {
            id: meter
            width: parent.width
            height: 3 * root.s
            radius: 1.5 * root.s
            color: Theme.threadBg

            Rectangle {
                anchors.left: parent.left
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                width: parent.width * Battery.frac
                radius: parent.radius
                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop { position: 0.0; color: Battery.charging ? Theme.vermLit : Theme.vermDeep }
                    GradientStop { position: 1.0; color: Battery.charging ? Theme.flameGlow : Theme.vermLit }
                }
            }
        }

        Column {
            width: parent.width
            topPadding: 16 * root.s
            spacing: 10 * root.s

            component StatRow: Item {
                id: stat
                width: parent ? parent.width : 0
                height: vText.implicitHeight
                property string label: ""
                property string value: ""
                property bool warm: false

                Text {
                    anchors.left: parent.left
                    anchors.baseline: vText.baseline
                    text: stat.label
                    color: Theme.faint
                    font.family: Theme.font
                    font.pixelSize: 10 * root.s
                    font.weight: Font.Medium
                    font.capitalization: Font.AllUppercase
                    font.letterSpacing: 0.8 * root.s
                }

                Text {
                    id: vText
                    anchors.right: parent.right
                    text: stat.value
                    color: stat.warm ? Theme.flameGlow : Theme.cream
                    font.family: Theme.font
                    font.pixelSize: 12.5 * root.s
                    font.weight: Font.DemiBold
                    font.features: { "tnum": 1 }
                }
            }

            StatRow {
                visible: Math.abs(Battery.rateW) >= 0.05
                label: "Rate"
                value: (Battery.rateW > 0 ? "+" : "−") + Math.abs(Battery.rateW).toFixed(1) + " W"
                warm: Battery.charging
            }

            StatRow {
                visible: Battery.healthSupported
                label: "Health"
                value: Battery.health + "%"
                warm: true
            }

            StatRow {
                visible: Battery.capacityWh >= 1
                label: "Capacity"
                value: Battery.capacityWh.toFixed(1) + " Wh"
            }
        }
    }
}

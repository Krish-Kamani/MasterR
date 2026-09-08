pragma Singleton
import QtQuick
import Quickshell

Singleton {
    readonly property real mult: Flags.reduceMotion ? 0.4 : 1
    readonly property int microFast: Math.round(80 * mult)
    readonly property int fast:      Math.round(130 * mult)
    readonly property int hover:     Math.round(140 * mult)
    readonly property int standard:  Math.round(220 * mult)
    readonly property int morph:     Math.round(260 * mult)
    readonly property int shapeshift: Math.round(440 * mult)
    readonly property int glide:     Math.round(180 * mult)
    readonly property int heat:      Math.round(750 * mult)
    readonly property int easeStandard: Easing.OutCubic
    readonly property int easeSmooth:   Easing.OutCubic
    readonly property int easeMorph:    Easing.BezierSpline

    /**
     * Ultra-smooth fluid morph curve with instantaneous response & silky settle:
     * cubic-bezier(0.16, 1.00, 0.30, 1.00).
     */
    readonly property var morphCurve: [0.16, 1.00, 0.30, 1.00, 1, 1]

    /**
     * Lively, refined feedback curve for buttons & chips: cubic-bezier(0.05, 0.95, 0.15, 1.02)
     */
    readonly property var snappyCurve: [0.05, 0.95, 0.15, 1.02, 1, 1]

    /**
     * Instantaneous responsive fade curve: cubic-bezier(0.25, 1.00, 0.50, 1.00)
     */
    readonly property var fadeCurve: [0.25, 1.00, 0.50, 1.00, 1, 1]

    readonly property real rSmall: 7
    readonly property real rTile:  13

    /** Looping scan/pairing breath pulse. */
    readonly property int pulse: Math.round(360 * mult)
}

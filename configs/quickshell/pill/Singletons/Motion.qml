pragma Singleton
import QtQuick
import Quickshell

Singleton {
    readonly property real mult: Flags.reduceMotion ? 0.4 : 1
    readonly property int microFast: Math.round(95 * mult)
    readonly property int fast:      Math.round(150 * mult)
    readonly property int hover:     Math.round(160 * mult)
    readonly property int standard:  Math.round(300 * mult)
    readonly property int morph:     Math.round(420 * mult)
    readonly property int shapeshift: Math.round(800 * mult)
    readonly property int glide:     Math.round(260 * mult)
    readonly property int heat:      Math.round(1050 * mult)
    readonly property int easeStandard: Easing.OutBack
    readonly property int easeSmooth:   Easing.OutCubic
    readonly property int easeMorph:    Easing.BezierSpline

    /**
     * Spunky liquid morph curve with energetic spring & silky settle:
     * cubic-bezier(0.05, 0.90, 0.10, 1.08).
     */
    readonly property var morphCurve: [0.05, 0.90, 0.10, 1.08, 1, 1]

    /**
     * Spunky spring feedback curve for buttons & chips: cubic-bezier(0.175, 0.885, 0.32, 1.275)
     */
    readonly property var snappyCurve: [0.175, 0.885, 0.32, 1.275, 1, 1]

    /**
     * Silk smooth fade curve: cubic-bezier(0.40, 0.00, 0.20, 1.00)
     */
    readonly property var fadeCurve: [0.40, 0.00, 0.20, 1.00, 1, 1]

    readonly property real rSmall: 7
    readonly property real rTile:  13

    /** Looping scan/pairing breath pulse. */
    readonly property int pulse: Math.round(420 * mult)
}

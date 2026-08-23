pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.UPower

/**
 * Laptop-battery state for the pill, sourced from UPower's display device and
 * gated so a desktop without a battery reports `present` false (the hover
 * cluster and 蓄 surface stay hidden). Exposes percentage, charge state, a
 * signed draw/charge wattage, capacity and optional health, plus a formatted
 * time-to-empty/full string. `low` flags a discharging battery at or below 20%.
 * Also manages system Power Profile and Fan Speed controls.
 */
Singleton {
    id: root

    readonly property var dev: UPower.displayDevice

    readonly property bool present: dev !== null && dev.ready && dev.isLaptopBattery && dev.isPresent
    readonly property real frac: dev ? Math.max(0, Math.min(1, dev.percentage)) : 0
    readonly property int pct: Math.round(frac * 100)
    readonly property int state: dev ? dev.state : UPowerDeviceState.Unknown

    readonly property bool charging: state === UPowerDeviceState.Charging
    readonly property bool full: state === UPowerDeviceState.FullyCharged || pct >= 100
    readonly property bool discharging: state === UPowerDeviceState.Discharging
    readonly property bool low: !charging && pct <= 20

    readonly property real rateW: !dev ? 0
        : (discharging ? -dev.changeRate : (charging ? dev.changeRate : 0))
    readonly property real capacityWh: dev ? dev.energyCapacity : 0

    readonly property bool healthSupported: dev ? dev.healthSupported : false
    readonly property int health: dev ? Math.round(dev.healthPercentage) : 0

    readonly property bool hasTime: !dev ? false
        : (charging ? dev.timeToFull > 0 : (discharging ? dev.timeToEmpty > 0 : false))
    readonly property string timeStr: !dev ? ""
        : (charging ? fmt(dev.timeToFull) : (discharging ? fmt(dev.timeToEmpty) : ""))

    readonly property string stateLabel: charging ? "Charging"
        : (full ? "On AC · Full"
        : (discharging ? "Discharging" : "On AC"))

    property string powerProfile: Flags.powerProfile || "balanced"
    property string fanSpeed: Flags.fanSpeed || "auto"

    readonly property string powerProfileLabel: {
        if (powerProfile === "power-saving") return "Power-saving";
        if (powerProfile === "ultimate") return "Ultimate";
        return "Balanced";
    }

    readonly property string fanSpeedLabel: {
        if (fanSpeed === "quiet") return "Quiet";
        if (fanSpeed === "balanced") return "Balanced";
        if (fanSpeed === "performance") return "Performance";
        return "Auto";
    }

    property bool internalChange: false

    Timer {
        id: resetInternalTimer
        interval: 1500
        repeat: false
        onTriggered: root.internalChange = false
    }

    function setPowerProfile(profile) {
        internalChange = true;
        resetInternalTimer.restart();
        powerProfile = profile;
        Flags.powerProfile = profile;
        var p = "balanced";
        if (profile === "power-saving")
            p = "power-saver";
        else if (profile === "ultimate")
            p = "performance";
        powerProc.command = ["powerprofilesctl", "set", p];
        powerProc.running = true;
    }

    function setFanSpeed(speed) {
        fanSpeed = speed;
        Flags.fanSpeed = speed;
        fanProc.command = ["bash", Quickshell.env("HOME") + "/.config/hypr/scripts/fan-speed.sh", speed];
        fanProc.running = true;
    }

    function refreshPowerProfile() {
        if (!watchPowerProc.running)
            watchPowerProc.running = true;
    }

    Process {
        id: powerProc
    }

    Process {
        id: fanProc
    }

    Process {
        id: watchPowerProc
        command: ["sh", "-c", "last=\"\"; while true; do p=$(cat /sys/firmware/acpi/platform_profile 2>/dev/null); [ -n \"$p\" ] || p=$(powerprofilesctl get 2>/dev/null); if [ -n \"$p\" ] && [ \"$p\" != \"$last\" ]; then echo \"$p\"; last=\"$p\"; fi; sleep 0.5; done"]
        running: true
        stdout: SplitParser {
            onRead: function(data) {
                var s = data.trim();
                var newProfile = "balanced";
                if (s === "power-saver" || s === "low-power")
                    newProfile = "power-saving";
                else if (s === "performance" || s === "max-power")
                    newProfile = "ultimate";
                else if (s === "balanced")
                    newProfile = "balanced";

                if (root.powerProfile !== newProfile) {
                    var wasInternal = root.internalChange;
                    root.powerProfile = newProfile;
                    Flags.powerProfile = newProfile;

                    // When power profile changes externally (such as via Lenovo LOQ Fn + Q shortcut), automatically switch fan mode to auto
                    if (!wasInternal) {
                        root.setFanSpeed("auto");
                    }
                }
            }
        }
    }

    Component.onCompleted: {
        refreshPowerProfile();
    }

    function fmt(sec) {
        var s = Math.max(0, Math.round(sec));
        var h = Math.floor(s / 3600);
        var m = Math.floor((s % 3600) / 60);
        if (h > 0)
            return h + "h " + m + "m";
        return m + "m";
    }
}



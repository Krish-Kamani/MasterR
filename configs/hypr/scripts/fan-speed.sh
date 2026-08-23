#!/usr/bin/env bash
# fan-speed.sh: Set and manage system fan speed mode (auto, quiet, balanced, performance)
set -euo pipefail

MODE="${1:-auto}"
STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/masterr"
mkdir -p "$STATE_DIR"
echo "$MODE" > "$STATE_DIR/fan-speed"

# Locate Lenovo IdeaPad / LOQ fan_mode sysfs path
FAN_NODE=""
for path in \
    "/sys/bus/platform/drivers/ideapad_acpi/VPC2004:00/fan_mode" \
    "/sys/devices/pci0000:00/0000:00:1f.0/PNP0C09:00/VPC2004:00/fan_mode" \
    "/sys/devices/platform/ideapad_acpi/VPC2004:00/fan_mode"; do
    if [ -f "$path" ]; then
        FAN_NODE="$path"
        break
    fi
done

# Map fan modes for Lenovo IdeaPad/LOQ EC:
# 0 = Super Silent / Quiet
# 1 = Standard / Auto / Balanced
# 4 = Efficient Thermal Dissipation / Performance (Max fan speed)
case "$MODE" in
    "quiet"|"quite")
        VAL="0"
        ;;
    "balanced")
        VAL="1"
        ;;
    "performance")
        VAL="4"
        ;;
    "auto"|*)
        VAL="1"
        ;;
esac

if [ -n "$FAN_NODE" ]; then
    if [ -w "$FAN_NODE" ]; then
        echo "$VAL" > "$FAN_NODE" 2>/dev/null || true
    fi
fi

# If vendor tools are installed (legion-cli, nbfc, isw, etc.), dispatch to them
if command -v legion-cli >/dev/null 2>&1; then
    case "$MODE" in
        "quiet"|"quite") legion-cli fan quiet 2>/dev/null || true ;;
        "balanced")      legion-cli fan balance 2>/dev/null || true ;;
        "performance")   legion-cli fan performance 2>/dev/null || true ;;
        "auto"|*)        legion-cli fan auto 2>/dev/null || true ;;
    esac
elif command -v isw >/dev/null 2>&1; then
    case "$MODE" in
        "quiet"|"quite") isw -s 0 2>/dev/null || true ;;
        "balanced")      isw -s 1 2>/dev/null || true ;;
        "performance")   isw -s 2 2>/dev/null || true ;;
        "auto"|*)        isw -s 1 2>/dev/null || true ;;
    esac
fi

exit 0

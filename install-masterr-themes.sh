#!/usr/bin/env bash
# MasterR Liquid Glass Themes Installer (GRUB & SDDM)
# Designed for Arch Linux + Hyprland MasterR Rice

set -euo pipefail

# Check root privileges
if [ "$(id -u)" -ne 0 ]; then
    echo "[-] This installation script requires root privileges to configure GRUB and SDDM."
    echo "[*] Elevating with sudo..."
    exec sudo bash "$0" "$@"
fi

TARGET_USER="${SUDO_USER:-$USER}"
USER_HOME=$(getent passwd "$TARGET_USER" | cut -d: -f6)
SDDM_SRC="$USER_HOME/.local/share/sddm-themes/masterr-glass"
GRUB_SRC="$USER_HOME/.local/share/grub-themes/masterr-glass"

echo "======================================================"
echo "  Installing MasterR Liquid Glass Themes (GRUB & SDDM)"
echo "  Target User: $TARGET_USER"
echo "======================================================"

# -------------------------------------------------------------
# 1. SDDM THEME INSTALLATION
# -------------------------------------------------------------
echo "[*] Installing SDDM Theme..."
mkdir -p /usr/share/sddm/themes/masterr-glass
cp -r "$SDDM_SRC"/* /usr/share/sddm/themes/masterr-glass/

# Setup shared background cache directory with user write permissions
mkdir -p /var/cache/masterr
chown -R "$TARGET_USER:$TARGET_USER" /var/cache/masterr 2>/dev/null || true
chmod 777 /var/cache/masterr 2>/dev/null || true

# Configure SDDM Theme setting
mkdir -p /etc/sddm.conf.d
cat << 'SDDM_CONF' > /etc/sddm.conf.d/theme.conf
[Theme]
Current=masterr-glass
SDDM_CONF

echo "[✓] SDDM Theme installed and set to 'masterr-glass'."

# -------------------------------------------------------------
# 2. GRUB THEME INSTALLATION
# -------------------------------------------------------------
echo "[*] Installing GRUB Theme to /boot/grub/themes/masterr-glass..."
mkdir -p /boot/grub/themes/masterr-glass
cp -r "$GRUB_SRC"/* /boot/grub/themes/masterr-glass/

# Setup background sync helper for vfat /boot partition
cat << 'GRUB_SYNC' > /usr/local/bin/sync-grub-bg
#!/usr/bin/env bash
set -euo pipefail
SRC="${1:-}"
[ -n "$SRC" ] && [ -f "$SRC" ] || exit 0
TARGET="/boot/grub/themes/masterr-glass/background.png"
mkdir -p "$(dirname "$TARGET")"
cp "$SRC" "$TARGET.tmp" && mv "$TARGET.tmp" "$TARGET"
GRUB_SYNC
chmod 755 /usr/local/bin/sync-grub-bg

# Configure passwordless sudo helper for wallpaper syncing
mkdir -p /etc/sudoers.d
echo "$TARGET_USER ALL=(root) NOPASSWD: /usr/local/bin/sync-grub-bg" > /etc/sudoers.d/masterr-grub-bg
chmod 440 /etc/sudoers.d/masterr-grub-bg

# Update /etc/default/grub
if grep -q "^GRUB_THEME=" /etc/default/grub; then
    sed -i 's|^GRUB_THEME=.*|GRUB_THEME="/boot/grub/themes/masterr-glass/theme.txt"|' /etc/default/grub
elif grep -q "^#GRUB_THEME=" /etc/default/grub; then
    sed -i 's|^#GRUB_THEME=.*|GRUB_THEME="/boot/grub/themes/masterr-glass/theme.txt"|' /etc/default/grub
else
    echo 'GRUB_THEME="/boot/grub/themes/masterr-glass/theme.txt"' >> /etc/default/grub
fi

# Ensure graphical terminal is enabled in GRUB
sed -i 's|^GRUB_TERMINAL_OUTPUT="console"|#GRUB_TERMINAL_OUTPUT="console"|' /etc/default/grub 2>/dev/null || true
sed -i 's|^#GRUB_GFXMODE=.*|GRUB_GFXMODE=1920x1080,auto|' /etc/default/grub 2>/dev/null || true
if ! grep -q "^GRUB_GFXMODE=" /etc/default/grub; then
    echo 'GRUB_GFXMODE=1920x1080,auto' >> /etc/default/grub
fi

echo "[*] Regenerating GRUB configuration with grub-mkconfig..."
grub-mkconfig -o /boot/grub/grub.cfg

echo "[✓] GRUB Theme installed and configured."

# -------------------------------------------------------------
# 3. INITIAL WALLPAPER SYNC
# -------------------------------------------------------------
echo "[*] Running initial wallpaper synchronization..."
sudo -u "$TARGET_USER" "$USER_HOME/.config/hypr/scripts/sync-theme-wallpaper.sh" || true

echo "======================================================"
echo "  Installation Complete! Liquid Glass Themes Active."
echo "======================================================"

#!/usr/bin/env bash
# Install the Torii GRUB theme + curated 3-entry boot menu (CachyOS New/Old, Windows).
# Run as root:  sudo bash configs/grub/install-torii.sh
set -euo pipefail

REPO="$(cd "$(dirname "$0")" && pwd)"
SRC="$REPO/themes/torii"
DEST="/boot/grub/themes/torii"
GRUBDEF="/etc/default/grub"

[ "$(id -u)" -eq 0 ] || { echo "run as root: sudo bash $0"; exit 1; }

echo "==> install theme files -> $DEST"
mkdir -p "$DEST"
find "$DEST" -name '*.pf2' -delete 2>/dev/null || true
cp -f "$SRC"/theme.txt "$SRC"/background.png "$SRC"/*.pf2 "$SRC"/select_*.png "$DEST/"

echo "==> backup + set GRUB_THEME / timeout / gfxmode"
cp -n "$GRUBDEF" "$GRUBDEF.bak-pre-torii" || true
grep -q '^GRUB_THEME=' "$GRUBDEF" \
  && sed -i "s|^GRUB_THEME=.*|GRUB_THEME='$DEST/theme.txt'|" "$GRUBDEF" \
  || echo "GRUB_THEME='$DEST/theme.txt'" >> "$GRUBDEF"
sed -i "s|^GRUB_TIMEOUT=.*|GRUB_TIMEOUT='10'|" "$GRUBDEF"
sed -i "s|^GRUB_GFXMODE=.*|GRUB_GFXMODE='2560x1440,auto'|" "$GRUBDEF"

echo "==> install curated 3-entry menu, disable auto-generators"
cp -f "$REPO/10_masterr" /etc/grub.d/10_masterr
chmod 755 /etc/grub.d/10_masterr
rm -f /etc/grub.d/11_cachyos_old
for g in 10_linux 30_os-prober 30_uefi-firmware 41_snapshots-btrfs 20_linux_xen 25_bli; do
  [ -e "/etc/grub.d/$g" ] && chmod -x "/etc/grub.d/$g" || true
done

echo "==> regenerate grub.cfg"
grub-mkconfig -o /boot/grub/grub.cfg

echo "==> boot menu entries:"
grep -E "^menuentry" /boot/grub/grub.cfg | sed -E "s/'([^']*)'.*/  -> \1/"
echo "==> DONE. Reboot to see torii theme."

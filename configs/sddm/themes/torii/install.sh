#!/usr/bin/env bash
set -euo pipefail

THEME_NAME="torii"
SRC_DIR="$(cd "$(dirname "$0")" && pwd)"
DEST_DIR="/usr/share/sddm/themes/${THEME_NAME}"
CONF_DIR="/etc/sddm.conf.d"
CONF_FILE="${CONF_DIR}/10-theme.conf"

echo ":: Installing SDDM theme '${THEME_NAME}'"
echo "   source : ${SRC_DIR}"
echo "   target : ${DEST_DIR}"

echo ":: Copying theme files (sudo)"
sudo install -d -m 0755 "${DEST_DIR}"
sudo cp -aT "${SRC_DIR}" "${DEST_DIR}"
sudo rm -f "${DEST_DIR}/install.sh" "${DEST_DIR}/Xsetup-torii.sh"

echo ":: Installing X11 setup script (primary output + cursor warp)"
sudo install -D -m 0755 "${SRC_DIR}/Xsetup-torii.sh" /etc/sddm/Xsetup-torii.sh
sudo tee "${CONF_DIR}/20-xsetup.conf" >/dev/null <<EOF
[X11]
DisplayCommand=/etc/sddm/Xsetup-torii.sh
EOF

echo ":: Writing ${CONF_FILE} (sudo)"
sudo install -d -m 0755 "${CONF_DIR}"
sudo tee "${CONF_FILE}" >/dev/null <<EOF
[Theme]
Current=${THEME_NAME}
EOF

echo ":: Disabling SDDM on-screen virtual keyboard"
sudo tee "${CONF_DIR}/virtualkeyboard.conf" >/dev/null <<EOF
[General]
InputMethod=
EOF

echo ":: Done. Theme installed and selected."
echo "   Test without logging out:"
echo "     sddm-greeter-qt6 --test-mode --theme ${DEST_DIR}"
echo "   The sddm service was NOT touched; (re)start it yourself when ready."

#!/usr/bin/env bash
set -euo pipefail

THEME_NAME="masterr-glass"
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
sudo rm -f "${DEST_DIR}/install.sh"

echo ":: Writing ${CONF_FILE} (sudo)"
sudo install -d -m 0755 "${CONF_DIR}"
sudo tee "${CONF_FILE}" >/dev/null <<SDDM_CONF
[Theme]
Current=${THEME_NAME}
SDDM_CONF

echo ":: Disabling SDDM on-screen virtual keyboard"
sudo tee "${CONF_DIR}/virtualkeyboard.conf" >/dev/null <<SDDM_VK
[General]
InputMethod=
SDDM_VK

echo ":: Done. Theme installed and selected."

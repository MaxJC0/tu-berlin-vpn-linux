#!/bin/sh
# Install the TU Berlin VPN tray app for the current user.
set -e
cd "$(dirname "$0")"

CON_NAME="TU Berlin VPN"
USER_AGENT="AnyConnect Linux_64 4.10.07061"
BINDIR="$HOME/.local/bin"
APPDIR="$HOME/.local/share/applications"

missing=""
command -v openconnect >/dev/null || missing="$missing openconnect"
[ -x /usr/lib/nm-openconnect-auth-dialog ] || missing="$missing networkmanager-openconnect"
python3 -c 'import PyQt6' 2>/dev/null || missing="$missing python-pyqt6"
if [ -n "$missing" ]; then
  echo "Missing:$missing"
  echo "Arch: sudo pacman -S openconnect networkmanager-openconnect python-pyqt6"
  exit 1
fi

if nmcli -g connection.id connection show "$CON_NAME" >/dev/null 2>&1; then
  echo "NetworkManager profile '$CON_NAME' already exists, updating it."
  nmcli connection modify "$CON_NAME" vpn.data \
    "gateway=vpn.tu-berlin.de,protocol=anyconnect,useragent=$USER_AGENT,cookie-flags=2,gateway-flags=2,gwcert-flags=2"
else
  nmcli connection add type vpn con-name "$CON_NAME" vpn-type openconnect \
    vpn.data "gateway=vpn.tu-berlin.de,protocol=anyconnect,useragent=$USER_AGENT,cookie-flags=2,gateway-flags=2,gwcert-flags=2" \
    ipv4.never-default yes ipv6.never-default yes
fi

mkdir -p "$BINDIR" "$APPDIR"
install -m 755 tu-vpn-tray tu-vpn "$BINDIR/"
sed "s|@BINDIR@|$BINDIR|" tu-vpn.desktop > "$APPDIR/tu-vpn.desktop"
command -v update-desktop-database >/dev/null && update-desktop-database "$APPDIR" 2>/dev/null || true

echo "Done. Start 'TU Berlin VPN' from your app launcher."

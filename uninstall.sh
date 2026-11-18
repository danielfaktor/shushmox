#!/bin/sh
# Remove the patch script and apt hook, and restore the original UI files.
set -eu
JS=/usr/share/javascript/proxmox-widget-toolkit/proxmoxlib.js
TPL=/usr/share/pve-yew-mobile-gui/index.html.tpl

if [ "$(id -u)" -ne 0 ]; then
  echo "error: run as root" >&2; exit 1
fi
if [ ! -f "$JS" ]; then
  echo "error: $JS not found; this does not look like a Proxmox host" >&2; exit 1
fi

rm -f /etc/apt/apt.conf.d/86shushmox /usr/local/sbin/shushmox
pkgs=proxmox-widget-toolkit
dpkg -s pve-yew-mobile-gui >/dev/null 2>&1 && pkgs="$pkgs pve-yew-mobile-gui"
# shellcheck disable=SC2086 # $pkgs is a word list
DEBIAN_FRONTEND=noninteractive apt-get install -y --reinstall $pkgs
rm -f "$JS.orig" "$TPL.orig"
systemctl reload pveproxy.service
echo "uninstalled; original UI files restored"

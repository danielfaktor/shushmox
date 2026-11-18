#!/bin/sh
# Install the patch script and apt hook, then apply the patch once.
set -eu
JS=/usr/share/javascript/proxmox-widget-toolkit/proxmoxlib.js
TPL=/usr/share/pve-yew-mobile-gui/index.html.tpl
cd "$(dirname "$0")"

if [ "$(id -u)" -ne 0 ]; then
  echo "error: run as root" >&2; exit 1
fi
if [ ! -f "$JS" ]; then
  echo "error: $JS not found; this does not look like a Proxmox host" >&2; exit 1
fi

install -m 755 shushmox /usr/local/sbin/shushmox
install -m 644 86shushmox /etc/apt/apt.conf.d/86shushmox
/usr/local/sbin/shushmox

ok=1
for f in "$JS" "$TPL"; do
  if [ -f "$f" ] && ! grep -q 'SHUSHMOX-PATCHED' "$f"; then
    echo "patch did not apply to $f (upstream code changed?); see: journalctl -t shushmox" >&2
    ok=
  fi
done
[ -n "$ok" ] || exit 1
echo "installed and applied"

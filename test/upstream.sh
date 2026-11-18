#!/bin/sh
# Apply shushmox to the current upstream Proxmox sources and check that both patches still land.
set -eu
cd "$(dirname "$0")/.."
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
export SHUSHMOX_JS="$tmp/proxmoxlib.js" SHUSHMOX_TPL="$tmp/index.html.tpl"
curl -fsSL 'https://git.proxmox.com/?p=proxmox-widget-toolkit.git;a=blob_plain;f=src/Utils.js;hb=HEAD' -o "$SHUSHMOX_JS"
curl -fsSL 'https://git.proxmox.com/?p=ui/pve-yew-mobile-gui.git;a=blob_plain;f=index.html.tpl;hb=HEAD' -o "$SHUSHMOX_TPL"

fail() { echo "FAIL: $*" >&2; exit 1; }

./shushmox
./shushmox # a second run must change nothing

[ "$(grep -c SHUSHMOX-PATCHED "$SHUSHMOX_JS")" -eq 1 ] || fail "web UI patch did not apply"
[ "$(diff "$SHUSHMOX_JS.orig" "$SHUSHMOX_JS" | grep -c '^[<>]')" -eq 2 ] || fail "web UI patch changed more than one line"
node --check "$SHUSHMOX_JS" || fail "patched web UI file is not valid JavaScript"

[ "$(grep -c SHUSHMOX-PATCHED "$SHUSHMOX_TPL")" -eq 1 ] || fail "mobile UI patch did not apply"
node test/mobile-hook.mjs "$SHUSHMOX_TPL" || fail "mobile UI fetch hook misbehaves"

echo "ok: both patches apply to upstream HEAD"

# shushmox

Stops the "No valid subscription" popup in the Proxmox VE web UI (at login and when you
open the Updates panel) and in the mobile UI. It keeps working after package upgrades,
and it never breaks an apt run.

## What it changes

### Web UI

The popup comes from `Proxmox.Utils.checked_command` in
`/usr/share/javascript/proxmox-widget-toolkit/proxmoxlib.js`, which ships in the
`proxmox-widget-toolkit` package. That function asks the API for the subscription
status and shows the popup when the status is not `active`.

The patch changes one line inside that function:

```diff
-                        res.data.status.toLowerCase() !== 'active'
+                        false /* SHUSHMOX-PATCHED */
```

With that check always false, the function runs the original action straight away.
Nothing else in the file changes. The subscription status in the
Updates panel uses a different check, so it still shows correctly.

### Mobile UI

The mobile UI (`/pve2/mobile`, package `pve-yew-mobile-gui`) is compiled WebAssembly, so
its code can't be edited the same way. It shows the popup when any online node in the
`/nodes` API reply has an empty subscription `level`. The patch adds a small script to the
page template, `/usr/share/pve-yew-mobile-gui/index.html.tpl`, that fills in empty
levels in that one reply before the app reads it. All other requests pass through
unchanged.

One side effect: on the mobile dashboard, nodes without a subscription show `-` instead of
"No subscription".

## Files

| File | Installed to | Purpose |
|---|---|---|
| `shushmox` | `/usr/local/sbin/` | Applies both patches. Safe to run repeatedly. |
| `86shushmox` | `/etc/apt/apt.conf.d/` | apt hook that runs the script after every dpkg run |
| `install.sh` / `uninstall.sh` | — | Install or remove the two files above |
| `test/` | — | Applies the patches to the current upstream sources (run in CI weekly) |

## Tested on

- Proxmox VE 9.2.26
- proxmox-widget-toolkit 5.2.12
- Debian 13 (trixie)

The mobile UI patch is checked in CI against the upstream template and a simulated `/nodes`
reply, not yet on a live host.

## Install

Run as root on the Proxmox node:

```sh
git clone https://github.com/danielfaktor/shushmox.git
cd shushmox
./install.sh
```

Then hard-refresh the browser (Cmd+Shift+R or Ctrl+Shift+R), or use a private window.
Otherwise the browser may keep serving the cached `proxmoxlib.js`.

## Verify

```sh
grep -c SHUSHMOX-PATCHED /usr/share/javascript/proxmox-widget-toolkit/proxmoxlib.js   # 1
grep -c SHUSHMOX-PATCHED /usr/share/pve-yew-mobile-gui/index.html.tpl                  # 1
diff /usr/share/javascript/proxmox-widget-toolkit/proxmoxlib.js.orig \
     /usr/share/javascript/proxmox-widget-toolkit/proxmoxlib.js                        # one line changed
journalctl -t shushmox                                                                  # "patched ..."
```

To check what a node actually serves:

```sh
curl -sk https://<node>:8006/proxmoxlib.js | grep -c SHUSHMOX-PATCHED
```

## Clusters

Each node serves its own copy of the web UI, so run `install.sh` on every node.
Run it on any node you add to the cluster later, too.
The patch works whether you reach the UI through a node's IP or through a shared
virtual IP (keepalived or similar), and it doesn't need a virtual IP.

## Upgrades

An upgrade of `proxmox-widget-toolkit` or `pve-yew-mobile-gui` replaces the patched file.
The apt hook (`DPkg::Post-Invoke`) runs the script after every package operation,
so the patch is applied again right after the upgrade, and `pveproxy` is reloaded.

This was tested by running `apt-get install --reinstall proxmox-widget-toolkit`
on a patched node. The reinstall restored the original file, the hook ran,
and the marker was back in place with `pveproxy` still active.

## If upstream changes the code

The script only edits a file when it finds the expected code. If a future release
renames or restructures it:

- the file is left unchanged and the popup comes back
- the web UI keeps working
- a message is logged: `journalctl -t shushmox` shows `pattern not found ... left unchanged`

`install.sh` exits non-zero in that case. The apt hook never fails an apt run.

A weekly CI job applies the patches to the latest upstream sources, so a breaking change
upstream shows up as a failed build here, often before it reaches the package repos.

Before each patch the script saves a copy of the unpatched file next to it with an `.orig`
suffix.

## Uninstall

```sh
./uninstall.sh
```

This removes the script and the hook, reinstalls `proxmox-widget-toolkit` (and
`pve-yew-mobile-gui` if present) to restore the original files, and reloads `pveproxy`.
Hard-refresh the browser afterwards.

## Disclaimer

This is unofficial and not affiliated with Proxmox Server Solutions GmbH. Use at your own
risk. It only edits client-side UI checks and doesn't change licensing, repositories, or
any server-side behavior. If Proxmox VE is useful to you, consider supporting the project
with a subscription.

## License

MIT. See [LICENSE](LICENSE).

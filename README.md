# TU Berlin VPN on Linux (without Cisco Secure Client)

A small tray app that connects to the TU Berlin VPN (`vpn.tu-berlin.de`, 2FA profiles) using the open-source
[openconnect](https://www.infradead.org/openconnect/) and NetworkManager, instead of the official Cisco Secure Client.

Open the app, log in on the TU page with password + TAN, and it sits in the system tray: hover for status (IP, connected
time), right-click → **Disconnect**.

> Unofficial. Not affiliated with TU Berlin / ZECM. Tested on Arch Linux (Hyprland, Wayland, NVIDIA).

## How it works

The [official TU guide](https://www.tu.berlin/go142249/) uses Cisco's installer. `openconnect` implements the same
AnyConnect protocol, but the TU server needs a few adjustments:

1. **SSO login in an embedded browser.** The 2FA profiles use SAML single sign-on, which the server only offers in an
   embedded browser. Plain `openconnect` fails with `No SSO handler`, and `--external-browser` is not supported by the
   server. The app therefore uses the WebKit login window shipped with `networkmanager-openconnect`
   (`/usr/lib/nm-openconnect-auth-dialog`).
2. **Cisco user agent.** With openconnect's default user agent the server responds with `404` and falls back to a plain
   username/password form that cannot do 2FA. The user agent `AnyConnect Linux_64 4.10.07061` gets the SSO login.
3. **No group in the request.** Setting `usergroup` also results in a `404`. The default group
   (`1-TU-Split-Tunnel-2FA`) is preselected in the login window.
4. **NVIDIA + Wayland.** WebKitGTK may stop redrawing, which makes the login window appear frozen. The app sets
   `WEBKIT_DISABLE_DMABUF_RENDERER=1` and `WEBKIT_DISABLE_COMPOSITING_MODE=1`.
5. **No sudo.** The session cookie from the login window is handed to NetworkManager
   (`nmcli connection up … passwd-file`), which runs openconnect itself. This requires the profile's secrets to be marked
   as not saved (`cookie-flags=2`, `gateway-flags=2`, `gwcert-flags=2`); otherwise activation fails with
   `No valid secrets`.

The tray UI is a small PyQt6 app.

## Install

Requirements: NetworkManager, `openconnect`, `networkmanager-openconnect`, `python-pyqt6`, and a desktop with a system tray
(StatusNotifierItem).

```sh
# Arch
sudo pacman -S openconnect networkmanager-openconnect python-pyqt6

git clone https://github.com/MaxJC0/tu-berlin-vpn-linux.git
cd tu-berlin-vpn-linux
./install.sh
```

`install.sh` creates a NetworkManager profile **"TU Berlin VPN"** (split tunnel: only TU traffic goes through the VPN)
and installs `tu-vpn-tray`, `tu-vpn` to `~/.local/bin` and a launcher entry.

## Usage

1. Start **TU Berlin VPN** from your app launcher.
2. In the login window, keep the group `1-TU-Split-Tunnel-2FA` and click **Connect**.
3. Log in with your TUB account, password and TAN.
4. The window closes and a tray icon appears. Hover for status.
5. Right-click the tray icon → **Disconnect**.

Starting the app again while it is connected only shows a notification. If a login window got lost, starting it again
replaces the stuck instance.

**Check it's working:** `ip -br addr | grep vpn0` shows a `130.149.x.x` address.

**Terminal fallback:** `tu-vpn` does the same login without the tray and runs openconnect with `sudo` in the foreground
(Ctrl+C to disconnect).

**Full tunnel** (all traffic through TU): pick `2-TU-Full-Tunnel-2FA` in the login window, and run
`nmcli connection modify "TU Berlin VPN" ipv4.never-default no ipv6.never-default no`.

## Uninstall

```sh
rm ~/.local/bin/tu-vpn-tray ~/.local/bin/tu-vpn ~/.local/share/applications/tu-vpn.desktop
nmcli connection delete "TU Berlin VPN"
```

## License

MIT

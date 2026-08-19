#!/usr/bin/env bash
# Diagnose niri/xdg-desktop-portal screencast breakage.
#
# Read-only: this script makes no changes, it only gathers state.
#
# Background (2026-08-19 investigation)
# --------------------------------------
# Screensharing under niri depends on a chain of three things all lining up:
#
#   1. component/niri/niri.nix xdg.portal.config.niri must route the
#      *exact* interface name org.freedesktop.impl.portal.ScreenCast (capital
#      C) to "gnome". A case typo here (e.g. "Screencast") is silently
#      ignored by xdg-desktop-portal and falls back to `default`, which may
#      pick "gtk" first -- gtk does not implement ScreenCast, so every
#      request fails with "No such interface". Found and fixed a real
#      instance of this typo at component/niri/niri.nix:79.
#
#   2. Even with (1) fixed, xdg-desktop-portal-gnome only *exports*
#      org.freedesktop.impl.portal.ScreenCast/RemoteDesktop/Clipboard/
#      InputCapture if it could reach org.gnome.Mutter.ScreenCast (niri's
#      own implementation of the Mutter D-Bus API) at its OWN startup. If
#      niri didn't own that name yet, xdg-desktop-portal-gnome silently
#      drops those interfaces from what it exports for the rest of its
#      life -- introspect it to check (see below). Restarting
#      xdg-desktop-portal-gnome only helps if niri already owns the Mutter
#      name by the time it restarts.
#
#   3. niri registers org.gnome.Mutter.ScreenCast with D-Bus flags
#      AllowReplacement | ReplaceExisting | DoNotQueue (see
#      src/dbus/mutter_screen_cast.rs upstream). This means ANY other
#      client that calls RequestName with ReplaceExisting on that same
#      name can steal it from niri, and because niri does not queue to
#      reclaim it, once the thief disconnects the name is permanently
#      unowned until niri itself is restarted. This is the most likely
#      explanation for "it worked before, broke with no config change,
#      and a reboot fixes it" -- something (a duplicate niri instance, a
#      stray tool) briefly grabbed the name and let it go.
#
# Net effect: (3) is the actual root cause of a spontaneous break; fixing
# it in the *current* login session requires niri to re-register the name,
# which today only happens by restarting niri (disruptive to the whole
# compositor session). (1) is a real bug worth keeping fixed regardless,
# but does not by itself explain a screencast outage that appeared without
# a config change.
#
# There is also an unrelated, currently-blocking issue: `make home` fails
# to evaluate because programs.niri.settings.xwayland no longer exists in
# the pinned niri-flake input (schema changed upstream). This must be
# fixed before any niri.nix change -- including the ScreenCast typo fix --
# can be applied via `make home`.
set -euo pipefail

section() {
    printf '\n=== %s ===\n' "$1"
}

section "Session"
echo "XDG_SESSION_TYPE=${XDG_SESSION_TYPE:-<unset>}"
echo "XDG_CURRENT_DESKTOP=${XDG_CURRENT_DESKTOP:-<unset>}"
loginctl show-session "$(loginctl list-sessions --no-legend | awk '{print $1}' | head -1)" 2>/dev/null \
    | grep -E '^(Type|Desktop)=' || true

section "niri process"
pgrep -a niri || echo "niri not running"
if command -v niri >/dev/null; then
    niri --version
fi

section "pipewire / portal service status"
for unit in pipewire pipewire-pulse wireplumber xdg-desktop-portal xdg-desktop-portal-gnome xdg-desktop-portal-gtk; do
    printf '%-28s %s\n' "$unit" "$(systemctl --user is-active "$unit" 2>&1)"
done

section "D-Bus: who owns the Mutter ScreenCast/RemoteDesktop names (niri implements these)"
for name in org.gnome.Mutter.ScreenCast org.gnome.Mutter.RemoteDesktop; do
    owner=$(busctl --user call org.freedesktop.DBus /org/freedesktop/DBus \
        org.freedesktop.DBus GetNameOwner s "$name" 2>&1) || true
    echo "$name -> $owner"
done
echo
echo "If either shows 'The name does not have an owner', niri lost its"
echo "D-Bus registration (see point 3 above) and screencast/remote-desktop"
echo "cannot work until niri is restarted."

section "What xdg-desktop-portal-gnome actually exports right now"
echo "(if ScreenCast/RemoteDesktop/Clipboard/InputCapture are missing below,"
echo " it decided at its own startup that niri's Mutter API was unavailable)"
busctl --user introspect org.freedesktop.impl.portal.desktop.gnome /org/freedesktop/portal/desktop 2>&1 \
    | grep -E 'org\.freedesktop\.impl\.portal\.' || echo "could not introspect gnome portal backend"

section "portals.conf search order (all files xdg-desktop-portal merges for desktop=niri)"
for f in \
    "$HOME/.config/xdg-desktop-portal/niri-portals.conf" \
    /etc/xdg/xdg-desktop-portal/niri-portals.conf \
    "$HOME/.nix-profile/share/xdg-desktop-portal/niri-portals.conf" \
    /run/current-system/sw/share/xdg-desktop-portal/niri-portals.conf \
    ; do
    if [[ -f "$f" ]]; then
        echo "--- $f ---"
        cat "$f"
        echo
    fi
done

section "Sanity check: portal config keys use the correct interface name"
# The real interface is org.freedesktop.impl.portal.ScreenCast (capital C).
# A typo here is silently ignored and falls back to `default`.
for f in \
    "$HOME/.config/xdg-desktop-portal/niri-portals.conf" \
    /etc/xdg/xdg-desktop-portal/niri-portals.conf \
    ; do
    [[ -f "$f" ]] || continue
    if grep -qi '^org\.freedesktop\.impl\.portal\.screencast' "$f" \
        && ! grep -q '^org\.freedesktop\.impl\.portal\.ScreenCast' "$f"; then
        echo "MISMATCH in $f: key present but wrong case, will not override 'default'"
    fi
done

section "Recent portal errors (this boot)"
journalctl -b --no-pager _COMM=xdg-desktop-portal 2>/dev/null \
    | grep -iE 'screencast|backend call failed' | tail -20 || true
journalctl -b --no-pager _COMM=xdg-desktop-portal-gnome 2>/dev/null | tail -20 || true

section "Current niri.nix source (for reference against the ScreenCast typo)"
REPO_ROOT="$(git -C "$(dirname "${BASH_SOURCE[0]}")" rev-parse --show-toplevel 2>/dev/null || true)"
if [[ -n "$REPO_ROOT" && -f "$REPO_ROOT/component/niri/niri.nix" ]]; then
    grep -n 'org.freedesktop.impl.portal' "$REPO_ROOT/component/niri/niri.nix"
fi

section "Next steps"
cat <<'EOF'
1. If org.gnome.Mutter.ScreenCast has no owner: only restarting niri
   re-registers it. There is no known way to make niri re-request a
   D-Bus name it lost while remaining alive. Log out/in or reboot.

2. `make home` is currently blocked by an unrelated niri-flake schema
   change (programs.niri.settings.xwayland removed). That must be fixed
   in component/niri/niri.nix before the ScreenCast typo fix (or anything
   else in niri.nix) can be applied via `make home`.

3. Once `make home` succeeds and niri.nix has the corrected
   "org.freedesktop.impl.portal.ScreenCast" key, restart the portal user
   units to pick up the new niri-portals.conf without a full logout:

       systemctl --user restart xdg-desktop-portal xdg-desktop-portal-gnome xdg-desktop-portal-gtk

   This alone will NOT fix a lost org.gnome.Mutter.ScreenCast ownership
   (step 1) -- both issues need to be resolved together.
EOF

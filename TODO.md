# To do

## Trash location support in Files (nautilus)

Fix:

> Oops! Something went wrong.
>
> "trash" locations are not supported.

## Mako doesn't consistently choose an output for notifications

When the system resumes from suspend and during some output configuration changes, such as docking or undocking the laptop, Mako sometimes chooses the wrong display to draw notifications on.

## OBS should inhibit screen lock

When OBS is actively recording or streaming, the system should not lock the session or suspend the system.

## Firefox popover menus are broken

Firefox popover menus should reliably be displayed and not be positioned off screen. At the moment under Niri in Firefox 149 anmd 150, it appears as though this is broken. The fix seems to have landed in the Firefox one fifty one series, but that's not yet in nixpkgs.

## wpaperd doesn't reliably scale the wallpaper

When multiple displays are connected to a system, it appears as though wpaperd gets confused and draws the wallpaper at the wrong size on some displays, not scaling it to match the full display resolution.

# linux-tools

My KDE Plasma 6 customizations.

## Plasmoids

| Widget | ID | Description |
|---|---|---|
| [Media Controls](plasmoids/mediacontrols) | `com.furkan.mediacontrols` | Compact media controls with album art, seek bar, shuffle and repeat |
| [Sound Panel](plasmoids/soundpanel) | `com.furkan.soundpanel` | Sound control panel with per-app volume (system tray) |
| [Notifications](plasmoids/notifications) | — | Work in progress |
| [Lockscreen Media Controls](plasmoids/lockscreen-media-controls) | — | Work in progress |

## Install

Requires Plasma 6 (`kpackagetool6`).

```sh
./install.sh                 # install/upgrade all widgets
./install.sh soundpanel      # just one (folder name under plasmoids/)
```

The script restarts `plasmashell` afterwards so changes take effect.

## License

GPL-2.0-or-later. See [LICENSE](LICENSE).

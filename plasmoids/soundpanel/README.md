# Sound Panel

`com.furkan.soundpanel`: a Plasma 6 system tray sound panel with per-app volume, a replacement for the stock Audio Volume applet.

## Features

- **Output / Input** tabs, switched with a segmented control
- **Device picker** for the default speaker/headphones or microphone (monitor sources are hidden)
- **Master volume** with mute, a live level meter, and up to 150% with a marker at 100%. Volume above 100% shows in the warning color.
- **Per-app volume**, with streams grouped by application:
  - One slider controls all of an app's streams (e.g. every browser tab)
  - Click **"· N streams"** to expand and adjust each stream on its own. Generic names like "Playback" are shown as "Stream 1", "Stream 2", …
  - Right-click an app to move it to another output or input device
  - App icons come from open windows when possible, so apps that report the wrong icon name still look right
- Settings button that opens the System Settings audio page
- Scrolls when there are more apps than fit in the tray popup

## Tray icon

| Action | Result |
|---|---|
| Left click | Open/close the panel |
| Middle click | Mute/unmute the output |
| Scroll | Output volume ±5% |

Hover the icon to see the device name and volume.

## Install

From the repo root:

```sh
./install.sh soundpanel
```

Then enable **Sound Panel** in *System Tray Settings → Entries*. You'll probably want to hide the stock **Audio Volume** entry so you don't get two icons.

## Requirements

- Plasma 6.0+
- `plasma-pa` (PulseAudio/PipeWire QML module)
- `plasma-workspace` (task manager module, used for app icons)
- `kcmutils`

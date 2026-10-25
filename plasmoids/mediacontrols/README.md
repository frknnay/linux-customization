# Media Controls

`com.furkan.mediacontrols`: a compact Plasma 6 panel widget for whatever is playing over MPRIS (Spotify, browsers, mpv, …).

## Features

- Album art (falls back to the player's icon), track title, artist and album
- Seek bar with elapsed/total time; drag to seek
- Previous / play-pause / next
- Shuffle toggle and repeat that cycles **off → playlist → track**
- Hides itself from the panel when nothing has played for 10 seconds, and comes back as soon as media starts. Browser tabs that leave an empty player behind don't count as playing.

## Panel icon

| Action | Result |
|---|---|
| Left click | Open/close the popup |
| Middle click | Play/pause |
| Scroll | Change the player's volume (±5%) |

Hover the icon to see the current track and artist.

## Install

From the repo root:

```sh
./install.sh mediacontrols
```

Then add **Media Controls** to a panel. While the widget is hidden, it still shows in panel edit mode.

## Requirements

- Plasma 6.0+
- `plasma-workspace` (provides the MPRIS QML module)

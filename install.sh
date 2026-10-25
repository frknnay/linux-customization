#!/usr/bin/env bash
# Install or upgrade plasmoids for the current user, then reload plasmashell.
# Usage: ./install.sh            # all plasmoids
#        ./install.sh soundpanel # only the named ones
set -euo pipefail
cd "$(dirname "$0")/plasmoids"

if [[ $# -gt 0 ]]; then
    targets=("$@")
else
    targets=(*/)
fi

installed=$(kpackagetool6 -t Plasma/Applet -l)
changed=0

for dir in "${targets[@]}"; do
    dir=${dir%/}
    if [[ ! -f $dir/metadata.json ]]; then
        echo "skip: $dir (no metadata.json)"
        continue
    fi

    id=$(grep -oP '"Id"\s*:\s*"\K[^"]+' "$dir/metadata.json")
    if grep -qx "$id" <<<"$installed"; then
        echo "upgrade: $id"
        kpackagetool6 -t Plasma/Applet -u "$dir"
    else
        echo "install: $id"
        kpackagetool6 -t Plasma/Applet -i "$dir"
    fi
    changed=1
done

if (( changed )); then
    systemctl --user restart plasma-plasmashell.service
fi

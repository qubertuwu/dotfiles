#!/usr/bin/env bash

WORKSHOP_DIR="$HOME/.local/share/Steam/steamapps/workshop/content/431960"
SCRIPT_PATH="$HOME/.config/quickshell/end4-pC/scripts/sync_wallpaper_engine.py"

mkdir -p "$WORKSHOP_DIR"

# Run initial sync on startup
python3 "$SCRIPT_PATH"
python3 "$HOME/.config/quickshell/end4-pC/scripts/sync_wallpapers.py"

# Watch for new files, finished downloads, or deletions in the workshop content directory
while true; do
    inotifywait -m -r -e create,close_write,delete,moved_to "$WORKSHOP_DIR" --format "%w%f" 2>/dev/null | while read -r changed; do
        # Debounce rapid file writes while Steam finishes downloading
        while read -r -t 2 ignored; do :; done
        python3 "$SCRIPT_PATH"
        python3 "$HOME/.config/quickshell/end4-pC/scripts/sync_wallpapers.py"
    done
    sleep 3
done

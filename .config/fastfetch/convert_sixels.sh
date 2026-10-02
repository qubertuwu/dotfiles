#!/bin/bash
PHOTO_DIR="$HOME/.config/fastfetch/photos"
SIXEL_DIR="$HOME/.config/fastfetch/sixels"
mkdir -p "$SIXEL_DIR"

for img in "$PHOTO_DIR"/*.jpg; do
    [ -f "$img" ] || continue
    name=$(basename "$img" .jpg)
    out="$SIXEL_DIR/$name.six"
    if [ ! -f "$out" ] || [ "$img" -nt "$out" ]; then
        magick "$img" -resize 280x280 sixel:"$out"
    fi
done

#!/bin/bash
# Запуск: ~/.config/fastfetch/add_photo.sh /путь/к/картинке.jpg
PHOTO_DIR="$HOME/.config/fastfetch/photos"
SIXEL_DIR="$HOME/.config/fastfetch/sixels"
mkdir -p "$PHOTO_DIR" "$SIXEL_DIR"

if [ -f "$1" ]; then
    cp "$1" "$PHOTO_DIR/"
    filename=$(basename "$1")
    name="${filename%.*}"
    magick "$1" -resize 280x280 sixel:"$SIXEL_DIR/$name.six"
    echo "Добавлено: $name"
else
    echo "Файл не найден: $1"
fi

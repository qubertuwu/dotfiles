#!/usr/bin/env bash
set -e

APK_DIR="$HOME/.var/app/org.vinegarhq.Sober/data/sober/packages/x86_64/com.roblox.client"
APK="$APK_DIR/base.apk"
BAK="$APK_DIR/base.apk.bak"

if [ ! -f "$BAK" ]; then
    echo "Ошибка: Резервная копия base.apk.bak не найдена!"
    exit 1
fi

cp -f "$BAK" "$APK"
echo "Оригинальные шрифты Roblox успешно восстановлены!"
echo "Перезапустите Sober/Roblox, чтобы изменения вступили в силу."

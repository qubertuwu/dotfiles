#!/usr/bin/env bash
set -e

FONT_FILE="${1:-$HOME/.local/share/fonts/RobloxFont121Regular-axoyE.ttf}"

if [ ! -f "$FONT_FILE" ]; then
    echo "Ошибка: Файл шрифта '$FONT_FILE' не найден!"
    exit 1
fi

python3 - << PYEOF
import os, shutil, zipfile

font_path = "$FONT_FILE"
apk_dir = os.path.expanduser("~/.var/app/org.vinegarhq.Sober/data/sober/packages/x86_64/com.roblox.client")
apk_path = os.path.join(apk_dir, "base.apk")
bak_path = os.path.join(apk_dir, "base.apk.bak")
tmp_path = os.path.join(apk_dir, "base.apk.tmp")

if not os.path.exists(apk_path):
    print("Ошибка: base.apk не найден в", apk_dir)
    exit(1)

if not os.path.exists(bak_path):
    print("Создаём резервную копию base.apk.bak...")
    shutil.copy2(apk_path, bak_path)

with open(font_path, "rb") as f:
    font_bytes = f.read()

targets = {
    'assets/content/fonts/BuilderSans-Bold.otf',
    'assets/content/fonts/BuilderSans-ExtraBold.otf',
    'assets/content/fonts/BuilderSans-Medium.otf',
    'assets/content/fonts/BuilderSans-Regular.otf',
    'assets/content/fonts/SourceSansPro-Bold.ttf',
    'assets/content/fonts/SourceSansPro-It.ttf',
    'assets/content/fonts/SourceSansPro-Light.ttf',
    'assets/content/fonts/SourceSansPro-Regular.ttf',
    'assets/content/fonts/SourceSansPro-Semibold.ttf',
    'assets/fonts/SourceSansPro-Black.ttf',
    'assets/fonts/SourceSansPro-Bold.ttf',
    'assets/fonts/SourceSansPro-Light.ttf',
    'assets/fonts/SourceSansPro-Regular.ttf',
    'assets/fonts/SourceSansPro-Semibold.ttf',
}

with zipfile.ZipFile(apk_path, 'r') as zin, zipfile.ZipFile(tmp_path, 'w') as zout:
    for item in zin.infolist():
        zinfo = zipfile.ZipInfo(item.filename, date_time=item.date_time)
        if item.filename in targets:
            zinfo.compress_type = zipfile.ZIP_STORED
            zout.writestr(zinfo, font_bytes)
        else:
            zinfo.compress_type = item.compress_type
            zinfo.flag_bits = item.flag_bits
            zout.writestr(zinfo, zin.read(item.filename))

os.replace(tmp_path, apk_path)
print("Шрифт успешно установлен в Roblox (Sober)!")
print("Перезапустите Roblox, чтобы изменения вступили в силу.")
PYEOF

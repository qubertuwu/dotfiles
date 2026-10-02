#!/usr/bin/env python3
import os
import re
import json
import urllib.parse
import hashlib
import subprocess
from PIL import Image

CACHE_BASE = os.path.expanduser("~/.cache/thumbnails")
for sz in ["normal", "large", "x-large", "xx-large"]:
    os.makedirs(os.path.join(CACHE_BASE, sz), exist_ok=True)

THEMES_DIR = os.path.expanduser("~/.cache/quickshell/presets/assets")
PRESETS_DIR = os.path.expanduser("~/.cache/quickshell/presets")
WE_DIR = os.path.expanduser("~/Изображения/Wallpaper_Engine")
TARGET_ALL = os.path.expanduser("~/Изображения/Wallpapers")
TARGET_THEMES = os.path.expanduser("~/Изображения/Theme_Wallpapers")

os.makedirs(TARGET_ALL, exist_ok=True)
os.makedirs(TARGET_THEMES, exist_ok=True)

def format_theme_name(raw):
    acronyms = {"bmw": "BMW", "gtr": "GTR", "nfs": "NFS", "v2": "v2", "4k": "4K"}
    parts = re.split(r"[-_]", raw)
    return " ".join([acronyms.get(p.lower(), p.capitalize()) for p in parts if p])

def sanitize_filename(name):
    s = re.sub(r"[/\\?%*:|\"<>]", "_", name).strip()
    s = re.sub(r"\s+", " ", s)
    return s[:120]

def generate_thumbnail(file_path):
    parts = [urllib.parse.quote(part) for part in file_path.split("/")]
    encoded_url = "file://" + "/".join(parts)
    md5 = hashlib.md5(encoded_url.encode("utf-8")).hexdigest()
    target_xxl = os.path.join(CACHE_BASE, "xx-large", f"{md5}.png")
    target_xl = os.path.join(CACHE_BASE, "x-large", f"{md5}.png")
    target_l = os.path.join(CACHE_BASE, "large", f"{md5}.png")
    target_norm = os.path.join(CACHE_BASE, "normal", f"{md5}.png")

    if os.path.exists(target_xxl) and os.path.exists(target_xl):
        return

    ext = os.path.splitext(file_path)[1].lower()
    if ext in [".mp4", ".webm", ".mkv", ".avi", ".mov"]:
        subprocess.run(["ffmpegthumbnailer", "-i", file_path, "-o", target_xxl, "-s", "1024"], stderr=subprocess.DEVNULL)
    else:
        try:
            with Image.open(file_path) as img:
                img = img.convert("RGB")
                img.thumbnail((1024, 1024), Image.Resampling.LANCZOS)
                img.save(target_xxl, "PNG", optimize=True)
        except Exception:
            subprocess.run(["magick", f"{file_path}[0]", "-resize", "1024x1024", target_xxl], stderr=subprocess.DEVNULL)

    if os.path.exists(target_xxl):
        for t in [target_xl, target_l, target_norm]:
            if not os.path.exists(t):
                try:
                    os.symlink(target_xxl, t)
                except Exception:
                    pass

def get_designated_wallpapers():
    designated = set()
    if not os.path.isdir(PRESETS_DIR):
        return designated
    for f in os.listdir(PRESETS_DIR):
        if f.endswith(".json") and f != "tree_cache.json":
            try:
                with open(os.path.join(PRESETS_DIR, f)) as jf:
                    d = json.load(jf)
                    bg = d.get("background", {})
                    for k in ["wallpaperPath", "lockWall"]:
                        p = bg.get(k, "")
                        if p and os.path.exists(p):
                            designated.add(os.path.realpath(p))
            except Exception:
                pass
    return designated

def sync():
    # Remove all current symlinks in TARGET_ALL and TARGET_THEMES so we can repopulate only clean, high-res ones
    for folder in [TARGET_ALL, TARGET_THEMES]:
        for fn in os.listdir(folder):
            fp = os.path.join(folder, fn)
            if os.path.islink(fp):
                os.remove(fp)

    designated = get_designated_wallpapers()
    theme_count = 0
    we_count = 0

    # 1. Sync theme wallpapers - ONLY high resolution widescreen wallpapers!
    if os.path.isdir(THEMES_DIR):
        for t in sorted(os.listdir(THEMES_DIR)):
            tdir = os.path.join(THEMES_DIR, t)
            if not os.path.isdir(tdir):
                continue
            theme_title = format_theme_name(t)
            imgs = [f for f in os.listdir(tdir) if f.lower().endswith((".png", ".jpg", ".jpeg", ".webp", ".gif", ".mp4")) and f not in ["preview.png", "preview-lock.png"]]
            for img in imgs:
                src = os.path.join(tdir, img)
                real_src = os.path.realpath(src)
                
                # Check resolution
                is_valid_wallpaper = False
                ext = os.path.splitext(img)[1].lower()
                if ext in [".mp4", ".webm", ".mkv"]:
                    is_valid_wallpaper = True
                else:
                    try:
                        with Image.open(src) as im:
                            w, h = im.size
                            ratio = w / h if h > 0 else 0
                            # Real desktop wallpaper must be at least 1600x900 widescreen OR designated in theme config
                            if (w >= 1600 and h >= 900 and ratio >= 1.2) or (real_src in designated and w >= 1280):
                                is_valid_wallpaper = True
                    except Exception:
                        pass

                if not is_valid_wallpaper:
                    continue

                clean_img = sanitize_filename(img)
                link_name = f"[{theme_title}] {clean_img}"
                
                # In Theme_Wallpapers
                theme_link = os.path.join(TARGET_THEMES, link_name)
                os.symlink(src, theme_link)
                generate_thumbnail(theme_link)

                # In Wallpapers (all)
                all_link = os.path.join(TARGET_ALL, link_name)
                os.symlink(src, all_link)
                generate_thumbnail(all_link)

                theme_count += 1

    # 2. Sync Wallpaper Engine wallpapers into Wallpapers (all)
    if os.path.isdir(WE_DIR):
        for item in sorted(os.listdir(WE_DIR)):
            src = os.path.join(WE_DIR, item)
            clean_item = sanitize_filename(item)
            link_name = f"[Wallpaper Engine] {clean_item}"
            all_link = os.path.join(TARGET_ALL, link_name)
            os.symlink(src, all_link)
            generate_thumbnail(all_link)
            we_count += 1

    print(f"High-quality wallpapers sync complete:")
    print(f"  - {theme_count} high-res wallpapers from themes")
    print(f"  - {we_count} Wallpaper Engine wallpapers")
    print(f"  - Total {theme_count + we_count} in {TARGET_ALL}")

if __name__ == "__main__":
    sync()

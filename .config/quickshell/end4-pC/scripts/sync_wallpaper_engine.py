#!/usr/bin/env python3
import os
import sys
import json
import glob
import re
import urllib.parse
import hashlib
import subprocess
import struct
import io
from PIL import Image

WORKSHOP_DIR = "/home/qubert/.local/share/Steam/steamapps/workshop/content/431960"
WALLPAPER_DIR = os.path.expanduser("~/Изображения/Wallpapers")
EXTRACTED_DIR = os.path.join(WALLPAPER_DIR, ".extracted")
CACHE_BASE = os.path.expanduser("~/.cache/thumbnails")

for sz in ["normal", "large", "x-large", "xx-large"]:
    os.makedirs(os.path.join(CACHE_BASE, sz), exist_ok=True)
os.makedirs(WALLPAPER_DIR, exist_ok=True)
os.makedirs(EXTRACTED_DIR, exist_ok=True)

# Also ensure ~/Pictures symlink exists
pictures_link = os.path.expanduser("~/Pictures")
if not os.path.exists(pictures_link) and not os.path.islink(pictures_link):
    try:
        os.symlink(os.path.expanduser("~/Изображения"), pictures_link)
    except Exception:
        pass

def sanitize_filename(name):
    s = re.sub(r"[/\\?%*:|\"<>]", "_", name).strip()
    s = re.sub(r"\s+", " ", s)
    return s[:120]

def generate_thumbnail(file_path):
    parts = [urllib.parse.quote(part) for part in file_path.split("/")]
    encoded_url = "file://" + "/".join(parts)
    md5 = hashlib.md5(encoded_url.encode("utf-8")).hexdigest()
    target_xl = os.path.join(CACHE_BASE, "x-large", f"{md5}.png")
    target_l = os.path.join(CACHE_BASE, "large", f"{md5}.png")
    target_xxl = os.path.join(CACHE_BASE, "xx-large", f"{md5}.png")
    target_norm = os.path.join(CACHE_BASE, "normal", f"{md5}.png")

    if not os.path.exists(target_xl):
        ext = os.path.splitext(file_path)[1].lower()
        if ext in [".mp4", ".webm", ".mkv"]:
            subprocess.run(["ffmpegthumbnailer", "-i", file_path, "-o", target_xl, "-s", "512"], stderr=subprocess.DEVNULL)
        else:
            subprocess.run(["magick", f"{file_path}[0]", "-resize", "512x512", target_xl], stderr=subprocess.DEVNULL)
        
        if os.path.exists(target_xl):
            for t in [target_l, target_xxl, target_norm]:
                if not os.path.exists(t):
                    try:
                        os.symlink(target_xl, t)
                    except Exception:
                        pass

def find_best_image_in_pkg(pkg_path):
    best_img_bytes = None
    best_ext = "png"
    best_pixels = 0
    try:
        with open(pkg_path, 'rb') as f:
            mlen = struct.unpack('<I', f.read(4))[0]
            f.seek(4 + mlen)
            num_files = struct.unpack('<I', f.read(4))[0]
            entries = []
            for _ in range(num_files):
                nlen = struct.unpack('<I', f.read(4))[0]
                name = f.read(nlen).decode('latin1', errors='ignore')
                off = struct.unpack('<I', f.read(4))[0]
                sz = struct.unpack('<I', f.read(4))[0]
                entries.append((name, off, sz))
            hend = f.tell()
            for name, off, sz in entries:
                if sz < 40000:
                    continue
                f.seek(hend + off)
                data = f.read(min(sz, 30 * 1024 * 1024))
                for sig, ext in [(b'\x89PNG\r\n\x1a\n', 'png'), (b'\xff\xd8\xff', 'jpg')]:
                    idx = data.find(sig)
                    if idx != -1:
                        try:
                            img = Image.open(io.BytesIO(data[idx:]))
                            w, h = img.size
                            if w * h > best_pixels:
                                best_pixels = w * h
                                best_img_bytes = data[idx:]
                                best_ext = ext
                        except Exception:
                            pass
    except Exception:
        pass
    return best_img_bytes, best_ext, best_pixels

def find_best_image_in_folder(folder_path):
    best_file = None
    best_pixels = 0
    for root, dirs, files in os.walk(folder_path):
        for fn in files:
            ext = os.path.splitext(fn)[1].lower()
            if ext in ['.jpg', '.jpeg', '.png', '.webp']:
                full_p = os.path.join(root, fn)
                try:
                    with Image.open(full_p) as img:
                        w, h = img.size
                        penalty = 0.5 if 'preview' in fn.lower() else 1.0
                        score = w * h * penalty
                        if score > best_pixels:
                            best_pixels = score
                            best_file = full_p
                except Exception:
                    pass
    return best_file

def sync():
    if not os.path.isdir(WORKSHOP_DIR):
        print(f"Workshop directory not found: {WORKSHOP_DIR}")
        return

    seen_names = set()
    count = 0

    for item_id in sorted(os.listdir(WORKSHOP_DIR)):
        item_path = os.path.join(WORKSHOP_DIR, item_id)
        if not os.path.isdir(item_path):
            continue
        proj_path = os.path.join(item_path, "project.json")
        title = item_id
        if os.path.exists(proj_path):
            try:
                with open(proj_path, "r", encoding="utf-8", errors="ignore") as f:
                    pdata = json.load(f)
                    title = pdata.get("title", item_id)
            except Exception:
                pass

        clean_title = sanitize_filename(title)
        if clean_title in seen_names:
            clean_title = f"{clean_title} ({item_id})"
        seen_names.add(clean_title)

        # 1. Check for standalone video
        videos = glob.glob(os.path.join(item_path, "*.mp4")) + glob.glob(os.path.join(item_path, "*.webm")) + glob.glob(os.path.join(item_path, "*.mkv"))
        if videos:
            vpath = videos[0]
            ext = os.path.splitext(vpath)[1]
            dest = os.path.join(WALLPAPER_DIR, f"{clean_title}{ext}")
            for e in ['.jpg', '.png', '.gif', '.webp', '.mp4']:
                old = os.path.join(WALLPAPER_DIR, f"{clean_title}{e}")
                if os.path.lexists(old):
                    try: os.remove(old)
                    except Exception: pass
            try:
                os.symlink(vpath, dest)
                generate_thumbnail(dest)
                count += 1
            except Exception as e:
                print(f"Error linking {clean_title}: {e}")
            continue

        # 2. Check scene.pkg
        pkg_path = os.path.join(item_path, "scene.pkg")
        pkg_bytes, pkg_ext, pkg_px = (None, None, 0)
        if os.path.exists(pkg_path):
            pkg_bytes, pkg_ext, pkg_px = find_best_image_in_pkg(pkg_path)

        # 3. Check for loose images in folder (e.g. assets/img/bg.jpg)
        loose_img = find_best_image_in_folder(item_path)
        loose_px = 0
        if loose_img and not 'preview' in os.path.basename(loose_img).lower():
            try:
                with Image.open(loose_img) as img:
                    loose_px = img.size[0] * img.size[1]
            except Exception:
                pass

        final_source = None
        final_ext = "jpg"

        if pkg_px > loose_px and pkg_bytes:
            out_name = f"{clean_title}.{pkg_ext}"
            out_path = os.path.join(EXTRACTED_DIR, out_name)
            with open(out_path, "wb") as f:
                f.write(pkg_bytes)
            final_source = out_path
            final_ext = pkg_ext
        elif loose_img and loose_px > 500000:
            final_source = loose_img
            final_ext = os.path.splitext(loose_img)[1].lstrip('.')
        else:
            fb = loose_img or os.path.join(item_path, "preview.jpg")
            if os.path.exists(fb):
                final_source = fb
                final_ext = os.path.splitext(fb)[1].lstrip('.')

        if final_source:
            for e in ['.jpg', '.png', '.gif', '.webp', '.mp4']:
                old = os.path.join(WALLPAPER_DIR, f"{clean_title}{e}")
                if os.path.lexists(old):
                    try: os.remove(old)
                    except Exception: pass
            link_path = os.path.join(WALLPAPER_DIR, f"{clean_title}.{final_ext}")
            try:
                os.symlink(final_source, link_path)
                generate_thumbnail(link_path)
                count += 1
            except Exception as e:
                print(f"Error linking {clean_title}: {e}")

    print(f"Synced {count} high-resolution Wallpaper Engine items into {WALLPAPER_DIR}")

if __name__ == "__main__":
    sync()

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
import ctypes
from PIL import Image

WORKSHOP_DIR = os.path.expanduser("~/.local/share/Steam/steamapps/workshop/content/431960")
WE_DIR = os.path.expanduser("~/Изображения/Wallpaper_Engine")
EXTRACTED_DIR = os.path.expanduser("~/.local/share/quickshell/extracted_wallpapers")
CACHE_BASE = os.path.expanduser("~/.cache/thumbnails")

for sz in ["normal", "large", "x-large", "xx-large"]:
    os.makedirs(os.path.join(CACHE_BASE, sz), exist_ok=True)
os.makedirs(WE_DIR, exist_ok=True)
os.makedirs(EXTRACTED_DIR, exist_ok=True)

# Also ensure ~/Pictures symlink exists
pictures_link = os.path.expanduser("~/Pictures")
if not os.path.exists(pictures_link) and not os.path.islink(pictures_link):
    try:
        os.symlink(os.path.expanduser("~/Изображения"), pictures_link)
    except Exception:
        pass

def sanitize_filename(name):
    s = re.sub(r'[/\\?%*:|"\n\r\t]', '_', name).strip()
    s = re.sub(r'\s+', ' ', s)
    return s[:120]

def get_thumbnail_hash(file_path):
    parts = [urllib.parse.quote(part, safe="-_.!~*'()") for part in file_path.split("/")]
    encoded_url = "file://" + "/".join(parts)
    return hashlib.md5(encoded_url.encode("utf-8")).hexdigest()

def generate_thumbnail(file_path, force=False):
    md5 = get_thumbnail_hash(file_path)
    target_xl = os.path.join(CACHE_BASE, "x-large", f"{md5}.png")
    target_l = os.path.join(CACHE_BASE, "large", f"{md5}.png")
    target_xxl = os.path.join(CACHE_BASE, "xx-large", f"{md5}.png")
    target_norm = os.path.join(CACHE_BASE, "normal", f"{md5}.png")

    real_path = os.path.realpath(file_path)
    need_gen = force
    if not need_gen:
        if not os.path.exists(target_xl) or os.path.getsize(target_xl) == 0:
            need_gen = True
        elif os.path.exists(real_path) and os.path.getmtime(real_path) > os.path.getmtime(target_xl):
            need_gen = True

    if need_gen:
        for t in [target_xl, target_l, target_xxl, target_norm]:
            if os.path.islink(t) or os.path.exists(t):
                try: os.unlink(t) if os.path.islink(t) else os.remove(t)
                except Exception: pass
        ext = os.path.splitext(file_path)[1].lower()
        if ext in [".mp4", ".webm", ".mkv"]:
            subprocess.run(["ffmpegthumbnailer", "-i", file_path, "-o", target_xl, "-s", "512", "-t", "10%"], stderr=subprocess.DEVNULL)
            if not os.path.exists(target_xl) or os.path.getsize(target_xl) == 0:
                subprocess.run(["ffmpeg", "-y", "-ss", "00:00:01", "-i", file_path, "-vframes", "1", "-vf", "scale=512:512:force_original_aspect_ratio=decrease", target_xl], stderr=subprocess.DEVNULL)
        else:
            subprocess.run(["magick", f"{file_path}[0]", "-resize", "512x512", target_xl], stderr=subprocess.DEVNULL)

    if os.path.exists(target_xl) and os.path.getsize(target_xl) > 0:
        for t in [target_l, target_xxl, target_norm]:
            if not os.path.exists(t):
                try:
                    os.symlink(target_xl, t)
                except Exception:
                    pass

def is_preset_item(item_path):
    pj = os.path.join(item_path, "project.json")
    if os.path.exists(pj):
        try:
            with open(pj, "r", encoding="utf-8", errors="ignore") as f:
                d = json.load(f)
                if "preset" in d or d.get("is_preset", False):
                    return True
                if "dependency" in d and not os.path.exists(os.path.join(item_path, "scene.pkg")):
                    vids = (glob.glob(os.path.join(item_path, "*.mp4")) +
                            glob.glob(os.path.join(item_path, "*.webm")) +
                            glob.glob(os.path.join(item_path, "*.mkv")))
                    if not vids:
                        return True
        except Exception:
            pass
    return False

def read_pkg_entries(pkg_path):
    entries = {}
    try:
        with open(pkg_path, "rb") as f:
            mlen = struct.unpack("<I", f.read(4))[0]
            f.seek(4 + mlen)
            num_files = struct.unpack("<I", f.read(4))[0]
            file_meta = []
            for _ in range(num_files):
                nlen = struct.unpack("<I", f.read(4))[0]
                name = f.read(nlen).decode("latin1", errors="ignore")
                off = struct.unpack("<I", f.read(4))[0]
                sz = struct.unpack("<I", f.read(4))[0]
                file_meta.append((name, off, sz))
            hend = f.tell()
            for name, off, sz in file_meta:
                f.seek(hend + off)
                entries[name] = f.read(sz)
    except Exception as e:
        print(f"Error reading pkg {pkg_path}: {e}")
    return entries

def decompress_texb0004(tex_data):
    try:
        liblz4 = ctypes.CDLL("liblz4.so.1")
        liblz4.LZ4_decompress_safe.argtypes = [ctypes.c_char_p, ctypes.c_char_p, ctypes.c_int, ctypes.c_int]
        liblz4.LZ4_decompress_safe.restype = ctypes.c_int

        is_v4 = True
        idx = tex_data.find(b"TEXB0004")
        if idx == -1:
            idx = tex_data.find(b"TEXB0003")
            is_v4 = False
        if idx == -1: return None

        texi_idx = tex_data.find(b"TEXI0001")
        if texi_idx == -1: return None
        format_id, flags, tex_w, tex_h, orig_w, orig_h = struct.unpack("<IIIIII", tex_data[texi_idx+9:texi_idx+33])
        
        if is_v4:
            uncomp_sz, comp_sz = struct.unpack("<II", tex_data[idx+37:idx+45])
            src_bytes = tex_data[idx+45:idx+45+comp_sz]
        else:
            uncomp_sz, comp_sz = struct.unpack("<II", tex_data[idx+33:idx+41])
            src_bytes = tex_data[idx+41:idx+41+comp_sz]

        dst_buf = ctypes.create_string_buffer(uncomp_sz)
        res = liblz4.LZ4_decompress_safe(src_bytes, dst_buf, comp_sz, uncomp_sz)
        if res != uncomp_sz: return None

        dds = bytearray(128)
        dds[0:4] = b"DDS "
        struct.pack_into("<I", dds, 4, 124)
        struct.pack_into("<I", dds, 8, 0x1 | 0x2 | 0x4 | 0x1000 | 0x80000)
        struct.pack_into("<I", dds, 12, tex_h)
        struct.pack_into("<I", dds, 16, tex_w)
        struct.pack_into("<I", dds, 20, uncomp_sz)
        struct.pack_into("<I", dds, 76, 32)
        struct.pack_into("<I", dds, 80, 0x4)
        dds[84:88] = b"DXT5"
        struct.pack_into("<I", dds, 108, 0x1000)

        p = subprocess.Popen(["magick", "-", "png:-"], stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.DEVNULL)
        png_data, _ = p.communicate(input=dds + dst_buf.raw)
        if png_data and p.returncode == 0:
            im = Image.open(io.BytesIO(png_data))
            if orig_w > 0 and orig_h > 0 and (im.width != orig_w or im.height != orig_h):
                im = im.crop((0, 0, min(im.width, orig_w), min(im.height, orig_h)))
            return im
    except Exception:
        pass
    return None

def extract_embedded_video(entries, clean_title):
    for name, data in entries.items():
        if name.endswith(".tex") and len(data) > 2000000:
            idx = data.find(b"ftypisom")
            if idx != -1:
                v_start = idx - 4
                out_path = os.path.join(EXTRACTED_DIR, f"{clean_title}.mp4")
                with open(out_path, "wb") as vf:
                    vf.write(data[v_start:])
                return out_path
    return None

def extract_intelligent_scene(pkg_path, item_id, clean_title):
    entries = read_pkg_entries(pkg_path)
    if not entries:
        return None

    vid_file = extract_embedded_video(entries, clean_title)
    if vid_file:
        return vid_file

    if item_id == "3284855031":
        try:
            tex_images = {}
            for name, data in entries.items():
                if name.endswith(".tex"):
                    for sig in [b"\x89PNG\r\n\x1a\n", b"\xff\xd8\xff"]:
                        idx = data.find(sig)
                        if idx != -1:
                            tex_images[name] = Image.open(io.BytesIO(data[idx:]))
                            break
            c5 = [im for n, im in tex_images.items() if "线稿" in n or "\xe7\xba\xbf\xe7\xa8\xbf" in n]
            if c5:
                base = c5[0].convert("RGBA")
                W, H = base.size
                canvas = Image.new("RGBA", (W, H), (255, 255, 255, 255))
                sublayers = [
                    (base, 1920.0, 1080.0),
                    (tex_images.get("materials/帽子.tex") or tex_images.get("materials/\xe5\xb8\xbd\xe5\xad\x90.tex"), 2105.78, 1553.67),
                    (tex_images.get("materials/火焰.tex") or tex_images.get("materials/\xe7\x81\xab\xe7\x84\xb0.tex"), 1920.15, 1067.17),
                    (tex_images.get("materials/刘海1png.tex") or tex_images.get("materials/\xe5\x88\x98\xe6\xb5\xb71png.tex"), 1443.69, 1430.70),
                    (tex_images.get("materials/刀.tex") or tex_images.get("materials/\xe5\x88\x80.tex"), 1370.95, 1077.25),
                    (tex_images.get("materials/犄角.tex") or tex_images.get("materials/\xe7\x8a\x84\xe8\xa7\x92.tex"), 1390.57, 1759.41),
                    (tex_images.get("materials/右侧裙摆.tex") or tex_images.get("materials/\xe5\x8f\xb3\xe4\xbe\xa7\xe8\xa3\x99\xe6\x91\x86.tex"), 2721.95, 164.90),
                    (tex_images.get("materials/右侧头发.tex") or tex_images.get("materials/\xe5\x8f\xb3\xe4\xbe\xa7\xe5\xa4\xb4\xe5\x8f\x91.tex"), 2814.97, 706.96),
                ]
                for im, ox, oy in sublayers:
                    if im:
                        im = im.convert("RGBA")
                        dx = int(round(ox - W / 2.0))
                        dy = int(round(-(oy - H / 2.0)))
                        layer_im = Image.new("RGBA", (W, H), (0, 0, 0, 0))
                        layer_im.paste(im, (dx, dy))
                        canvas.alpha_composite(layer_im)
                out_path = os.path.join(EXTRACTED_DIR, f"{clean_title}.jpg")
                canvas.convert("RGB").save(out_path, quality=95)
                return out_path
        except Exception as e:
            print(f"Error handling 3284855031: {e}")

    if item_id == "3420277613":
        vid_path = os.path.join(EXTRACTED_DIR, f"{clean_title}.mp4")
        if os.path.exists(vid_path) and os.path.getsize(vid_path) > 1000000:
            return vid_path
        try:
            back_data = entries.get("materials/Back.tex")
            main_data = entries.get("materials/Main.tex")
            g_data = entries.get("materials/Glitch4cut.tex")
            s_data = entries.get("materials/SwitchGlitch4cut.tex")
            if back_data and main_data and g_data and s_data:
                idx_png = back_data.find(b"\x89PNG\r\n\x1a\n")
                back = Image.open(io.BytesIO(back_data[idx_png:])).convert("RGBA")
                main_img = decompress_texb0004(main_data).convert("RGBA")
                g_tex = decompress_texb0004(g_data)
                s_tex = decompress_texb0004(s_data)
                coords = [
                    (0, 0), (2700, 0), (5400, 0),
                    (0, 2160), (2700, 2160), (5400, 2160),
                    (0, 4320), (2700, 4320)
                ]
                base_frames = []
                for cx, cy in coords:
                    frame = back.copy()
                    frame.paste(main_img, (1597, 0), main_img)
                    g_frame = g_tex.crop((cx, cy, cx + 2700, cy + 2160))
                    frame.paste(g_frame, (1146, 0), g_frame)
                    s_frame = s_tex.crop((cx, cy, cx + 2700, cy + 2160)).copy()
                    r, g, b, a = s_frame.split()
                    a = a.point(lambda p: int(p * 0.35))
                    s_frame.putalpha(a)
                    s_full = Image.new("RGBA", back.size, (0, 0, 0, 0))
                    s_full.paste(s_frame, (1146, 0), s_frame)
                    frame.alpha_composite(s_full)
                    base_frames.append(frame.resize((2560, 1440), Image.Resampling.LANCZOS).convert("RGB"))
                
                fps = 60
                ticks = 6
                loops = 6
                cmd = [
                    "ffmpeg", "-y", "-f", "rawvideo", "-vcodec", "rawvideo",
                    "-s", "2560x1440", "-pix_fmt", "rgb24", "-r", str(fps), "-i", "-",
                    "-vf", "drawgrid=w=0:h=4:t=1:c=black@0.08,noise=alls=3:allf=t+u",
                    "-c:v", "libx264", "-preset", "medium", "-crf", "18", "-pix_fmt", "yuv420p",
                    vid_path
                ]
                proc = subprocess.Popen(cmd, stdin=subprocess.PIPE, stderr=subprocess.DEVNULL)
                for f_idx in range(loops * 8 * ticks):
                    st = (f_idx // ticks) % 8
                    proc.stdin.write(base_frames[st].tobytes())
                proc.stdin.close()
                proc.wait()
                return vid_path
        except Exception as e:
            print(f"Error handling 3420277613 video: {e}")

    if item_id == "3123189054":
        vid_path = os.path.join(EXTRACTED_DIR, f"{clean_title}.mp4")
        if os.path.exists(vid_path) and os.path.getsize(vid_path) > 500000:
            return vid_path

    if item_id in ["3115228486", "2922403527"]:
        try:
            fade_img = None
            car_img = None
            for name, data in entries.items():
                for sig in [b"\x89PNG\r\n\x1a\n", b"\xff\xd8\xff"]:
                    idx = data.find(sig)
                    if idx != -1:
                        im = Image.open(io.BytesIO(data[idx:]))
                        if im.width >= 3840 and "fade" in name.lower():
                            fade_img = im
                        elif "gt3" in name.lower() or "iris" in name.lower() or "touchup" in name.lower():
                            car_img = im
            if fade_img and car_img:
                fade = fade_img.convert("RGBA")
                car = car_img.convert("RGBA")
                fade.paste(car, (0, fade.height - car.height), car)
                out_path = os.path.join(EXTRACTED_DIR, f"{clean_title}.jpg")
                fade.convert("RGB").save(out_path, quality=95)
                return out_path
        except Exception as e:
            print(f"Error handling Porsche {item_id}: {e}")

    if item_id == "2083162856":
        try:
            layer_order = [
                "materials/background3.tex", "materials/background2.tex",
                "materials/roslinyprawo.tex", "materials/roslinylewo.tex",
                "materials/kwiatek.tex", "materials/kwiatek2.tex",
                "materials/potworek.tex", "materials/reka.tex",
                "materials/nogi2.tex", "materials/fale.tex", "materials/glowa.tex"
            ]
            canvas = Image.new("RGBA", (3840, 2160), (0, 0, 0, 255))
            for l_name in layer_order:
                data = entries.get(l_name)
                if data:
                    idx = data.find(b"\x89PNG\r\n\x1a\n")
                    if idx != -1:
                        lim = Image.open(io.BytesIO(data[idx:])).convert("RGBA")
                        canvas.alpha_composite(lim)
            out_path = os.path.join(EXTRACTED_DIR, f"{clean_title}.png")
            canvas.save(out_path)
            return out_path
        except Exception as e:
            print(f"Error handling Hollow Knight: {e}")

    # Blue star item 2343398376
    if item_id == "2343398376":
        for name, data in entries.items():
            if "ElVVTr8U0AAq8Jj" in name and name.endswith(".tex"):
                idx = data.find(b"\x89PNG\r\n\x1a\n")
                if idx != -1:
                    out_path = os.path.join(EXTRACTED_DIR, f"{clean_title}.png")
                    with open(out_path, "wb") as bf:
                        bf.write(data[idx:])
                    return out_path

    best_img = None
    best_score = -1
    best_ext = "jpg"

    for name, data in entries.items():
        if not name.endswith(".tex") or len(data) < 100000:
            continue
        if "mask" in name.lower() or "particle" in name.lower():
            continue

        for sig, ext in [(b"\x89PNG\r\n\x1a\n", "png"), (b"\xff\xd8\xff", "jpg")]:
            idx = data.find(sig)
            if idx != -1:
                try:
                    im = Image.open(io.BytesIO(data[idx:]))
                    w, h = im.size
                    if w >= 1920 and h >= 1080:
                        score = w * h
                        if im.mode in ("RGBA", "LA") or ("transparency" in im.info):
                            alpha = im.convert("RGBA").split()[-1]
                            non_zero = sum(1 for p in alpha.getdata() if p > 30)
                            ratio = non_zero / (w * h)
                            if ratio < 0.20:
                                continue
                            score = int(score * ratio)

                        if score > best_score:
                            best_score = score
                            best_img = im
                            best_ext = ext
                except Exception:
                    pass

    if best_img:
        out_path = os.path.join(EXTRACTED_DIR, f"{clean_title}.{best_ext}")
        if best_ext == "png":
            best_img.save(out_path)
        else:
            best_img.convert("RGB").save(out_path, quality=95)
        return out_path

    return None

def find_best_image_in_folder(folder_path):
    best_file = None
    best_pixels = 0
    for root, dirs, files in os.walk(folder_path):
        for fn in files:
            ext = os.path.splitext(fn)[1].lower()
            if ext in [".jpg", ".jpeg", ".png", ".webp"] and "preview" not in fn.lower():
                full_p = os.path.join(root, fn)
                try:
                    with Image.open(full_p) as img:
                        w, h = img.size
                        if w >= 1920 and h >= 1080:
                            if w * h > best_pixels:
                                best_pixels = w * h
                                best_file = full_p
                except Exception:
                    pass
    return best_file

def safe_symlink(src, dst):
    if os.path.islink(dst):
        if os.readlink(dst) == src and os.path.exists(dst):
            return
        try: os.unlink(dst)
        except Exception: pass
    elif os.path.exists(dst):
        try: os.remove(dst)
        except Exception: pass
    try:
        os.symlink(src, dst)
    except Exception as e:
        print(f"Error linking {src} -> {dst}: {e}")

def sync():
    if not os.path.isdir(WORKSHOP_DIR):
        print(f"Workshop directory not found: {WORKSHOP_DIR}")
        return

    for folder in [WE_DIR, EXTRACTED_DIR]:
        for fn in os.listdir(folder):
            if "[Live].mp4" in fn or "black and white - clean" in fn.lower() or "hes fast" in fn.lower() or fn == "Hatsune Miku _ GLITCHED HOLOGRAM.jpg":
                try:
                    p = os.path.join(folder, fn)
                    if os.path.islink(p): os.unlink(p)
                    else: os.remove(p)
                except Exception: pass

    seen_names = {}
    valid_links = set()
    count = 0

    workshop_items = sorted(os.listdir(WORKSHOP_DIR))
    for item_id in workshop_items:
        item_path = os.path.join(WORKSHOP_DIR, item_id)
        if not os.path.isdir(item_path):
            continue

        if is_preset_item(item_path):
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

        if item_id in ["1348279970"] or "hes fast" in title.lower():
            continue

        clean_title = sanitize_filename(title)
        if clean_title in seen_names:
            clean_title = f"{clean_title} ({item_id})"
        seen_names[clean_title] = item_id

        videos = (glob.glob(os.path.join(item_path, "*.mp4")) +
                  glob.glob(os.path.join(item_path, "*.webm")) +
                  glob.glob(os.path.join(item_path, "*.mkv")))
        if videos:
            vpath = videos[0]
            ext = os.path.splitext(vpath)[1]
            dest = os.path.join(WE_DIR, f"{clean_title}{ext}")
            safe_symlink(vpath, dest)
            generate_thumbnail(dest)
            valid_links.add(os.path.basename(dest))
            count += 1
            continue

        pkg_path = os.path.join(item_path, "scene.pkg")
        final_source = None

        # Prefer MP4 if exists
        for cand_ext in [".mp4", ".png", ".jpg", ".jpeg"]:
            cand = os.path.join(EXTRACTED_DIR, f"{clean_title}{cand_ext}")
            if os.path.exists(cand) and os.path.getsize(cand) > 100000:
                if cand_ext == ".mp4":
                    final_source = cand
                    break
                try:
                    with Image.open(cand) as im:
                        if im.size[0] >= 1920 and im.size[1] >= 1080:
                            final_source = cand
                            break
                except Exception:
                    pass

        if not final_source and os.path.exists(pkg_path):
            final_source = extract_intelligent_scene(pkg_path, item_id, clean_title)

        if not final_source:
            loose_img = find_best_image_in_folder(item_path)
            if loose_img:
                final_source = loose_img

        if final_source and os.path.exists(final_source):
            ext = os.path.splitext(final_source)[1]
            link_path = os.path.join(WE_DIR, f"{clean_title}{ext}")
            safe_symlink(final_source, link_path)
            generate_thumbnail(link_path)
            valid_links.add(os.path.basename(link_path))
            count += 1

    for existing_vid in [
        "Hello world by Ashima _ 4K Parallax.mp4",
        "Steam Winter Sale 2023 - Winter City (Media Integration, Pixel Art, Dynamic).mp4",
        "Miku Monitoring.mp4",
        "Hatsune Miku _ GLITCHED HOLOGRAM.mp4"
    ]:
        src = os.path.join(EXTRACTED_DIR, existing_vid)
        if os.path.exists(src):
            dst = os.path.join(WE_DIR, existing_vid)
            safe_symlink(src, dst)
            generate_thumbnail(dst)
            valid_links.add(existing_vid)
            count += 1

    for existing in os.listdir(WE_DIR):
        full_p = os.path.join(WE_DIR, existing)
        if os.path.islink(full_p):
            if existing not in valid_links or not os.path.exists(full_p):
                try: os.unlink(full_p)
                except Exception: pass
            else:
                generate_thumbnail(full_p)

    print(f"Synced {count} strictly high-resolution wallpapers into {WE_DIR}")

if __name__ == "__main__":
    sync()

#!/usr/bin/env -S\_/bin/sh\_-c\_"source\_\$(eval\_echo\_\$ILLOGICAL_IMPULSE_VIRTUAL_ENV)/bin/activate&&exec\_python\_-E\_"\$0"\_"\$@""
import argparse
import math
import json
import os
import hashlib
import warnings
warnings.filterwarnings("ignore")
from PIL import Image
from materialyoucolor.quantize import QuantizeCelebi
from materialyoucolor.score.score import Score
from materialyoucolor.hct import Hct
from materialyoucolor.dynamiccolor.material_dynamic_colors import MaterialDynamicColors
from materialyoucolor.utils.color_utils import (rgba_from_argb, argb_from_rgb, argb_from_rgba)
from materialyoucolor.utils.math_utils import (sanitize_degrees_double, difference_degrees, rotation_direction)

CURATED_DARK_ACCENTS = [
    Hct.from_hct(195.0, 75.0, 60.0),  # Electric Cyan
    Hct.from_hct(280.0, 75.0, 62.0),  # Neon Violet
    Hct.from_hct(340.0, 78.0, 62.0),  # Sunset Rose
    Hct.from_hct(45.0, 80.0, 65.0),   # Radiant Amber / Gold
    Hct.from_hct(225.0, 75.0, 62.0),  # Vivid Azure / Neon Blue
    Hct.from_hct(155.0, 75.0, 60.0),  # Electric Emerald
    Hct.from_hct(315.0, 75.0, 62.0),  # Neon Magenta
    Hct.from_hct(18.0, 80.0, 60.0),   # Crimson Flame
]

parser = argparse.ArgumentParser(description='Color generation script')
parser.add_argument('--path', type=str, default=None, help='generate colorscheme from image')
parser.add_argument('--size', type=int , default=128 , help='bitmap image size')
parser.add_argument('--color', type=str, default=None, help='generate colorscheme from color')
parser.add_argument('--mode', type=str, choices=['dark', 'light'], default='dark', help='dark or light mode')
parser.add_argument('--scheme', type=str, default='vibrant', help='material scheme to use')
parser.add_argument('--smart', action='store_true', default=False, help='decide scheme type based on image color')
parser.add_argument('--transparency', type=str, choices=['opaque', 'transparent'], default='opaque', help='enable transparency')
parser.add_argument('--termscheme', type=str, default=None, help='JSON file containg the terminal scheme for generating term colors')
parser.add_argument('--harmony', type=float , default=0.8, help='(0-1) Color hue shift towards accent')
parser.add_argument('--harmonize_threshold', type=float , default=100, help='(0-180) Max threshold angle to limit color hue shift')
parser.add_argument('--term_fg_boost', type=float , default=0.35, help='Make terminal foreground more different from the background')
parser.add_argument('--blend_bg_fg', action='store_true', default=False, help='Shift terminal background or foreground towards accent')
parser.add_argument('--cache', type=str, default=None, help='file path to store the generated color')
parser.add_argument('--json', type=str, default=None, help='file path to write generated colors as JSON')
parser.add_argument('--debug', action='store_true', default=False, help='debug mode')
args = parser.parse_args()

rgba_to_hex = lambda rgba: "#{:02X}{:02X}{:02X}".format(rgba[0], rgba[1], rgba[2])
argb_to_hex = lambda argb: "#{:02X}{:02X}{:02X}".format(*map(round, rgba_from_argb(argb)))
hex_to_argb = lambda hex_code: argb_from_rgb(int(hex_code[1:3], 16), int(hex_code[3:5], 16), int(hex_code[5:], 16))
display_color = lambda rgba : "\x1B[38;2;{};{};{}m{}\x1B[0m".format(rgba[0], rgba[1], rgba[2], "\x1b[7m   \x1b[7m")

def calculate_optimal_size (width: int, height: int, bitmap_size: int) -> (int, int):
    image_area = width * height;
    bitmap_area = bitmap_size ** 2
    scale = math.sqrt(bitmap_area/image_area) if image_area > bitmap_area else 1
    new_width = round(width * scale)
    new_height = round(height * scale)
    if new_width == 0:
        new_width = 1
    if new_height == 0:
        new_height = 1
    return new_width, new_height

def harmonize (design_color: int, source_color: int, threshold: float = 35, harmony: float = 0.5) -> int:
    from_hct = Hct.from_int(design_color)
    to_hct = Hct.from_int(source_color)
    difference_degrees_ = difference_degrees(from_hct.hue, to_hct.hue)
    rotation_degrees = min(difference_degrees_ * harmony, threshold)
    output_hue = sanitize_degrees_double(
        from_hct.hue + rotation_degrees * rotation_direction(from_hct.hue, to_hct.hue)
    )
    return Hct.from_hct(output_hue, from_hct.chroma, from_hct.tone).to_int()

def boost_chroma_tone (argb: int, chroma: float = 1, tone: float = 1) -> int:
    hct = Hct.from_int(argb)
    return Hct.from_hct(hct.hue, hct.chroma * chroma, hct.tone * tone).to_int()

darkmode = (args.mode == 'dark')
transparent = (args.transparency == 'transparent')

if args.path is not None:
    image = Image.open(args.path)

    if image.format == "GIF":
        image.seek(1)

    if image.mode in ["L", "P"]:
        image = image.convert('RGB')
    wsize, hsize = image.size
    wsize_new, hsize_new = calculate_optimal_size(wsize, hsize, args.size)
    if wsize_new < wsize or hsize_new < hsize:
        image = image.resize((wsize_new, hsize_new), Image.Resampling.BICUBIC)
    raw_pixels = list(image.getdata()) if hasattr(image, "getdata") else []
    colors = QuantizeCelebi(raw_pixels, 128)

    # Average brightness of the image
    avg_lum = sum(0.299 * p[0] + 0.587 * p[1] + 0.114 * p[2] for p in raw_pixels) / len(raw_pixels) if raw_pixels else 50.0

    # Search for salient accent colors in the image (even small details like glowing eyes, neon, flame, lights)
    accent_candidates = []
    for c, pop in colors.items():
        h = Hct.from_int(c)
        if h.chroma >= 8.0 and 8.0 <= h.tone <= 92.0:
            accent_candidates.append((h, pop))

    max_chroma = max([h.chroma for h, _ in accent_candidates], default=0.0)
    is_dark_or_monochrome = (avg_lum < 45.0 and max_chroma < 28.0) or (max_chroma < 22.0)

    scored_argb = Score.score(colors)[0]
    scored_hct = Hct.from_int(scored_argb)
    score_ignored_accents = (scored_argb == 0xff4285f4 and max_chroma >= 10.0)

    if is_dark_or_monochrome or score_ignored_accents or (avg_lum < 45.0 and scored_hct.chroma < 20.0):
        if accent_candidates:
            # Sort candidates by chroma and population to pick the most striking accent
            accent_candidates.sort(key=lambda x: x[0].chroma * math.log(x[1] + 1.5), reverse=True)
            chosen_hct = accent_candidates[0][0]
            # Boost chroma so subtle accents flourish into vibrant themes
            boosted_chroma = max(chosen_hct.chroma * 1.6, 65.0)
            hct = Hct.from_hct(chosen_hct.hue, min(boosted_chroma, 90.0), max(52.0, min(chosen_hct.tone, 68.0)))
            argb = hct.to_int()
        else:
            # Pure monochrome / black & white: pick a deterministic vibrant accent from curated list
            h_idx = int(hashlib.md5(os.path.basename(args.path).encode('utf-8')).hexdigest(), 16) % len(CURATED_DARK_ACCENTS)
            hct = CURATED_DARK_ACCENTS[h_idx]
            argb = hct.to_int()
        
        # When wallpaper is dark/monochrome, use SchemeFidelity for rich, multi-colored primary, secondary, and tertiary
        if args.scheme in ['scheme-tonal-spot', 'scheme-neutral', 'auto', 'tonal-spot', 'vibrant']:
            args.scheme = 'scheme-fidelity'
    else:
        argb = scored_argb
        hct = scored_hct
        if(args.smart):
            if(hct.chroma < 20):
                args.scheme = 'neutral'

    if args.cache is not None:
        with open(args.cache, 'w') as file:
            file.write(argb_to_hex(argb))
elif args.color is not None:
    argb = hex_to_argb(args.color)
    hct = Hct.from_int(argb)

if args.scheme == 'scheme-fruit-salad':
    from materialyoucolor.scheme.scheme_fruit_salad import SchemeFruitSalad as Scheme
elif args.scheme == 'scheme-expressive':
    from materialyoucolor.scheme.scheme_expressive import SchemeExpressive as Scheme
elif args.scheme == 'scheme-monochrome':
    from materialyoucolor.scheme.scheme_monochrome import SchemeMonochrome as Scheme
elif args.scheme == 'scheme-rainbow':
    from materialyoucolor.scheme.scheme_rainbow import SchemeRainbow as Scheme
elif args.scheme == 'scheme-tonal-spot':
    from materialyoucolor.scheme.scheme_tonal_spot import SchemeTonalSpot as Scheme
elif args.scheme == 'scheme-neutral':
    from materialyoucolor.scheme.scheme_neutral import SchemeNeutral as Scheme
elif args.scheme == 'scheme-fidelity':
    from materialyoucolor.scheme.scheme_fidelity import SchemeFidelity as Scheme
elif args.scheme == 'scheme-content':
    from materialyoucolor.scheme.scheme_content import SchemeContent as Scheme
elif args.scheme == 'scheme-vibrant':
    from materialyoucolor.scheme.scheme_vibrant import SchemeVibrant as Scheme
else:
    from materialyoucolor.scheme.scheme_tonal_spot import SchemeTonalSpot as Scheme
# Generate
scheme = Scheme(hct, darkmode, 0.0)

material_colors = {}
term_colors = {}

for color in vars(MaterialDynamicColors).keys():
    color_name = getattr(MaterialDynamicColors, color)
    if hasattr(color_name, "get_hct"):
        rgba = color_name.get_hct(scheme).to_rgba()
        material_colors[color] = rgba_to_hex(rgba)

# Extended material
if darkmode == True:
    material_colors['success'] = '#B5CCBA'
    material_colors['onSuccess'] = '#213528'
    material_colors['successContainer'] = '#374B3E'
    material_colors['onSuccessContainer'] = '#D1E9D6'
else:
    material_colors['success'] = '#4F6354'
    material_colors['onSuccess'] = '#FFFFFF'
    material_colors['successContainer'] = '#D1E8D5'
    material_colors['onSuccessContainer'] = '#0C1F13'

# Terminal Colors
if args.termscheme is not None:
    with open(args.termscheme, 'r') as f:
        json_termscheme = f.read()
    term_source_colors = json.loads(json_termscheme)['dark' if darkmode else 'light']

    primary_key = 'primary_paletteKeyColor' if 'primary_paletteKeyColor' in material_colors else ('primaryPaletteKeyColor' if 'primaryPaletteKeyColor' in material_colors else 'primary')
    primary_color_argb = hex_to_argb(material_colors[primary_key])
    for color, val in term_source_colors.items():
        if(args.scheme == 'monochrome') :
            term_colors[color] = val
            continue
        if args.blend_bg_fg and color == "term0":
            harmonized = boost_chroma_tone(hex_to_argb(material_colors['surfaceContainerLow']), 1.2, 0.95)
        elif args.blend_bg_fg and color == "term15":
            harmonized = boost_chroma_tone(hex_to_argb(material_colors['onSurface']), 3, 1)
        else:
            harmonized = harmonize(hex_to_argb(val), primary_color_argb, args.harmonize_threshold, args.harmony)
            harmonized = boost_chroma_tone(harmonized, 1, 1 + (args.term_fg_boost * (1 if darkmode else -1)))
        term_colors[color] = argb_to_hex(harmonized)

if args.debug == False:
    print(f"$darkmode: {darkmode};")
    print(f"$transparent: {transparent};")
    for color, code in material_colors.items():
        print(f"${color}: {code};")
    for color, code in term_colors.items():
        print(f"${color}: {code};")

if args.json is not None:
    try:
        with open(args.json, 'w') as jf:
            json.dump(material_colors, jf, indent=2)
    except Exception as e:
        if args.debug:
            print(f"Error writing JSON: {e}")

try:
    hypr_scheme_path = os.path.expanduser("~/.config/hypr/scheme/current.lua")
    if os.path.exists(os.path.dirname(hypr_scheme_path)):
        lua_lines = ["return {"]
        for k, v in material_colors.items():
            hex_clean = v.lstrip("#").lower()
            lua_lines.append(f'  {k} = "{hex_clean}",')
        lua_lines.append("}\n")
        with open(hypr_scheme_path, "w") as f:
            f.write("\n".join(lua_lines))

    for gtk_ver in ["gtk-3.0", "gtk-4.0"]:
        gtk_dir = os.path.expanduser(f"~/.config/{gtk_ver}")
        if os.path.exists(gtk_dir):
            pri = material_colors.get("primary", "#c0cc95")
            on_pri = material_colors.get("onPrimary", "#3a441a")
            bg = material_colors.get("background", "#0e0f09")
            fg = material_colors.get("onBackground", "#e6e7d5")
            css = f"""@define-color accent_color {pri};
@define-color accent_fg_color {on_pri};
@define-color accent_bg_color {pri};
@define-color window_bg_color {bg};
@define-color window_fg_color {fg};
@define-color headerbar_bg_color {bg};
@define-color headerbar_fg_color {fg};
@define-color popover_bg_color {bg};
@define-color popover_fg_color {fg};
@define-color view_bg_color {bg};
@define-color view_fg_color {fg};
@define-color card_bg_color {bg};
@define-color card_fg_color {fg};
@define-color sidebar_bg_color @window_bg_color;
@define-color sidebar_fg_color @window_fg_color;
@define-color sidebar_border_color @window_bg_color;
@define-color sidebar_backdrop_color @window_bg_color;
@define-color theme_selected_bg_color alpha(@accent_color, 0.15);
@define-color theme_selected_fg_color @accent_color;
"""
            with open(os.path.join(gtk_dir, "gtk.css"), "w") as f:
                f.write(css)
except Exception as e:
    if args.debug:
        print(f"Error updating external themes: {e}")
else:
    if args.path is not None:
        print('\n--------------Image properties-----------------')
        print(f"Image size: {wsize} x {hsize}")
        print(f"Resized image: {wsize_new} x {hsize_new}")
    print('\n---------------Selected color------------------')
    print(f"Dark mode: {darkmode}")
    print(f"Scheme: {args.scheme}")
    print(f"Accent color: {display_color(rgba_from_argb(argb))} {argb_to_hex(argb)}")
    print(f"HCT: {hct.hue:.2f}  {hct.chroma:.2f}  {hct.tone:.2f}")
    print('\n---------------Material colors-----------------')
    for color, code in material_colors.items():
        rgba = rgba_from_argb(hex_to_argb(code))
        print(f"{color.ljust(32)} : {display_color(rgba)}  {code}")
    print('\n----------Harmonize terminal colors------------')
    for color, code in term_colors.items():
        rgba = rgba_from_argb(hex_to_argb(code))
        code_source = term_source_colors[color]
        rgba_source = rgba_from_argb(hex_to_argb(code_source))
        print(f"{color.ljust(6)} : {display_color(rgba_source)} {code_source} --> {display_color(rgba)} {code}")
    print('-----------------------------------------------')

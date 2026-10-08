#!/usr/bin/env bash

export PATH="$HOME/.local/bin:$PATH"

QUICKSHELL_CONFIG_NAME="ii"
XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"
XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"
CONFIG_DIR="$XDG_CONFIG_HOME/quickshell/$QUICKSHELL_CONFIG_NAME"
CACHE_DIR="$XDG_CACHE_HOME/quickshell"
STATE_DIR="$XDG_STATE_HOME/quickshell"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SHELL_CONFIG_FILE="$XDG_CONFIG_HOME/illogical-impulse/config.json"
MATUGEN_DIR="$XDG_CONFIG_HOME/matugen"
terminalscheme="$SCRIPT_DIR/terminal/scheme-base.json"

handle_kde_material_you_colors() {
    if [ -f "$SHELL_CONFIG_FILE" ]; then
        enable_qt_apps=$(jq -r '.appearance.wallpaperTheming.enableQtApps' "$SHELL_CONFIG_FILE")
        if [ "$enable_qt_apps" == "false" ]; then
            return
        fi
    fi

    local kde_scheme_variant=""
    case "$type_flag" in
        scheme-content|scheme-expressive|scheme-fidelity|scheme-fruit-salad|scheme-monochrome|scheme-neutral|scheme-rainbow|scheme-tonal-spot)
            kde_scheme_variant="$type_flag"
            ;;
        *)
            kde_scheme_variant="scheme-tonal-spot"
            ;;
    esac
    "$XDG_CONFIG_HOME"/matugen/templates/kde/kde-material-you-colors-wrapper.sh --scheme-variant "$kde_scheme_variant"
}

pre_process() {
    local mode_flag="$1"
    if [[ "$mode_flag" == "dark" ]]; then
        gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'
        gsettings set org.gnome.desktop.interface gtk-theme 'adw-gtk3-dark'
    elif [[ "$mode_flag" == "light" ]]; then
        gsettings set org.gnome.desktop.interface color-scheme 'prefer-light'
        gsettings set org.gnome.desktop.interface gtk-theme 'adw-gtk3'
    fi

    if [ ! -d "$CACHE_DIR"/user/generated ]; then
        mkdir -p "$CACHE_DIR"/user/generated
    fi
}

post_process() {
    local screen_width="$1"
    local screen_height="$2"
    local wallpaper_path="$3"
    local colors_lock_flag="$4"

    if [[ -n "$colors_lock_flag" ]]; then
        return
    fi

    handle_kde_material_you_colors &
    "$SCRIPT_DIR/code/material-code-set-color.sh" &
}

UPSCALE_CACHE_DIR="$CACHE_DIR/user/upscaled_wallpapers"
mkdir -p "$UPSCALE_CACHE_DIR" 2>/dev/null

# Returns the (possibly upscaled) path for the wallpaper.
# If the image is smaller than the monitor, upscales it with ImageMagick and caches the result.
# Sets global $imgpath to the new path if upscaling was done.
auto_upscale_if_needed() {
    local img="$1"
    min_width_desired="$(hyprctl monitors -j | jq '([.[].width] | max)' | xargs)"
    min_height_desired="$(hyprctl monitors -j | jq '([.[].height] | max)' | xargs)"

    if ! command -v magick &>/dev/null && ! command -v convert &>/dev/null; then
        return
    fi
    if is_video "$img" || [ ! -f "$img" ]; then
        return
    fi

    local img_width img_height
    if command -v identify &>/dev/null; then
        img_width=$(identify -format "%w" "$img" 2>/dev/null | head -1)
        img_height=$(identify -format "%h" "$img" 2>/dev/null | head -1)
    else
        img_width=$(magick identify -format "%w" "$img" 2>/dev/null | head -1)
        img_height=$(magick identify -format "%h" "$img" 2>/dev/null | head -1)
    fi

    if [[ -z "$img_width" || -z "$img_height" ]]; then
        return
    fi

    if [[ "$img_width" -lt "$min_width_desired" || "$img_height" -lt "$min_height_desired" ]]; then
        local ext="${img##*.}"
        local basename_noext="$(basename "$img" ".$ext")"
        local upscaled="$UPSCALE_CACHE_DIR/${basename_noext}_${min_width_desired}x${min_height_desired}.png"

        if [ ! -f "$upscaled" ]; then
            notify-send "Wallpaper switcher" \
                "Апскейл ${img_width}x${img_height} → ${min_width_desired}x${min_height_desired}..." \
                -a "Wallpaper switcher" -t 4000

            if command -v magick &>/dev/null; then
                magick "$img" \
                    -filter Lanczos \
                    -resize "${min_width_desired}x${min_height_desired}^" \
                    -gravity Center -extent "${min_width_desired}x${min_height_desired}" \
                    -quality 95 \
                    "$upscaled" 2>/dev/null
            else
                convert "$img" \
                    -filter Lanczos \
                    -resize "${min_width_desired}x${min_height_desired}^" \
                    -gravity Center -extent "${min_width_desired}x${min_height_desired}" \
                    -quality 95 \
                    "$upscaled" 2>/dev/null
            fi
        fi

        if [ -f "$upscaled" ]; then
            notify-send "Wallpaper switcher" \
                "Готово! Апскейл ${img_width}x${img_height} → ${min_width_desired}x${min_height_desired}" \
                -a "Wallpaper switcher" -t 3000
            imgpath="$upscaled"
        fi
    fi
}

CUSTOM_DIR="$XDG_CONFIG_HOME/hypr/custom"
RESTORE_SCRIPT_DIR="$CUSTOM_DIR/scripts"
RESTORE_SCRIPT="$RESTORE_SCRIPT_DIR/__restore_video_wallpaper.sh"
THUMBNAIL_DIR="$RESTORE_SCRIPT_DIR/mpvpaper_thumbnails"
mkdir -p "$RESTORE_SCRIPT_DIR" "$THUMBNAIL_DIR" 2>/dev/null
VIDEO_OPTS="no-audio loop hwdec=auto scale=spline36 interpolation=no panscan=1.0 video-scale-x=1.0 video-scale-y=1.0 video-align-x=0.5 video-align-y=0.5 load-scripts=no"

is_video() {
    local extension="${1##*.}"
    [[ "$extension" == "mp4" || "$extension" == "webm" || "$extension" == "mkv" || "$extension" == "avi" || "$extension" == "mov" ]] && return 0 || return 1
}

kill_existing_mpvpaper() {
    pkill -x mpvpaper || true
}

create_restore_script() {
    local video_path=$1
    cat > "$RESTORE_SCRIPT.tmp" << EOF
#!/bin/bash
# Generated by switchwall.sh - Don't modify it by yourself.
# Time: $(date)

export PATH="\$HOME/.local/bin:\$PATH"
pkill -x mpvpaper || true

for monitor in \$(hyprctl monitors -j | jq -r '.[] | .name'); do
    mpvpaper --fork -o "$VIDEO_OPTS" "\$monitor" "$video_path"
    sleep 0.1
done
EOF
    mv "$RESTORE_SCRIPT.tmp" "$RESTORE_SCRIPT"
    chmod +x "$RESTORE_SCRIPT"
}

remove_restore() {
    cat > "$RESTORE_SCRIPT.tmp" << EOF
#!/bin/bash
# The content of this script will be generated by switchwall.sh - Don't modify it by yourself.
EOF
    mv "$RESTORE_SCRIPT.tmp" "$RESTORE_SCRIPT"
}

set_wallpaper_path() {
    local path="$1"
    if [ -f "$SHELL_CONFIG_FILE" ]; then
        jq --arg path "$path" '.background.wallpaperPath = $path' "$SHELL_CONFIG_FILE" > "$SHELL_CONFIG_FILE.tmp" && mv "$SHELL_CONFIG_FILE.tmp" "$SHELL_CONFIG_FILE"
    fi
}

set_thumbnail_path() {
    local path="$1"
    if [ -f "$SHELL_CONFIG_FILE" ]; then
        jq --arg path "$path" '.background.thumbnailPath = $path' "$SHELL_CONFIG_FILE" > "$SHELL_CONFIG_FILE.tmp" && mv "$SHELL_CONFIG_FILE.tmp" "$SHELL_CONFIG_FILE"
    fi
}

categorize_wallpaper() {
    img_cat=$("$SCRIPT_DIR/../ai/gemini-categorize-wallpaper.sh" "$1")
    echo "$img_cat" > "$STATE_DIR/user/generated/wallpaper/category.txt"
}

switch() {
    imgpath="$1"
    mode_flag="$2"
    type_flag="$3"
    color_flag="$4"
    color="$5"
    colors_only_flag="$6"
    colors_lock_flag="$7"

    aiStylingEnabled=$(jq -r '.background.widgets.clock.cookie.aiStyling' "$SHELL_CONFIG_FILE")
    if [[ "$aiStylingEnabled" == "true" && -z "$colors_only_flag" ]]; then
        categorize_wallpaper "$imgpath" &
    fi

    read scale screenx screeny screensizey < <(hyprctl monitors -j | jq '.[] | select(.focused) | .scale, .x, .y, .height' | xargs)
    cursorposx=$(hyprctl cursorpos -j | jq '.x' 2>/dev/null) || cursorposx=960
    if command -v bc >/dev/null 2>&1; then
        cursorposx=$(bc <<< "scale=0; ($cursorposx - $screenx) * $scale / 1")
    else
        cursorposx=$(awk "BEGIN { printf \"%d\", ($cursorposx - $screenx) * $scale }")
    fi
    cursorposy=$(hyprctl cursorpos -j | jq '.y' 2>/dev/null) || cursorposy=540
    if command -v bc >/dev/null 2>&1; then
        cursorposy=$(bc <<< "scale=0; ($cursorposy - $screeny) * $scale / 1")
    else
        cursorposy=$(awk "BEGIN { printf \"%d\", ($cursorposy - $screeny) * $scale }")
    fi
    cursorposy_inverted=$((screensizey - cursorposy))

    matugen_args=(--source-color-index 0)

    if [[ "$color_flag" == "1" ]]; then
        matugen_args+=(color hex "$color")
        generate_colors_material_args=(--color "$color")
    else
        if [[ -z "$imgpath" ]]; then
            echo 'Aborted'
            exit 0
        fi

        auto_upscale_if_needed "$imgpath"

        if [[ -z "$colors_only_flag" ]]; then
            kill_existing_mpvpaper
        fi

        if is_video "$imgpath"; then
            mkdir -p "$THUMBNAIL_DIR"

            missing_deps=()
            if ! command -v mpvpaper &> /dev/null; then
                missing_deps+=("mpvpaper")
            fi
            if ! command -v ffmpeg &> /dev/null; then
                missing_deps+=("ffmpeg")
            fi
            if [ ${#missing_deps[@]} -gt 0 ]; then
                echo "Missing deps: ${missing_deps[*]}"
                echo "Arch: sudo pacman -S ${missing_deps[*]}"
                action=$(notify-send \
                    -a "Wallpaper switcher" \
                    -c "im.error" \
                    -A "install_arch=Install (Arch)" \
                    "Can't switch to video wallpaper" \
                    "Missing dependencies: ${missing_deps[*]}")
                if [[ "$action" == "install_arch" ]]; then
                    kitty -1 sudo pacman -S "${missing_deps[*]}"
                    if command -v mpvpaper &>/dev/null && command -v ffmpeg &>/dev/null; then
                        notify-send 'Wallpaper switcher' 'Alright, try again!' -a "Wallpaper switcher"
                    fi
                fi
                exit 0
            fi

            if [[ -z "$colors_only_flag" ]]; then
                set_wallpaper_path "$imgpath"

                local video_path="$imgpath"
                monitors=$(hyprctl monitors -j | jq -r '.[] | .name')
                for monitor in $monitors; do
                    mpvpaper --fork -o "$VIDEO_OPTS" "$monitor" "$video_path"
                    sleep 0.1
                done
            fi

            thumbnail="$THUMBNAIL_DIR/$(basename "$imgpath").jpg"
            ffmpeg -y -ss 00:00:01 -i "$imgpath" -vframes 1 -vf "scale=2560:1440:flags=lanczos,format=yuvj420p" -q:v 2 "$thumbnail" 2>/dev/null \
                || ffmpeg -y -i "$imgpath" -vframes 1 -vf "scale=2560:1440:flags=lanczos,format=yuvj420p" -q:v 2 "$thumbnail" 2>/dev/null

            if [[ -z "$colors_only_flag" ]]; then
                set_thumbnail_path "$thumbnail"
            fi

            if [ -f "$thumbnail" ]; then
                matugen_args+=(image "$thumbnail")
                generate_colors_material_args=(--path "$thumbnail")
                if [[ -z "$colors_only_flag" ]]; then
                    create_restore_script "$video_path"
                fi
            else
                echo "Cannot create image to colorgen"
                if [[ -z "$colors_only_flag" ]]; then
                    remove_restore
                fi
                exit 1
            fi
        else
            matugen_args+=(image "$imgpath")
            generate_colors_material_args=(--path "$imgpath")
            if [[ -z "$colors_only_flag" ]]; then
                set_wallpaper_path "$imgpath"
                remove_restore
            fi
        fi
    fi

    if [[ -z "$mode_flag" ]]; then
        current_mode=$(gsettings get org.gnome.desktop.interface color-scheme 2>/dev/null | tr -d "'")
        if [[ "$current_mode" == "prefer-dark" ]]; then
            mode_flag="dark"
        else
            mode_flag="light"
        fi
    fi

    if [[ -n "$mode_flag" ]]; then
        matugen_args+=(--mode "$mode_flag")
        if [[ $(jq -r '.appearance.wallpaperTheming.terminalGenerationProps.forceDarkMode' "$SHELL_CONFIG_FILE") == "true" ]]; then
            generate_colors_material_args+=(--mode "dark")
        else
            generate_colors_material_args+=(--mode "$mode_flag")
        fi
    fi
    [[ -n "$type_flag" ]] && matugen_args+=(--type "$type_flag") && generate_colors_material_args+=(--scheme "$type_flag")
    generate_colors_material_args+=(--termscheme "$terminalscheme" --blend_bg_fg)
    generate_colors_material_args+=(--cache "$STATE_DIR/user/generated/color.txt")

    pre_process "$mode_flag"

    if [ -f "$SHELL_CONFIG_FILE" ]; then
        enable_apps_shell=$(jq -r '.appearance.wallpaperTheming.enableAppsAndShell' "$SHELL_CONFIG_FILE")
        if [ "$enable_apps_shell" == "false" ]; then
            echo "App and shell theming disabled, skipping matugen and color generation"
            return
        fi
    fi

    if [ -f "$SHELL_CONFIG_FILE" ]; then
        harmony=$(jq -r '.appearance.wallpaperTheming.terminalGenerationProps.harmony' "$SHELL_CONFIG_FILE")
        harmonize_threshold=$(jq -r '.appearance.wallpaperTheming.terminalGenerationProps.harmonizeThreshold' "$SHELL_CONFIG_FILE")
        term_fg_boost=$(jq -r '.appearance.wallpaperTheming.terminalGenerationProps.termFgBoost' "$SHELL_CONFIG_FILE")
        [[ "$harmony" != "null" && -n "$harmony" ]] && generate_colors_material_args+=(--harmony "$harmony")
        [[ "$harmonize_threshold" != "null" && -n "$harmonize_threshold" ]] && generate_colors_material_args+=(--harmonize_threshold "$harmonize_threshold")
        [[ "$term_fg_boost" != "null" && -n "$term_fg_boost" ]] && generate_colors_material_args+=(--term_fg_boost "$term_fg_boost")
    fi

    colors_json_path="$STATE_DIR/user/generated/colors.json"
    colors_lock_json_path="$STATE_DIR/user/generated/colors-lock.json"
    colors_lock_watch_paths=(
        "$colors_json_path"
        "$XDG_CONFIG_HOME/gtk-3.0/gtk.css"
        "$XDG_CONFIG_HOME/gtk-4.0/gtk.css"
    )
    colors_lock_backups=()
    if [[ -n "$colors_lock_flag" ]]; then
        for i in "${!colors_lock_watch_paths[@]}"; do
            watch_path="${colors_lock_watch_paths[$i]}"
            if [[ -f "$watch_path" ]]; then
                backup_path="$(mktemp)"
                cp "$watch_path" "$backup_path"
                colors_lock_backups[$i]="$backup_path"
            fi
        done
    fi

    if command -v matugen >/dev/null 2>&1; then
        matugen "${matugen_args[@]}"
    fi

    if [[ -n "$colors_lock_flag" ]]; then
        if [[ -f "$colors_json_path" ]]; then
            cp "$colors_json_path" "$colors_lock_json_path"
        fi
        for i in "${!colors_lock_watch_paths[@]}"; do
            watch_path="${colors_lock_watch_paths[$i]}"
            backup_path="${colors_lock_backups[$i]:-}"
            if [[ -n "$backup_path" ]]; then
                mv "$backup_path" "$watch_path"
            fi
        done
    fi

    local venv_path="$(eval echo $ILLOGICAL_IMPULSE_VIRTUAL_ENV)"
    if [[ -n "$venv_path" && -f "$venv_path/bin/activate" ]]; then
        source "$venv_path/bin/activate"
    fi

    if [[ -n "$colors_lock_flag" ]]; then
        output_scss="$STATE_DIR/user/generated/material_colors_lock.scss"
        target_json="$colors_lock_json_path"
    else
        output_scss="$STATE_DIR/user/generated/material_colors.scss"
        target_json="$colors_json_path"
    fi

    generate_colors_material_args+=(--json "$target_json")

    python3 "$SCRIPT_DIR/generate_colors_material.py" "${generate_colors_material_args[@]}" \
        > "$output_scss"
    if type deactivate &>/dev/null; then
        deactivate
    fi

    if [[ -z "$colors_lock_flag" ]]; then
        "$SCRIPT_DIR"/applycolor.sh
    fi

    max_width_desired="$(hyprctl monitors -j | jq '([.[].width] | min)' | xargs)"
    max_height_desired="$(hyprctl monitors -j | jq '([.[].height] | min)' | xargs)"
    post_process "$max_width_desired" "$max_height_desired" "$imgpath" "$colors_lock_flag"
}

main() {
    imgpath=""
    mode_flag=""
    type_flag=""
    color_flag=""
    color=""
    noswitch_flag=""
    colors_only_flag=""
    colors_lock_flag=""
    explicit_image=""
    start_dir_flag=""

    get_type_from_config() {
        jq -r '.appearance.palette.type' "$SHELL_CONFIG_FILE" 2>/dev/null || echo "auto"
    }
    get_accent_color_from_config() {
        jq -r '.appearance.palette.accentColor' "$SHELL_CONFIG_FILE" 2>/dev/null || echo ""
    }
    set_accent_color() {
        local color="$1"
        jq --arg color "$color" '.appearance.palette.accentColor = $color' "$SHELL_CONFIG_FILE" > "$SHELL_CONFIG_FILE.tmp" && mv "$SHELL_CONFIG_FILE.tmp" "$SHELL_CONFIG_FILE"
    }

    detect_scheme_type_from_image() {
        local img="$1"
        local venv_path="$(eval echo "$ILLOGICAL_IMPULSE_VIRTUAL_ENV")"
        if [ -n "$venv_path" ] && [ -f "$venv_path/bin/activate" ]; then
            source "$venv_path/bin/activate"
            "$SCRIPT_DIR"/scheme_for_image.py "$img" 2>/dev/null | tr -d '\n'
            deactivate
        else
            python3 "$SCRIPT_DIR"/scheme_for_image.py "$img" 2>/dev/null | tr -d '\n'
        fi
    }

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --mode)
                mode_flag="$2"
                shift 2
                ;;
            --type)
                type_flag="$2"
                shift 2
                ;;
            --color)
                if [[ "$2" =~ ^#?[A-Fa-f0-9]{6}$ ]]; then
                    set_accent_color "$2"
                    shift 2
                elif [[ "$2" == "clear" ]]; then
                    set_accent_color ""
                    shift 2
                else
                    set_accent_color $(hyprpicker --no-fancy)
                    shift
                fi
                ;;
            --image)
                imgpath="$2"
                explicit_image="1"
                shift 2
                ;;
            --start-dir)
                start_dir_flag="$2"
                shift 2
                ;;
            --noswitch)
                noswitch_flag="1"
                if [[ -z "$imgpath" ]]; then
                    imgpath=$(jq -r '.background.wallpaperPath' "$SHELL_CONFIG_FILE" 2>/dev/null || echo "")
                fi
                shift
                ;;
            --colors_lock)
                colors_lock_flag="1"
                colors_only_flag="1"
                noswitch_flag="1"
                if [[ -z "$imgpath" ]]; then
                    imgpath=$(jq -r '.background.wallpaperPath' "$SHELL_CONFIG_FILE" 2>/dev/null || echo "")
                fi
                shift
                ;;
            *)
                if [[ -z "$imgpath" ]]; then
                    imgpath="$1"
                fi
                shift
                ;;
        esac
    done

    if [[ -n "$noswitch_flag" && -n "$explicit_image" ]]; then
        colors_only_flag="1"
    fi

    config_color="$(get_accent_color_from_config)"
    if [[ "$config_color" =~ ^#?[A-Fa-f0-9]{6}$ ]]; then
        color_flag="1"
        color="$config_color"
    fi

    if [[ -z "$type_flag" ]]; then
        type_flag="$(get_type_from_config)"
    fi

    allowed_types=(scheme-content scheme-expressive scheme-fidelity scheme-fruit-salad scheme-monochrome scheme-neutral scheme-rainbow scheme-tonal-spot auto)
    valid_type=0
    for t in "${allowed_types[@]}"; do
        if [[ "$type_flag" == "$t" ]]; then
            valid_type=1
            break
        fi
    done
    if [[ $valid_type -eq 0 ]]; then
        echo "[switchwall.sh] Warning: Invalid type '$type_flag', defaulting to 'auto'" >&2
        type_flag="auto"
    fi

    # Only prompt for wallpaper if not using --color and not using --noswitch and no imgpath set
    if [[ -z "$imgpath" && -z "$color_flag" && -z "$noswitch_flag" ]]; then
        if [[ -n "$start_dir_flag" && -d "$start_dir_flag" ]]; then
            cd "$start_dir_flag" || return 1
        else
            cd "$(xdg-user-dir PICTURES)/Wallpapers/showcase" 2>/dev/null || cd "$(xdg-user-dir PICTURES)/Wallpapers" 2>/dev/null || cd "$(xdg-user-dir PICTURES)" || return 1
        fi
        imgpath="$(kdialog --getopenfilename . --title 'Choose wallpaper')"
    fi

    if [[ -n "$imgpath" && -z "$noswitch_flag" ]]; then
        set_accent_color ""
        color_flag=""
        color=""
    fi

    if [[ "$type_flag" == "auto" ]]; then
        if [[ -n "$imgpath" && -f "$imgpath" ]]; then
            detected_type="$(detect_scheme_type_from_image "$imgpath")"
            valid_detected=0
            for t in "${allowed_types[@]}"; do
                if [[ "$detected_type" == "$t" && "$detected_type" != "auto" ]]; then
                    valid_detected=1
                    break
                fi
            done
            if [[ $valid_detected -eq 1 ]]; then
                type_flag="$detected_type"
            else
                echo "[switchwall] Warning: Could not auto-detect a valid scheme, defaulting to 'scheme-tonal-spot'" >&2
                type_flag="scheme-tonal-spot"
            fi
        else
            echo "[switchwall] Warning: No image to auto-detect scheme from, defaulting to 'scheme-tonal-spot'" >&2
            type_flag="scheme-tonal-spot"
        fi
    fi

    if [[ "$mode_flag" == "dark" || "$mode_flag" == "light" ]]; then
        local imgdir="$(dirname "$imgpath")"
        local imgbase="$(basename "$imgpath")"
        local imgname="${imgbase%.*}"
        local imgext="${imgbase##*.}"

        local stripped_name="${imgname%-dark}"
        stripped_name="${stripped_name%-light}"

        local new_imgpath="${imgdir}/${stripped_name}-${mode_flag}.${imgext}"
        local new_stripped_imgpath="${imgdir}/${stripped_name}.${imgext}"

        if [[ -f "$new_imgpath" ]]; then
            imgpath="$new_imgpath"
        elif [[ -f "$new_stripped_imgpath" ]]; then
            imgpath="$new_stripped_imgpath"
        fi
    fi

    switch "$imgpath" "$mode_flag" "$type_flag" "$color_flag" "$color" "$colors_only_flag" "$colors_lock_flag"
}

main "$@"
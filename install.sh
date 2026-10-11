#!/usr/bin/env bash
set -e

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

AUTO_YES=false
for arg in "$@"; do
    if [[ "$arg" == "-y" || "$arg" == "--yes" || "$arg" == "--non-interactive" ]]; then
        AUTO_YES=true
    fi
done

echo -e "${PURPLE}====================================================================${NC}"
echo -e "${PURPLE}   🌌 Установка полной конфигурации Qubert (ПК + Ноутбук)           ${NC}"
echo -e "${PURPLE}   Hyprland • Quickshell (end4) • Горячие клавиши • Скрипты • Темы   ${NC}"
echo -e "${PURPLE}====================================================================${NC}"

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd)"

# Если скрипт запущен напрямую через curl / web
if [ ! -d "$DOTFILES_DIR/.config" ]; then
    echo -e "${YELLOW}--> Загрузка актуального репозитория dotfiles...${NC}"
    CLONE_DIR="$HOME/.dotfiles"
    if [ -d "$CLONE_DIR/.git" ]; then
        echo -e "${YELLOW}Каталог $CLONE_DIR уже существует, обновляем из GitHub...${NC}"
        git -C "$CLONE_DIR" pull || true
    else
        git clone --depth 1 https://github.com/qubertuwu/dotfiles.git "$CLONE_DIR"
    fi
    DOTFILES_DIR="$CLONE_DIR"
fi

# Проверка типа оборудования (ноутбук или ПК)
IS_LAPTOP=false
if [ -d /sys/class/power_supply ] && ls /sys/class/power_supply/ 2>/dev/null | grep -qi "BAT"; then
    IS_LAPTOP=true
elif [ -d /proc/acpi/button/lid ]; then
    IS_LAPTOP=true
fi

if [ "$IS_LAPTOP" = true ]; then
    echo -e "${CYAN}⚡ Обнаружен Ноутбук (Battery/Lid)! Включаем оптимизации для ноутбука (eDP-1/eDP-4, тачпад, яркость, батарея).${NC}"
else
    echo -e "${CYAN}🖥 Обнаружен Стационарный ПК / Workstation (DP-1 / HDMI).${NC}"
fi

# 1. Определение дистрибутива
echo -e "\n${BLUE}--> [1/8] Определение операционной системы...${NC}"
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS_ID=$ID
    OS_LIKE=$ID_LIKE
else
    OS_ID="unknown"
    OS_LIKE=""
fi

install_packages() {
    if [[ "$OS_ID" == "arch" || "$OS_ID" == "cachyos" || "$OS_LIKE" =~ "arch" ]]; then
        echo -e "${GREEN}Обнаружен Arch / CachyOS Linux!${NC}"
        echo -e "${CYAN}Установка базового набора окружения через pacman...${NC}"
        
        sudo pacman -S --needed --noconfirm \
            hyprland \
            foot \
            alacritty \
            fish \
            fastfetch \
            starship \
            swappy \
            grim \
            slurp \
            tesseract \
            tesseract-data-rus \
            tesseract-data-eng \
            imagemagick \
            wl-clipboard \
            cliphist \
            btop \
            fuzzel \
            cava \
            mpv \
            playerctl \
            brightnessctl \
            inotify-tools \
            python-pillow \
            thunar \
            micro \
            pipewire \
            wireplumber \
            qt6-base \
            qt6-declarative \
            qt6-svg \
            qt6-wayland \
            polkit \
            xdg-desktop-portal-hyprland || true

        # Quickshell / Noctalia Shell engine
        if ! command -v qs >/dev/null 2>&1 && ! command -v quickshell >/dev/null 2>&1; then
            echo -e "${YELLOW}Установка Quickshell / noctalia-qs...${NC}"
            sudo pacman -S --needed --noconfirm noctalia-qs 2>/dev/null || \
            sudo pacman -S --needed --noconfirm quickshell 2>/dev/null || true
        fi

        # Поиск AUR helper
        AUR_HELPER=""
        if command -v paru >/dev/null 2>&1; then
            AUR_HELPER="paru"
        elif command -v yay >/dev/null 2>&1; then
            AUR_HELPER="yay"
        fi

        # Если Quickshell еще не установлен, ставим через AUR
        if ! command -v qs >/dev/null 2>&1 && ! command -v quickshell >/dev/null 2>&1; then
            if [ -n "$AUR_HELPER" ]; then
                echo -e "${YELLOW}Установка quickshell через $AUR_HELPER...${NC}"
                $AUR_HELPER -S --needed --noconfirm quickshell-git 2>/dev/null || \
                $AUR_HELPER -S --needed --noconfirm noctalia-qs-git 2>/dev/null || true
            fi
        fi

        # Опционально: полная установка всех пакетов из packages-pacman.txt
        if [ -f "$DOTFILES_DIR/packages-pacman.txt" ]; then
            REPLY_ALL="n"
            if [ "$AUTO_YES" = true ]; then
                REPLY_ALL="y"
            elif [ -t 0 ]; then
                read -p "Хотите установить ВСЕ пакеты системы из packages-pacman.txt? (y/N): " -n 1 -r REPLY_ALL
                echo
            fi
            if [[ "$REPLY_ALL" =~ ^[Yy]$ ]]; then
                echo -e "${YELLOW}Установка всех пакетов через pacman...${NC}"
                sudo pacman -S --needed --noconfirm - < "$DOTFILES_DIR/packages-pacman.txt" || true
            fi
        fi

        # Установка AUR пакетов
        if [ -n "$AUR_HELPER" ] && [ -f "$DOTFILES_DIR/packages-aur.txt" ]; then
            REPLY_AUR="n"
            if [ "$AUTO_YES" = true ]; then
                REPLY_AUR="y"
            elif [ -t 0 ]; then
                read -p "Обнаружен $AUR_HELPER. Установить AUR пакеты из packages-aur.txt? (y/N): " -n 1 -r REPLY_AUR
                echo
            fi
            if [[ "$REPLY_AUR" =~ ^[Yy]$ ]]; then
                $AUR_HELPER -S --needed --noconfirm - < "$DOTFILES_DIR/packages-aur.txt" || true
            else
                # Хотя бы базовые компоненты для тем и рантайма
                $AUR_HELPER -S --needed --noconfirm caelestia-cli caelestia-shell qtengine 2>/dev/null || true
            fi
        fi

    elif [[ "$OS_ID" == "fedora" || "$OS_LIKE" =~ "fedora" ]]; then
        echo -e "${GREEN}Обнаружена Fedora Linux! Установка пакетов через dnf/copr...${NC}"
        
        # Подключение RPM Fusion
        echo -e "${YELLOW}Включение RPM Fusion...${NC}"
        sudo dnf install -y https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm \
            https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm || true

        # Подключение COPR
        sudo dnf copr enable -y solopasha/hyprland || true
        sudo dnf copr enable -y outfoxxed/quickshell || true

        # Установка базового набора
        sudo dnf install -y \
            hyprland \
            quickshell \
            foot \
            alacritty \
            fish \
            fastfetch \
            starship \
            swappy \
            grim \
            slurp \
            tesseract \
            tesseract-langpack-rus \
            tesseract-langpack-eng \
            wl-clipboard \
            ImageMagick \
            btop \
            fuzzel \
            cava \
            mpv \
            playerctl \
            brightnessctl \
            pipewire-utils \
            qt6-qtdeclarative \
            qt6-qtquickcontrols2 \
            jetbrains-mono-fonts-all || true

    elif [[ "$OS_ID" == "ubuntu" || "$OS_ID" == "debian" || "$OS_LIKE" =~ "debian" ]]; then
        echo -e "${GREEN}Обнаружен Debian / Ubuntu! Установка доступных пакетов через apt...${NC}"
        sudo apt update || true
        sudo apt install -y \
            foot \
            alacritty \
            fish \
            fastfetch \
            starship \
            grim \
            slurp \
            tesseract-ocr \
            tesseract-ocr-rus \
            tesseract-ocr-eng \
            imagemagick \
            wl-clipboard \
            btop \
            cava \
            mpv \
            playerctl \
            brightnessctl \
            micro || true
    else
        echo -e "${YELLOW}Дистрибутив ($OS_ID). Пропускаем автоматическую установку менеджером пакетов.${NC}"
    fi
}

REPLY_PKG="y"
if [ "$AUTO_YES" != true ] && [ -t 0 ]; then
    read -p "Установить системные пакеты и зависимости окружения? (y/n, по умолчанию y): " -n 1 -r REPLY_PKG
    echo
fi
if [[ "$REPLY_PKG" =~ ^[Yy]$ || -z "$REPLY_PKG" ]]; then
    install_packages
fi

# Настройка прав для ноутбука (управление подсветкой и тачпадом)
if [ "$IS_LAPTOP" = true ]; then
    echo -e "${YELLOW}Настройка прав доступа для ноутбука (video, input)...${NC}"
    sudo usermod -aG video,input "$USER" 2>/dev/null || true
fi

# 2. Шрифты
echo -e "\n${BLUE}--> [2/8] Проверка и установка шрифтов...${NC}"
mkdir -p "$HOME/.local/share/fonts"

# Копирование пользовательских шрифтов репозитория
if [ -d "$DOTFILES_DIR/.local/share/fonts" ]; then
    cp -rn "$DOTFILES_DIR/.local/share/fonts/"* "$HOME/.local/share/fonts/" 2>/dev/null || true
fi

# JetBrains Mono Nerd Font
if ! fc-list : family 2>/dev/null | grep -iq "JetBrainsMono NF"; then
    echo -e "${YELLOW}Загрузка и установка JetBrainsMono Nerd Font...${NC}"
    FONT_TMP=$(mktemp -d /tmp/jbm-font-XXXXXX)
    curl -sL -o "$FONT_TMP/font.tar.xz" "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.tar.xz" || true
    if [ -f "$FONT_TMP/font.tar.xz" ]; then
        tar -xf "$FONT_TMP/font.tar.xz" -C "$HOME/.local/share/fonts/" 2>/dev/null || true
    fi
    rm -rf "$FONT_TMP"
fi
fc-cache -f "$HOME/.local/share/fonts/" 2>/dev/null || true

# 3. Резервное копирование текущих конфигураций
echo -e "\n${BLUE}--> [3/8] Резервное копирование существующих конфигураций...${NC}"
BACKUP_DIR="$HOME/.config/dotfiles_backup_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_DIR"

CONFIG_BACKUP_ITEMS=(
    alacritty
    autostart
    btop
    caelestia
    cava
    environment.d
    fastfetch
    fish
    foot
    fuzzel
    gtk-3.0
    gtk-4.0
    hypr
    illogical-impulse
    micro
    quickshell
    swappy
    systemd/user
    Thunar
    xsettingsd
    zed
    Code/User/settings.json
    starship.toml
    wireplumber
    vesktop
    kglobalshortcutsrc
    kwinrc
    kdeglobals
    dolphinrc
)

for item in "${CONFIG_BACKUP_ITEMS[@]}"; do
    if [ -e "$HOME/.config/$item" ]; then
        mkdir -p "$BACKUP_DIR/$(dirname "$item")"
        cp -a "$HOME/.config/$item" "$BACKUP_DIR/$item" 2>/dev/null || true
    fi
done

for shf in .bashrc .bash_profile .zshrc; do
    if [ -f "$HOME/$shf" ]; then
        cp -a "$HOME/$shf" "$BACKUP_DIR/" 2>/dev/null || true
    fi
done

echo -e "${GREEN}Резервная копия сохранена в:${NC} $BACKUP_DIR"

# 4. Копирование .config конфигураций
echo -e "\n${BLUE}--> [4/8] Развертывание конфигураций в ~/.config/...${NC}"
mkdir -p "$HOME/.config"
cp -r "$DOTFILES_DIR/.config/"* "$HOME/.config/"

# Симлинк для quickshell (ii -> end4-pC)
if [ -d "$HOME/.config/quickshell/end4-pC" ]; then
    ln -sfn "$HOME/.config/quickshell/end4-pC" "$HOME/.config/quickshell/ii"
fi

# 5. Развертывание шелл-файлов (.bashrc, .bash_profile, .zshrc)
echo -e "\n${BLUE}--> [5/8] Настройка оболочки шелла...${NC}"
for shf in .bashrc .bash_profile .zshrc; do
    if [ -f "$DOTFILES_DIR/$shf" ]; then
        cp "$DOTFILES_DIR/$shf" "$HOME/$shf"
    fi
done

# 6. Развертывание пользовательских скриптов и системных интеграций
echo -e "\n${BLUE}--> [6/8] Установка утилит и скриптов в ~/.local/bin и системных интеграций...${NC}"
mkdir -p "$HOME/.local/bin"
if [ -d "$DOTFILES_DIR/.local/bin" ]; then
    cp -r "$DOTFILES_DIR/.local/bin/"* "$HOME/.local/bin/"
    chmod +x "$HOME/.local/bin/"* 2>/dev/null || true
fi

# Интеграции Dolphin / KDE ServiceMenus
if [ -d "$DOTFILES_DIR/.local/share/kio/servicemenus" ]; then
    mkdir -p "$HOME/.local/share/kio/servicemenus"
    cp -r "$DOTFILES_DIR/.local/share/kio/servicemenus/"* "$HOME/.local/share/kio/servicemenus/"
fi
if [ -d "$DOTFILES_DIR/.local/share/kservices5/ServiceMenus" ]; then
    mkdir -p "$HOME/.local/share/kservices5/ServiceMenus"
    cp -r "$DOTFILES_DIR/.local/share/kservices5/ServiceMenus/"* "$HOME/.local/share/kservices5/ServiceMenus/"
fi

# Выдача прав на исполнение всем скриптам
find "$HOME/.config/quickshell/" "$HOME/.config/hypr/" -type f \( -name "*.sh" -o -name "*.py" \) -exec chmod +x {} + 2>/dev/null || true

# Восстановление настроек dconf (темы, шрифты)
if [ -f "$DOTFILES_DIR/dconf-settings.ini" ] && command -v dconf >/dev/null 2>&1; then
    echo -e "${YELLOW}Восстановление настроек dconf...${NC}"
    dconf load / < "$DOTFILES_DIR/dconf-settings.ini" 2>/dev/null || true
fi

# 7. Tesseract OCR модели для экранного переводчика
echo -e "\n${BLUE}--> [7/8] Проверка моделей экранного переводчика Tesseract OCR...${NC}"
mkdir -p "$HOME/.local/share/tessdata"
if [ ! -f "$HOME/.local/share/tessdata/rus.traineddata" ]; then
    echo -e "${YELLOW}Загрузка русской модели rus.traineddata...${NC}"
    curl -sL -o "$HOME/.local/share/tessdata/rus.traineddata" "https://github.com/tesseract-ocr/tessdata_fast/raw/main/rus.traineddata" || true
fi
if [ -f "/usr/share/tessdata/eng.traineddata" ] && [ ! -f "$HOME/.local/share/tessdata/eng.traineddata" ]; then
    cp "/usr/share/tessdata/eng.traineddata" "$HOME/.local/share/tessdata/" 2>/dev/null || true
elif [ ! -f "$HOME/.local/share/tessdata/eng.traineddata" ]; then
    curl -sL -o "$HOME/.local/share/tessdata/eng.traineddata" "https://github.com/tesseract-ocr/tessdata_fast/raw/main/eng.traineddata" || true
fi

# Перезагрузка пользовательских демонов systemd
if command -v systemctl >/dev/null 2>&1; then
    systemctl --user daemon-reload 2>/dev/null || true
    systemctl --user enable wallpaper-engine-sync.service 2>/dev/null || true
fi

# Установка расширений VS Code (если установлен `code`)
if command -v code >/dev/null 2>&1 && [ -f "$DOTFILES_DIR/vscode-extensions.txt" ]; then
    echo -e "\n${BLUE}--> Обнаружен VS Code. Проверка расширений...${NC}"
    while read -r ext; do
        [ -n "$ext" ] && code --install-extension "$ext" --force 2>/dev/null || true
    done < "$DOTFILES_DIR/vscode-extensions.txt"
fi

# Копирование шпаргалок на рабочий стол или в домашнюю папку
if [ -f "$DOTFILES_DIR/горячие_клавиши.md" ]; then
    cp "$DOTFILES_DIR/горячие_клавиши.md" "$HOME/" 2>/dev/null || true
    cp "$DOTFILES_DIR/Горячие_клавиши_Hyprland.html" "$HOME/" 2>/dev/null || true
fi

# 8. Перезагрузка сессии при необходимости
echo -e "\n${BLUE}--> [8/8] Финализация...${NC}"
if command -v hyprctl >/dev/null 2>&1 && [ -n "$HYPRLAND_INSTANCE_SIGNATURE" ]; then
    echo -e "${GREEN}Перезагрузка активной конфигурации Hyprland...${NC}"
    hyprctl reload >/dev/null 2>&1 || true
fi

echo -e "\n${GREEN}====================================================================${NC}"
echo -e "${GREEN}   ✨ Конфигурация Qubert успешно развернута! 🎉                   ${NC}"
echo -e "${GREEN}====================================================================${NC}"
echo -e "Горячие клавиши (работают на EN и RU раскладках):"
echo -e "  • ${YELLOW}Super + W / Ц${NC}             — Селектор обоев (Wallpaper Engine / MPV / Темы)"
echo -e "  • ${YELLOW}Super + T / Е${NC}             — Быстрый Google переводчик (карточка)"
echo -e "  • ${YELLOW}Super + Shift + T / Е${NC}       — Экранный переводчик OCR (выделение области)"
echo -e "  • ${YELLOW}Super + M / Ь${NC}             — Управление музыкой и медиаплеером"
echo -e "  • ${YELLOW}Super + I / Ш / Esc${NC}       — Панель настроек оболочки (темы, анимации)"
echo -e "  • ${YELLOW}Super + Q / Й${NC}             — Терминал (Foot / Alacritty)"
echo -e "  • ${YELLOW}Super + F / А / B${NC}         — Браузер (Firefox)"
echo -e "  • ${YELLOW}Super + E / У${NC}             — Файловый менеджер (Dolphin / Thunar)"
echo -e "  • ${YELLOW}Super + D / В${NC}             — Меню приложений (Launcher)"
echo -e "  • ${YELLOW}Super + V / М${NC}             — История буфера обмена (Cliphist)"
echo -e "  • ${YELLOW}Super + C / С / Alt+F4${NC}    — Закрыть окно"
echo -e "  • ${YELLOW}PrintScreen${NC}               — Скриншот со Swappy"
echo -e "  • ${CYAN}Тачпад ноутбука:${NC} свайп 3 пальцами влево/вправо для рабочих столов"
echo -e "  • ${CYAN}Яркость ноутбука:${NC} функциональные клавиши Fn + Яркость поддерживаются"
echo -e "  • ${CYAN}Мониторы:${NC} автоматическая поддержка ноутбуков (eDP-1/eDP-4) и мониторов (DP-1)"
echo

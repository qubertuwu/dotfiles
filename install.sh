#!/usr/bin/env bash
set -e

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
PURPLE='\033[0;35m'
NC='\033[0m'

echo -e "${PURPLE}====================================================${NC}"
echo -e "${PURPLE}   Установка окружения Qubert (Hyprland + Quickshell)  ${NC}"
echo -e "${PURPLE}====================================================${NC}"

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd)"

# Если скрипт запущен напрямую через curl
if [ ! -d "$DOTFILES_DIR/.config" ]; then
    echo -e "${YELLOW}--> Загрузка репозитория dotfiles...${NC}"
    CLONE_DIR="$HOME/.dotfiles"
    if [ -d "$CLONE_DIR" ]; then
        echo -e "${YELLOW}Каталог $CLONE_DIR уже существует, обновляем...${NC}"
        git -C "$CLONE_DIR" pull || true
    else
        git clone --depth 1 https://github.com/qubertuwu/dotfiles.git "$CLONE_DIR"
    fi
    DOTFILES_DIR="$CLONE_DIR"
fi

# 1. Определение дистрибутива и установка пакетов
echo -e "${BLUE}--> Определение операционной системы...${NC}"
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS_ID=$ID
    OS_LIKE=$ID_LIKE
else
    OS_ID="unknown"
fi

install_packages() {
    if [[ "$OS_ID" == "fedora" || "$OS_LIKE" =~ "fedora" ]]; then
        echo -e "${GREEN}Обнаружена Fedora Linux! Установка пакетов через dnf/copr...${NC}"
        
        # Подключение RPM Fusion
        echo -e "${YELLOW}Включение RPM Fusion...${NC}"
        sudo dnf install -y https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm \
            https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm || true

        # Подключение Hyprland COPR (актуальные сборки)
        echo -e "${YELLOW}Включение COPR solopasha/hyprland...${NC}"
        sudo dnf copr enable -y solopasha/hyprland || true

        # Подключение COPR quickshell
        sudo dnf copr enable -y outfoxxed/quickshell || true

        # Установка базового набора
        echo -e "${YELLOW}Установка системных пакетов Fedora...${NC}"
        sudo dnf install -y \
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

    elif [[ "$OS_ID" == "arch" || "$OS_ID" == "cachyos" || "$OS_LIKE" =~ "arch" ]]; then
        echo -e "${GREEN}Обнаружен Arch / CachyOS Linux! Установка через pacman...${NC}"
        sudo pacman -S --needed --noconfirm \
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
            tesseract-data-rus \
            tesseract-data-eng \
            imagemagick \
            wl-clipboard \
            btop \
            fuzzel \
            cava \
            mpv \
            playerctl \
            brightnessctl || true
    else
        echo -e "${RED}Неизвестный дистрибутив. Пропускаем автоматическую установку пакетов.${NC}"
    fi
}

# Спрашиваем или ставим пакеты
if [ -t 0 ]; then
    read -p "Хотите автоматически установить/обновить системные пакеты? (y/n, по умолчанию y): " -n 1 -r REPLY_PKG
    echo
    if [[ "$REPLY_PKG" =~ ^[Yy]$ || -z "$REPLY_PKG" ]]; then
        install_packages
    fi
else
    install_packages
fi

# 2. Шрифты (JetBrains Mono Nerd Font)
echo -e "${BLUE}--> Проверка шрифтов...${NC}"
mkdir -p "$HOME/.local/share/fonts"
if ! fc-list : family | grep -iq "JetBrainsMono NF"; then
    echo -e "${YELLOW}Установка JetBrainsMono Nerd Font...${NC}"
    FONT_TMP=$(mktemp -d /tmp/jbm-font-XXXXXX)
    curl -sL -o "$FONT_TMP/font.tar.xz" "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.tar.xz" || true
    if [ -f "$FONT_TMP/font.tar.xz" ]; then
        tar -xf "$FONT_TMP/font.tar.xz" -C "$HOME/.local/share/fonts/" 2>/dev/null || true
        fc-cache -f "$HOME/.local/share/fonts/" 2>/dev/null || true
    fi
    rm -rf "$FONT_TMP"
fi

# 3. Резервное копирование существующих конфигураций
CONFIG_LIST=(
    alacritty
    caelestia
    fastfetch
    fish
    foot
    hypr
    quickshell
    illogical-impulse
    fuzzel
    swappy
    btop
    cava
    starship.toml
)

BACKUP_DIR="$HOME/.config/dotfiles_backup_$(date +%Y%m%d_%H%M%S)"
echo -e "${YELLOW}--> Создание резервной копии старых конфигов в:${NC} $BACKUP_DIR"
mkdir -p "$BACKUP_DIR"

for item in "${CONFIG_LIST[@]}"; do
    if [ -e "$HOME/.config/$item" ]; then
        cp -a "$HOME/.config/$item" "$BACKUP_DIR/" 2>/dev/null || true
    fi
done

# 4. Копирование актуальных конфигураций
echo -e "${BLUE}--> Копирование конфигураций в ~/.config/...${NC}"
mkdir -p "$HOME/.config"
cp -r "$DOTFILES_DIR/.config/"* "$HOME/.config/"

# Создание симлинка quickshell/ii -> quickshell/end4-pC
if [ -d "$HOME/.config/quickshell/end4-pC" ]; then
    ln -sfn "$HOME/.config/quickshell/end4-pC" "$HOME/.config/quickshell/ii"
fi

# Выдача прав на исполнение скриптам
echo -e "${BLUE}--> Настройка прав исполнения для скриптов...${NC}"
find "$HOME/.config/quickshell/" "$HOME/.config/hypr/" -type f \( -name "*.sh" -o -name "*.py" \) -exec chmod +x {} + 2>/dev/null || true

# 5. Модели для переводчика Tesseract OCR
mkdir -p "$HOME/.local/share/tessdata"
if [ ! -f "$HOME/.local/share/tessdata/rus.traineddata" ]; then
    echo -e "${BLUE}--> Загрузка русской модели Tesseract OCR для экранного переводчика...${NC}"
    curl -sL -o "$HOME/.local/share/tessdata/rus.traineddata" "https://github.com/tesseract-ocr/tessdata_fast/raw/main/rus.traineddata" || true
fi
if [ -f "/usr/share/tessdata/eng.traineddata" ] && [ ! -f "$HOME/.local/share/tessdata/eng.traineddata" ]; then
    cp "/usr/share/tessdata/eng.traineddata" "$HOME/.local/share/tessdata/" 2>/dev/null || true
fi

# 6. Перезагрузка Hyprland при наличии активной сессии
if command -v hyprctl >/dev/null 2>&1 && [ -n "$HYPRLAND_INSTANCE_SIGNATURE" ]; then
    echo -e "${GREEN}--> Перезагрузка активной сессии Hyprland...${NC}"
    hyprctl reload >/dev/null 2>&1 || true
fi

echo -e "\n${GREEN}====================================================${NC}"
echo -e "${GREEN}   ✨ Оболочка Qubert успешно установлена! 🎉       ${NC}"
echo -e "${GREEN}====================================================${NC}"
echo -e "Горячие клавиши:"
echo -e "  • ${YELLOW}Super + W${NC}             — Селектор обоев (Wallpaper Engine / MPV)"
echo -e "  • ${YELLOW}Super + T${NC}             — Быстрый перевод выделенного текста"
echo -e "  • ${YELLOW}Super + Shift + T${NC}       — Перевод выделенной области экрана"
echo -e "  • ${YELLOW}Super + M${NC}             — Управление плеером и музыкой"
echo -e "  • ${YELLOW}Super + I / Super + Esc${NC} — Панель настроек оболочки"
echo -e "  • ${YELLOW}PrintScreen${NC}           — Скриншот области экрана (Swappy)"
echo -e "  • ${YELLOW}Super + Space${NC}         — Меню запуска приложений (Fuzzel)"
echo

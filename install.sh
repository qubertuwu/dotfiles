#!/usr/bin/env bash
set -e

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}====================================================${NC}"
echo -e "${BLUE}        Установка Dotfiles Qubert (Caelestia + Hyprland) ${NC}"
echo -e "${BLUE}====================================================${NC}"

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd)"

# If run via curl pipe, clone into temporary directory
if [ ! -d "$DOTFILES_DIR/.config" ]; then
    echo -e "${YELLOW}--> Загрузка репозитория dotfiles...${NC}"
    TMP_DIR=$(mktemp -d /tmp/qubert-dotfiles-XXXXXX)
    git clone --depth 1 https://github.com/qubertuwu/dotfiles.git "$TMP_DIR"
    DOTFILES_DIR="$TMP_DIR"
fi

# 1. Backup existing configurations
BACKUP_DIR="$HOME/.config/dotfiles_backup_$(date +%Y%m%d_%H%M%S)"
echo -e "${YELLOW}--> Создание резервной копии старых конфигов в:${NC} $BACKUP_DIR"
mkdir -p "$BACKUP_DIR"

for item in alacritty caelestia fastfetch fish foot hypr quickshell; do
    if [ -d "$HOME/.config/$item" ] || [ -f "$HOME/.config/$item" ]; then
        mv "$HOME/.config/$item" "$BACKUP_DIR/" 2>/dev/null || true
    fi
done

# 2. Copy new configurations
echo -e "${BLUE}--> Копирование конфигураций в ~/.config/...${NC}"
mkdir -p "$HOME/.config"
cp -r "$DOTFILES_DIR/.config/"* "$HOME/.config/"

# Make scripts executable
find "$HOME/.config/quickshell/" "$HOME/.config/hypr/" -type f -name "*.sh" -exec chmod +x {} + 2>/dev/null || true
find "$HOME/.config/quickshell/" "$HOME/.config/hypr/" -type f -name "*.py" -exec chmod +x {} + 2>/dev/null || true

# 3. Ensure Tesseract Russian language model is present
mkdir -p "$HOME/.local/share/tessdata"
if [ ! -f "$HOME/.local/share/tessdata/rus.traineddata" ]; then
    echo -e "${BLUE}--> Загрузка русской модели Tesseract OCR...${NC}"
    curl -sL -o "$HOME/.local/share/tessdata/rus.traineddata" https://github.com/tesseract-ocr/tessdata_fast/raw/main/rus.traineddata || true
fi
if [ -f "/usr/share/tessdata/eng.traineddata" ] && [ ! -f "$HOME/.local/share/tessdata/eng.traineddata" ]; then
    cp "/usr/share/tessdata/eng.traineddata" "$HOME/.local/share/tessdata/" 2>/dev/null || true
fi

# 4. Check dependencies
echo -e "${BLUE}--> Проверка системных пакетов...${NC}"
PKGS_TO_CHECK=(hyprland quickshell grim slurp tesseract imagemagick wl-clipboard fish foot fastfetch)
MISSING=()

for pkg in "${PKGS_TO_CHECK[@]}"; do
    if ! command -v "$pkg" >/dev/null 2>&1; then
        MISSING+=("$pkg")
    fi
done

if [ ${#MISSING[@]} -gt 0 ]; then
    echo -e "${YELLOW}Рекомендуется установить недостающие пакеты: ${MISSING[*]}${NC}"
    if command -v pacman >/dev/null 2>&1; then
        echo -e "${YELLOW}Команда для Arch/CachyOS: sudo pacman -S ${MISSING[*]}${NC}"
    fi
fi

# 5. Reload Hyprland if running
if command -v hyprctl >/dev/null 2>&1; then
    hyprctl reload >/dev/null 2>&1 || true
fi

echo -e "${GREEN}====================================================${NC}"
echo -e "${GREEN}      Оболочка успешно установлена! 🎉             ${NC}"
echo -e "${GREEN}====================================================${NC}"
echo -e "Горячие клавиши переводчика:"
echo -e "  • ${YELLOW}Super + T${NC}       — Быстрый перевод выделенного текста"
echo -e "  • ${YELLOW}Super + Shift + T${NC} — Перевод выделенной области экрана (Google Lens)"

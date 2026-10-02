# 🌌 Qubert's Dotfiles (Hyprland + Quickshell / Caelestia)

Полный комплект моей рабочей оболочки для Linux под управлением **Hyprland** и **Quickshell**.

![Hyprland](https://img.shields.io/badge/WM-Hyprland-blue)
![Shell](https://img.shields.io/badge/Shell-Quickshell%20%7C%20Caelestia-purple)
![Terminal](https://img.shields.io/badge/Terminal-Foot%20%7C%20Alacritty-green)
![Status](https://img.shields.io/badge/Status-Maintained-brightgreen)

---

## 🚀 Быстрая установка на новый ПК (в одну команду)

Откройте терминал и выполните:

```bash
curl -sSL https://raw.githubusercontent.com/qubertuwu/dotfiles/main/install.sh | bash
```

*Или через ручное клонирование:*
```bash
git clone https://github.com/qubertuwu/dotfiles.git
cd dotfiles
./install.sh
```

> **Примечание:** Скрипт автоматически создаст резервную копию ваших текущих конфигов в `~/.config/dotfiles_backup_<дата>/` перед заменой.

---

## 📦 Что входит в комплект:

* 🪟 **Hyprland (`~/.config/hypr/`)**: Полная тайлинговая конфигурация на Lua с анимациями, сплитами, правилами окон и жестами.
* 🪄 **Quickshell / Caelestia (`~/.config/quickshell/`)**: Кастомная панель задач, виджеты, оверлеи, центр уведомлений, слайдеры громкости и управление обоями.
* 🌐 **Встроенный переводчик + Google Lens**:
  * `Super + T` — перевод выделенного мышью текста в любой программе.
  * `Super + Shift + T` — выделение любой прямоугольной области экрана рамкой (`slurp + grim + tesseract`).
  * Встроенная база **IT-сленга** и терминов программирования.
* 🖥️ **Терминалы (`foot`, `alacritty`)**: Настроенные цветовые схемы и шрифты.
* 🐟 **Fish shell (`~/.config/fish/`)**: Конфигурация шелла и функций.
* 📊 **Fastfetch (`~/.config/fastfetch/`)**: Кастомный вывод системной информации с поддержкой Sixels и картинок.

---

## ⌨️ Основные горячие клавиши

| Сочетание | Описание |
|---|---|
| **`Super + T`** | Быстрый перевод выделенного текста |
| **`Super + Shift + T`** | Перевод выбранной области экрана (Google Lens) |
| **`Super + Return`** | Открыть терминал |
| **`Super + Q`** | Закрыть активное окно |
| **`Super + I`** | Настройки оболочки (Quickshell Settings) |
| **`Super + W`** | Селектор живых и статичных обоев |
| **`Super + M`** | Медиа-плеер и управление воспроизведением |

---

## 📄 Лицензия
MIT License.

# 🌌 Dotfiles Qubert (Hyprland + Quickshell / Caelestia)

Полноценная конфигурация рабочего окружения **Hyprland** с кастомной оболочкой на базе **Quickshell** (`end4-pC`), живыми обоями Wallpaper Engine, экранным переводчиком, интеграцией ИИ и виджетами.

Поддерживает установку в **1 клик** на **Fedora Linux** и **Arch / CachyOS**.

---

## ⚡ Быстрая установка в 1 команду

На свежеустановленной системе (Fedora или Arch) открой терминал и выполни:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/qubertuwu/dotfiles/main/install.sh)
```

Или вручную:
```bash
git clone --depth 1 https://github.com/qubertuwu/dotfiles.git ~/.dotfiles
cd ~/.dotfiles
./install.sh
```

---

## 🧩 Что входит в состав:

- **Оконный менеджер:** Hyprland
- **Оболочка / виджеты:** Quickshell (`end4-pC` / `caelestia`)
- **Меню приложений:** Fuzzel
- **Терминалы:** Foot / Alacritty
- **Шелл:** Fish / Bash + Starship Prompt
- **Скриншоты и аннотации:** Grim + Slurp + Swappy
- **Переводчик:** Кастомный экранный OCR-переводчик (Tesseract RUS + ENG + Google Lens / API)
- **Живые обои:** Селектор видео-обоев Wallpaper Engine / MPV
- **ИИ-ассистент:** Интеграция боковой панели с DeepSeek R1 / OpenAI API
- **Системный монитор:** btop, cava, fastfetch

---

## ⌨️ Основные горячие клавиши:

| Комбинация | Действие |
|---|---|
| **Super + Space** | Меню запуска приложений (Fuzzel) |
| **Super + Return** | Запуск терминала (Foot) |
| **Super + W** | Селектор обоев (Wallpaper Engine) |
| **Super + T** | Быстрый перевод выделенного текста |
| **Super + Shift + T** | Перевод области экрана (OCR Google Lens) |
| **Super + M** | Окно управления плеером (музыка / YouTube) |
| **Super + I** / **Super + Esc** | Центр настроек оболочки (темы, размытие, анимации) |
| **PrintScreen** | Скриншот области экрана с редактором Swappy |
| **Super + Q** | Закрыть активное окно |
| **Super + E** | Файловый менеджер (Dolphin / Thunar) |

---

## 📁 Структура репозитория

```
~/.config/
├── hypr/               # Конфигурация Hyprland (Lua)
├── quickshell/         # Оболочка end4-pC, виджеты, оверлеи
├── caelestia/          # Пользовательские оверрайды переменных
├── illogical-impulse/  # Настройки внешнего вида, шрифты, ИИ
├── fuzzel/             # Стиль лаунчера приложений
├── swappy/             # Настройки редактора скриншотов
├── btop/               # Системный монитор и тема
├── cava/               # Аудио-визуализатор
└── starship.toml       # Кастомный промпт терминала
```

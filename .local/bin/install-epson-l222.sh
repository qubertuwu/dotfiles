#!/usr/bin/env bash
set -e

# Clear broken local proxy variables
unset HTTP_PROXY HTTPS_PROXY ALL_PROXY http_proxy https_proxy all_proxy

echo "=========================================================="
echo "    Установка драйверов и службы печати для Epson L222    "
echo "=========================================================="
echo ""
echo "1. Установка системы печати CUPS и утилит управления..."
sudo pacman -S --needed --noconfirm cups cups-filters cups-pdf ghostscript system-config-printer libusb colord

echo ""
echo "2. Запуск и включение службы печати CUPS..."
sudo systemctl enable --now cups.service

echo ""
echo "3. Сборка и установка официальных драйверов Epson L222 из AUR..."
# epson-inkjet-printer-201401w (L130, L132, L220, L222, L310, L312, L360...)
paru -S --needed --noconfirm epson-inkjet-printer-201401w epson-inkjet-printer-escpr

echo ""
echo "4. Перезапуск службы CUPS для применения новых драйверов..."
sudo systemctl restart cups.service

echo ""
echo "=========================================================="
echo "   Установка завершена! Подключите принтер Epson L222.    "
echo "=========================================================="
echo "Сейчас откроется менеджер принтеров. Если принтер уже"
echo "подключен по USB и включен, он определится автоматически."
echo ""
system-config-printer &

echo ""
echo "Нажмите Enter для завершения..."
read -r

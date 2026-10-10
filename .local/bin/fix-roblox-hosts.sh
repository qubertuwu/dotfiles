#!/usr/bin/env bash
set -e

ROBLOX_BLOCK="# --- Roblox CDN fix (TikTok Kurkupa) ---
18.65.39.105 tr.rbxcdn.com
18.65.39.105 t0.rbxcdn.com t1.rbxcdn.com t2.rbxcdn.com t3.rbxcdn.com t4.rbxcdn.com t5.rbxcdn.com t6.rbxcdn.com t7.rbxcdn.com
18.65.39.105 c0.rbxcdn.com c1.rbxcdn.com c2.rbxcdn.com c3.rbxcdn.com c4.rbxcdn.com c5.rbxcdn.com c6.rbxcdn.com c7.rbxcdn.com
# --- End Roblox CDN fix ---"

if grep -q "tr.rbxcdn.com" /etc/hosts; then
    echo "Записи Roblox CDN уже присутствуют в /etc/hosts"
else
    echo -e "\n$ROBLOX_BLOCK" >> /etc/hosts
    echo "Записи успешно добавлены в /etc/hosts"
fi

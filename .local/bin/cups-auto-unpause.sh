#!/bin/bash
PRINTER="L222-Series"

while true; do
    STATUS=$(lpstat -p "$PRINTER" 2>/dev/null)
    if echo "$STATUS" | grep -qE "отключен|disabled|stopped|paused"; then
        cupsenable "$PRINTER" 2>/dev/null
        cupsaccept "$PRINTER" 2>/dev/null
    fi
    sleep 2
done
